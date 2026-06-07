#!/usr/bin/env Rscript

# Detailed Missing Data Report
# This script provides a comprehensive analysis of missing data by country

library(tidyverse)
library(readr)

cat("📋 DETAILED MISSING DATA REPORT\n")
cat("==============================\n\n")

# Load the coverage analysis
coverage <- read_csv("data_coverage_analysis.csv", show_col_types = FALSE)

# Load individual data sources for detailed analysis
fao_data <- read_csv("data/raw/fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv", show_col_types = FALSE)
wb_data <- read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE)
wfp_markets <- read_csv("data/raw/wfp/markets.csv", show_col_types = FALSE)
em_dat <- read_csv("data/raw/em_dat/em_dat_data.csv", show_col_types = FALSE)

# Countries with only FAO data (missing 4 other sources)
fao_only <- coverage[coverage$Total_Sources == 1 & coverage$FAO_Data == TRUE,]

cat("🚨 COUNTRIES WITH ONLY FAO DATA (MISSING 4 OTHER SOURCES)\n")
cat("=======================================================\n")
for(i in 1:nrow(fao_only)) {
  country <- fao_only$Country[i]
  
  # Check what FAO data is available
  fao_country_data <- fao_data[fao_data$Area == country,]
  undernourishment <- fao_country_data[fao_country_data$Item == "Prevalence of undernourishment (percent) (3-year average)",]
  undernourished_pop <- fao_country_data[fao_country_data$Item == "Number of people undernourished (million) (3-year average)",]
  
  cat(sprintf("\n📍 %s\n", country))
  cat("   Missing: World Bank, WFP, EM-DAT, WPR data\n")
  
  if(nrow(undernourishment) > 0) {
    cat(sprintf("   ✅ FAO: Undernourishment rate: %s%%\n", undernourishment$Value[1]))
  }
  if(nrow(undernourished_pop) > 0) {
    cat(sprintf("   ✅ FAO: Undernourished population: %s million\n", undernourished_pop$Value[1]))
  }
}

# Countries with only WFP data
wfp_only <- coverage[coverage$Total_Sources == 1 & coverage$WFP_Data == TRUE,]

cat("\n\n🏪 COUNTRIES WITH ONLY WFP DATA (MISSING 4 OTHER SOURCES)\n")
cat("========================================================\n")
for(i in 1:nrow(wfp_only)) {
  country <- wfp_only$Country[i]
  
  # Check WFP market data
  wfp_country_markets <- wfp_markets[wfp_markets$Country == country,]
  
  cat(sprintf("\n📍 %s\n", country))
  cat("   Missing: FAO, World Bank, EM-DAT, WPR data\n")
  cat(sprintf("   ✅ WFP: %d markets available\n", nrow(wfp_country_markets)))
}

# Countries with 2 sources
two_sources <- coverage[coverage$Total_Sources == 2,]

cat("\n\n📊 COUNTRIES WITH 2 DATA SOURCES\n")
cat("================================\n")
for(i in 1:min(20, nrow(two_sources))) {
  country <- two_sources$Country[i]
  
  sources <- c()
  if(two_sources$FAO_Data[i]) sources <- c(sources, "FAO")
  if(two_sources$WorldBank_Data[i]) sources <- c(sources, "WorldBank")
  if(two_sources$WFP_Data[i]) sources <- c(sources, "WFP")
  if(two_sources$EMDAT_Data[i]) sources <- c(sources, "EM-DAT")
  if(two_sources$WPR_Data[i]) sources <- c(sources, "WPR")
  
  missing_sources <- c()
  if(!two_sources$FAO_Data[i]) missing_sources <- c(missing_sources, "FAO")
  if(!two_sources$WorldBank_Data[i]) missing_sources <- c(missing_sources, "WorldBank")
  if(!two_sources$WFP_Data[i]) missing_sources <- c(missing_sources, "WFP")
  if(!two_sources$EMDAT_Data[i]) missing_sources <- c(missing_sources, "EM-DAT")
  if(!two_sources$WPR_Data[i]) missing_sources <- c(missing_sources, "WPR")
  
  cat(sprintf("\n📍 %s\n", country))
  cat(sprintf("   ✅ Available: %s\n", paste(sources, collapse = ", ")))
  cat(sprintf("   ❌ Missing: %s\n", paste(missing_sources, collapse = ", ")))
}

# Countries with 3+ sources (good coverage)
good_coverage <- coverage[coverage$Total_Sources >= 3,]

cat("\n\n✅ COUNTRIES WITH GOOD DATA COVERAGE (3+ SOURCES)\n")
cat("===============================================\n")
cat(sprintf("Total countries with good coverage: %d\n", nrow(good_coverage)))

# Show first 20 countries with good coverage
for(i in 1:min(20, nrow(good_coverage))) {
  country <- good_coverage$Country[i]
  total <- good_coverage$Total_Sources[i]
  
  sources <- c()
  if(good_coverage$FAO_Data[i]) sources <- c(sources, "FAO")
  if(good_coverage$WorldBank_Data[i]) sources <- c(sources, "WorldBank")
  if(good_coverage$WFP_Data[i]) sources <- c(sources, "WFP")
  if(good_coverage$EMDAT_Data[i]) sources <- c(sources, "EM-DAT")
  if(good_coverage$WPR_Data[i]) sources <- c(sources, "WPR")
  
  cat(sprintf("%-30s | %d/5 sources: %s\n", country, total, paste(sources, collapse = ", ")))
}

# Summary statistics
cat("\n\n📈 DATA COVERAGE SUMMARY STATISTICS\n")
cat("===================================\n")
cat(sprintf("Total countries analyzed: %d\n", nrow(coverage)))
cat(sprintf("Countries with 1 source only: %d\n", sum(coverage$Total_Sources == 1)))
cat(sprintf("Countries with 2 sources: %d\n", sum(coverage$Total_Sources == 2)))
cat(sprintf("Countries with 3 sources: %d\n", sum(coverage$Total_Sources == 3)))
cat(sprintf("Countries with 4 sources: %d\n", sum(coverage$Total_Sources == 4)))
cat(sprintf("Countries with 5 sources: %d\n", sum(coverage$Total_Sources == 5)))

# Source-specific coverage
cat("\n📊 SOURCE-SPECIFIC COVERAGE\n")
cat("==========================\n")
cat(sprintf("FAO data: %d countries (%.1f%%)\n", sum(coverage$FAO_Data), 100*sum(coverage$FAO_Data)/nrow(coverage)))
cat(sprintf("World Bank data: %d countries (%.1f%%)\n", sum(coverage$WorldBank_Data), 100*sum(coverage$WorldBank_Data)/nrow(coverage)))
cat(sprintf("WFP data: %d countries (%.1f%%)\n", sum(coverage$WFP_Data), 100*sum(coverage$WFP_Data)/nrow(coverage)))
cat(sprintf("EM-DAT data: %d countries (%.1f%%)\n", sum(coverage$EMDAT_Data), 100*sum(coverage$EMDAT_Data)/nrow(coverage)))
cat(sprintf("WPR data: %d countries (%.1f%%)\n", sum(coverage$WPR_Data), 100*sum(coverage$WPR_Data)/nrow(coverage)))

cat("\n✅ ANALYSIS COMPLETE!\n")
