# Global models — results log

This file is the **results companion** to the methodology write-up. After each analysis run, paste updated coefficients and refresh the **What this means** paragraphs so they match the new numbers.

| Document | Role |
|----------|------|
| `docs/global_models_1_4_methodology.md` | Why each model is specified the way it is (design choices, data, limitations). |
| **This file** | What the estimates **are** and how to **interpret** them for the paper. |
| `scripts/global_models_1_to_4.py` | Reproduces Models **1–4**; writes `output/global_models_1_4_tables.csv`. |

**Last updated:** 2026-04-02 (Models 1–4 reflect the pipeline run documented in `global_models_1_4_methodology.md`. Models 5–7 are placeholders until those analyses are implemented.)

---

## Model 1 — Cross-sectional OLS (vulnerability → undernourishment)

### Results

| Quantity | Value |
|----------|--------|
| Sample size | **N = 143** countries |
| Dependent variable | FAO prevalence of undernourishment (%), Item 210041 (`Y20222024` vintage) |
| Key regressor | ND-GAIN composite vulnerability, **2022** |
| Intercept | **−20.04** (robust SE 2.59) |
| Vulnerability (β₁) | **69.42** (robust SE 7.12) |
| **R²** | **0.423** |
| Standard errors | Heteroskedasticity-robust (HC1) |

### What this means

- **Direction and size:** A **higher** climate-vulnerability score is strongly associated with **higher** undernourishment. Moving the index by **0.1** (on a 0–1 scale) lines up with roughly **7 percentage points** higher PoU in this linear fit.
- **Explanatory power:** Vulnerability **alone** explains a little over **42%** of cross-country variation in undernourishment — a strong bivariate pattern, but **not** the whole story.
- **Caution:** This is a **snapshot across countries**, not proof that vulnerability *causes* hunger. Richer, more peaceful countries might differ on both V and PoU for reasons the model does not include.

---

## Model 2 — Multivariate OLS (vulnerability + controls)

### Results

| Quantity | Value |
|----------|--------|
| Sample size | **N = 139** countries (complete cases on all regressors) |
| Controls | ln(GDP per capita), rural %, disaster count (2013–2022), ln(1 + ACLED avg fatalities) |
| Vulnerability (β₁) | **40.07** (robust SE 11.48), **p &lt; 0.001** |
| ln(GDP per capita) | **−2.84** (robust SE 1.04), **p = 0.006** |
| Rural % | −0.047 (0.045), p = 0.29 |
| Disaster count | 0.12 (0.25), p = 0.63 |
| ln(1 + fatalities) | 0.065 (0.31), p = 0.83 |
| **R²** | **0.464** |
| Standard errors | HC1 |

### What this means

- **Vulnerability still matters:** After controlling for income, rurality, and crude shock proxies, the partial association of vulnerability with hunger remains **large and statistically significant**. The coefficient **drops** from Model 1 (**~69**) to **~40**, which suggests part of the **raw** cross-country correlation between V and hunger lines up with **development and other observables** — but not all of it.
- **Income:** Higher GDP per capita is associated with **lower** undernourishment **holding vulnerability (and the other controls) fixed** — the expected development gradient.
- **Disasters and conflict (this spec):** In this linear form, **disaster counts** and **ACLED fatalities** do not add clear precision. That does **not** prove shocks are irrelevant; it may reflect **measurement noise**, **nonlinear effects**, or **better variables** (e.g. conflict intensity coded differently, aid flows).
- **Reporting note:** Statsmodels warned a **high condition number** — worth a robustness check with **standardized** regressors or a slightly smaller regressor set.

---

## Model 3 — Two-way fixed effects panel (within-country over time)

### Results

| Quantity | Value |
|----------|--------|
| Specification | PoU ~ vulnerability + ln(GDPpc), **country FE + year FE** |
| Sample | **3,072** country–year observations; **144** countries; **22** years (2002–2023 overlap); unbalanced |
| Vulnerability | **35.10** (clustered SE 26.12), **p ≈ 0.18** |
| ln(GDP per capita) | **−5.48** (clustered SE 0.94), **p &lt; 0.001** |
| Standard errors | Clustered by country |

### What this means

- **Within-country story:** Effects are identified from **changes within the same country over time**, after removing **permanent** country differences and **common** year shocks. That is a different question than Models 1–2.
- **Income inside countries:** Years with **higher** GDP per capita line up with **lower** undernourishment for the same country — a clear within-country pattern.
- **Vulnerability inside countries:** The coefficient on vulnerability is **positive** (higher V years ↔ higher PoU years) but **not statistically significant at 5%** here — the estimate is **noisy** once two-way FE and clustering are applied. That is an **honest** finding: **cross-sectional** gradients do not automatically reproduce as **sharp within-country** slopes when both indices are slow-moving and smoothed.
- **Next steps for the paper:** Try **lags** of vulnerability, **longer** windows, or **region × year** effects; discuss as **robustness**, not as failure of the idea.

---

## Model 4 — Determinants of the adaptation buffer (residual-based)

### Definition used

\[
\text{buffer}_i = \hat{y}_i - \text{PoU}_i
\]

where \(\hat{y}_i\) is the **Model 1** fitted value (climate-only prediction). **Larger buffer ⇒ actual hunger is lower than the climate-only benchmark** (“beating the prediction”).

### Results

| Quantity | Value |
|----------|--------|
| Sample size | **N = 139** |
| Regressors | ln(GDPpc), ND-GAIN readiness, rural %, disaster count, ln(1 + fatalities) |
| ln(GDP per capita) | 0.41 (robust SE 1.09), p ≈ 0.71 |
| Readiness | **13.35** (8.69), p ≈ **0.12** |
| Rural % | 0.065 (0.043), p ≈ 0.13 |
| Disaster count | −0.055 (0.25), p ≈ 0.83 |
| ln(1 + fatalities) | 0.049 (0.31), p ≈ 0.87 |
| **R²** | **0.057** |
| Standard errors | HC1 |

### What this means

- **Low R²:** This set of variables explains only a **small fraction** of who beats the climate-only line. Most buffer variation is **not** captured by this simple linear menu — expected if buffers reflect **policy, institutions, aid, agricultural history**, etc.
- **Readiness (substantive):** The **largest** coefficient is **positive**: countries with **higher** ND-GAIN readiness tend to have **larger** buffers, consistent with “capacity helps you outperform the benchmark.” It is **not** significant at 5% with this N and specification — treat as **hypothesis-generating**, not definitive.
- **Do not over-interpret nulls:** Null results on GDP here do **not** contradict Model 2; the buffer is a **nonlinear transform** of Model 1’s prediction and actual outcome, and collinearity patterns differ.

---

## Model 5 — Constrained optimization (Lagrangian / KKT) — *pending*

### Results

*(To fill after you implement the global or stylized allocation problem: optimal budgets \(x_i\), shadow price \(\lambda\), constraint multipliers \(\mu\), and which policies sit at zero.)*

| Quantity | Value |
|----------|--------|
| Objective | |
| Constraints | |
| Optimal allocation summary | |
| Shadow prices | |

### What this means

*(Explain: marginal value of budget; cost of political floors; which interventions the optimum excludes and why — tie to complementary slackness.)*

---

## Model 6 — PCA + clustering (resilience typologies) — *pending*

### Results

*(To fill: number of components retained, variance explained, cluster sizes, example country lists per cluster.)*

| Quantity | Value |
|----------|--------|
| Features used in X | |
| Components (k) | |
| Variance explained | |
| Clusters | |

### What this means

*(Explain: what each component “looks like” in plain language; what distinguishes clusters; how that supports policy grouping — e.g. “high V, high buffer” vs “high V, negative buffer.”)*

---

## Model 7 — Ridge / Lasso / Elastic Net (buffer prediction) — *pending*

### Results

*(To fill: chosen λ via cross-validation, test metrics RMSE/MAE, non-zero coefficients for Lasso.)*

| Quantity | Value |
|----------|--------|
| Outcome | |
| Penalty | |
| CV metric | |
| Test RMSE / MAE | |
| Key nonzero predictors | |

### What this means

*(Explain: out-of-sample predictive performance; which predictors survive shrinkage; humility about causality — prediction ≠ causal effect.)*

---

## How to refresh this document

1. Run `python3 scripts/global_models_1_to_4.py` from the project root.  
2. Open `output/global_models_1_4_tables.csv` and copy coefficients, SEs, p-values, and N into Models **1–4** above.  
3. Update the **Last updated** line and adjust **What this means** if the story changes (e.g. sign flips after a spec change).  
4. When Models **5–7** exist, replace the *pending* blocks with outputs from those scripts.
