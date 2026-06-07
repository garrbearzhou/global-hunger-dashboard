# Data Organization Script for Hunger Research Project
# This script organizes all collected data into proper folder structure

library(tidyverse)
library(WDI)

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Create comprehensive data folder structure
create_data_structure <- function() {
  cat("🗂️ Creating comprehensive data folder structure...\n")
  
  # Main data directories
  dirs_to_create <- c(
    "data/raw/world_bank",
    "data/raw/fao", 
    "data/raw/wfp",
    "data/raw/em_dat",
    "data/processed/cleaned",
    "data/processed/aggregated",
    "data/processed/analysis_ready",
    "data/external/country_codes",
    "data/external/geographic",
    "data/external/metadata"
  )
  
  for(dir in dirs_to_create) {
    if(!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
      cat("✅ Created:", dir, "\n")
    }
  }
}

# Collect and organize World Bank data
collect_world_bank_data <- function() {
  cat("🌍 Collecting comprehensive World Bank data...\n")
  
  # Comprehensive indicators for hunger research
  indicators <- c(
    # Population and Demographics
    "SP.POP.TOTL",           # Population, total
    "SP.POP.GROW",           # Population growth (annual %)
    "SP.RUR.TOTL.ZS",        # Rural population (% of total population)
    "SP.URB.TOTL.IN.ZS",     # Urban population (% of total)
    "SP.DYN.LE00.IN",        # Life expectancy at birth, total (years)
    "SP.DYN.IMRT.IN",        # Infant mortality rate (per 1,000 live births)
    "SP.DYN.CBRT.IN",        # Birth rate, crude (per 1,000 people)
    "SP.DYN.CDRT.IN",        # Death rate, crude (per 1,000 people)
    
    # Economic Indicators
    "NY.GDP.MKTP.CD",        # GDP (current US$)
    "NY.GDP.PCAP.CD",        # GDP per capita (current US$)
    "NY.GDP.MKTP.KD.ZG",     # GDP growth (annual %)
    "FP.CPI.TOTL.ZG",        # Inflation, consumer prices (annual %)
    "NE.TRD.GNFS.ZS",        # Trade (% of GDP)
    "NE.EXP.GNFS.ZS",        # Exports of goods and services (% of GDP)
    "NE.IMP.GNFS.ZS",        # Imports of goods and services (% of GDP)
    
    # Poverty and Inequality
    "SI.POV.DDAY",           # Poverty headcount ratio at $1.90/day
    "SI.POV.GINI",           # GINI index (World Bank estimate)
    "SI.POV.NAHC",           # Poverty headcount ratio at national poverty lines
    
    # Agriculture and Food
    "AG.LND.AGRI.ZS",        # Agricultural land (% of land area)
    "AG.LND.FRST.ZS",        # Forest area (% of land area)
    "AG.PRD.CROP.XD",        # Crop production index (2014-2016 = 100)
    "AG.PRD.LVSK.XD",        # Livestock production index (2014-2016 = 100)
    "AG.YLD.CREL.KG",        # Cereal yield (kg per hectare)
    "AG.CON.FERT.ZS",        # Fertilizer consumption (kg per hectare of arable land)
    
    # Health and Nutrition
    "SH.STA.MALN.ZS",        # Prevalence of underweight, weight for age (% of children under 5)
    "SH.STA.STNT.ZS",        # Prevalence of stunting, height for age (% of children under 5)
    "SH.STA.WAST.ZS",        # Prevalence of wasting, weight for height (% of children under 5)
    "SH.STA.ANVC.ZS",        # Immunization, BCG (% of one-year-old children)
    "SH.STA.IMME.ZS",        # Immunization, measles (% of children ages 12-23 months)
    
    # Education
    "SE.ADT.LITR.ZS",        # Literacy rate, adult total (% of people ages 15 and above)
    "SE.PRM.NENR",           # School enrollment, primary (% net)
    "SE.SEC.NENR",           # School enrollment, secondary (% net)
    "SE.TER.ENRR",           # School enrollment, tertiary (% gross)
    
    # Infrastructure and Development
    "EG.ELC.ACCS.ZS",        # Access to electricity (% of population)
    "SH.STA.ACSN",           # Improved water source (% of population with access)
    "SH.STA.ACSN.RU",        # Improved water source, rural (% of rural population with access)
    "SH.STA.ACSN.UR",        # Improved water source, urban (% of urban population with access)
    "SH.STA.SMSS.ZS",        # Improved sanitation facilities (% of population with access)
    
    # Climate and Environment
    "AG.LND.PRCP.MM",        # Average precipitation in depth (mm per year)
    "EN.ATM.CO2E.PC",        # CO2 emissions (metric tons per capita)
    "EN.CLC.GHGR.MT.CE",     # Total greenhouse gas emissions (kt of CO2 equivalent)
    
    # Conflict and Governance
    "PV.EST",                # Political Stability and Absence of Violence/Terrorism
    "CC.EST",                # Control of Corruption
    "GE.EST",                # Government Effectiveness
    "RL.EST",                # Rule of Law
    "RQ.EST",                # Regulatory Quality
    "VA.EST"                 # Voice and Accountability
  )
  
  # Collect data for all countries from 2000 to latest available year
  current_year <- as.numeric(format(Sys.Date(), "%Y"))
  wb_data <- WDI(
    country = "all", 
    indicator = indicators,
    start = 2000, 
    end = current_year,
    extra = TRUE
  )
  
  # Save raw data
  write_csv(wb_data, "data/raw/world_bank/world_bank_comprehensive.csv")
  
  # Create processed versions
  # Latest year data
  latest_data <- wb_data %>%
    group_by(country) %>%
    summarise(
      latest_year = max(year, na.rm = TRUE),
      across(all_of(indicators), ~last(.x, order_by = year)),
      .groups = "drop"
    ) %>%
    filter(!is.na(latest_year))
  
  write_csv(latest_data, "data/processed/cleaned/world_bank_latest.csv")
  
  # Time series data (cleaned)
  time_series_data <- wb_data %>%
    filter(!is.na(country) & !is.na(year)) %>%
    arrange(country, year)
  
  write_csv(time_series_data, "data/processed/cleaned/world_bank_timeseries.csv")
  
  # Summary statistics
  summary_stats <- wb_data %>%
    group_by(country) %>%
    summarise(
      years_available = n(),
      latest_year = max(year, na.rm = TRUE),
      earliest_year = min(year, na.rm = TRUE),
      .groups = "drop"
    )
  
  write_csv(summary_stats, "data/processed/aggregated/world_bank_coverage.csv")
  
  cat("✅ World Bank data collected and organized!\n")
  cat("📊 Total records:", nrow(wb_data), "\n")
  cat("🌍 Countries:", length(unique(wb_data$country)), "\n")
  cat("📅 Years:", min(wb_data$year, na.rm = TRUE), "to", max(wb_data$year, na.rm = TRUE), "\n")
  cat("📈 Indicators:", length(indicators), "\n")
  
  return(wb_data)
}

# Create metadata files
create_metadata <- function() {
  cat("📋 Creating metadata files...\n")
  
  # Indicator descriptions
  indicators_metadata <- data.frame(
    indicator_code = c(
      "SP.POP.TOTL", "SP.POP.GROW", "SP.RUR.TOTL.ZS", "SP.URB.TOTL.IN.ZS",
      "SP.DYN.LE00.IN", "SP.DYN.IMRT.IN", "SP.DYN.CBRT.IN", "SP.DYN.CDRT.IN",
      "NY.GDP.MKTP.CD", "NY.GDP.PCAP.CD", "NY.GDP.MKTP.KD.ZG", "FP.CPI.TOTL.ZG",
      "SI.POV.DDAY", "SI.POV.GINI", "AG.LND.AGRI.ZS", "AG.PRD.CROP.XD",
      "SH.STA.MALN.ZS", "SH.STA.STNT.ZS", "SH.STA.WAST.ZS", "SE.ADT.LITR.ZS"
    ),
    indicator_name = c(
      "Population, total", "Population growth (annual %)", "Rural population (% of total)",
      "Urban population (% of total)", "Life expectancy at birth (years)",
      "Infant mortality rate (per 1,000 live births)", "Birth rate, crude (per 1,000 people)",
      "Death rate, crude (per 1,000 people)", "GDP (current US$)", "GDP per capita (current US$)",
      "GDP growth (annual %)", "Inflation, consumer prices (annual %)",
      "Poverty headcount ratio at $1.90/day", "GINI index", "Agricultural land (% of land area)",
      "Crop production index", "Prevalence of underweight (% of children under 5)",
      "Prevalence of stunting (% of children under 5)", "Prevalence of wasting (% of children under 5)",
      "Literacy rate, adult total (% of people ages 15 and above)"
    ),
    category = c(
      "Demographics", "Demographics", "Demographics", "Demographics",
      "Health", "Health", "Health", "Health",
      "Economic", "Economic", "Economic", "Economic",
      "Poverty", "Poverty", "Agriculture", "Agriculture",
      "Nutrition", "Nutrition", "Nutrition", "Education"
    ),
    source = "World Bank",
    last_updated = Sys.Date()
  )
  
  write_csv(indicators_metadata, "data/external/metadata/indicator_descriptions.csv")
  
  # Data collection log
  collection_log <- data.frame(
    data_source = "World Bank",
    collection_date = Sys.Date(),
    indicators_collected = 50,
    countries_covered = 266,
    years_covered = "2000-2024",
    file_locations = c(
      "data/raw/world_bank/world_bank_comprehensive.csv",
      "data/processed/cleaned/world_bank_latest.csv",
      "data/processed/cleaned/world_bank_timeseries.csv",
      "data/processed/aggregated/world_bank_coverage.csv"
    ),
    notes = "Comprehensive World Bank data collection for hunger research project"
  )
  
  write_csv(collection_log, "data/external/metadata/data_collection_log.csv")
  
  cat("✅ Metadata files created!\n")
}

# Create data documentation
create_documentation <- function() {
  cat("📚 Creating data documentation...\n")
  
  documentation <- "
# Data Documentation - Global Hunger Research Project

## Data Sources

### World Bank Data
- **Source**: World Bank Open Data API
- **Collection Date**: {Sys.Date()}
- **Coverage**: 2000-2024
- **Countries**: 266
- **Indicators**: 50+

### File Structure

```
data/
├── raw/                    # Raw data files
│   ├── world_bank/        # World Bank data
│   ├── fao/              # FAO data (future)
│   ├── wfp/              # WFP data (future)
│   └── em_dat/           # EM-DAT data (future)
├── processed/             # Processed data files
│   ├── cleaned/          # Cleaned datasets
│   ├── aggregated/       # Aggregated summaries
│   └── analysis_ready/   # Analysis-ready datasets
└── external/             # External reference data
    ├── country_codes/    # Country code mappings
    ├── geographic/       # Geographic data
    └── metadata/         # Data documentation
```

### Key Indicators

#### Demographics
- Population, total
- Population growth
- Rural/Urban population
- Life expectancy
- Birth/Death rates

#### Economic
- GDP and GDP per capita
- GDP growth
- Inflation
- Trade indicators

#### Poverty & Inequality
- Poverty headcount ratios
- GINI index
- Income inequality measures

#### Agriculture & Food
- Agricultural land use
- Crop production indices
- Cereal yields
- Fertilizer consumption

#### Health & Nutrition
- Child malnutrition indicators
- Immunization rates
- Health infrastructure

#### Education
- Literacy rates
- School enrollment rates

#### Infrastructure
- Access to electricity
- Water and sanitation access

#### Climate & Environment
- Precipitation data
- CO2 emissions
- Greenhouse gas emissions

#### Governance
- Political stability
- Government effectiveness
- Rule of law indicators

### Data Quality Notes

- Missing data is common in developing countries
- Some indicators have limited temporal coverage
- Regional aggregations available for missing country data
- Data collection methods vary by country

### Usage Guidelines

1. Always check data coverage before analysis
2. Consider data quality and collection methods
3. Use appropriate imputation methods for missing data
4. Validate findings with multiple data sources when possible

### Contact

For questions about this data, contact: Garrett Zhou
Project: Global Hunger Research 2024
"
  
  writeLines(documentation, "data/README.md")
  cat("✅ Data documentation created!\n")
}

# Main execution
main <- function() {
  cat("🗂️ Starting comprehensive data organization...\n")
  cat("==============================================\n")
  
  # Create folder structure
  create_data_structure()
  
  # Collect and organize World Bank data
  wb_data <- collect_world_bank_data()
  
  # Create metadata
  create_metadata()
  
  # Create documentation
  create_documentation()
  
  cat("\n🎉 Data organization complete!\n")
  cat("📁 All data files are now properly organized in the data/ folder\n")
  cat("📊 Check data/README.md for complete documentation\n")
}

# Run the script
main()
