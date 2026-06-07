# Data Collection & Integration Recommendations for Global Hunger Research

## 📊 **Current Data Coverage Analysis**

### **Data Sources Currently Integrated:**
1. ✅ **World Bank Indicators** - GDP, poverty, population, life expectancy, literacy, agriculture
2. ✅ **FAO Undernourishment** - Prevalence rates (with time series) **(266 countries)**
3. ✅ **WFP GRFC** - IPC phases, acute hunger assessments **(48 countries)**. Data from `data/raw/wfp/`: app reads **`grfc2016-2024_data.xlsx`** (2016–2024) and any **`grfcYYYY_data.csv`** (e.g. 2025); uses latest assessment per country. PDFs in that folder are for reference only.
4. ✅ **IPC / Cadre Harmonisé (CH)** - Three sources in `data/raw/ipc/`: **(1)** `ipc data general data.csv` (country-level phase & Phase 3+ population, ~31 countries); **(2)** `IPC data population analysis.xlsx` (Population Tracking Tool; latest analysis per country); **(3)** **`ipc all data 2017-2025.csv`** (historical subnational; aggregated to country-year). Merge order: GRFC → general IPC → population analysis → **IPC historical (latest year)**. The **GRFC & IPC Trends** tab uses both GRFC panel and IPC 2017–2025 panel for over-time charts and CSV export.
5. ✅ **FAO FPMA** - Food Price Monitoring and Analysis (commodity/market prices); cited, not merged into score
6. ✅ **WHO** - Child stunting rates **(633 countries)**
7. ✅ **Our World in Data** - Additional poverty metrics **(195 countries)**
8. ✅ **Global Data Lab** - Climate & health vulnerability indices **(Climate: 1,426 countries; Health: 572 countries)**
9. ✅ **UNHCR** - Refugee/displaced populations **(179 countries)**
10. ✅ **Historical Hunger Outbreaks** - 21st century crisis data **(18 countries)**
11. ✅ **EM-DAT** - Disaster data **(266 countries)**
12. ✅ **Food Trade Dependency** - Import dependency ratios **(66 countries)**
13. ✅ **Food Supply** - kcal/day per capita **(241 countries)**
14. ✅ **Water Resources** - Per capita and agricultural withdrawals **(199 countries)**
15. ✅ **USDA** - Agricultural productivity/TFP data **(225 countries in source file)**
16. ✅ **GHI** - Global Hunger Index scores **(123 countries)**
17. ✅ **ACLED** - Conflict data **(180 countries)**
18. ✅ **WPR** - Malnutrition rates **(169 countries)**

**Note:** FEWS NET (Famine Early Warning Systems Network) was **not** obtained; IPC and FAO data were added instead to improve acute food insecurity and price context.

**IPC data files (in `data/raw/ipc/`):**
- **`ipc data general data.csv`** – Header on row 2; columns include Country, Phase 1–5, Phase 3+, Period from/to. Footer text rows are filtered out on load.
- **`IPC data population analysis.xlsx`** – Sheet “Population Tracking Tool”; country-level rows have non-NA “Country Population”. First column format: `XX: Acute Food Insecurity...` (XX = ISO2). App takes latest analysis per country; to support more countries, add their ISO2 → country name in `load_ipc_population_data()` in `app.R`.
- **`ipc all data 2017-2025.csv`** – Historical IPC (subnational areas); columns include Date of analysis, Country (ISO3), Phase 1–5 and Phase 3+ number current. App aggregates to **country-year**, uses latest year to supplement GRFC/IPC where missing, and exposes the full panel in **GRFC & IPC Trends** (chart + CSV export).

---

### **What other data still needs to be collected**

| Priority | Data source / indicator | Why | Status |
|----------|--------------------------|-----|--------|
| **High** | **FEWS NET** | Food security classifications and early warning; would complement GRFC/IPC. | ❌ Not obtained (use IPC/CH and FAO as current alternatives). |
| **High** | **FAO GIEWS** | Country-level food security and crop assessments. | Not yet integrated. |
| **High** | **Food trade dependency** (expand beyond 66 countries) | FAO FAOSTAT trade, World Bank food imports, or UN Comtrade. | Only 66 countries currently. |
| **High** | **Literacy** (alternative to World Bank) | UNESCO or other; many countries missing. | Not yet integrated. |
| **Medium** | **Historical GRFC / IPC by year** | Panel analysis and crisis prediction over time. | ✅ GRFC 2016–2024 + IPC 2017–2025 integrated; **GRFC & IPC Trends** tab with chart and panel CSV export. |
| **Medium** | **World Bank PIP** (poverty) | Broader poverty coverage and thresholds. | Optional; OWID already supplements. |
| **Medium** | **IDMC / IOM** (displacement) | Supplement UNHCR for IDPs and migration. | Optional. |
| **Lower** | **Food price inflation (country-level)** | Food CPI for shock analysis. | Not integrated. |
| **Lower** | **Governance (WGI), social protection (ASPIRE)** | For regression and policy analysis. | Not integrated. |

---

### **HDX data: what’s needed for this project**

Below is a concise view of HDX datasets you listed: **needed** (high value for hunger/vulnerability), **optional** (useful but overlapping or niche), or **not needed** (out of scope or already covered).

| HDX dataset | Verdict | Why |
|-------------|--------|-----|
| **FAO DIEM** | **Needed** | You already note FAO GIEWS as high priority; DIEM is similar (early warning / food security). |
| **IOM** | **Needed** | You already flag IDMC/IOM for displacement; IOM adds migration/IDP context. |
| **Internal Displacement Updates (IDU)** | **Needed** | Complements UNHCR; improves IDP coverage (you already flag IDMC/IOM as medium priority). |
| **OCHA FTS** | **Needed** | Standard for humanitarian funding; good for “requirements vs funding” and gaps. |
| **UNHCR: Monthly Refugee + Asylum Seekers** | **Needed** | Finer time series than current UNHCR; good for trends and panel. |
| **IPC data** | **Already integrated** | Historical IPC 2017–2025 is in `data/raw/ipc/` and used in the app. |
| **CERF Allocations, Donor Contributions** | **Optional** | Funding context; useful for reporting, not for score. |
| **CERF Topline Figures** | **Optional** | Same as CERF above. |
| **Central America: Media Analysis, Coffee/Sugar/Banana prices, agroclimatic hazards** | **Optional** | Good for regional or commodity shock analysis; not global core. |
| **Disaster Types** | **Optional** | You have EM-DAT; add if you want disaster-type breakdowns. |
| **Foreign Exchange Rates** | **Optional** | Useful for cost/import analysis; not core to score. |
| **GDACS alerts** | **Optional** | Early warning for disasters; you already have EM-DAT. Add if you want real-time hazard alerts. |
| **Global Violent Deaths** | **Optional** | Overlaps with ACLED / conflict; add for a different violence metric. |
| **HAPI Data** | **Optional** | Depends on indicators; integrate if it adds hunger/health indicators you lack. |
| **HDX Humanitarian API Data** | **Optional** | Use to pull any of the “needed” or “optional” datasets above. |
| **Humanitarian Outcomes data** | **Optional** | Depends on content; add if it adds security/access indicators. |
| **IATI Activities** | **Optional** | Aid flows; useful for “funding vs need” analysis, not core to vulnerability score. |
| **IBTrACS Storm Tracks** | **Optional** | Climate shocks; you have EM-DAT and climate vulnerability. Add for storm-specific analysis. |
| **IFRC** | **Optional** | Can add emergency/response context; not core to score. |
| **IGAD ICPAC** | **Optional** | Regional (East Africa) climate; add if focusing on that region. |
| **OCHA HPC Tools** | **Optional** | Process/planning; not a direct data source for the app. |
| **Operation Presence** | **Optional** | Context on where operations are; not core to score. |
| **Rainfall Data** | **Optional** | Complements climate vulnerability; add for drought/rainfall analysis. |
| **Requirements and Funding Data** | **Optional** | Useful for “funding gap” and FTS-style analysis. |
| **UN: Peacekeeping, Mission Fatalities, Personnel, Police Fatalities, Security Council, Trust Fund, Uniformed Deaths, WPS, Voting, etc.** | **Optional** | Conflict/peace context; you have ACLED. Add for UN-specific or governance angles. |
| **USGS: Magnitude 2.5+ Earthquakes** | **Optional** | You have EM-DAT; add if you want earthquake-specific shocks. |
| **WFP Hungermaps** (Ukraine, Syria, Nigeria, Haiti, etc.) | **Optional** | Subnational/crisis-specific; good for deep-dives on those countries, not for global score. |
| **WHO: SSA on Healthcare** | **Optional** | Health systems; you have WHO stunting. Add for health-systems analysis. |
| **Aid Worker Security Database** | **Not needed** | Focus is aid worker safety; tangential to hunger. |
| **Airport Data** | **Not needed** | Not relevant to hunger vulnerability. |
| **Covid 19 Funding Data** | **Not needed** | One-off; out of scope for ongoing hunger vulnerability. |
| **Facebook Social Connectedness Index** | **Not needed** | Not relevant to hunger. |
| **Real-time energy/currency prices** | **Not needed** | Out of scope for hunger vulnerability. |


**Summary:** Prioritize **Internal Displacement Updates (IDU)**, **UNHCR monthly**, **OCHA FTS**, **FAO DIEM**, and **IOM** for hunger and vulnerability. Add others as needed for regional or funding analysis.

---

## 🚨 **CRITICAL ISSUES IDENTIFIED**

### **1. Country Name Standardization** ✅ **ADDRESSED**

**Status:** Standardization has been expanded and fuzzy matching added.

**What was done:**
1. **Mapping table** – The app loads `country_name_mapping.csv` in the project root (200+ variants: World Bank, UN, FAO style names → one canonical name per country). You can add rows to this file for new variants.
2. **Inline overrides** – `standardize_country_names()` still applies WB/UN-style overrides (e.g. "Venezuela, RB", "Yemen, Rep.", "Macedonia, FYR" → "Venezuela", "Yemen", "North Macedonia").
3. **Fuzzy matching** – Before each merge, country names from each data source are matched to the backbone list via `match_country_to_backbone()` (Levenshtein distance ≤ 4). Names that still don’t match after the mapping table get a best fuzzy match when possible.
4. **Merge coverage** – When the app runs interactively, it prints how many countries have undernourishment, poverty, GHI, and displaced data after merging.

**If you need to add variants:** Edit `country_name_mapping.csv` (columns: `original_name`, `standardized_name`). Use the same standardized names as in the app (e.g. "Czechia", "North Macedonia", "Sao Tome and Principe"). No code change required.

---

### **Afghanistan: Why some indicators are missing**

Verified against raw data and loaders:

| Indicator | Status | Reason |
|-----------|--------|--------|
| **Poverty** | Often missing | World Bank `SI.POV.DDAY` is frequently NA for Afghanistan in the WB file; OWID may not cover AFG or may not merge. |
| **Literacy** | Missing | World Bank `SE.ADT.LITR.ZS` is NA for Afghanistan in the source data. |
| **WFP GRFC (IPC phase)** | NA in file | `grfc2025_data.csv` has a row for Afghanistan but `ipc_phase` is NA (population_phase3_plus is 33.9M). IPC general and IPC population analysis now supplement and can fill phase where available. |
| **Import share (trade)** | Missing | Trade dependency data uses **importer** country; Afghanistan appears only as **exporter** in the file, so there is no importer row for Afghanistan and thus no import share. |
| **Displaced** | Should be present | UNHCR `persons_of_concern.csv` has Afghanistan as “Country of Asylum” with IDPs (e.g. 2.55M in 2019). Loader aggregates by Country of Asylum, so Afghanistan should get `total_displaced_latest` after merge. If still missing, check column names or filters. |
| **GHI** | Missing | Afghanistan is not included in the GHI 2025 country list (common for fragile/conflict states). |

Use the **Data Coverage** tab in the app to confirm current merge results for Afghanistan and any other country.

---

### **2. UNHCR Displaced People Data** ✅ **FIXED**

**Status:** ✅ **WORKING** – Loader updated to use actual CSV column names (e.g. `Asylum-seekers`, `Other people in need of international protection`). **179 countries** with displacement data. Integrated into vulnerability score and country details.

---

### **3. Limited Coverage in Key Data Sources**

**WFP GRFC Data:** 48 countries; **IPC/CH** now integrated from three sources to supplement.
- **IPC general data** (`ipc data general data.csv`): one row per country, phase 1–5 and Phase 3+ population (~31 countries).
- **IPC population analysis** (`IPC data population analysis.xlsx`): Population Tracking Tool; latest analysis per country (ISO2-based).
- **IPC historical** (`ipc all data 2017-2025.csv`): country-year panel (2017–2025); latest year used in merge after the two above; full panel in **GRFC & IPC Trends** tab. Merge order: GRFC → general IPC → population analysis → IPC historical (latest year).
- **Still missing / not obtained:** **FEWS NET** (Famine Early Warning Systems Network) – food security classifications and alerts were not obtained.
- **Other alternatives:** **FAO GIEWS** (Global Information and Early Warning System) – country-level food security and crop assessments.

**Food Trade Dependency:** Only 66 countries
- Missing: Many import-dependent countries
- **Alternative data sources:** (1) **FAO FAOSTAT** – trade (cereals, food) and food balance sheets by country; (2) **World Bank** – indicators such as food imports (% of merchandise imports) and trade; (3) **UN Comtrade** – detailed trade data by country and product.

**GHI Scores:** **123 countries** in current integration
- Missing: Some countries not in the GHI report
- **Alternative data sources:** (1) **FAO** – prevalence of undernourishment (already in app; use as proxy where GHI missing); (2) **WHO/UNICEF JME** – child malnutrition (wasting, stunting) for comparison; (3) **National household surveys** – DHS, MICS, or other national food security / nutrition surveys where GHI is not computed.

**Historical Hunger Outbreaks:** 18 countries
- **Alternative data sources:** (1) **EM-DAT** (CRED) – famine and disaster events; (2) **Academic / grey literature** – famine databases and case studies; (3) **FAO / WFP** – major food crises and emergency reports by country and year.

**Food Supply (kcal):** 241 countries
- **Alternative data sources:** (1) **FAO FAOSTAT** – food balance sheets (supply, kcal/capita/day); (2) **IFPRI** – food security and supply indicators; (3) **National statistics** – official food balance or consumption surveys.

**Water Resources:** 199 countries
- **Alternative data sources:** (1) **FAO AQUASTAT** – water use, resources, and stress by country; (2) **WRI Aqueduct** – water risk and availability; (3) **UN Water / national statistics** – country-level water data.

**USDA (TFP / productivity):** 225 countries in source file
- **Alternative data sources:** (1) **FAO FAOSTAT** – production, yields, and land use; (2) **IFPRI** – agricultural productivity and TFP where available; (3) **National agricultural statistics** – official ag agencies.

**UNHCR (displaced):** 179 countries
- **Alternative data sources:** (1) **IDMC** (Internal Displacement Monitoring Centre) – IDPs and displacement events; (2) **IOM** (Migration data portal, DTM) – displacement and migration; (3) **UN OCHA** – humanitarian and displacement figures.

**ACLED (conflict):** 180 countries
- **Alternative data sources:** (1) **UCDP** (Uppsala Conflict Data Program) – conflict and fatalities; (2) **PRIO** – conflict and political violence; (3) **SIPRI** – conflict and arms data.

**WPR malnutrition:** 169 countries
- **Alternative data sources:** (1) **WHO Global Health Observatory** – malnutrition and health indicators; (2) **UNICEF** – child malnutrition and nutrition; (3) **National surveys** – DHS, MICS, or national nutrition reports.

**Literacy (missing in many countries):**
- **Alternative data sources:** (1) **UNESCO** – literacy and education statistics; (2) **World Bank** – other education indicators (e.g. school enrollment); (3) **National census / surveys** – literacy from census or household surveys.

---

### **4. Data Quality Issues**

**Poverty Data:**
- World Bank `SI.POV.DDAY` missing for many countries (especially conflict zones)
- OWID poverty data (195 countries) should fill some gaps but may not merge due to name issues
- Need: Better fallback logic and name matching

**Literacy Rate:**
- World Bank `SE.ADT.LITR.ZS` missing for many countries
- No alternative source currently integrated
- Need: Find alternative literacy data source or accept missing values

**WFP IPC Phase:**
- GRFC 2025 covers 48 countries. **IPC/CH** supplements from two files: general data CSV (~31 countries) and population analysis xlsx (latest analysis per country); same IPC phase and Phase 3+ used where GRFC missing.
- Remaining gaps: countries in neither GRFC nor either IPC file; historical IPC by year for panel analysis.

---

## 🎯 **IMMEDIATE ACTION ITEMS (Priority Order)**

### **Week 1: Fix Critical Data Integration Issues**

#### **1. UNHCR Data Loading** ✅ **DONE**
- [x] Fixed `rowSums()` / column names in `load_refugee_data()`
- [x] Displaced people integrated into vulnerability score and country details

#### **2. Country Name Standardization** ✅ **DONE**
- [x] Country name mapping table (`country_name_mapping.csv`) with 200+ variants
- [x] Fuzzy matching fallback before each merge (`match_country_to_backbone`)
- [x] Merge coverage reported on load (undernourishment, poverty, GHI, displaced)
- [ ] Optional: add more variants to `country_name_mapping.csv` as you find new source names

#### **3. Verify and Fix Data Merging** ✅ **DONE**
- [x] **Afghanistan:** Checked why poverty, literacy, WFP, import, displaced, GHI are missing or NA (see “Afghanistan: Why some indicators are missing” below).
- [x] **Standardized names:** All data loaders use `standardize_country_names()` and/or `map_data_countries_to_backbone()` before merge; country name mapping table and fuzzy matching are in place.
- [x] **Merge validation:** On app load (interactive), the app prints merge coverage counts and Afghanistan-specific missing indicators; a structured `merge_validation_report` and `merge_validation_summary` are built for the Data Coverage tab.
- [x] **Data coverage dashboard:** New **Data Coverage** tab in the app shows: (1) coverage by indicator (count and % of countries with data), (2) countries with fewest indicators, (3) searchable/sortable per-country table (✓/— for each indicator).

---

### **Week 2: Expand Data Coverage**

#### **4. Improve WFP GRFC / IPC Coverage** ✅ **PARTIALLY DONE**
- [x] IPC/CH data integrated to supplement GRFC (fills IPC phase and Phase 3+ where GRFC missing)
- [x] Historical GRFC: **`grfc2016-2024_data.xlsx`** in `data/raw/wfp/` is loaded for 2016–2024. The app also loads any `grfcYYYY_data.csv` (e.g. `grfc2025_data.csv`). Expected columns (xlsx or CSV): `country` (or Country), `assessment_year` (or Year), `ipc_phase`, `population_phase3_plus`. Latest assessment per country is used.
- [x] **Use** multiple years of GRFC in the app for panel analysis (time series / trends) — *GRFC Trends tab added: over-time chart (IPC phase or Phase 3+ population by year, multi-country), plus panel CSV export and table preview.*
- [ ] Consider FEWS NET if access becomes available

#### **5. Expand Food Trade Dependency Data**
- [ ] Check FAO trade statistics for additional countries
- [ ] Integrate World Bank trade indicators
- [ ] Calculate import dependency from trade balance data
- [ ] Add cereal import dependency specifically

#### **6. Find Alternative Literacy Data Source**
- [ ] Check UNESCO literacy statistics
- [ ] Check World Bank alternative education indicators
- [ ] Use education enrollment as proxy if literacy unavailable
- [ ] Accept missing values with clear indication in UI

---

### **Week 3: Enhance Data Quality**

#### **7. Improve Poverty Data Coverage**
- [ ] Verify OWID poverty data is merging correctly
- [ ] Check World Bank PIP (Poverty and Inequality Platform) data
- [ ] Add multiple poverty thresholds ($1.90, $3.20, $5.50)
- [ ] Use GDP per capita as proxy for missing poverty data

#### **8. Verify GHI Data Integration**
- [ ] Check GHI data coverage (how many countries?)
- [ ] Verify country name matching for GHI
- [ ] Add GHI component breakdown (undernourishment, child wasting, stunting, mortality)
- [ ] Use GHI for validation and comparison

---

## 📈 **STATISTICAL ANALYSIS RECOMMENDATIONS**

### **Data to collect for your statistical analysis (aligned with integrated app)**

The app’s vulnerability score, correlation matrix, regression tools, and time series rely on the variables below. Collect or improve these to run robust statistical analysis.

**Outcome / target variables**
- **Hunger vulnerability score (0–100)** – computed in-app; keep inputs below so the score is reproducible.
- **Undernourishment rate (%)** – primary hunger indicator; needed for validation and as outcome in regressions.
- **GHI (Global Hunger Index)** – for validating your vulnerability score (correlation, comparison).
- **Crisis outcomes** (for prediction/validation): GRFC IPC phase, major hunger outbreak (21st C), and (when fixed) displaced population.

**Predictor / input variables (by category)**

| Category | Variables to collect | Used in app for |
|---------|---------------------|------------------|
| **Demographics** | Population, rural population (%) | Score context; correlation/regression |
| **Economy** | GDP, GDP per capita, poverty ($1.90/day), poverty ($3/day), inflation | Vulnerability score (poverty + GDP); correlation matrix |
| **Food & agriculture** | Undernourishment (%), food supply (kcal/capita/day), agricultural land (%), crop production, food import share (avg/max), USDA TFP index | Score (undernourishment, food supply, trade dependency); regressions |
| **Health** | Life expectancy, infant mortality, stunting rate (%), literacy (%) | Score (life expectancy, stunting); correlation/regression |
| **Climate & environment** | Climate vulnerability index, water per capita (m³), agricultural water withdrawals (%) | Score (climate, water stress); regression |
| **Crisis & shocks** | GRFC IPC phase, Phase 3+ population; displaced people (refugees + IDPs); active conflict (Y/N), conflict intensity, total fatalities; disasters (5yr count, latest year); major hunger outbreak 21st C, outbreak count | Score (conflict, outbreaks, trade); crisis prediction |
| **Comparison** | GHI score | Validation and comparison analyses |

**Time dimension**
- **Cross-section:** One row per country (latest year) – what the app uses for maps and most summaries.
- **Panel (country–year):** Same variables by **country and year** for:
  - Vulnerability score over time (trend charts)
  - Regional and temporal analysis
  - Time series and forecasting
- **Priority time series:** Undernourishment, poverty, GDP per capita, life expectancy (already used in-app for trend); add conflict, disasters, and GRFC by year where available.

**Minimum data for core analyses**
- **Correlation matrix:** Need non-missing values for the variables you include; the app uses population, GDP per capita, poverty, agriculture land, life expectancy, literacy, undernourishment, vulnerability score. Collect these at minimum for as many countries as possible.
- **Regression (e.g. vulnerability or undernourishment as outcome):** Same predictors as above; prioritize undernourishment, poverty, GDP per capita, life expectancy, conflict, and (when fixed) displacement.
- **Score validation (vs GHI):** GHI + your vulnerability score; both need consistent country coverage and naming.
- **Crisis prediction:** Outcome = crisis indicator (e.g. IPC ≥ 3 or major outbreak); predictors = conflict, disasters, poverty, undernourishment, trade dependency, climate. Collect crisis outcomes and predictors by country (and by year if doing panel).

**Gaps that limit analysis (fix first)**
1. **UNHCR displaced people** – fix load; then integrate into score and use in regression/prediction.
2. **Country name / ISO alignment** – ensure all sources use the same country identifiers so merges don’t drop countries.
3. **WFP GRFC** – expand to more countries and, if possible, historical years for panel and prediction.
4. **Trade dependency** – expand beyond 66 countries for regression and score quality.
5. **Literacy** – many missing; add UNESCO or other source if literacy is in your models.

---

### **1. Data Coverage Analysis**

**Create Reports:**
- [ ] **Data Completeness Matrix:** Country × Indicator matrix showing which data exists
- [ ] **Coverage Statistics:** % of countries with data for each indicator
- [ ] **Missing Data Patterns:** Identify countries/regions with systematic data gaps
- [ ] **Temporal Coverage:** Years of data available for each country/indicator

**Metrics to Track:**
- Overall data completeness (%)
- Coverage by region
- Coverage by income level
- Coverage by conflict status
- Coverage trends over time

---

### **2. Data Quality Assessment**

**Validation Checks:**
- [ ] **Outlier Detection:** Identify countries with extreme values that may be errors
- [ ] **Consistency Checks:** Compare related indicators (e.g., poverty vs GDP)
- [ ] **Temporal Consistency:** Check for sudden jumps/drops in time series
- [ ] **Cross-Source Validation:** Compare same indicator from different sources

**Quality Metrics:**
- Data freshness (years since last update)
- Source reliability scores
- Completeness scores by country
- Confidence intervals for estimates

---

### **3. Vulnerability Score Validation**

**Validation Approaches:**
- [ ] **GHI Comparison:** Correlate vulnerability score with GHI scores
- [ ] **Crisis Prediction:** Test if high scores predict actual food crises
- [ ] **Component Analysis:** Identify which components drive scores most
- [ ] **Sensitivity Analysis:** Test how score changes with missing data

**Statistical Tests:**
- Correlation analysis (vulnerability score vs GHI)
- Regression analysis (predicting actual crises)
- Factor analysis (identifying key drivers)
- Cluster analysis (grouping similar countries)

---

### **4. Predictive Modeling**

**Models to Develop:**
- [ ] **Crisis Prediction Model:** Predict food crises 6-12 months ahead
- [ ] **Score Forecasting:** Project vulnerability scores forward
- [ ] **Risk Classification:** Classify countries into risk categories
- [ ] **Early Warning System:** Identify countries approaching crisis thresholds

**Machine Learning Approaches:**
- Random Forest for feature importance
- Time series forecasting (ARIMA, Prophet)
- Classification models (logistic regression, decision trees)
- Ensemble methods for robust predictions

---

### **5. Regional and Temporal Analysis**

**Analyses to Conduct:**
- [ ] **Regional Trends:** How vulnerability changes by region over time
- [ ] **Country Trajectories:** Identify countries improving/worsening
- [ ] **Shock Analysis:** Impact of conflicts, disasters, economic crises
- [ ] **Recovery Patterns:** How countries recover from food crises

**Visualizations:**
- Heatmaps of vulnerability by region/year
- Trajectory plots for individual countries
- Shock impact analysis charts
- Recovery timeline visualizations

---

## 🔬 **ADVANCED STATISTICAL ANALYSES**

### **1. Causal Inference**

**Research Questions:**
- What factors causally drive hunger vulnerability?
- Does conflict cause food insecurity or vice versa?
- Impact of climate shocks on food security
- Effectiveness of interventions

**Methods:**
- Difference-in-differences
- Instrumental variables
- Regression discontinuity
- Propensity score matching

---

### **2. Network Analysis**

**Applications:**
- Food trade networks (identify critical import dependencies)
- Refugee flow networks (track displacement patterns)
- Conflict spillover effects (regional instability)
- Aid distribution networks

**Tools:**
- Network graphs
- Centrality measures
- Community detection
- Influence analysis

---

### **3. Spatial Analysis**

**Applications:**
- Geographic clustering of food insecurity
- Border effects (conflict spillover)
- Climate zone impacts
- Resource distribution patterns

**Methods:**
- Spatial autocorrelation
- Hotspot analysis
- Spatial regression
- Geographic weighted regression

---

## 📋 **DATA COLLECTION PRIORITIES**

### **HIGHEST PRIORITY - Fix Existing Data**

1. **Fix UNHCR loading error** - Critical for displacement data
2. **Expand country name standardization** - Critical for all data merging
3. **Verify all data sources merge correctly** - Ensure no silent failures

### **HIGH PRIORITY - Expand Coverage**

4. **Historical GRFC data** - Expand WFP coverage beyond 2025
5. **FAO trade statistics** - Expand food import dependency coverage
6. **UNESCO literacy data** - Fill literacy gaps
7. **World Bank PIP poverty data** - Expand poverty coverage

### **MEDIUM PRIORITY - New Data Sources**

8. **Food price inflation** - Country-level food CPI data
9. **Agricultural productivity** - Crop yields, TFP (expand USDA coverage)
10. **Governance indicators** - World Bank WGI
11. **Social protection** - World Bank ASPIRE database
12. **Food waste/loss** - FAO Food Loss Index

---

## 🛠️ **IMPLEMENTATION CHECKLIST**

### **Data Integration Fixes**
- [ ] Fix UNHCR data loading function
- [ ] Expand `standardize_country_names()` to 200+ variations
- [ ] Add ISO-3 code-based merging as primary method
- [ ] Create data merge validation report
- [ ] Test with high-priority countries (Afghanistan, Venezuela, etc.)

### **Data Coverage Expansion**
- [ ] Integrate historical GRFC data (2020-2024)
- [ ] Expand food trade dependency to all countries with trade data
- [ ] Add UNESCO literacy statistics
- [ ] Integrate World Bank PIP poverty data
- [ ] Verify GHI data coverage and fix name matching

### **Statistical Analysis Setup**
- [ ] Create data completeness dashboard
- [ ] Implement outlier detection
- [ ] Set up GHI validation analysis
- [ ] Create crisis prediction model framework
- [ ] Build regional trend analysis tools

### **Documentation**
- [ ] Document all data sources and coverage
- [ ] Create data quality report template
- [ ] Document statistical methods used
- [ ] Create user guide for interpreting scores

---

## 📊 **SUCCESS METRICS**

### **Data Coverage Goals**
- **Target:** 90%+ of countries have data for core indicators (poverty, GDP, life expectancy)
- **Target:** 80%+ of countries have vulnerability-relevant data (conflict, disasters, trade)
- **Target:** 100% of high-risk countries (vulnerability score ≥75) have complete data

### **Data Quality Goals**
- **Target:** <5% of data points flagged as outliers
- **Target:** >0.7 correlation between vulnerability score and GHI
- **Target:** <10% of countries with >50% missing indicators

### **Analysis Goals**
- **Target:** Crisis prediction model with >70% accuracy
- **Target:** Identify top 5 drivers of vulnerability
- **Target:** Regional trend analysis for all major regions

---

## 🔗 **KEY DATA SOURCE URLs**

1. **UNHCR:** https://www.unhcr.org/refugee-statistics/
2. **WFP GRFC:** https://www.fsinplatform.org/global-report-food-crises
3. **FAO Trade:** https://www.fao.org/faostat/en/#data/TP
4. **UNESCO Literacy:** http://uis.unesco.org/en/topic/literacy
5. **World Bank PIP:** https://pip.worldbank.org/
6. **World Bank WGI:** https://databank.worldbank.org/source/worldwide-governance-indicators
7. **FAO Food Loss Index:** https://www.fao.org/sustainable-development-goals/indicators/1231/en/

---

## 💡 **KEY INSIGHTS**

1. **Country name matching is the #1 blocker** - Most data exists but fails to merge
2. **UNHCR data is critical but broken** - Needs immediate fix
3. **WFP coverage is limited** - Only 48 countries, need historical data
4. **Trade dependency data is sparse** - Only 66 countries, need expansion
5. **Validation is essential** - Use GHI to validate vulnerability scores

---

## 🔧 **MITIGATING THE IMPACTS OF DATA GAPS**

When key indicators are missing, scores can be biased (e.g. countries with no data get 0 for that factor). Below are practical ways to reduce the impact of missing data.

### **1. Do not treat “no data” as “low risk”**
- **Current:** Missing values often default to 0 in the formula, so data-poor countries can get artificially low scores.
- **Mitigation:** Use a **“data availability” or “coverage” flag** per country (e.g. share of factors with non-missing data). Grey out or separate low-coverage countries on the map and in tables, or show a “Data quality: Low coverage” badge so users don’t treat the score as comparable to well-covered countries.

### **2. Show transparency in the UI**
- **Score breakdown:** For each country, show which components had data (e.g. “Undernourishment: 12 pts (data); Poverty: 0 pts (no data)” with a small “no data” label).
- **Tooltip / footnote:** e.g. “Score based on 8 of 12 factors; 4 factors had no data.” This makes gaps explicit and avoids over-interpreting sparse scores.

### **3. Imputation with clear caveats**
- **Regional or peer imputation:** For a missing indicator (e.g. undernourishment), fill with the regional median or a similar country’s value, then **flag** “Imputed” in the breakdown and in exports. Use only for display/exploration, not for high-stakes comparisons.
- **Model-based imputation:** Use a simple model (e.g. predict undernourishment from poverty, GDP, region) and show “Estimated” or “Imputed” so users know the value is not observed.

### **4. Sensitivity and robustness**
- **Score under different assumptions:** e.g. “If missing factors were set to the sample median, score = X; if set to the 75th percentile (high risk), score = Y.” Shows how much the score depends on the missing data.
- **Bounds:** Publish “Lower bound” (all missing = 0) and “Upper bound” (all missing = max points) so the true score is understood to lie in an interval when coverage is low.

### **5. Flag “likely inaccurate” and low-coverage countries**
- **Already in place:** Grey on map + hover disclaimer for countries with known unreliable official data (e.g. North Korea, Eritrea, Turkmenistan).
- **Extension:** Add a **“Low data coverage”** category (e.g. &lt; 50% of factors non-missing) and style them differently (e.g. hatched or lighter shade) so they are not over-interpreted.

### **6. Use the score only when coverage is sufficient**
- **Optional rule:** Only show or rank the vulnerability score when at least N of the main factors have data (e.g. undernourishment or poverty, plus at least 4 others). Below that, show “Insufficient data for score” and list what is available instead of a single number.

### **7. Prioritize filling the most influential gaps**
- **Focus collection on:** (1) Undernourishment and poverty (largest weights), (2) conflict and shocks (high impact), (3) countries that are currently grey or have very low coverage. A small number of high-value series (e.g. undernourishment for the top 20 data-sparse countries) can reduce bias more than many minor indicators.

### **8. Document and version assumptions**
- In the methodology doc or app, state clearly: how missing values are handled (0, imputed, or excluded), which countries are flagged as unreliable or low-coverage, and that scores are not comparable when coverage differs. This protects both researchers and users.

---

## 📝 **NEXT STEPS**

1. **Immediate (This Week):**
   - Fix UNHCR data loading error
   - Expand country name standardization function
   - Verify data merging for Afghanistan and other high-priority countries

2. **Short-term (Next 2 Weeks):**
   - Integrate historical GRFC data
   - Expand food trade dependency coverage
   - Add UNESCO literacy data
   - Create data completeness dashboard

3. **Medium-term (Next Month):**
   - Implement statistical validation analyses
   - Build crisis prediction model
   - Create regional trend analysis
   - Document all data sources and methods

4. **Long-term (Next Quarter):**
   - Set up automated data collection pipeline
   - Implement real-time data updates
   - Build early warning system
   - Publish research findings

---

**Last Updated:** February 2026  
**Status:** Active Development - Critical Issues Identified; Data Requirements for Statistical Analysis Documented
