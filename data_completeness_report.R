# Data Completeness Report
# This script generates a comprehensive report of countries missing specific data fields

library(tidyverse)

# Load the app data
source('enhanced_fao_wfp_app.R', local = TRUE)

if(exists('sovereign_countries')) {
  data <- sovereign_countries
  
  cat("=" %+% strrep("=", 80) %+% "\n")
  cat("DATA COMPLETENESS REPORT\n")
  cat("=" %+% strrep("=", 80) %+% "\n\n")
  
  cat("Total countries in dataset:", nrow(data), "\n\n")
  
  # Missing undernourishment
  missing_undernourishment <- data %>% 
    filter(is.na(undernourishment_rate)) %>% 
    select(Area) %>%
    arrange(Area)
  cat("COUNTRIES MISSING UNDERNOURISHMENT DATA:", nrow(missing_undernourishment), "\n")
  cat(paste(missing_undernourishment$Area, collapse = ", "), "\n\n")
  
  # Missing GDP
  missing_gdp <- data %>% 
    filter(is.na(gdp_per_capita)) %>% 
    select(Area) %>%
    arrange(Area)
  cat("COUNTRIES MISSING GDP PER CAPITA DATA:", nrow(missing_gdp), "\n")
  cat(paste(missing_gdp$Area, collapse = ", "), "\n\n")
  
  # Missing poverty
  missing_poverty <- data %>% 
    filter(is.na(poverty_rate) & is.na(poverty_headcount)) %>% 
    select(Area) %>%
    arrange(Area)
  cat("COUNTRIES MISSING POVERTY DATA:", nrow(missing_poverty), "\n")
  cat(paste(missing_poverty$Area, collapse = ", "), "\n\n")
  
  # Missing life expectancy
  missing_life <- data %>% 
    filter(is.na(life_expectancy)) %>% 
    select(Area) %>%
    arrange(Area)
  cat("COUNTRIES MISSING LIFE EXPECTANCY DATA:", nrow(missing_life), "\n")
  cat(paste(missing_life$Area, collapse = ", "), "\n\n")
  
  # Missing population
  missing_pop <- data %>% 
    filter(is.na(population)) %>% 
    select(Area) %>%
    arrange(Area)
  cat("COUNTRIES MISSING POPULATION DATA:", nrow(missing_pop), "\n")
  cat(paste(missing_pop$Area, collapse = ", "), "\n\n")
  
  # Countries missing multiple key indicators
  missing_multiple <- data %>%
    mutate(
      missing_count = (
        is.na(undernourishment_rate) +
        is.na(gdp_per_capita) +
        (is.na(poverty_rate) & is.na(poverty_headcount)) +
        is.na(life_expectancy) +
        is.na(population)
      )
    ) %>%
    filter(missing_count >= 3) %>%
    select(Area, missing_count, undernourishment_rate, gdp_per_capita, poverty_rate, poverty_headcount, life_expectancy, population) %>%
    arrange(desc(missing_count), Area)
  
  cat("COUNTRIES MISSING 3+ KEY INDICATORS:", nrow(missing_multiple), "\n")
  print(missing_multiple)
  
  # Write to CSV
  write_csv(missing_undernourishment, "countries_missing_undernourishment.csv")
  write_csv(missing_gdp, "countries_missing_gdp.csv")
  write_csv(missing_poverty, "countries_missing_poverty.csv")
  write_csv(missing_life, "countries_missing_life_expectancy.csv")
  write_csv(missing_multiple, "countries_missing_multiple_indicators.csv")
  
  cat("\n\nReports saved to CSV files.\n")
}

