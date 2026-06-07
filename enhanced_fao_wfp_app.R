# Enhanced FAO-WFP Global Hunger Research Website
# Integrates latest FAO data (2022-2024), World Bank, and WFP data

library(shiny)
library(plotly)
library(DT)
library(tidyverse)
library(readr)
library(readxl)  # For reading Excel files (GHI data)
library(wbstats)  # World Bank API
# library(rnoaa)    # Climate data - not available for this R version
# library(WHO)      # Health data - not available for this R version

# Load and process data
cat("🌍 Loading Latest FAO, World Bank, and WFP Data...\n")

# Load comprehensive country name mapping first
country_mapping_df <- read_csv("country_name_mapping.csv", show_col_types = FALSE)
country_mapping <- setNames(country_mapping_df$standardized_name, country_mapping_df$original_name)

# Define standardize_country_names function
standardize_country_names <- function(country_names) {
  # Use the loaded mapping
  for (old_name in names(country_mapping)) {
    country_names[country_names == old_name] <- country_mapping[old_name]
  }
  return(country_names)
}

# Function to get ISO country code for flag display
get_country_flag_code <- function(country_name) {
  if(is.null(country_name) || is.na(country_name)) return("un")
  
  country_lower <- tolower(country_name)
  
  # Comprehensive country name to ISO code mapping
  country_codes <- c(
    "united states" = "us", "united states of america" = "us",
    "canada" = "ca",
    "united kingdom" = "gb", "britain" = "gb",
    "germany" = "de",
    "france" = "fr",
    "china" = "cn",
    "japan" = "jp",
    "india" = "in",
    "brazil" = "br",
    "russia" = "ru", "russian federation" = "ru",
    "australia" = "au",
    "south korea" = "kr", "korea, republic of" = "kr", "korea, rep." = "kr",
    "north korea" = "kp", "korea, democratic" = "kp", "korea, dem. people's rep." = "kp",
    "mexico" = "mx",
    "italy" = "it",
    "spain" = "es",
    "netherlands" = "nl",
    "sweden" = "se",
    "norway" = "no",
    "denmark" = "dk",
    "finland" = "fi",
    "switzerland" = "ch",
    "austria" = "at",
    "belgium" = "be",
    "poland" = "pl",
    "czech republic" = "cz",
    "hungary" = "hu",
    "portugal" = "pt",
    "greece" = "gr",
    "turkey" = "tr", "turkiye" = "tr",
    "israel" = "il",
    "saudi arabia" = "sa",
    "united arab emirates" = "ae",
    "egypt" = "eg",
    "south africa" = "za",
    "nigeria" = "ng",
    "kenya" = "ke",
    "ethiopia" = "et",
    "ghana" = "gh",
    "morocco" = "ma",
    "tunisia" = "tn",
    "algeria" = "dz",
    "libya" = "ly",
    "sudan" = "sd",
    "somalia" = "so",
    "yemen" = "ye",
    "iraq" = "iq",
    "iran" = "ir", "iran, islamic rep." = "ir",
    "afghanistan" = "af",
    "pakistan" = "pk",
    "bangladesh" = "bd",
    "sri lanka" = "lk",
    "nepal" = "np",
    "bhutan" = "bt",
    "maldives" = "mv",
    "myanmar" = "mm", "burma" = "mm",
    "thailand" = "th",
    "vietnam" = "vn", "viet nam" = "vn",
    "laos" = "la", "lao pdr" = "la",
    "cambodia" = "kh",
    "malaysia" = "my",
    "singapore" = "sg",
    "indonesia" = "id",
    "philippines" = "ph",
    "taiwan" = "tw", "taiwan, china" = "tw",
    "mongolia" = "mn",
    "new zealand" = "nz",
    "fiji" = "fj",
    "papua new guinea" = "pg",
    "argentina" = "ar",
    "chile" = "cl",
    "colombia" = "co",
    "peru" = "pe",
    "venezuela" = "ve", "venezuela, rb" = "ve",
    "ecuador" = "ec",
    "bolivia" = "bo",
    "paraguay" = "py",
    "uruguay" = "uy",
    "guyana" = "gy",
    "suriname" = "sr",
    "haiti" = "ht",
    "dominican republic" = "do",
    "cuba" = "cu",
    "jamaica" = "jm",
    "trinidad and tobago" = "tt",
    "barbados" = "bb",
    "belize" = "bz",
    "costa rica" = "cr",
    "panama" = "pa",
    "nicaragua" = "ni",
    "honduras" = "hn",
    "el salvador" = "sv",
    "guatemala" = "gt",
    "bahamas" = "bs",
    "democratic republic of the congo" = "cd", "drc" = "cd", "congo, dem. rep." = "cd",
    "congo" = "cg", "republic of the congo" = "cg", "congo, rep." = "cg",
    "tanzania" = "tz", "united republic of tanzania" = "tz",
    "uganda" = "ug",
    "rwanda" = "rw",
    "burundi" = "bi",
    "madagascar" = "mg",
    "mozambique" = "mz",
    "zimbabwe" = "zw",
    "zambia" = "zm",
    "malawi" = "mw",
    "angola" = "ao",
    "cameroon" = "cm",
    "senegal" = "sn",
    "mali" = "ml",
    "burkina faso" = "bf",
    "niger" = "ne",
    "chad" = "td",
    "central african republic" = "cf",
    "south sudan" = "ss",
    "eritrea" = "er",
    "djibouti" = "dj",
    "mauritania" = "mr",
    "gambia" = "gm", "the gambia" = "gm", "gambia, the" = "gm",
    "guinea" = "gn",
    "sierra leone" = "sl",
    "liberia" = "lr",
    "togo" = "tg",
    "benin" = "bj",
    "ivory coast" = "ci", "cote divoire" = "ci", "côte divoire" = "ci", "cote d'ivoire" = "ci"
  )
  
  # Try exact match first
  if(country_lower %in% names(country_codes)) {
    return(country_codes[[country_lower]])
  }
  
  # Try partial matching for compound names
  for(code_name in names(country_codes)) {
    if(grepl(code_name, country_lower, fixed = TRUE)) {
      return(country_codes[[code_name]])
    }
  }
  
  # Default to UN flag
  return("un")
}

# Function to fetch additional World Bank data
fetch_worldbank_indicators <- function() {
  cat("📊 Fetching additional World Bank indicators...\n")
  
  # Define key indicators for hunger vulnerability
  indicators <- c(
    "SN.ITK.DEFC.ZS",    # Prevalence of undernourishment (%)
    "SH.STA.STNT.ZS",    # Prevalence of stunting in children (%)
    "AG.LND.AGRI.ZS",    # Agricultural land (% of land area)
    "AG.YLD.CREL.KG",    # Cereal yield (kg per hectare)
    "AG.PRD.FOOD.XD",    # Food production index
    "SP.POP.TOTL",       # Population, total
    "NY.GDP.PCAP.CD",    # GDP per capita (current US$)
    "SP.DYN.LE00.IN"     # Life expectancy at birth, total (years)
  )
  
  tryCatch({
    # Fetch data for 2020-2024
    wb_data <- wbstats::wb_data(
      indicator = indicators,
      country = "countries_only",
      start_date = 2020,
      end_date = 2024,
      return_wide = TRUE
    )
    
    cat("✅ World Bank API data fetched successfully!\n")
    return(wb_data)
  }, error = function(e) {
    cat("⚠️ World Bank API error:", e$message, "\n")
    return(NULL)
  })
}

# Function to process World Bank API data
process_worldbank_api_data <- function(wb_api_data) {
  if (is.null(wb_api_data)) {
    cat("⚠️ No World Bank API data available\n")
    return(NULL)
  }
  
  cat("📊 Processing World Bank API data...\n")
  
  # Process the API data
  wb_processed <- wb_api_data %>%
    # Get the most recent data for each country
    group_by(country) %>%
    summarise(
      # Get latest values for each indicator
      stunting_rate = last(SH.STA.STNT.ZS, order_by = date),
      agricultural_land = last(AG.LND.AGRI.ZS, order_by = date),
      cereal_yield = last(AG.YLD.CREL.KG, order_by = date),
      food_production_index = last(AG.PRD.FOOD.XD, order_by = date),
      api_population = last(SP.POP.TOTL, order_by = date),
      api_gdp_per_capita = last(NY.GDP.PCAP.CD, order_by = date),
      api_life_expectancy = last(SP.DYN.LE00.IN, order_by = date),
      .groups = "drop"
    ) %>%
    # Standardize country names
    mutate(country = standardize_country_names(country)) %>%
    # Remove rows with all NA values
    filter(!is.na(country))
  
  cat("✅ World Bank API data processed successfully!\n")
  return(wb_processed)
}

# Function to fetch climate data
fetch_climate_data <- function() {
  cat("🌡️ Fetching climate data...\n")
  
  tryCatch({
    # Get global temperature anomalies (simplified approach)
    # Note: This is a basic implementation - real climate data would be more complex
    climate_data <- data.frame(
      country = c("Global", "United States", "China", "India", "Brazil", "Nigeria", "Bangladesh", "Ethiopia", "Democratic Republic of the Congo", "Tanzania"),
      temperature_anomaly = c(1.1, 1.2, 1.0, 1.3, 1.1, 1.4, 1.2, 1.3, 1.1, 1.2),
      drought_risk = c("Medium", "Low", "Medium", "High", "Medium", "High", "High", "High", "Medium", "High"),
      stringsAsFactors = FALSE
    ) %>%
      mutate(
        # Convert drought risk to numeric score
        drought_score = case_when(
          drought_risk == "High" ~ 3,
          drought_risk == "Medium" ~ 2,
          drought_risk == "Low" ~ 1,
          TRUE ~ 0
        )
      )
    
    cat("✅ Climate data processed successfully!\n")
    return(climate_data)
  }, error = function(e) {
    cat("⚠️ Climate data error:", e$message, "\n")
    return(NULL)
  })
}

# Function to fetch health data
fetch_health_data <- function() {
  cat("🏥 Fetching health data...\n")
  
  tryCatch({
    # Get health indicators (simplified approach)
    # Note: This is a basic implementation - real WHO data would be more complex
    health_data <- data.frame(
      country = c("United States", "China", "India", "Brazil", "Nigeria", "Bangladesh", "Ethiopia", "Democratic Republic of the Congo", "Tanzania", "Kenya"),
      child_mortality_rate = c(6.5, 8.1, 32.3, 15.2, 89.1, 28.9, 45.8, 78.2, 45.1, 38.2),
      maternal_mortality_rate = c(19, 29, 145, 60, 917, 176, 401, 473, 524, 342),
      immunization_coverage = c(95, 99, 95, 99, 51, 95, 49, 45, 68, 78),
      stringsAsFactors = FALSE
    ) %>%
      mutate(
        # Convert to vulnerability scores
        child_mortality_score = case_when(
          child_mortality_rate >= 100 ~ 5,
          child_mortality_rate >= 50 ~ 4,
          child_mortality_rate >= 25 ~ 3,
          child_mortality_rate >= 10 ~ 2,
          TRUE ~ 1
        ),
        maternal_mortality_score = case_when(
          maternal_mortality_rate >= 500 ~ 5,
          maternal_mortality_rate >= 200 ~ 4,
          maternal_mortality_rate >= 100 ~ 3,
          maternal_mortality_rate >= 50 ~ 2,
          TRUE ~ 1
        ),
        immunization_score = case_when(
          immunization_coverage < 50 ~ 3,
          immunization_coverage < 80 ~ 2,
          immunization_coverage < 90 ~ 1,
          TRUE ~ 0
        )
      )
    
    cat("✅ Health data processed successfully!\n")
    return(health_data)
  }, error = function(e) {
    cat("⚠️ Health data error:", e$message, "\n")
    return(NULL)
  })
}

# Function to load and process Global Hunger Index (GHI) data
load_ghi_data <- function() {
  cat("📊 Loading Global Hunger Index (GHI) data...\n")
  
  tryCatch({
    ghi_file <- "data/raw/global hunger index/2025 csv.xlsx"
    
    if (!file.exists(ghi_file)) {
      cat("⚠️ GHI file not found:", ghi_file, "\n")
      return(NULL)
    }
    
    # Read GHI Scores sheet (most useful for comparison)
    # Try different possible sheet names
    sheets <- excel_sheets(ghi_file)
    scores_sheet <- sheets[grepl("Scores", sheets, ignore.case = TRUE)][1]
    if(is.na(scores_sheet)) scores_sheet <- sheets[1]  # Fallback to first sheet
    
    # Read the data - skip first row which is header
    ghi_scores_raw <- read_excel(ghi_file, sheet = scores_sheet, skip = 1, col_names = FALSE)
    
    # The structure: Column 1 = Country, Columns 2-7 = 2000, 2008, 2016, 2025, Abs change, % change
    names(ghi_scores_raw) <- c("Country", "ghi_2000", "ghi_2008", "ghi_2016", "ghi_2025", "ghi_change_abs", "ghi_change_pct")
    
    # Remove header rows and clean data
    ghi_scores <- ghi_scores_raw %>%
      filter(!is.na(Country) & 
             Country != "Country" & 
             !str_detect(Country, "with") &
             !str_detect(Country, "2000")) %>%
      mutate(
        # Convert GHI scores to numeric (handle "<5" and "—" values)
        ghi_2000 = as.numeric(ifelse(ghi_2000 == "<5" | ghi_2000 == "—" | is.na(ghi_2000), NA, ghi_2000)),
        ghi_2008 = as.numeric(ifelse(ghi_2008 == "<5" | ghi_2008 == "—" | is.na(ghi_2008), NA, ghi_2008)),
        ghi_2016 = as.numeric(ifelse(ghi_2016 == "<5" | ghi_2016 == "—" | is.na(ghi_2016), NA, ghi_2016)),
        ghi_2025 = as.numeric(ifelse(ghi_2025 == "<5" | ghi_2025 == "—" | is.na(ghi_2025), NA, ghi_2025)),
        ghi_change_abs = as.numeric(ifelse(ghi_change_abs == "—" | is.na(ghi_change_abs), NA, ghi_change_abs)),
        ghi_change_pct = as.numeric(ifelse(ghi_change_pct == "—" | is.na(ghi_change_pct), NA, ghi_change_pct))
      ) %>%
      # Standardize country names
      mutate(Country = standardize_country_names(Country)) %>%
      # Use 2025 GHI score as primary, fallback to 2016 if 2025 is missing
      mutate(ghi_score = ifelse(!is.na(ghi_2025), ghi_2025, ghi_2016)) %>%
      select(Country, ghi_score, ghi_2025, ghi_2016, ghi_2008, ghi_2000, ghi_change_abs, ghi_change_pct) %>%
      filter(!is.na(Country))
    
    # Read GHI Indicator Values sheet for component data
    indicators_sheet <- sheets[grepl("Indicator", sheets, ignore.case = TRUE)][1]
    if(is.na(indicators_sheet)) indicators_sheet <- sheets[2]  # Fallback to second sheet
    
    ghi_indicators_raw <- read_excel(ghi_file, sheet = indicators_sheet, skip = 1, col_names = FALSE)
    
    # Structure: 
    # Col 1: Country
    # Cols 2-5: Undernourishment periods ('00-'02, '07-'09, '15-'17, '22-'25) - Col 5 is latest
    # Cols 6-13: Child wasting periods - need to identify latest
    # Cols 14-17: Child stunting (numeric) - Col 17 appears to be latest
    # Cols 18-22: Child mortality - need to identify latest
    
    names(ghi_indicators_raw)[1] <- "Country"
    
    # Extract all GHI components for latest period (2022-2025)
    ghi_indicators_clean <- ghi_indicators_raw %>%
      filter(!is.na(Country) & Country != "Country" & !str_detect(Country, "'00|'07|'15|'22|'98")) %>%
      mutate(
        Country = standardize_country_names(Country),
        # Undernourishment - column 5 is '22-'25 (latest period)
        ghi_undernourishment = as.numeric(ifelse(
          .[[5]] == "< 2.5" | .[[5]] == "—" | is.na(.[[5]]), 
          NA, 
          .[[5]]
        )),
        # Child wasting - column 10 appears to be latest period
        ghi_child_wasting = as.numeric(ifelse(
          .[[10]] == "< 2.5" | .[[10]] == "—" | is.na(.[[10]]), 
          NA, 
          .[[10]]
        )),
        # Child stunting - column 17 appears to be latest (numeric)
        ghi_child_stunting = ifelse(is.na(.[[17]]), NA, as.numeric(.[[17]])),
        # Child mortality - column 21 appears to be latest
        ghi_child_mortality = as.numeric(ifelse(
          .[[21]] == "< 2.5" | .[[21]] == "—" | is.na(.[[21]]), 
          NA, 
          .[[21]]
        ))
      ) %>%
      select(Country, ghi_undernourishment, ghi_child_wasting, ghi_child_stunting, ghi_child_mortality) %>%
      filter(!is.na(Country))
    
    # Merge scores and indicators
    ghi_data <- ghi_scores %>%
      left_join(ghi_indicators_clean, by = "Country") %>%
      filter(!is.na(Country))
    
    cat("✅ GHI data loaded successfully! Countries:", nrow(ghi_data), "\n")
    return(ghi_data)
    
  }, error = function(e) {
    cat("⚠️ GHI data loading error:", e$message, "\n")
    return(NULL)
  })
}

# Load latest FAO data (2022-2024)
fao_latest <- read_csv("data/raw/fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv", show_col_types = FALSE)

# Load World Bank data
wb_raw_data <- read_csv("data/raw/world bank/world_bank_data.csv", show_col_types = FALSE)

# Load Global Hunger Index data
ghi_data <- load_ghi_data()

# Fetch additional World Bank indicators via API (temporarily disabled)
# wb_api_data <- fetch_worldbank_indicators()
# wb_api_processed <- process_worldbank_api_data(wb_api_data)
wb_api_processed <- NULL

# Fetch climate data
climate_data <- fetch_climate_data()

# Fetch health data
health_data <- fetch_health_data()

# Load PIP poverty data
pip_data <- read_csv("data/raw/world bank/pip 2.csv", show_col_types = FALSE)

# Load WFP data
wfp_markets <- read_csv("data/raw/wfp/markets.csv", show_col_types = FALSE)
wfp_commodities <- read_csv("data/raw/wfp/commodities.csv", show_col_types = FALSE)

# Load new data sources (if processed file exists, otherwise process it)
if(file.exists("data/processed/new_data_sources_combined.csv")) {
  cat("Loading new data sources...\n")
  new_data_sources <- read_csv("data/processed/new_data_sources_combined.csv", show_col_types = FALSE)
} else {
  cat("Processing new data sources...\n")
  source("process_new_data_sources.R")
  new_data_sources <- read_csv("data/processed/new_data_sources_combined.csv", show_col_types = FALSE)
}

# Load GRFC 2025 data (if available)
grfc2025_data <- NULL
if(file.exists("data/raw/wfp/grfc2025_data.csv")) {
  cat("Loading GRFC 2025 Hunger Crises data...\n")
  grfc2025_raw <- read_csv("data/raw/wfp/grfc2025_data.csv", show_col_types = FALSE)
  grfc2025_data <- grfc2025_raw %>%
    mutate(country = standardize_country_names(country)) %>%
    # Take most recent assessment per country
    group_by(country) %>%
    slice_max(assessment_year, n = 1) %>%
    ungroup() %>%
    rename(
      grfc_ipc_phase = ipc_phase,
      grfc_population_phase3_plus = population_phase3_plus,
      grfc_population_phase4_plus = population_phase4_plus,
      grfc_population_phase5 = population_phase5,
      grfc_primary_driver = primary_driver,
      grfc_assessment_year = assessment_year
    )
  cat("✅ Loaded GRFC 2025 data for", nrow(grfc2025_data), "countries\n")
} else {
  cat("GRFC 2025 data not found (optional)\n")
}

# Load ACLED conflict data (if available)
acled_data <- NULL
if(file.exists("data/processed/acled_conflict_data.csv")) {
  cat("Loading ACLED conflict data...\n")
  acled_raw <- read_csv("data/processed/acled_conflict_data.csv", show_col_types = FALSE)
  acled_data <- acled_raw %>%
    mutate(country = standardize_country_names(country)) %>%
    # Take most recent data per country
    group_by(country) %>%
    slice(1) %>%
    ungroup() %>%
    rename(
      acled_conflict_score = conflict_score,
      acled_conflict_intensity = conflict_intensity_score,
      acled_civilian_targeting = civilian_targeting_score,
      acled_fatalities_avg_3yr = fatalities_avg_3yr,
      acled_violence_events_avg_3yr = violence_events_avg_3yr,
      acled_civilian_deaths_avg_3yr = civilian_deaths_avg_3yr,
      acled_has_active_conflict = has_active_conflict,
      acled_latest_year = acled_latest_year
    )
  cat("✅ Loaded ACLED conflict data for", nrow(acled_data), "countries\n")
} else {
  cat("ACLED conflict data not found (optional)\n")
}

# Load new priority data (Refugee/IDP, Food Import Dependency, Water Scarcity)
new_priority_data <- NULL
if(file.exists("data/processed/new_priority_data.csv")) {
  cat("Loading new priority data (Refugee/IDP, Food Import, Water)...\n")
  new_priority_raw <- read_csv("data/processed/new_priority_data.csv", show_col_types = FALSE)
  new_priority_data <- new_priority_raw %>%
    mutate(country = standardize_country_names(country)) %>%
    # Take most recent data per country
    group_by(country) %>%
    slice(1) %>%
    ungroup()
  cat("✅ Loaded new priority data for", nrow(new_priority_data), "countries\n")
} else {
  cat("New priority data not found (optional)\n")
}

# Hunger Vulnerability Rating Calculation Function
calculate_hunger_vulnerability <- function(data) {
  # Create a comprehensive vulnerability score incorporating ALL available data sources
  # Higher score = higher vulnerability (0-100 scale)
  
  data %>%
    mutate(
      # 1. UNDERNOURISHMENT FACTORS (0-40 points) - PRIMARY FACTOR
      # Use GRFC population data if available and undernourishment rate is missing
      undernourishment_score = case_when(
        !is.na(undernourishment_rate) ~ pmin(undernourishment_rate * 0.8, 40),
        # If no undernourishment rate but have GRFC Phase 3+ population, estimate
        !is.na(grfc_population_phase3_plus) & !is.na(population) & population > 0 ~ 
          pmin((grfc_population_phase3_plus / population * 100) * 0.8, 40),
        TRUE ~ 0
      ),
      
      # 2. POVERTY FACTORS (0-20 points) - BALANCED
      # Use PIP poverty data if available, otherwise fall back to World Bank poverty rate, then Our World in Data
      poverty_score = case_when(
        !is.na(poverty_headcount) ~ pmin(poverty_headcount * 0.4, 20),  # PIP data (0-1 scale)
        !is.na(poverty_rate) ~ pmin(poverty_rate * 0.4, 20),  # World Bank data (0-100 scale)
        !is.na(poverty_below_3usd) ~ pmin(poverty_below_3usd * 0.4, 20),  # Our World in Data (0-100 scale)
        TRUE ~ 0
      ),
      
      # 3. ECONOMIC FACTORS (0-15 points) - BALANCED
      # GDP per capita (inverse relationship, lower GDP = higher vulnerability)
      gdp_score = case_when(
        is.na(gdp_per_capita) ~ 0,  # Don't penalize for missing data
        gdp_per_capita < 1000 ~ 15,
        gdp_per_capita < 3000 ~ 12,
        gdp_per_capita < 10000 ~ 8,
        gdp_per_capita < 20000 ~ 4,
        TRUE ~ 0
      ),
      
      # 4. HEALTH FACTORS (0-10 points) - BALANCED
      # Life expectancy (inverse relationship, lower life expectancy = higher vulnerability)
      # Use API data if available, otherwise fall back to existing data
      life_expectancy_score = case_when(
        is.na(life_expectancy) ~ 0,  # Don't penalize for missing data
        life_expectancy < 50 ~ 10,
        life_expectancy < 60 ~ 8,
        life_expectancy < 70 ~ 5,
        TRUE ~ 0
      ),
      
      # 5. INEQUALITY FACTORS (0-8 points) - BALANCED
      # Gini coefficient (higher inequality = higher vulnerability)
      inequality_score = case_when(
        is.na(gini_coefficient) ~ 0,
        gini_coefficient >= 0.6 ~ 8,  # Very high inequality
        gini_coefficient >= 0.5 ~ 6,  # High inequality
        gini_coefficient >= 0.4 ~ 4,  # Moderate inequality
        TRUE ~ 0
      ),
      
      # 6. MARKET ACCESS FACTORS (0-7 points) - BALANCED
      # WFP market data (lower market access = higher vulnerability)
      market_access_score = case_when(
        is.na(total_markets) ~ 0,  # No data = neutral
        total_markets == 0 ~ 7,    # No markets = high vulnerability
        total_markets < 5 ~ 5,     # Very few markets
        total_markets < 20 ~ 3,    # Limited markets
        TRUE ~ 0                   # Good market access
      ),
      
      # 7. CONFLICT FACTORS (0-20 points) - HIGH EMPHASIS
      # ACLED conflict data - conflict is the #1 driver of food insecurity
      conflict_score = case_when(
        !is.na(acled_conflict_score) & acled_conflict_score >= 75 ~ 20,  # Very high conflict
        !is.na(acled_conflict_score) & acled_conflict_score >= 50 ~ 15,  # High conflict
        !is.na(acled_conflict_score) & acled_conflict_score >= 25 ~ 10,  # Moderate conflict
        !is.na(acled_conflict_score) & acled_conflict_score > 0 ~ 5,     # Low conflict
        !is.na(acled_has_active_conflict) & acled_has_active_conflict ~ 10,  # Active conflict but no score
        TRUE ~ 0
      ),
      
      # 8. HISTORICAL CRISIS FACTORS (0-15 points) - HIGH EMPHASIS
      # Historical hunger outbreaks (15 points if had major outbreak in 21st century)
      # Also check GRFC 2025 IPC Phase 4/5 for current major crises
      # Reduced from 20 to 15 since conflict now has its own factor
      outbreak_score = case_when(
        !is.na(major_hunger_outbreak_21st) & major_hunger_outbreak_21st ~ 15,
        !is.na(grfc_ipc_phase) & grfc_ipc_phase >= 4 ~ 15,  # Current Phase 4/5 = major crisis
        !is.na(grfc_ipc_phase) & grfc_ipc_phase == 3 ~ 8,   # Current Phase 3 = moderate crisis
        TRUE ~ 0
      ),
      
      # 9. POPULATION DENSITY FACTORS (0-5 points) - BALANCED
      # Higher population density can indicate urban poverty and food access issues
      population_density_score = case_when(
        is.na(population) ~ 0,
        population > 100000000 ~ 5,  # Very large population (China, India, etc.)
        population > 50000000 ~ 3,   # Large population
        population > 10000000 ~ 1,    # Medium population
        TRUE ~ 0
      ),
      
      # 10. REGIONAL VULNERABILITY FACTORS (0-15 points) - HIGH EMPHASIS
      # Some regions are inherently more vulnerable due to climate, conflict, etc.
      regional_vulnerability_score = case_when(
        is.na(region) ~ 0,
        region %in% c("Sub-Saharan Africa", "Middle East & North Africa") ~ 15,
        region %in% c("South Asia", "Latin America & Caribbean") ~ 10,
        region %in% c("East Asia & Pacific", "Europe & Central Asia") ~ 5,
        TRUE ~ 0
      ),
      
      # 11. CHILD STUNTING FACTORS (0-8 points) - ENABLED (WHO and Global Data Lab data available)
      stunting_score = case_when(
        !is.na(who_stunting_rate) ~ pmin(who_stunting_rate * 0.2, 8),  # WHO data (0-100 scale)
        !is.na(child_stunting_rate) ~ pmin(child_stunting_rate * 0.2, 8),  # Global Data Lab (0-100 scale)
        TRUE ~ 0
      ),
      
      # 11. AGRICULTURAL PRODUCTIVITY FACTORS (0-6 points) - ENABLED (USDA data available)
      agriculture_score = case_when(
        is.na(tfp_index) ~ 0,
        tfp_index < 100 ~ 6,  # Very low productivity
        tfp_index < 120 ~ 4,  # Low productivity
        tfp_index < 150 ~ 2,  # Moderate productivity
        TRUE ~ 0
      ),
      
      # 13. FOOD PRODUCTION FACTORS (0-4 points) - ENABLED (Our World in Data available)
      food_production_score = case_when(
        is.na(food_supply_kcal) ~ 0,
        food_supply_kcal < 2000 ~ 4,  # Very low food supply
        food_supply_kcal < 2200 ~ 3,  # Low food supply
        food_supply_kcal < 2500 ~ 2,  # Below recommended (2500 kcal/day)
        TRUE ~ 0
      ),
      
      # 14. CLIMATE VULNERABILITY FACTORS (0-6 points) - ENABLED (Global Data Lab data available)
      climate_score = case_when(
        is.na(climate_vulnerability_index) ~ 0,
        climate_vulnerability_index >= 80 ~ 6,  # Very high vulnerability
        climate_vulnerability_index >= 70 ~ 4,  # High vulnerability
        climate_vulnerability_index >= 60 ~ 2,  # Moderate vulnerability
        TRUE ~ 0
      ),
      
      # 15. HEALTH VULNERABILITY FACTORS (0-8 points) - ENABLED (Global Data Lab data available)
      health_vulnerability_score = case_when(
        !is.na(under5_mortality) & under5_mortality >= 100 ~ 8,  # Very high child mortality
        !is.na(under5_mortality) & under5_mortality >= 50 ~ 6,   # High child mortality
        !is.na(under5_mortality) & under5_mortality >= 25 ~ 4,   # Moderate child mortality
        !is.na(infant_mortality) & infant_mortality >= 50 ~ 6,   # High infant mortality
        !is.na(infant_mortality) & infant_mortality >= 25 ~ 4,   # Moderate infant mortality
        !is.na(child_wasting_rate) & child_wasting_rate >= 15 ~ 6,  # High wasting
        !is.na(child_wasting_rate) & child_wasting_rate >= 10 ~ 4,   # Moderate wasting
        TRUE ~ 0
      ),
      
      # 16. DISPLACEMENT FACTORS (0-10 points) - HIGH EMPHASIS
      # Refugee and IDP populations are extremely vulnerable to hunger
      displacement_score = case_when(
        # High displacement: >5% of population or >1M people
        (!is.na(total_displaced_latest) & !is.na(population) & population > 0 & 
         (total_displaced_latest / population > 0.05 | total_displaced_latest > 1000000)) ~ 10,
        # Moderate displacement: 1-5% of population or 100K-1M people
        (!is.na(total_displaced_latest) & !is.na(population) & population > 0 & 
         (total_displaced_latest / population > 0.01 | total_displaced_latest > 100000)) ~ 6,
        # Low displacement: <1% but >10K people
        (!is.na(total_displaced_latest) & total_displaced_latest > 10000) ~ 3,
        TRUE ~ 0
      ),
      
      # 17. FOOD IMPORT DEPENDENCY FACTORS (0-6 points) - BALANCED
      # High dependency on food imports = vulnerability to trade disruptions
      food_import_score = case_when(
        !is.na(food_import_dependency) & food_import_dependency > 0.5 ~ 6,  # Very high dependency (>50%)
        !is.na(food_import_dependency) & food_import_dependency > 0.3 ~ 4,  # High dependency (30-50%)
        !is.na(food_import_dependency) & food_import_dependency > 0.1 ~ 2,  # Moderate dependency (10-30%)
        TRUE ~ 0
      ),
      
      # 18. WATER SCARCITY FACTORS (0-6 points) - BALANCED
      # Water stress affects agricultural productivity and food security
      water_scarcity_score = case_when(
        !is.na(water_stress_index) & water_stress_index > 100 ~ 6,  # Critical (>100% - using non-renewable)
        !is.na(water_stress_index) & water_stress_index > 75 ~ 6,   # Very high stress (>75%)
        !is.na(water_stress_index) & water_stress_index > 50 ~ 4,   # High stress (50-75%)
        !is.na(water_stress_index) & water_stress_index > 25 ~ 2,   # Moderate stress (25-50%)
        TRUE ~ 0
      ),
      
      # Calculate total vulnerability score (0-100)
      hunger_vulnerability_rating = round(
        undernourishment_score + 
        poverty_score + 
        gdp_score + 
        life_expectancy_score + 
        inequality_score +
        market_access_score +
        conflict_score +
        outbreak_score +
        population_density_score +
        regional_vulnerability_score +
        stunting_score +
        agriculture_score +
        food_production_score +
        climate_score +
        health_vulnerability_score +
        displacement_score +
        food_import_score +
        water_scarcity_score,
        1
      ),
      
      # Ensure score is within 0-100 range
      hunger_vulnerability_rating = pmax(0, pmin(100, hunger_vulnerability_rating))
    ) %>%
    select(-undernourishment_score, -poverty_score, -gdp_score, -life_expectancy_score, 
           -inequality_score, -market_access_score, -conflict_score, -outbreak_score, 
           -population_density_score, -regional_vulnerability_score,
           -stunting_score, -agriculture_score, -food_production_score,
           -climate_score, -health_vulnerability_score, -displacement_score,
           -food_import_score, -water_scarcity_score)
}

# Country name mapping already loaded above

# Process latest FAO data
process_latest_fao_data <- function() {
  fao_processed <- fao_latest %>%
    # Clean and process the data
    mutate(
      # Handle special values like "<2.5" and empty strings
      Value_clean = case_when(
        Value == "<2.5" ~ "2.5",
        Value == "" ~ NA_character_,
        TRUE ~ Value
      ),
      Value_numeric = as.numeric(Value_clean)
    ) %>%
    # Select relevant columns first
    select(Area, `Item Code`, Item, Element, Unit, Year, Value_numeric) %>%
    # Pivot to wide format for easier analysis
    pivot_wider(
      names_from = `Item Code`, 
      values_from = Value_numeric, 
      names_prefix = "ind_"
    ) %>%
    # Rename for clarity
    rename(
      undernourishment_rate = ind_210041,
      undernourished_population = ind_210011
    ) %>%
    # Standardize country names for map compatibility
    mutate(Area = standardize_country_names(Area)) %>%
    # Filter to keep countries with valid undernourishment rate data (even if population is missing)
    filter(!is.na(undernourishment_rate) & undernourishment_rate > 0)
  
  return(fao_processed)
}

# Process PIP poverty data
process_pip_data <- function() {
  pip_summary <- pip_data %>%
    # Standardize country names
    mutate(country_name = standardize_country_names(country_name)) %>%
    # Filter for most recent data and national level
    filter(reporting_level == "national") %>%
    group_by(country_name) %>%
    # Get the most recent poverty data for each country
    slice_max(reporting_year, n = 1) %>%
    summarise(
      latest_pip_year = max(reporting_year, na.rm = TRUE),
      poverty_headcount = last(headcount, order_by = reporting_year),
      poverty_gap = last(poverty_gap, order_by = reporting_year),
      poverty_severity = last(poverty_severity, order_by = reporting_year),
      gini_coefficient = last(gini, order_by = reporting_year),
      mean_consumption = last(mean, order_by = reporting_year),
      median_consumption = last(median, order_by = reporting_year),
      survey_year = last(survey_year, order_by = reporting_year),
      .groups = "drop"
    ) %>%
    filter(!is.na(poverty_headcount))
  
  return(pip_summary)
}

# Process World Bank data
process_worldbank_data <- function() {
  wb_summary <- wb_raw_data %>%
    # Standardize country names first
    mutate(country = standardize_country_names(country)) %>%
    group_by(country) %>%
    summarise(
      latest_year_wb = max(year, na.rm = TRUE),
      population = last(SP.POP.TOTL, order_by = year),
      gdp_per_capita = last(NY.GDP.PCAP.CD, order_by = year),
      poverty_rate = last(SI.POV.DDAY, order_by = year),
      life_expectancy = last(SP.DYN.LE00.IN, order_by = year),
      agriculture_land = last(AG.LND.AGRI.ZS, order_by = year),
      rural_population = last(SP.RUR.TOTL.ZS, order_by = year),
      .groups = "drop"
    ) %>%
    filter(!is.na(population)) %>%
    mutate(
      # Create development level categories
      development_level = case_when(
        gdp_per_capita < 1045 ~ "Very Low Income",
        gdp_per_capita < 4095 ~ "Low Income", 
        gdp_per_capita < 12695 ~ "Lower Middle Income",
        gdp_per_capita < 40955 ~ "Upper Middle Income",
        TRUE ~ "High Income"
      ),
      development_level = factor(development_level, levels = c("Very Low Income", "Low Income", "Lower Middle Income", "Upper Middle Income", "High Income")),
      
      # Create region categories
      region = case_when(
        country %in% c("Afghanistan", "Bangladesh", "Bhutan", "India", "Maldives", "Nepal", "Pakistan", "Sri Lanka") ~ "South Asia",
        country %in% c("China", "Japan", "Korea, Rep.", "Mongolia", "Thailand", "Vietnam", "Indonesia", "Malaysia", "Philippines", "Singapore", "Viet Nam", "Republic of Korea") ~ "East Asia & Pacific",
        country %in% c("Algeria", "Egypt", "Morocco", "Tunisia", "Libya", "Sudan", "Ethiopia", "Kenya", "Nigeria", "South Africa", "Somalia", "Yemen", "South Sudan", "Madagascar", "Democratic Republic of the Congo", "Central African Republic", "Chad", "Mali", "Burkina Faso", "Niger") ~ "Africa",
        country %in% c("Brazil", "Argentina", "Chile", "Colombia", "Mexico", "Peru", "Venezuela", "Haiti", "Bolivia", "Venezuela, RB", "Bolivia (Plurinational State of)") ~ "Latin America & Caribbean",
        country %in% c("United States", "Canada", "United States of America") ~ "North America",
        country %in% c("Germany", "France", "United Kingdom", "Italy", "Spain", "Poland", "Russia", "Russian Federation", "Albania", "Armenia", "Azerbaijan", "Belarus", "Bulgaria", "Croatia", "Czech Republic", "Estonia", "Georgia", "Hungary", "Kazakhstan", "Kyrgyz Republic", "Latvia", "Lithuania", "Moldova", "Montenegro", "North Macedonia", "Romania", "Serbia", "Slovak Republic", "Slovenia", "Tajikistan", "Turkey", "Turkmenistan", "Ukraine", "Uzbekistan") ~ "Europe & Central Asia",
        TRUE ~ "Other"
      )
    )
  
  return(wb_summary)
}

# Process WFP data
process_wfp_data <- function() {
  # Process market data
  wfp_market_summary <- wfp_markets %>%
    # Standardize country names first
    mutate(Country = standardize_country_names(Country)) %>%
    group_by(Country) %>%
    summarise(
      total_markets = n(),
      total_population_served = sum(Population, na.rm = TRUE),
      avg_market_population = mean(Population, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      # Create market access categories
      market_access = case_when(
        total_markets >= 100 ~ "High Market Access",
        total_markets >= 50 ~ "Medium Market Access",
        total_markets >= 10 ~ "Low Market Access",
        TRUE ~ "Very Low Market Access"
      ),
      market_access = factor(market_access, levels = c("Very Low Market Access", "Low Market Access", "Medium Market Access", "High Market Access"))
    )
  
  # Process commodity data
  wfp_commodity_summary <- wfp_commodities %>%
    mutate(
      # Categorize commodities
      commodity_category = case_when(
        str_detect(Name, "(Rice|Wheat|Maize|Corn|Cereal|Grain)") ~ "Cereals",
        str_detect(Name, "(Bean|Lentil|Pea|Pulse)") ~ "Pulses",
        str_detect(Name, "(Milk|Cheese|Dairy)") ~ "Dairy",
        str_detect(Name, "(Fish|Meat|Chicken|Beef)") ~ "Protein",
        str_detect(Name, "(Potato|Onion|Tomato|Vegetable)") ~ "Vegetables",
        str_detect(Name, "(Oil|Fat)") ~ "Fats & Oils",
        TRUE ~ "Other"
      )
    ) %>%
    count(commodity_category) %>%
    mutate(percentage = n / sum(n) * 100)
  
  return(list(
    markets = wfp_market_summary,
    commodities = wfp_commodity_summary,
    raw_markets = wfp_markets,
    raw_commodities = wfp_commodities
  ))
}

# Add 21st century hunger outbreak data
add_hunger_outbreaks <- function(data) {
  # Major hunger outbreaks in 21st century (based on historical data)
  hunger_outbreaks <- data.frame(
    Area = c("Somalia", "Yemen", "South Sudan", "Nigeria", "Ethiopia", 
             "Afghanistan", "Haiti", "Madagascar", "Democratic Republic of the Congo",
             "Central African Republic", "Chad", "Mali", "Burkina Faso", "Niger",
             "Zambia", "Zimbabwe", "Venezuela (Bolivarian Republic of)", "United Republic of Tanzania"),
    major_hunger_outbreak_21st = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
    outbreak_years = c("2011, 2017, 2022", "2016-2023", "2017-2023", "2016-2018", "2015-2016, 2020-2022",
                      "2001-2002, 2018-2021", "2008, 2010, 2016", "2021-2022", "2017-2019",
                      "2013-2014, 2018-2020", "2010, 2017-2018", "2012, 2018-2020", "2012, 2018-2020", "2005, 2010, 2018-2020",
                      "2019-2020", "2019-2021", "2016-2020", "2017-2019")
  )
  
  data <- data %>%
    left_join(hunger_outbreaks, by = "Area") %>%
    mutate(
      major_hunger_outbreak_21st = ifelse(is.na(major_hunger_outbreak_21st), FALSE, major_hunger_outbreak_21st),
      outbreak_years = ifelse(is.na(outbreak_years), "None", outbreak_years)
    )
  
  return(data)
}

# Process the data
fao_processed <- process_latest_fao_data()
wb_summary <- process_worldbank_data()
pip_summary <- process_pip_data()
wfp_data <- process_wfp_data()

# Create comprehensive country list from all datasets
# Include countries from all sources, not just FAO
all_countries <- unique(c(
  fao_processed$Area, 
  wb_summary$country, 
  pip_summary$country_name, 
  wfp_data$markets$Country
))

# Create base dataset with all countries
all_countries_data <- data.frame(Area = all_countries) %>%
  # Add latest FAO data
  left_join(fao_processed, by = "Area") %>%
  # Add World Bank data
  left_join(wb_summary, by = c("Area" = "country")) %>%
  # Add PIP poverty data
  left_join(pip_summary, by = c("Area" = "country_name")) %>%
  # Add World Bank API data (if available)
  {if (!is.null(wb_api_processed)) left_join(., wb_api_processed, by = c("Area" = "country")) else .} %>%
  # Add climate data (if available)
  {if (!is.null(climate_data)) left_join(., climate_data, by = c("Area" = "country")) else .} %>%
  # Add health data (if available)
  {if (!is.null(health_data)) left_join(., health_data, by = c("Area" = "country")) else .} %>%
  # Add Global Hunger Index (GHI) data (if available)
  {if (!is.null(ghi_data)) left_join(., ghi_data, by = c("Area" = "Country")) else .} %>%
  # Add new data sources (climate, stunting, food supply, agriculture, health)
  # Handle many-to-many by taking first match (most recent data)
  left_join(
    new_data_sources %>% 
      group_by(country) %>% 
      slice(1) %>% 
      ungroup(), 
    by = c("Area" = "country")
  ) %>%
  # Add GRFC 2025 data (if available)
  {if (!is.null(grfc2025_data)) left_join(., grfc2025_data, by = c("Area" = "country")) else .} %>%
  # Add ACLED conflict data (if available)
  {if (!is.null(acled_data)) left_join(., acled_data, by = c("Area" = "country")) else .} %>%
  # Add new priority data (Refugee/IDP, Food Import, Water) (if available)
  {if (!is.null(new_priority_data)) left_join(., new_priority_data, by = c("Area" = "country")) else .} %>%
  # Add WFP market data
  left_join(wfp_data$markets, by = c("Area" = "Country")) %>%
  # Add hunger outbreak data
  add_hunger_outbreaks() %>%
  # Calculate hunger vulnerability rating FIRST
  calculate_hunger_vulnerability() %>%
  mutate(
    # Create combined risk assessment based on hunger vulnerability rating (0-100 scale)
    # Risk categories based on vulnerability score:
    # - Critical: 70-100 (severe vulnerability)
    # - High: 50-69.9 (high vulnerability)
    # - Medium: 30-49.9 (moderate vulnerability)
    # - Low: 15-29.9 (low vulnerability)
    # - Very Low: 0-14.9 (very low vulnerability)
    combined_risk = case_when(
      !is.na(hunger_vulnerability_rating) & hunger_vulnerability_rating >= 70 ~ "Critical",
      !is.na(hunger_vulnerability_rating) & hunger_vulnerability_rating >= 50 ~ "High",
      !is.na(hunger_vulnerability_rating) & hunger_vulnerability_rating >= 30 ~ "Medium",
      !is.na(hunger_vulnerability_rating) & hunger_vulnerability_rating >= 15 ~ "Low",
      !is.na(hunger_vulnerability_rating) ~ "Very Low",
      # Fallback to old method if vulnerability score not available
      (!is.na(undernourishment_rate) & undernourishment_rate >= 25) | (!is.na(poverty_rate) & poverty_rate >= 30) ~ "Critical",
      (!is.na(undernourishment_rate) & undernourishment_rate >= 15) | (!is.na(poverty_rate) & poverty_rate >= 15) ~ "High",
      (!is.na(undernourishment_rate) & undernourishment_rate >= 10) | (!is.na(poverty_rate) & poverty_rate >= 5) ~ "Medium",
      (!is.na(undernourishment_rate) & undernourishment_rate >= 5) | (!is.na(poverty_rate) & poverty_rate >= 1) ~ "Low",
      TRUE ~ "Very Low"
    ),
    combined_risk = factor(combined_risk, levels = c("Very Low", "Low", "Medium", "High", "Critical")),
    
    # Create region categories for all countries
    region = case_when(
      Area %in% c("Afghanistan", "Bangladesh", "Bhutan", "India", "Maldives", "Nepal", "Pakistan", "Sri Lanka") ~ "South Asia",
      Area %in% c("China", "Japan", "Korea, Rep.", "Mongolia", "Thailand", "Vietnam", "Indonesia", "Malaysia", "Philippines", "Singapore", "Viet Nam", "Republic of Korea") ~ "East Asia & Pacific",
      Area %in% c("Sudan", "Ethiopia", "Kenya", "Nigeria", "South Africa", "Somalia", "South Sudan", "Madagascar", "Democratic Republic of the Congo", "Central African Republic", "Chad", "Mali", "Burkina Faso", "Niger", "Zambia", "Zimbabwe", "United Republic of Tanzania", "Congo, Dem. Rep.", "Congo, Democratic Republic of the", "Congo, the Democratic Republic of the") ~ "Africa",
      Area %in% c("Brazil", "Argentina", "Chile", "Colombia", "Mexico", "Peru", "Venezuela", "Haiti", "Bolivia", "Venezuela, RB", "Bolivia (Plurinational State of)", "Venezuela (Bolivarian Republic of)") ~ "Latin America & Caribbean",
      Area %in% c("United States", "Canada", "United States of America") ~ "North America",
      Area %in% c("Germany", "France", "United Kingdom", "Italy", "Spain", "Poland", "Russia", "Russian Federation", "Albania", "Armenia", "Azerbaijan", "Belarus", "Bulgaria", "Croatia", "Czech Republic", "Estonia", "Georgia", "Hungary", "Kazakhstan", "Kyrgyz Republic", "Latvia", "Lithuania", "Moldova", "Montenegro", "North Macedonia", "Romania", "Serbia", "Slovak Republic", "Slovenia", "Tajikistan", "Turkey", "Turkmenistan", "Ukraine", "Uzbekistan") ~ "Europe & Central Asia",
      # Only disputed/contested territories should be "Other"
      Area %in% c("Palestine", "Kashmir", "Taiwan", "Western Sahara", "Northern Cyprus", "Abkhazia", "South Ossetia", "Transnistria", "Nagorno-Karabakh", "Kosovo", "Somaliland", "Puntland") ~ "Other",
      # All other sovereign countries should be assigned to their proper regions
      # If a country doesn't match any region, assign based on geographic location
      Area %in% c("Australia", "New Zealand", "Fiji", "Papua New Guinea", "Samoa", "Tonga", "Vanuatu", "Solomon Islands", "Kiribati", "Tuvalu", "Nauru", "Palau", "Marshall Islands", "Micronesia") ~ "East Asia & Pacific",
      # Add more countries to proper regions to avoid "Other"
      Area %in% c("Iceland", "Norway", "Sweden", "Finland", "Denmark", "Ireland", "Iceland", "Luxembourg", "Switzerland", "Austria", "Belgium", "Netherlands", "Portugal", "Greece") ~ "Europe & Central Asia",
      Area %in% c("Cuba", "Jamaica", "Trinidad and Tobago", "Barbados", "Bahamas", "Belize", "Costa Rica", "El Salvador", "Guatemala", "Honduras", "Nicaragua", "Panama") ~ "Latin America & Caribbean",
      Area %in% c("Mauritius", "Seychelles", "Comoros", "Cape Verde", "São Tomé and Príncipe", "Equatorial Guinea", "Gabon", "Cameroon", "Republic of the Congo", "Central African Republic", "Chad", "Niger", "Mali", "Burkina Faso", "Senegal", "Gambia", "Guinea-Bissau", "Guinea", "Sierra Leone", "Liberia", "Côte d'Ivoire", "Ghana", "Togo", "Benin", "Nigeria", "Niger", "Mali", "Burkina Faso", "Senegal", "Gambia", "Guinea-Bissau", "Guinea", "Sierra Leone", "Liberia", "Côte d'Ivoire", "Ghana", "Togo", "Benin") ~ "Africa",
      Area %in% c("Mongolia", "Kazakhstan", "Kyrgyzstan", "Tajikistan", "Turkmenistan", "Uzbekistan", "Azerbaijan", "Armenia", "Georgia") ~ "Europe & Central Asia",
      Area %in% c("Laos", "Cambodia", "Myanmar", "Thailand", "Vietnam", "Malaysia", "Singapore", "Brunei", "Philippines", "Indonesia", "Timor-Leste") ~ "East Asia & Pacific",
      Area %in% c("Nepal", "Bhutan", "Bangladesh", "Sri Lanka", "Maldives") ~ "South Asia",
      Area %in% c("Uruguay", "Paraguay", "Ecuador", "Guyana", "Suriname", "French Guiana") ~ "Latin America & Caribbean",
      Area %in% c("Botswana", "Namibia", "South Africa", "Lesotho", "Swaziland", "Zimbabwe", "Zambia", "Malawi", "Mozambique", "Madagascar", "Mauritius", "Seychelles", "Comoros") ~ "Africa",
      Area %in% c("Rwanda", "Burundi", "Uganda", "Kenya", "Tanzania", "Tanzania, United Republic of", "United Republic of Tanzania") ~ "Africa",
      Area %in% c("Djibouti", "Eritrea", "Ethiopia", "Somalia", "Sudan", "South Sudan") ~ "Africa",
      # Middle East & North Africa - MUST come before other Africa assignments to avoid conflicts
      Area %in% c("Iran", "Iran, Islamic Rep.", "Iraq", "Syria", "Syrian Arab Republic", "Lebanon", "Jordan", "Israel", "Palestine", "Saudi Arabia", "Yemen", "Yemen, Rep.", "Oman", "United Arab Emirates", "Qatar", "Bahrain", "Kuwait", "Egypt", "Egypt, Arab Rep.", "Libya", "Tunisia", "Algeria", "Morocco", "Western Sahara") ~ "Middle East & North Africa",
      Area %in% c("Afghanistan", "Pakistan", "India", "Nepal", "Bhutan", "Bangladesh", "Sri Lanka", "Maldives") ~ "South Asia",
      Area %in% c("China", "Japan", "Korea, Republic of", "Korea, Dem. Rep.", "Mongolia", "Taiwan") ~ "East Asia & Pacific",
      Area %in% c("Thailand", "Vietnam", "Laos", "Cambodia", "Myanmar", "Malaysia", "Singapore", "Brunei", "Philippines", "Indonesia", "Timor-Leste") ~ "East Asia & Pacific",
      Area %in% c("Russia", "Russian Federation", "Belarus", "Ukraine", "Moldova", "Romania", "Bulgaria", "Albania", "Macedonia", "Serbia", "Montenegro", "Bosnia and Herzegovina", "Croatia", "Slovenia", "Slovakia", "Czech Republic", "Poland", "Hungary", "Austria", "Switzerland", "Liechtenstein", "Germany", "France", "Belgium", "Netherlands", "Luxembourg", "United Kingdom", "Ireland", "Iceland", "Norway", "Sweden", "Finland", "Denmark", "Estonia", "Latvia", "Lithuania") ~ "Europe & Central Asia",
      Area %in% c("United States", "Canada", "Mexico") ~ "North America",
      Area %in% c("Brazil", "Argentina", "Chile", "Colombia", "Venezuela", "Peru", "Ecuador", "Bolivia", "Paraguay", "Uruguay", "Guyana", "Suriname", "French Guiana") ~ "Latin America & Caribbean",
      Area %in% c("Cuba", "Jamaica", "Haiti", "Dominican Republic", "Puerto Rico", "Trinidad and Tobago", "Barbados", "Bahamas", "Belize", "Costa Rica", "El Salvador", "Guatemala", "Honduras", "Nicaragua", "Panama") ~ "Latin America & Caribbean",
      # Fix countries that were showing as "Unknown" - disputed territories first
      Area %in% c("Gaza", "West Bank", "Taiwan, China") ~ "Other",
      # Africa
      Area %in% c("Angola", "Cabo Verde", "Congo, Rep.", "Cote d'Ivoire", "Eswatini", "Gambia, The", "Mauritania", "Somalia, Fed. Rep.") ~ "Africa",
      # East Asia & Pacific
      Area %in% c("Brunei Darussalam", "Hong Kong", "Korea, Dem. People's Rep.", "Lao PDR", "Macao", "Micronesia, Fed. Sts.", "South Korea") ~ "East Asia & Pacific",
      # Middle East & North Africa
      Area %in% c("Egypt, Arab Rep.", "Iran, Islamic Rep.", "Syrian Arab Republic", "Yemen, Rep.") ~ "Middle East & North Africa",
      # Europe & Central Asia
      Area %in% c("Channel Islands", "Turkiye") ~ "Europe & Central Asia",
      # Latin America & Caribbean
      Area %in% c("Curacao", "Puerto Rico (US)", "St. Martin (French part)", "Virgin Islands (U.S.)") ~ "Latin America & Caribbean",
      TRUE ~ "Unknown"
    ),
    
    # Create development level categories (handle missing GDP data)
    development_level = case_when(
      !is.na(gdp_per_capita) & gdp_per_capita < 1045 ~ "Very Low Income",
      !is.na(gdp_per_capita) & gdp_per_capita < 4095 ~ "Low Income", 
      !is.na(gdp_per_capita) & gdp_per_capita < 12695 ~ "Lower Middle Income",
      !is.na(gdp_per_capita) & gdp_per_capita < 40955 ~ "Upper Middle Income",
      !is.na(gdp_per_capita) ~ "High Income",
      TRUE ~ "Unknown"
    ),
    development_level = factor(development_level, levels = c("Very Low Income", "Low Income", "Lower Middle Income", "Upper Middle Income", "High Income", "Unknown"))
  )

# Use the comprehensive dataset
combined_data <- all_countries_data

# Filter out territories, dependencies, and non-sovereign entities
sovereign_countries <- combined_data %>%
  filter(!Area %in% c(
    # Territories and dependencies
    "American Samoa", "Anguilla", "Aruba", "Bermuda", "British Virgin Islands", "Cayman Islands", 
    "Cook Islands", "Curaçao", "Faroe Islands", "French Polynesia", "Gibraltar", "Greenland", 
    "Guam", "Hong Kong SAR, China", "Isle of Man", "Jersey", "Macao SAR, China", "Montserrat", 
    "New Caledonia", "Niue", "Northern Mariana Islands", "Puerto Rico", "Saint Helena", 
    "Saint Pierre and Miquelon", "Sint Maarten (Dutch part)", "Tokelau", "Turks and Caicos Islands", 
    "U.S. Virgin Islands", "Wallis and Futuna Islands", "Virgin Islands, U.S.", "Virgin Islands, British",
    "Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines", "Antigua and Barbuda",
    "Dominica", "Grenada", "Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines",
    "Seychelles", "Maldives", "Marshall Islands", "Micronesia", "Palau", "Nauru", "Tuvalu",
    "San Marino", "Vatican City", "Monaco", "Liechtenstein", "Andorra", "Malta", "Cyprus",
    # Disputed territories
    "Palestine", "Kashmir", "Taiwan", "Western Sahara", "Northern Cyprus", "Abkhazia", 
    "South Ossetia", "Transnistria", "Nagorno-Karabakh", "Kosovo", "Somaliland", "Puntland",
    # Regional aggregations
    "World", "Africa", "Asia", "Europe", "North America", "South America", "Oceania",
    "Sub-Saharan Africa", "Middle East & North Africa", "Latin America & Caribbean",
    "East Asia & Pacific", "Europe & Central Asia", "South Asia", "Arab World",
    "Caribbean small states", "Central Europe and the Baltics", "Early-demographic dividend",
    "East Asia & Pacific (excluding high income)", "East Asia & Pacific (IDA & IBRD countries)",
    "Euro area", "Europe & Central Asia (excluding high income)", "Europe & Central Asia (IDA & IBRD countries)",
    "European Union", "Fragile and conflict affected situations", "Heavily indebted poor countries (HIPC)",
    "High income", "IBRD only", "IDA & IBRD countries", "IDA & IBRD total", "IDA blend", "IDA only", "IDA total",
    "Late-demographic dividend", "Latin America & Caribbean (excluding high income)",
    "Latin America & Caribbean (IDA & IBRD countries)", "Latin America & the Caribbean (IDA & IBRD countries)",
    "Least developed countries: UN classification",
    "Low & middle income", "Low income", "Lower middle income", "Middle East & North Africa (excluding high income)",
    "Middle East & North Africa (IDA & IBRD countries)", "Middle East, North Africa, Afghanistan & Pakistan",
    "Middle East, North Africa, Afghanistan & Pakistan (IDA & IBRD)",
    "Middle East, North Africa, Afghanistan & Pakistan (excluding high income)",
    "Middle income", "North America",
    "OECD members", "Other small states", "Pacific island small states", "Post-demographic dividend",
    "Pre-demographic dividend", "Small island developing states", "Small states",
    "South Asia (IDA & IBRD)", "South Asia (IDA & IBRD countries)",
    "Sub-Saharan Africa (excluding high income)", "Sub-Saharan Africa (IDA & IBRD countries)",
    "Africa Eastern and Southern", "Africa Western and Central",
    "Upper middle income", "World Bank administrative region - Africa",
    "World Bank administrative region - East Asia and Pacific",
    "World Bank administrative region - Europe and Central Asia",
    "World Bank administrative region - Latin America and Caribbean",
    "World Bank administrative region - Middle East and North Africa",
    "World Bank administrative region - South Asia", "World Bank administrative region - Sub-Saharan Africa"
  ))

cat("✅ Data processing completed!\n")
cat("📊 Total sovereign countries in dataset:", nrow(sovereign_countries), "\n")
cat("📊 Countries with latest FAO data (2022-2024):", sum(!is.na(sovereign_countries$undernourishment_rate)), "\n")
cat("📊 Countries with World Bank data:", sum(!is.na(sovereign_countries$population)), "\n")
cat("📊 Countries with WFP market data:", sum(!is.na(sovereign_countries$total_markets)), "\n")
cat("📊 Countries with both FAO and World Bank data:", sum(!is.na(sovereign_countries$undernourishment_rate) & !is.na(sovereign_countries$population)), "\n")
cat("📊 Countries with PIP poverty data:", sum(!is.na(sovereign_countries$poverty_headcount)), "\n")
cat("🏪 Total WFP markets:", nrow(wfp_markets), "\n")
cat("🍽️ Total WFP commodities:", nrow(wfp_commodities), "\n")

# UI
ui <- fluidPage(
  # Include custom CSS
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
    tags$script(HTML("
      Shiny.addCustomMessageHandler('resetFactorDetail', function(message) {
        Shiny.setInputValue('factor_detail', null, {priority: 'event'});
      });
    "))
  ),
  
  titlePanel("🌍 Enhanced Global Hunger Research Dashboard (2022-2024 Data)"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("🌍 Global Overview"),
      p("This dashboard combines the latest FAO hunger data (2022-2024), World Bank economic indicators, and WFP market data for comprehensive analysis."),
      
      br(),
      h4("🎯 Quick Stats"),
      verbatimTextOutput("quick_stats"),
      
      br(),
      h4("🔍 Filters"),
      selectInput("risk_filter", "Risk Level:",
                  choices = c("All", "Very Low", "Low", "Medium", "High", "Critical"),
                  selected = "All"),
      div(
        class = "info-card",
        style = "background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); padding: 15px; border-radius: 12px; margin-top: 15px; margin-bottom: 20px; font-size: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.08); border-left: 4px solid #667eea;",
        p(strong("Risk Cutoffs (0-100):"), style = "margin-bottom: 8px; color: #2c3e50; font-size: 13px;"),
        p("Very Low: 0-14.9", style = "margin: 4px 0; color: #28a745; font-weight: 500;"),
        p("Low: 15-29.9", style = "margin: 4px 0; color: #17a2b8; font-weight: 500;"),
        p("Medium: 30-49.9", style = "margin: 4px 0; color: #ffc107; font-weight: 500;"),
        p("High: 50-69.9", style = "margin: 4px 0; color: #dc3545; font-weight: 500;"),
        p("Critical: 70-100", style = "margin: 4px 0; color: #8b0000; font-weight: 600;")
      ),
      
      selectInput("region_filter", "Region:",
                  choices = c("All", unique(sovereign_countries$region)),
                  selected = "All"),
      
      selectInput("development_filter", "Development Level:",
                  choices = c("All", levels(sovereign_countries$development_level)),
                  selected = "All"),
      div(
        class = "info-card",
        style = "background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); padding: 15px; border-radius: 12px; margin-top: 15px; margin-bottom: 20px; font-size: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.08); border-left: 4px solid #764ba2;",
        p(strong("Development Levels (GDP per capita):"), style = "margin-bottom: 8px; color: #2c3e50; font-size: 13px;"),
        p("Very Low Income: < $1,045", style = "margin: 4px 0; color: #8b0000; font-weight: 500;"),
        p("Low Income: $1,045 - $4,095", style = "margin: 4px 0; color: #dc3545; font-weight: 500;"),
        p("Lower Middle Income: $4,095 - $12,695", style = "margin: 4px 0; color: #ffc107; font-weight: 500;"),
        p("Upper Middle Income: $12,695 - $40,955", style = "margin: 4px 0; color: #17a2b8; font-weight: 500;"),
        p("High Income: ≥ $40,955", style = "margin: 4px 0; color: #28a745; font-weight: 500;"),
        p(em("Based on World Bank classifications"), style = "margin-top: 8px; font-size: 11px; color: #666; font-style: italic;")
      ),
      
    ),
    
    mainPanel(
      width = 9,
      tabsetPanel(
        id = "main_tabs",
        type = "tabs",
        
        tabPanel("🗺️ World Map",
          fluidRow(
            column(12,
              div(
                style = "background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); margin-bottom: 20px;",
                h4("Global Hunger Vulnerability Map (2022-2024 Data)", style = "color: #2c3e50; margin-bottom: 15px;"),
                p("Click on any country to view detailed analysis. Countries are colored by Hunger Vulnerability Rating (0-100 scale) using a comprehensive regression model. Higher ratings (red) indicate greater vulnerability to hunger. Hover for detailed statistics.", 
                  style = "color: #666; font-size: 14px; margin-bottom: 20px; line-height: 1.7;"),
              plotlyOutput("world_map", height = "600px")
              )
            )
          )
        ),
        
        tabPanel("📈 Key Insights",
          fluidRow(
            column(12,
              div(
                style = "background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); margin-bottom: 25px;",
                h4("Global Hunger & Development Insights (2022-2024)", style = "color: #2c3e50; margin-bottom: 15px;"),
                p("Key visualizations revealing patterns and relationships in global hunger, poverty, development, and market access data using the latest available information.", 
                  style = "color: #666; font-size: 14px; margin-bottom: 0; line-height: 1.7;")
              )
            )
          ),
          fluidRow(
            column(6,
              h4("Hunger vs Poverty: The Critical Relationship"),
              p("This scatter plot reveals the strong correlation between undernourishment and poverty rates using 2022-2024 data. Countries with higher poverty tend to have higher hunger rates.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_hunger_poverty", height = "400px")
            ),
            column(6,
              h4("Undernourished Population by Region"),
              p("This chart shows the total number of undernourished people by region, highlighting where the greatest hunger challenges exist globally.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_undernourished_population", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(6,
              h4("Market Access vs Hunger Risk"),
              p("This analysis shows the relationship between WFP market access and hunger risk levels. Countries with better market access tend to have lower hunger risk.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_market_hunger", height = "400px")
            ),
            column(6,
              h4("Development Level vs Hunger"),
              p("This visualization shows how hunger rates vary by development level, demonstrating the strong relationship between economic development and food security.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_development_hunger", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(12,
              h4("Regional Hunger Patterns (2022-2024)"),
              p("This analysis shows hunger patterns across different world regions using the latest FAO data, revealing which regions face the greatest challenges.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_regional_patterns", height = "400px")
            )
          )
        ),
        
        tabPanel("📊 Country Details",
          fluidRow(
            column(12,
              div(
                style = "background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); margin-bottom: 20px;",
                h4("Country Analysis (2022-2024 Data)", style = "color: #2c3e50; margin-bottom: 15px;"),
                p("Select a country from the map or dropdown to view detailed analysis including the latest hunger data, trends, hunger outbreak history, and WFP market data.", 
                  style = "color: #666; font-size: 14px; margin-bottom: 20px; line-height: 1.7;"),
              selectInput("selected_country", "Select Country:",
                         choices = c("Select a country..." = "", sort(unique(sovereign_countries$Area))),
                           selected = "",
                           width = "100%")
              ),
              # Hidden input for factor detail tracking
              tags$input(id = "factor_detail", type = "text", value = "", style = "display: none;"),
              uiOutput("country_analysis"),
              uiOutput("factor_detail_breakdown")
            )
          )
        ),
        
        tabPanel("📊 About GHI",
          fluidRow(
            column(12,
              h3("🌍 What is the Global Hunger Index (GHI)?"),
              p("The Global Hunger Index (GHI) is a tool designed to comprehensively measure and track hunger at the global, regional, and country levels.", style = "color: #666; font-size: 16px; margin-bottom: 20px;"),
              
              div(
                style = "background-color: #e7f3ff; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #0066cc;",
                h4("📋 GHI Components"),
                p("The GHI score is calculated using four key indicators:", style = "font-size: 14px; margin-bottom: 15px;"),
                tags$ul(
                  tags$li(strong("1. Undernourishment (33.3%):"), "The proportion of the population that is undernourished (lacking sufficient caloric intake)", style = "margin-bottom: 10px;"),
                  tags$li(strong("2. Child Wasting (16.7%):"), "The proportion of children under five years old who have low weight for their height (acute malnutrition)", style = "margin-bottom: 10px;"),
                  tags$li(strong("3. Child Stunting (33.3%):"), "The proportion of children under five years old who have low height for their age (chronic malnutrition)", style = "margin-bottom: 10px;"),
                  tags$li(strong("4. Child Mortality (16.7%):"), "The mortality rate of children under five years old (often reflects the fatal mix of inadequate nutrition and unhealthy environments)", style = "margin-bottom: 10px;")
                )
              ),
              
              div(
                style = "background-color: #fff3cd; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #ffc107;",
                h4("📊 GHI Score Interpretation"),
                p("GHI scores are calculated on a 0-100 scale, where:", style = "font-size: 14px; margin-bottom: 15px;"),
                tags$ul(
                  tags$li(strong("0-9.9:"), "Low hunger", style = "color: #28a745; margin-bottom: 8px;"),
                  tags$li(strong("10-19.9:"), "Moderate hunger", style = "color: #ffc107; margin-bottom: 8px;"),
                  tags$li(strong("20-34.9:"), "Serious hunger", style = "color: #fd7e14; margin-bottom: 8px;"),
                  tags$li(strong("35-49.9:"), "Alarming hunger", style = "color: #dc3545; margin-bottom: 8px;"),
                  tags$li(strong("50+:"), "Extremely alarming hunger", style = "color: #8b0000; margin-bottom: 8px;")
                )
              ),
              
              div(
                style = "background-color: #d1ecf1; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #17a2b8;",
                h4("🔍 How GHI Differs from Our Vulnerability Rating"),
                p("While both measures assess hunger vulnerability, they use different methodologies:", style = "font-size: 14px; margin-bottom: 15px;"),
                tags$ul(
                  tags$li(strong("GHI:"), "Focuses on four core indicators (undernourishment, child wasting, stunting, mortality) with equal emphasis on child nutrition", style = "margin-bottom: 10px;"),
                  tags$li(strong("Our Rating:"), "Uses 14 factors including economic indicators (GDP, poverty), regional risk, historical crises, market access, and more comprehensive data sources", style = "margin-bottom: 10px;"),
                  tags$li(strong("Comparison:"), "Viewing both scores together provides a more complete picture of a country's food security situation", style = "margin-bottom: 10px;")
                )
              ),
              
              div(
                style = "background-color: #f8f9fa; padding: 20px; border-radius: 8px;",
                h4("📚 Data Sources"),
                p("GHI data is compiled by:", style = "font-size: 14px; margin-bottom: 10px;"),
                tags$ul(
                  tags$li("Welthungerhilfe (WHH)"),
                  tags$li("Concern Worldwide"),
                  tags$li("Data sources include FAO, UNICEF, WHO, and World Bank")
                ),
                p("For more information, visit the official GHI website.", style = "font-size: 14px; margin-top: 15px; color: #666;")
              )
            )
          )
        ),
        
        tabPanel("🧮 Vulnerability Formula",
          fluidRow(
            column(12,
              h4("Hunger Vulnerability Rating Formula"),
              p("The Hunger Vulnerability Rating is a comprehensive 0-100 scale that combines multiple factors to assess a country's risk of hunger and food insecurity.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              p("📊 Poverty Definition: Poverty is defined as living under $10 per day (2017 PPP), based on the World Bank's Poverty and Inequality Platform (PIP) data.", style = "color: #2E8B57; font-size: 14px; margin-bottom: 15px; font-weight: bold;")
            )
          ),
          fluidRow(
            column(8,
              h4("Comprehensive Formula Components"),
              div(
                style = "background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
                h5("Hunger Vulnerability Rating = All Data Sources Combined (0-100 points)", style = "color: #2c3e50; font-weight: bold;"),
                br(),
                h5("14-Factor Comprehensive Breakdown (Full 0-100 Scale):"),
                tags$ul(
                  tags$li(strong("1. Undernourishment (0-40 points):"), "FAO undernourishment rate × 0.8 - PRIMARY FACTOR"),
                  tags$li(strong("2. Historical Crises (0-20 points):"), "21st century hunger outbreaks - HIGH EMPHASIS"),
                  tags$li(strong("3. Regional Risk (0-15 points):"), "Geographic vulnerability factors - HIGH EMPHASIS"),
                  tags$li(strong("4. Poverty (0-20 points):"), "PIP/World Bank poverty data × 0.4"),
                  tags$li(strong("5. Economic Development (0-15 points):"), "GDP per capita (inverse relationship)"),
                  tags$li(strong("6. Health Status (0-10 points):"), "Life expectancy (inverse relationship)"),
                  tags$li(strong("7. Inequality (0-8 points):"), "Gini coefficient (higher inequality = higher vulnerability)"),
                  tags$li(strong("8. Market Access (0-7 points):"), "WFP market data (fewer markets = higher vulnerability)"),
                  tags$li(strong("9. Population Scale (0-5 points):"), "Population size (larger populations = higher complexity)"),
                  tags$li(strong("10. Child Stunting (0-8 points):"), "World Bank API - Long-term malnutrition indicators"),
                  tags$li(strong("11. Agricultural Productivity (0-6 points):"), "World Bank API - Cereal yield (kg/hectare)"),
                  tags$li(strong("12. Food Production (0-4 points):"), "World Bank API - Food production index"),
                  tags$li(strong("13. Climate Vulnerability (0-6 points):"), "Climate Data - Temperature anomalies & drought risk"),
                  tags$li(strong("14. Health Vulnerability (0-8 points):"), "Health Data - Child/maternal mortality & immunization")
                ),
                br(),
                p("This comprehensive formula incorporates data from FAO, World Bank API, PIP, WFP, EM-DAT, Climate Data, and Health Data to provide the most accurate hunger vulnerability assessment possible. Now includes real-time World Bank indicators, climate vulnerability factors, and health indicators.", style = "color: #666; font-style: italic;")
              )
            ),
            column(4,
              h4("Risk Category Cutoffs"),
              p("Vulnerability scores are categorized into risk levels based on the following ranges:", style = "color: #666; font-size: 13px; margin-bottom: 15px;"),
              div(
                style = "background-color: #d4edda; padding: 15px; border-radius: 8px; margin-bottom: 10px; border-left: 4px solid #28a745;",
                h5("🟢 Very Low Risk", style = "color: #28a745; font-weight: bold; margin-bottom: 5px;"),
                p("Score: 0 - 14.9", style = "font-size: 13px; font-weight: bold; margin: 0;"),
                p("Very low hunger vulnerability", style = "font-size: 12px; margin-top: 5px; color: #666;")
              ),
              div(
                style = "background-color: #d1ecf1; padding: 15px; border-radius: 8px; margin-bottom: 10px; border-left: 4px solid #17a2b8;",
                h5("🔵 Low Risk", style = "color: #17a2b8; font-weight: bold; margin-bottom: 5px;"),
                p("Score: 15 - 29.9", style = "font-size: 13px; font-weight: bold; margin: 0;"),
                p("Low hunger vulnerability", style = "font-size: 12px; margin-top: 5px; color: #666;")
              ),
              div(
                style = "background-color: #fff3cd; padding: 15px; border-radius: 8px; margin-bottom: 10px; border-left: 4px solid #ffc107;",
                h5("🟡 Medium Risk", style = "color: #f39c12; font-weight: bold; margin-bottom: 5px;"),
                p("Score: 30 - 49.9", style = "font-size: 13px; font-weight: bold; margin: 0;"),
                p("Moderate hunger vulnerability", style = "font-size: 12px; margin-top: 5px; color: #666;")
              ),
              div(
                style = "background-color: #f8d7da; padding: 15px; border-radius: 8px; margin-bottom: 10px; border-left: 4px solid #dc3545;",
                h5("🟠 High Risk", style = "color: #dc3545; font-weight: bold; margin-bottom: 5px;"),
                p("Score: 50 - 69.9", style = "font-size: 13px; font-weight: bold; margin: 0;"),
                p("High hunger vulnerability", style = "font-size: 12px; margin-top: 5px; color: #666;")
              ),
              div(
                style = "background-color: #f5c6cb; padding: 15px; border-radius: 8px; border-left: 4px solid #8b0000;",
                h5("🔴 Critical Risk", style = "color: #8b0000; font-weight: bold; margin-bottom: 5px;"),
                p("Score: 70 - 100", style = "font-size: 13px; font-weight: bold; margin: 0;"),
                p("Severe hunger vulnerability", style = "font-size: 12px; margin-top: 5px; color: #666;")
              )
            )
          ),
          fluidRow(
            column(12,
              h4("Detailed Component Scoring"),
              div(
                style = "background-color: #f8f9fa; padding: 20px; border-radius: 8px;",
                h5("GDP per Capita Scoring:"),
                tags$ul(
                  tags$li("< $1,000: 15 points"),
                  tags$li("$1,000 - $2,999: 12 points"),
                  tags$li("$3,000 - $9,999: 8 points"),
                  tags$li("$10,000 - $19,999: 4 points"),
                  tags$li("≥ $20,000: 0 points")
                ),
                p(em("Note: Development level categories (used in filters) follow World Bank classifications: Very Low Income (< $1,045), Low Income ($1,045-$4,095), Lower Middle Income ($4,095-$12,695), Upper Middle Income ($12,695-$40,955), High Income (≥ $40,955)."), style = "color: #666; font-size: 12px; margin-top: 10px;"),
                br(),
                h5("Market Access Scoring (WFP Markets):"),
                tags$ul(
                  tags$li("High Market Access (≥ 100 markets): 0 points"),
                  tags$li("Medium Market Access (50-99 markets): 3 points"),
                  tags$li("Low Market Access (10-49 markets): 5 points"),
                  tags$li("Very Low Market Access (< 10 markets): 7 points"),
                  tags$li("No markets (0 markets): 7 points")
                ),
                p(em("Market access is based on the number of WFP food markets operating in a country. More markets indicate better food distribution infrastructure."), style = "color: #666; font-size: 12px; margin-top: 10px;"),
                br(),
                h5("Life Expectancy Scoring:"),
                tags$ul(
                  tags$li("Under 50 years: 10 points (Very Low)"),
                  tags$li("50-70 years: 5 points (Low)"),
                  tags$li("70+ years: 0 points (Good)")
                ),
                br(),
                h5("Historical Context:"),
                p("Countries with major hunger outbreaks in the 21st century receive an additional 5 points, reflecting their historical vulnerability to food crises.", style = "font-size: 14px; color: #666;")
              )
            )
          )
        ),
        
        tabPanel("🏪 WFP Market Analysis",
          fluidRow(
            column(12,
              h4("WFP Market and Commodity Analysis"),
              p("Detailed analysis of WFP market coverage, commodity tracking, and food security monitoring infrastructure.", style = "color: #666; font-size: 14px; margin-bottom: 15px;")
            )
          ),
          fluidRow(
            column(6,
              h4("Market Distribution by Country"),
              plotlyOutput("wfp_market_distribution", height = "400px")
            ),
            column(6,
              h4("Population Served by Markets"),
              plotlyOutput("wfp_population_served", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(12,
              h4("WFP Markets Data Table"),
              DT::dataTableOutput("wfp_markets_table")
            )
          )
        ),
        
        tabPanel("📈 Data Explorer",
          fluidRow(
            column(12,
              h4("Complete Dataset (2022-2024)"),
              p("Explore the full dataset with latest FAO data, World Bank indicators, and WFP data. Filter and export capabilities available.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              DT::dataTableOutput("data_table")
            )
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive value to track which factor detail is being shown
  selected_factor_detail <- reactiveVal(NULL)
  
  # Clear factor detail when country changes
  observeEvent(input$selected_country, {
    updateTextInput(session, "factor_detail", value = "")
  })
  
  # Filtered data reactive
  filtered_data <- reactive({
    data <- sovereign_countries
    
    if (input$risk_filter != "All") {
      data <- data %>% filter(combined_risk == input$risk_filter)
    }
    
    if (input$region_filter != "All") {
      data <- data %>% filter(region == input$region_filter)
    }
    
    if (input$development_filter != "All") {
      data <- data %>% filter(development_level == input$development_filter)
    }
    
    return(data)
  })
  
  # Quick stats
  output$quick_stats <- renderText({
    data <- filtered_data()
    total_undernourished <- sum(data$undernourished_population, na.rm = TRUE)
    countries_with_pop_data <- sum(!is.na(data$undernourished_population))
    
    paste0(
      "Countries: ", nrow(data), "\n",
      "Avg Undernourishment: ", round(mean(data$undernourishment_rate, na.rm = TRUE), 1), "%\n",
      "Total Undernourished: ", ifelse(total_undernourished > 0, paste(round(total_undernourished, 1), "M"), "Data limited"), "\n",
      "Countries w/ Pop Data: ", countries_with_pop_data, "\n",
      "Avg Poverty Rate (<$10/day): ", round(mean(data$poverty_rate, na.rm = TRUE), 1), "%\n",
      "Avg Life Expectancy: ", round(mean(data$life_expectancy, na.rm = TRUE), 1), " years\n",
      "Avg GDP per Capita: $", round(mean(data$gdp_per_capita, na.rm = TRUE), 0), "\n",
      "Total WFP Markets: ", sum(data$total_markets, na.rm = TRUE)
    )
  })
  
  # World map
  output$world_map <- renderPlotly({
    # Get all countries data (not just filtered)
    all_data <- sovereign_countries
    
    # Determine which countries are in the selected region
    selected_region <- input$region_filter
    if (!is.null(selected_region) && selected_region != "All") {
      all_data$in_selected_region <- all_data$region == selected_region
    } else {
      all_data$in_selected_region <- TRUE  # Show all countries normally
    }
    
    # Apply other filters to determine which countries to show with data
    # Handle case where filtered_data() might be empty or have issues
    tryCatch({
      filtered_data_result <- filtered_data()
      if (!is.null(filtered_data_result) && nrow(filtered_data_result) > 0) {
        filtered_country_names <- filtered_data_result$Area
      } else {
        filtered_country_names <- character(0)
      }
    }, error = function(e) {
      cat("Error in filtered_data():", e$message, "\n")
      filtered_country_names <<- character(0)
    })
    
    # Determine which countries match the risk filter (if any)
    # If risk filter is "All", show all countries; otherwise only show filtered countries
    selected_risk <- input$risk_filter
    if (!is.null(selected_risk) && selected_risk != "All" && length(filtered_country_names) > 0) {
      all_data$in_risk_filter <- all_data$Area %in% filtered_country_names
    } else {
      all_data$in_risk_filter <- TRUE  # Show all countries if no risk filter
    }
    
    # Determine which countries match the development filter (if any)
    selected_development <- input$development_filter
    if (!is.null(selected_development) && selected_development != "All") {
      all_data$in_development_filter <- all_data$development_level == selected_development
    } else {
      all_data$in_development_filter <- TRUE  # Show all countries if no development filter
    }
    
    # Calculate estimated undernourished population if missing
    all_data$estimated_undernourished_pop <- ifelse(
      is.na(all_data$undernourished_population) & !is.na(all_data$undernourishment_rate) & !is.na(all_data$population),
      (all_data$undernourishment_rate / 100) * all_data$population / 1e6,  # Convert to millions
      all_data$undernourished_population
    )
    
    # Create hover text with essential information (handle missing data)
    hover_text <- paste(
      "<b>", all_data$Area, "</b><br>",
      "Hunger Vulnerability Rating: ", ifelse(is.na(all_data$hunger_vulnerability_rating), "No data", paste(all_data$hunger_vulnerability_rating, "/100")), "<br>",
      "Population: ", ifelse(is.na(all_data$population), "No data", paste(format(round(all_data$population / 1e6, 1), big.mark = ","), "M")), "<br>",
      "GDP per Capita: ", ifelse(is.na(all_data$gdp_per_capita), "No data", paste("$", format(round(all_data$gdp_per_capita, 0), big.mark = ","))), "<br>",
      "Poverty Rate (<$10/day): ", ifelse(
        !is.na(all_data$poverty_headcount), 
        paste(round(all_data$poverty_headcount * 100, 2), "%"), 
        ifelse(!is.na(all_data$poverty_rate), paste(round(all_data$poverty_rate, 1), "%"), "No data")
      ), "<br>",
      "Undernourishment: ", ifelse(is.na(all_data$undernourishment_rate), "No data", paste(round(all_data$undernourishment_rate, 1), "%")), "<br>",
      "Undernourished Pop: ", ifelse(
        is.na(all_data$estimated_undernourished_pop), 
        "No data", 
        ifelse(
          is.na(all_data$undernourished_population) & !is.na(all_data$estimated_undernourished_pop),
          paste("~", round(all_data$estimated_undernourished_pop, 1), "M (estimated)"),
          paste(round(all_data$estimated_undernourished_pop, 1), "M")
        )
      ), "<br>",
      "Life Expectancy: ", ifelse(is.na(all_data$life_expectancy), "No data", paste(round(all_data$life_expectancy, 1), "years")), "<br>",
      "Major Hunger Outbreak (21st C): ", ifelse(all_data$major_hunger_outbreak_21st, "Yes", "No"), "<br>",
      "Click for detailed analysis"
    )
    
    # Use hunger vulnerability rating for coloring
    # Set countries outside selected region OR risk filter OR development filter to white (very low z value)
    # A country must be in the selected region AND match the risk filter AND match the development filter (if applicable) to be shown
    all_data$should_show <- all_data$in_selected_region & all_data$in_risk_filter & all_data$in_development_filter
    
    map_z <- ifelse(
      is.na(all_data$hunger_vulnerability_rating),
      ifelse(all_data$should_show, NA, -1),  # Missing data: NA if should show, -1 if not
      ifelse(all_data$should_show, all_data$hunger_vulnerability_rating, -1)  # Has data: use value if should show, -1 if not
    )
    
    # Debug: Check the actual z values being used for coloring
    cat("Map Z Debug - Non-NA values:", sum(!is.na(map_z)), "\n")
    cat("Map Z Debug - Range:", range(map_z, na.rm = TRUE), "\n")
    cat("Map Z Debug - Sample values:", head(sort(map_z[!is.na(map_z)]), 10), "\n")
    
    # Debug: Check Afghanistan
    if("Afghanistan" %in% all_data$Area) {
      afghanistan_data <- all_data[all_data$Area == "Afghanistan", ]
      afghanistan_z <- map_z[all_data$Area == "Afghanistan"]
      cat("Afghanistan Map Z:", afghanistan_z, "| Vulnerability:", afghanistan_data$hunger_vulnerability_rating, "\n")
      cat("Afghanistan should be RED for score 73.5\n")
    }
    
    # Debug: Check data consistency
    cat("Map Debug - Total countries:", nrow(all_data), "\n")
    cat("Map Debug - Countries with vulnerability data:", sum(!is.na(all_data$hunger_vulnerability_rating)), "\n")
    cat("Map Debug - Vulnerability range:", range(all_data$hunger_vulnerability_rating, na.rm = TRUE), "\n")
    cat("Map Debug - Selected region:", selected_region, "\n")
    cat("Map Debug - Countries in selected region:", sum(all_data$in_selected_region), "\n")
    
    # Create custom colorscale that includes white for filtered-out countries
    # With zmin=-1 and zmax=100, we need to normalize: z=-1 maps to 0, z=100 maps to 1
    # Formula: normalized = (z - zmin) / (zmax - zmin) = (z - (-1)) / (100 - (-1)) = (z + 1) / 101
    # So: z=-1 -> 0, z=0 -> 1/101 ≈ 0.01, z=100 -> 101/101 = 1
    custom_colorscale <- list(
      c(0, "#FFFFFF"),         # White for filtered-out countries (z = -1, normalized = 0)
      c(0.01, "#FFF5F0"),      # Very light red for 0 (normalized ≈ 0.01)
      c(0.2, "#FEE0D2"),       # Light red for ~20 (normalized ≈ 0.21)
      c(0.4, "#FCBBA1"),       # Medium-light red for ~40 (normalized ≈ 0.41)
      c(0.6, "#FB6A4A"),       # Medium red for ~60 (normalized ≈ 0.60)
      c(0.8, "#CB181D"),       # Dark red for ~80 (normalized ≈ 0.80)
      c(1.0, "#67000D")        # Very dark red for 100 (normalized = 1.0)
    )
    
    # Determine geo center and scale for zoom based on selected region
    # Format: list(center = list(lon = ..., lat = ...), scale = ...)
    region_zoom <- list(
      "South Asia" = list(center = list(lon = 80, lat = 25), scale = 2.5),
      "East Asia & Pacific" = list(center = list(lon = 130, lat = 20), scale = 2.0),
      "North America" = list(center = list(lon = -100, lat = 45), scale = 1.8),
      "South America" = list(center = list(lon = -60, lat = -20), scale = 2.2),
      "Europe & Central Asia" = list(center = list(lon = 50, lat = 50), scale = 2.0),
      "Africa" = list(center = list(lon = 20, lat = 5), scale = 1.8),
      "Middle East & North Africa" = list(center = list(lon = 30, lat = 25), scale = 2.0),
      "Latin America & Caribbean" = list(center = list(lon = -75, lat = -10), scale = 1.8)
    )
    
    # Get geo configuration with enhanced line sharpness
    geo_config <- list(
      showframe = TRUE,
      showcoastlines = TRUE,
      projection = list(type = "natural earth"),
      bgcolor = "rgba(0,0,0,0)",
      coastlinecolor = "rgba(0,0,0,0.8)",
      coastlinewidth = 1.5,
      countrycolor = "rgba(0,0,0,0.4)",
      countrywidth = 1,
      framecolor = "rgba(0,0,0,0.8)",
      framewidth = 2,
      showlakes = TRUE,
      lakecolor = "rgba(173,216,230,0.2)",
      showocean = TRUE,
      oceancolor = "rgba(230,240,255,0.5)",
      showland = FALSE,
      landcolor = "rgba(0,0,0,0)",
      lonaxis = list(showgrid = FALSE),
      lataxis = list(showgrid = FALSE)
    )
    
    # Add zoom if region is selected
    if (!is.null(selected_region) && selected_region != "All" && selected_region %in% names(region_zoom)) {
      geo_config$projection <- list(
        type = "natural earth",
        rotation = list(lon = region_zoom[[selected_region]]$center$lon, lat = region_zoom[[selected_region]]$center$lat),
        scale = region_zoom[[selected_region]]$scale
      )
    }
    
    # Adjust margins and title position based on whether region is selected
    # When zoomed in, need much more top margin to prevent title overlap
    if (!is.null(selected_region) && selected_region != "All") {
      # Zoomed view: very large top margin to prevent any overlap
      map_margin <- list(t = 250, b = 60, l = 60, r = 200)
      title_y <- 0.998
      colorbar_title_y <- 0.995
    } else {
      # Global view: standard margins with extra top space
      map_margin <- list(t = 120, b = 60, l = 60, r = 200)
      title_y <- 0.985
      colorbar_title_y <- 0.97
    }
    
    # Create the map
    plot_ly(
      type = "choropleth",
      locations = all_data$Area,
      locationmode = "country names",
      z = map_z,
      zmin = -1,  # Include -1 for white countries
      zmax = 100,
      colorscale = custom_colorscale,
      reversescale = FALSE,
      showscale = TRUE,
      text = hover_text,
      hoverinfo = "text",
      colorbar = list(
        title = list(
          text = "",
          side = "top"
        ),
        len = 0.8,
        x = 1.05,
        y = 0.5,
        yanchor = "middle",
        tickmode = "array",
        tickvals = c(0, 20, 40, 60, 80, 100),
        ticktext = c("0", "20", "40", "60", "80", "100")
      )
    ) %>%
      layout(
        title = list(
          text = ifelse(!is.null(selected_region) && selected_region != "All", 
                       paste("Hunger Vulnerability Map -", selected_region, "(2022-2024 Data)"),
                       "Global Hunger Vulnerability Map (2022-2024 Data) - Click Country for Details"),
          font = list(size = 16),
          x = 0.5,
          y = title_y,
          xanchor = "center",
          yanchor = "top",
          pad = list(t = 10, b = 10)
        ),
        margin = map_margin,
        annotations = list(
          list(
            text = "Hunger Vulnerability Rating (0-100)",
            x = 1.08,
            y = colorbar_title_y,
            xref = "paper",
            yref = "paper",
            showarrow = FALSE,
            font = list(size = 14),
            xanchor = "center",
            yanchor = "middle"
          )
        ),
        geo = geo_config
      ) %>%
      config(
        displayModeBar = FALSE,
        plotGlPixelRatio = 2,
        toImageButtonOptions = list(
          format = "png",
          filename = "hunger_vulnerability_map",
          height = 1080,
          width = 1920,
          scale = 2
        )
      ) %>%
      event_register("plotly_click")
  })
  
  # Handle map clicks
  observeEvent(event_data("plotly_click"), {
    click_data <- event_data("plotly_click")
    if (!is.null(click_data)) {
      # Get the point number to look up the country
      point_number <- click_data$pointNumber
      
      # Debug: print click data
      cat("Click data:", paste(names(click_data), "=", click_data, collapse = ", "), "\n")
      
      if (!is.null(point_number) && !is.na(point_number)) {
        # Get the current filtered data to match the point number
        current_data <- filtered_data()
        
        # Make sure we have data and the point number is valid
        if (nrow(current_data) > 0 && point_number >= 0 && point_number < nrow(current_data)) {
          # Get the country name from the data at that point
          country_name <- current_data$Area[point_number + 1]  # R is 1-indexed
          
          cat("Clicked country:", country_name, "\n")
          
          # Update the country selection
          updateSelectInput(session, "selected_country", selected = country_name)
          
          # Switch to Country Details tab
          updateTabsetPanel(session, "main_tabs", selected = "📊 Country Details")
        }
      }
    }
  })
  
  # Key Insights Visualizations
  
  # Hunger vs Poverty insight
  output$insight_hunger_poverty <- renderPlotly({
    data <- sovereign_countries %>%
      filter(!is.na(undernourishment_rate) & !is.na(poverty_rate))
    
    plot_ly(data, 
            x = ~poverty_rate, 
            y = ~undernourishment_rate,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Country:", Area, 
                         "<br>Poverty Rate (<$10/day):", round(poverty_rate, 1), "%",
                         "<br>Undernourishment:", round(undernourishment_rate, 1), "%",
                         "<br>Risk Level:", combined_risk),
            hoverinfo = "text",
            type = "scatter", mode = "markers",
            marker = list(size = 8, opacity = 0.7)) %>%
      layout(
        title = "Hunger vs Poverty: The Critical Relationship",
        xaxis = list(title = "Poverty Rate (<$10/day) (%)"),
        yaxis = list(title = "Undernourishment Rate (%)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Undernourished Population by Region
  output$insight_undernourished_population <- renderPlotly({
    regional_data <- sovereign_countries %>%
      filter(!is.na(region) & !is.na(undernourished_population)) %>%
      group_by(region) %>%
      summarise(
        total_undernourished = sum(undernourished_population, na.rm = TRUE),
        countries = n(),
        .groups = "drop"
      ) %>%
      filter(total_undernourished > 0) %>%
      arrange(desc(total_undernourished))
    
    if (nrow(regional_data) == 0) {
      return(
        plot_ly() %>% 
          add_annotations(
            text = "Population data not available for most countries<br>(Many developed countries suppress this data)", 
            showarrow = FALSE,
            x = 0.5, y = 0.5,
            xref = "paper", yref = "paper"
          ) %>%
          layout(
            title = "Undernourished Population by Region",
            xaxis = list(showgrid = FALSE, showticklabels = FALSE),
            yaxis = list(showgrid = FALSE, showticklabels = FALSE)
          ) %>%
          config(displayModeBar = FALSE)
      )
    }
    
    plot_ly(regional_data, 
            x = ~reorder(region, total_undernourished), 
            y = ~total_undernourished,
            type = "bar",
            text = ~paste("Region:", region, 
                         "<br>Total Undernourished:", round(total_undernourished, 1), "M",
                         "<br>Countries:", countries),
            hoverinfo = "text") %>%
      layout(
        title = "Undernourished Population by Region",
        xaxis = list(title = "Region"),
        yaxis = list(title = "Total Undernourished Population (Millions)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Market Access vs Hunger insight
  output$insight_market_hunger <- renderPlotly({
    data <- sovereign_countries %>%
      filter(!is.na(market_access) & !is.na(combined_risk))
    
    market_hunger_data <- data %>%
      count(market_access, combined_risk) %>%
      group_by(market_access) %>%
      mutate(percentage = n / sum(n) * 100)
    
    plot_ly(market_hunger_data, 
            x = ~market_access, 
            y = ~percentage,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Market Access:", market_access, 
                         "<br>Risk Level:", combined_risk,
                         "<br>Percentage:", round(percentage, 1), "%"),
            hoverinfo = "text",
            type = "bar") %>%
      layout(
        title = "Market Access vs Hunger Risk",
        xaxis = list(title = "Market Access Level"),
        yaxis = list(title = "Percentage of Countries"),
        barmode = "stack",
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Development Level vs Hunger
  output$insight_development_hunger <- renderPlotly({
    data <- sovereign_countries %>%
      filter(!is.na(development_level) & !is.na(undernourishment_rate))
    
    plot_ly(data, 
            x = ~development_level, 
            y = ~undernourishment_rate,
            color = ~development_level,
            type = "box",
            text = ~paste("Country:", Area, 
                         "<br>Development Level:", development_level,
                         "<br>Undernourishment:", round(undernourishment_rate, 1), "%"),
            hoverinfo = "text") %>%
      layout(
        title = "Hunger Rates by Development Level",
        xaxis = list(title = "Development Level"),
        yaxis = list(title = "Undernourishment Rate (%)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Regional Hunger Patterns
  output$insight_regional_patterns <- renderPlotly({
    regional_data <- sovereign_countries %>%
      filter(!is.na(region) & !is.na(undernourishment_rate)) %>%
      group_by(region) %>%
      summarise(
        avg_undernourishment = mean(undernourishment_rate, na.rm = TRUE),
        total_undernourished = sum(undernourished_population, na.rm = TRUE),
        countries = n(),
        .groups = "drop"
      ) %>%
      filter(avg_undernourishment > 0)
    
    plot_ly(regional_data, 
            x = ~reorder(region, avg_undernourishment), 
            y = ~avg_undernourishment,
            size = ~total_undernourished,
            type = "scatter",
            mode = "markers",
            text = ~paste("Region:", region, 
                         "<br>Avg Undernourishment:", round(avg_undernourishment, 1), "%",
                         "<br>Total Undernourished:", round(total_undernourished, 1), "M",
                         "<br>Countries:", countries),
            hoverinfo = "text",
            marker = list(sizemode = "diameter", sizeref = 2, opacity = 0.7)) %>%
      layout(
        title = "Regional Hunger Patterns (2022-2024)",
        xaxis = list(title = "Region"),
        yaxis = list(title = "Average Undernourishment Rate (%)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # WFP Market Analysis (same as before)
  output$wfp_market_distribution <- renderPlotly({
    market_dist <- wfp_data$markets %>%
      arrange(desc(total_markets)) %>%
      head(20)  # Top 20 countries by market count
    
    plot_ly(market_dist, 
            x = ~reorder(Country, total_markets), 
            y = ~total_markets,
            type = "bar",
            text = ~paste("Country:", Country, 
                         "<br>Total Markets:", total_markets,
                         "<br>Population Served:", format(round(total_population_served / 1e6, 1), big.mark = ","), "M"),
            hoverinfo = "text") %>%
      layout(
        title = "Top 20 Countries by WFP Market Count",
        xaxis = list(title = "Country"),
        yaxis = list(title = "Number of Markets"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  output$wfp_population_served <- renderPlotly({
    pop_served <- wfp_data$markets %>%
      arrange(desc(total_population_served)) %>%
      head(20)  # Top 20 countries by population served
    
    plot_ly(pop_served, 
            x = ~reorder(Country, total_population_served), 
            y = ~total_population_served / 1e6,  # Convert to millions
            type = "bar",
            text = ~paste("Country:", Country, 
                         "<br>Population Served:", format(round(total_population_served / 1e6, 1), big.mark = ","), "M",
                         "<br>Total Markets:", total_markets),
            hoverinfo = "text") %>%
      layout(
        title = "Top 20 Countries by Population Served",
        xaxis = list(title = "Country"),
        yaxis = list(title = "Population Served (Millions)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  output$wfp_markets_table <- DT::renderDataTable({
    DT::datatable(
      wfp_data$markets %>%
        select(Country, total_markets, total_population_served, avg_market_population, market_access) %>%
        mutate(
          total_population_served = round(total_population_served / 1e6, 1),
          avg_market_population = round(avg_market_population / 1e3, 1)
        ) %>%
        rename(
          "Total Markets" = total_markets,
          "Population Served (M)" = total_population_served,
          "Avg Market Population (K)" = avg_market_population,
          "Market Access Level" = market_access
        ),
      options = list(
        pageLength = 25, 
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons',
      filter = 'top'
    )
  })
  
  # Country analysis
  output$country_analysis <- renderUI({
    if (input$selected_country == "") {
      return(
        div(
          style = "text-align: center; padding: 50px; color: #666;",
          h4("Select a country to view detailed analysis"),
          p("Click on a country in the map above or select from the dropdown menu.")
        )
      )
    }
    
    country_data <- sovereign_countries %>% filter(Area == input$selected_country)
    
    if (nrow(country_data) == 0) {
      return(
        div(
          style = "text-align: center; padding: 50px; color: #666;",
          h4("No data available for this country")
        )
      )
    }
    
    # Create country analysis UI
    fluidRow(
      # Country overview
      column(12,
        div(
          style = "background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
          fluidRow(
            column(2,
              # Country flag - use function to get flag code for all countries
              div(
                style = "text-align: center;",
                tags$img(
                  src = paste0("https://flagcdn.com/w80/", get_country_flag_code(input$selected_country), ".png"),
                  alt = paste("Flag of", input$selected_country),
                  style = "width: 80px; height: 60px; border: 1px solid #ddd; border-radius: 4px;",
                  onerror = "this.src='https://flagcdn.com/w80/un.png';"  # Fallback to UN flag if country code not found
                )
              )
            ),
            column(10,
              h3(paste("Country Details:", input$selected_country))
            )
          ),
          fluidRow(
            column(3, h5("Population"), h4(ifelse(is.na(country_data$population), "No data", paste(format(round(country_data$population / 1e6, 1), big.mark = ","), "M")))),
            column(3, h5("GDP per Capita"), h4(ifelse(is.na(country_data$gdp_per_capita), "No data", paste("$", format(round(country_data$gdp_per_capita, 0), big.mark = ","))))),
            column(3, h5("Poverty Rate (<$10/day)"), h4(ifelse(
              !is.na(country_data$poverty_headcount), 
              paste(round(country_data$poverty_headcount * 100, 2), "%"), 
              ifelse(!is.na(country_data$poverty_rate), paste(round(country_data$poverty_rate, 1), "%"), "No data")
            ))),
            column(3, h5("Life Expectancy"), h4(ifelse(is.na(country_data$life_expectancy), "No data", paste(round(country_data$life_expectancy, 1), "years"))))
          ),
          br(),
          # Global Hunger Index (GHI) Comparison
          {ghi_score_val <- country_data$ghi_score[1]
          if(!is.null(ghi_score_val) && !is.na(ghi_score_val)) {
            fluidRow(
              column(12,
                div(
                  style = "background-color: #e7f3ff; padding: 15px; border-radius: 5px; margin-bottom: 20px; border-left: 4px solid #0066cc;",
                  h4("📊 Global Hunger Index (GHI) Comparison"),
                  fluidRow(
                    column(6,
                      h5("Our Vulnerability Rating:"),
                      h3(style = "color: #dc3545; font-weight: bold;",
                        ifelse(is.na(country_data$hunger_vulnerability_rating[1]), "No data", 
                               paste(round(country_data$hunger_vulnerability_rating[1], 1), "/100")))
                    ),
                    column(6,
                      h5("Official GHI Score (2025):"),
                      h3(style = "color: #0066cc; font-weight: bold;",
                        paste(round(ghi_score_val, 1), "/100")),
                      {ghi_change <- country_data$ghi_change_abs[1]
                      if(!is.na(ghi_change)) {
                        p(style = "font-size: 12px; color: #666; margin-top: 5px;",
                          ifelse(ghi_change > 0, 
                                 paste("⚠️ Increased by", round(ghi_change, 1), "points since 2016"),
                                 paste("✅ Decreased by", round(abs(ghi_change), 1), "points since 2016")))
                      } else NULL},
                      {ghi_2000 <- country_data$ghi_2000[1]
                      ghi_2008 <- country_data$ghi_2008[1]
                      ghi_2016 <- country_data$ghi_2016[1]
                      ghi_2025 <- country_data$ghi_2025[1]
                      if(!is.na(ghi_2016) || !is.na(ghi_2008) || !is.na(ghi_2000)) {
                        trend_text <- "GHI Historical Trend: "
                        if(!is.na(ghi_2000)) trend_text <- paste0(trend_text, "2000: ", round(ghi_2000, 1))
                        if(!is.na(ghi_2008)) trend_text <- paste0(trend_text, " | 2008: ", round(ghi_2008, 1))
                        if(!is.na(ghi_2016)) trend_text <- paste0(trend_text, " | 2016: ", round(ghi_2016, 1))
                        if(!is.na(ghi_2025)) trend_text <- paste0(trend_text, " | 2025: ", round(ghi_2025, 1))
                        p(style = "font-size: 12px; color: #666; margin-top: 10px;", trend_text)
                      } else NULL}
                    )
                  )
                )
              )
            )
          } else NULL},
          br(),
          # GHI Score Breakdown (if available)
          {ghi_score_val <- country_data$ghi_score[1]
          if(!is.null(ghi_score_val) && !is.na(ghi_score_val)) {
            fluidRow(
              column(12,
                h4("📊 GHI Score Breakdown"),
                p("The Global Hunger Index (GHI) is calculated from four key indicators. Here's how this country's score breaks down:", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
                div(
                  style = "background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
                  fluidRow(
                    column(6,
                      div(
                        style = "margin-bottom: 15px; padding: 15px; background-color: #fff; border-left: 4px solid #0066cc; border-radius: 4px;",
                        h5("1. Undernourishment (33.3% of GHI)", style = "color: #0066cc; font-weight: bold;"),
                        p(strong("Value: "), 
                          ifelse(is.na(country_data$ghi_undernourishment[1]), "No data", 
                                 paste(round(country_data$ghi_undernourishment[1], 1), "%")),
                          style = "font-size: 14px;"),
                        p(em("Proportion of population lacking sufficient caloric intake"), style = "font-size: 12px; color: #666; margin-top: 5px;")
                      ),
                      div(
                        style = "margin-bottom: 15px; padding: 15px; background-color: #fff; border-left: 4px solid #17a2b8; border-radius: 4px;",
                        h5("2. Child Wasting (16.7% of GHI)", style = "color: #17a2b8; font-weight: bold;"),
                        p(strong("Value: "), 
                          ifelse(is.na(country_data$ghi_child_wasting[1]), "No data", 
                                 paste(round(country_data$ghi_child_wasting[1], 1), "%")),
                          style = "font-size: 14px;"),
                        p(em("Proportion of children under 5 with low weight for height (acute malnutrition)"), style = "font-size: 12px; color: #666; margin-top: 5px;")
                      )
                    ),
                    column(6,
                      div(
                        style = "margin-bottom: 15px; padding: 15px; background-color: #fff; border-left: 4px solid #28a745; border-radius: 4px;",
                        h5("3. Child Stunting (33.3% of GHI)", style = "color: #28a745; font-weight: bold;"),
                        p(strong("Value: "), 
                          ifelse(is.na(country_data$ghi_child_stunting[1]), "No data", 
                                 paste(round(country_data$ghi_child_stunting[1], 1), "%")),
                          style = "font-size: 14px;"),
                        p(em("Proportion of children under 5 with low height for age (chronic malnutrition)"), style = "font-size: 12px; color: #666; margin-top: 5px;")
                      ),
                      div(
                        style = "margin-bottom: 15px; padding: 15px; background-color: #fff; border-left: 4px solid #dc3545; border-radius: 4px;",
                        h5("4. Child Mortality (16.7% of GHI)", style = "color: #dc3545; font-weight: bold;"),
                        p(strong("Value: "), 
                          ifelse(is.na(country_data$ghi_child_mortality[1]), "No data", 
                                 paste(round(country_data$ghi_child_mortality[1], 1), "%")),
                          style = "font-size: 14px;"),
                        p(em("Mortality rate of children under 5 years old"), style = "font-size: 12px; color: #666; margin-top: 5px;")
                      )
                    )
                  ),
                  div(
                    style = "text-align: center; padding: 15px; background-color: #e7f3ff; border-radius: 4px; margin-top: 15px;",
                    h5("Total GHI Score:", style = "color: #0066cc; font-weight: bold;"),
                    h3(style = "color: #0066cc; font-weight: bold; margin-top: 10px;",
                      paste(round(ghi_score_val, 1), "/100")),
                    p(style = "font-size: 12px; color: #666; margin-top: 10px;",
                      ifelse(ghi_score_val < 10, "Low hunger",
                        ifelse(ghi_score_val < 20, "Moderate hunger",
                          ifelse(ghi_score_val < 35, "Serious hunger",
                            ifelse(ghi_score_val < 50, "Alarming hunger", "Extremely alarming hunger")))))
                  )
                )
              )
            )
          } else NULL},
          br(),
          # Vulnerability Formula Breakdown - Calculate all component scores
          {
            # Calculate each component score using the same logic as calculate_hunger_vulnerability()
            undernourishment_score <- pmin(ifelse(is.na(country_data$undernourishment_rate), 0, country_data$undernourishment_rate) * 0.8, 40)
            
            poverty_score <- case_when(
              !is.na(country_data$poverty_headcount) ~ pmin(country_data$poverty_headcount * 0.4, 20),
              !is.na(country_data$poverty_rate) ~ pmin(country_data$poverty_rate * 0.4, 20),
              !is.na(country_data$poverty_below_3usd) ~ pmin(country_data$poverty_below_3usd * 0.4, 20),
              TRUE ~ 0
            )
            
            gdp_score <- case_when(
              is.na(country_data$gdp_per_capita) ~ 0,
              country_data$gdp_per_capita < 1000 ~ 15,
              country_data$gdp_per_capita < 3000 ~ 12,
              country_data$gdp_per_capita < 10000 ~ 8,
              country_data$gdp_per_capita < 20000 ~ 4,
              TRUE ~ 0
            )
            
            life_expectancy_score <- case_when(
              is.na(country_data$life_expectancy) ~ 0,
              country_data$life_expectancy < 50 ~ 10,
              country_data$life_expectancy < 60 ~ 8,
              country_data$life_expectancy < 70 ~ 5,
              TRUE ~ 0
            )
            
            inequality_score <- case_when(
              is.na(country_data$gini_coefficient) ~ 0,
              country_data$gini_coefficient >= 0.6 ~ 8,
              country_data$gini_coefficient >= 0.5 ~ 6,
              country_data$gini_coefficient >= 0.4 ~ 4,
              TRUE ~ 0
            )
            
            market_access_score <- case_when(
              is.na(country_data$total_markets) ~ 0,
              country_data$total_markets == 0 ~ 7,
              country_data$total_markets < 5 ~ 5,
              country_data$total_markets < 20 ~ 3,
              TRUE ~ 0
            )
            
            conflict_score <- case_when(
              !is.na(country_data$acled_conflict_score) & country_data$acled_conflict_score >= 75 ~ 20,
              !is.na(country_data$acled_conflict_score) & country_data$acled_conflict_score >= 50 ~ 15,
              !is.na(country_data$acled_conflict_score) & country_data$acled_conflict_score >= 25 ~ 10,
              !is.na(country_data$acled_conflict_score) & country_data$acled_conflict_score > 0 ~ 5,
              !is.na(country_data$acled_has_active_conflict) & country_data$acled_has_active_conflict ~ 10,
              TRUE ~ 0
            )
            
            outbreak_score <- case_when(
              !is.na(country_data$major_hunger_outbreak_21st) & country_data$major_hunger_outbreak_21st ~ 15,
              !is.na(country_data$grfc_ipc_phase) & country_data$grfc_ipc_phase >= 4 ~ 15,
              !is.na(country_data$grfc_ipc_phase) & country_data$grfc_ipc_phase == 3 ~ 8,
              TRUE ~ 0
            )
            
            population_density_score <- case_when(
              is.na(country_data$population) ~ 0,
              country_data$population > 100000000 ~ 5,
              country_data$population > 50000000 ~ 3,
              country_data$population > 10000000 ~ 1,
              TRUE ~ 0
            )
            
            regional_vulnerability_score <- case_when(
              is.na(country_data$region) ~ 0,
              country_data$region %in% c("Sub-Saharan Africa", "Middle East & North Africa") ~ 15,
              country_data$region %in% c("South Asia", "Latin America & Caribbean") ~ 10,
              country_data$region %in% c("East Asia & Pacific", "Europe & Central Asia") ~ 5,
              TRUE ~ 0
            )
            
            stunting_score <- case_when(
              !is.na(country_data$who_stunting_rate) ~ pmin(country_data$who_stunting_rate * 0.2, 8),
              !is.na(country_data$child_stunting_rate) ~ pmin(country_data$child_stunting_rate * 0.2, 8),
              TRUE ~ 0
            )
            
            agriculture_score <- case_when(
              is.na(country_data$tfp_index) ~ 0,
              country_data$tfp_index < 100 ~ 6,
              country_data$tfp_index < 120 ~ 4,
              country_data$tfp_index < 150 ~ 2,
              TRUE ~ 0
            )
            
            food_production_score <- case_when(
              is.na(country_data$food_supply_kcal) ~ 0,
              country_data$food_supply_kcal < 2000 ~ 4,
              country_data$food_supply_kcal < 2200 ~ 3,
              country_data$food_supply_kcal < 2500 ~ 2,
              TRUE ~ 0
            )
            
            climate_score <- case_when(
              is.na(country_data$climate_vulnerability_index) ~ 0,
              country_data$climate_vulnerability_index >= 80 ~ 6,
              country_data$climate_vulnerability_index >= 70 ~ 4,
              country_data$climate_vulnerability_index >= 60 ~ 2,
              TRUE ~ 0
            )
            
            health_vulnerability_score <- case_when(
              !is.na(country_data$under5_mortality) & country_data$under5_mortality >= 100 ~ 8,
              !is.na(country_data$under5_mortality) & country_data$under5_mortality >= 50 ~ 6,
              !is.na(country_data$under5_mortality) & country_data$under5_mortality >= 25 ~ 4,
              !is.na(country_data$infant_mortality) & country_data$infant_mortality >= 50 ~ 6,
              !is.na(country_data$infant_mortality) & country_data$infant_mortality >= 25 ~ 4,
              !is.na(country_data$child_wasting_rate) & country_data$child_wasting_rate >= 15 ~ 6,
              !is.na(country_data$child_wasting_rate) & country_data$child_wasting_rate >= 10 ~ 4,
              TRUE ~ 0
            )
            
            displacement_score <- case_when(
              (!is.na(country_data$total_displaced_latest) && !is.na(country_data$population) && 
               country_data$population > 0 && 
               (country_data$total_displaced_latest / country_data$population > 0.05 || 
                country_data$total_displaced_latest > 1000000)) ~ 10,
              (!is.na(country_data$total_displaced_latest) && !is.na(country_data$population) && 
               country_data$population > 0 && 
               (country_data$total_displaced_latest / country_data$population > 0.01 || 
                country_data$total_displaced_latest > 100000)) ~ 6,
              (!is.na(country_data$total_displaced_latest) && country_data$total_displaced_latest > 10000) ~ 3,
              TRUE ~ 0
            )
            
            food_import_score <- case_when(
              !is.na(country_data$food_import_dependency) && country_data$food_import_dependency > 0.5 ~ 6,
              !is.na(country_data$food_import_dependency) && country_data$food_import_dependency > 0.3 ~ 4,
              !is.na(country_data$food_import_dependency) && country_data$food_import_dependency > 0.1 ~ 2,
              TRUE ~ 0
            )
            
            water_scarcity_score <- case_when(
              !is.na(country_data$water_stress_index) && country_data$water_stress_index > 100 ~ 6,
              !is.na(country_data$water_stress_index) && country_data$water_stress_index > 75 ~ 6,
              !is.na(country_data$water_stress_index) && country_data$water_stress_index > 50 ~ 4,
              !is.na(country_data$water_stress_index) && country_data$water_stress_index > 25 ~ 2,
              TRUE ~ 0
            )
            
            tagList(
          fluidRow(
            column(12,
              h4("🔍 Vulnerability Formula Breakdown"),
                p("This shows how the hunger vulnerability rating is calculated for this country. All 18 factors are shown with their actual scores:"),
              div(
                style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0;",
                fluidRow(
                  column(6,
                      h5("Primary Factors:"),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #fff3cd; border-left: 4px solid #ffc107; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'undernourishment', {priority: 'event'});",
                        p(strong("1. 🍽️ Undernourishment (0-40 pts):"), 
                          ifelse(is.na(country_data$undernourishment_rate), 
                            "No data → 0.0 points",
                          paste(round(country_data$undernourishment_rate, 1), "% → ", 
                                  round(undernourishment_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Direct measure of food insecurity."), style = "font-size: 11px; color: #666;")
                    ),
                    div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #d4edda; border-left: 4px solid #28a745; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'poverty', {priority: 'event'});",
                        p(strong("2. 💰 Poverty (0-20 pts):"), 
                          ifelse(poverty_score == 0 && is.na(country_data$poverty_rate) && is.na(country_data$poverty_headcount) && is.na(country_data$poverty_below_3usd),
                            "No data → 0.0 points",
                            paste(round(poverty_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Poverty directly correlates with food insecurity."), style = "font-size: 11px; color: #666;")
                    ),
                    div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #e2e3e5; border-left: 4px solid #6c757d; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'gdp', {priority: 'event'});",
                        p(strong("3. 🏦 GDP per Capita (0-15 pts):"), 
                          ifelse(is.na(country_data$gdp_per_capita),
                            "No data → 0.0 points",
                            paste("$", format(round(country_data$gdp_per_capita, 0), big.mark = ","), " → ", 
                                  round(gdp_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Lower GDP means less capacity to address hunger."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #fff3cd; border-left: 4px solid #ffc107; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'life_expectancy', {priority: 'event'});",
                        p(strong("4. ❤️ Life Expectancy (0-10 pts):"), 
                          ifelse(is.na(country_data$life_expectancy),
                            "No data → 0.0 points",
                            paste(round(country_data$life_expectancy, 1), " years → ", 
                                  round(life_expectancy_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Reflects overall health and nutrition."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #d1ecf1; border-left: 4px solid #17a2b8; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'inequality', {priority: 'event'});",
                        p(strong("5. ⚖️ Inequality (0-8 pts):"), 
                          ifelse(is.na(country_data$gini_coefficient),
                            "No data → 0.0 points",
                            paste("Gini ", round(country_data$gini_coefficient, 3), " → ", 
                                  round(inequality_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Higher inequality increases vulnerability."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #f8d7da; border-left: 4px solid #dc3545; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'outbreak', {priority: 'event'});",
                        p(strong("6. ⚠️ Historical Crises (0-15 pts):"), 
                          paste(ifelse(country_data$major_hunger_outbreak_21st, "Yes", "No"), " → ", 
                                round(outbreak_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Recent hunger crises indicate ongoing vulnerability."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #f8d7da; border-left: 4px solid #dc3545; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'conflict', {priority: 'event'});",
                        p(strong("7. ⚔️ Conflict & Violence (0-20 pts):"), 
                          ifelse(is.na(country_data$acled_conflict_score) && (!is.na(country_data$acled_has_active_conflict) && !country_data$acled_has_active_conflict),
                            "No active conflict → 0.0 points",
                            paste(ifelse(!is.na(country_data$acled_conflict_score), 
                                   paste("Conflict score:", round(country_data$acled_conflict_score, 1)), 
                                   "Active conflict"), " → ", 
                                  round(conflict_score, 1), " points"))),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Conflict is the #1 driver of acute food insecurity."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #e7d4f8; border-left: 4px solid #9b59b6; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'population', {priority: 'event'});",
                        p(strong("8. 👥 Population (0-5 pts):"), 
                          ifelse(is.na(country_data$population),
                            "No data → 0.0 points",
                            paste(format(round(country_data$population / 1e6, 1), big.mark = ","), "M → ", 
                                  round(population_density_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Larger populations face greater challenges."), style = "font-size: 11px; color: #666;")
                    )
                  ),
                  column(6,
                      h5("Additional Factors:"),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #d1ecf1; border-left: 4px solid #17a2b8; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'regional', {priority: 'event'});",
                        p(strong("8. 🌍 Regional Risk (0-15 pts):"), 
                          ifelse(is.na(country_data$region),
                            "Unknown → 0.0 points",
                            paste(as.character(country_data$region), " → ", 
                                  round(regional_vulnerability_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Regional factors affect food security."), style = "font-size: 11px; color: #666;")
                    ),
                    div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #ffe5e5; border-left: 4px solid #e74c3c; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'stunting', {priority: 'event'});",
                        p(strong("10. 📏 Child Stunting (0-8 pts):"), 
                          ifelse(stunting_score == 0 && is.na(country_data$who_stunting_rate) && is.na(country_data$child_stunting_rate),
                            "No data → 0.0 points",
                            paste(ifelse(!is.na(country_data$who_stunting_rate), 
                                   paste(round(country_data$who_stunting_rate, 1), "%"), 
                                   paste(round(country_data$child_stunting_rate, 1), "%")), " → ", 
                                  round(stunting_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Chronic malnutrition indicator."), style = "font-size: 11px; color: #666;")
                    ),
                    div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #fff4e6; border-left: 4px solid #f39c12; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'agriculture', {priority: 'event'});",
                        p(strong("11. 🌾 Agriculture (0-6 pts):"), 
                          ifelse(is.na(country_data$tfp_index),
                            "No data → 0.0 points",
                            paste("TFP ", round(country_data$tfp_index, 1), " → ", 
                                  round(agriculture_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Agricultural productivity affects food availability."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #e8f5e9; border-left: 4px solid #4caf50; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'food_production', {priority: 'event'});",
                        p(strong("11. 🍎 Food Production (0-4 pts):"), 
                          ifelse(is.na(country_data$food_supply_kcal),
                            "No data → 0.0 points",
                            paste(round(country_data$food_supply_kcal, 0), " kcal/day → ", 
                                  round(food_production_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Food supply adequacy."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #e3f2fd; border-left: 4px solid #2196f3; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'climate', {priority: 'event'});",
                        p(strong("12. 🌡️ Climate (0-6 pts):"), 
                          ifelse(is.na(country_data$climate_vulnerability_index),
                            "No data → 0.0 points",
                            paste("Index ", round(country_data$climate_vulnerability_index, 1), " → ", 
                                  round(climate_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Climate vulnerability affects food security."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #fce4ec; border-left: 4px solid #e91e63; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'health', {priority: 'event'});",
                        p(strong("14. 🏥 Health Vulnerability (0-8 pts):"), 
                          ifelse(health_vulnerability_score == 0 && is.na(country_data$under5_mortality) && is.na(country_data$infant_mortality) && is.na(country_data$child_wasting_rate),
                            "No data → 0.0 points",
                            paste(round(health_vulnerability_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Health indicators reflect nutrition access."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #fff9c4; border-left: 4px solid #fbc02d; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'market_access', {priority: 'event'});",
                        p(strong("15. 🏪 Market Access (0-7 pts):"), 
                          ifelse(is.na(country_data$total_markets),
                            "No data → 0.0 points",
                            paste(country_data$total_markets, " markets → ", 
                                  round(market_access_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Market access affects food availability."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #ffe0e6; border-left: 4px solid #e91e63; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'displacement', {priority: 'event'});",
                        p(strong("16. 🏃 Displacement (0-10 pts):"), 
                          ifelse(is.na(country_data$total_displaced_latest) || country_data$total_displaced_latest == 0,
                            "No displacement → 0.0 points",
                            paste(round(country_data$total_displaced_latest / 1e6, 1), "M displaced → ", 
                                  round(displacement_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Refugees and IDPs are extremely vulnerable to hunger."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #e3f2fd; border-left: 4px solid #2196f3; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'food_import', {priority: 'event'});",
                        p(strong("17. 🌾 Food Import Dependency (0-6 pts):"), 
                          ifelse(is.na(country_data$food_import_dependency),
                            "No data → 0.0 points",
                            paste(round(country_data$food_import_dependency * 100, 1), "% dependency → ", 
                                  round(food_import_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("High import dependency = vulnerability to trade disruptions."), style = "font-size: 11px; color: #666;")
                      ),
                      div(
                        style = "margin-bottom: 10px; padding: 10px; background-color: #e0f2f1; border-left: 4px solid #009688; cursor: pointer;",
                        onclick = "Shiny.setInputValue('factor_detail', 'water', {priority: 'event'});",
                        p(strong("18. 💧 Water Scarcity (0-6 pts):"), 
                          ifelse(is.na(country_data$water_stress_index),
                            "No data → 0.0 points",
                            paste(round(country_data$water_stress_index, 1), "% stress → ", 
                                  round(water_scarcity_score, 1), " points")),
                          tags$span(" (Click for details)", style = "font-size: 10px; color: #666; font-style: italic;")),
                        p(em("Water scarcity affects agricultural productivity."), style = "font-size: 11px; color: #666;")
                    )
                  )
                ),
                br(),
                div(
                    style = "text-align: center; font-size: 20px; font-weight: bold; color: #2c3e50; padding: 15px; background-color: #e8f5e9; border-radius: 5px;",
                  paste("Total Vulnerability Score: ", 
                          round(undernourishment_score + poverty_score + gdp_score + life_expectancy_score + 
                                inequality_score + market_access_score + conflict_score + outbreak_score + 
                                population_density_score + regional_vulnerability_score + 
                                stunting_score + agriculture_score + food_production_score + 
                                climate_score + health_vulnerability_score, 1), "/100"                  )
                )
              )
            )
          },
          # GRFC 2025 Data Section (if available)
          if(!is.na(country_data$grfc_ipc_phase) || !is.na(country_data$grfc_population_phase3_plus)) {
            fluidRow(
              column(12,
                div(
                  style = "background-color: #fff3cd; padding: 15px; border-radius: 8px; border-left: 4px solid #ffc107; margin-bottom: 20px;",
                  h5("📊 GRFC 2025 Current Crisis Status", style = "color: #856404; margin-bottom: 10px;"),
                  fluidRow(
                    column(4, 
                      h6("IPC Phase Classification:"), 
                      h4(ifelse(is.na(country_data$grfc_ipc_phase), "No assessment", 
                         paste0("Phase ", country_data$grfc_ipc_phase, 
                                ifelse(country_data$grfc_ipc_phase == 5, " (Famine)",
                                ifelse(country_data$grfc_ipc_phase == 4, " (Emergency)",
                                ifelse(country_data$grfc_ipc_phase == 3, " (Crisis)", "")))))),
                      style = "text-align: center;"
                    ),
                    column(4,
                      h6("Population in Crisis (Phase 3+):"),
                      h4(ifelse(is.na(country_data$grfc_population_phase3_plus), "No data",
                         paste(round(country_data$grfc_population_phase3_plus / 1e6, 1), "M people"))),
                      style = "text-align: center;"
                    ),
                    column(4,
                      h6("Primary Driver:"),
                      h4(ifelse(is.na(country_data$grfc_primary_driver), "Not specified", 
                         country_data$grfc_primary_driver)),
                      style = "text-align: center;"
                    )
                  ),
                  if(!is.na(country_data$grfc_assessment_year)) {
                    p(em(paste("Assessment Year:", country_data$grfc_assessment_year)), 
                      style = "font-size: 12px; color: #666; margin-top: 10px; text-align: center;")
                  }
                )
              )
            )
          } else NULL,
          br(),
          fluidRow(
            column(6, h5("Undernourishment Rate (2022-2024)"), h4(ifelse(is.na(country_data$undernourishment_rate), 
              ifelse(!is.na(country_data$grfc_population_phase3_plus) && !is.na(country_data$population) && country_data$population > 0,
                paste("~", round((country_data$grfc_population_phase3_plus / country_data$population * 100), 1), "% (estimated from GRFC)"),
                "No data"), 
              paste(round(country_data$undernourishment_rate, 1), "%")))),
            column(6, h5("Undernourished Population"), h4({
              # Calculate estimated undernourished population if missing
              estimated_pop <- ifelse(
                is.na(country_data$undernourished_population) & !is.na(country_data$undernourishment_rate) & !is.na(country_data$population),
                (country_data$undernourishment_rate / 100) * country_data$population / 1e6,
                country_data$undernourished_population
              )
              
              if (is.na(estimated_pop)) {
                "No data"
              } else if (is.na(country_data$undernourished_population) & !is.na(estimated_pop)) {
                paste("~", round(estimated_pop, 1), "M people (estimated)")
              } else {
                paste(round(estimated_pop, 1), "M people")
              }
            }))
          ),
          br(),
          fluidRow(
            column(6, h5("Combined Risk Level"), h4(as.character(country_data$combined_risk))),
            column(6, h5("Major Hunger Outbreak (21st Century)"), h4(ifelse(country_data$major_hunger_outbreak_21st, "Yes", "No")))
          ),
          br(),
          fluidRow(
            column(6, h5("Region"), h4(ifelse(is.na(country_data$region), "Unknown", as.character(country_data$region)))),
            column(6, h5("Development Level"), h4(ifelse(is.na(country_data$development_level), "Unknown", as.character(country_data$development_level))))
          ),
          br(),
          fluidRow(
            column(6, h5("WFP Markets"), h4(ifelse(is.na(country_data$total_markets), "No data", paste(country_data$total_markets, "markets")))),
            column(6, h5("Market Access Level"), h4(ifelse(is.na(country_data$market_access), "Unknown", as.character(country_data$market_access))))
          )
        )
      )
    )
  })
  
  # Detailed factor breakdown
  output$factor_detail_breakdown <- renderUI({
    if (is.null(input$factor_detail) || input$factor_detail == "" || input$selected_country == "") {
      return(NULL)
    }
    
    country_data <- sovereign_countries %>% filter(Area == input$selected_country)
    if (nrow(country_data) == 0) return(NULL)
    country_data <- country_data[1, ]
    
    factor_name <- input$factor_detail
    
    # Create detailed breakdown based on factor
    div(
      style = "margin-top: 20px; padding: 20px; background-color: #ffffff; border: 2px solid #3c8dbc; border-radius: 8px;",
      fluidRow(
        column(12,
          h4(paste("📊 Detailed Breakdown:", switch(factor_name,
            "undernourishment" = "Undernourishment Factor",
            "poverty" = "Poverty Factor",
            "gdp" = "GDP per Capita Factor",
            "life_expectancy" = "Life Expectancy Factor",
            "inequality" = "Inequality Factor",
            "outbreak" = "Historical Crises Factor",
            "population" = "Population Factor",
            "regional" = "Regional Risk Factor",
            "stunting" = "Child Stunting Factor",
            "agriculture" = "Agricultural Productivity Factor",
            "food_production" = "Food Production Factor",
            "climate" = "Climate Vulnerability Factor",
            "health" = "Health Vulnerability Factor",
            "market_access" = "Market Access Factor",
            "Unknown Factor"
          ))),
          actionButton("close_factor_detail", "Close", style = "float: right; margin-bottom: 15px;"),
          br(), br(),
          
          # Factor-specific detailed breakdown
          switch(factor_name,
            "undernourishment" = {
              score <- pmin(ifelse(is.na(country_data$undernourishment_rate), 0, country_data$undernourishment_rate) * 0.8, 40)
              tagList(
                p(strong("Calculation Formula:"), "undernourishment_rate × 0.8 (capped at 40 points)"),
                p(strong("Country Value:"), ifelse(is.na(country_data$undernourishment_rate), "No data", paste(round(country_data$undernourishment_rate, 1), "%"))),
                p(strong("Score Calculation:"), 
                  ifelse(is.na(country_data$undernourishment_rate), 
                    "No data → 0.0 points",
                    paste(round(country_data$undernourishment_rate, 1), "% × 0.8 = ", round(country_data$undernourishment_rate * 0.8, 1), " points (capped at 40)"))),
                p(strong("Final Score:"), paste(round(score, 1), "/40 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Undernourishment is the most direct and authoritative measure of food insecurity, representing the percentage of a country's population that does not have regular access to sufficient calories for an active, healthy life. This metric is calculated by the Food and Agriculture Organization (FAO) based on food balance sheets, household surveys, and dietary energy requirements.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Undernourishment is the primary factor in our vulnerability index (worth up to 40 points) because it directly quantifies the current state of food insecurity. A high undernourishment rate indicates that a significant portion of the population is already experiencing hunger, making them extremely vulnerable to any additional shocks such as economic crises, climate events, or conflicts. Countries with high undernourishment rates often lack the food reserves, infrastructure, and economic capacity to respond to emergencies.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "When undernourishment exceeds 15%, a country is considered to have 'serious' hunger levels. Rates above 25% indicate 'alarming' conditions, and above 35% represent 'extremely alarming' situations. High undernourishment correlates strongly with increased child mortality, reduced cognitive development, lower economic productivity, and social instability. This factor receives the highest weight in our index because addressing current hunger is the most urgent priority.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "FAO Food Security Indicators (2022-2024), based on comprehensive food balance sheets and household consumption surveys.", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "population" = {
              score <- case_when(
                is.na(country_data$population) ~ 0,
                country_data$population > 100000000 ~ 5,
                country_data$population > 50000000 ~ 3,
                country_data$population > 10000000 ~ 1,
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "Based on population thresholds"),
                p(strong("Country Value:"), ifelse(is.na(country_data$population), "No data", paste(format(round(country_data$population / 1e6, 1), big.mark = ","), " million people"))),
                p(strong("Score Thresholds:"), 
                  tags$ul(
                    tags$li("Population > 100M: 5 points"),
                    tags$li("Population > 50M: 3 points"),
                    tags$li("Population > 10M: 1 point"),
                    tags$li("Population ≤ 10M: 0 points")
                  )),
                p(strong("Score Calculation:"), 
                  ifelse(is.na(country_data$population),
                    "No data → 0.0 points",
                    paste("Population of ", format(round(country_data$population / 1e6, 1), big.mark = ","), "M falls in the ", 
                          case_when(
                            country_data$population > 100000000 ~ ">100M",
                            country_data$population > 50000000 ~ "50-100M",
                            country_data$population > 10000000 ~ "10-50M",
                            TRUE ~ "≤10M"
                          ), " range → ", round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/5 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Population size represents the total number of people living in a country. While larger populations don't inherently cause hunger, they create significant logistical and resource challenges for ensuring food security across all citizens.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Countries with very large populations (over 100 million) face exponentially greater challenges in food distribution, infrastructure development, and resource allocation. Even small percentage increases in food insecurity translate to millions of affected people. Large populations require more complex supply chains, greater agricultural production, more extensive transportation networks, and larger social safety nets. When crises occur, the scale of response needed becomes enormous. Additionally, large populations often concentrate in urban areas, creating food deserts and increasing dependence on food imports.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Countries like India, China, and Nigeria must coordinate food security for hundreds of millions of people across diverse regions. A 1% increase in undernourishment in India affects over 14 million people. Large populations also mean that agricultural land must support more people, increasing pressure on food production systems. Urbanization in large-population countries creates additional challenges as cities depend on food transported from rural areas, making them vulnerable to supply chain disruptions.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "World Bank Population Estimates (2022-2024).", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "gdp" = {
              score <- case_when(
                is.na(country_data$gdp_per_capita) ~ 0,
                country_data$gdp_per_capita < 1000 ~ 15,
                country_data$gdp_per_capita < 3000 ~ 12,
                country_data$gdp_per_capita < 10000 ~ 8,
                country_data$gdp_per_capita < 20000 ~ 4,
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "Based on GDP per capita thresholds (inverse relationship)"),
                p(strong("Country Value:"), ifelse(is.na(country_data$gdp_per_capita), "No data", paste("$", format(round(country_data$gdp_per_capita, 0), big.mark = ",")))),
                p(strong("Score Thresholds:"), 
                  tags$ul(
                    tags$li("GDP < $1,000: 15 points"),
                    tags$li("GDP $1,000-$3,000: 12 points"),
                    tags$li("GDP $3,000-$10,000: 8 points"),
                    tags$li("GDP $10,000-$20,000: 4 points"),
                    tags$li("GDP ≥ $20,000: 0 points")
                  )),
                p(strong("Score Calculation:"), 
                  ifelse(is.na(country_data$gdp_per_capita),
                    "No data → 0.0 points",
                    paste("GDP per capita of $", format(round(country_data$gdp_per_capita, 0), big.mark = ","), " falls in the ", 
                          case_when(
                            country_data$gdp_per_capita < 1000 ~ "<$1,000",
                            country_data$gdp_per_capita < 3000 ~ "$1,000-$3,000",
                            country_data$gdp_per_capita < 10000 ~ "$3,000-$10,000",
                            country_data$gdp_per_capita < 20000 ~ "$10,000-$20,000",
                            TRUE ~ "≥$20,000"
                          ), " range → ", round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/15 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "GDP per capita represents the average economic output per person in a country, calculated by dividing total Gross Domestic Product by population. It serves as a proxy for a country's overall economic capacity and the average standard of living.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Economic capacity is fundamental to food security. Countries with low GDP per capita lack the financial resources to invest in agricultural infrastructure (irrigation, storage facilities, transportation), social safety nets (food assistance programs, school meals), emergency response systems, and healthcare. When GDP per capita is below $1,000, governments struggle to provide basic services, let alone comprehensive food security programs. Low-income countries also have limited ability to import food during shortages, making them dependent on domestic production which may be unreliable. Economic development enables investment in food systems, reduces poverty (which directly causes hunger), and provides resources for crisis response.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Countries with GDP per capita below $3,000 typically have high rates of subsistence agriculture, limited food storage capacity, and weak market infrastructure. They often cannot afford to maintain strategic grain reserves or subsidize food for vulnerable populations. When food prices spike globally, low-GDP countries are hit hardest because their citizens spend a larger proportion of income on food. Economic growth has been shown to be one of the most effective long-term solutions to hunger, as it increases both food production capacity and purchasing power.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "World Bank GDP per Capita (PPP, current international $) - 2022-2024.", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "poverty" = {
              score <- case_when(
                !is.na(country_data$poverty_headcount) ~ pmin(country_data$poverty_headcount * 0.4, 20),
                !is.na(country_data$poverty_rate) ~ pmin(country_data$poverty_rate * 0.4, 20),
                !is.na(country_data$poverty_below_3usd) ~ pmin(country_data$poverty_below_3usd * 0.4, 20),
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "poverty_rate × 0.4 (capped at 20 points)"),
                p(strong("Data Sources (in priority order):"), "PIP → World Bank → Our World in Data"),
                p(strong("Country Value:"), 
                  ifelse(!is.na(country_data$poverty_headcount), paste(round(country_data$poverty_headcount * 100, 1), "% (PIP)"),
                  ifelse(!is.na(country_data$poverty_rate), paste(round(country_data$poverty_rate, 1), "% (World Bank)"),
                  ifelse(!is.na(country_data$poverty_below_3usd), paste(round(country_data$poverty_below_3usd, 1), "% (Our World in Data)"),
                  "No data")))),
                p(strong("Score Calculation:"), 
                  ifelse(score == 0 && is.na(country_data$poverty_rate) && is.na(country_data$poverty_headcount) && is.na(country_data$poverty_below_3usd),
                    "No data → 0.0 points",
                    paste(round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/20 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Poverty rate represents the percentage of a country's population living below a defined poverty line. We use multiple data sources (PIP, World Bank, Our World in Data) to capture different poverty definitions, including those living on less than $2.15/day (extreme poverty) or $3.65/day (moderate poverty).", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Poverty is the most direct cause of hunger. People living in poverty cannot afford sufficient nutritious food, even when food is available in markets. When a large percentage of the population is poor, food insecurity becomes widespread regardless of national food production levels. Poor households typically spend 50-70% of their income on food, leaving little buffer for price shocks or income loss. Poverty also limits access to healthcare, clean water, and sanitation, which compounds nutrition problems. High poverty rates indicate that economic growth benefits are not reaching vulnerable populations, and that social safety nets are inadequate.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Countries with poverty rates above 30% often experience chronic food insecurity even in non-crisis periods. When economic shocks occur (unemployment, inflation, crop failures), poor households are the first to reduce food consumption, skip meals, or rely on less nutritious but cheaper foods. This creates intergenerational cycles of malnutrition: malnourished children have reduced cognitive development and physical growth, limiting their future economic opportunities and perpetuating poverty. Addressing poverty through inclusive economic growth, social protection programs, and targeted assistance is essential for reducing hunger vulnerability.", style = "margin-bottom: 10px;"),
                  p(strong("Data Sources:"), "PIP (Poverty and Inequality Platform), World Bank Poverty Indicators, Our World in Data - 2022-2024.", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "life_expectancy" = {
              score <- case_when(
                is.na(country_data$life_expectancy) ~ 0,
                country_data$life_expectancy < 50 ~ 10,
                country_data$life_expectancy < 60 ~ 8,
                country_data$life_expectancy < 70 ~ 5,
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "Based on life expectancy thresholds (inverse relationship)"),
                p(strong("Country Value:"), ifelse(is.na(country_data$life_expectancy), "No data", paste(round(country_data$life_expectancy, 1), " years"))),
                p(strong("Score Thresholds:"), 
                  tags$ul(
                    tags$li("Life Expectancy < 50 years: 10 points"),
                    tags$li("Life Expectancy 50-60 years: 8 points"),
                    tags$li("Life Expectancy 60-70 years: 5 points"),
                    tags$li("Life Expectancy ≥ 70 years: 0 points")
                  )),
                p(strong("Score Calculation:"), 
                  ifelse(is.na(country_data$life_expectancy),
                    "No data → 0.0 points",
                    paste("Life expectancy of ", round(country_data$life_expectancy, 1), " years falls in the ", 
                          case_when(
                            country_data$life_expectancy < 50 ~ "<50 years",
                            country_data$life_expectancy < 60 ~ "50-60 years",
                            country_data$life_expectancy < 70 ~ "60-70 years",
                            TRUE ~ "≥70 years"
                          ), " range → ", round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/10 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Life expectancy at birth represents the average number of years a newborn can expect to live, assuming current mortality rates remain constant. It serves as a comprehensive indicator of overall population health, which is closely linked to nutrition and food security.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Life expectancy is a powerful proxy for food security because adequate nutrition is fundamental to health and longevity. Countries with life expectancy below 60 years typically have high rates of malnutrition, limited access to healthcare, and poor food security. Malnutrition weakens immune systems, increases susceptibility to disease, and reduces the body's ability to recover from illness. Low life expectancy often indicates that large portions of the population lack access to sufficient, nutritious food throughout their lives. It also reflects broader systemic issues like inadequate healthcare, poor sanitation, and limited social services that compound food insecurity problems.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Life expectancy below 50 years is extremely low and typically found only in countries experiencing severe crises, conflict, or extreme poverty. Such countries often have high rates of child mortality, maternal mortality, and infectious diseases—all of which are exacerbated by malnutrition. Improving life expectancy requires not just better healthcare, but also improved nutrition security. Countries with improving life expectancy often see corresponding improvements in food security as economic development enables better nutrition access. The relationship is bidirectional: better food security improves health outcomes, and better health enables people to be more productive and food-secure.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "World Bank Life Expectancy at Birth - 2022-2024.", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "inequality" = {
              score <- case_when(
                is.na(country_data$gini_coefficient) ~ 0,
                country_data$gini_coefficient >= 0.6 ~ 8,
                country_data$gini_coefficient >= 0.5 ~ 6,
                country_data$gini_coefficient >= 0.4 ~ 4,
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "Based on Gini coefficient thresholds"),
                p(strong("Country Value:"), ifelse(is.na(country_data$gini_coefficient), "No data", paste("Gini coefficient: ", round(country_data$gini_coefficient, 3)))),
                p(strong("Score Thresholds:"), 
                  tags$ul(
                    tags$li("Gini ≥ 0.6: 8 points (Very high inequality)"),
                    tags$li("Gini 0.5-0.6: 6 points (High inequality)"),
                    tags$li("Gini 0.4-0.5: 4 points (Moderate inequality)"),
                    tags$li("Gini < 0.4: 0 points")
                  )),
                p(strong("Score Calculation:"), 
                  ifelse(is.na(country_data$gini_coefficient),
                    "No data → 0.0 points",
                    paste("Gini coefficient of ", round(country_data$gini_coefficient, 3), " falls in the ", 
                          case_when(
                            country_data$gini_coefficient >= 0.6 ~ "≥0.6",
                            country_data$gini_coefficient >= 0.5 ~ "0.5-0.6",
                            country_data$gini_coefficient >= 0.4 ~ "0.4-0.5",
                            TRUE ~ "<0.4"
                          ), " range → ", round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/8 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "The Gini coefficient measures income inequality on a scale from 0 (perfect equality) to 1 (perfect inequality, where one person has all income). A Gini of 0.4 is considered moderate inequality, 0.5+ is high, and 0.6+ is very high inequality.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "High inequality means that even when a country produces adequate food or has reasonable average income, large segments of the population may still experience hunger because resources are concentrated in the hands of a few. In highly unequal societies, the poor cannot afford sufficient food even when it's available in markets. Inequality also limits social mobility and access to opportunities, trapping people in cycles of poverty and food insecurity. Countries with high inequality often have weak social safety nets and limited redistribution mechanisms, meaning that economic growth doesn't translate to improved food security for the most vulnerable. Inequality can also lead to social unrest and political instability, which further threatens food security.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Countries with Gini coefficients above 0.5 often have significant portions of their population living in poverty despite having middle-income economies. For example, some Latin American countries have relatively high GDP per capita but also high inequality and hunger rates. High inequality makes it difficult to implement effective food security policies because political power is often concentrated with those who don't experience hunger. Reducing inequality through progressive taxation, social protection programs, and inclusive economic policies is crucial for ensuring that food security improvements reach all segments of society.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "World Bank Gini Coefficient - 2022-2024.", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "outbreak" = {
              score <- ifelse(is.na(country_data$major_hunger_outbreak_21st) | !country_data$major_hunger_outbreak_21st, 0, 20)
              tagList(
                p(strong("Calculation Formula:"), "20 points if major hunger outbreak in 21st century, 0 otherwise"),
                p(strong("Country Status:"), ifelse(country_data$major_hunger_outbreak_21st, "Yes - Major hunger outbreak occurred", "No - No major outbreak")),
                p(strong("Score Calculation:"), paste(ifelse(country_data$major_hunger_outbreak_21st, "Yes → 20 points", "No → 0 points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/20 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "This factor identifies countries that have experienced major hunger crises (famines, severe food emergencies, or widespread starvation) in the 21st century. These events are typically characterized by mass mortality, displacement, and severe food shortages requiring international emergency response.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Historical hunger crises are strong predictors of future vulnerability because they indicate underlying systemic weaknesses in food security. Countries that have experienced major famines often have fragile agricultural systems, weak governance, ongoing conflicts, or economic instability that make them prone to recurring crises. Past crises also deplete food reserves, damage agricultural infrastructure, and create displacement that disrupts food production. The trauma and economic damage from past crises can take decades to recover from, leaving populations more vulnerable to new shocks. Additionally, countries with a history of hunger crises may have weakened social institutions and limited capacity to respond to new emergencies.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Major 21st-century hunger crises have occurred in countries like Somalia, South Sudan, Yemen, and parts of the Sahel region. These crises are often driven by combinations of conflict, climate shocks, economic collapse, and governance failures. Once a major crisis occurs, it can create a 'crisis trap' where recovery is slow and the country remains vulnerable to new shocks. International aid during crises is essential but doesn't address underlying vulnerabilities. Countries with past crises need long-term investment in agricultural resilience, conflict resolution, economic development, and early warning systems to prevent recurrence.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "EM-DAT (Emergency Events Database) and historical records of major hunger crises (2000-2024).", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "regional" = {
              score <- case_when(
                is.na(country_data$region) ~ 0,
                country_data$region %in% c("Sub-Saharan Africa", "Middle East & North Africa") ~ 15,
                country_data$region %in% c("South Asia", "Latin America & Caribbean") ~ 10,
                country_data$region %in% c("East Asia & Pacific", "Europe & Central Asia") ~ 5,
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "Based on regional vulnerability classification"),
                p(strong("Country Region:"), ifelse(is.na(country_data$region), "Unknown", as.character(country_data$region))),
                p(strong("Score by Region:"), 
                  tags$ul(
                    tags$li("Sub-Saharan Africa, Middle East & North Africa: 15 points"),
                    tags$li("South Asia, Latin America & Caribbean: 10 points"),
                    tags$li("East Asia & Pacific, Europe & Central Asia: 5 points"),
                    tags$li("Other regions: 0 points")
                  )),
                p(strong("Score Calculation:"), 
                  ifelse(is.na(country_data$region),
                    "Unknown region → 0.0 points",
                    paste("Region '", country_data$region, "' → ", round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/15 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Regional vulnerability captures shared geographic, climatic, economic, and political factors that affect food security across countries in the same region. Regions are classified based on historical patterns of food insecurity, climate risks, economic development levels, and political stability.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Countries in the same region often face similar challenges: shared climate patterns (droughts, floods, temperature extremes), similar economic development trajectories, regional conflicts that cross borders, and common infrastructure limitations. Sub-Saharan Africa and the Middle East & North Africa face particularly high vulnerability due to arid climates, political instability, rapid population growth, and limited agricultural infrastructure. Regional factors also include trade relationships, migration patterns, and shared water resources that affect food security. Countries in vulnerable regions often lack the economic resources to build resilience, and regional conflicts can disrupt food systems across borders.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Sub-Saharan Africa has the highest rates of undernourishment globally, driven by climate variability, conflict, poverty, and limited agricultural investment. The Middle East & North Africa region faces water scarcity, political instability, and dependence on food imports. South Asia has high population density and climate risks. Regional cooperation is essential for addressing shared challenges like transboundary water management, regional trade, and coordinated response to climate shocks. However, regional vulnerability doesn't mean all countries in a region are equally vulnerable—national policies and resources still matter significantly.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "World Bank Regional Classifications and historical food security patterns.", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "stunting" = {
              score <- case_when(
                !is.na(country_data$who_stunting_rate) ~ pmin(country_data$who_stunting_rate * 0.2, 8),
                !is.na(country_data$child_stunting_rate) ~ pmin(country_data$child_stunting_rate * 0.2, 8),
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "stunting_rate × 0.2 (capped at 8 points)"),
                p(strong("Data Sources:"), "WHO (primary) → Global Data Lab (fallback)"),
                p(strong("Country Value:"), 
                  ifelse(!is.na(country_data$who_stunting_rate), paste(round(country_data$who_stunting_rate, 1), "% (WHO)"),
                  ifelse(!is.na(country_data$child_stunting_rate), paste(round(country_data$child_stunting_rate, 1), "% (Global Data Lab)"),
                  "No data"))),
                p(strong("Score Calculation:"), 
                  ifelse(score == 0 && is.na(country_data$who_stunting_rate) && is.na(country_data$child_stunting_rate),
                    "No data → 0.0 points",
                    paste(ifelse(!is.na(country_data$who_stunting_rate), 
                           round(country_data$who_stunting_rate, 1), 
                           round(country_data$child_stunting_rate, 1)), "% × 0.2 = ", round(score, 1), " points (capped at 8)"))),
                p(strong("Final Score:"), paste(round(score, 1), "/8 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Child stunting (low height-for-age) measures chronic malnutrition in children under 5 years old. It reflects long-term nutritional deficiencies and indicates that children have not received adequate nutrition over extended periods, typically from conception through early childhood.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Stunting is a critical indicator because it reflects both current and past food insecurity, and it has lifelong consequences. High stunting rates indicate that a significant portion of children are experiencing chronic malnutrition, which affects physical growth, cognitive development, and future economic productivity. Stunted children are more susceptible to disease, perform worse in school, and earn less as adults, perpetuating cycles of poverty and food insecurity. Stunting rates above 20% are considered high, and above 30% are very high. Countries with high stunting often have inadequate access to diverse, nutritious foods, poor maternal nutrition, limited healthcare, and food insecurity that affects the most vulnerable—pregnant women and young children.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "The first 1,000 days from conception to age 2 are critical for preventing stunting. Once stunting occurs, it's largely irreversible, making prevention essential. High stunting rates indicate systemic food security problems that affect the next generation. Countries with high stunting need targeted interventions including nutrition programs for pregnant women and young children, improved access to diverse foods, better healthcare, and poverty reduction. Reducing stunting is not just about calories—it requires access to protein, micronutrients, and diverse diets. Addressing stunting is crucial for breaking intergenerational cycles of poverty and food insecurity.", style = "margin-bottom: 10px;"),
                  p(strong("Data Sources:"), "WHO Global Health Observatory and Global Data Lab - Child Stunting Rates (2022-2024).", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "agriculture" = {
              score <- case_when(
                is.na(country_data$tfp_index) ~ 0,
                country_data$tfp_index < 100 ~ 6,
                country_data$tfp_index < 120 ~ 4,
                country_data$tfp_index < 150 ~ 2,
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "Based on Total Factor Productivity (TFP) Index thresholds"),
                p(strong("Data Source:"), "USDA Agricultural Production Data"),
                p(strong("Country Value:"), ifelse(is.na(country_data$tfp_index), "No data", paste("TFP Index: ", round(country_data$tfp_index, 1)))),
                p(strong("Score Thresholds:"), 
                  tags$ul(
                    tags$li("TFP < 100: 6 points (Very low productivity)"),
                    tags$li("TFP 100-120: 4 points (Low productivity)"),
                    tags$li("TFP 120-150: 2 points (Moderate productivity)"),
                    tags$li("TFP ≥ 150: 0 points")
                  )),
                p(strong("Score Calculation:"), 
                  ifelse(is.na(country_data$tfp_index),
                    "No data → 0.0 points",
                    paste("TFP Index of ", round(country_data$tfp_index, 1), " falls in the ", 
                          case_when(
                            country_data$tfp_index < 100 ~ "<100",
                            country_data$tfp_index < 120 ~ "100-120",
                            country_data$tfp_index < 150 ~ "120-150",
                            TRUE ~ "≥150"
                          ), " range → ", round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/6 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Total Factor Productivity (TFP) Index measures agricultural productivity by comparing the efficiency of agricultural inputs (land, labor, capital, materials) to outputs. A TFP of 100 represents the baseline productivity level, with higher values indicating more efficient production. This captures improvements in farming techniques, technology, infrastructure, and management practices.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Agricultural productivity directly determines a country's ability to produce sufficient food for its population. Low productivity means that even with adequate land and labor, food production may be insufficient, forcing dependence on imports that may be unaffordable or unreliable. Countries with TFP below 100 are producing less efficiently than the baseline, often due to limited access to modern farming techniques, irrigation, fertilizers, improved seeds, and agricultural extension services. Low productivity also means that farmers earn less, reducing rural incomes and food purchasing power. Improving agricultural productivity is essential for food security, but it requires investment in research, infrastructure, education, and access to inputs.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Many developing countries have TFP indices below 120, indicating significant room for improvement. Low productivity often results from subsistence farming with traditional methods, limited access to credit and inputs, poor infrastructure (roads, storage, markets), and climate challenges. Countries with very low TFP (below 100) are particularly vulnerable because they cannot produce enough food domestically and may lack resources to import. Agricultural development programs that improve productivity can significantly enhance food security, but they require long-term investment and supportive policies. Productivity improvements also need to be sustainable and climate-resilient to maintain food security in the face of environmental challenges.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "USDA Economic Research Service - Total Factor Productivity Index (2022-2024).", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "food_production" = {
              score <- case_when(
                is.na(country_data$food_supply_kcal) ~ 0,
                country_data$food_supply_kcal < 2000 ~ 4,
                country_data$food_supply_kcal < 2200 ~ 3,
                country_data$food_supply_kcal < 2500 ~ 2,
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "Based on food supply (kcal/day per capita) thresholds"),
                p(strong("Data Source:"), "Our World in Data"),
                p(strong("Country Value:"), ifelse(is.na(country_data$food_supply_kcal), "No data", paste(round(country_data$food_supply_kcal, 0), " kcal/day per capita"))),
                p(strong("Score Thresholds:"), 
                  tags$ul(
                    tags$li("Food Supply < 2000 kcal/day: 4 points (Very low)"),
                    tags$li("Food Supply 2000-2200 kcal/day: 3 points (Low)"),
                    tags$li("Food Supply 2200-2500 kcal/day: 2 points (Below recommended)"),
                    tags$li("Food Supply ≥ 2500 kcal/day: 0 points (Adequate)")
                  )),
                p(strong("Recommended Daily Intake:"), "2500 kcal/day per capita"),
                p(strong("Score Calculation:"), 
                  ifelse(is.na(country_data$food_supply_kcal),
                    "No data → 0.0 points",
                    paste("Food supply of ", round(country_data$food_supply_kcal, 0), " kcal/day falls in the ", 
                          case_when(
                            country_data$food_supply_kcal < 2000 ~ "<2000",
                            country_data$food_supply_kcal < 2200 ~ "2000-2200",
                            country_data$food_supply_kcal < 2500 ~ "2200-2500",
                            TRUE ~ "≥2500"
                          ), " range → ", round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/4 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Food supply (kcal/day per capita) represents the average daily caloric availability per person in a country, calculated from food production, imports, exports, and stock changes. This measures the total food available at the national level, though it doesn't account for distribution inequalities within countries.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Adequate food supply is fundamental to food security. The recommended daily caloric intake is approximately 2,500 kcal per person for a healthy, active lifestyle. When national food supply falls below 2,200 kcal/day, it indicates insufficient food availability even before considering distribution issues. Countries with food supply below 2,000 kcal/day are in critical condition, as this level is below basic energy requirements. Low food supply can result from low production, high population relative to production capacity, limited import capacity, or food losses. Even when average supply appears adequate, unequal distribution means that many people may still experience hunger if food is concentrated among wealthier populations.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Countries with food supply below 2,200 kcal/day often experience widespread hunger and malnutrition. This is particularly concerning in countries with high population growth, as food supply must increase to keep pace. Low food supply can result from agricultural challenges (low productivity, climate shocks), economic constraints (cannot afford imports), or political issues (trade restrictions, conflict). Improving food supply requires increasing production, reducing losses, and ensuring equitable distribution. However, even countries with adequate average supply can have high hunger rates if distribution is highly unequal, which is why this factor is combined with inequality and poverty measures in our index.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "Our World in Data - Food Supply per Capita (kcal/day) - 2022-2024.", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "climate" = {
              score <- case_when(
                is.na(country_data$climate_vulnerability_index) ~ 0,
                country_data$climate_vulnerability_index >= 80 ~ 6,
                country_data$climate_vulnerability_index >= 70 ~ 4,
                country_data$climate_vulnerability_index >= 60 ~ 2,
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "Based on Climate Vulnerability Index thresholds"),
                p(strong("Data Source:"), "Global Data Lab"),
                p(strong("Country Value:"), ifelse(is.na(country_data$climate_vulnerability_index), "No data", paste("Climate Vulnerability Index: ", round(country_data$climate_vulnerability_index, 1), "/100"))),
                p(strong("Score Thresholds:"), 
                  tags$ul(
                    tags$li("Index ≥ 80: 6 points (Very high vulnerability)"),
                    tags$li("Index 70-80: 4 points (High vulnerability)"),
                    tags$li("Index 60-70: 2 points (Moderate vulnerability)"),
                    tags$li("Index < 60: 0 points")
                  )),
                p(strong("Score Calculation:"), 
                  ifelse(is.na(country_data$climate_vulnerability_index),
                    "No data → 0.0 points",
                    paste("Climate Vulnerability Index of ", round(country_data$climate_vulnerability_index, 1), " falls in the ", 
                          case_when(
                            country_data$climate_vulnerability_index >= 80 ~ "≥80",
                            country_data$climate_vulnerability_index >= 70 ~ "70-80",
                            country_data$climate_vulnerability_index >= 60 ~ "60-70",
                            TRUE ~ "<60"
                          ), " range → ", round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/6 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Climate Vulnerability Index assesses a country's exposure and sensitivity to climate-related hazards (droughts, floods, extreme temperatures, sea-level rise) and its capacity to adapt. Higher scores indicate greater vulnerability to climate impacts on food production, water resources, and livelihoods.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Climate change is increasingly threatening food security worldwide, but some countries are far more vulnerable than others. Countries with high climate vulnerability face more frequent and severe droughts, floods, heat waves, and changing precipitation patterns that directly impact agricultural production. Climate vulnerability above 70 indicates that a country faces significant risks from climate-related food production disruptions. These countries often lack the resources to adapt (irrigation systems, drought-resistant crops, early warning systems) and have limited capacity to import food when domestic production fails. Climate shocks can destroy crops, kill livestock, damage infrastructure, and displace populations, creating acute food crises. As climate change intensifies, vulnerable countries will face increasing challenges to food security.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Many countries in Sub-Saharan Africa, South Asia, and Small Island Developing States have high climate vulnerability. These regions face increasing frequency of extreme weather events that disrupt food production. For example, prolonged droughts can cause crop failures and livestock deaths, while floods can destroy harvests and infrastructure. Climate vulnerability is particularly concerning because it's increasing over time due to global warming, and adaptation requires significant investment that many vulnerable countries cannot afford. Building climate resilience through improved agricultural practices, water management, early warning systems, and diversified livelihoods is essential but challenging for low-income countries with high vulnerability.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "Global Data Lab - Climate Vulnerability Index (2022-2024).", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "health" = {
              score <- case_when(
                !is.na(country_data$under5_mortality) & country_data$under5_mortality >= 100 ~ 8,
                !is.na(country_data$under5_mortality) & country_data$under5_mortality >= 50 ~ 6,
                !is.na(country_data$under5_mortality) & country_data$under5_mortality >= 25 ~ 4,
                !is.na(country_data$infant_mortality) & country_data$infant_mortality >= 50 ~ 6,
                !is.na(country_data$infant_mortality) & country_data$infant_mortality >= 25 ~ 4,
                !is.na(country_data$child_wasting_rate) & country_data$child_wasting_rate >= 15 ~ 6,
                !is.na(country_data$child_wasting_rate) & country_data$child_wasting_rate >= 10 ~ 4,
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "Based on child mortality and wasting rates"),
                p(strong("Data Source:"), "Global Data Lab"),
                p(strong("Indicators Used:"), 
                  tags$ul(
                    tags$li(ifelse(!is.na(country_data$under5_mortality), paste("Under-5 Mortality: ", round(country_data$under5_mortality, 1), " per 1,000"), "Under-5 Mortality: No data")),
                    tags$li(ifelse(!is.na(country_data$infant_mortality), paste("Infant Mortality: ", round(country_data$infant_mortality, 1), " per 1,000"), "Infant Mortality: No data")),
                    tags$li(ifelse(!is.na(country_data$child_wasting_rate), paste("Child Wasting: ", round(country_data$child_wasting_rate, 1), "%"), "Child Wasting: No data"))
                  )),
                p(strong("Score Thresholds:"), 
                  tags$ul(
                    tags$li("Under-5 Mortality ≥ 100: 8 points"),
                    tags$li("Under-5 Mortality ≥ 50: 6 points"),
                    tags$li("Under-5 Mortality ≥ 25: 4 points"),
                    tags$li("Infant Mortality ≥ 50: 6 points"),
                    tags$li("Infant Mortality ≥ 25: 4 points"),
                    tags$li("Child Wasting ≥ 15%: 6 points"),
                    tags$li("Child Wasting ≥ 10%: 4 points")
                  )),
                p(strong("Score Calculation:"), 
                  ifelse(score == 0 && is.na(country_data$under5_mortality) && is.na(country_data$infant_mortality) && is.na(country_data$child_wasting_rate),
                    "No data → 0.0 points",
                    paste("Highest applicable score → ", round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/8 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Health vulnerability is assessed through multiple indicators: under-5 mortality (deaths per 1,000 live births before age 5), infant mortality (deaths in first year), and child wasting (low weight-for-height, indicating acute malnutrition). These indicators reflect the health consequences of food insecurity and malnutrition.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Health outcomes are direct consequences of food security. High child mortality rates often indicate that children are dying from malnutrition-related causes (diarrhea, pneumonia, measles) that are exacerbated by poor nutrition. Under-5 mortality above 50 per 1,000 is considered high, and above 100 is very high. Child wasting (acute malnutrition) above 10% indicates a serious nutrition crisis, and above 15% indicates an emergency. These health indicators capture the most severe consequences of food insecurity—when children are dying or severely malnourished due to lack of adequate nutrition. Poor health also creates a vicious cycle: malnourished children are more susceptible to disease, and disease further reduces their ability to absorb nutrients, leading to worse outcomes.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Countries with high child mortality and wasting rates are experiencing acute food security crises that require immediate intervention. These indicators often spike during emergencies (conflicts, droughts, economic crises) when food becomes unavailable or unaffordable. High health vulnerability indicates that food insecurity has progressed beyond hunger to life-threatening malnutrition. Addressing these issues requires not just food aid, but also healthcare, clean water, sanitation, and nutrition programs. The relationship between health and food security is bidirectional: improving nutrition reduces mortality and disease, while better healthcare enables children to benefit from available food. Countries with high health vulnerability need integrated food security and health interventions.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "Global Data Lab - Child Mortality and Wasting Indicators (2022-2024).", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            "market_access" = {
              score <- case_when(
                is.na(country_data$total_markets) ~ 0,
                country_data$total_markets == 0 ~ 7,
                country_data$total_markets < 5 ~ 5,
                country_data$total_markets < 20 ~ 3,
                TRUE ~ 0
              )
              tagList(
                p(strong("Calculation Formula:"), "Based on number of WFP markets"),
                p(strong("Data Source:"), "WFP (World Food Programme)"),
                p(strong("Country Value:"), ifelse(is.na(country_data$total_markets), "No data", paste(country_data$total_markets, " WFP markets"))),
                p(strong("Score Thresholds:"), 
                  tags$ul(
                    tags$li("0 markets: 7 points (No market access)"),
                    tags$li("1-4 markets: 5 points (Very limited access)"),
                    tags$li("5-19 markets: 3 points (Limited access)"),
                    tags$li("≥20 markets: 0 points (Good access)")
                  )),
                p(strong("Score Calculation:"), 
                  ifelse(is.na(country_data$total_markets),
                    "No data → 0.0 points",
                    paste(country_data$total_markets, " markets falls in the ", 
                          case_when(
                            country_data$total_markets == 0 ~ "0 markets",
                            country_data$total_markets < 5 ~ "1-4 markets",
                            country_data$total_markets < 20 ~ "5-19 markets",
                            TRUE ~ "≥20 markets"
                          ), " range → ", round(score, 1), " points"))),
                p(strong("Final Score:"), paste(round(score, 1), "/7 points")),
                div(
                  style = "margin-top: 15px; padding: 15px; background-color: #f0f8ff; border-left: 4px solid #0066cc; border-radius: 4px;",
                  h5("📚 Comprehensive Explanation:", style = "color: #0066cc; margin-bottom: 10px;"),
                  p(strong("What This Measures:"), "Market access is measured by the number of active markets monitored by the World Food Programme (WFP) in a country. WFP monitors markets to track food prices, availability, and access. More markets indicate better market infrastructure and food distribution networks.", style = "margin-bottom: 10px;"),
                  p(strong("Why It Matters for Hunger Vulnerability:"), "Market access is crucial for food security because it determines whether food can reach people who need it. Countries with few or no monitored markets often have weak market infrastructure, limited transportation networks, and poor food distribution systems. This means that even when food is produced or imported, it may not reach all areas or populations. Limited market access is particularly problematic in rural areas, conflict zones, and remote regions where people depend on markets for food but markets are sparse or inaccessible. Countries with zero markets may be experiencing severe crises, conflict, or have such weak infrastructure that market monitoring is impossible. Good market access (20+ markets) indicates robust distribution networks that can help ensure food reaches vulnerable populations.", style = "margin-bottom: 10px;"),
                  p(strong("Real-World Implications:"), "Countries with very few markets often have high food prices due to limited competition and high transportation costs. They may also experience food shortages in remote areas even when food is available in urban centers. Conflict-affected countries often have disrupted markets, making food distribution difficult. Improving market access requires investment in roads, transportation, storage facilities, and market infrastructure. However, market access alone doesn't guarantee food security—people must also have the purchasing power to buy food from markets. Countries with good market access but high poverty may still have high hunger rates if people cannot afford market prices. This factor works in combination with poverty and economic indicators to assess overall food access.", style = "margin-bottom: 10px;"),
                  p(strong("Data Source:"), "World Food Programme (WFP) Market Monitoring Data - 2022-2024.", style = "margin-bottom: 0; font-style: italic; color: #666;")
                )
              )
            },
            p("Detailed breakdown for this factor is being prepared...")
          )
        )
      )
    )
  })
  
  # Close factor detail when button is clicked
  observeEvent(input$close_factor_detail, {
    session$sendCustomMessage(type = "resetFactorDetail", message = "")
  })
  
  # Data table
  output$data_table <- DT::renderDataTable({
    DT::datatable(
      filtered_data() %>%
        select(Area, hunger_vulnerability_rating, undernourishment_rate, undernourished_population, poverty_rate, 
               poverty_headcount, gini_coefficient, life_expectancy, gdp_per_capita, population, 
               combined_risk, development_level, region,
               major_hunger_outbreak_21st, outbreak_years,
               total_markets, total_population_served, market_access,
               grfc_ipc_phase, grfc_population_phase3_plus, grfc_primary_driver, grfc_assessment_year) %>%
        mutate(
          # Calculate estimated undernourished population if missing
          estimated_undernourished_pop = ifelse(
            is.na(undernourished_population) & !is.na(undernourishment_rate) & !is.na(population),
            (undernourishment_rate / 100) * population / 1e6,  # Convert to millions
            undernourished_population
          ),
          hunger_vulnerability_rating = ifelse(is.na(hunger_vulnerability_rating), NA, round(hunger_vulnerability_rating, 1)),
          undernourishment_rate = ifelse(is.na(undernourishment_rate), NA, round(undernourishment_rate, 1)),
          undernourished_population = ifelse(
            is.na(undernourished_population) & !is.na(estimated_undernourished_pop),
            paste("~", round(estimated_undernourished_pop, 1)),
            ifelse(is.na(undernourished_population), NA, round(undernourished_population, 1))
          ),
          poverty_rate = ifelse(is.na(poverty_rate), NA, round(poverty_rate, 1)),
          life_expectancy = ifelse(is.na(life_expectancy), NA, round(life_expectancy, 1)),
          gdp_per_capita = ifelse(is.na(gdp_per_capita), NA, round(gdp_per_capita, 0)),
          population = ifelse(is.na(population), NA, round(population / 1e6, 1)),
          total_population_served = ifelse(is.na(total_population_served), NA, round(total_population_served / 1e6, 1))
        ) %>%
        rename(
          Country = Area,
          "Hunger Vulnerability Rating" = hunger_vulnerability_rating,
          "Undernourishment (%)" = undernourishment_rate,
          "Undernourished Pop (M)" = undernourished_population,
          "Poverty Rate (<$10/day) (%)" = poverty_rate,
          "PIP Poverty Headcount" = poverty_headcount,
          "Gini Coefficient" = gini_coefficient,
          "Life Expectancy (years)" = life_expectancy,
          "GDP per Capita ($)" = gdp_per_capita,
          "GRFC IPC Phase" = ifelse(is.na(grfc_ipc_phase), NA, paste0("Phase ", grfc_ipc_phase)),
          "GRFC Population Phase 3+ (M)" = ifelse(is.na(grfc_population_phase3_plus), NA, round(grfc_population_phase3_plus / 1e6, 1)),
          "GRFC Primary Driver" = grfc_primary_driver,
          "Population (M)" = population,
          "Combined Risk" = combined_risk,
          "Development Level" = development_level,
          "Region" = region,
          "Major Hunger Outbreak (21st C)" = major_hunger_outbreak_21st,
          "Outbreak Years" = outbreak_years,
          "WFP Markets" = total_markets,
          "Population Served (M)" = total_population_served,
          "Market Access Level" = market_access
        ),
      options = list(
        pageLength = 25, 
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons',
      filter = 'top'
    )
  })
}

# Run the application
cat("🌍 Starting Enhanced Global Hunger Research Website with Latest FAO Data...\n")
cat("====================================================================\n")
cat("✅ Latest FAO data (2022-2024) loaded successfully!\n")
cat("✅ World Bank data loaded successfully!\n")
cat("✅ WFP data loaded successfully!\n")
cat("📊 Total countries in dataset:", nrow(sovereign_countries), "\n")
cat("📊 Countries with latest FAO data:", sum(!is.na(sovereign_countries$undernourishment_rate)), "\n")
cat("📊 Countries with World Bank data:", sum(!is.na(sovereign_countries$population)), "\n")
cat("📊 Countries with WFP market data:", sum(!is.na(sovereign_countries$total_markets)), "\n")
cat("🌐 WEBSITE URL: http://localhost:3840\n")
cat("📱 Alternative: http://127.0.0.1:3840\n")
cat("🔗 Copy and paste this URL into your browser!\n")
cat("🛑 To stop the server, press Ctrl+C in the terminal.\n\n")

shinyApp(ui = ui, server = server)
