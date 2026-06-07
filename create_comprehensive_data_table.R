library(tidyverse)

cat("Creating comprehensive data table with all indicators...\n")

# Load country name mapping
country_mapping_df <- read_csv("country_name_mapping.csv", show_col_types = FALSE)
country_mapping <- setNames(country_mapping_df$standardized_name, country_mapping_df$original_name)

standardize_country_names <- function(country_names) {
  for (old_name in names(country_mapping)) {
    country_names[country_names == old_name] <- country_mapping[old_name]
  }
  return(country_names)
}

# Load all data sources
cat("Loading FAO data...\n")
# Try to load processed time series data first, fallback to summary
if(file.exists("data/processed/fao_time_series_data.csv")) {
  fao_data <- read_csv("data/processed/fao_time_series_data.csv", show_col_types = FALSE)
} else {
  fao_data <- read_csv("data/processed/fao_summary_data.csv", show_col_types = FALSE)
}

# Also load raw FAO to get undernourishment data
fao_raw <- read_csv("data/raw/fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv", show_col_types = FALSE)

cat("Loading World Bank data...\n")
wb_raw <- read_csv("data/raw/world bank/world_bank_data.csv", show_col_types = FALSE)

cat("Loading PIP data...\n")
pip_data <- read_csv("data/raw/world bank/pip 2.csv", show_col_types = FALSE)

cat("Loading WFP data...\n")
wfp_markets <- read_csv("data/raw/wfp/markets.csv", show_col_types = FALSE)

cat("Loading new data sources...\n")
new_data <- read_csv("data/processed/new_data_sources_combined.csv", show_col_types = FALSE)

# Process FAO raw data to get undernourishment (similar to app)
cat("Processing FAO raw data...\n")
fao_processed <- fao_raw %>%
  mutate(
    Value_clean = case_when(
      Value == "<2.5" ~ "2.5",
      Value == "" ~ NA_character_,
      TRUE ~ Value
    ),
    Value_numeric = as.numeric(Value_clean)
  ) %>%
  select(Area, `Item Code`, Year, Value_numeric) %>%
  filter(`Item Code` %in% c(210041, 210011)) %>%  # Undernourishment rate and population
  pivot_wider(
    names_from = `Item Code`,
    values_from = Value_numeric,
    names_prefix = "ind_"
  ) %>%
  mutate(Area = standardize_country_names(Area)) %>%
  group_by(Area) %>%
  summarise(
    undernourishment_rate = last(ind_210041, order_by = Year),
    undernourished_population = last(ind_210011, order_by = Year),
    latest_fao_year = max(Year, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(!is.na(undernourishment_rate) | !is.na(undernourished_population))

# Process World Bank data (similar to app)
cat("Processing World Bank data...\n")
wb_summary <- wb_raw %>%
  mutate(country = standardize_country_names(country)) %>%
  group_by(country) %>%
  summarise(
    gdp_per_capita = last(NY.GDP.PCAP.CD, order_by = year),
    life_expectancy = last(SP.DYN.LE00.IN, order_by = year),
    population = last(SP.POP.TOTL, order_by = year),
    poverty_rate = last(SI.POV.DDAY, order_by = year),
    region = first(region),
    income = first(income),
    .groups = "drop"
  ) %>%
  # Filter out aggregates
  filter(!country %in% c("Aggregates", "Africa", "Asia", "Europe", "Americas", "Oceania") & 
         !str_detect(country, "Aggregates|^Africa |^Asia |^Europe |^Americas |^Oceania "))

# Process PIP data (similar to app)
cat("Processing PIP data...\n")
pip_summary <- pip_data %>%
  mutate(country_name = standardize_country_names(country_name)) %>%
  filter(reporting_level == "national") %>%
  group_by(country_name) %>%
  slice_max(reporting_year, n = 1) %>%
  summarise(
    poverty_headcount = last(headcount, order_by = reporting_year),
    gini_coefficient = last(gini, order_by = reporting_year),
    poverty_gap = last(poverty_gap, order_by = reporting_year),
    .groups = "drop"
  ) %>%
  filter(!is.na(poverty_headcount))

# Process WFP markets
cat("Processing WFP data...\n")
wfp_summary <- wfp_markets %>%
  mutate(Country = standardize_country_names(Country)) %>%
  group_by(Country) %>%
  summarise(
    total_markets = n(),
    total_population_served = sum(Population, na.rm = TRUE),
    .groups = "drop"
  )

# Process new data sources (take most recent for each country)
cat("Processing new data sources...\n")
new_data_summary <- new_data %>%
  group_by(country) %>%
  slice(1) %>%
  ungroup() %>%
  select(
    country,
    climate_vulnerability_index,
    who_stunting_rate,
    child_stunting_rate,
    child_wasting_rate,
    child_underweight_rate,
    infant_mortality,
    under5_mortality,
    child_mortality,
    food_supply_kcal,
    poverty_below_3usd,
    tfp_index
  )

# Load historical hunger outbreaks (from CSV if available, otherwise use default)
if(file.exists("data/raw/historical_hunger_outbreaks.csv")) {
  cat("Loading historical hunger outbreaks from CSV...\n")
  hunger_outbreaks_raw <- read_csv("data/raw/historical_hunger_outbreaks.csv", show_col_types = FALSE)
  
  # Process the CSV data
  hunger_outbreaks <- hunger_outbreaks_raw %>%
    mutate(
      country = standardize_country_names(country),
      # Create outbreak_years string from start/end years
      outbreak_years = ifelse(
        outbreak_end_year == "Ongoing" | as.numeric(outbreak_end_year) >= as.numeric(format(Sys.Date(), "%Y")),
        paste0(outbreak_start_year, "-Ongoing"),
        ifelse(
          outbreak_start_year == outbreak_end_year,
          as.character(outbreak_start_year),
          paste0(outbreak_start_year, "-", outbreak_end_year)
        )
      )
    ) %>%
    group_by(country) %>%
    summarise(
      major_hunger_outbreak_21st = TRUE,
      outbreak_years = paste(unique(outbreak_years), collapse = ", "),
      .groups = "drop"
    ) %>%
    rename(Area = country)
  
  cat("Loaded", nrow(hunger_outbreaks), "countries with historical outbreaks from CSV\n")
} else {
  cat("Using default historical hunger outbreaks (create data/raw/historical_hunger_outbreaks.csv to customize)\n")
  # Default data (from app logic)
  hunger_outbreaks <- data.frame(
    Area = c("Somalia", "Yemen", "South Sudan", "Nigeria", "Ethiopia", 
             "Afghanistan", "Haiti", "Madagascar", "Democratic Republic of the Congo",
             "Central African Republic", "Chad", "Mali", "Burkina Faso", "Niger",
             "Zambia", "Zimbabwe", "Venezuela (Bolivarian Republic of)", "United Republic of Tanzania"),
    major_hunger_outbreak_21st = TRUE,
    outbreak_years = c("2011, 2017, 2022", "2016-2023", "2017-2023", "2016-2018", "2015-2016, 2020-2022",
                      "2001-2002, 2018-2021", "2008, 2010, 2016", "2021-2022", "2017-2019",
                      "2013-2014, 2018-2020", "2010, 2017-2018", "2012, 2018-2020", "2012, 2018-2020", "2005, 2010, 2018-2020",
                      "2019-2020", "2019-2021", "2016-2020", "2017-2019"),
    stringsAsFactors = FALSE
  )
}

# Get all unique countries (filter out aggregates and regions)
all_countries <- unique(c(
  fao_processed$Area,
  wb_summary$country,
  pip_summary$country_name,
  wfp_summary$Country,
  new_data_summary$country
)) %>% 
  # Filter out obvious aggregates and regions
  .[!str_detect(., "Aggregates|^Africa$|^Asia$|^Europe$|^Americas$|^Oceania$|^World$|^EU|European Union")] %>%
  .[!str_detect(., "\\(FAO\\)|\\(WB\\)|Eastern|Western|Northern|Southern|Central")] %>%
  sort()

cat("Total unique countries:", length(all_countries), "\n")

# Create comprehensive data table
cat("Combining all data sources...\n")
comprehensive_data <- data.frame(
  Country = all_countries,
  stringsAsFactors = FALSE
) %>%
  # Add FAO processed data
  left_join(
    fao_processed %>% 
      select(Area, undernourishment_rate, undernourished_population, latest_fao_year) %>%
      rename(Country = Area),
    by = "Country"
  ) %>%
  # Add World Bank data
  left_join(
    wb_summary %>% rename(Country = country),
    by = "Country"
  ) %>%
  # Add PIP data
  left_join(
    pip_summary %>% rename(Country = country_name),
    by = "Country"
  ) %>%
  # Add WFP data
  left_join(
    wfp_summary,
    by = "Country"
  ) %>%
  # Add new data sources
  left_join(
    new_data_summary %>% rename(Country = country),
    by = "Country"
  ) %>%
  # Add hunger outbreaks
  left_join(
    hunger_outbreaks %>% rename(Country = Area),
    by = "Country"
  ) %>%
  # Add GRFC 2025 data (if available)
  {
    if(file.exists("data/raw/wfp/grfc2025_data.csv")) {
      cat("Loading GRFC 2025 data...\n")
      grfc_data <- read_csv("data/raw/wfp/grfc2025_data.csv", show_col_types = FALSE) %>%
        mutate(country = standardize_country_names(country)) %>%
        # Take most recent assessment per country
        group_by(country) %>%
        slice_max(assessment_year, n = 1) %>%
        ungroup() %>%
        rename(
          Country = country,
          grfc_assessment_year = assessment_year,
          grfc_ipc_phase = ipc_phase,
          grfc_population_phase3_plus = population_phase3_plus,
          grfc_population_phase4_plus = population_phase4_plus,
          grfc_population_phase5 = population_phase5,
          grfc_primary_driver = primary_driver
        )
      
      cat("Loaded GRFC data for", nrow(grfc_data), "countries\n")
      
      left_join(., grfc_data, by = "Country")
    } else {
      cat("GRFC 2025 data not found (optional - create data/raw/wfp/grfc2025_data.csv to include)\n")
      .
    }
  } %>%
  # Fill in missing values for boolean
  mutate(
    major_hunger_outbreak_21st = ifelse(is.na(major_hunger_outbreak_21st), FALSE, major_hunger_outbreak_21st),
    outbreak_years = ifelse(is.na(outbreak_years), "None", outbreak_years)
  ) %>%
  # Reorder columns for better readability
  select(
    Country,
    # FAO indicators
    undernourishment_rate,
    undernourished_population,
    latest_fao_year,
    # World Bank economic indicators
    gdp_per_capita,
    life_expectancy,
    population,
    poverty_rate,
    region,
    income,
    # PIP poverty indicators
    poverty_headcount,
    gini_coefficient,
    poverty_gap,
    # WFP market indicators
    total_markets,
    total_population_served,
    # New data sources - Climate
    climate_vulnerability_index,
    # New data sources - Nutrition
    who_stunting_rate,
    child_stunting_rate,
    child_wasting_rate,
    child_underweight_rate,
    # New data sources - Health
    infant_mortality,
    under5_mortality,
    child_mortality,
    # New data sources - Food & Agriculture
    food_supply_kcal,
    tfp_index,
    # New data sources - Poverty (alternative)
    poverty_below_3usd,
    # Historical data
    major_hunger_outbreak_21st,
    outbreak_years
  ) %>%
  # Calculate vulnerability rating (same as app)
  mutate(
    # Calculate component scores
    undernourishment_score = pmin(ifelse(is.na(undernourishment_rate), 0, undernourishment_rate) * 0.8, 40),
    poverty_score = case_when(
      !is.na(poverty_headcount) ~ pmin(poverty_headcount * 0.4, 20),
      !is.na(poverty_rate) ~ pmin(poverty_rate * 0.4, 20),
      !is.na(poverty_below_3usd) ~ pmin(poverty_below_3usd * 0.4, 20),
      TRUE ~ 0
    ),
    gdp_score = case_when(
      is.na(gdp_per_capita) ~ 0,
      gdp_per_capita < 1000 ~ 15,
      gdp_per_capita < 3000 ~ 12,
      gdp_per_capita < 10000 ~ 8,
      gdp_per_capita < 20000 ~ 4,
      TRUE ~ 0
    ),
    life_expectancy_score = case_when(
      is.na(life_expectancy) ~ 0,
      life_expectancy < 50 ~ 10,
      life_expectancy < 60 ~ 8,
      life_expectancy < 70 ~ 5,
      TRUE ~ 0
    ),
    inequality_score = case_when(
      is.na(gini_coefficient) ~ 0,
      gini_coefficient >= 0.6 ~ 8,
      gini_coefficient >= 0.5 ~ 6,
      gini_coefficient >= 0.4 ~ 4,
      TRUE ~ 0
    ),
    market_access_score = case_when(
      is.na(total_markets) ~ 0,
      total_markets == 0 ~ 7,
      total_markets < 5 ~ 5,
      total_markets < 20 ~ 3,
      TRUE ~ 0
    ),
    outbreak_score = ifelse(is.na(major_hunger_outbreak_21st) | !major_hunger_outbreak_21st, 0, 20),
    population_density_score = case_when(
      is.na(population) ~ 0,
      population > 100000000 ~ 5,
      population > 50000000 ~ 3,
      population > 10000000 ~ 1,
      TRUE ~ 0
    ),
    regional_vulnerability_score = case_when(
      is.na(region) ~ 0,
      region %in% c("Sub-Saharan Africa", "Middle East & North Africa") ~ 15,
      region %in% c("South Asia", "Latin America & Caribbean") ~ 10,
      region %in% c("East Asia & Pacific", "Europe & Central Asia") ~ 5,
      TRUE ~ 0
    ),
    stunting_score = case_when(
      !is.na(who_stunting_rate) ~ pmin(who_stunting_rate * 0.2, 8),
      !is.na(child_stunting_rate) ~ pmin(child_stunting_rate * 0.2, 8),
      TRUE ~ 0
    ),
    agriculture_score = case_when(
      is.na(tfp_index) ~ 0,
      tfp_index < 100 ~ 6,
      tfp_index < 120 ~ 4,
      tfp_index < 150 ~ 2,
      TRUE ~ 0
    ),
    food_production_score = case_when(
      is.na(food_supply_kcal) ~ 0,
      food_supply_kcal < 2000 ~ 4,
      food_supply_kcal < 2200 ~ 3,
      food_supply_kcal < 2500 ~ 2,
      TRUE ~ 0
    ),
    climate_score = case_when(
      is.na(climate_vulnerability_index) ~ 0,
      climate_vulnerability_index >= 80 ~ 6,
      climate_vulnerability_index >= 70 ~ 4,
      climate_vulnerability_index >= 60 ~ 2,
      TRUE ~ 0
    ),
    health_vulnerability_score = case_when(
      !is.na(under5_mortality) & under5_mortality >= 100 ~ 8,
      !is.na(under5_mortality) & under5_mortality >= 50 ~ 6,
      !is.na(under5_mortality) & under5_mortality >= 25 ~ 4,
      !is.na(infant_mortality) & infant_mortality >= 50 ~ 6,
      !is.na(infant_mortality) & infant_mortality >= 25 ~ 4,
      !is.na(child_wasting_rate) & child_wasting_rate >= 15 ~ 6,
      !is.na(child_wasting_rate) & child_wasting_rate >= 10 ~ 4,
      TRUE ~ 0
    ),
    # Calculate total vulnerability score
    hunger_vulnerability_rating = round(
      undernourishment_score + poverty_score + gdp_score + life_expectancy_score + 
      inequality_score + market_access_score + outbreak_score + 
      population_density_score + regional_vulnerability_score + 
      stunting_score + agriculture_score + food_production_score + 
      climate_score + health_vulnerability_score,
      1
    ),
    hunger_vulnerability_rating = pmax(0, pmin(100, hunger_vulnerability_rating))
  ) %>%
  # Round numeric columns for readability
  mutate(
    across(where(is.numeric) & !matches("hunger_vulnerability_rating|undernourishment_score|poverty_score|gdp_score|life_expectancy_score|inequality_score|market_access_score|outbreak_score|population_density_score|regional_vulnerability_score|stunting_score|agriculture_score|food_production_score|climate_score|health_vulnerability_score"), ~ round(.x, 2))
  ) %>%
  # Reorder to put vulnerability rating near the front
  select(
    Country,
    hunger_vulnerability_rating,
    # FAO indicators
    undernourishment_rate,
    undernourished_population,
    latest_fao_year,
    # World Bank economic indicators
    gdp_per_capita,
    life_expectancy,
    population,
    poverty_rate,
    region,
    income,
    # PIP poverty indicators
    poverty_headcount,
    gini_coefficient,
    poverty_gap,
    # WFP market indicators
    total_markets,
    total_population_served,
    # New data sources - Climate
    climate_vulnerability_index,
    # New data sources - Nutrition
    who_stunting_rate,
    child_stunting_rate,
    child_wasting_rate,
    child_underweight_rate,
    # New data sources - Health
    infant_mortality,
    under5_mortality,
    child_mortality,
    # New data sources - Food & Agriculture
    food_supply_kcal,
    tfp_index,
    # New data sources - Poverty (alternative)
    poverty_below_3usd,
    # Historical data
    major_hunger_outbreak_21st,
    outbreak_years,
    # GRFC 2025 data (if available - use any_of to handle missing columns)
    any_of(c("grfc_assessment_year", "grfc_ipc_phase", "grfc_population_phase3_plus",
             "grfc_population_phase4_plus", "grfc_population_phase5", "grfc_primary_driver"))
  )

# Save to CSV
output_file <- "comprehensive_country_data.csv"
write_csv(comprehensive_data, output_file)

cat("\n✅ Comprehensive data table created!\n")
cat("File saved as:", output_file, "\n")
cat("Total countries:", nrow(comprehensive_data), "\n")
cat("Total indicators:", ncol(comprehensive_data) - 1, "\n\n")

# Print summary statistics
cat("Data Coverage Summary:\n")
cat("=====================\n")
cat("Undernourishment Rate:", sum(!is.na(comprehensive_data$undernourishment_rate)), "/", nrow(comprehensive_data), "\n")
cat("GDP per Capita:", sum(!is.na(comprehensive_data$gdp_per_capita)), "/", nrow(comprehensive_data), "\n")
cat("Life Expectancy:", sum(!is.na(comprehensive_data$life_expectancy)), "/", nrow(comprehensive_data), "\n")
cat("Population:", sum(!is.na(comprehensive_data$population)), "/", nrow(comprehensive_data), "\n")
cat("Poverty Headcount (PIP):", sum(!is.na(comprehensive_data$poverty_headcount)), "/", nrow(comprehensive_data), "\n")
cat("Gini Coefficient:", sum(!is.na(comprehensive_data$gini_coefficient)), "/", nrow(comprehensive_data), "\n")
cat("WFP Markets:", sum(!is.na(comprehensive_data$total_markets)), "/", nrow(comprehensive_data), "\n")
cat("Climate Vulnerability Index:", sum(!is.na(comprehensive_data$climate_vulnerability_index)), "/", nrow(comprehensive_data), "\n")
cat("WHO Stunting Rate:", sum(!is.na(comprehensive_data$who_stunting_rate)), "/", nrow(comprehensive_data), "\n")
cat("Child Stunting Rate (GDL):", sum(!is.na(comprehensive_data$child_stunting_rate)), "/", nrow(comprehensive_data), "\n")
cat("Food Supply (kcal):", sum(!is.na(comprehensive_data$food_supply_kcal)), "/", nrow(comprehensive_data), "\n")
cat("TFP Index:", sum(!is.na(comprehensive_data$tfp_index)), "/", nrow(comprehensive_data), "\n")
cat("Infant Mortality:", sum(!is.na(comprehensive_data$infant_mortality)), "/", nrow(comprehensive_data), "\n")
cat("Under-5 Mortality:", sum(!is.na(comprehensive_data$under5_mortality)), "/", nrow(comprehensive_data), "\n")
cat("Child Wasting Rate:", sum(!is.na(comprehensive_data$child_wasting_rate)), "/", nrow(comprehensive_data), "\n")
cat("Poverty Below 3 USD:", sum(!is.na(comprehensive_data$poverty_below_3usd)), "/", nrow(comprehensive_data), "\n")

