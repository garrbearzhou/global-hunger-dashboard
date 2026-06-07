# =============================================================================
# PROCESS NEW DATA SOURCES
# Integrates data from Germanwatch, Global Data Lab, Our World in Data, USDA, WHO
# =============================================================================

library(tidyverse)
library(readr)
library(here)

setwd(here())

# =============================================================================
# 1. PROCESS CLIMATE VULNERABILITY INDEX (Global Data Lab)
# =============================================================================

process_climate_vulnerability <- function() {
  cat("Processing Climate Vulnerability Index...\n")
  
  climate_data <- read_csv(
    "data/raw/global_data_lab/climate vunerability index.csv",
    show_col_types = FALSE
  )
  
  # Get national level data only
  climate_national <- climate_data %>%
    filter(Level == "National") %>%
    select(Country, ISO_Code, `2023`, `2022`, `2021`, `2020`) %>%
    # Use most recent available year
    mutate(
      climate_vulnerability_index = coalesce(`2023`, `2022`, `2021`, `2020`)
    ) %>%
    select(Country, ISO_Code, climate_vulnerability_index) %>%
    rename(country = Country, iso3 = ISO_Code)
  
  cat("  Processed", nrow(climate_national), "countries\n")
  return(climate_national)
}

# =============================================================================
# 2. PROCESS HEALTH VULNERABILITY DATA (Global Data Lab)
# =============================================================================

process_health_vulnerability <- function() {
  cat("Processing Health Vulnerability Data...\n")
  
  health_data <- read_csv(
    "data/raw/global_data_lab/health vunerability data.csv",
    show_col_types = FALSE
  )
  
  # Get national level data for most recent year
  health_national <- health_data %>%
    filter(Level == "National") %>%
    group_by(Country) %>%
    slice_max(Year, n = 1) %>%
    ungroup() %>%
    select(
      Country, ISO_Code, Year,
      stunting, wasting, underweight,
      infmort, u5mort, chmort
    ) %>%
    rename(
      country = Country,
      iso3 = ISO_Code,
      child_stunting_rate = stunting,
      child_wasting_rate = wasting,
      child_underweight_rate = underweight,
      infant_mortality = infmort,
      under5_mortality = u5mort,
      child_mortality = chmort
    )
  
  cat("  Processed", nrow(health_national), "countries\n")
  return(health_national)
}

# =============================================================================
# 3. PROCESS WHO CHILD STUNTING DATA
# =============================================================================

process_who_stunting <- function() {
  cat("Processing WHO Child Stunting Data...\n")
  
  who_data <- read_csv(
    "data/raw/who/child_stunting_data.csv",
    show_col_types = FALSE
  )
  
  # Filter for country-level data (not regions)
  who_countries <- who_data %>%
    filter(
      DIM_GEO_CODE_TYPE == "COUNTRY" | 
      (DIM_GEO_CODE_TYPE == "REGION" & !is.na(GEO_NAME_SHORT))
    ) %>%
    # Get most recent year for each country
    group_by(GEO_NAME_SHORT) %>%
    slice_max(DIM_TIME, n = 1) %>%
    ungroup() %>%
    select(GEO_NAME_SHORT, DIM_TIME, RATE_PER_100_N) %>%
    rename(
      country = GEO_NAME_SHORT,
      year = DIM_TIME,
      who_stunting_rate = RATE_PER_100_N
    )
  
  cat("  Processed", nrow(who_countries), "countries/regions\n")
  return(who_countries)
}

# =============================================================================
# 4. PROCESS FOOD SUPPLY DATA (Our World in Data)
# =============================================================================

process_food_supply <- function() {
  cat("Processing Food Supply Data...\n")
  
  food_data <- read_csv(
    "data/raw/our_world_in_data/food supply data.csv",
    show_col_types = FALSE
  )
  
  # Get column name (it's a long name)
  col_name <- names(food_data)[3]
  
  # Get most recent year for each country
  food_supply <- food_data %>%
    rename(
      country = Entity,
      year = Year,
      food_supply_kcal = !!sym(col_name)
    ) %>%
    group_by(country) %>%
    slice_max(year, n = 1) %>%
    ungroup() %>%
    select(country, year, food_supply_kcal)
  
  cat("  Processed", nrow(food_supply), "countries\n")
  return(food_supply)
}

# =============================================================================
# 5. PROCESS POVERTY DATA (Our World in Data)
# =============================================================================

process_poverty_owid <- function() {
  cat("Processing Poverty Data (Our World in Data)...\n")
  
  poverty_data <- read_csv(
    "data/raw/our_world_in_data/poverty data.csv",
    show_col_types = FALSE
  )
  
  # Get most recent year for each country
  poverty <- poverty_data %>%
    rename(
      country = Country,
      year = Year,
      poverty_below_3usd = `Share below $3 a day`
    ) %>%
    group_by(country) %>%
    slice_max(year, n = 1) %>%
    ungroup() %>%
    select(country, year, poverty_below_3usd)
  
  cat("  Processed", nrow(poverty), "countries\n")
  return(poverty)
}

# =============================================================================
# 6. PROCESS AGRICULTURAL PRODUCTION DATA (USDA)
# =============================================================================

process_agricultural_production <- function() {
  cat("Processing Agricultural Production Data...\n")
  
  ag_data <- read_csv(
    "data/raw/usda/agricultural_production_1.csv",
    show_col_types = FALSE
  )
  
  # Get most recent year for each country
  # Focus on TFP_Index (Total Factor Productivity) as key indicator
  ag_production <- ag_data %>%
    filter(Attribute == "TFP_Index") %>%
    rename(
      country = `Country/territory`,
      iso3 = ISO3,
      year = Year,
      tfp_index = Value
    ) %>%
    group_by(country) %>%
    slice_max(year, n = 1) %>%
    ungroup() %>%
    select(country, iso3, year, tfp_index)
  
  cat("  Processed", nrow(ag_production), "countries\n")
  return(ag_production)
}

# =============================================================================
# 7. MAIN PROCESSING FUNCTION
# =============================================================================

process_all_new_data <- function() {
  cat("========================================\n")
  cat("PROCESSING ALL NEW DATA SOURCES\n")
  cat("========================================\n\n")
  
  # Process each data source
  climate_data <- process_climate_vulnerability()
  health_data <- process_health_vulnerability()
  who_stunting <- process_who_stunting()
  food_supply <- process_food_supply()
  poverty_owid <- process_poverty_owid()
  ag_production <- process_agricultural_production()
  
  # Combine all data
  cat("\nCombining all data sources...\n")
  
  # Start with climate data as base (has ISO codes)
  combined_data <- climate_data %>%
    full_join(health_data, by = c("country", "iso3")) %>%
    full_join(who_stunting %>% select(country, who_stunting_rate), by = "country") %>%
    full_join(food_supply %>% select(country, food_supply_kcal), by = "country") %>%
    full_join(poverty_owid %>% select(country, poverty_below_3usd), by = "country") %>%
    full_join(ag_production %>% select(country, tfp_index), by = "country")
  
  # Save processed data
  output_file <- "data/processed/new_data_sources_combined.csv"
  write_csv(combined_data, output_file)
  
  cat("\n========================================\n")
  cat("PROCESSING COMPLETE!\n")
  cat("========================================\n")
  cat("Output saved to:", output_file, "\n")
  cat("Total countries:", nrow(combined_data), "\n")
  cat("\nData coverage:\n")
  cat("  Climate Vulnerability:", sum(!is.na(combined_data$climate_vulnerability_index)), "countries\n")
  cat("  Health Data:", sum(!is.na(combined_data$child_stunting_rate)), "countries\n")
  cat("  WHO Stunting:", sum(!is.na(combined_data$who_stunting_rate)), "countries\n")
  cat("  Food Supply:", sum(!is.na(combined_data$food_supply_kcal)), "countries\n")
  cat("  Poverty (OWID):", sum(!is.na(combined_data$poverty_below_3usd)), "countries\n")
  cat("  Agricultural TFP:", sum(!is.na(combined_data$tfp_index)), "countries\n")
  
  return(combined_data)
}

# Run processing
if (!interactive()) {
  processed_data <- process_all_new_data()
}

