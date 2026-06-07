# =============================================================================
# DATA COLLECTION SCRIPT FOR HUNGER RESEARCH PROJECT
# Author: Garrett Zhou
# Date: October 2024
# 
# This script provides functions to collect data from various sources
# for the global hunger research project.
# =============================================================================

# Load required libraries
library(tidyverse)
library(WDI)
library(jsonlite)
library(httr)
library(here)
library(lubridate)

# =============================================================================
# 1. WORLD BANK DATA COLLECTION
# =============================================================================

collect_world_bank_data <- function(start_year = 2000, end_year = 2023) {
  cat("Collecting World Bank data...\n")
  
  # Key indicators for hunger research
  indicators <- c(
    "SP.POP.TOTL",           # Population, total
    "NY.GDP.MKTP.CD",        # GDP (current US$)
    "NY.GDP.PCAP.CD",        # GDP per capita (current US$)
    "FP.CPI.TOTL.ZG",        # Inflation, consumer prices (annual %)
    "SI.POV.DDAY",           # Poverty headcount ratio at $1.90/day
    "AG.LND.AGRI.ZS",        # Agricultural land (% of land area)
    "AG.PRD.CROP.XD",        # Crop production index
    "SP.RUR.TOTL.ZS",        # Rural population (% of total population)
    "SP.URB.TOTL.IN.ZS",     # Urban population (% of total)
    "SE.ADT.LITR.ZS",        # Literacy rate, adult total (% of people ages 15+)
    "SH.XPD.CHEX.GD.ZS",     # Current health expenditure (% of GDP)
    "SP.DYN.LE00.IN",        # Life expectancy at birth, total (years)
    "SP.DYN.IMRT.IN",        # Mortality rate, infant (per 1,000 live births)
    "AG.CON.FERT.ZS",        # Fertilizer consumption (kilograms per hectare of arable land)
    "AG.LND.ARBL.ZS",        # Arable land (% of land area)
    "AG.LND.ARBL.HA.PC",     # Arable land (hectares per person)
    "SP.POP.GROW",           # Population growth (annual %)
    "NY.GDP.MKTP.KD.ZG",     # GDP growth (annual %)
    "NE.TRD.GNFS.ZS",        # Trade (% of GDP)
    "NE.EXP.GNFS.ZS",        # Exports of goods and services (% of GDP)
    "NE.IMP.GNFS.ZS"         # Imports of goods and services (% of GDP)
  )
  
  # Collect data for all countries
  wb_data <- WDI(country = "all", 
                 indicator = indicators,
                 start = start_year, 
                 end = end_year,
                 extra = TRUE)
  
  # Clean column names
  names(wb_data) <- gsub("^SP\\.", "pop_", names(wb_data))
  names(wb_data) <- gsub("^NY\\.", "gdp_", names(wb_data))
  names(wb_data) <- gsub("^FP\\.", "inflation_", names(wb_data))
  names(wb_data) <- gsub("^SI\\.", "poverty_", names(wb_data))
  names(wb_data) <- gsub("^AG\\.", "agriculture_", names(wb_data))
  names(wb_data) <- gsub("^SE\\.", "education_", names(wb_data))
  names(wb_data) <- gsub("^SH\\.", "health_", names(wb_data))
  names(wb_data) <- gsub("^NE\\.", "trade_", names(wb_data))
  
  # Save raw data
  write_csv(wb_data, here("data/raw/world_bank_data.csv"))
  
  cat("World Bank data collected and saved to data/raw/world_bank_data.csv\n")
  cat("Total records:", nrow(wb_data), "\n")
  cat("Countries:", length(unique(wb_data$country)), "\n")
  cat("Years:", min(wb_data$year, na.rm = TRUE), "to", max(wb_data$year, na.rm = TRUE), "\n\n")
  
  return(wb_data)
}

# =============================================================================
# 2. FAO DATA COLLECTION (PLACEHOLDER)
# =============================================================================

collect_fao_data <- function() {
  cat("FAO data collection requires manual setup...\n")
  cat("Please visit: http://www.fao.org/faostat/en/#data\n")
  cat("Key datasets to download:\n")
  cat("1. Food Security Indicators\n")
  cat("2. Food Balance Sheets\n")
  cat("3. Production\n")
  cat("4. Trade\n")
  cat("5. Prices\n\n")
  
  # Placeholder for future API integration
  return(NULL)
}

# =============================================================================
# 3. WFP DATA COLLECTION (PLACEHOLDER)
# =============================================================================

collect_wfp_data <- function() {
  cat("WFP data collection requires manual setup...\n")
  cat("Please visit: https://dataviz.vam.wfp.org/\n")
  cat("Key datasets to explore:\n")
  cat("1. Food Security\n")
  cat("2. Market Prices\n")
  cat("3. Vulnerability Analysis\n\n")
  
  # Placeholder for future API integration
  return(NULL)
}

# =============================================================================
# 4. EM-DAT DATA COLLECTION (PLACEHOLDER)
# =============================================================================

collect_emdat_data <- function() {
  cat("EM-DAT data collection requires manual setup...\n")
  cat("Please visit: https://www.emdat.be/\n")
  cat("Key datasets to download:\n")
  cat("1. Natural Disasters\n")
  cat("2. Technological Disasters\n")
  cat("3. Conflict data\n\n")
  
  # Placeholder for future API integration
  return(NULL)
}

# =============================================================================
# 5. CLIMATE DATA COLLECTION
# =============================================================================

collect_climate_data <- function() {
  cat("Climate data collection...\n")
  
  # This is a placeholder for climate data collection
  # Consider using packages like:
  # - rnoaa for NOAA climate data
  # - nasapower for NASA climate data
  # - worldmet for weather station data
  
  cat("Climate data collection requires additional setup...\n")
  cat("Consider using:\n")
  cat("1. NOAA Climate Data API\n")
  cat("2. NASA POWER API\n")
  cat("3. World Bank Climate Change Knowledge Portal\n\n")
  
  return(NULL)
}

# =============================================================================
# 6. CONFLICT DATA COLLECTION
# =============================================================================

collect_conflict_data <- function() {
  cat("Conflict data collection...\n")
  
  # This is a placeholder for conflict data collection
  # Consider using:
  # - UCDP (Uppsala Conflict Data Program)
  # - ACLED (Armed Conflict Location & Event Data Project)
  # - GTD (Global Terrorism Database)
  
  cat("Conflict data collection requires additional setup...\n")
  cat("Consider using:\n")
  cat("1. UCDP API\n")
  cat("2. ACLED API\n")
  cat("3. GTD database\n\n")
  
  return(NULL)
}

# =============================================================================
# 7. DATA VALIDATION AND QUALITY CHECK
# =============================================================================

validate_data_quality <- function(data, data_source = "Unknown") {
  cat("Validating data quality for", data_source, "...\n")
  
  # Basic data quality checks
  cat("Total records:", nrow(data), "\n")
  cat("Total columns:", ncol(data), "\n")
  cat("Missing values per column:\n")
  
  missing_summary <- data %>%
    summarise_all(~sum(is.na(.))) %>%
    gather(key = "variable", value = "missing_count") %>%
    arrange(desc(missing_count))
  
  print(missing_summary)
  
  # Check for duplicate records
  duplicates <- sum(duplicated(data))
  cat("Duplicate records:", duplicates, "\n")
  
  # Check date ranges
  if("year" %in% names(data)) {
    cat("Year range:", min(data$year, na.rm = TRUE), "to", max(data$year, na.rm = TRUE), "\n")
  }
  
  # Check country coverage
  if("country" %in% names(data)) {
    cat("Countries covered:", length(unique(data$country)), "\n")
  }
  
  cat("\n")
  
  return(missing_summary)
}

# =============================================================================
# 8. DATA MERGING AND INTEGRATION
# =============================================================================

merge_datasets <- function(wb_data, fao_data = NULL, wfp_data = NULL, emdat_data = NULL) {
  cat("Merging datasets...\n")
  
  # Start with World Bank data as base
  merged_data <- wb_data
  
  # Add FAO data if available
  if(!is.null(fao_data)) {
    merged_data <- merged_data %>%
      left_join(fao_data, by = c("country", "year"))
    cat("FAO data merged\n")
  }
  
  # Add WFP data if available
  if(!is.null(wfp_data)) {
    merged_data <- merged_data %>%
      left_join(wfp_data, by = c("country", "year"))
    cat("WFP data merged\n")
  }
  
  # Add EM-DAT data if available
  if(!is.null(emdat_data)) {
    merged_data <- merged_data %>%
      left_join(emdat_data, by = c("country", "year"))
    cat("EM-DAT data merged\n")
  }
  
  # Save merged dataset
  write_csv(merged_data, here("data/processed/merged_hunger_data.csv"))
  
  cat("Merged dataset saved to data/processed/merged_hunger_data.csv\n")
  cat("Final dataset dimensions:", nrow(merged_data), "x", ncol(merged_data), "\n\n")
  
  return(merged_data)
}

# =============================================================================
# 9. DATA COLLECTION WORKFLOW
# =============================================================================

run_data_collection <- function() {
  cat("Starting comprehensive data collection...\n")
  cat("========================================\n\n")
  
  # Create data directories
  dir.create(here("data/raw"), showWarnings = FALSE, recursive = TRUE)
  dir.create(here("data/processed"), showWarnings = FALSE, recursive = TRUE)
  
  # Collect World Bank data
  wb_data <- collect_world_bank_data()
  validate_data_quality(wb_data, "World Bank")
  
  # Collect other data sources (placeholders)
  fao_data <- collect_fao_data()
  wfp_data <- collect_wfp_data()
  emdat_data <- collect_emdat_data()
  climate_data <- collect_climate_data()
  conflict_data <- collect_conflict_data()
  
  # Merge datasets
  merged_data <- merge_datasets(wb_data, fao_data, wfp_data, emdat_data)
  
  # Final validation
  validate_data_quality(merged_data, "Merged Dataset")
  
  cat("Data collection completed!\n")
  cat("Next steps:\n")
  cat("1. Manually download FAO, WFP, and EM-DAT data\n")
  cat("2. Set up APIs for automated data collection\n")
  cat("3. Perform data cleaning and preprocessing\n")
  cat("4. Begin exploratory data analysis\n")
  
  return(merged_data)
}

# =============================================================================
# 10. DATA SOURCE DOCUMENTATION
# =============================================================================

document_data_sources <- function() {
  cat("DATA SOURCES DOCUMENTATION\n")
  cat("==========================\n\n")
  
  sources <- list(
    "World Bank" = list(
      url = "https://data.worldbank.org/",
      api = "WDI package in R",
      key_indicators = c("GDP", "Population", "Inflation", "Poverty", "Agriculture"),
      update_frequency = "Annual",
      access_method = "API via WDI package"
    ),
    
    "FAO" = list(
      url = "http://www.fao.org/faostat/en/#data",
      api = "FAOSTAT API (requires setup)",
      key_indicators = c("Food Security", "Production", "Trade", "Prices"),
      update_frequency = "Annual",
      access_method = "Manual download or API"
    ),
    
    "WFP" = list(
      url = "https://dataviz.vam.wfp.org/",
      api = "WFP API (requires setup)",
      key_indicators = c("Food Security", "Market Prices", "Vulnerability"),
      update_frequency = "Monthly/Annual",
      access_method = "Manual download or API"
    ),
    
    "EM-DAT" = list(
      url = "https://www.emdat.be/",
      api = "EM-DAT API (requires setup)",
      key_indicators = c("Natural Disasters", "Conflict", "Technological Disasters"),
      update_frequency = "Real-time",
      access_method = "Manual download or API"
    )
  )
  
  for(source in names(sources)) {
    cat(source, ":\n")
    for(field in names(sources[[source]])) {
      cat("  ", field, ":", sources[[source]][[field]], "\n")
    }
    cat("\n")
  }
}

# =============================================================================
# EXECUTION
# =============================================================================

# Uncomment to run data collection
# results <- run_data_collection()

# Print data source documentation
document_data_sources()

cat("Data collection script loaded successfully!\n")
cat("To start data collection, run: results <- run_data_collection()\n")
