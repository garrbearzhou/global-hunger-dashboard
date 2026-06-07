# Global statistical models 1–4: methodology and results

This document records **design choices**, **identification logic**, and **interpretation** for the four baseline models supporting the global “adaptation buffer” paper. Numbers below come from a reproducible run of `scripts/global_models_1_to_4.py` on the project’s local extracts (ND-GAIN, FAO Food Security, World Bank, EM-DAT, ACLED).

---

## 1. Data construction (shared across models)

### 1.1 Outcome: prevalence of undernourishment

- **Source:** FAO Food Security Indicators, Item **210041** (*Prevalence of undernourishment (%), 3-year average*), from `Food_Security_Data_E_All_Data_NOFLAG.csv`.
- **Top-coding:** Reported values **&lt;2.5** are set to **2.5**, FAO’s conventional lower bound for censored estimates.
- **Wide-file column convention:** In this extract, single-year columns such as `Y2022` are often empty. Published values sit in **paired** columns `Y{start}{end}` for a **three-year window ending in `end`**. Example: `Y20202022` is the window ending in 2022; `Y20222024` is the headline **2022–2024** vintage used in short FAOSTAT tables.

### 1.2 Exposure: climate vulnerability

- **Source:** ND-GAIN composite **vulnerability** from `vulnerability/vulnerability.csv` (Notre Dame Global Adaptation Initiative).
- **Scale:** Approximately 0–1, **higher = more vulnerable**.

### 1.3 Country key and sample

- **ISO3** links FAO area names to World Bank `iso3c` (sovereign list; regional aggregates dropped).
- **Cross-section sample:** All countries with **non-missing** undernourishment (headline column below) **and** 2022 vulnerability.
- **Latest run:** **N = 143** for Model 1 (vulnerability-only complete cases). **N = 139** for Models 2 and 4 where all regressors must be non-missing.

### 1.4 Temporal alignment (cross-section)

| Variable | Calendar / reporting choice | Rationale |
|----------|------------------------------|-----------|
| ND-GAIN vulnerability | **2022** annual index | Matches the year used in the Bangladesh case study graphs and Master_Sheet vulnerability column. |
| FAO undernourishment | Column **`Y20222024`** (2022–2024 average), with fallback to **`Y20202022`** if missing | Aligns with the **headline FAO vintage** in the short FAOSTAT extract used for `Master_Sheet` (e.g. Bangladesh **10.4%**). |

**Caveat:** Vulnerability is pinned to **2022** while prevalence is a **2022–2024** average. This is a **modest stagger** in timing; sensitivity checks could use `Y20202022` for both a stricter 2022-end window or harmonize both to the latest overlapping year.

### 1.5 Covariates (Models 2 and 4)

| Variable | Source | Year / window | Role |
|----------|--------|-----------------|------|
| `ln_gdp_pcap` | World Bank `NY.GDP.PCAP.CD` (column `gdp_GDP.PCAP.CD`) | 2022 (calendar) | Classic control for income level; log reduces leverage of rich outliers. |
| `rural_pct` | World Bank `SP.RUR.TOTL.ZS` | 2022 | Structural agrarian share / market access proxy. |
| `disaster_count` | EM-DAT `Number of Disasters` | **Sum 2013–2022** | Coarse physical shock exposure (same window as `scripts/build_master_sheet.R`). |
| `ln1_fatalities` | `log(1 + fatalities_avg_3yr)` from `data/processed/acled_conflict_data.csv` | ACLED-processed snapshot | Skewed conflict intensity; `log1p` keeps zeros in sample. |
| `readiness` (Model 4 only) | ND-GAIN readiness, **2022** | Adaptive **capacity**; excluded from Model 2 to limit collinearity with vulnerability and keep M2 interpretable as “hunger on V + structural/shock controls.” |

*Reason readiness is in Model 4 but not Model 2:* Model 2 focuses on **economic structure and violence/disasters** as alternative explanations for the raw V–hunger correlation. Readiness is conceptually closer to **the buffer story** (capacity to beat the climate-only benchmark) and is reserved for Model 4. You may add readiness to Model 2 in a robustness table if desired.

### 1.6 Standard errors

- **Models 1, 2, 4:** OLS with **heteroskedasticity-robust (HC1)** covariance. Cross-country residuals are unlikely to be homoskedastic.
- **Model 3:** **Two-way fixed effects** with **cluster-robust** standard errors **by country** (default for serial correlation within panels).

### 1.7 Plain-English workflow (what each step does)

Use this as a direct methodology script when you present your process.

1. **Pick one hunger measure for everyone.**  
   I use FAO undernourishment (%) so every country is on the same outcome scale.

2. **Clean special FAO values like `<2.5`.**  
   I convert them to 2.5 so the model can read them as numbers.

3. **Match country names across datasets.**  
   I use ISO3 country codes so ND-GAIN, FAO, World Bank, EM-DAT, and ACLED all refer to the same country rows.

4. **Choose the same time window across variables.**  
   For cross-section models, I pair ND-GAIN 2022 with the FAO 2022-2024 published prevalence window.  
   For panel models, I use 2002-2023 where both ND-GAIN and FAO are available.

5. **Build Model 1 (baseline line of best fit).**  
   I regress hunger on climate vulnerability only.  
   This gives the basic climate-hunger relationship and a first R² benchmark.

6. **Build Model 2 (add controls).**  
   I add GDP, rural share, disasters, and conflict to see whether vulnerability still matters after accounting for major country differences.

7. **Build Model 3 (within-country over time).**  
   I run a two-way fixed-effects panel model so the estimate comes from changes inside each country over years, not just rich-vs-poor country differences.

8. **Create the adaptation buffer from Model 1.**  
   For each country, I compute:  
   **predicted hunger from climate model - actual hunger**.  
   Positive means the country performs better than climate vulnerability alone would predict.

9. **Build Model 4 (explain the buffer).**  
   I regress the buffer on readiness and structural variables to test what is associated with outperforming the climate-only benchmark.

10. **Use robust/clustered errors and report uncertainty.**  
    I use HC1 or country-clustered errors so p-values and confidence intervals are more reliable under real-world noisy data.

11. **Interpret conservatively (association, not automatic causation).**  
    I explain coefficients as statistical associations and explicitly note limits from omitted variables and measurement issues.

12. **Run robustness checks.**  
    I test alternative windows/specifications to see whether the core conclusions stay similar.

---

## 2. Model 1 — Cross-sectional OLS (baseline)

### 2.1 Specification

\[
\text{PoU}_i = \beta_0 + \beta_1 V_i + \varepsilon_i
\]

- **PoU:** prevalence of undernourishment (%).  
- **V:** ND-GAIN vulnerability (2022).

### 2.2 Reasoning

- Provides a **transparent benchmark**: how much cross-country dispersion in hunger aligns with a **single** climate-exposure index.
- **OLS** is the appropriate linear least-squares estimator under mean-zero errors; **robust SE** addresses unequal variance across countries.
- **Not causal:** omitted variables (income, institutions, conflict) that load on both V and PoU will bias \(\beta_1\).

### 2.3 Results (latest run, N = 143)

| | Coefficient | Robust SE | Interpretation |
|--|------------|-----------|----------------|
| const | **−20.04** | 2.59 | Predicted PoU when V=0 (extrapolation outside support; not literal). |
| vulnerability | **69.42** | 7.12 | **+1 unit** (0–1 scale) in V associated with **~69 pp** higher PoU on average. **0.1** index points ≈ **6.9 pp** higher PoU. |
| **R²** | **0.423** | | Vulnerability alone explains **~42%** of the cross-country variance in PoU (vs **~48%** in the Bangladesh competition draft — difference is sample and exact FAO/ND-GAIN vintage). |

**Plain language:** Countries with higher ND-GAIN vulnerability scores tend to report much higher undernourishment. A large share of cross-country differences is statistically aligned with this single index, but many other factors also matter (see Model 2).

**Worked example (Bangladesh):** \(V \approx 0.569\) ⇒ predicted PoU \(\approx -20.04 + 69.42 \times 0.569 \approx 19.5\%\). Actual headline PoU **10.4%** ⇒ **adaptation buffer** \(\approx 19.5 - 10.4 \approx 9.1\) percentage points (consistent in spirit with the case-study narrative).

---

## 3. Model 2 — Multivariate OLS

### 3.1 Specification

\[
\text{PoU}_i = \beta_0 + \beta_1 V_i + \beta_2 \ln(\text{GDPpc})_i + \beta_3 \text{rural}_i + \beta_4 \text{disasters}_i + \beta_5 \ln(1+\text{fatalities})_i + \varepsilon_i
\]

### 3.2 Reasoning

- **Goal:** Ask whether **V still matters** after observable **income, structure, disasters, and conflict**.
- **Logs on GDP:** standard in cross-country work; coefficients are **elasticities in spirit** (semi-elasticity for PoU in levels).
- **Disasters / ACLED:** crude **shock** proxies; measurement error likely **attenuates** coefficients toward zero.

### 3.3 Results (latest run, N = 139)

| Variable | Coefficient | Robust SE | p-value | Notes |
|----------|-------------|-----------|---------|-------|
| vulnerability | **40.07** | 11.48 | &lt;0.001 | **Smaller than Model 1 (69.4)** → part of the raw V–hunger correlation co-moves with controls. |
| ln_gdp_pcap | **−2.84** | 1.04 | 0.006 | **Higher GDP per capita** associated with **lower** PoU, conditional on V and other covariates. |
| rural_pct | −0.047 | 0.045 | 0.29 | Not significant at 5%; sign can reflect multiple structural channels. |
| disaster_count | 0.12 | 0.25 | 0.63 | Noisy; EM-DAT reporting varies by capacity. |
| ln1_fatalities | 0.065 | 0.31 | 0.83 | Weak linear signal in this specification. |
| **R²** | **0.464** | | | Modest gain vs Model 1; joint explanatory power still dominated by V + income. |

**Plain language:** Climate vulnerability remains **economically and statistically important** after conditioning on income and simple shock proxies. **Wealth** is a strong correlate of lower hunger. Disaster and ACLED aggregates do not add clear linear signal here (good candidate for **robustness** with alternative conflict windows or intensity measures).

**Condition number warning:** Statsmodels flags a large condition number — driven mainly by scaling / correlation among predictors. **Robustness:** re-run with standardized regressors or drop redundant terms to confirm sign stability.

---

## 4. Model 3 — Two-way fixed effects panel

### 4.1 Specification

\[
\text{PoU}_{it} = \alpha_i + \gamma_t + \beta V_{it} + \delta \ln(\text{GDPpc})_{it} + u_{it}
\]

- **\(i\):** country; **\(t\):** year.
- **\(\alpha_i\):** country fixed effects (time-invariant confounders).  
- **\(\gamma_t\):** year fixed effects (global shocks, common trends).

### 4.2 Panel construction

- **Years:** 2002–2023 (overlap ND-GAIN annual columns and FAO windows `Y{t-2}{t}`).
- **Merge:** Inner join on `(iso3, year)` where PoU, V, and WB GDPpc exist.
- **Latest run:** **3,072** country–year rows; **144** countries; **22** years (unbalanced).

### 4.3 Reasoning

- Identifies off **within-country** changes in V and PoU, purging **fixed** country traits and **common** year shocks.
- **Clustered SE** respects **serial correlation** within countries.
- **Still not automatic causality:** policies or shocks that move V and PoU together within countries remain confounders.

### 4.4 Results (latest run)

| Variable | Coef. | Clustered SE | p-value | Interpretation |
|----------|-------|--------------|---------|----------------|
| vulnerability | **35.10** | 26.12 | **0.18** | **Not significant at 5%** after two-way FE + ln GDP: within-country co-movement of V and PoU is **noisy** once trends are absorbed. |
| ln_gdp_pcap | **−5.48** | 0.94 | &lt;0.001 | Within-country years with **higher** GDPpc align with **lower** PoU. |

**Plain language:** **Income dynamics** inside countries line up clearly with hunger outcomes. The **within-country** association between **vulnerability and PoU is positive but imprecise** in this specification — a useful **honest** result: cross-sectional gradients (Models 1–2) need not replicate cleanly in **short** within-country variation of smoothed indices. **Extensions:** longer spans, lags of V, or regional time trends.

---

## 5. Model 4 — Adaptation buffer (determinants)

### 5.1 Definition

Using **Model 1** fitted values \(\hat{y}_i = \hat\beta_0 + \hat\beta_1 V_i\):

\[
\text{buffer}_i = \hat{y}_i - \text{PoU}_i
\]

- **Positive buffer:** actual undernourishment is **below** the climate-only benchmark (**better** than the simple model predicts).

### 5.2 Specification

\[
\text{buffer}_i = \gamma_0 + \gamma_1 \ln(\text{GDPpc})_i + \gamma_2 \text{readiness}_i + \gamma_3 \text{rural}_i + \gamma_4 \text{disasters}_i + \gamma_5 \ln(1+\text{fatalities})_i + \eta_i
\]

### 5.3 Reasoning

- **Do not include \(V\)** on the right-hand side: it enters \(\hat{y}\) linearly in Model 1; adding \(V\) creates **mechanical collinearity** with the constructed buffer.
- This is a **descriptive decomposition** of who **beats** the climate-only line, not a causal structural equation.

### 5.4 Results (latest run, N = 139)

| Variable | Coefficient | p-value | Notes |
|----------|-------------|---------|-------|
| ln_gdp_pcap | 0.41 | 0.71 | No linear signal at 5%. |
| readiness | **13.35** | **0.12** | **Large positive** coefficient: higher readiness tends to align with **larger** buffers, but **not significant at 5%** with this N and covariate set. |
| rural_pct | 0.065 | 0.13 | Suggestive positive link to buffer (interpret with care). |
| disaster_count | −0.055 | 0.83 | — |
| ln1_fatalities | 0.049 | 0.87 | — |
| **R²** | **0.057** | | Low — most buffer variation is **not** explained by this linear menu. |

**Plain language:** Observable correlates **do not sharply explain** who beats the climate-only benchmark in this parsimonious spec. **Readiness** is the **most substantively interesting** positive coefficient (adaptive capacity ↔ outperforming the benchmark) but needs **wider covariates** (e.g. aid, agricultural productivity, trade) for a publishable Model 4 — as planned in the global paper outline.

---

## 6. Reproducibility

```bash
cd "/Users/27zhou/Documents/Research Project"
pip install -r scripts/requirements-global-models.txt
python3 scripts/global_models_1_to_4.py
```

**Outputs:**

- `output/global_models_1_4_tables.csv` — combined coefficient table.  
- `output/global_models_panel_sample.csv` — panel used for Model 3.

---

## 7. Suggested robustness checks (next steps)

1. **Cross-section FAO:** Replace `Y20222024` with `Y20202022` (window ending 2022) to tighten alignment with 2022 ND-GAIN.  
2. **Model 2:** Add **readiness** and/or **TFP** when a clean global panel is merged.  
3. **Model 3:** Try **lagged** V, or **region × year** FE.  
4. **Model 4:** Enrich with **ODA**, **government effectiveness**, **cereal yields** — all named in `DATA_COLLECTION_RECOMMENDATIONS.md`.

---

*Document generated to accompany `scripts/global_models_1_to_4.py`. Re-run the script after data updates; refresh numbers in Section 2.3–5.4 if coefficients change materially.*
