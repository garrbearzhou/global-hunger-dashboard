# New Data Sources Integration Summary

## ✅ Successfully Processed Data Sources

### 1. **Climate Vulnerability Index** (Global Data Lab)
- **Source:** `data/raw/global_data_lab/climate vunerability index.csv`
- **Coverage:** 118 countries (312 total entries including subnational)
- **Afghanistan Value:** 76.8 (2023) - **VERY HIGH VULNERABILITY**
- **Status:** ✅ Ready to integrate
- **Impact:** Can enable **Climate Vulnerability Score (0-6 points)** in vulnerability calculation

### 2. **Health Vulnerability Data** (Global Data Lab)
- **Source:** `data/raw/global_data_lab/health vunerability data.csv`
- **Coverage:** 38 countries at national level
- **Afghanistan:** Not found at national level (may be subnational only)
- **Status:** ⚠️ Limited coverage
- **Impact:** Could supplement health indicators

### 3. **WHO Child Stunting Data**
- **Source:** `data/raw/who/child_stunting_data.csv`
- **Coverage:** 576 countries/regions
- **Afghanistan Values:** 41.4-42.7% (multiple years) - **VERY HIGH**
- **Status:** ✅ Ready to integrate
- **Impact:** Can enable **Child Stunting Score (0-8 points)** in vulnerability calculation

### 4. **Food Supply Data** (Our World in Data)
- **Source:** `data/raw/our_world_in_data/food supply data.csv`
- **Coverage:** 241 countries
- **Afghanistan Value:** 2,273.894 kcal/day (2022) - **BELOW RECOMMENDED** (2500 kcal/day)
- **Status:** ✅ Ready to integrate
- **Impact:** Can enable **Food Production Score (0-4 points)** in vulnerability calculation

### 5. **Poverty Data** (Our World in Data)
- **Source:** `data/raw/our_world_in_data/poverty data.csv`
- **Coverage:** 195 countries
- **Afghanistan:** Not found (may use different country name)
- **Status:** ⚠️ Need to check country name mapping
- **Impact:** Could supplement existing poverty data

### 6. **Agricultural Production Data** (USDA)
- **Source:** `data/raw/usda/agricultural_production_1.csv`
- **Coverage:** 234 countries
- **Afghanistan TFP Index:** 131.85 - **MODERATE**
- **Status:** ✅ Ready to integrate
- **Impact:** Can enable **Agricultural Productivity Score (0-6 points)** in vulnerability calculation

---

## 📊 Afghanistan Data Summary

### **New Data Available for Afghanistan:**

| Indicator | Value | Status | Impact on Vulnerability |
|-----------|-------|--------|------------------------|
| **Climate Vulnerability Index** | 76.8/100 | ✅ Available | Can add 4-6 points |
| **Child Stunting Rate (WHO)** | 41.4-42.7% | ✅ Available | Can add 6-8 points |
| **Food Supply** | 2,273.9 kcal/day | ✅ Available | Can add 2-4 points (below recommended) |
| **Agricultural TFP Index** | 131.85 | ✅ Available | Can add 2-4 points |
| **Poverty Below $3/day** | Not found | ❌ Missing | Need to check alternative sources |

### **Current Vulnerability Score:** 73.5/100
### **Potential New Score with All Data:** ~85-95/100

---

## 🔧 Integration Steps

### **Step 1: Update Data Loading in `enhanced_fao_wfp_app.R`**

Add this code to load the new processed data:

```r
# Load new data sources
new_data_sources <- read_csv("data/processed/new_data_sources_combined.csv", show_col_types = FALSE)
```

### **Step 2: Update Vulnerability Calculation Function**

The following factors can now be enabled:

#### **A. Climate Vulnerability Score (0-6 points)**
```r
climate_score = case_when(
  is.na(climate_vulnerability_index) ~ 0,
  climate_vulnerability_index >= 80 ~ 6,  # Very high vulnerability
  climate_vulnerability_index >= 70 ~ 4,  # High vulnerability (Afghanistan: 76.8)
  climate_vulnerability_index >= 60 ~ 2,  # Moderate vulnerability
  TRUE ~ 0
)
```

#### **B. Child Stunting Score (0-8 points)**
```r
stunting_score = case_when(
  !is.na(who_stunting_rate) ~ pmin(who_stunting_rate * 0.2, 8),  # Use WHO data
  !is.na(child_stunting_rate) ~ pmin(child_stunting_rate * 0.2, 8),  # Fallback to Global Data Lab
  TRUE ~ 0
)
# Afghanistan: 41.4% × 0.2 = 8.28 → capped at 8 points
```

#### **C. Food Production Score (0-4 points)**
```r
food_production_score = case_when(
  is.na(food_supply_kcal) ~ 0,
  food_supply_kcal < 2000 ~ 4,  # Very low food supply
  food_supply_kcal < 2200 ~ 3,  # Low food supply
  food_supply_kcal < 2500 ~ 2,  # Below recommended (Afghanistan: 2273.9)
  TRUE ~ 0
)
```

#### **D. Agricultural Productivity Score (0-6 points)**
```r
agriculture_score = case_when(
  is.na(tfp_index) ~ 0,
  tfp_index < 100 ~ 6,  # Very low productivity
  tfp_index < 120 ~ 4,  # Low productivity
  tfp_index < 150 ~ 2,  # Moderate productivity (Afghanistan: 131.85)
  TRUE ~ 0
)
```

### **Step 3: Join New Data to Main Dataset**

Add this to the data joining section:

```r
# Add new data sources
left_join(new_data_sources, by = c("Area" = "country")) %>%
```

---

## 📈 Expected Impact

### **For Afghanistan Specifically:**

**Current Score:** 73.5/100
- Undernourishment: ~22.5 points (estimated 28.1%)
- GDP: 15 points
- Life Expectancy: 5 points
- Regional: 10 points
- Outbreak: 20 points
- **Missing:** Poverty, Climate, Stunting, Food Supply, Agriculture

**New Score (with all data):** ~85-95/100
- **+ Climate:** 4-6 points (76.8 vulnerability index)
- **+ Stunting:** 6-8 points (41.4% stunting rate)
- **+ Food Supply:** 2-3 points (below recommended)
- **+ Agriculture:** 2 points (moderate productivity)
- **+ Poverty:** 0-20 points (if found)

### **For Overall Model:**

- **Better Coverage:** Can now calculate vulnerability for countries missing FAO data
- **More Accurate:** Additional factors provide more comprehensive assessment
- **Enabled Factors:** 4 previously disabled factors can now be used (32 additional points possible)

---

## 🎯 Next Steps

1. ✅ **Data Processing:** Complete (see `process_new_data_sources.R`)
2. ⏳ **Integration:** Update `enhanced_fao_wfp_app.R` to use new data
3. ⏳ **Testing:** Verify Afghanistan and other countries get correct scores
4. ⏳ **Validation:** Compare new scores with existing scores
5. ⏳ **Documentation:** Update vulnerability formula documentation

---

## 📝 Files Created

1. **`process_new_data_sources.R`** - Script to process all new data sources
2. **`data/processed/new_data_sources_combined.csv`** - Combined processed data
3. **`NEW_DATA_INTEGRATION_SUMMARY.md`** - This document

---

## ⚠️ Notes

- **Country Name Mapping:** Some data sources may use different country names. Need to create mapping table.
- **Data Quality:** Some sources have multiple entries per country (different years/regions). Using most recent national-level data.
- **Missing Data:** Not all countries have all indicators. The calculation handles missing data gracefully.
- **Afghanistan Poverty:** Still missing from Our World in Data. May need to check alternative sources or use existing World Bank/PIP data.

---

## 🔍 Data Quality Checks

Run this to check data quality:

```r
# Check for Afghanistan specifically
afghan_data <- new_data_sources %>%
  filter(country == "Afghanistan") %>%
  select(country, climate_vulnerability_index, who_stunting_rate, 
         food_supply_kcal, tfp_index, poverty_below_3usd)

print(afghan_data)
```

---

## ✅ Success Metrics

- [x] Climate vulnerability data processed for 118 countries
- [x] WHO stunting data processed for 576 countries/regions
- [x] Food supply data processed for 241 countries
- [x] Agricultural production data processed for 234 countries
- [x] Afghanistan has climate, stunting, food supply, and agriculture data
- [ ] Integration into vulnerability calculation (next step)
- [ ] Testing and validation (next step)

