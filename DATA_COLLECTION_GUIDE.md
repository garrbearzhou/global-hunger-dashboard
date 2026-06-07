# Data Collection Guide - Missing Data for Hunger Vulnerability Analysis

## 📊 Current Data Status

### Overall Coverage
- **Total Countries:** 206
- **Countries with Vulnerability Scores:** 206 (100% coverage)
- **Countries with Undernourishment Data:** 159 (77%)
- **Countries with Poverty Data:** 163 (79%)
- **Countries with GDP Data:** 175 (85%)
- **Countries with Life Expectancy Data:** 184 (89%)
- **Countries with Gini Coefficient Data:** 162 (79%)
- **Countries with WFP Market Data:** 98 (48%)

---

## 🎯 Priority Data to Collect

### **1. CRITICAL: Undernourishment Data (Missing for 38 countries)**

**Why it's critical:** This is the PRIMARY factor in vulnerability calculation (0-40 points, 40% of total score)

**Missing for key countries:**
- **Afghanistan** ⚠️ (High priority - currently has vulnerability score of 73.5 but missing this critical data)
- Yemen
- Somalia
- Eritrea
- North Korea
- Iran
- Egypt
- Sudan
- Venezuela
- And 30 others

**Where to collect:**
- **FAO (Food and Agriculture Organization)**: Primary source
  - Website: https://www.fao.org/faostat/en/#data/FS
  - Dataset: "Prevalence of undernourishment"
  - Update frequency: Annual
  - Latest data: 2022-2024

**Action items:**
1. Download latest FAO Food Security Indicators dataset
2. Focus on countries with missing data
3. Check for alternative names (e.g., "Iran, Islamic Rep." vs "Iran")

---

### **2. HIGH PRIORITY: Poverty Data (Missing for 34 countries)**

**Why it's important:** Second most important factor (0-20 points, 20% of total score)

**Missing for key countries:**
- **Afghanistan** ⚠️ (High priority)
- Yemen
- Somalia
- Eritrea
- North Korea
- Iran
- Egypt
- Saudi Arabia
- And 26 others

**Where to collect:**
- **World Bank Poverty and Inequality Platform (PIP)**: Primary source
  - Website: https://pip.worldbank.org/
  - Dataset: "Poverty headcount ratio at $1.90/day"
  - Update frequency: Annual
  - Latest data: 2022-2023

- **World Bank Open Data**: Alternative source
  - Indicator: SI.POV.DDAY (Poverty headcount ratio at $1.90/day)
  - Website: https://data.worldbank.org/indicator/SI.POV.DDAY

**Action items:**
1. Download latest PIP dataset (pip 2.csv or pip.csv)
2. Check World Bank API for missing countries
3. For Afghanistan specifically, check:
   - World Bank country profile
   - UN Development Programme (UNDP) reports
   - National statistical office reports

---

### **3. MEDIUM PRIORITY: Gini Coefficient Data (Missing for 35 countries)**

**Why it's useful:** Measures inequality (0-8 points, 8% of total score)

**Missing for key countries:**
- **Afghanistan** ⚠️
- Yemen
- Somalia
- Eritrea
- North Korea
- Iran
- Saudi Arabia
- And 28 others

**Where to collect:**
- **World Bank Open Data**: Primary source
  - Indicator: SI.POV.GINI (Gini coefficient)
  - Website: https://data.worldbank.org/indicator/SI.POV.GINI

- **World Income Inequality Database (WIID)**: Alternative source
  - Website: https://www.wider.unu.edu/database/world-income-inequality-database-wiid

**Action items:**
1. Download latest Gini coefficient data from World Bank
2. Check WIID for countries missing in World Bank data
3. For conflict-affected countries, check UN/UNDP reports

---

### **4. DISABLED FACTORS (Currently Not Used - High Value if Collected)**

These factors are currently disabled in your vulnerability calculation but would add significant value:

#### **A. Child Stunting Data (0-8 points potential)**
- **Source:** WHO Global Health Observatory
- **Indicator:** Prevalence of stunting in children under 5
- **Why valuable:** Direct indicator of chronic malnutrition
- **Website:** https://www.who.int/data/gho/data/indicators

#### **B. Agricultural Productivity Data (0-6 points potential)**
- **Source:** FAO
- **Indicator:** Crop production index, agricultural value added
- **Why valuable:** Measures food production capacity
- **Website:** https://www.fao.org/faostat/en/#data/QI

#### **C. Food Production Data (0-4 points potential)**
- **Source:** FAO
- **Indicator:** Food production index, cereal production
- **Why valuable:** Measures actual food availability
- **Website:** https://www.fao.org/faostat/en/#data/QCL

#### **D. Climate Vulnerability Data (0-6 points potential)**
- **Source:** Notre Dame Global Adaptation Initiative (ND-GAIN)
- **Indicator:** Climate vulnerability index
- **Why valuable:** Measures climate-related food security risks
- **Website:** https://gain.nd.edu/

#### **E. Health Vulnerability Data (0-8 points potential)**
- **Source:** WHO, World Bank
- **Indicators:** Maternal mortality, child mortality, access to healthcare
- **Why valuable:** Health status affects food security
- **Website:** https://www.who.int/data/gho

---

## 🔍 Specific Data Collection for Afghanistan

### **Current Status:**
- ✅ GDP per capita: Available (414 USD in 2023)
- ✅ Life expectancy: Available (66 years)
- ❌ Undernourishment rate: **MISSING** (Critical!)
- ❌ Poverty rate: **MISSING** (High priority!)
- ❌ Gini coefficient: **MISSING** (Medium priority)
- ❌ WFP market data: **MISSING** (Low priority - WFP may not operate there)

### **Recommended Sources for Afghanistan:**

1. **FAO Data:**
   - Check FAO country profile: https://www.fao.org/countryprofiles/index/en/?iso3=AFG
   - Look for "Prevalence of undernourishment" in recent years
   - May need to check alternative FAO datasets

2. **World Bank:**
   - Country profile: https://data.worldbank.org/country/afghanistan
   - Check for poverty data in recent years (may be limited due to conflict)
   - Check World Bank reports on Afghanistan

3. **UN Sources:**
   - **UN OCHA (Office for Coordination of Humanitarian Affairs)**: https://www.unocha.org/
   - **WFP Country Briefs**: https://www.wfp.org/countries/afghanistan
   - **UNICEF**: May have child nutrition data

4. **National Sources:**
   - Afghanistan Central Statistics Organization (if accessible)
   - Ministry of Agriculture, Irrigation and Livestock reports

5. **Research/Academic Sources:**
   - Recent academic papers on food security in Afghanistan
   - International research organizations (IFPRI, etc.)

---

## 📋 Data Collection Checklist

### **Immediate Priority (For Afghanistan and similar high-vulnerability countries):**

- [ ] **Undernourishment data** - Check FAO, UN sources, country reports
- [ ] **Poverty data** - Check World Bank PIP, country statistical offices
- [ ] **Gini coefficient** - Check World Bank, WIID, country reports

### **Short-term Priority (To improve overall model):**

- [ ] **Child stunting data** - WHO Global Health Observatory
- [ ] **Agricultural productivity** - FAO datasets
- [ ] **Food production data** - FAO datasets
- [ ] **WFP market data** - For countries where WFP operates

### **Long-term Priority (To enable disabled factors):**

- [ ] **Climate vulnerability index** - ND-GAIN database
- [ ] **Health vulnerability indicators** - WHO, World Bank
- [ ] **Conflict/disaster data** - EM-DAT (already have, but can expand)

---

## 🛠️ Data Collection Scripts

### **Recommended Approach:**

1. **Automated Data Collection:**
   - Use R packages: `WDI` (World Bank), `FAOSTAT` (FAO), `rgho` (WHO)
   - Create scripts to automatically download latest data
   - Set up scheduled updates

2. **Manual Data Collection:**
   - For countries with missing data, manually check:
     - Country statistical office websites
     - UN agency reports
     - Academic research papers
     - NGO reports (Oxfam, Save the Children, etc.)

3. **Data Validation:**
   - Cross-reference multiple sources
   - Check for data quality flags
   - Verify country name consistency

---

## 📊 Impact of Collecting Missing Data

### **For Afghanistan specifically:**

**Current vulnerability score:** 73.5/100

**If we add missing data:**
- **Undernourishment data (28.1% based on debug output):** Would add ~22.5 points (28.1 × 0.8)
- **Poverty data (estimated 50-70%):** Would add 20 points (capped)
- **Gini coefficient (estimated 0.3-0.4):** Would add 4 points

**Potential new score:** ~95-100/100 (more accurate representation of extreme vulnerability)

### **For overall model:**

- **Better accuracy:** More complete data = more accurate vulnerability scores
- **Better coverage:** Currently 38 countries missing critical undernourishment data
- **Enable disabled factors:** Collecting child stunting, climate, health data would enable 32 additional points in vulnerability calculation

---

## 🔗 Key Data Sources Summary

| Data Type | Primary Source | Alternative Sources | Update Frequency |
|-----------|---------------|---------------------|------------------|
| Undernourishment | FAO FAOSTAT | UN, Country reports | Annual |
| Poverty | World Bank PIP | World Bank Open Data, Country stats | Annual |
| GDP | World Bank | IMF, Country stats | Annual |
| Life Expectancy | World Bank | WHO, UN | Annual |
| Gini Coefficient | World Bank | WIID, Country stats | Annual |
| Child Stunting | WHO | UNICEF, Country reports | Annual |
| Agricultural Data | FAO | Country reports | Annual |
| Climate Vulnerability | ND-GAIN | Various | Annual |
| Health Indicators | WHO | World Bank, Country reports | Annual |
| Market Data | WFP | Country reports | Monthly/Annual |

---

## 📝 Next Steps

1. **Immediate:** Collect undernourishment and poverty data for Afghanistan
2. **Short-term:** Expand data collection for all 38 countries missing undernourishment data
3. **Medium-term:** Collect data for disabled factors (stunting, climate, health)
4. **Long-term:** Set up automated data collection pipeline

---

## 💡 Tips for Data Collection

1. **Country name variations:** Be aware of different naming conventions (e.g., "Iran" vs "Iran, Islamic Rep.")
2. **Data years:** Some countries may have data for different years - use most recent available
3. **Data quality:** Check for flags indicating data quality (estimated, imputed, etc.)
4. **Multiple sources:** Cross-reference data from multiple sources when possible
5. **Documentation:** Keep track of data sources and collection dates for reproducibility

