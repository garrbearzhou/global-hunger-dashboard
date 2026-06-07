# Process ACLED Conflict Data for Integration
library(tidyverse)
library(readxl)

cat("📊 Processing ACLED Conflict Data\n")
cat("==================================\n\n")

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

# Process fatalities data
cat("1. Processing fatalities per country...\n")
fatalities <- NULL
if(file.exists("data/raw/acled - conflict data/fatalities per country.xlsx")) {
  fatalities_raw <- read_excel("data/raw/acled - conflict data/fatalities per country.xlsx")
  
  # Get most recent year and aggregate
  fatalities <- fatalities_raw %>%
    mutate(country = standardize_country_names(COUNTRY)) %>%
    group_by(country) %>%
    # Get most recent year's data and average of last 3 years
    summarise(
      latest_year = max(YEAR, na.rm = TRUE),
      fatalities_latest = FATALITIES[YEAR == latest_year][1],
      fatalities_avg_3yr = mean(FATALITIES[YEAR >= latest_year - 2], na.rm = TRUE),
      fatalities_total = sum(FATALITIES, na.rm = TRUE),
      years_with_conflict = n_distinct(YEAR[FATALITIES > 0]),
      .groups = "drop"
    ) %>%
    filter(!is.na(country) & country != "")
  
  cat("   ✅ Processed", nrow(fatalities), "countries\n")
  cat("   Latest year range:", min(fatalities$latest_year, na.rm = TRUE), "-", 
      max(fatalities$latest_year, na.rm = TRUE), "\n\n")
} else {
  cat("   ⚠️ File not found\n\n")
}

# Process events targeting civilians
cat("2. Processing events targeting civilians...\n")
civilian_events <- NULL
if(file.exists("data/raw/acled - conflict data/events targeting civilians.xlsx")) {
  civilian_events_raw <- read_excel("data/raw/acled - conflict data/events targeting civilians.xlsx")
  
  civilian_events <- civilian_events_raw %>%
    mutate(country = standardize_country_names(COUNTRY)) %>%
    group_by(country) %>%
    summarise(
      latest_year = max(YEAR, na.rm = TRUE),
      civilian_events_latest = EVENTS[YEAR == latest_year][1],
      civilian_events_avg_3yr = mean(EVENTS[YEAR >= latest_year - 2], na.rm = TRUE),
      civilian_events_total = sum(EVENTS, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(!is.na(country) & country != "")
  
  cat("   ✅ Processed", nrow(civilian_events), "countries\n\n")
} else {
  cat("   ⚠️ File not found\n\n")
}

# Process political violence incidents
cat("3. Processing political violence incidents...\n")
violence <- NULL
if(file.exists("data/raw/acled - conflict data/political violence incidents.xlsx")) {
  violence_raw <- read_excel("data/raw/acled - conflict data/political violence incidents.xlsx")
  
  violence <- violence_raw %>%
    mutate(country = standardize_country_names(COUNTRY)) %>%
    group_by(country, YEAR) %>%
    summarise(events = sum(EVENTS, na.rm = TRUE), .groups = "drop") %>%
    group_by(country) %>%
    summarise(
      latest_year = max(YEAR, na.rm = TRUE),
      violence_events_latest = events[YEAR == latest_year][1],
      violence_events_avg_3yr = mean(events[YEAR >= latest_year - 2], na.rm = TRUE),
      violence_events_total = sum(events, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(!is.na(country) & country != "")
  
  cat("   ✅ Processed", nrow(violence), "countries\n\n")
} else {
  cat("   ⚠️ File not found\n\n")
}

# Process reported civilian deaths
cat("4. Processing reported civilian deaths...\n")
civilian_deaths <- NULL
if(file.exists("data/raw/acled - conflict data/reported civilian deaths from targeting.xlsx")) {
  civilian_deaths_raw <- read_excel("data/raw/acled - conflict data/reported civilian deaths from targeting.xlsx")
  
  civilian_deaths <- civilian_deaths_raw %>%
    mutate(country = standardize_country_names(COUNTRY)) %>%
    group_by(country) %>%
    summarise(
      latest_year = max(YEAR, na.rm = TRUE),
      civilian_deaths_latest = FATALITIES[YEAR == latest_year][1],
      civilian_deaths_avg_3yr = mean(FATALITIES[YEAR >= latest_year - 2], na.rm = TRUE),
      civilian_deaths_total = sum(FATALITIES, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(!is.na(country) & country != "")
  
  cat("   ✅ Processed", nrow(civilian_deaths), "countries\n\n")
} else {
  cat("   ⚠️ File not found\n\n")
}

# Combine all ACLED data
cat("5. Combining all ACLED indicators...\n")
acled_data <- data.frame(country = character(), stringsAsFactors = FALSE)

# Get all unique countries
all_countries <- unique(c(
  if(!is.null(fatalities)) fatalities$country else NULL,
  if(!is.null(civilian_events)) civilian_events$country else NULL,
  if(!is.null(violence)) violence$country else NULL,
  if(!is.null(civilian_deaths)) civilian_deaths$country else NULL
))

acled_data <- data.frame(country = all_countries, stringsAsFactors = FALSE) %>%
  # Join fatalities
  {if(!is.null(fatalities)) {
    left_join(., fatalities %>% select(-latest_year), by = "country")
  } else .} %>%
  # Join civilian events
  {if(!is.null(civilian_events)) {
    left_join(., civilian_events %>% select(-latest_year), by = "country")
  } else .} %>%
  # Join violence
  {if(!is.null(violence)) {
    left_join(., violence %>% select(-latest_year), by = "country")
  } else .} %>%
  # Join civilian deaths
  {if(!is.null(civilian_deaths)) {
    left_join(., civilian_deaths %>% select(-latest_year), by = "country")
  } else .}

# Create conflict intensity score (0-100 scale)
acled_data <- acled_data %>%
  mutate(
    # Conflict intensity indicators
    has_active_conflict = !is.na(fatalities_latest) & fatalities_latest > 0,
    
    # Conflict intensity score (0-100)
    # Based on fatalities, events, and civilian targeting
    conflict_intensity_score = case_when(
      # Very high intensity: >10,000 fatalities/year or >1000 events/year
      (!is.na(fatalities_avg_3yr) & fatalities_avg_3yr > 10000) |
      (!is.na(violence_events_avg_3yr) & violence_events_avg_3yr > 1000) ~ 100,
      
      # High intensity: 1,000-10,000 fatalities/year or 100-1000 events/year
      (!is.na(fatalities_avg_3yr) & fatalities_avg_3yr > 1000) |
      (!is.na(violence_events_avg_3yr) & violence_events_avg_3yr > 100) ~ 75,
      
      # Moderate intensity: 100-1,000 fatalities/year or 10-100 events/year
      (!is.na(fatalities_avg_3yr) & fatalities_avg_3yr > 100) |
      (!is.na(violence_events_avg_3yr) & violence_events_avg_3yr > 10) ~ 50,
      
      # Low intensity: 10-100 fatalities/year or 1-10 events/year
      (!is.na(fatalities_avg_3yr) & fatalities_avg_3yr > 10) |
      (!is.na(violence_events_avg_3yr) & violence_events_avg_3yr > 1) ~ 25,
      
      # Minimal/no conflict
      TRUE ~ 0
    ),
    
    # Civilian targeting severity (0-100)
    civilian_targeting_score = case_when(
      !is.na(civilian_deaths_avg_3yr) & civilian_deaths_avg_3yr > 1000 ~ 100,
      !is.na(civilian_deaths_avg_3yr) & civilian_deaths_avg_3yr > 100 ~ 75,
      !is.na(civilian_deaths_avg_3yr) & civilian_deaths_avg_3yr > 10 ~ 50,
      !is.na(civilian_deaths_avg_3yr) & civilian_deaths_avg_3yr > 1 ~ 25,
      !is.na(civilian_events_avg_3yr) & civilian_events_avg_3yr > 100 ~ 50,
      !is.na(civilian_events_avg_3yr) & civilian_events_avg_3yr > 10 ~ 25,
      TRUE ~ 0
    ),
    
    # Overall conflict score (average of intensity and civilian targeting)
    conflict_score = round((conflict_intensity_score + civilian_targeting_score) / 2, 1),
    
    # Latest assessment year
    acled_latest_year = pmax(
      if(!is.null(fatalities)) fatalities$latest_year[match(country, fatalities$country)] else NA,
      if(!is.null(civilian_events)) civilian_events$latest_year[match(country, civilian_events$country)] else NA,
      if(!is.null(violence)) violence$latest_year[match(country, violence$country)] else NA,
      if(!is.null(civilian_deaths)) civilian_deaths$latest_year[match(country, civilian_deaths$country)] else NA,
      na.rm = TRUE
    )
  ) %>%
  # Remove rows with no conflict data
  filter(has_active_conflict | !is.na(fatalities_latest) | !is.na(violence_events_latest))

cat("   ✅ Combined data for", nrow(acled_data), "countries\n\n")

# Save processed data
output_file <- "data/processed/acled_conflict_data.csv"
write_csv(acled_data, output_file)
cat("💾 Saved processed ACLED data to:", output_file, "\n\n")

# Summary statistics
cat("📊 ACLED Data Summary:\n")
cat("=====================\n")
cat("Total countries with conflict data:", nrow(acled_data), "\n")
cat("Countries with active conflict:", sum(acled_data$has_active_conflict, na.rm = TRUE), "\n")
cat("Countries with high conflict intensity (score >= 75):", 
    sum(acled_data$conflict_score >= 75, na.rm = TRUE), "\n")
cat("Countries with moderate conflict intensity (score 25-74):", 
    sum(acled_data$conflict_score >= 25 & acled_data$conflict_score < 75, na.rm = TRUE), "\n")
cat("\n")

# Top 10 countries by conflict score
cat("Top 10 countries by conflict score:\n")
top_conflict <- acled_data %>%
  arrange(desc(conflict_score)) %>%
  head(10) %>%
  select(country, conflict_score, fatalities_avg_3yr, violence_events_avg_3yr, civilian_deaths_avg_3yr)
print(top_conflict)

cat("\n✅ ACLED data processing complete!\n")
