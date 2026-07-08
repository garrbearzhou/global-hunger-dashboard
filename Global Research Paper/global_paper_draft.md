# The Adaptation Buffer: Why Some Climate-Vulnerable Countries Avoid Hunger and Others Don't

**Working draft — v1.0 (June 2026)**

*Alternative title: Climate Vulnerability Does Not Equal Hunger: A Cross-Country Analysis of Adaptation Resilience*

> **Draft status.** All five models are implemented and every reported number comes from the reproducible pipeline: `Global Research Paper/scripts/global_models_1_to_4.py` (Models 1–3), `Global Research Paper/scripts/compute_buffer_rankings.py` (buffer table), `Global Research Paper/scripts/global_monte_carlo.py` (Models 4–5, the Monte Carlo simulations), and `Global Research Paper/scripts/global_robustness_checks.py` (§4.7). Every method used here stays within the toolkit of a student who has taken statistics, multivariable calculus, and linear algebra: ordinary least squares (a linear-algebra projection), and Monte Carlo simulation (repeated random sampling). Key academic references have been verified; remaining web-source entries are catalogued in `citations.md`. One data note: a few countries lack a clean 2022 row in the World Bank extract; the multivariate model (Model 2) and buffer-determinants model (Model 3) therefore use 139 complete cases, while the bivariate and Monte Carlo analyses use all 143.

---

## Abstract

Climate vulnerability is widely treated as a proxy for food insecurity, yet countries with nearly identical vulnerability scores report dramatically different rates of hunger. We introduce and formalize the **adaptation buffer**: the gap between a country's *predicted* prevalence of undernourishment — derived from a cross-country regression on climate vulnerability — and its *actual* prevalence. A positive buffer indicates a country outperforming its climate odds; a negative buffer indicates underperformance; a shrinking buffer is an early-warning signal of eroding resilience. Using ND-GAIN vulnerability and readiness indices, FAO undernourishment estimates, World Bank development indicators, EM-DAT disaster records, and ACLED conflict data for 143 countries, we estimate the buffer for every country and analyze its determinants and dynamics. Climate vulnerability alone explains 42% of cross-country variation in undernourishment, and its association survives controls for income, rurality, disasters, and conflict. But the residual variation — the buffer — is large (SD ≈ 7.5 percentage points, range −38.8 to +14.6) and only weakly explained by standard covariates (R² ≈ 0.06), with ND-GAIN readiness the most substantively promising correlate. Overperformers include Bangladesh, Senegal, and Vietnam; the largest underperformers are dominated by conflict-affected and governance-fragile states (Haiti, Syria, Madagascar). We use **Monte Carlo simulation** — repeated random sampling — to do two things conventional formulas cannot do transparently. First, by resampling the data thousands of times and adding realistic measurement noise to the hunger figures, we attach a confidence interval and an over-performance probability to every country's buffer: 66 of 143 countries are over-performers in at least 90% of simulations, and 42 are under-performers in at least 90%, so the rankings are not statistical noise. Second, we simulate the buffer forward year by year under random climate and conflict shocks: a Bangladesh-like buffer of +9 points has a 41% chance of collapsing below zero within twenty years under baseline shock conditions, but only a 4% chance once resilience investments shrink shock severity and speed recovery — a tenfold reduction that quantifies the value of defending a buffer. We argue the buffer is a measurable, trackable, policy-relevant metric: aid and adaptation finance should target not only highly vulnerable countries but countries whose buffers are shrinking. An appendix works through Bangladesh's national policy budget as a country-level allocation example.

*Keywords: climate adaptation, food security, undernourishment, ND-GAIN, vulnerability, resilience, regression, Monte Carlo simulation*

---

## 1. Introduction

Bangladesh and Afghanistan have similar ND-GAIN climate-vulnerability scores (0.57 and 0.59 on a 0–1 scale). If climate vulnerability translated directly into hunger, the two countries should report similar rates of undernourishment. They do not. Afghanistan's prevalence of undernourishment is 28.1%; Bangladesh's is 10.4% — nearly three times lower, in a low-lying delta exposed to cyclones, salinity intrusion, and some of the most severe projected climate impacts on Earth.

This pattern is not an isolated anomaly. Across 143 countries, climate vulnerability is strongly associated with undernourishment — it explains roughly 42% of cross-country variation. But the remaining 58% is not noise. Some highly vulnerable countries (Bangladesh, Senegal, Nepal, Vietnam) systematically report far less hunger than their vulnerability predicts, while others (Haiti, Syria, Madagascar, Kenya) report dramatically more. The gap between prediction and reality is structured, persistent, and — we argue — the single most policy-relevant quantity in the climate–hunger relationship.

We call this gap the **adaptation buffer**:

$$
\text{Buffer}_{c,t} \;=\; \widehat{U}_{c,t} - U_{c,t}
$$

where \(\widehat{U}_{c,t}\) is the undernourishment rate predicted from climate vulnerability alone and \(U_{c,t}\) is the observed rate. A positive buffer means a country is beating its climate odds — through some combination of agricultural progress, institutions, social protection, trade, and aid. A negative buffer means hunger exceeds what climate exposure alone would predict — typically because conflict, governance failure, or compounding shocks have destroyed the country's capacity to convert resources into food security. A *shrinking* buffer is a warning sign that resilience is eroding before hunger statistics spike.

The paper is organized around three research questions:

1. **What explains why some climate-vulnerable countries avoid hunger?** Which structural factors — income, agricultural productivity, readiness, conflict, disasters, trade, governance — are associated with overperformance after accounting for vulnerability?
2. **How stable is the adaptation buffer over time, and what causes it to collapse?** When do countries that once beat the prediction fall back toward or below it? Bangladesh's buffer collapse following the 2007–2009 cyclones, and its partial rebuilding by 2020, is the motivating prototype.
3. **Can the buffer be predicted — and therefore protected?** Can we flag countries whose buffers are shrinking and prioritize aid or policy intervention before hunger crises fully materialize?

**Contributions.** First, we define, measure, and publish the adaptation buffer for 143 countries — to our knowledge the first systematic cross-country quantification of the residual between climate-predicted and actual hunger as a named, trackable metric. Second, we provide a five-model analytical hierarchy built entirely from tools a student of statistics, multivariable calculus, and linear algebra already has: ordinary least squares (a linear-algebra projection), and Monte Carlo simulation (repeated random sampling). The simulations do real work — they put confidence intervals and over-performance probabilities on every country's buffer without relying on opaque standard-error formulas, and they model how a buffer collapses under random shocks. The whole pipeline is therefore auditable line by line. Third, we connect the global framework to country-level action: an appendix works through Bangladesh's policy budget as an allocation example, using the simple "fund a policy until its marginal return falls to the budget's marginal value" rule and a Monte Carlo shock simulation to show what defending a buffer costs and buys.

The rest of the paper proceeds as follows. Section 2 situates the buffer in the climate–food-security and adaptation-measurement literatures. Section 3 describes data and the model hierarchy. Section 4 presents results. Section 5 discusses policy implications, Section 6 states limitations, and Section 7 concludes.

---

## 2. Literature Review

### 2.1 Climate change and food security

A large literature establishes that climate change threatens food security through yield losses, extreme events, price volatility, and disrupted livelihoods (Wheeler & von Braun, 2013; IPCC AR6 WGII, 2022; Mbow et al., 2019). Crop-model and statistical studies project significant cereal yield declines in low-latitude agriculture under warming scenarios, with the burden concentrated in countries that already have high rates of undernourishment. The FAO's *State of Food Security and Nutrition in the World* reports have repeatedly identified climate extremes as one of three principal drivers of recent increases in global hunger, alongside conflict and economic downturns (FAO et al., 2024).

This literature, however, mostly treats exposure and outcome as tightly coupled: countries are ranked by vulnerability, and vulnerability rankings are read as hunger-risk rankings. Aid-allocation frameworks and adaptation-finance criteria frequently follow the same logic (e.g., allocation formulas weighting vulnerability indices). The empirical premise — that vulnerability maps cleanly onto outcomes — is rarely tested directly at the global scale.

### 2.2 Measuring vulnerability and adaptation

The ND-GAIN Country Index (Chen et al., 2015) is the most widely used composite measure of national climate vulnerability, aggregating exposure, sensitivity, and adaptive capacity across six life-supporting sectors (food, water, health, ecosystem services, human habitat, infrastructure), paired with a *readiness* index capturing economic, governance, and social capacity to deploy adaptation investment. Alternative composites include the World Risk Index and Global Data Lab vulnerability measures. All such indices face well-known aggregation critiques — weighting choices, indicator substitutability, and scale effects (Hinkel, 2011) — which we address through robustness checks with alternative indices.

A separate strand asks how to measure *adaptation itself*. Tracking studies document a persistent gap between adaptation planning and implementation (Ford et al., 2013; Berrang-Ford et al., 2021): most national adaptation is reported as policies and plans, with little systematic evidence about outcomes. Berrang-Ford et al.'s (2021) global stocktake concludes that documented adaptation is overwhelmingly incremental and that **outcome-based evidence of risk reduction is rare**. This is the measurement gap our metric addresses: the buffer is an *outcome-based, revealed-performance* measure of adaptation effectiveness — it captures what countries actually achieve relative to their climate burden, rather than what they plan.

### 2.3 Hunger measurement and its drivers

The FAO prevalence of undernourishment (PoU) is the SDG 2.1.1 indicator, estimated from food balance sheets, consumption distributions, and energy requirements (Cafiero et al., 2018). It is a modeled estimate with known limitations — smoothing across years, parametric distributional assumptions, and weak sensitivity to short-run shocks — motivating robustness checks against stunting (WHO) and acute food-insecurity measures (IPC Phase 3+; GRFC). Cross-country studies consistently find income the dominant correlate of undernourishment (Headey, 2013); conflict has emerged as the leading driver of acute food crises in recent years (FAO et al., 2024; von Grebmer et al., 2023), and climate–conflict interactions remain an active research frontier (Burke, Hsiang & Miguel, 2015).

### 2.4 The gap this paper fills

No prior study, to our knowledge, formalizes the *residual* between climate-predicted and actual hunger as a named metric, computes it globally, models its determinants and dynamics, and links it to formal resource-allocation mathematics. Residual-based performance analysis is standard in other fields — education's value-added models, health's risk-adjusted mortality — but has not been transplanted to climate–food-security analysis. The adaptation buffer does for national food-security performance what value-added does for schools: it benchmarks outcomes against circumstances, so that performance, not just exposure, becomes visible and trackable.

---

## 3. Data and Methods

### 3.1 Data sources and sample

| Source | Variables | Coverage |
|---|---|---|
| ND-GAIN (Notre Dame) | Composite climate vulnerability; readiness | 185 countries, 1995–2023, annual |
| FAO Food Security Indicators | Prevalence of undernourishment (PoU, %), Item 210041, 3-year averages | Global, 2000–2024 windows |
| World Bank WDI | GDP per capita (current US$), rural population share, governance | Global panel |
| EM-DAT | Disaster counts and damages | Global, event-level |
| ACLED | Conflict fatalities (3-year averages) | Global, processed extract |
| USDA ERS | Agricultural total factor productivity | Global (planned for Model 3 extension) |
| IPC/GRFC, WHO | Acute food insecurity; stunting | Robustness checks |
| World Risk Index, Global Data Lab | Alternative vulnerability indices | Robustness checks |

**Outcome.** FAO PoU (%), with FAO's censored "<2.5" values coded at 2.5. In the FAO wide file, published values sit in paired three-year window columns (`Y{start}{end}`); the cross-section uses the headline 2022–2024 vintage (fallback: window ending 2022).

**Exposure.** ND-GAIN composite vulnerability (0–1 scale; higher = more vulnerable), 2022 annual value. Countries are linked across datasets by ISO3 code; regional aggregates are dropped.

**Sample.** **N = 143** countries with non-missing PoU and vulnerability (139 complete cases for the multivariate models). The analysis is cross-sectional; the year-by-year dynamics that matter for monitoring (research question 2) are studied through simulation in Model 5 rather than through a historical panel regression.

**Timing caveat.** Vulnerability is pinned to calendar-2022 while PoU is a 2022–2024 average — a modest stagger; a robustness check re-runs with the 2020–2022 window for strict alignment.

### 3.2 The adaptation buffer: formal definition

Let \(V_c\) denote vulnerability and \(U_c\) observed PoU. From the baseline regression (Model 1) we obtain fitted values \(\widehat{U}_c = \hat\beta_0 + \hat\beta_1 V_c\). The adaptation buffer is

$$
B_c = \widehat{U}_c - U_c .
$$

Three properties make this construction useful. (i) **Comparability:** the buffer is denominated in percentage points of undernourishment for every country. (ii) **Benchmark transparency:** the benchmark is a single, published, reproducible bivariate regression — anyone can recompute it. (iii) **Trackability:** because the benchmark is just a formula, the buffer \(B_{c,t}\) can be recomputed each year as vulnerability and hunger figures update, turning it into a monitorable time series whose *changes* matter as much as its level. By construction the buffer averages zero across the estimation sample; it is a relative performance measure, not an absolute welfare measure.

### 3.3 Model hierarchy

The analysis proceeds through five models. The first three are ordinary least squares (OLS) — the standard least-squares regression, which is geometrically the projection of the outcome vector onto the space spanned by the predictors, and is solved by the normal equations \(X^\top X\,\hat\beta = X^\top y\). The last two are Monte Carlo simulations: we draw random samples many thousands of times and summarize the results. Nothing here goes beyond statistics, multivariable calculus, and linear algebra.

| Model | Method | Question |
|---|---|---|
| 1 | Cross-section OLS (bivariate) | How much hunger variation aligns with vulnerability alone? |
| 2 | Multivariate OLS | Does vulnerability survive controls for income, rurality, shocks, conflict? |
| 3 | Buffer-determinants OLS | What correlates with beating the climate-only benchmark? |
| 4 | Monte Carlo — buffer uncertainty | How confident are we in each country's buffer and ranking? |
| 5 | Monte Carlo — buffer collapse dynamics | How easily does a buffer collapse, and what protects it? |
| A | Bangladesh budget allocation | Country-level worked example (Appendix A) |

**Model 1 — Baseline cross-section.**

$$
U_c = \beta_0 + \beta_1 V_c + \varepsilon_c
$$

This is the benchmark that defines the buffer; it is deliberately sparse. We fit it by OLS and report the coefficients, \(R^2\), and standard errors. It is not causal: omitted variables that move both \(V\) and \(U\) would bias \(\beta_1\).

**Model 2 — Multivariate cross-section.**

$$
U_c = \beta_0 + \beta_1 V_c + \beta_2 \ln(\text{GDPpc}_c) + \beta_3 \text{Rural}_c + \beta_4 \text{Disasters}_c + \beta_5 \ln(1+\text{Fatalities}_c) + \varepsilon_c
$$

Controls: log GDP per capita (2022), rural population share (2022), EM-DAT disaster count summed 2013–2022, and log(1 + ACLED 3-year average fatalities). The question is whether the raw climate–hunger gradient survives conditioning on development and shock exposure.

**Model 3 — Buffer determinants.**

$$
B_c = \gamma_0 + \gamma_1 \ln(\text{GDPpc}_c) + \gamma_2 \text{Readiness}_c + \gamma_3 \text{Rural}_c + \gamma_4 \text{Disasters}_c + \gamma_5 \ln(1+\text{Fatalities}_c) + \eta_c
$$

Here the buffer itself is the outcome. Vulnerability is *excluded* from the right-hand side because it already enters \(\widehat{U}\) linearly in Model 1; including it would create mechanical collinearity with the constructed dependent variable. ND-GAIN readiness — adaptive capacity — enters here rather than in Model 2 because it is conceptually part of the buffer story (the capacity to beat the climate-only benchmark) rather than an alternative explanation of the raw gradient. This is a descriptive decomposition, not a causal structural equation.

**Model 4 — Monte Carlo for buffer uncertainty.** A country's buffer is a point estimate built on two shaky inputs: the fitted line (which depends on the particular 143 countries we observe) and the reported hunger rate (which the FAO itself describes as a modeled, uncertain estimate). Rather than invoke specialized standard-error formulas, we quantify the uncertainty by direct simulation, which any reader can follow and re-run. We repeat the following \(B = 20{,}000\) times:

1. **Resample the countries** (the *bootstrap*): draw 143 countries at random *with replacement* from the 143 we have, and re-fit Model 1 on that resample to get a new line \((\beta_0^{(b)}, \beta_1^{(b)})\). Different resamples give slightly different lines; the spread of those lines is the uncertainty in the benchmark.
2. **Add measurement noise to the hunger figures:** replace each country's reported PoU \(U_c\) with \(U_c + e_c\), where \(e_c\) is drawn from a normal distribution with standard deviation \(\sigma_c = \max(1.0,\ 0.10\,U_c)\) — i.e. a 10% coefficient of variation with a 1-percentage-point floor. (This is a transparent, stated assumption, since the FAO does not publish country-level standard errors in this extract.)
3. **Recompute every country's buffer** \(B_c^{(b)} = (\beta_0^{(b)} + \beta_1^{(b)} V_c) - (U_c + e_c)\).

Collecting the 20,000 simulated values for each country gives a whole *distribution* of plausible buffers. We report each country's average simulated buffer, its 90% interval (the 5th to 95th percentile), and — the most useful number — the **probability that the country is a genuine over-performer**, \(P(B_c > 0)\), estimated as the fraction of simulations in which its buffer is positive. The same simulation delivers a 90% interval for the Model 1 slope without any formula.

**Model 5 — Monte Carlo for buffer collapse dynamics.** Research question 2 asks how stable a buffer is and what makes it collapse. We answer with a simple stochastic simulation of a single country's buffer over \(T = 20\) years, calibrated to Bangladesh (starting buffer \(B_0 \approx 9\)). Each year the buffer drifts back toward its long-run target and is occasionally knocked down by a climate or conflict shock:

$$
B_{t+1} = B_t + \rho\,(B^\star - B_t) \; - \; S_t \; + \; \nu_t .
$$

Here \(\rho\) is the annual recovery rate (the fraction of the gap to the target \(B^\star\) that is closed each year), \(\nu_t\) is small year-to-year noise, and \(S_t\) is the shock: with probability \(p\) a shock strikes with a random size drawn from a gamma distribution of mean \(m\) (and \(S_t = 0\) otherwise). We run 20,000 simulated 20-year histories and read off the **probability the buffer ever falls below zero** within 10 and 20 years, the expected number of years spent underwater, and the buffer's 5th-percentile value at year 20. We then compare two countries that face the *same* climate exposure but differ in resilience: a **baseline** country (\(p=0.20\), mean shock \(m=4.0\) pp, slow recovery \(\rho=0.25\)) and one that has made **resilience investments** that blunt shocks and speed recovery (\(m=2.4\) pp, \(\rho=0.40\)). The contrast shows, in probability terms, what "defending the buffer" is worth. All shock and recovery parameters are explicitly stated assumptions; the point is the *mechanism* and the *comparison*, not a precise forecast for any one country.

### 3.4 Inference and reproducibility

Models 1–3 report OLS coefficients, \(R^2\), and standard errors; for the buffer — the paper's central object — we prefer the Monte Carlo confidence intervals of Model 4, because the bootstrap makes no distributional assumption and is fully transparent. All models are implemented in Python (`numpy`, `pandas`, `statsmodels`). The full pipeline — data construction, estimation, buffer rankings, the Monte Carlo simulations, and all robustness checks — is reproducible from `Global Research Paper/scripts/` (`global_models_1_to_4.py`, `compute_buffer_rankings.py`, `global_monte_carlo.py`, `global_robustness_checks.py`); outputs land in `Global Research Paper/output/`; raw data remain in the parent project's `data/` tree. (Earlier exploratory analyses using constrained optimization, principal-component clustering, and regularized regression are retained in `Global Research Paper/archive/` but are not part of this paper.)

---

## 4. Results

### 4.1 Model 1: Climate vulnerability is a strong — but very incomplete — predictor of hunger

| Term | Coefficient | Std. error | p |
|---|---|---|---|
| Constant | −20.04 | 2.59 | <0.001 |
| Vulnerability | **69.42** | 7.12 | <0.001 |
| R² | **0.423** | (N = 143) | |

A 0.1-point increase in ND-GAIN vulnerability (on its 0–1 scale) is associated with roughly **6.9 percentage points** higher undernourishment. Vulnerability alone accounts for **42.3%** of cross-country variance — a strong bivariate gradient that justifies the widespread intuition linking climate exposure to hunger. (Model 4's bootstrap puts a 90% interval of [58.3, 81.5] on the slope and [0.34, 0.53] on \(R^2\), so the gradient is precisely estimated.)

But the same regression establishes the paper's central fact: **most of the variation in hunger is not explained by climate vulnerability.** The residual standard deviation is ~7.5 percentage points — comparable in magnitude to the entire undernourishment rate of many middle-income countries. The unexplained 58% is where adaptation, institutions, conflict, and policy live.

*Worked example.* Bangladesh's 2022 vulnerability of 0.569 yields a predicted PoU of \(-20.04 + 69.42 \times 0.569 \approx 19.4\%\). Actual PoU is 10.4%. Bangladesh's adaptation buffer is therefore **≈ +9.0 percentage points** — roughly 15 million people who, on climate fundamentals alone, "should" be undernourished but are not.

### 4.2 Model 2: The climate–hunger link survives controls, but shrinks

| Variable | Coefficient | Std. error | p |
|---|---|---|---|
| Vulnerability | **40.07** | 11.48 | <0.001 |
| ln(GDP per capita) | **−2.84** | 1.04 | 0.006 |
| Rural share (%) | −0.047 | 0.045 | 0.29 |
| Disaster count (2013–22) | 0.12 | 0.25 | 0.63 |
| ln(1 + conflict fatalities) | 0.065 | 0.31 | 0.83 |
| R² | **0.464** | (N = 139) | |

Three findings. First, vulnerability remains large and highly significant after conditioning on income, rurality, disasters, and conflict — the climate–hunger association is not merely a poverty artifact. Second, the coefficient falls from ~69 to ~40: roughly **40% of the raw gradient co-moves with development and shock observables**, a quantitative statement about how much of the climate–hunger correlation runs through development channels. Third, higher income is robustly associated with lower hunger (each log-point of GDP per capita ≈ 2.8 pp lower PoU), while crude disaster and conflict aggregates carry no significant *linear* signal in the cross-section — a result we interpret as measurement noise and functional-form limitation rather than evidence that shocks don't matter (the buffer rankings in §4.3 strongly suggest otherwise).

### 4.3 The global adaptation buffer: who beats their climate odds

Computing \(B_c\) for all 143 countries yields a distribution centered at zero (by construction) with **SD = 7.5 pp**, ranging from **+14.6** (Kiribati) to **−38.8** (Haiti). Half of all countries lie between −2.6 and +3.9; the tails are where the story is.

**Top 15 overperformers (largest positive buffers):**

| Rank | Country | V | Predicted PoU | Actual PoU | Buffer |
|---|---|---|---|---|---|
| 1 | Kiribati | 0.558 | 18.7 | 4.1 | **+14.6** |
| 2 | Senegal | 0.537 | 17.2 | 5.1 | **+12.1** |
| 3 | Samoa | 0.514 | 15.6 | 3.6 | **+12.0** |
| 4 | Vanuatu | 0.558 | 18.7 | 7.2 | **+11.5** |
| 5 | Sudan | 0.613 | 22.5 | 11.0 | **+11.5** |
| 6 | Mauritania | 0.578 | 20.1 | 8.7 | **+11.4** |
| 7 | Niger | 0.636 | 24.1 | 12.9 | **+11.2** |
| 8 | Myanmar | 0.515 | 15.7 | 5.4 | **+10.3** |
| 9 | **Bangladesh** | 0.569 | 19.4 | 10.4 | **+9.0** |
| 10 | Cameroon | 0.486 | 13.7 | 4.8 | **+8.9** |
| 11 | Nepal | 0.491 | 14.0 | 5.3 | **+8.7** |
| 12 | Cambodia | 0.481 | 13.3 | 5.2 | **+8.1** |
| 13 | Philippines | 0.445 | 10.9 | 3.0 | **+7.9** |
| 14 | Seychelles | 0.437 | 10.3 | 2.5 | **+7.8** |
| 15 | Mali | 0.576 | 19.9 | 12.3 | **+7.6** |

**Bottom 10 underperformers (most negative buffers):**

| Rank | Country | V | Predicted PoU | Actual PoU | Buffer |
|---|---|---|---|---|---|
| 134 | Central African Rep. | 0.578 | 20.1 | 29.8 | **−9.7** |
| 135 | Papua New Guinea | 0.550 | 18.2 | 28.7 | **−10.5** |
| 136 | Botswana | 0.431 | 9.9 | 24.0 | **−14.1** |
| 137 | Gabon | 0.436 | 10.3 | 25.3 | **−15.0** |
| 138 | Liberia | 0.539 | 17.4 | 35.5 | **−18.1** |
| 139 | Madagascar | 0.560 | 18.8 | 39.5 | **−20.7** |
| 140 | Kenya | 0.500 | 14.7 | 36.8 | **−22.1** |
| 141 | Zambia | 0.486 | 13.7 | 37.2 | **−23.5** |
| 142 | Syria | 0.487 | 13.8 | 39.0 | **−25.2** |
| 143 | Haiti | 0.510 | 15.4 | 54.2 | **−38.8** |

(Full 143-country table: Appendix B / `output/global_buffer_rankings.csv`.)

Three patterns stand out.

**Overperformance clusters in two groups.** Pacific and Indian Ocean small island states (Kiribati, Samoa, Vanuatu, Seychelles) carry very high vulnerability indices — driven by exposure metrics — but low measured undernourishment; part of this may reflect FAO estimation in small states, which we flag for robustness analysis. The second, more policy-relevant group consists of **agrarian states with sustained agricultural and social-protection investment**: Bangladesh, Senegal, Nepal, Cambodia, Vietnam (rank 17, +7.1), and the Philippines. Notably, several Sahelian states (Senegal, Mauritania, Niger, Mali) appear among overperformers — extreme climate exposure, but hunger below what that exposure alone predicts.

**Underperformance is dominated by conflict and governance failure, not climate.** Haiti, Syria, Liberia, the Central African Republic, and Afghanistan (rank 129, −7.3) are all states where political violence or institutional collapse has destroyed food systems. Strikingly, several *moderately* vulnerable, middle-income countries (Botswana, Gabon, Jordan) post deeply negative buffers — hunger far in excess of their climate burden — pointing to inequality and distributional failure rather than exposure.

**The buffer and vulnerability are nearly orthogonal in the tails.** Niger (V = 0.636, among the world's most vulnerable) has a *positive* 11-point buffer; Botswana (V = 0.431, mid-range) has a *negative* 14-point buffer. A vulnerability ranking and a buffer ranking would direct attention — and aid — to substantially different country lists. This is the paper's core descriptive contribution.

### 4.4 Model 3: What explains the buffer? (Mostly, not what we can measure)

| Variable | Coefficient | Std. error | p |
|---|---|---|---|
| ln(GDP per capita) | 0.41 | 1.09 | 0.71 |
| **ND-GAIN readiness** | **13.35** | 8.69 | **0.12** |
| Rural share (%) | 0.065 | 0.043 | 0.13 |
| Disaster count | −0.055 | 0.25 | 0.83 |
| ln(1 + fatalities) | 0.049 | 0.31 | 0.87 |
| R² | **0.057** | (N = 139) | |

The headline result is the **low R²**: this parsimonious covariate menu explains only ~6% of buffer variation. The most substantively interesting coefficient is **readiness** — countries with greater adaptive capacity tend to post larger buffers (a 0.1-point readiness increase ≈ +1.3 pp of buffer) — but the estimate misses conventional significance (p ≈ 0.12) at this sample size. We treat it as hypothesis-generating.

Two interpretive points. First, the null on GDP does not contradict Model 2: income predicts the *level* of hunger, but the buffer already nets out the part of hunger that tracks vulnerability, and income's residual contribution is evidently weak in this linear form. Second, the low R² is itself informative: it says the buffer is **not** a repackaging of observable development indicators. Whatever produces overperformance — policy quality, agricultural innovation history, social-protection architecture, aid effectiveness, food-system institutions — lives largely outside the standard cross-country covariate set. The practical consequence is that buffers cannot be inferred from covariates; they must be **monitored**, by computing \(B_{c,t}\) directly from the data each year. A planned extension (agricultural productivity, aid flows, government effectiveness, cereal yields, trade dependency) remains worthwhile for *descriptive* decomposition, but the watch-list tool is the buffer time series itself, not a covariate-based forecast.

### 4.5 Model 4: How sure are we? Monte Carlo confidence in the buffer

A buffer is only useful if we can tell signal from noise. We re-estimate every country's buffer 20,000 times — each time resampling the 143 countries to redraw the benchmark line, and adding measurement noise to the reported hunger rates (§3.3) — and summarize the resulting distribution. Three findings emerge.

**The benchmark line is precisely estimated.** Across resamples, the vulnerability slope averages 69.6 with a 90% interval of [58.3, 81.5], the intercept −20.1 [−24.4, −16.0], and \(R^2\) 0.43 [0.34, 0.53]. The bivariate gradient is not an artifact of a few influential countries.

**Most rankings are statistically real.** Sorting the 143 countries by their probability of being a true over-performer, \(P(B_c > 0)\):

| Category | Definition | Countries |
|---|---|---|
| Robust over-performers | \(P(B_c>0) \ge 0.90\) | **66** |
| Statistically ambiguous | \(0.10 < P(B_c>0) < 0.90\) | 35 |
| Robust under-performers | \(P(B_c>0) \le 0.10\) | **42** |

Nearly three-quarters of countries land in a clear camp; only 35 sit near the benchmark where the sign of the buffer is genuinely uncertain. The headline names are unambiguous:

| Country | Buffer (MC mean) | 90% interval | P(over-performer) |
|---|---|---|---|
| Senegal | +12.1 | [+9.5, +14.9] | 1.00 |
| Niger | +11.2 | [+7.4, +15.2] | 1.00 |
| **Bangladesh** | **+9.1** | **[+6.1, +12.1]** | **1.00** |
| Viet Nam | +7.1 | [+5.0, +9.3] | 1.00 |
| Kenya | −22.1 | [−28.4, −15.7] | 0.00 |
| Haiti | −38.8 | [−47.9, −29.6] | 0.00 |

Bangladesh's buffer stays positive in 100% of 20,000 simulations, and even its pessimistic 5th-percentile value (+6.1 pp) leaves it a clear over-performer. The same holds in reverse for Haiti and Kenya. This is the rigor the point estimates in §4.3 lacked: the over- and under-performer lists are not coin-flips.

### 4.6 Model 5: How buffers collapse — and what protects them

Research question 2 asks how durable a buffer is. We simulate a Bangladesh-like buffer (starting at +9.1) forward 20 years, 20,000 times, letting random climate and conflict shocks knock it down and recovery rebuild it (§3.3). We compare two countries facing the **same** shock probability but differing in resilience.

| Scenario | P(collapse ≤ 10y) | P(collapse ≤ 20y) | Expected years underwater (of 20) | Buffer at year 20 (5th pct / median) |
|---|---|---|---|---|
| **Baseline** (big shocks, slow recovery) | 21.6% | **41.3%** | 1.01 | −0.5 / +6.6 |
| **Resilience investment** (smaller shocks, faster recovery) | 2.0% | **4.4%** | 0.05 | +4.4 / +8.2 |

The contrast is stark. A buffer of +9 points — comfortably positive today — has a **41% chance of collapsing below zero at least once within twenty years** if shocks are severe and recovery is slow. That is the Bangladesh-2007 scenario: a hard-won buffer is not permanent, and a single bad cyclone sequence can erase it. But a country that invests in resilience — so that shocks do 40% less damage and recovery is faster — cuts its twenty-year collapse probability to **4.4%**, a nearly tenfold reduction, and expects to spend essentially no time underwater (0.05 vs. 1.01 years). Crucially, both countries face the *same* climate exposure; the difference is entirely in how they absorb and recover from shocks.

This simulation reframes adaptation policy in stock-and-flow terms. The buffer is a stock that erodes under shocks and rebuilds through recovery; the highest-value interventions are those that either soften shocks (early warning, flood protection, stress-tolerant crops, storage) or accelerate recovery (safety nets, credit, insurance). The Monte Carlo puts a probability on what is otherwise an intuition: defending a buffer is far cheaper than rebuilding one after collapse. Appendix A works through what such a defending budget looks like for Bangladesh.

### 4.7 Robustness

All pre-registered checks were run (`Global Research Paper/scripts/global_robustness_checks.py`; full table in `Global Research Paper/output/global_robustness_summary.csv`). Each is a re-run of the same OLS benchmark with a different input.

| Check | Result |
|---|---|
| R1. FAO window 2020–22 (strict 2022 alignment) | β = 68.7 (SE 7.2), R² = 0.442, N = 143 — essentially identical to headline |
| R2a. WRI 2025 vulnerability component | β = 31.5 (SE 4.3), R² = 0.289 — positive, significant, weaker fit |
| R2b. WRI 2025 composite index | β = 4.6 (SE 7.3), R² = 0.002 — **no relationship** |
| R2c. Global Data Lab vulnerability | β = 39.9 (SE 4.7), R² = 0.408, N = 92 — closely replicates ND-GAIN |
| R2d. ND-GAIN exposure sub-index only | β = 50.6 (SE 9.8), R² = 0.153 — much weaker than composite |
| R3. WHO child stunting as outcome | β = 110.8 (SE 7.4), R² = 0.624, N = 121 — **stronger** than PoU |
| R4. Model 2, z-scored regressors | V: +3.7 pp/SD (p < 0.001); ln GDP: −3.9 pp/SD (p = 0.006); signs stable, no collinearity problem |
| R5. Excluding states < 1M population | β = 75.5, R² = 0.458, N = 125; island anomalies drop out; top buffers: Senegal +13.4, Sudan +13.2, Niger +13.1, Mauritania +13.0, Myanmar +11.5, **Bangladesh +10.5** |

Three conclusions. **(i) The headline gradient is stable** to FAO vintage, small-state exclusion, and standardization, and the core overperformer list (Sahelian states, Bangladesh, Southeast Asian deltas) survives dropping small islands — Bangladesh in fact rises to sixth. **(ii) The vulnerability *concept* matters more than the index vendor.** Indices that embed sensitivity and adaptive capacity (ND-GAIN composite, GDL, the WRI *vulnerability* component) all show strong gradients; pure physical-exposure measures (ND-GAIN exposure sub-index, the exposure-dominated WRI composite) show weak or no association with hunger. The climate–hunger link runs through *susceptibility*, not raw hazard — a substantive finding, and a caution that the buffer benchmark conditions on a socioeconomically-laden vulnerability concept (see §6). **(iii) The relationship is not an artifact of FAO's PoU:** the stunting gradient is even steeper (R² = 0.62).

---

## 5. Discussion

**The buffer measures effective adaptation, not planned adaptation.** Adaptation tracking today counts policies, plans, and dollars. The buffer counts outcomes: it is the revealed difference between the hunger a country's climate burden predicts and the hunger it experiences. A country can publish national adaptation plans and still run a negative buffer; a country can appear in few adaptation databases and quietly outperform its climate odds for two decades. For global frameworks under the Paris Agreement's Global Goal on Adaptation — which has struggled to define measurable indicators — an outcome-based residual metric is a concrete candidate.

**Conflict destroys buffers faster than climate erodes them.** The underperformer list is a roll call of political violence and state fragility: Haiti, Syria, Liberia, CAR, Afghanistan. None of these countries is among the world's *most* climate-vulnerable; all are among the hungriest relative to prediction. Conversely, several of the world's most climate-exposed countries (Niger, Bangladesh, Senegal) hold large positive buffers. The implication is uncomfortable for climate-centric aid allocation: **vulnerability indices alone would systematically misdirect resources away from the countries where hunger most exceeds climate fundamentals.**

**Buffers are assets that can be built — and lost.** Bangladesh is the prototype: a ~9-point buffer assembled through decades of agricultural innovation (high-yielding and stress-tolerant rice), disaster-preparedness institutions, and social protection — yet one that collapsed after the 2007–2009 cyclone sequence and was only partially rebuilt by 2020, with renewed warning signs after 2021. Treating the buffer as a stock variable reframes adaptation policy: the goal is not only to reduce vulnerability (slow, expensive) but to **defend the buffer** (often cheaper, faster — e.g., maintaining early-warning systems, storage, and safety nets). Model 5's Monte Carlo puts numbers on this: a +9-point buffer carries a 41% chance of collapsing within twenty years under severe shocks and slow recovery, but only a 4% chance once resilience investments soften shocks and speed rebuilding — a tenfold reduction from interventions that leave climate exposure itself unchanged.

**Aid allocation: target shrinking buffers, not just high vulnerability.** The actionable monitoring rule the paper supports is a two-axis screen — vulnerability level × buffer trend. High-vulnerability countries with large but *shrinking* buffers (the Bangladesh-2007 configuration) are the highest-value targets for preventive finance, because intervention there protects existing adaptive infrastructure rather than rebuilding after collapse. Model 3's low R² sharpens this rule: because the buffer cannot be inferred from standard covariates, the watch-list must come from *direct monitoring* of the buffer time series, not from forecasting models. Model 4 supplies the discipline to do this honestly — by attaching an over-performance probability to each country, it separates the 66 robust over-performers and 42 robust under-performers from the 35 countries too close to the benchmark to classify.

**Defending a buffer beats rebuilding one.** The collapse simulation (Model 5) exposes a tension that vulnerability-based aid rhetoric obscures: two countries can face identical climate exposure yet differ enormously in how durable their food security is, purely because of how well they absorb and recover from shocks. The policy payoff is not in reducing the hazard — that is slow and largely outside any single country's control — but in the absorptive and recovery capacity that turns a 41% collapse risk into a 4% one. This is where adaptation finance has the highest marginal return, and it is invisible to a vulnerability index, which scores the hazard rather than the response.

**What we still cannot explain matters.** Model 3's low R² is a finding, not a failure: roughly 94% of buffer variation is unexplained by standard development covariates. The most plausible candidate explanations — quality of food-system institutions, cumulative agricultural research investment, aid effectiveness, social-protection design — are precisely the factors hardest to measure in cross-country data. The buffer thus also serves as a research agenda: it tells us *where* to look for adaptation success (Senegal, Nepal, Cambodia) and failure (Botswana, Madagascar) in depth.

---

## 6. Limitations

**Association, not causation.** Every model here is observational. Model 1's benchmark is deliberately naive; the buffer inherits any bias in that benchmark. Countries are not randomized into vulnerability, and omitted variables (colonial history, geography, disease burden) load on both vulnerability and hunger.

**The buffer is benchmark-relative.** It is defined against a specific bivariate regression on a specific vulnerability index. A different index or functional form yields different buffers — which is why robustness across WRI, GDL, and ND-GAIN sub-indices is essential before strong country-level claims. The buffer also averages to zero by construction: it ranks relative performance and cannot say whether *global* adaptation is adequate.

**Index aggregation and concept-dependence.** ND-GAIN is an index of indices; weighting and substitutability choices propagate into the benchmark. The robustness results sharpen this: indices embedding sensitivity and adaptive capacity replicate the gradient (GDL R² = 0.41; WRI vulnerability component R² = 0.29), while pure exposure measures do not (ND-GAIN exposure sub-index R² = 0.15; WRI composite R² ≈ 0). The buffer therefore benchmarks hunger against *susceptibility-weighted* vulnerability, not raw hazard — defensible, since susceptibility is what vulnerability indices are designed to capture, but a choice users of the metric should understand. Small-state anomalies (Kiribati, Samoa at the top of the rankings) may partly reflect how exposure-heavy sub-indices treat island geography; they drop out of the ranking when states under 1M population are excluded, with the substantive top-ten unchanged.

**Outcome measurement.** FAO PoU is a modeled, smoothed estimate, weak on short-run shocks and on within-country distribution; censoring at 2.5% compresses the secure tail. The stunting robustness check (R² = 0.62 on the same vulnerability index) shows the gradient is not a PoU artifact, but anthropometric and acute-insecurity outcomes measure different constructs and an IPC Phase 3+ check remains to be added.

**The Monte Carlo simulations rest on stated assumptions.** Model 4's measurement-error term (a 10% coefficient of variation, 1-pp floor) is a transparent stand-in for country-level uncertainty the FAO does not publish; larger assumed noise would widen the intervals and shrink the "robust" category, though the headline names (Bangladesh, Haiti) are far enough from zero to be insensitive. Model 5's collapse simulation is a stylized stock-and-flow process whose shock frequency, shock size, and recovery rate are illustrative parameters, not estimates for any specific country. Its value is the *mechanism and the comparison* — that resilience investments cut collapse risk roughly tenfold for the same climate exposure — not a precise collapse probability for Bangladesh.

**Climate–conflict entanglement.** Conflict both responds to and amplifies climate stress; treating them as separable covariates understates their interaction. This biases against finding clean "climate effects" and complicates buffer attribution in conflict states.

---

## 7. Conclusion

Climate vulnerability does not equal hunger. Across 143 countries, vulnerability explains 42% of the variation in undernourishment — and the remaining 58% is structured, persistent, and policy-laden. We have named that residual the adaptation buffer, measured it for every country, shown that it is large (±7.5 pp SD, spanning −39 to +15), demonstrated that it is nearly orthogonal to vulnerability in the tails, and established that it is *not* a disguise for income or other standard covariates.

The buffer reframes three conversations. For **measurement**, it offers what adaptation tracking has lacked: an outcome-based, annually computable, globally comparable indicator of effective adaptation. For **allocation**, it shows that vulnerability-weighted aid formulas would miss the countries where hunger most exceeds climate fundamentals — and overlook the overperformers whose fragile gains most merit defending. For **research**, its unexplained variance is a map of where adaptation success and failure should be studied in depth.

The regression backbone (Models 1–3) establishes the metric; the Monte Carlo layer (Models 4–5) makes it trustworthy and dynamic. Resampling the data 20,000 times shows that 66 countries are robust over-performers and 42 robust under-performers — the rankings are signal, not noise. Simulating the buffer forward under random shocks shows that a healthy buffer is nonetheless fragile: a +9-point buffer collapses within twenty years 41% of the time under severe shocks, but only 4% of the time once resilience investments soften shocks and speed recovery — for the very same climate exposure. And the low explanatory power of standard covariates (Model 3) establishes that the buffer must be monitored rather than inferred: it contains information about adaptation effectiveness that no standard covariate set reproduces. The Bangladesh appendix demonstrates the endpoint: a country beating its climate odds by nine percentage points, whose buffer can be defended, at stated cost, through a transparent budget allocation. We propose that buffer monitoring — level and trend — be integrated into climate-adaptation frameworks, so that the countries living on borrowed time are visible before the loan is called.

---

## Appendix A — Bangladesh Case Study: Budget Allocation and Collapse Risk

*This appendix works through one country to show what "defending a buffer" looks like in practice. It uses only two ideas: the equal-marginal-return rule for spending a fixed budget (the standard Lagrange-multiplier result from multivariable calculus), and a Monte Carlo simulation of the buffer under random shocks (Model 5 applied to Bangladesh). Full data and derivations are in the project's appendix documentation.*

### A.1 Setting

Bangladesh's adaptation buffer is ≈ +9.0 pp (predicted PoU 19.4%, actual 10.4%), corresponding to roughly 18.05 million people who remain undernourished and a national caloric deficit of ≈ 4.6 trillion kcal/year (≈700 kcal/day per undernourished person, against the BBS extreme-poverty threshold of 1,805 kcal/day and national mean intake of 2,393 kcal/day).

### A.2 The allocation problem and how it is solved

Thirteen evidence-based policies (school feeding with fortified rice, saline-tolerant rice, post-harvest storage, AWD irrigation, flood-tolerant Sub1 rice, renewable-powered irrigation, crop diversification, farmer insurance, river/canal excavation, tree planting, aquaculture, cyclone early warning, flood forecasting) each have a *diminishing-returns* impact function — the first dollar feeds more people than the millionth:

$$
\text{Impact}_i(x_i) = \frac{a_i}{b_i}\, x_i^{\,b_i}, \qquad 0 < b_i < 1,
$$

where \(a_i\) is people-fed per $1M at the first dollar and \(b_i\) encodes how fast returns fade (0.80–0.85 for standardized delivery; 0.50 for the hardest interventions). Seven documented policy pairs receive synergy bonuses \(S_{ij} = \alpha_{ij}\sqrt{f_i f_j}\,(\text{Impact}_i + \text{Impact}_j)\). We split a working budget of ≈ $8.0B/year (BDP 2100 allocation at 2.5% of GDP, discounted 40% for political risk, plus ~$0.9–1.5B guaranteed international aid, less a 20% implementation-efficiency discount) to maximize total people fed, subject to a 35% political floor on BNP-aligned policies and a $200M minimum per funded policy.

Maximizing a sum of concave functions under a single budget constraint is a textbook Lagrange-multiplier problem. Its solution is intuitive: **at the optimum, every funded policy delivers the same marginal return** — call it \(\lambda\), the budget's *marginal value* (extra people fed per extra $1M). The marginal return of policy \(i\) is the derivative \(a_i x_i^{\,b_i-1}\), which decreases as you spend more; you keep moving dollars toward whichever policy has the highest marginal return until all funded policies are tied at \(\lambda\). A policy is funded **only if its very first dollar clears the bar** \(\lambda\); if even its first dollar returns less than \(\lambda\), it gets nothing. That single rule — equal marginal returns across what you fund, fund nothing below the bar — is the entire logic, and it requires no machinery beyond the Lagrange multipliers in a multivariable-calculus course.

### A.3 Results

At the $8B optimum, **10 of 13 policies are funded**, led by fortified school feeding ($1.8B; 11.5M people-equivalents), saline-tolerant rice ($1.5B), post-harvest storage and renewable irrigation ($1.2B each), and AWD irrigation ($1.0B). Three policies — cyclone early warning, flood forecasting, and aquaculture — are left unfunded because their marginal return at the very first dollar already falls below the budget's marginal value \(\lambda\) at the $8B scale. Total impact: **22.2M people-equivalents, closing 100% of the caloric deficit with a 23% resilience buffer**; synergies contribute 7.4% of base impact; the BNP floor binds exactly at 35% (forcing money into policies that would otherwise score below \(\lambda\) is exactly what a political constraint costs).

### A.4 Collapse risk: a Monte Carlo for Bangladesh

The allocation above describes a single good year. But Bangladesh's buffer lives in a world of cyclones, floods, and price shocks, so we simulate it forward (Model 5): start at \(B_0 = +9.1\), let the buffer recover toward its target each year, and subtract a random shock that strikes with 20% annual probability. Across 20,000 simulated twenty-year histories, a Bangladesh that has *not* invested in resilience (large shocks, slow recovery) sees its buffer fall below zero at least once **41% of the time within 20 years**, spending on average a full year underwater. A Bangladesh that *has* invested — so cyclones do ~40% less damage to the buffer and recovery is faster — cuts that collapse probability to **4.4%** and expects essentially zero years underwater. The climate exposure is identical in both runs; the entire difference comes from the absorptive and recovery capacity the budget in A.2–A.3 buys. This is the quantitative case for spending on early warning, flood protection, storage, and safety nets: they do not lower the hazard, but they are what stands between a +9 buffer and its collapse.

### A.5 Connection to the global framework

The Bangladesh exercise is what "defending a buffer" looks like up close: a transparent spending rule (equal marginal returns, a funding bar \(\lambda\), a priced political floor) paired with a simulation that shows how much collapse risk that spending removes. The global results generalize both halves — the buffer rankings (§4.3) say *which* countries have buffers worth defending, and the collapse Monte Carlo (§4.6) says *why* defending them early beats rebuilding them after a crisis.

---

## Appendix B — Supplementary Materials

- **B.1 Full adaptation-buffer rankings (143 countries):** `Global Research Paper/output/global_buffer_rankings.csv` (rank, vulnerability, readiness, actual PoU, predicted PoU, buffer).
- **B.2 Regression tables (Models 1–3):** `Global Research Paper/output/global_models_1_4_tables.csv` (coefficients, standard errors, confidence intervals, and fit statistics for the OLS models).
- **B.3 Monte Carlo buffer uncertainty (Model 4):** `Global Research Paper/output/global_mc_buffer_uncertainty.csv` (per-country Monte Carlo mean buffer, 90% interval, and over-performance probability across 20,000 draws) and `Global Research Paper/output/global_mc_slope_distribution.csv` (bootstrap 90% intervals for the Model 1 slope, intercept, and R²).
- **B.4 Monte Carlo collapse dynamics (Model 5):** `Global Research Paper/output/global_mc_collapse_dynamics.csv` (collapse probabilities, expected years underwater, and year-20 buffer percentiles for the baseline and resilience-investment scenarios).
- **B.5 Robustness tables:** `Global Research Paper/output/global_robustness_summary.csv` (all R1–R5 coefficients) and `Global Research Paper/output/global_buffer_rankings_pop1m.csv` (buffer ranking excluding states < 1M population).
- **B.6 Archived exploratory analyses:** earlier work using constrained optimization, principal-component clustering, and regularized regression — not part of this paper — is retained under `Global Research Paper/archive/scripts/` and `Global Research Paper/archive/output/` for the interested reader.

---

## References

### Academic literature

Berrang-Ford, L., Siders, A. R., Lesnikowski, A., et al. (2021). A systematic global stocktake of evidence on human adaptation to climate change. *Nature Climate Change*, 11(11), 989–1000. doi:10.1038/s41558-021-01170-y. *(verified)*

Burke, M., Hsiang, S. M., & Miguel, E. (2015). Climate and conflict. *Annual Review of Economics*, 7, 577–617. doi:10.1146/annurev-economics-080614-115430.

Cafiero, C., Viviani, S., & Nord, M. (2018). Food security measurement in a global context: The Food Insecurity Experience Scale. *Measurement*, 116, 146–152. doi:10.1016/j.measurement.2017.10.065.

Chen, C., Noble, I., Hellmann, J., Coffee, J., Murillo, M., & Chawla, N. (2015). *University of Notre Dame Global Adaptation Index: Country Index Technical Report*. Notre Dame, IN: ND-GAIN.

Ford, J. D., Berrang-Ford, L., Lesnikowski, A., Barrera, M., & Heymann, S. J. (2013). How to track adaptation to climate change: A typology of approaches for national-level application. *Ecology and Society*, 18(3), 40. doi:10.5751/ES-05732-180340.

Headey, D. (2013). Developmental drivers of nutritional change: A cross-country analysis. *World Development*, 42, 76–88. doi:10.1016/j.worlddev.2012.07.002.

Hinkel, J. (2011). "Indicators of vulnerability and adaptive capacity": Towards a clarification of the science–policy interface. *Global Environmental Change*, 21(1), 198–208. doi:10.1016/j.gloenvcha.2010.08.002.

IPCC (2022). *Climate Change 2022: Impacts, Adaptation and Vulnerability.* Contribution of Working Group II to the Sixth Assessment Report of the Intergovernmental Panel on Climate Change. Cambridge: Cambridge University Press.

Mbow, C., Rosenzweig, C., et al. (2019). Food security. In P. R. Shukla et al. (Eds.), *Climate Change and Land: An IPCC Special Report on Climate Change, Desertification, Land Degradation, Sustainable Land Management, Food Security, and Greenhouse Gas Fluxes in Terrestrial Ecosystems* (Ch. 5). Cambridge: Cambridge University Press.

von Grebmer, K., Bernstein, J., et al. (2023). *2023 Global Hunger Index: The Power of Youth in Shaping Food Systems*. Bonn/Dublin: Welthungerhilfe and Concern Worldwide.

Wheeler, T., & von Braun, J. (2013). Climate change impacts on global food security. *Science*, 341(6145), 508–513. doi:10.1126/science.1239402.

### Data sources

Armed Conflict Location & Event Data Project (ACLED). Conflict event and fatality data. acleddata.com. Accessed 2026.

Bündnis Entwicklung Hilft & Ruhr University Bochum — IFHV (2025). *WorldRiskReport 2025* (WorldRiskIndex). weltrisikobericht.de.

Centre for Research on the Epidemiology of Disasters (CRED). EM-DAT: The International Disaster Database. UCLouvain, Brussels. www.emdat.be. Accessed 2026.

Food and Agriculture Organization of the United Nations. Suite of Food Security Indicators (Item 210041: Prevalence of undernourishment, 3-year averages). *FAOSTAT*, www.fao.org/faostat/en/#data/FS. Accessed 2026.

FAO, IFAD, UNICEF, WFP, & WHO (2024). *The State of Food Security and Nutrition in the World 2024*. Rome: FAO.

Global Data Lab. Climate Vulnerability Index. Radboud University, Nijmegen. globaldatalab.org. Accessed 2026.

Notre Dame Global Adaptation Initiative. ND-GAIN Country Index Data (vulnerability, readiness, and sectoral sub-indices, 1995–2023). University of Notre Dame, gain.nd.edu/our-work/country-index/download-data/. Accessed 2026.

UNICEF, WHO, & World Bank. Joint Child Malnutrition Estimates: stunting prevalence in children under 5. WHO Global Health Observatory. Accessed 2026.

World Bank. World Development Indicators (GDP per capita, population, rural share, land use, health, governance). databank.worldbank.org. Accessed 2026.

### Appendix A sources (Bangladesh case study)

CGIAR. "Flood-Tolerant Rice Improves Climate Resilience, Profitability, and Household Consumption in Bangladesh." cgspace.cgiar.org. Accessed 2026.

ICIMOD (2026). "Hindu Kush Himalaya Glaciers Losing Ice at Double the Rate since 2000." International Centre for Integrated Mountain Development, 21 Mar. 2026.

IRRI. "Saving Water: Alternate Wetting and Drying (AWD)." *IRRI Rice Knowledge Bank*. Accessed 2026.

World Bank (2023). "Bangladesh Receives $858 Million World Bank Financing to Improve Climate Resilient Agriculture Growth and Road Safety." Press release, 7 June 2023.

World Bank (2025). "World Bank Supports Bangladesh in Flood Risk Reduction and Recovery" (B-STRONG project). Press release, 14 May 2025.

World Food Programme. *Bangladesh School Feeding USDA McGovern-Dole Grant (2020–2023) Evaluation*. Accessed 2026.

World Food Programme (2024). *Bangladesh Market Monitor — April 2024* (national food-basket cost, BDT 2,844/person/month).

*The complete catalogue of Appendix A evidence sources (44 MLA entries: BRRI field trials, ADB project documents, BDP 2100 portal, BBS HIES 2022, hermetic storage trials, early-warning valuations, and political-constraint sources) is maintained in `Global Research Paper/citations.md` and will be merged at typesetting. Academic entries above marked (verified) have been checked against publisher records; remaining DOIs are from standard bibliographic records and should receive a final check at submission.*
