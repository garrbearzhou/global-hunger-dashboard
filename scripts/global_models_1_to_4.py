#!/usr/bin/env python3
"""
Global adaptation-buffer statistical models (1–4).

Outputs:
  - Printed narrative: methodology reminders + result interpretation
  - output/global_models_1_4_tables.csv  (coefficient summaries)
  - output/global_models_panel_sample.csv (optional diagnostic row count)

Run from repository root:
  python3 scripts/global_models_1_to_4.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm
from linearmodels.panel import PanelOLS
from statsmodels.regression.linear_model import OLS

# -----------------------------------------------------------------------------
# Paths (run from project root)
# -----------------------------------------------------------------------------
ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
OUT = ROOT / "output"
OUT.mkdir(parents=True, exist_ok=True)

CV_VULN = RAW / "climate vulnerability" / "cv" / "vulnerability" / "vulnerability.csv"
CV_READ = RAW / "climate vulnerability" / "cv" / "readiness" / "readiness.csv"
FAO_WIDE = RAW / "fao" / "FAO_Data" / "Food_Security_Data_E_All_Data_NOFLAG.csv"
WB = RAW / "world_bank_data.csv"
EMDAT = RAW / "em_dat" / "em_dat_data.csv"
ACLED = ROOT / "data" / "processed" / "acled_conflict_data.csv"


# -----------------------------------------------------------------------------
# Methodology (embedded for maintainers; full prose in docs/global_models_1_4_methodology.md)
# -----------------------------------------------------------------------------
METHODOLOGY = """
================================================================================
MODEL 1 — Cross-sectional OLS (baseline climate → hunger)
================================================================================
Goal: Estimate how much of cross-country variation in undernourishment co-moves
with ND-GAIN climate vulnerability, holding nothing else constant.

Specification:
  undernourishment_i = β0 + β1 * vulnerability_i + ε_i

Choices:
  • Outcome: FAO prevalence of undernourishment (%), Item 210041. Values "<2.5"
    are coded as 2.5 (standard FAO reporting cap).
  • Exposure: ND-GAIN composite vulnerability, calendar year 2022, scale ~0–1
    (higher = more vulnerable), Notre Dame GAIN methodology.
  • FAO prevalence uses wide-file column Y20222024 (official 2022–2024 3-year
    average, same vintage as short FAOSTAT extract). ND-GAIN vulnerability uses
    the 2022 annual index — a deliberate one-year stagger, documented below.
  • Estimator: OLS with heteroskedasticity-robust (HC1) standard errors.
  • Interpretation: β1 is expected change in undernourishment (percentage points)
    for a one-unit increase in vulnerability index. R² measures linear share of
    cross-country variance explained by vulnerability alone.

Limitations: Ecological / cross-sectional; not causal. Omitted variables (income,
conflict) bias β1 if they correlate with both V and hunger.

================================================================================
MODEL 2 — Multivariate OLS (isolate vulnerability from key covariates)
================================================================================
Goal: Assess whether the vulnerability association survives conditioning on
observable structural and shock-related factors.

Specification:
  undernourishment_i = β0 + β1*V_i + β2*ln(GDPpc)_i + β3*rural_i
                       + β4*disasters_i + β5*ln(1+conflict_fatalities)_i + ε_i

Choices:
  • ln(GDP per capita): World Bank GDP.PCAP.CD, year 2022; log reduces leverage
    of high-income outliers and matches common growth/development specifications.
  • Rural %: WB RUR.TOTL.ZS — structural agrarian dependence / market access.
  • Disaster count: EM-DAT "Number of Disasters", sum 2013–2022 per country
    (same window as Master_Sheet build) — coarse shock exposure.
  • Conflict: log1p ACLED average fatalities (3-year) from processed file —
    strictly positive transform for skewed violence data.
  • Robust SE: HC1.

Interpretation: β1 is the "partial" association of vulnerability with hunger after
linearly controlling for the block above. If β1 shrinks vs Model 1, part of the
raw correlation is explained by economics / shocks.

================================================================================
MODEL 3 — Two-way fixed effects panel (within-country over time)
================================================================================
Goal: Remove time-invariant country confounders and common global shocks using
within-country variation in vulnerability and undernourishment over time.

Specification:
  y_it = α_i + γ_t + β * V_it + δ * ln(GDPpc)_it + u_it

Choices:
  • Panel: country × year. V from ND-GAIN annual columns 2002–2023. Undernutrition
    from FAO Item 210041 using columns Y{t-2}{t} (3-year window ending year t),
    e.g. Y20002002 → end year 2002 (standalone Y2002 cells are empty in this file).
  • Years 2002–2023: overlap with reliable ND-GAIN annual series and FAO columns.
  • Entity + time effects: α_i absorbs stable geography/institutions; γ_t absorbs
    global food-price or measurement trends.
  • ln(GDPpc)_it: time-varying control from World Bank panel.
  • Estimator: PanelOLS with clustered standard errors by country (serial
    correlation within i).

Interpretation: β is the within-country association of a change in V with a
change in y, purging permanent country differences and year-specific shocks common
to all countries. Not necessarily causal if within-country V trends correlate
with unobserved policies.

================================================================================
MODEL 4 — Determinants of the adaptation buffer (regression on residuals)
================================================================================
Concept: Define predicted hunger from Model 1 (vulnerability-only): ŷ_i = β̂0+β̂1*V_i.
Adaptation buffer (positive = better than climate-only benchmark):
  buffer_i = ŷ_i - undernourishment_i

Specification:
  buffer_i = γ0 + γ1*ln(GDPpc)_i + γ2*readiness_i + γ3*rural_i
             + γ4*disasters_i + γ5*ln(1+fatalities)_i + η_i

Choices:
  • We do NOT include V on the right-hand side: it is already in ŷ through
    Model 1; adding V creates strong collinearity with the constructed buffer.
  • Readiness: ND-GAIN readiness 2022 (capacity to absorb climate stress).
  • Same disaster and conflict measures as Model 2 for comparability.
  • Robust SE: HC1.

Interpretation: Positive γ on a covariate means countries with higher values of
that variable tend to *outperform* the climate-only hunger prediction (larger
buffer). This is descriptive: it highlights correlates of “beating the benchmark.”
================================================================================
"""


def log(msg: str = "") -> None:
    print(msg)


def parse_fao_pct(x) -> float | np.nan:
    if pd.isna(x) or x == "":
        return np.nan
    s = str(x).strip().replace("<", "")
    try:
        return float(s)
    except ValueError:
        return np.nan


def fao_wide_column_for_end_year(end_year: int) -> str:
    """
    FAO Food Security wide file uses 3-year prevalence columns Y{start}{end}
    (e.g. Y20002002 = window ending in 2002). No data in the standalone Y2002 column.
    """
    start = end_year - 2
    return f"Y{start:04d}{end_year:04d}"


def load_world_bank_backbone() -> tuple[pd.DataFrame, list[str]]:
    """Return WB panel and list of sovereign country names (exclude regions)."""
    # WB extract occasionally has ragged rows; skip bad lines (matches R col_character approach).
    wb = pd.read_csv(WB, low_memory=False, on_bad_lines="skip")
    wb["year"] = pd.to_numeric(wb["year"], errors="coerce")
    drop = {
        "World", "Total", "Africa", "Americas", "Europe", "Asia", "Oceania",
        "Arab World", "East Asia & Pacific", "Europe & Central Asia",
        "Latin America & Caribbean", "Middle East & North Africa",
        "North America", "Sub-Saharan Africa", "European Union",
        "High income", "Low income", "Middle income", "Not classified",
    }
    countries = wb.loc[~wb["country"].isin(drop) & wb["iso3c"].notna(), "country"].unique()
    countries = sorted(c for c in countries if isinstance(c, str) and c.strip())
    return wb, list(countries)


def country_to_iso3(wb: pd.DataFrame, backbone: list[str]) -> dict[str, str]:
    m = wb[wb["country"].isin(backbone) & wb["iso3c"].notna()][["country", "iso3c"]].drop_duplicates(
        subset=["country"], keep="first"
    )
    return dict(zip(m["country"], m["iso3c"]))


def load_ndgain_wide(path: Path, year_cols: list[str]) -> pd.DataFrame:
    df = pd.read_csv(path, low_memory=False)
    idc = "ISO3" if "ISO3" in df.columns else "iso3"
    use = [idc, "Name"] + [c for c in year_cols if c in df.columns]
    out = df[use].copy()
    out = out.rename(columns={idc: "iso3"})
    return out


def melt_ndgain(df: pd.DataFrame, value_name: str) -> pd.DataFrame:
    idv = ["iso3", "Name"]
    ycols = [c for c in df.columns if c not in idv]
    long = df.melt(id_vars=idv, value_vars=ycols, var_name="year", value_name=value_name)
    long["year"] = pd.to_numeric(long["year"], errors="coerce")
    long[value_name] = pd.to_numeric(long[value_name], errors="coerce")
    return long.dropna(subset=["year", value_name])


def load_fao_undernourishment_long(wb: pd.DataFrame, backbone: list[str], y0: int, y1: int) -> pd.DataFrame:
    fao = pd.read_csv(FAO_WIDE, low_memory=False)
    c2i = country_to_iso3(wb, backbone)
    rows = fao[fao["Item Code"].astype(str) == "210041"]
    if rows.empty:
        raise FileNotFoundError("FAO Item 210041 not found in Food_Security wide file.")
    out_rows = []
    for y in range(y0, y1 + 1):
        col = fao_wide_column_for_end_year(y)
        if col not in fao.columns:
            continue
        for _, r in rows.iterrows():
            cc = str(r["Area"]).strip()
            iso = c2i.get(cc)
            if iso is None:
                continue
            v = parse_fao_pct(r[col])
            if pd.notna(v):
                out_rows.append({"iso3": iso, "year": y, "undernourishment": v})
    return pd.DataFrame(out_rows)


def disaster_count_2013_2022(wb: pd.DataFrame, backbone: list[str]) -> pd.DataFrame:
    c2i = country_to_iso3(wb, backbone)
    em = pd.read_csv(EMDAT, low_memory=False)
    em["year"] = pd.to_numeric(em["year"], errors="coerce")
    sub = em[
        (em["indicator"] == "Number of Disasters")
        & em["year"].between(2013, 2022)
        & em["country"].notna()
    ].copy()
    sub["iso3"] = sub["country"].map(c2i)
    sub = sub.dropna(subset=["iso3"])
    sub["value"] = pd.to_numeric(sub["value"], errors="coerce")
    g = sub.groupby("iso3", as_index=False)["value"].sum()
    g = g.rename(columns={"value": "disaster_count"})
    return g


def cross_section_2022(wb: pd.DataFrame, backbone: list[str]) -> pd.DataFrame:
    c2i = country_to_iso3(wb, backbone)
    vuln = pd.read_csv(CV_VULN, low_memory=False)
    read = pd.read_csv(CV_READ, low_memory=False)
    iso_v = vuln[["ISO3", "2022"]].rename(columns={"ISO3": "iso3", "2022": "vulnerability"})
    iso_v["vulnerability"] = pd.to_numeric(iso_v["vulnerability"], errors="coerce")
    iso_r = read[["ISO3", "2022"]].rename(columns={"ISO3": "iso3", "2022": "readiness"})
    iso_r["readiness"] = pd.to_numeric(iso_r["readiness"], errors="coerce")

    fao = pd.read_csv(FAO_WIDE, low_memory=False)
    row = fao[fao["Item Code"].astype(str) == "210041"]
    # Headline FAO vintage 2022–2024 (matches short FAOSTAT extract / Master_Sheet); ND-GAIN V is 2022.
    headline_col = "Y20222024"
    out = []
    for _, r in row.iterrows():
        cc = str(r["Area"]).strip()
        iso = c2i.get(cc)
        if iso is None:
            continue
        u = parse_fao_pct(r.get(headline_col, np.nan))
        if pd.isna(u):
            u = parse_fao_pct(r.get(fao_wide_column_for_end_year(2022), np.nan))
        if pd.notna(u):
            out.append({"iso3": iso, "undernourishment": u})
    cs = pd.DataFrame(out).drop_duplicates(subset=["iso3"], keep="first")
    cs = cs.merge(iso_v, on="iso3", how="inner").merge(iso_r, on="iso3", how="left")

    wb22 = wb[wb["year"] == 2022][["iso3c", "gdp_GDP.PCAP.CD", "pop_RUR.TOTL.ZS"]].copy()
    wb22 = wb22.rename(
        columns={"iso3c": "iso3", "gdp_GDP.PCAP.CD": "gdp_pcap", "pop_RUR.TOTL.ZS": "rural_pct"}
    )
    wb22["gdp_pcap"] = pd.to_numeric(wb22["gdp_pcap"], errors="coerce")
    wb22["rural_pct"] = pd.to_numeric(wb22["rural_pct"], errors="coerce")
    cs = cs.merge(wb22, on="iso3", how="left")

    dct = disaster_count_2013_2022(wb, backbone)
    cs = cs.merge(dct, on="iso3", how="left")
    cs["disaster_count"] = cs["disaster_count"].fillna(0)

    if ACLED.exists():
        ac = pd.read_csv(ACLED, low_memory=False)
        ac["iso3"] = ac["country"].map(c2i)
        fatal = ac.dropna(subset=["iso3"])[["iso3", "fatalities_avg_3yr"]].copy()
        fatal["fatalities_avg_3yr"] = pd.to_numeric(fatal["fatalities_avg_3yr"], errors="coerce").fillna(0)
        cs = cs.merge(fatal, on="iso3", how="left")
        cs["fatalities_avg_3yr"] = cs["fatalities_avg_3yr"].fillna(0)
    else:
        cs["fatalities_avg_3yr"] = 0.0

    cs["ln_gdp_pcap"] = np.log(cs["gdp_pcap"].clip(lower=1))
    cs["ln1_fatalities"] = np.log1p(cs["fatalities_avg_3yr"])
    return cs


def build_panel(wb: pd.DataFrame, backbone: list[str], y0: int, y1: int) -> pd.DataFrame:
    c2i = country_to_iso3(wb, backbone)
    vuln_w = pd.read_csv(CV_VULN, low_memory=False)
    years = [str(y) for y in range(y0, y1 + 1)]
    vdf = vuln_w[["ISO3"] + [c for c in years if c in vuln_w.columns]].rename(columns={"ISO3": "iso3"})
    vlong = vdf.melt(id_vars=["iso3"], var_name="year", value_name="vulnerability")
    vlong["year"] = pd.to_numeric(vlong["year"], errors="coerce")
    vlong["vulnerability"] = pd.to_numeric(vlong["vulnerability"], errors="coerce")

    ulong = load_fao_undernourishment_long(wb, backbone, y0, y1)
    panel = ulong.merge(vlong, on=["iso3", "year"], how="inner")
    panel = panel[panel["year"].between(y0, y1)]

    wb_p = wb[["iso3c", "year", "gdp_GDP.PCAP.CD"]].copy()
    wb_p = wb_p.rename(columns={"iso3c": "iso3", "gdp_GDP.PCAP.CD": "gdp_pcap"})
    wb_p["gdp_pcap"] = pd.to_numeric(wb_p["gdp_pcap"], errors="coerce")
    wb_p["ln_gdp_pcap"] = np.log(wb_p["gdp_pcap"].clip(lower=1))
    panel = panel.merge(wb_p[["iso3", "year", "ln_gdp_pcap"]], on=["iso3", "year"], how="left")
    return panel.dropna(subset=["undernourishment", "vulnerability"])


def summarize_ols(name: str, model: OLS, fit) -> pd.DataFrame:
    rows = []
    for par in fit.params.index:
        rows.append(
            {
                "model": name,
                "term": par,
                "coef": fit.params[par],
                "std_err": fit.bse[par],
                "t": fit.tvalues[par],
                "pvalue": fit.pvalues[par],
                "ci_low": fit.conf_int().loc[par, 0],
                "ci_high": fit.conf_int().loc[par, 1],
                "n": int(fit.nobs),
                "r2": getattr(fit, "rsquared", np.nan),
                "r2_adj": getattr(fit, "rsquared_adj", np.nan),
            }
        )
    return pd.DataFrame(rows)


def main() -> int:
    log(METHODOLOGY)

    if not CV_VULN.exists():
        log(f"Missing {CV_VULN}")
        return 1

    wb, backbone = load_world_bank_backbone()
    cs = cross_section_2022(wb, backbone)

    # --- Model 1 ---
    d1 = cs.dropna(subset=["undernourishment", "vulnerability"]).copy()
    X1 = sm.add_constant(d1["vulnerability"])
    m1 = OLS(d1["undernourishment"], X1)
    f1 = m1.fit(cov_type="HC1")
    log("\n--- MODEL 1 RESULTS ---")
    log(f1.summary().as_text())
    log(f"\nInterpretation: A 0.1 increase in ND-GAIN vulnerability (~10 pp index) is associated with "
        f"approximately {0.1 * f1.params['vulnerability']:.2f} percentage points higher undernourishment, "
        f"holding nothing else constant. R²={f1.rsquared:.3f}: share of cross-country variance in "
        f"undernourishment linearly explained by vulnerability alone.")

    # --- Model 2 ---
    d2 = cs.dropna(
        subset=["undernourishment", "vulnerability", "ln_gdp_pcap", "rural_pct", "disaster_count", "ln1_fatalities"]
    ).copy()
    X2 = sm.add_constant(
        d2[
            [
                "vulnerability",
                "ln_gdp_pcap",
                "rural_pct",
                "disaster_count",
                "ln1_fatalities",
            ]
        ]
    )
    m2 = OLS(d2["undernourishment"], X2)
    f2 = m2.fit(cov_type="HC1")
    log("\n--- MODEL 2 RESULTS ---")
    log(f2.summary().as_text())
    log("\nInterpretation: Compare vulnerability coefficient to Model 1. A large shrinkage suggests "
        "part of the raw climate–hunger correlation aligns with income, rurality, disasters, or conflict. "
        "Signs: negative ln(GDPpc) → richer countries tend to have lower undernourishment; "
        "positive disasters/fatalities → more shock-prone places tend to show higher undernourishment.")

    # --- Model 3 ---
    panel = build_panel(wb, backbone, 2002, 2023)
    panel = panel.dropna(subset=["ln_gdp_pcap"])
    panel_idx = panel.set_index(["iso3", "year"])
    y_p = panel_idx["undernourishment"]
    X_p = panel_idx[["vulnerability", "ln_gdp_pcap"]]
    mod3 = PanelOLS(y_p, X_p, entity_effects=True, time_effects=True)
    f3 = mod3.fit(cov_type="clustered", cluster_entity=True)
    log("\n--- MODEL 3 RESULTS (two-way FE, clustered SE by country) ---")
    log(str(f3.summary))
    log("\nInterpretation: Coefficients are within-country (and within-year) associations. "
        "A positive β on vulnerability means years with higher national vulnerability scores line up "
        "with years of higher reported undernourishment for the same country, after stripping "
        "permanent country differences and global year shocks.")

    panel.to_csv(OUT / "global_models_panel_sample.csv", index=False)
    log(f"\nPanel rows written: {len(panel)} (diagnostic: {OUT / 'global_models_panel_sample.csv'})")

    # --- Model 4 ---
    pred = f1.predict(sm.add_constant(d1["vulnerability"]))
    buffer = pred.values - d1["undernourishment"].values
    d4 = d1.copy()
    d4["buffer"] = buffer
    d4 = d4.dropna(
        subset=["buffer", "ln_gdp_pcap", "readiness", "rural_pct", "disaster_count", "ln1_fatalities"]
    )
    X4 = sm.add_constant(
        d4[["ln_gdp_pcap", "readiness", "rural_pct", "disaster_count", "ln1_fatalities"]]
    )
    m4 = OLS(d4["buffer"], X4)
    f4 = m4.fit(cov_type="HC1")
    log("\n--- MODEL 4 RESULTS (adaptation buffer = climate-only predicted − actual) ---")
    log(f4.summary().as_text())
    log("\nInterpretation: Positive predicted buffer means actual undernourishment is *lower* than "
        "the climate-only benchmark (good). The regression explains which observables correlate with "
        "larger buffers. Example: positive readiness → countries with more adaptive capacity tend to "
        "outperform the vulnerability-only prediction.")

    tables = pd.concat(
        [
            summarize_ols("M1_baseline_vulnerability", m1, f1),
            summarize_ols("M2_multivariate", m2, f2),
            summarize_ols("M4_buffer_determinants", m4, f4),
        ],
        ignore_index=True,
    )
    # Panel: manual row for FE model
    fe_rows = []
    for par in f3.params.index:
        fe_rows.append(
            {
                "model": "M3_panel_twoway_FE",
                "term": par,
                "coef": f3.params[par],
                "std_err": f3.std_errors[par],
                "t": f3.tstats[par],
                "pvalue": f3.pvalues[par],
                "ci_low": np.nan,
                "ci_high": np.nan,
                "n": int(f3.nobs),
                "r2": f3.rsquared,
                "r2_adj": np.nan,
            }
        )
    tables = pd.concat([tables, pd.DataFrame(fe_rows)], ignore_index=True)
    tables.to_csv(OUT / "global_models_1_4_tables.csv", index=False)
    log(f"\nCoefficient tables: {OUT / 'global_models_1_4_tables.csv'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
