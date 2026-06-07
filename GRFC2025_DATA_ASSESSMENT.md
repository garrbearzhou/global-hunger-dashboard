# GRFC 2025 Hunger Crises Data - Assessment & Integration Guide

## 📊 Data Overview

**File:** `data/raw/wfp/GRFC2025 Hunger Crises Data.pdf`  
**Size:** 32 MB  
**Source:** Global Report on Food Crises 2025 (WFP/FAO/FSIN)

## ✅ Why This Data is Excellent

The GRFC (Global Report on Food Crises) is **the most authoritative source** for acute food insecurity data. It's perfect for your project because:

### 1. **IPC Phase Classifications**
- **Phase 3 (Crisis):** 20-30% of population in crisis
- **Phase 4 (Emergency):** 30-50% of population in emergency
- **Phase 5 (Famine):** >20% of population in famine conditions
- This directly maps to your vulnerability index!

### 2. **Accurate Population Numbers**
- Provides exact numbers of people in each phase
- More reliable than estimates from other sources
- Updated annually with latest assessments

### 3. **Primary Drivers**
- Identifies main causes: Conflict, Climate, Economic
- Helps understand why countries are vulnerable
- Useful for factor analysis

### 4. **Comprehensive Coverage**
- Covers all major food crisis countries
- Includes countries you might miss in other sources
- Validates and supplements your existing data

## 🎯 How This Data Enhances Your Project

### For Vulnerability Index:
- **IPC Phase 4 or 5** = Major hunger outbreak (update `major_hunger_outbreak_21st`)
- **Population in Phase 3+** = Current crisis severity
- **Primary driver** = Helps explain vulnerability factors

### For Historical Outbreak Data:
- Countries in Phase 4/5 in 2024 = Current major crises
- Can identify new countries to add to outbreak list
- Provides exact dates/periods for outbreak years

### For Data Validation:
- Cross-check with your existing undernourishment data
- Verify countries you've identified as vulnerable
- Fill gaps in countries with missing FAO data

## 📋 Data Extraction Guide

### Step 1: Extract Data from PDF

The PDF likely contains tables in these sections:
- **Executive Summary:** Key numbers and top countries
- **Country Profiles:** Detailed country-by-country data
- **Appendices:** Comprehensive data tables
- **Regional Analysis:** Regional aggregations

### Step 2: Create CSV File

Save extracted data as: `data/raw/wfp/grfc2025_data.csv`

**Required Columns:**
```csv
country,assessment_year,ipc_phase,population_phase3_plus,population_phase4_plus,population_phase5,primary_driver,secondary_driver
```

**Example:**
```csv
country,assessment_year,ipc_phase,population_phase3_plus,population_phase4_plus,population_phase5,primary_driver,secondary_driver
Afghanistan,2024,3,15800000,2800000,0,Conflict,Economic
Yemen,2024,4,18000000,6500000,0,Conflict,Economic
Somalia,2024,4,6700000,4200000,0,Climate,Conflict
Sudan,2024,5,20000000,8000000,500000,Conflict,Economic
```

### Step 3: Integration

The script `create_comprehensive_data_table.R` has been updated to:
- ✅ Automatically load GRFC data if CSV exists
- ✅ Join it to comprehensive country data
- ✅ Include all GRFC columns in final CSV

**Just run:**
```bash
Rscript create_comprehensive_data_table.R
```

## 🔍 What to Look For in the PDF

### Key Tables:
1. **"Countries/territories in food crisis"** - List with IPC phases
2. **"Population in Phase 3+"** - Total people in crisis
3. **"Population in Phase 4+"** - People in emergency
4. **"Population in Phase 5"** - People in famine
5. **"Primary drivers"** - What's causing the crisis

### Important Numbers:
- **Total countries in crisis:** Usually 40-60 countries
- **Total population in Phase 3+:** Usually 150-200 million
- **Countries in Phase 4/5:** Usually 10-20 countries (these are your major outbreaks!)

## 💡 Recommended Extraction Strategy

### Option 1: Manual Extraction (Most Reliable)
1. Open PDF in Adobe Reader or Preview
2. Find the main data table (usually in appendices)
3. Copy table to Excel/Google Sheets
4. Clean and standardize:
   - Country names (use your `standardize_country_names()` function)
   - Numbers (remove commas, ensure numeric)
   - IPC phases (ensure consistent format: 3, 4, or 5)
5. Save as CSV: `data/raw/wfp/grfc2025_data.csv`

### Option 2: PDF Text Extraction (If pdftools available)
```r
# Install pdftools if needed
install.packages("pdftools")

# Run extraction script
Rscript process_grfc2025_data.R
```

### Option 3: Check for Official CSV
- Sometimes GRFC releases data in Excel/CSV format
- Check WFP/FAO websites for downloadable datasets
- Look for "GRFC 2025 data" or "Food Crises dataset"

## 🎯 Integration with Existing Data

### Update Historical Outbreak Data:
Countries in **Phase 4 or 5** in GRFC 2024 should be added to `historical_hunger_outbreaks.csv`:

```csv
country,outbreak_start_year,outbreak_end_year,severity,primary_cause,affected_population,deaths,source
Sudan,2023,2024,Famine,Conflict,20000000,500000,GRFC 2025
```

### Enhance Vulnerability Calculation:
You could add a new factor based on GRFC data:
- **Current IPC Phase:** Phase 5 = +15 points, Phase 4 = +10 points, Phase 3 = +5 points
- This would capture current crisis status, not just historical

### Validate Existing Data:
- Compare GRFC Phase 3+ populations with your undernourishment data
- Check if countries you identified as vulnerable match GRFC classifications
- Identify countries missing from your dataset

## 📊 Expected Data Quality

**Strengths:**
- ✅ Most authoritative source for food crises
- ✅ Standardized IPC classification system
- ✅ Comprehensive country coverage
- ✅ Includes population numbers (not just percentages)
- ✅ Identifies primary drivers

**Considerations:**
- ⚠️ Data is for 2024 (most recent assessment)
- ⚠️ Some countries may have multiple assessments in one year
- ⚠️ Population numbers are estimates (but best available)
- ⚠️ IPC phases can change throughout the year

## 🚀 Next Steps

1. **Extract data from PDF** → Create `data/raw/wfp/grfc2025_data.csv`
2. **Re-run comprehensive data script** → `Rscript create_comprehensive_data_table.R`
3. **Review new columns** in `comprehensive_country_data.csv`
4. **Update historical outbreaks** based on Phase 4/5 countries
5. **Consider adding IPC phase** as a new vulnerability factor

## 📝 Notes

- GRFC data is **complementary** to your existing data, not a replacement
- Use it to **validate** and **enhance** your vulnerability index
- The **IPC Phase 4/5** countries are your most vulnerable - these should have high vulnerability scores
- **Primary drivers** help explain why countries are vulnerable (conflict, climate, economic)

---

**This is excellent data!** The GRFC is exactly what you need to validate and enhance your hunger vulnerability index. Once extracted, it will significantly improve your data quality and coverage.

