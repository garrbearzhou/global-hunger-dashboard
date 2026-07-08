#!/usr/bin/env python3
"""
Model 5 — Global constrained policy optimization (Lagrangian / KKT).

Stylized global aid-allocation problem: allocate a fixed annual budget W
(in $M) across countries to maximize total people lifted out of
undernourishment, where each country's response is a concave saturating
impact function calibrated to the Bangladesh appendix model.

Impact function (people lifted at spending x, x in $M):

    f_c(x) = H_c * (1 - exp(-k_c x)),   k_c = KAPPA * readiness_c / H_c

  - H_c  : undernourished headcount (FAO PoU x WB population, 2022)
  - readiness_c : ND-GAIN readiness (delivery / absorptive capacity)
  - KAPPA: people lifted per $1M at the first marginal dollar, per unit
           readiness. Calibrated so that for Bangladesh (readiness 0.275,
           H = 18.05M) a budget of $8,000M closes ~95% of the deficit,
           matching the Appendix A single-year optimum.

KKT structure (interior optimum):
    f_c'(x_c) = H_c k_c e^{-k_c x_c} = KAPPA * readiness_c * e^{-k_c x_c} = lambda
 => x_c* = max(0, (1/k_c) * ln(KAPPA * readiness_c / lambda))
Funding rule (complementary slackness): country funded iff
    KAPPA * readiness_c > lambda.
lambda solved by 1-D root finding on the budget constraint.

Scenarios:
  1. Unconstrained budgets W in {10, 25, 50, 100} $B -> shadow price path.
  2. Political earmark at W = $50B: at least PHI of budget must flow to
     non-low-income countries (mimics strategic/political earmarking).
     If binding, solved as two group problems; mu = lambda_P - lambda_NP gap.

Outputs: output/global_model5_allocation.csv, printed summary tables.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.optimize import brentq

PAPER = Path(__file__).resolve().parents[1]
PROJECT = PAPER.parent
sys.path.insert(0, str(PAPER / "scripts"))

from global_models_1_to_4 import (  # noqa: E402
    CV_VULN,
    cross_section_2022,
    load_world_bank_backbone,
    wb_latest,
)

KAPPA = 24_500.0          # people per $M per unit readiness at first dollar
BUDGETS_BN = [10, 25, 50, 100]
PHI = 0.50                # earmark share
SCENARIO_W_BN = 50


def build_problem() -> pd.DataFrame:
    wb, backbone = load_world_bank_backbone()
    cs = cross_section_2022(wb, backbone)

    names = pd.read_csv(CV_VULN, low_memory=False)[["ISO3", "Name"]].rename(
        columns={"ISO3": "iso3", "Name": "country"}
    )
    cs = cs.merge(names, on="iso3", how="left")

    wb22 = wb_latest(wb, {"pop_POP.TOTL": "population", "income": "income"})
    cs = cs.merge(wb22, on="iso3", how="left")

    d = cs.dropna(subset=["undernourishment", "readiness", "population"]).copy()
    d["H"] = d["undernourishment"] / 100.0 * d["population"]
    d = d[d["H"] > 0].copy()
    d["k"] = KAPPA * d["readiness"] / d["H"]
    d["marg0"] = KAPPA * d["readiness"]  # f'(0), people per $M
    return d


def allocate(d: pd.DataFrame, W: float) -> tuple[pd.Series, float]:
    """Solve max sum f_c(x_c) s.t. sum x_c = W, x >= 0. Returns (x, lambda)."""
    marg0 = d["marg0"].to_numpy()
    k = d["k"].to_numpy()

    def spend(lam: float) -> float:
        x = np.maximum(0.0, np.log(marg0 / lam) / k)
        return x.sum()

    lo, hi = 1e-9, marg0.max() * (1 - 1e-12)
    lam = brentq(lambda L: spend(L) - W, lo, hi, xtol=1e-12, rtol=1e-12)
    x = np.maximum(0.0, np.log(marg0 / lam) / k)
    return pd.Series(x, index=d.index), lam


def impact(d: pd.DataFrame, x: pd.Series) -> pd.Series:
    return d["H"] * (1 - np.exp(-d["k"] * x))


def kkt_check(d: pd.DataFrame, x: pd.Series, lam: float) -> tuple[float, int]:
    """Max |f'(x)-lambda| over funded countries; count of exclusions violating rule."""
    marg = d["marg0"] * np.exp(-d["k"] * x)
    funded = x > 1e-9
    stat_err = (marg[funded] - lam).abs().max() / lam
    bad_excl = int(((~funded) & (d["marg0"] > lam * (1 + 1e-9))).sum())
    return float(stat_err), bad_excl


def main() -> int:
    d = build_problem()
    n = len(d)
    print(f"Countries in problem: {n}; total undernourished: {d['H'].sum()/1e6:.1f}M")
    print(f"Calibration: KAPPA={KAPPA:,.0f} people/$M per readiness unit; "
          f"Bangladesh f'(0)={KAPPA*0.275:,.0f} people/$M (~${1e6/(KAPPA*0.275):,.0f}/person)\n")

    # --- Scenario set 1: shadow-price path across budgets ---
    rows = []
    for wbn in BUDGETS_BN:
        W = wbn * 1000.0
        x, lam = allocate(d, W)
        ppl = impact(d, x).sum()
        stat_err, bad = kkt_check(d, x, lam)
        funded = int((x > 1e-9).sum())
        rows.append({
            "budget_bn": wbn, "lambda_people_per_M": lam,
            "marginal_cost_per_person": 1e6 / lam,
            "total_lifted_M": ppl / 1e6,
            "pct_of_global_deficit": 100 * ppl / d["H"].sum(),
            "countries_funded": funded, "countries_excluded": n - funded,
            "kkt_stationarity_relerr": stat_err, "kkt_exclusion_violations": bad,
        })
    path = pd.DataFrame(rows)
    print("=== SHADOW PRICE PATH (unconstrained) ===")
    print(path.round(3).to_string(index=False))

    # --- Detailed allocation at W = 50B ---
    W = SCENARIO_W_BN * 1000.0
    x50, lam50 = allocate(d, W)
    d_out = d.copy()
    d_out["alloc_M"] = x50
    d_out["lifted"] = impact(d, x50)
    d_out["funded"] = d_out["alloc_M"] > 1e-9
    d_out = d_out.sort_values("alloc_M", ascending=False)

    print(f"\n=== W=$50B OPTIMUM: lambda={lam50:.1f} people/$M "
          f"(${1e6/lam50:,.0f}/person at margin) ===")
    print("\nTop 12 allocations:")
    cols = ["country", "iso3", "income", "readiness", "H", "alloc_M", "lifted"]
    top = d_out.head(12)[cols].copy()
    top["H"] = (top["H"] / 1e6).round(2)
    top["lifted"] = (top["lifted"] / 1e6).round(2)
    print(top.round(3).to_string(index=False))

    excl = d_out[~d_out["funded"]].sort_values("marg0")
    print(f"\nExcluded countries ({len(excl)}): "
          + ", ".join(f"{r.country} (readiness {r.readiness:.2f})" for r in excl.itertuples()))
    print("Exclusion rule: funded iff KAPPA*readiness > lambda "
          f"<=> readiness > {lam50/KAPPA:.3f}")

    # income-group shares
    d_out["lic"] = d_out["income"] == "Low income"
    share_lic = d_out.loc[d_out["lic"], "alloc_M"].sum() / W
    print(f"\nUnconstrained share to low-income countries: {share_lic:.1%}; "
          f"to non-LIC: {1-share_lic:.1%}")

    # --- Scenario 2: political earmark (floor on non-LIC share) ---
    nonlic_share = 1 - share_lic
    print(f"\n=== EARMARK SCENARIO: >= {PHI:.0%} of W=$50B to non-low-income ===")
    if nonlic_share >= PHI:
        print("Floor does NOT bind at the unconstrained optimum (mu = 0).")
        # try the opposite: equity floor on LIC
        print(f"Testing instead an equity floor: >= {PHI:.0%} to low-income countries.")
        P = d[d["income"] == "Low income"]
        NP = d[d["income"] != "Low income"]
        floor_label = "low-income"
    else:
        P = d[d["income"] != "Low income"]
        NP = d[d["income"] == "Low income"]
        floor_label = "non-low-income"

    xP, lamP = allocate(P, PHI * W)
    xNP, lamNP = allocate(NP, (1 - PHI) * W)
    tot_con = impact(P, xP).sum() + impact(NP, xNP).sum()
    tot_unc = impact(d, x50).sum()
    mu = lamNP - lamP
    print(f"Constrained optimum: lambda_P({floor_label})={lamP:.1f}, "
          f"lambda_rest={lamNP:.1f} people/$M")
    print(f"mu (marginal efficiency cost of the floor) = {mu:.1f} people per $M shifted")
    print(f"Total lifted: constrained {tot_con/1e6:.2f}M vs unconstrained {tot_unc/1e6:.2f}M "
          f"-> efficiency cost {(tot_unc-tot_con)/1e6:.2f}M people "
          f"({100*(tot_unc-tot_con)/tot_unc:.1f}%)")

    out = d_out[["country", "iso3", "income", "readiness", "undernourishment",
                 "H", "marg0", "alloc_M", "lifted", "funded"]].round(3)
    out_path = PAPER / "output" / "global_model5_allocation.csv"
    out.to_csv(out_path, index=False)
    path.round(4).to_csv(PAPER / "output" / "global_model5_shadow_prices.csv", index=False)
    print(f"\nWritten: {out_path} and global_model5_shadow_prices.csv")
    return 0


if __name__ == "__main__":
    sys.exit(main())
