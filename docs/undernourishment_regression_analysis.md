# Undernourishment and vulnerability inputs: regression analysis

**Generated:** 2026-04-10 22:01

## What you need to know for the dashboard (summary)

### Are any predictors “statistically significant” in the multivariate models?

- **Model with all 12 predictors (n = 15 complete countries):** **No.** Every predictor has **p ≥ 0.05** in this classical OLS output. The specification is also **under-powered**: 12 predictors on only 15 observations leave very few degrees of freedom, so **do not interpret this block** as evidence for or against individual drivers.

- **Model with 11 predictors, GRFC IPC phase excluded (n = 45):** **2** predictor(s) with **p < 0.05**: `water_per_capita`, `displaced_pct`.  **`stunting_rate`** is **borderline** (**p ≈ 0.0579**): not significant at strict α = 0.05. Coefficients are **partial** associations (not causal).

- **Univariate models:** **None** of the single-predictor regressions reach **p < 0.05** at conventional levels; the smallest p is **0.1697** (`avg_import_share`). Crude linear associations with FAO undernourishment are **weak** in this cross-section by classical tests.

### What this means for your vulnerability dashboard (actionable)

1. **Do not drop formula variables** based on these regressions. The dashboard score is a **structured composite** (thresholds, caps, multiple dimensions). These OLS models explain **FAO undernourishment %** only, not your full 0–100 score — alignment was for **diagnostic** insight, not for automatic variable selection.
2. **A sparse multivariate sample** (here, n = 15 with all 12 predictors) is **not** reliable for testing individual coefficients; treat that table as **illustrative only**.
3. **The n = 45 multivariate model** has **adjusted R² ≈ 0.149**. If individual predictors (e.g. water, displacement) show partial linear associations with PoU in this merge, use that as a **hypothesis** for narrative or future work (logs, robust SE, regions), **not** as proof that other factors “don’t matter.”
4. **For communication:** You can say that multivariate regressions on merged cross-sectional inputs leave **most variation in FAO undernourishment unexplained** and that **statistical significance depends strongly on sample size and specification** — consistent with hunger being multi-causal and imperfectly captured by any single linear model.

---

## Purpose

This note reports **ordinary least squares (OLS)** regressions with **FAO prevalence of undernourishment (%)** as the outcome and **each raw input** that feeds the dashboard hunger vulnerability formula as a predictor (plus a **multivariate** model with all predictors jointly). **No variables were removed from the vulnerability formula** — this is evidence for interpretation only.

## Data and sample

- **Unit of analysis:** one row per country after `distinct(country)` on the same `latest_summary` object built in `app.R`.
- **Countries with non-missing FAO undernourishment:** 203.
- **Univariate models:** each uses **all countries with non-missing outcome and that predictor** (sample size **n** differs by variable due to missing data).
- **Multivariate (all 12 predictors):** complete cases **n = 15**.
- **Multivariate (11 predictors, excluding sparse `grfc_ipc_phase`):** complete cases **n = 45** — *preferred for interpretation* when the 12-predictor sample is tiny.

## Methodology

### Outcome

- **Dependent variable:** `undernourishment_rate` — FAO prevalence of undernourishment (%) for the latest merged year in `latest_summary`.

### Predictors (aligned with the formula)

Each predictor below corresponds to an input used in the scoring rules in `app.R` (poverty, GDP thresholds, life expectancy, stunting, climate index, conflict buckets, historical/IPC-related outbreak logic, trade dependency, food supply, water stress, displacement share). Categorical conflict is coded as **ordinal 0–4** (none, low, medium, high, very high). The outbreak indicator uses **`mho_for_reg`** (0/1, NA→0 for regression only).

### Plain-language vulnerability scoring rules (no abbreviations)

The dashboard vulnerability score adds points from 12 components. Higher points mean higher vulnerability. The maximum total is 100.

1. **Undernourishment (maximum 25 points):**  
   Take the percentage of people who are undernourished and multiply by 0.25, then cap at 25.  
   If undernourishment data are missing, use the poverty percentage in the same way.
2. **Poverty (maximum 8 points):**  
   Take the poverty percentage and multiply by 0.16, then cap at 8.  
   Poverty comes from the World Bank $1.90 line or, when needed, the Our World in Data $3 line.
3. **Income per person (maximum 7 points):**  
   If gross domestic product per person is below $1,000, add 7 points;  
   below $3,000, add 5 points; below $10,000, add 3 points; below $20,000, add 1 point.
4. **Life expectancy (maximum 5 points):**  
   If life expectancy is under 50 years, add 5 points; under 60 years, add 4 points; under 70 years, add 2 points.
5. **Child stunting (maximum 5 points):**  
   Take the child stunting percentage and multiply by 0.05, then cap at 5.
6. **Climate vulnerability (maximum 10 points):**  
   If the climate vulnerability index is at least 60, add 3 points;  
   at least 70, add 7 points; at least 80, add 10 points.
7. **Conflict intensity (maximum 10 points):**  
   If there is active conflict: very high intensity adds 10 points, high adds 7, medium adds 4, and low adds 2.
8. **Major hunger crises and food security phase (maximum 15 points):**  
   Add 15 points if the country had a major hunger crisis in the 21st century, or is in food security phase 4 or higher.  
   Add 8 points if it is in food security phase 3.
9. **Food import dependency (maximum 5 points):**  
   Points increase by threshold levels of average food import share (50%, 30%, and 20%).
10. **Food supply (maximum 5 points):**  
    Points increase when daily food supply per person is below 2,400, below 2,200, and below 2,000 calories.
11. **Water stress (maximum 5 points):**  
    Points increase when renewable water per person is below 1,700, below 1,000, and below 500 cubic meters per year.
12. **Displacement (maximum 5 points):**  
    Points are based on refugees and internally displaced people, using either share of population thresholds or absolute-size thresholds.

### Models

1. **Univariate OLS:** for each predictor *X*, estimate *Undernourishment = β₀ + β₁ X + ε*. Report **β₁**, **heteroskedasticity-robust** inference is *not* shown here (NHST is classical OLS); for policy conclusions consider **robust SE** in a follow-up.
2. **Standardized coefficient (univariate):** same model after **z-scoring** both sides (approximately the correlation when univariate); use **only for ranking relative linear association scale**, not causal effect size.
3. **Multivariate OLS:** all predictors entered **simultaneously** on the complete-case subset — coefficients are **partial** associations holding others **linearly** constant (subject to multicollinearity).

### Missing outbreak flag (regression coding only)

The column `mho_for_reg` equals `major_hunger_outbreak_21st` with **NA treated as FALSE** so every country has a defined 0/1 for OLS. **The dashboard vulnerability formula is unchanged** — this affects only these regressions.

### Limitations

- **Cross-section:** not causal; omitted variables and reverse causality are likely.
- **Missingness:** different **n** per univariate model; multivariate **n** can drop sharply.
- **Functional form:** linearity assumed; GDP and displacement are often skewed (log specifications are a natural robustness check).
- **Conflict and IPC** are coarse; **stunting** and **undernourishment** are both nutrition-related — expect **positive correlation** and **multicollinearity** in the full model.

## Results: univariate regressions

| Predictor | n | β (raw units) | SE | p-value | R² | β (standardized) |
|-----------|---:|---------------:|----:|---------:|-----:|------------------:|
| `poverty_display` | 155 | 0.0262 | 0.0319 | 0.4129 | 0.004 | 0.0662 |
| `gdp_per_capita` | 188 | -0.0000 | 0.0000 | 0.2629 | 0.007 | -0.0821 |
| `life_expectancy` | 203 | -0.0928 | 0.0818 | 0.2582 | 0.006 | -0.0797 |
| `stunting_rate` | 148 | -0.0068 | 0.0557 | 0.9033 | 0.000 | -0.0101 |
| `climate_vulnerability_index` | 164 | 4.0440 | 7.3319 | 0.5820 | 0.002 | 0.0433 |
| `conflict_ord` | 156 | 0.3511 | 0.5777 | 0.5443 | 0.002 | 0.0489 |
| `mho_for_reg` | 203 | 2.1422 | 2.1680 | 0.3243 | 0.005 | 0.0695 |
| `grfc_ipc_phase` | 55 | -0.3273 | 1.0708 | 0.7611 | 0.002 | -0.0419 |
| `avg_import_share` | 61 | 12.7917 | 9.2023 | 0.1697 | 0.032 | 0.1781 |
| `food_supply_kcal` | 171 | -0.0005 | 0.0013 | 0.6856 | 0.001 | -0.0312 |
| `water_per_capita` | 163 | 0.0000 | 0.0000 | 0.6810 | 0.001 | 0.0324 |
| `displaced_pct` | 155 | 0.0967 | 0.1947 | 0.6201 | 0.002 | 0.0401 |

Full table (CSV): `docs/regression_univariate_undernourishment.csv`.

### Short interpretation (univariate, descriptive)

Larger **|β (standardized)|** suggests a stronger **linear** association with undernourishment in the cross-section **ignoring other variables**. Statistical significance is sensitive to **n** and **linearity**.

### Ranking (univariate standardized |β|)

The five predictors with the largest absolute standardized slopes (linear association scale only) are: `avg_import_share`, `gdp_per_capita`, `life_expectancy`, `mho_for_reg`, `poverty_display`. This does **not** imply causality and can change when other variables are controlled (see multivariate section).

## Results: multivariate regression (all 12 predictors, including GRFC IPC phase)

**n = 15**. **Adjusted R² = 0.033**.

| Term | Estimate | SE | t | p-value |
|------|----------|----|----|---------|
| `(Intercept)` | 95.5931 | 180.2707 | 0.5303 | 0.6489 |
| `poverty_display` | 0.0034 | 0.5121 | 0.0066 | 0.9953 |
| `gdp_per_capita` | -0.0018 | 0.0065 | -0.2790 | 0.8065 |
| `life_expectancy` | -1.0364 | 0.9306 | -1.1137 | 0.3813 |
| `stunting_rate` | -0.3803 | 0.5300 | -0.7175 | 0.5475 |
| `climate_vulnerability_index` | -25.4764 | 280.7996 | -0.0907 | 0.9360 |
| `conflict_ord` | -2.2366 | 12.0189 | -0.1861 | 0.8695 |
| `mho_for_reg` | 1.4889 | 16.3309 | 0.0912 | 0.9357 |
| `grfc_ipc_phase` | -0.1220 | 4.3432 | -0.0281 | 0.9801 |
| `avg_import_share` | 23.3172 | 54.2986 | 0.4294 | 0.7094 |
| `food_supply_kcal` | 0.0046 | 0.0144 | 0.3182 | 0.7805 |
| `water_per_capita` | 0.0011 | 0.0006 | 2.0404 | 0.1781 |
| `displaced_pct` | 1.1949 | 4.3521 | 0.2746 | 0.8094 |

CSV: `docs/regression_multivariate_undernourishment_all12.csv`.

## Results: multivariate regression (11 predictors, excluding GRFC IPC phase)

**n = 45**. **Adjusted R² = 0.149**.

| Term | Estimate | SE | t | p-value |
|------|----------|----|----|---------|
| `(Intercept)` | 61.0129 | 51.8146 | 1.1775 | 0.2474 |
| `poverty_display` | -0.0323 | 0.1816 | -0.1776 | 0.8602 |
| `gdp_per_capita` | -0.0001 | 0.0001 | -1.5035 | 0.1422 |
| `life_expectancy` | -0.1523 | 0.5186 | -0.2936 | 0.7709 |
| `stunting_rate` | -0.3540 | 0.1802 | -1.9645 | 0.0579 |
| `climate_vulnerability_index` | -37.4961 | 34.8291 | -1.0766 | 0.2895 |
| `conflict_ord` | 1.8666 | 1.4941 | 1.2493 | 0.2203 |
| `mho_for_reg` | 8.1576 | 10.0869 | 0.8087 | 0.4245 |
| `avg_import_share` | 0.8974 | 13.7660 | 0.0652 | 0.9484 |
| `food_supply_kcal` | -0.0060 | 0.0045 | -1.3410 | 0.1891 |
| `water_per_capita` | 0.0003 | 0.0001 | 2.2424 | 0.0318 |
| `displaced_pct` | -0.9293 | 0.3846 | -2.4160 | 0.0214 |

GRFC IPC phase has limited country coverage in this merge; excluding it recovers a usable joint-sample size. CSV: `docs/regression_multivariate_undernourishment_no_ipc.csv`.

## Suggested robustness checks (not run here)

- Log-transform **gdp_per_capita**, **displaced_pct**, and possibly **water_per_capita**.
- **Heteroskedasticity-robust** (HC) standard errors.
- **Spatial** or **regional fixed effects** if treating countries as i.i.d. is implausible.

