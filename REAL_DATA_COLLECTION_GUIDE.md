# 📊 Real Data Collection Guide - FAO, WFP, USDA, EM-DAT

## 🌾 **FAO (Food and Agriculture Organization) - Real Data**

### **Method 1: FAO FAOSTAT Database (Recommended)**
1. **Go to:** https://www.fao.org/faostat/en/#data
2. **Select Domain:** "Food Security and Nutrition"
3. **Key Datasets to Download:**
   - **Prevalence of Undernourishment:** https://www.fao.org/faostat/en/#data/FS
   - **Food Security Indicators:** https://www.fao.org/faostat/en/#data/FS
   - **Food Balance Sheets:** https://www.fao.org/faostat/en/#data/FBS
   - **Agricultural Production:** https://www.fao.org/faostat/en/#data/QCL

### **Method 2: FAO API (Programmatic)**
```r
# FAO API endpoint
fao_url <- "https://fenixservices.fao.org/faostat/api/v1/en/data/FS"

# Example API call
library(httr)
response <- GET(fao_url, query = list(
  area = "5000",  # All countries
  item = "21001", # Prevalence of Undernourishment
  elements = "Value",
  year = "2020,2021,2022,2023"
))
```

### **Specific CSV Files to Download:**
1. **Prevalence of Undernourishment (%).csv**
2. **Number of Undernourished (millions).csv**
3. **Depth of Food Deficit (kcal/person/day).csv**
4. **Average Dietary Energy Supply Adequacy (%).csv**

---

## 🍞 **WFP (World Food Programme) - Real Data**

### **Method 1: WFP Data Portal**
1. **Go to:** https://dataviz.vam.wfp.org/
2. **Key Datasets:**
   - **Food Security Phase Classification:** https://dataviz.vam.wfp.org/global-level
   - **Market Prices:** https://dataviz.vam.wfp.org/price-tool
   - **Vulnerability Assessment:** https://dataviz.vam.wfp.org/vulnerability-analysis

### **Method 2: WFP API**
```r
# WFP API endpoint
wfp_url <- "https://api.hungermapdata.org/v1/foodsecurity/country"

# Example API call
library(httr)
response <- GET(wfp_url)
```

### **Specific Data to Look For:**
1. **Food Security Phase Classification (IPC/CH)**
2. **Market Price Index**
3. **Vulnerability Assessment Scores**
4. **Food Assistance Needs**

---

## 🇺🇸 **USDA (United States Department of Agriculture) - Real Data**

### **Method 1: USDA Economic Research Service**
1. **Go to:** https://www.ers.usda.gov/data-products/
2. **Key Datasets:**
   - **Food Security in the U.S.:** https://www.ers.usda.gov/data-products/food-security-in-the-united-states/
   - **Food Environment Atlas:** https://www.ers.usda.gov/data-products/food-environment-atlas/
   - **Agricultural Trade:** https://www.ers.usda.gov/data-products/agricultural-trade-multipliers/

### **Method 2: USDA API**
```r
# USDA API endpoint
usda_url <- "https://api.ers.usda.gov/data/foodsecurity"

# Example API call
library(httr)
response <- GET(usda_url)
```

### **Specific CSV Files to Download:**
1. **Food Security in the U.S. - State Level Data.csv**
2. **Food Environment Atlas - County Level Data.csv**
3. **SNAP Participation Rates by State.csv**
4. **Food Expenditure Data by State.csv**

---

## 🌪️ **EM-DAT (Emergency Events Database) - Real Data**

### **Method 1: EM-DAT Public Database**
1. **Go to:** https://public.emdat.be/
2. **Registration Required:** You need to create a free account
3. **Key Datasets:**
   - **Natural Disasters:** https://public.emdat.be/data
   - **Disaster Impact:** https://public.emdat.be/data
   - **Food Security Impact:** https://public.emdat.be/data

### **Method 2: EM-DAT API**
```r
# EM-DAT API endpoint
em_dat_url <- "https://public.emdat.be/api/v1/disasters"

# Example API call
library(httr)
response <- GET(em_dat_url)
```

### **Specific Data to Look For:**
1. **Natural Disasters by Country and Year**
2. **Total Affected Population**
3. **Economic Damages**
4. **Food Security Impact Scores**

---

## 📁 **How to Organize Real Data:**

### **Step 1: Download CSV Files**
```
data/raw/
├── fao/
│   ├── prevalence_undernourishment.csv
│   ├── number_undernourished.csv
│   ├── food_deficit.csv
│   └── dietary_energy_supply.csv
├── wfp/
│   ├── food_security_phases.csv
│   ├── market_prices.csv
│   ├── vulnerability_assessment.csv
│   └── food_assistance_needs.csv
├── usda/
│   ├── food_security_states.csv
│   ├── snap_participation.csv
│   ├── food_expenditure.csv
│   └── food_environment_atlas.csv
└── em_dat/
    ├── natural_disasters.csv
    ├── disaster_impact.csv
    ├── economic_damages.csv
    └── food_security_impact.csv
```

### **Step 2: Data Processing Script**
```r
# Process real data
process_real_data <- function() {
  # Load FAO data
  fao_data <- read_csv("data/raw/fao/prevalence_undernourishment.csv")
  
  # Load WFP data
  wfp_data <- read_csv("data/raw/wfp/food_security_phases.csv")
  
  # Load USDA data
  usda_data <- read_csv("data/raw/usda/food_security_states.csv")
  
  # Load EM-DAT data
  em_dat_data <- read_csv("data/raw/em_dat/natural_disasters.csv")
  
  # Process and clean data
  # ... data processing code ...
}
```

---

## 🚀 **Next Steps:**

### **Option 1: Manual Download (Recommended)**
1. **Visit each website** listed above
2. **Download the specific CSV files** mentioned
3. **Place them in the appropriate folders** in your `data/raw/` directory
4. **Update the app** to use real data instead of simulated data

### **Option 2: API Integration**
1. **Get API keys** from each organization (if required)
2. **Use the API endpoints** provided above
3. **Create automated data collection scripts**

### **Option 3: Hybrid Approach**
1. **Start with manual downloads** for immediate results
2. **Gradually implement API integration** for automated updates

---

## ⚠️ **Important Notes:**

### **Data Availability:**
- **FAO:** Most comprehensive, regularly updated
- **WFP:** Good coverage, but some data may be restricted
- **USDA:** Excellent for US data, limited global coverage
- **EM-DAT:** Requires registration, good disaster data

### **Data Quality:**
- **Real data** may have missing values
- **Different countries** may have different data availability
- **Time periods** may vary between sources
- **Data formats** may need standardization

### **Legal Considerations:**
- **Check data licenses** before use
- **Some data** may require attribution
- **Commercial use** may have restrictions

---

## 🎯 **Recommended Action Plan:**

1. **Start with FAO data** (most accessible and comprehensive)
2. **Download WFP data** for food security phases
3. **Get USDA data** for US-specific analysis
4. **Register for EM-DAT** for disaster data
5. **Update the app** to use real data instead of simulated data

**This will give you a much more accurate and credible hunger research project!** 🌍📊✨
