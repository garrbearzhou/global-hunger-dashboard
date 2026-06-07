library(tidyverse)

# Load all data sources
cat("Loading data sources...\n")
fao_data <- read_csv('data/processed/fao_summary_data.csv', show_col_types = FALSE)
wb_raw <- read_csv('data/raw/world bank/world_bank_data.csv', show_col_types = FALSE)
pip_data <- read_csv('data/raw/world bank/pip 2.csv', show_col_types = FALSE)
wfp_markets <- read_csv('data/raw/wfp/markets.csv', show_col_types = FALSE)
new_data <- read_csv('data/processed/new_data_sources_combined.csv', show_col_types = FALSE)

# Process World Bank data similar to app
wb_summary <- wb_raw %>%
  group_by(country) %>%
  summarise(
    gdp_per_capita = last(NY.GDP.PCAP.CD, order_by = year),
    life_expectancy = last(SP.DYN.LE00.IN, order_by = year),
    population = last(SP.POP.TOTL, order_by = year),
    .groups = "drop"
  )

# Get Gini from processed data if available, or check raw
# For now, we'll note that Gini might be in a different source

# Process WFP markets
wfp_summary <- wfp_markets %>%
  group_by(Country) %>%
  summarise(total_markets = n(), .groups = 'drop')

# Get all countries from the main app's processed data
# Load the actual processed data that the app uses
if(file.exists("data/processed/fao_time_series_data.csv")) {
  fao_ts <- read_csv('data/processed/fao_time_series_data.csv', show_col_types = FALSE)
  all_countries <- unique(fao_ts$Area)
} else {
  all_countries <- unique(c(
    fao_data$Area,
    wb_summary$country,
    pip_data$country_name,
    wfp_summary$Country,
    new_data$country
  ))
}

all_countries <- sort(all_countries)

cat("Total unique countries:", length(all_countries), "\n\n")

# Create comprehensive data availability summary
summary_data <- data.frame(
  Country = all_countries,
  stringsAsFactors = FALSE
) %>%
  left_join(
    fao_data %>% select(Area, undernourishment_rate) %>% rename(Country = Area),
    by = 'Country'
  ) %>%
  left_join(
    wb_summary %>% rename(Country = country),
    by = 'Country'
  ) %>%
  left_join(
    pip_data %>% select(country_name, poverty_headcount) %>% rename(Country = country_name),
    by = 'Country'
  ) %>%
  left_join(
    wfp_summary,
    by = 'Country'
  ) %>%
  left_join(
    new_data %>% 
      group_by(country) %>% 
      summarise(
        who_stunting_rate = first(na.omit(who_stunting_rate)),
        child_stunting_rate = first(na.omit(child_stunting_rate)),
        tfp_index = first(na.omit(tfp_index)),
        food_supply_kcal = first(na.omit(food_supply_kcal)),
        climate_vulnerability_index = first(na.omit(climate_vulnerability_index)),
        infant_mortality = first(na.omit(infant_mortality)),
        under5_mortality = first(na.omit(under5_mortality)),
        child_wasting_rate = first(na.omit(child_wasting_rate)),
        poverty_below_3usd = first(na.omit(poverty_below_3usd)),
        .groups = 'drop'
      ) %>% 
      rename(Country = country),
    by = 'Country'
  )

# Count missing data
cat("Data Availability Summary:\n")
cat("==========================\n\n")

total_countries <- nrow(summary_data)

cat("1. Undernourishment Rate (FAO):", sum(!is.na(summary_data$undernourishment_rate)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$undernourishment_rate))/total_countries, 1), "%)\n")
cat("2. GDP per Capita (World Bank):", sum(!is.na(summary_data$gdp_per_capita)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$gdp_per_capita))/total_countries, 1), "%)\n")
cat("3. Life Expectancy (World Bank):", sum(!is.na(summary_data$life_expectancy)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$life_expectancy))/total_countries, 1), "%)\n")
cat("4. Population (World Bank):", sum(!is.na(summary_data$population)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$population))/total_countries, 1), "%)\n")
cat("5. Poverty Headcount (PIP):", sum(!is.na(summary_data$poverty_headcount)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$poverty_headcount))/total_countries, 1), "%)\n")
cat("6. Poverty Below 3 USD (Our World in Data):", sum(!is.na(summary_data$poverty_below_3usd)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$poverty_below_3usd))/total_countries, 1), "%)\n")
cat("7. WFP Market Data:", sum(!is.na(summary_data$total_markets)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$total_markets))/total_countries, 1), "%)\n")
cat("8. WHO Stunting Rate:", sum(!is.na(summary_data$who_stunting_rate)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$who_stunting_rate))/total_countries, 1), "%)\n")
cat("9. Child Stunting Rate (Global Data Lab):", sum(!is.na(summary_data$child_stunting_rate)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$child_stunting_rate))/total_countries, 1), "%)\n")
cat("10. TFP Index (USDA):", sum(!is.na(summary_data$tfp_index)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$tfp_index))/total_countries, 1), "%)\n")
cat("11. Food Supply kcal (Our World in Data):", sum(!is.na(summary_data$food_supply_kcal)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$food_supply_kcal))/total_countries, 1), "%)\n")
cat("12. Climate Vulnerability Index (Global Data Lab):", sum(!is.na(summary_data$climate_vulnerability_index)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$climate_vulnerability_index))/total_countries, 1), "%)\n")
cat("13. Infant Mortality (Global Data Lab):", sum(!is.na(summary_data$infant_mortality)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$infant_mortality))/total_countries, 1), "%)\n")
cat("14. Under-5 Mortality (Global Data Lab):", sum(!is.na(summary_data$under5_mortality)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$under5_mortality))/total_countries, 1), "%)\n")
cat("15. Child Wasting Rate (Global Data Lab):", sum(!is.na(summary_data$child_wasting_rate)), "/", total_countries, "countries (", round(100*sum(!is.na(summary_data$child_wasting_rate))/total_countries, 1), "%)\n")

# Get lists of countries missing each data type
missing_undernourishment <- summary_data %>% filter(is.na(undernourishment_rate)) %>% pull(Country) %>% sort()
missing_gdp <- summary_data %>% filter(is.na(gdp_per_capita)) %>% pull(Country) %>% sort()
missing_life_exp <- summary_data %>% filter(is.na(life_expectancy)) %>% pull(Country) %>% sort()
missing_pop <- summary_data %>% filter(is.na(population)) %>% pull(Country) %>% sort()
missing_poverty_pip <- summary_data %>% filter(is.na(poverty_headcount)) %>% pull(Country) %>% sort()
missing_poverty_owid <- summary_data %>% filter(is.na(poverty_below_3usd)) %>% pull(Country) %>% sort()
missing_wfp <- summary_data %>% filter(is.na(total_markets)) %>% pull(Country) %>% sort()
missing_who_stunting <- summary_data %>% filter(is.na(who_stunting_rate)) %>% pull(Country) %>% sort()
missing_stunting_gdl <- summary_data %>% filter(is.na(child_stunting_rate)) %>% pull(Country) %>% sort()
missing_tfp <- summary_data %>% filter(is.na(tfp_index)) %>% pull(Country) %>% sort()
missing_food_supply <- summary_data %>% filter(is.na(food_supply_kcal)) %>% pull(Country) %>% sort()
missing_climate <- summary_data %>% filter(is.na(climate_vulnerability_index)) %>% pull(Country) %>% sort()
missing_infant_mort <- summary_data %>% filter(is.na(infant_mortality)) %>% pull(Country) %>% sort()
missing_under5_mort <- summary_data %>% filter(is.na(under5_mortality)) %>% pull(Country) %>% sort()
missing_wasting <- summary_data %>% filter(is.na(child_wasting_rate)) %>% pull(Country) %>% sort()

# Save results for markdown generation
results <- list(
  summary = summary_data,
  missing = list(
    undernourishment = missing_undernourishment,
    gdp = missing_gdp,
    life_expectancy = missing_life_exp,
    population = missing_pop,
    poverty_pip = missing_poverty_pip,
    poverty_owid = missing_poverty_owid,
    wfp_markets = missing_wfp,
    who_stunting = missing_who_stunting,
    stunting_gdl = missing_stunting_gdl,
    tfp = missing_tfp,
    food_supply = missing_food_supply,
    climate = missing_climate,
    infant_mortality = missing_infant_mort,
    under5_mortality = missing_under5_mort,
    wasting = missing_wasting
  ),
  counts = list(
    total = total_countries,
    undernourishment = sum(!is.na(summary_data$undernourishment_rate)),
    gdp = sum(!is.na(summary_data$gdp_per_capita)),
    life_expectancy = sum(!is.na(summary_data$life_expectancy)),
    population = sum(!is.na(summary_data$population)),
    poverty_pip = sum(!is.na(summary_data$poverty_headcount)),
    poverty_owid = sum(!is.na(summary_data$poverty_below_3usd)),
    wfp_markets = sum(!is.na(summary_data$total_markets)),
    who_stunting = sum(!is.na(summary_data$who_stunting_rate)),
    stunting_gdl = sum(!is.na(summary_data$child_stunting_rate)),
    tfp = sum(!is.na(summary_data$tfp_index)),
    food_supply = sum(!is.na(summary_data$food_supply_kcal)),
    climate = sum(!is.na(summary_data$climate_vulnerability_index)),
    infant_mortality = sum(!is.na(summary_data$infant_mortality)),
    under5_mortality = sum(!is.na(summary_data$under5_mortality)),
    wasting = sum(!is.na(summary_data$child_wasting_rate))
  )
)

saveRDS(results, "data_analysis_results.rds")
cat("\n\nResults saved to data_analysis_results.rds\n")
cat("Summary data saved to data_coverage_detailed.csv\n")
write_csv(summary_data, 'data_coverage_detailed.csv')

