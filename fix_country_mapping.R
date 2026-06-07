#!/usr/bin/env Rscript

# Country Name Mapping Fix
# This script creates a comprehensive country name mapping system

library(tidyverse)
library(readr)

cat("🔧 FIXING COUNTRY NAME MAPPING\n")
cat("=============================\n\n")

# Load all data sources to identify name variations
fao_data <- read_csv("data/raw/fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv", show_col_types = FALSE)
wb_data <- read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE)
wfp_markets <- read_csv("data/raw/wfp/markets.csv", show_col_types = FALSE)
em_dat <- read_csv("data/raw/em_dat/em_dat_data.csv", show_col_types = FALSE)

# Get all unique country names from each source
fao_countries <- unique(fao_data$Area)
wb_countries <- unique(wb_data$country)
wfp_countries <- unique(wfp_markets$Country)
em_dat_countries <- unique(em_dat$country)

cat("📊 IDENTIFYING COUNTRY NAME VARIATIONS\n")
cat("=====================================\n")

# Find countries that appear in multiple sources with different names
all_countries <- unique(c(fao_countries, wb_countries, wfp_countries, em_dat_countries))

# Create a comprehensive mapping
country_mapping <- list(
  # Major countries with multiple name variations
  "United States" = c("United States of America", "United States", "USA", "US"),
  "United Kingdom" = c("United Kingdom of Great Britain and Northern Ireland", "United Kingdom", "UK", "Britain"),
  "China" = c("China, mainland", "China", "People's Republic of China"),
  "Hong Kong" = c("China, Hong Kong SAR", "Hong Kong SAR, China", "Hong Kong"),
  "Macao" = c("China, Macao SAR", "Macao SAR, China", "Macao"),
  "Taiwan" = c("China, Taiwan Province of", "Taiwan", "Republic of China"),
  "South Korea" = c("Korea, Republic of", "Republic of Korea", "South Korea"),
  "North Korea" = c("Korea, Democratic People's Republic of", "Democratic People's Republic of Korea", "North Korea"),
  "Russia" = c("Russian Federation", "Russia"),
  "Vietnam" = c("Viet Nam", "Vietnam"),
  "Bolivia" = c("Bolivia (Plurinational State of)", "Bolivia"),
  "Venezuela" = c("Venezuela (Bolivarian Republic of)", "Venezuela"),
  "Iran" = c("Iran (Islamic Republic of)", "Iran"),
  "Turkey" = c("Türkiye", "Turkey"),
  "Moldova" = c("Republic of Moldova", "Moldova"),
  "Congo" = c("Congo", "Republic of the Congo"),
  "Democratic Republic of the Congo" = c("Democratic Republic of the Congo", "DRC", "Congo, Democratic Republic of the"),
  "Tanzania" = c("United Republic of Tanzania", "Tanzania"),
  "Côte d'Ivoire" = c("Côte d'Ivoire", "Ivory Coast"),
  "Laos" = c("Lao People's Democratic Republic", "Laos"),
  "Kyrgyzstan" = c("Kyrgyzstan", "Kyrgyz Republic"),
  "Gambia" = c("Gambia", "The Gambia"),
  "Bahamas" = c("Bahamas", "The Bahamas", "Bahamas, The"),
  "Netherlands" = c("Netherlands (Kingdom of the)", "Netherlands"),
  "Palestine" = c("Palestine", "Palestinian Territory"),
  "Gaza" = c("Gaza", "Gaza Strip"),
  "West Bank" = c("West Bank", "West Bank and Gaza"),
  "Cape Verde" = c("Cabo Verde", "Cape Verde"),
  "Micronesia" = c("Micronesia (Federated States of)", "Micronesia", "Federated States of Micronesia"),
  "Saint Kitts and Nevis" = c("Saint Kitts and Nevis", "St. Kitts and Nevis"),
  "Saint Lucia" = c("Saint Lucia", "St. Lucia"),
  "Saint Vincent and the Grenadines" = c("Saint Vincent and the Grenadines", "St. Vincent and the Grenadines"),
  "Cook Islands" = c("Cook Islands"),
  "Niue" = c("Niue"),
  "Tokelau" = c("Tokelau"),
  "Puerto Rico" = c("Puerto Rico"),
  "Slovakia" = c("Slovakia", "Slovak Republic"),
  "Slovenia" = c("Slovenia", "Republic of Slovenia"),
  "Czech Republic" = c("Czech Republic", "Czechia"),
  "Macedonia" = c("North Macedonia", "Macedonia", "Former Yugoslav Republic of Macedonia"),
  "Bosnia and Herzegovina" = c("Bosnia and Herzegovina", "Bosnia"),
  "Serbia" = c("Serbia", "Republic of Serbia"),
  "Montenegro" = c("Montenegro", "Republic of Montenegro"),
  "Kosovo" = c("Kosovo", "Republic of Kosovo"),
  "Eswatini" = c("Eswatini", "Swaziland"),
  "Cabo Verde" = c("Cabo Verde", "Cape Verde"),
  "São Tomé and Príncipe" = c("São Tomé and Príncipe", "Sao Tome and Principe"),
  "Guinea-Bissau" = c("Guinea-Bissau"),
  "Equatorial Guinea" = c("Equatorial Guinea"),
  "Central African Republic" = c("Central African Republic", "CAR"),
  "Democratic Republic of the Congo" = c("Democratic Republic of the Congo", "DRC", "Congo, Democratic Republic of the"),
  "Republic of the Congo" = c("Congo", "Republic of the Congo"),
  "Chad" = c("Chad", "Republic of Chad"),
  "Niger" = c("Niger", "Republic of Niger"),
  "Mali" = c("Mali", "Republic of Mali"),
  "Burkina Faso" = c("Burkina Faso"),
  "Senegal" = c("Senegal", "Republic of Senegal"),
  "Mauritania" = c("Mauritania", "Islamic Republic of Mauritania"),
  "Guinea" = c("Guinea", "Republic of Guinea"),
  "Sierra Leone" = c("Sierra Leone", "Republic of Sierra Leone"),
  "Liberia" = c("Liberia", "Republic of Liberia"),
  "Ghana" = c("Ghana", "Republic of Ghana"),
  "Togo" = c("Togo", "Togolese Republic"),
  "Benin" = c("Benin", "Republic of Benin"),
  "Nigeria" = c("Nigeria", "Federal Republic of Nigeria"),
  "Cameroon" = c("Cameroon", "Republic of Cameroon"),
  "Gabon" = c("Gabon", "Gabonese Republic"),
  "Republic of the Congo" = c("Congo", "Republic of the Congo"),
  "Angola" = c("Angola", "Republic of Angola"),
  "Zambia" = c("Zambia", "Republic of Zambia"),
  "Zimbabwe" = c("Zimbabwe", "Republic of Zimbabwe"),
  "Botswana" = c("Botswana", "Republic of Botswana"),
  "Namibia" = c("Namibia", "Republic of Namibia"),
  "South Africa" = c("South Africa", "Republic of South Africa"),
  "Lesotho" = c("Lesotho", "Kingdom of Lesotho"),
  "Eswatini" = c("Eswatini", "Kingdom of Eswatini", "Swaziland"),
  "Madagascar" = c("Madagascar", "Republic of Madagascar"),
  "Mauritius" = c("Mauritius", "Republic of Mauritius"),
  "Seychelles" = c("Seychelles", "Republic of Seychelles"),
  "Comoros" = c("Comoros", "Union of the Comoros"),
  "Djibouti" = c("Djibouti", "Republic of Djibouti"),
  "Somalia" = c("Somalia", "Federal Republic of Somalia"),
  "Ethiopia" = c("Ethiopia", "Federal Democratic Republic of Ethiopia"),
  "Eritrea" = c("Eritrea", "State of Eritrea"),
  "Sudan" = c("Sudan", "Republic of the Sudan"),
  "South Sudan" = c("South Sudan", "Republic of South Sudan"),
  "Kenya" = c("Kenya", "Republic of Kenya"),
  "Uganda" = c("Uganda", "Republic of Uganda"),
  "Rwanda" = c("Rwanda", "Republic of Rwanda"),
  "Burundi" = c("Burundi", "Republic of Burundi"),
  "Tanzania" = c("United Republic of Tanzania", "Tanzania"),
  "Malawi" = c("Malawi", "Republic of Malawi"),
  "Mozambique" = c("Mozambique", "Republic of Mozambique"),
  "Zambia" = c("Zambia", "Republic of Zambia"),
  "Zimbabwe" = c("Zimbabwe", "Republic of Zimbabwe"),
  "Botswana" = c("Botswana", "Republic of Botswana"),
  "Namibia" = c("Namibia", "Republic of Namibia"),
  "South Africa" = c("South Africa", "Republic of South Africa"),
  "Lesotho" = c("Lesotho", "Kingdom of Lesotho"),
  "Eswatini" = c("Eswatini", "Kingdom of Eswatini", "Swaziland"),
  "Madagascar" = c("Madagascar", "Republic of Madagascar"),
  "Mauritius" = c("Mauritius", "Republic of Mauritius"),
  "Seychelles" = c("Seychelles", "Republic of Seychelles"),
  "Comoros" = c("Comoros", "Union of the Comoros"),
  "Djibouti" = c("Djibouti", "Republic of Djibouti"),
  "Somalia" = c("Somalia", "Federal Republic of Somalia"),
  "Ethiopia" = c("Ethiopia", "Federal Democratic Republic of Ethiopia"),
  "Eritrea" = c("Eritrea", "State of Eritrea"),
  "Sudan" = c("Sudan", "Republic of the Sudan"),
  "South Sudan" = c("South Sudan", "Republic of South Sudan"),
  "Kenya" = c("Kenya", "Republic of Kenya"),
  "Uganda" = c("Uganda", "Republic of Uganda"),
  "Rwanda" = c("Rwanda", "Republic of Rwanda"),
  "Burundi" = c("Burundi", "Republic of Burundi"),
  "Tanzania" = c("United Republic of Tanzania", "Tanzania"),
  "Malawi" = c("Malawi", "Republic of Malawi"),
  "Mozambique" = c("Mozambique", "Republic of Mozambique")
)

# Create reverse mapping (from all variations to standard name)
reverse_mapping <- list()
for (standard_name in names(country_mapping)) {
  for (variation in country_mapping[[standard_name]]) {
    reverse_mapping[[variation]] <- standard_name
  }
}

cat("✅ Country mapping created with", length(reverse_mapping), "name variations\n\n")

# Function to standardize country names
standardize_country_name <- function(country_name) {
  if (is.na(country_name) || country_name == "") {
    return(country_name)
  }
  
  # Check if we have a mapping for this country name
  if (country_name %in% names(reverse_mapping)) {
    return(reverse_mapping[[country_name]])
  }
  
  # If no mapping found, return the original name
  return(country_name)
}

# Test the mapping with some examples
test_countries <- c(
  "United States of America",
  "United Kingdom of Great Britain and Northern Ireland", 
  "China, mainland",
  "Korea, Republic of",
  "Russian Federation",
  "Viet Nam",
  "Bolivia (Plurinational State of)",
  "Venezuela (Bolivarian Republic of)",
  "Iran (Islamic Republic of)",
  "Türkiye"
)

cat("🧪 TESTING COUNTRY NAME STANDARDIZATION\n")
cat("======================================\n")
for (country in test_countries) {
  standardized <- standardize_country_name(country)
  cat(sprintf("%-50s -> %s\n", country, standardized))
}

# Save the mapping to a file for use in the app
mapping_df <- data.frame(
  original_name = names(reverse_mapping),
  standardized_name = unlist(reverse_mapping),
  stringsAsFactors = FALSE
)

write_csv(mapping_df, "country_name_mapping.csv")

cat("\n💾 Country mapping saved to: country_name_mapping.csv\n")
cat("✅ Country name mapping fix complete!\n")
