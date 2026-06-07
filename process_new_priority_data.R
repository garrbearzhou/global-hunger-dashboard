# Process New Priority Data Sources
# 1. Food Price Inflation
# 2. Refugee & IDP Data
# 3. Food Import Dependency
# 4. Water Scarcity & Access
library(tidyverse)
library(readxl)
library(lubridate)

cat("📊 Processing New Priority Data Sources\n")
cat("=======================================\n\n")

# Function to standardize country names (same as in app)
standardize_country_names <- function(country) {
  country %>%
    str_trim() %>%
    str_replace_all("^Congo, Rep\\.$", "Republic of the Congo") %>%
    str_replace_all("^Congo, Dem\\. Rep\\.$", "Democratic Republic of the Congo") %>%
    str_replace_all("^Korea, Dem\\. People's Rep\\.$", "North Korea") %>%
    str_replace_all("^Korea, Rep\\.$", "South Korea") %>%
    str_replace_all("^Egypt, Arab Rep\\.$", "Egypt") %>%
    str_replace_all("^Venezuela, RB$", "Venezuela") %>%
    str_replace_all("^Yemen, Rep\\.$", "Yemen") %>%
    str_replace_all("^Iran, Islamic Rep\\.$", "Iran") %>%
    str_replace_all("^Russian Federation$", "Russia") %>%
    str_replace_all("^Syrian Arab Republic$", "Syria") %>%
    str_replace_all("^Lao PDR$", "Laos") %>%
    str_replace_all("^Micronesia, Fed\\. Sts\\.$", "Micronesia") %>%
    str_replace_all("^St\\. Martin \\(French part\\)$", "Saint Martin") %>%
    str_replace_all("^Turkiye$", "Turkey") %>%
    str_replace_all("^Gambia, The$", "Gambia") %>%
    str_replace_all("^Bahamas, The$", "Bahamas") %>%
    str_replace_all("^Somalia, Fed\\. Rep\\.$", "Somalia")
}

# ============================================================================
# 1. FOOD PRICE INFLATION DATA
# ============================================================================
cat("1. Processing Food Price Inflation Data...\n")
food_price_data <- NULL
if(file.exists("data/raw/fao/FAO_Data/food price indicies data.xlsx")) {
  tryCatch({
    # Check sheets
    sheets <- excel_sheets("data/raw/fao/FAO_Data/food price indicies data.xlsx")
    cat("   Sheets:", paste(sheets, collapse = ", "), "\n")
    
    # Read first sheet
    food_price_raw <- read_excel("data/raw/fao/FAO_Data/food price indicies data.xlsx", sheet = 1)
    cat("   Columns:", paste(names(food_price_raw)[1:10], collapse = ", "), "...\n")
    cat("   Rows:", nrow(food_price_raw), "\n")
    
    # Try to find country and year columns
    # If it's a time series, might need different processing
    # For now, create placeholder - will need to adjust based on actual structure
    cat("   ⚠️ Food price data structure needs manual review\n")
    cat("   💡 This data may need special processing based on format\n\n")
  }, error = function(e) {
    cat("   ⚠️ Error processing food price data:", e$message, "\n\n")
  })
} else {
  cat("   ⚠️ File not found\n\n")
}

# ============================================================================
# 2. REFUGEE & IDP DATA (UNHCR)
# ============================================================================
cat("2. Processing Refugee & IDP Data (UNHCR)...\n")
refugee_data <- NULL
if(file.exists("data/raw/un/unhcr/displaced people data/persons_of_concern.csv")) {
  tryCatch({
    refugee_raw <- read_csv("data/raw/un/unhcr/displaced people data/persons_of_concern.csv", show_col_types = FALSE)
    cat("   Columns:", paste(names(refugee_raw), collapse = ", "), "\n")
    cat("   Rows:", nrow(refugee_raw), "\n")
    
    # Process UNHCR data - aggregate by country of asylum (where refugees are hosted)
    refugee_data <- refugee_raw %>%
      filter(`Country of Asylum` != "-" & !is.na(`Country of Asylum`)) %>%
      mutate(
        country = standardize_country_names(`Country of Asylum`),
        refugees = as.numeric(Refugees),
        idps = as.numeric(if("IDPs" %in% names(.)) IDPs else 0),
        asylum_seekers = as.numeric(`Asylum-seekers`),
        stateless = as.numeric(`Stateless persons`)
      ) %>%
      filter(!is.na(country) & country != "") %>%
      group_by(country, Year) %>%
      summarise(
        refugees = sum(refugees, na.rm = TRUE),
        idps = sum(idps, na.rm = TRUE),
        asylum_seekers = sum(asylum_seekers, na.rm = TRUE),
        stateless = sum(stateless, na.rm = TRUE),
        total_displaced = refugees + idps + asylum_seekers + stateless,
        .groups = "drop"
      ) %>%
      # Get most recent year's data per country
      group_by(country) %>%
      slice_max(Year, n = 1) %>%
      ungroup() %>%
      select(country, refugee_latest_year = Year, refugees_latest = refugees, 
             idps_latest = idps, total_displaced_latest = total_displaced)
    
    cat("   ✅ Processed", nrow(refugee_data), "countries\n")
    cat("   Latest year:", max(refugee_data$refugee_latest_year, na.rm = TRUE), "\n\n")
  }, error = function(e) {
    cat("   ⚠️ Error processing refugee data:", e$message, "\n\n")
  })
} else {
  cat("   ⚠️ File not found\n\n")
}

# ============================================================================
# 3. FOOD IMPORT DEPENDENCY DATA
# ============================================================================
cat("3. Processing Food Import Dependency Data...\n")
food_import_data <- NULL
if(file.exists("data/raw/food trade dependency/data overview.csv")) {
  tryCatch({
    # Read sample first to understand structure
    import_raw <- read_csv("data/raw/food trade dependency/data overview.csv", show_col_types = FALSE)
    cat("   Columns:", paste(names(import_raw), collapse = ", "), "\n")
    cat("   Rows:", nrow(import_raw), "\n")
    
    # Process food import dependency
    # Extract year from date
    food_import_data <- import_raw %>%
      mutate(
        country = standardize_country_names(importer_country_name),
        year = year(as.Date(date)),
        import_share = as.numeric(import_share)
      ) %>%
      filter(!is.na(country) & country != "" & !is.na(import_share)) %>%
      # Aggregate by country and year (sum across commodities)
      group_by(country, year) %>%
      summarise(
        total_import_share = sum(import_share, na.rm = TRUE),
        avg_import_share = mean(import_share, na.rm = TRUE),
        max_import_share = max(import_share, na.rm = TRUE),
        commodities_count = n(),
        .groups = "drop"
      ) %>%
      # Get most recent year per country
      group_by(country) %>%
      slice_max(year, n = 1) %>%
      ungroup() %>%
      select(country, import_latest_year = year, 
             food_import_dependency = avg_import_share,
             food_import_max = max_import_share,
             food_import_commodities = commodities_count)
    
    cat("   ✅ Processed", nrow(food_import_data), "countries\n")
    cat("   Latest year:", max(food_import_data$import_latest_year, na.rm = TRUE), "\n\n")
  }, error = function(e) {
    cat("   ⚠️ Error processing food import data:", e$message, "\n\n")
  })
} else {
  cat("   ⚠️ File not found\n\n")
}

# ============================================================================
# 4. WATER SCARCITY & ACCESS DATA
# ============================================================================
cat("4. Processing Water Scarcity & Access Data...\n")
water_data <- NULL
water_file <- "data/raw/our_world_in_data/freshwater withdrawals as share of resources/freshwater-withdrawals-as-a-share-of-internal-resources.csv"
if(file.exists(water_file)) {
  tryCatch({
    water_raw <- read_csv(water_file, show_col_types = FALSE)
    cat("   Columns:", paste(names(water_raw), collapse = ", "), "\n")
    cat("   Rows:", nrow(water_raw), "\n")
    
    # Get the water stress column name (it's long)
    water_col <- names(water_raw)[grepl("water stress|withdrawal", names(water_raw), ignore.case = TRUE)][1]
    
    # Process water data
    water_data <- water_raw %>%
      mutate(
        country = standardize_country_names(Entity),
        water_stress = as.numeric(!!sym(water_col))
      ) %>%
      filter(!is.na(country) & country != "" & !is.na(water_stress)) %>%
      # Get most recent year per country
      group_by(country) %>%
      slice_max(Year, n = 1) %>%
      ungroup() %>%
      select(country, water_latest_year = Year, water_stress_index = water_stress)
    
    cat("   ✅ Processed", nrow(water_data), "countries\n")
    cat("   Latest year:", max(water_data$water_latest_year, na.rm = TRUE), "\n\n")
  }, error = function(e) {
    cat("   ⚠️ Error processing water data:", e$message, "\n\n")
  })
} else {
  cat("   ⚠️ File not found\n\n")
}

# ============================================================================
# COMBINE ALL DATA
# ============================================================================
cat("5. Combining all new data sources...\n")

# Get all unique countries
all_countries <- unique(c(
  if(!is.null(refugee_data)) refugee_data$country else NULL,
  if(!is.null(food_import_data)) food_import_data$country else NULL,
  if(!is.null(water_data)) water_data$country else NULL
))

new_priority_data <- data.frame(country = all_countries, stringsAsFactors = FALSE) %>%
  # Join refugee data
  {if(!is.null(refugee_data)) {
    left_join(., refugee_data, by = "country")
  } else .} %>%
  # Join food import data
  {if(!is.null(food_import_data)) {
    left_join(., food_import_data, by = "country")
  } else .} %>%
  # Join water data
  {if(!is.null(water_data)) {
    left_join(., water_data, by = "country")
  } else .}

cat("   ✅ Combined data for", nrow(new_priority_data), "countries\n\n")

# Save processed data
output_file <- "data/processed/new_priority_data.csv"
write_csv(new_priority_data, output_file)
cat("💾 Saved processed data to:", output_file, "\n\n")

# Summary statistics
cat("📊 Data Summary:\n")
cat("================\n")
cat("Total countries:", nrow(new_priority_data), "\n")
if(!is.null(refugee_data)) {
  cat("Countries with refugee/IDP data:", sum(!is.na(new_priority_data$refugees_latest) | !is.na(new_priority_data$idps_latest)), "\n")
  cat("Total refugees (latest):", sum(new_priority_data$refugees_latest, na.rm = TRUE) / 1e6, "M\n")
  cat("Total IDPs (latest):", sum(new_priority_data$idps_latest, na.rm = TRUE) / 1e6, "M\n")
}
if(!is.null(food_import_data)) {
  cat("Countries with food import dependency data:", sum(!is.na(new_priority_data$food_import_dependency)), "\n")
}
if(!is.null(water_data)) {
  cat("Countries with water scarcity data:", sum(!is.na(new_priority_data$water_stress_index)), "\n")
  cat("Countries with high water stress (>75%):", sum(new_priority_data$water_stress_index > 75, na.rm = TRUE), "\n")
}

cat("\n✅ Processing complete!\n")
