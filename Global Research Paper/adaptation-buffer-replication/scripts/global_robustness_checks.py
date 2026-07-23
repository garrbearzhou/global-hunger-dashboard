#!/usr/bin/env python3
"""
Robustness checks for the global adaptation-buffer paper (section 4.9).

R1. FAO window alignment: Model 1 with PoU window 2020-2022 (strict 2022 end)
    instead of headline 2022-2024.
R2. Alternative vulnerability indices for Model 1:
      - WRI 2025 vulnerability component (0-100 -> /100)
      - Global Data Lab climate vulnerability index, national 2022 (/100)
      - ND-GAIN exposure sub-index (2022)
R3. Alternative outcome: WHO child stunting (latest country estimate) on
    ND-GAIN vulnerability.
R4. Model 2 with standardized (z-scored) regressors - sign stability.
R5. Buffer ranking excluding small states (population < 1M).

Output: output/global_robustness_summary.csv + printed tables.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm
from statsmodels.regression.linear_model import OLS

PAPER = Path(__file__).resolve().parents[1]  # repo root
PROJECT = PAPER
sys.path.insert(0, str(PAPER / "scripts"))

from global_models_1_to_4 import (  # noqa: E402
    CV_VULN,
    FAO_WIDE,
    country_to_iso3,
    cross_section_2022,
    fao_wide_column_for_end_year,
    load_world_bank_backbone,
    parse_fao_pct,
)

RESULTS: list[dict] = []


def record(check: str, spec: str, term: str, fit, n: int, note: str = "") -> None:
    RESULTS.append({
        "check": check, "spec": spec, "term": term,
        "coef": float(fit.params[term]), "se": float(fit.bse[term]),
        "pvalue": float(fit.pvalues[term]),
        "r2": float(getattr(fit, "rsquared", np.nan)), "n": n, "note": note,
    })


def fit_m1(df: pd.DataFrame, yvar: str, xvar: str):
    d = df.dropna(subset=[yvar, xvar])
    f = OLS(d[yvar], sm.add_constant(d[xvar])).fit(cov_type="HC1")
    return f, len(d)


def main() -> int:
    wb, backbone = load_world_bank_backbone()
    cs = cross_section_2022(wb, backbone)
    names = pd.read_csv(CV_VULN, low_memory=False)[["ISO3", "Name"]].rename(
        columns={"ISO3": "iso3", "Name": "country"})
    cs = cs.merge(names, on="iso3", how="left")
    c2i = country_to_iso3(wb, backbone)

    # ---------------- R1: FAO window 2020-2022 ----------------
    fao = pd.read_csv(FAO_WIDE, low_memory=False)
    rows = fao[fao["Item Code"].astype(str) == "210041"]
    col = fao_wide_column_for_end_year(2022)
    alt = []
    for _, r in rows.iterrows():
        iso = c2i.get(str(r["Area"]).strip())
        if iso is None:
            continue
        v = parse_fao_pct(r.get(col, np.nan))
        if pd.notna(v):
            alt.append({"iso3": iso, "pou_2022w": v})
    cs = cs.merge(pd.DataFrame(alt).drop_duplicates("iso3"), on="iso3", how="left")
    f, n = fit_m1(cs, "pou_2022w", "vulnerability")
    record("R1_fao_window", "M1, PoU window 2020-2022", "vulnerability", f, n)
    print(f"R1  M1 with PoU 2020-2022 window: beta={f.params['vulnerability']:.2f} "
          f"(SE {f.bse['vulnerability']:.2f}), R2={f.rsquared:.3f}, N={n}")

    # ---------------- R2: alternative vulnerability indices ----------------
    wri = pd.read_excel(PROJECT / "data/raw/wri/WorldRiskIndex-2025.xlsx")
    wri = wri.rename(columns={"ISO3": "iso3"})
    wri["wri_vuln"] = pd.to_numeric(wri["Vulnerability"], errors="coerce") / 100
    wri["wri_index"] = pd.to_numeric(wri["WorldRiskIndex"], errors="coerce") / 100
    cs = cs.merge(wri[["iso3", "wri_vuln", "wri_index"]], on="iso3", how="left")
    for var, label in [("wri_vuln", "WRI 2025 vulnerability component"),
                       ("wri_index", "WRI 2025 composite index")]:
        f, n = fit_m1(cs, "undernourishment", var)
        record("R2_alt_vulnerability", f"M1, {label}", var, f, n)
        print(f"R2  {label}: beta={f.params[var]:.2f} (SE {f.bse[var]:.2f}), "
              f"R2={f.rsquared:.3f}, N={n}")

    gdl = pd.read_csv(PROJECT / "data/raw/global_data_lab/climate/climate vunerability index.csv")
    gdl = gdl[gdl["Level"] == "National"][["ISO_Code", "2022"]].rename(
        columns={"ISO_Code": "iso3", "2022": "gdl_vuln"})
    gdl["gdl_vuln"] = pd.to_numeric(gdl["gdl_vuln"], errors="coerce") / 100
    cs = cs.merge(gdl.drop_duplicates("iso3"), on="iso3", how="left")
    f, n = fit_m1(cs, "undernourishment", "gdl_vuln")
    record("R2_alt_vulnerability", "M1, GDL climate vulnerability 2022", "gdl_vuln", f, n)
    print(f"R2  GDL vulnerability: beta={f.params['gdl_vuln']:.2f} "
          f"(SE {f.bse['gdl_vuln']:.2f}), R2={f.rsquared:.3f}, N={n}")

    expo = pd.read_csv(PROJECT / "data/raw/climate vulnerability/cv/vulnerability/exposure.csv")
    expo = expo[["ISO3", "2022"]].rename(columns={"ISO3": "iso3", "2022": "ndg_exposure"})
    expo["ndg_exposure"] = pd.to_numeric(expo["ndg_exposure"], errors="coerce")
    cs = cs.merge(expo.drop_duplicates("iso3"), on="iso3", how="left")
    f, n = fit_m1(cs, "undernourishment", "ndg_exposure")
    record("R2_alt_vulnerability", "M1, ND-GAIN exposure sub-index", "ndg_exposure", f, n)
    print(f"R2  ND-GAIN exposure only: beta={f.params['ndg_exposure']:.2f} "
          f"(SE {f.bse['ndg_exposure']:.2f}), R2={f.rsquared:.3f}, N={n}")

    # ---------------- R3: WHO stunting outcome ----------------
    who = pd.read_csv(PROJECT / "data/raw/who/child_stunting_data.csv", low_memory=False)
    who = who[(who.DIM_GEO_CODE_TYPE == "COUNTRY") & (who.DIM_SEX == "TOTAL")]
    who = who.sort_values("DIM_TIME").groupby("GEO_NAME_SHORT").tail(1)
    fixes = {"United States of America": "United States", "Viet Nam": "Vietnam",
             "Russian Federation": "Russian Federation", "Republic of Korea": "Korea, Rep.",
             "Iran (Islamic Republic of)": "Iran, Islamic Rep.", "Egypt": "Egypt, Arab Rep.",
             "Democratic Republic of the Congo": "Congo, Dem. Rep.",
             "United Republic of Tanzania": "Tanzania", "Syrian Arab Republic": "Syrian Arab Republic",
             "Venezuela (Bolivarian Republic of)": "Venezuela, RB", "Yemen": "Yemen, Rep."}
    who["wb_name"] = who["GEO_NAME_SHORT"].replace(fixes)
    who["iso3"] = who["wb_name"].map(c2i)
    st = who.dropna(subset=["iso3"])[["iso3", "RATE_PER_100_N", "DIM_TIME"]].rename(
        columns={"RATE_PER_100_N": "stunting"})
    cs = cs.merge(st[["iso3", "stunting"]].drop_duplicates("iso3"), on="iso3", how="left")
    f, n = fit_m1(cs, "stunting", "vulnerability")
    record("R3_alt_outcome", "Stunting (latest) on ND-GAIN V", "vulnerability", f, n)
    print(f"R3  Stunting on V: beta={f.params['vulnerability']:.2f} "
          f"(SE {f.bse['vulnerability']:.2f}), R2={f.rsquared:.3f}, N={n}")

    # ---------------- R4: standardized Model 2 ----------------
    m2vars = ["vulnerability", "ln_gdp_pcap", "rural_pct", "disaster_count", "ln1_fatalities"]
    d2 = cs.dropna(subset=["undernourishment"] + m2vars).copy()
    Z = (d2[m2vars] - d2[m2vars].mean()) / d2[m2vars].std()
    fz = OLS(d2["undernourishment"], sm.add_constant(Z)).fit(cov_type="HC1")
    print(f"R4  Standardized M2 (N={len(d2)}, cond={np.linalg.cond(sm.add_constant(Z)):.1f}):")
    for t in m2vars:
        record("R4_standardized_M2", "M2 z-scored regressors", t, fz, len(d2),
               note="beta per 1 SD")
        print(f"      {t:16s} beta={fz.params[t]:+.2f} (p={fz.pvalues[t]:.3f})")

    # ---------------- R5: buffer excluding small states ----------------
    from global_models_1_to_4 import wb_latest
    wb22 = wb_latest(wb, {"pop_POP.TOTL": "population"})
    cs = cs.merge(wb22, on="iso3", how="left")
    big = cs[(cs["population"] >= 1e6)].dropna(subset=["undernourishment", "vulnerability"]).copy()
    fb = OLS(big["undernourishment"], sm.add_constant(big["vulnerability"])).fit(cov_type="HC1")
    record("R5_no_small_states", "M1, population >= 1M", "vulnerability", fb, len(big))
    big["buffer"] = fb.fittedvalues - big["undernourishment"]
    big = big.sort_values("buffer", ascending=False)
    print(f"R5  M1 excl. small states: beta={fb.params['vulnerability']:.2f}, "
          f"R2={fb.rsquared:.3f}, N={len(big)}")
    print("      Top 10 buffers: " + ", ".join(
        f"{r.country} ({r.buffer:+.1f})" for r in big.head(10).itertuples()))
    big[["country", "iso3", "vulnerability", "undernourishment", "buffer"]].round(3).to_csv(
        PAPER / "output" / "global_buffer_rankings_pop1m.csv", index=False)

    out = pd.DataFrame(RESULTS).round(4)
    out.to_csv(PAPER / "output" / "global_robustness_summary.csv", index=False)
    print(f"\nWritten: output/global_robustness_summary.csv ({len(out)} rows)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
