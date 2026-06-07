#!/usr/bin/env Rscript

# Data Coverage Analysis Script
# This script analyzes what data is available for each country across all data sources

library(tidyverse)
library(readr)

cat("🔍 ANALYZING DATA COVERAGE ACROSS ALL SOURCES\n")
cat("==============================================\n\n")

# Load all data sources
cat("📊 Loading data sources...\n")

# FAO Data
fao_data <- read_csv("data/raw/fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv", show_col_types = FALSE)
fao_countries <- unique(fao_data$Area)
fao_indicators <- unique(fao_data$Item)

# World Bank Data
wb_data <- read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE)
wb_countries <- unique(wb_data$country)
wb_indicators <- names(wb_data)[7:12]  # Main indicators

# WFP Data
wfp_markets <- read_csv("data/raw/wfp/markets.csv", show_col_types = FALSE)
wfp_commodities <- read_csv("data/raw/wfp/commodities.csv", show_col_types = FALSE)
wfp_countries <- unique(wfp_markets$Country)

# EM-DAT Data
em_dat <- read_csv("data/raw/em_dat/em_dat_data.csv", show_col_types = FALSE)
em_dat_countries <- unique(em_dat$country)
em_dat_indicators <- unique(em_dat$indicator)

# WPR Data
wpr_data <- read_csv("data/raw/wpr/malnutrition-rate-by-country-2025.csv", show_col_types = FALSE)
wpr_countries <- unique(wpr_data$Country)

cat("✅ Data sources loaded successfully!\n\n")

# Get all unique countries across all sources
all_countries <- unique(c(fao_countries, wb_countries, wfp_countries, em_dat_countries, wpr_countries))

cat("📈 DATA COVERAGE SUMMARY\n")
cat("=======================\n")
cat("Total unique countries across all sources:", length(all_countries), "\n")
cat("FAO countries:", length(fao_countries), "\n")
cat("World Bank countries:", length(wb_countries), "\n")
cat("WFP countries:", length(wfp_countries), "\n")
cat("EM-DAT countries:", length(em_dat_countries), "\n")
cat("WPR countries:", length(wpr_countries), "\n\n")

# Create comprehensive coverage analysis
coverage_analysis <- data.frame(
  Country = all_countries,
  FAO_Data = all_countries %in% fao_countries,
  WorldBank_Data = all_countries %in% wb_countries,
  WFP_Data = all_countries %in% wfp_countries,
  EMDAT_Data = all_countries %in% em_dat_countries,
  WPR_Data = all_countries %in% wpr_countries,
  stringsAsFactors = FALSE
)

# Calculate coverage statistics
coverage_analysis$Total_Sources <- rowSums(coverage_analysis[,2:6])
coverage_analysis$Missing_Sources <- 5 - coverage_analysis$Total_Sources

# Sort by missing sources (countries with least data first)
coverage_analysis <- coverage_analysis[order(coverage_analysis$Missing_Sources, decreasing = TRUE),]

cat("🚨 COUNTRIES WITH MOST MISSING DATA\n")
cat("===================================\n")
missing_data_countries <- coverage_analysis[coverage_analysis$Missing_Sources >= 3,]
if(nrow(missing_data_countries) > 0) {
  for(i in 1:min(20, nrow(missing_data_countries))) {
    country <- missing_data_countries$Country[i]
    missing <- missing_data_countries$Missing_Sources[i]
    sources <- c()
    if(!missing_data_countries$FAO_Data[i]) sources <- c(sources, "FAO")
    if(!missing_data_countries$WorldBank_Data[i]) sources <- c(sources, "WorldBank")
    if(!missing_data_countries$WFP_Data[i]) sources <- c(sources, "WFP")
    if(!missing_data_countries$EMDAT_Data[i]) sources <- c(sources, "EM-DAT")
    if(!missing_data_countries$WPR_Data[i]) sources <- c(sources, "WPR")
    
    cat(sprintf("%-30s | Missing %d sources: %s\n", country, missing, paste(sources, collapse = ", ")))
  }
} else {
  cat("All countries have data from at least 2 sources!\n")
}

cat("\n📊 DETAILED COVERAGE BY COUNTRY\n")
cat("===============================\n")

# Show detailed coverage for first 50 countries
for(i in 1:min(50, nrow(coverage_analysis))) {
  country <- coverage_analysis$Country[i]
  total <- coverage_analysis$Total_Sources[i]
  missing <- coverage_analysis$Missing_Sources[i]
  
  sources <- c()
  if(coverage_analysis$FAO_Data[i]) sources <- c(sources, "FAO")
  if(coverage_analysis$WorldBank_Data[i]) sources <- c(sources, "WorldBank")
  if(coverage_analysis$WFP_Data[i]) sources <- c(sources, "WFP")
  if(coverage_analysis$EMDAT_Data[i]) sources <- c(sources, "EM-DAT")
  if(coverage_analysis$WPR_Data[i]) sources <- c(sources, "WPR")
  
  cat(sprintf("%-30s | %d/5 sources: %s\n", country, total, paste(sources, collapse = ", ")))
}

cat("\n🔍 INDICATOR COVERAGE ANALYSIS\n")
cat("==============================\n")

# FAO Indicators
cat("FAO Indicators available:\n")
for(indicator in unique(fao_data$Item)) {
  countries_with_data <- length(unique(fao_data$Area[fao_data$Item == indicator]))
  cat(sprintf("  %-60s | %d countries\n", indicator, countries_with_data))
}

cat("\nWorld Bank Indicators available:\n")
for(indicator in wb_indicators) {
  countries_with_data <- length(unique(wb_data$country[!is.na(wb_data[[indicator]])]))
  cat(sprintf("  %-30s | %d countries\n", indicator, countries_with_data))
}

cat("\nEM-DAT Indicators available:\n")
for(indicator in em_dat_indicators) {
  countries_with_data <- length(unique(em_dat$country[em_dat$indicator == indicator]))
  cat(sprintf("  %-40s | %d countries\n", indicator, countries_with_data))
}

# Save detailed analysis
write_csv(coverage_analysis, "data_coverage_analysis.csv")
cat("\n💾 Detailed analysis saved to: data_coverage_analysis.csv\n")

cat("\n✅ ANALYSIS COMPLETE!\n")
