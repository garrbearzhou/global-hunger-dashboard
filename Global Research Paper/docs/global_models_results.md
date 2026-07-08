# Global models — results log

This file is the **results companion** to the methodology write-up. After each analysis run, paste updated coefficients and refresh the **What this means** paragraphs so they match the new numbers.

| Document | Role |
|----------|------|
| `Global Research Paper/docs/global_models_1_4_methodology.md` | Why each model is specified the way it is (design choices, data, limitations). |
| **This file** | What the estimates **are** and how to **interpret** them for the paper. |
| `Global Research Paper/scripts/global_models_1_to_4.py` | Reproduces the OLS Models **1–3**; writes `Global Research Paper/output/global_models_1_4_tables.csv`. |
| `Global Research Paper/scripts/global_monte_carlo.py` | Reproduces the Monte Carlo Models **4–5**; writes `global_mc_*.csv`. |

**Last updated:** 2026-06-12 (Models 1–3 reflect the OLS pipeline documented in `global_models_1_4_methodology.md`. Models 4–5 are Monte Carlo simulations from `scripts/global_monte_carlo.py`. Robustness checks: `scripts/global_robustness_checks.py` → `output/global_robustness_summary.csv`. The paper now uses only OLS and Monte Carlo; the earlier optimization/PCA/regularized analyses are archived under `Global Research Paper/archive/`.)

---

## Model 1 — Cross-sectional OLS (vulnerability → undernourishment)

### Results

| Quantity | Value |
|----------|--------|
| Sample size | **N = 143** countries |
| Dependent variable | FAO prevalence of undernourishment (%), Item 210041 (`Y20222024` vintage) |
| Key regressor | ND-GAIN composite vulnerability, **2022** |
| Intercept | **−20.04** (SE 2.59) |
| Vulnerability (β₁) | **69.42** (SE 7.12) |
| **R²** | **0.423** |

### What this means

- **Direction and size:** A **higher** climate-vulnerability score is strongly associated with **higher** undernourishment. Moving the index by **0.1** (on a 0–1 scale) lines up with roughly **7 percentage points** higher PoU in this linear fit.
- **Explanatory power:** Vulnerability **alone** explains a little over **42%** of cross-country variation in undernourishment — a strong bivariate pattern, but **not** the whole story.
- **Caution:** This is a **snapshot across countries**, not proof that vulnerability *causes* hunger. Richer, more peaceful countries might differ on both V and PoU for reasons the model does not include.
- **Uncertainty:** Model 4's bootstrap gives a 90% interval of [58.3, 81.5] on β₁ and [0.34, 0.53] on R² — the gradient is precisely estimated.

---

## Model 2 — Multivariate OLS (vulnerability + controls)

### Results

| Quantity | Value |
|----------|--------|
| Sample size | **N = 139** countries (complete cases on all regressors) |
| Controls | ln(GDP per capita), rural %, disaster count (2013–2022), ln(1 + ACLED avg fatalities) |
| Vulnerability (β₁) | **40.07** (SE 11.48), **p &lt; 0.001** |
| ln(GDP per capita) | **−2.84** (SE 1.04), **p = 0.006** |
| Rural % | −0.047 (0.045), p = 0.29 |
| Disaster count | 0.12 (0.25), p = 0.63 |
| ln(1 + fatalities) | 0.065 (0.31), p = 0.83 |
| **R²** | **0.464** |

### What this means

- **Vulnerability still matters:** After controlling for income, rurality, and crude shock proxies, the partial association of vulnerability with hunger remains **large and statistically significant**. The coefficient **drops** from Model 1 (**~69**) to **~40**, which suggests part of the **raw** cross-country correlation between V and hunger lines up with **development and other observables** — but not all of it.
- **Income:** Higher GDP per capita is associated with **lower** undernourishment **holding vulnerability (and the other controls) fixed** — the expected development gradient.
- **Disasters and conflict (this spec):** In this linear form, **disaster counts** and **ACLED fatalities** do not add clear precision. That does **not** prove shocks are irrelevant; it may reflect **measurement noise**, **nonlinear effects**, or **better variables** (e.g. conflict intensity coded differently, aid flows).
- **Reporting note:** A standardized re-run (robustness R4) confirms the signs are stable and there is no collinearity problem.

---

## Model 3 — Determinants of the adaptation buffer (residual-based)

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
| ln(GDP per capita) | 0.41 (SE 1.09), p ≈ 0.71 |
| Readiness | **13.35** (8.69), p ≈ **0.12** |
| Rural % | 0.065 (0.043), p ≈ 0.13 |
| Disaster count | −0.055 (0.25), p ≈ 0.83 |
| ln(1 + fatalities) | 0.049 (0.31), p ≈ 0.87 |
| **R²** | **0.057** |

### What this means

- **Low R²:** This set of variables explains only a **small fraction** of who beats the climate-only line. Most buffer variation is **not** captured by this simple linear menu — expected if buffers reflect **policy, institutions, aid, agricultural history**, etc.
- **Readiness (substantive):** The **largest** coefficient is **positive**: countries with **higher** ND-GAIN readiness tend to have **larger** buffers, consistent with “capacity helps you outperform the benchmark.” It is **not** significant at 5% with this N and specification — treat as **hypothesis-generating**, not definitive.
- **Practical consequence:** because standard covariates barely predict the buffer, it must be **monitored directly** (recompute it each year), not inferred from country characteristics.

---

## Model 4 — Monte Carlo for buffer uncertainty (bootstrap + measurement error)

*Script: `scripts/global_monte_carlo.py`. Outputs: `output/global_mc_buffer_uncertainty.csv`, `output/global_mc_slope_distribution.csv`.*

### Method (plain version)

Repeat 20,000 times: (1) resample the 143 countries with replacement and re-fit the Model 1 line (the **bootstrap**); (2) add normal measurement noise to each reported PoU, SD = max(1.0, 0.10·PoU); (3) recompute every country's buffer. Summarize each country's 20,000 simulated buffers.

### Results

| Quantity | Value |
|----------|--------|
| Model 1 slope β₁ | mean **69.6**, 90% interval **[58.3, 81.5]** |
| Model 1 intercept | mean −20.1, 90% interval [−24.4, −16.0] |
| Model 1 R² | mean 0.43, 90% interval [0.34, 0.53] |
| Robust over-performers (P(buffer>0) ≥ 0.90) | **66 countries** |
| Statistically ambiguous (0.10–0.90) | 35 countries |
| Robust under-performers (P(buffer>0) ≤ 0.10) | **42 countries** |
| Bangladesh | buffer +9.1, 90% interval [+6.1, +12.1], P(over) = 1.00 |
| Senegal / Niger / Viet Nam | +12.1 / +11.2 / +7.1, all P(over) = 1.00 |
| Haiti / Kenya | −38.8 / −22.1, both P(over) = 0.00 |

### What this means

- **The benchmark line is precise:** the slope's 90% interval [58.3, 81.5] excludes zero by a wide margin — the gradient is not driven by a few countries.
- **The rankings are real, not noise:** nearly three-quarters of countries fall clearly into the over- or under-performer camp; only 35 sit close enough to the line that the sign of the buffer is genuinely uncertain.
- **Monte Carlo replaces formulas:** all of this uses only resampling and random draws — no robust/clustered standard-error machinery — so any reader can re-run it.

---

## Model 5 — Monte Carlo for buffer collapse dynamics

*Script: `scripts/global_monte_carlo.py`. Output: `output/global_mc_collapse_dynamics.csv`.*

### Method (plain version)

Simulate a single country's buffer over 20 years, 20,000 times: each year it recovers toward its target at rate ρ, takes small noise, and with probability p suffers a shock of random size (gamma, mean m). Compare a **baseline** (p = 0.20, m = 4.0 pp, ρ = 0.25) with a **resilience-investment** country (m = 2.4 pp, ρ = 0.40) facing the same shock probability. Start at the Bangladesh buffer B₀ ≈ +9.1.

### Results

| Scenario | P(collapse ≤ 10y) | P(collapse ≤ 20y) | Expected years underwater | Buffer yr 20 (5th pct / median) |
|----------|-------------------|-------------------|---------------------------|---------------------------------|
| Baseline | 21.6% | **41.3%** | 1.01 | −0.5 / +6.6 |
| Resilience investment | 2.0% | **4.4%** | 0.05 | +4.4 / +8.2 |

### What this means

- A healthy +9-point buffer is **not permanent**: under severe shocks and slow recovery it collapses below zero within 20 years 41% of the time (the Bangladesh-2007 scenario).
- **Defending the buffer works:** investments that cut shock damage ~40% and speed recovery drop the 20-year collapse probability to 4.4% — a tenfold reduction — for the **same** climate exposure.
- The policy payoff is in **absorptive and recovery capacity** (early warning, flood protection, storage, safety nets), not in lowering the hazard itself.

---

## How to refresh this document

1. Run `python3 scripts/global_models_1_to_4.py` and `python3 scripts/global_monte_carlo.py` from `Global Research Paper/`.  
2. Copy OLS coefficients from `output/global_models_1_4_tables.csv` into Models **1–3**, and Monte Carlo summaries from `output/global_mc_*.csv` into Models **4–5**.  
3. Update the **Last updated** line and adjust **What this means** if the story changes.
