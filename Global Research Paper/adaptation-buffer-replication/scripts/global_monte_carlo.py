#!/usr/bin/env python3
"""
Monte Carlo analyses for the global adaptation-buffer paper.

Everything here uses only tools a student with single-variable statistics,
multivariable calculus, and linear algebra already has:
  - ordinary least squares (a linear-algebra projection),
  - repeated random sampling (Monte Carlo),
  - the bootstrap (resample the data, refit, repeat).
No robust/clustered standard-error formulas, no KKT conditions, no PCA,
no regularization are used.

Part A — Buffer uncertainty (bootstrap + measurement error)
-----------------------------------------------------------
The buffer for country c is B_c = (b0 + b1 * V_c) - U_c, where (b0, b1) come
from the Model 1 line and U_c is reported undernourishment. Two things are
uncertain: (1) the fitted line, and (2) the reported hunger rate. We capture
both by simulation:
  for each of B draws:
     * resample the 143 countries with replacement and refit the line  -> (b0, b1)
     * add measurement noise to each country's reported PoU:
           U_c* = U_c + e,   e ~ Normal(0, sigma_c),  sigma_c = max(1.0, 0.10*U_c)
     * recompute every country's buffer
This yields, per country, a buffer distribution -> 90% interval and the
probability the country is a genuine over-performer, P(buffer > 0).

Part B — Buffer-collapse dynamics (Monte Carlo of a shock process)
------------------------------------------------------------------
A stylized year-by-year model of one country's buffer (calibrated to
Bangladesh, B0 from Model 1). Each year the buffer drifts back toward its
target and is occasionally knocked down by a climate/conflict shock:
     B_{t+1} = B_t + rho*(B_target - B_t) - shock_t + noise_t
     shock_t = D  with prob p   (D ~ Gamma, mean m),   else 0
We compare a baseline country with one that has made resilience investments
(smaller shocks, faster recovery) and report collapse probabilities.

Outputs:
  output/global_mc_buffer_uncertainty.csv
  output/global_mc_slope_distribution.csv
  output/global_mc_collapse_dynamics.csv
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd

PAPER = Path(__file__).resolve().parents[1]  # repo root
PROJECT = PAPER
sys.path.insert(0, str(PAPER / "scripts"))

from global_models_1_to_4 import (  # noqa: E402
    CV_VULN,
    cross_section_2022,
    load_world_bank_backbone,
)

SEED = 42
B_DRAWS = 20_000
CV_MEAS = 0.10          # measurement-error coefficient of variation for FAO PoU
SIGMA_FLOOR = 1.0       # minimum measurement SD (percentage points)


def ols_line(v: np.ndarray, u: np.ndarray) -> tuple[float, float]:
    """Slope and intercept of the least-squares line u ~ b0 + b1 v."""
    X = np.column_stack([np.ones_like(v), v])
    # normal equations (X'X) b = X'u  -> solve via lstsq (linear algebra)
    b, *_ = np.linalg.lstsq(X, u, rcond=None)
    return float(b[0]), float(b[1])


def part_a_buffer_uncertainty(d: pd.DataFrame, rng: np.random.Generator) -> tuple[pd.DataFrame, pd.DataFrame]:
    v = d["vulnerability"].to_numpy()
    u = d["undernourishment"].to_numpy()
    n = len(d)
    sigma = np.maximum(SIGMA_FLOOR, CV_MEAS * u)

    buffers = np.empty((B_DRAWS, n))
    slopes = np.empty(B_DRAWS)
    intercepts = np.empty(B_DRAWS)
    r2s = np.empty(B_DRAWS)

    for b in range(B_DRAWS):
        idx = rng.integers(0, n, size=n)              # bootstrap resample
        b0, b1 = ols_line(v[idx], u[idx])
        slopes[b], intercepts[b] = b1, b0
        # R^2 of this bootstrap line on the resampled data
        pred_rs = b0 + b1 * v[idx]
        ss_res = np.sum((u[idx] - pred_rs) ** 2)
        ss_tot = np.sum((u[idx] - u[idx].mean()) ** 2)
        r2s[b] = 1 - ss_res / ss_tot if ss_tot > 0 else np.nan
        u_noisy = u + rng.normal(0.0, sigma)          # measurement error
        buffers[b] = (b0 + b1 * v) - u_noisy

    out = pd.DataFrame({
        "country": d["country"].to_numpy(),
        "iso3": d["iso3"].to_numpy(),
        "vulnerability": v,
        "undernourishment": u,
        "buffer_point": (intercepts.mean() + slopes.mean() * v) - u,
        "buffer_mc_mean": buffers.mean(axis=0),
        "buffer_ci_low": np.percentile(buffers, 5, axis=0),
        "buffer_ci_high": np.percentile(buffers, 95, axis=0),
        "prob_overperformer": (buffers > 0).mean(axis=0),
    }).sort_values("buffer_mc_mean", ascending=False).reset_index(drop=True)
    out.insert(0, "rank", out.index + 1)

    slope_df = pd.DataFrame({
        "quantity": ["slope_b1", "intercept_b0", "r_squared"],
        "mean": [slopes.mean(), intercepts.mean(), np.nanmean(r2s)],
        "ci_low": [np.percentile(slopes, 5), np.percentile(intercepts, 5), np.nanpercentile(r2s, 5)],
        "ci_high": [np.percentile(slopes, 95), np.percentile(intercepts, 95), np.nanpercentile(r2s, 95)],
    })
    return out.round(4), slope_df.round(4)


def simulate_collapse(B0: float, p: float, m_shock: float, rho: float,
                      sigma_noise: float, T: int, n_sims: int,
                      rng: np.random.Generator) -> dict:
    """Monte Carlo of the buffer process; return collapse statistics."""
    shape_k = 2.0                       # Gamma shape; scale set so mean = m_shock
    scale = m_shock / shape_k
    B = np.full(n_sims, B0, dtype=float)
    target = B0
    ever_neg_10 = np.zeros(n_sims, dtype=bool)
    ever_neg_20 = np.zeros(n_sims, dtype=bool)
    years_neg = np.zeros(n_sims, dtype=int)
    min_buffer = np.full(n_sims, B0, dtype=float)

    for t in range(1, T + 1):
        hit = rng.random(n_sims) < p
        shock = np.where(hit, rng.gamma(shape_k, scale, size=n_sims), 0.0)
        B = B + rho * (target - B) - shock + rng.normal(0.0, sigma_noise, size=n_sims)
        min_buffer = np.minimum(min_buffer, B)
        years_neg += (B < 0).astype(int)
        if t == 10:
            ever_neg_10 = min_buffer < 0
    ever_neg_20 = min_buffer < 0

    return {
        "B0": B0, "p_shock": p, "mean_shock_pp": m_shock, "recovery_rho": rho,
        "P_collapse_within_10y": ever_neg_10.mean(),
        "P_collapse_within_20y": ever_neg_20.mean(),
        "expected_years_negative_of_20": years_neg.mean(),
        "buffer_p05_year20": np.percentile(B, 5),
        "buffer_median_year20": np.percentile(B, 50),
    }


def part_b_collapse(B0: float, rng: np.random.Generator) -> pd.DataFrame:
    T, n_sims = 20, 20_000
    scenarios = {
        "baseline": dict(p=0.20, m_shock=4.0, rho=0.25, sigma_noise=0.8),
        "resilience_investment": dict(p=0.20, m_shock=2.4, rho=0.40, sigma_noise=0.8),
    }
    rows = []
    for name, par in scenarios.items():
        res = simulate_collapse(B0=B0, T=T, n_sims=n_sims, rng=rng, **par)
        res = {"scenario": name, **res}
        rows.append(res)
    return pd.DataFrame(rows).round(4)


def main() -> int:
    rng = np.random.default_rng(SEED)
    wb, backbone = load_world_bank_backbone()
    cs = cross_section_2022(wb, backbone)
    names = pd.read_csv(CV_VULN, low_memory=False)[["ISO3", "Name"]].rename(
        columns={"ISO3": "iso3", "Name": "country"})
    cs = cs.merge(names, on="iso3", how="left")
    d = cs.dropna(subset=["undernourishment", "vulnerability"]).copy()
    print(f"Monte Carlo on N = {len(d)} countries, {B_DRAWS:,} draws, seed {SEED}\n")

    # ---- Part A ----
    buf, slope = part_a_buffer_uncertainty(d, rng)
    print("=== MODEL 1 LINE: bootstrap uncertainty (90% intervals) ===")
    print(slope.to_string(index=False))

    robust_over = buf[buf["prob_overperformer"] >= 0.90]
    robust_under = buf[buf["prob_overperformer"] <= 0.10]
    ambiguous = buf[(buf["prob_overperformer"] > 0.10) & (buf["prob_overperformer"] < 0.90)]
    print(f"\nRobust over-performers  (P>0.90): {len(robust_over)}")
    print(f"Robust under-performers (P<0.10): {len(robust_under)}")
    print(f"Statistically ambiguous          : {len(ambiguous)}")

    print("\nTop 10 by buffer (with 90% CI and P(overperformer)):")
    show = buf.head(10)[["rank", "country", "buffer_mc_mean", "buffer_ci_low",
                         "buffer_ci_high", "prob_overperformer"]]
    print(show.to_string(index=False))
    print("\nBottom 8:")
    print(buf.tail(8)[["rank", "country", "buffer_mc_mean", "buffer_ci_low",
                       "buffer_ci_high", "prob_overperformer"]].to_string(index=False))

    for iso in ["BGD", "SEN", "VNM", "NER", "HTI", "KEN"]:
        r = buf[buf.iso3 == iso]
        if len(r):
            r = r.iloc[0]
            print(f"  {r['country']:12s} buffer {r['buffer_mc_mean']:+5.1f} "
                  f"[{r['buffer_ci_low']:+5.1f}, {r['buffer_ci_high']:+5.1f}], "
                  f"P(over)={r['prob_overperformer']:.2f}")

    buf.to_csv(PAPER / "output" / "global_mc_buffer_uncertainty.csv", index=False)
    slope.to_csv(PAPER / "output" / "global_mc_slope_distribution.csv", index=False)

    # ---- Part B ----
    bgd = buf[buf.iso3 == "BGD"]
    B0 = float(bgd["buffer_mc_mean"].iloc[0]) if len(bgd) else 9.0
    print(f"\n=== BUFFER-COLLAPSE MONTE CARLO (Bangladesh, B0={B0:.1f}) ===")
    coll = part_b_collapse(B0, rng)
    print(coll.to_string(index=False))
    coll.to_csv(PAPER / "output" / "global_mc_collapse_dynamics.csv", index=False)

    print("\nWritten: global_mc_buffer_uncertainty.csv, global_mc_slope_distribution.csv, "
          "global_mc_collapse_dynamics.csv")
    return 0


if __name__ == "__main__":
    sys.exit(main())
