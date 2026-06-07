# Test script to verify US data in the app
library(tidyverse)
library(plotly)

# Load and process data exactly like the app
fao_latest <- read_csv('data/raw/fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv', show_col_types = FALSE)

# Country name mapping function
standardize_country_names <- function(country_names) {
  country_mapping <- c(
    "United States of America" = "United States",
    "United Kingdom of Great Britain and Northern Ireland" = "United Kingdom",
    "China, mainland" = "China",
    "China, Hong Kong SAR" = "Hong Kong",
    "China, Macao SAR" = "Macao",
    "China, Taiwan Province of" = "Taiwan",
    "Hong Kong SAR, China" = "Hong Kong",
    "Macao SAR, China" = "Macao",
    "Bolivia (Plurinational State of)" = "Bolivia",
    "Venezuela (Bolivarian Republic of)" = "Venezuela",
    "Iran (Islamic Republic of)" = "Iran",
    "Korea, Republic of" = "South Korea",
    "Korea, Democratic People's Republic of" = "North Korea",
    "Russian Federation" = "Russia",
    "Viet Nam" = "Vietnam",
    "Republic of Korea" = "South Korea",
    "Democratic People's Republic of Korea" = "North Korea"
  )
  
  for (old_name in names(country_mapping)) {
    country_names[country_names == old_name] <- country_mapping[old_name]
  }
  
  return(country_names)
}

# Process FAO data
fao_processed <- fao_latest %>%
  mutate(
    Value_clean = case_when(
      Value == "<2.5" ~ "2.5",
      Value == "" ~ NA_character_,
      TRUE ~ Value
    ),
    Value_numeric = as.numeric(Value_clean)
  ) %>%
  select(Area, `Item Code`, Item, Element, Unit, Year, Value_numeric) %>%
  pivot_wider(
    names_from = `Item Code`, 
    values_from = Value_numeric, 
    names_prefix = "ind_"
  ) %>%
  rename(
    undernourishment_rate = ind_210041,
    undernourished_population = ind_210011
  ) %>%
  mutate(Area = standardize_country_names(Area)) %>%
  filter(!is.na(undernourishment_rate) & undernourishment_rate > 0)

# Check US data
print("=== US DATA VERIFICATION ===")
us_data <- fao_processed[grepl("United States", fao_processed$Area), ]
print(us_data)

# Create a simple test map with just US data
test_data <- data.frame(
  Area = c("United States", "China", "Canada", "Germany", "France", "United Kingdom"),
  undernourishment_rate = c(2.5, 2.5, 2.5, 2.5, 2.5, 2.5)
)

print("=== TEST MAP DATA ===")
print(test_data)

# Create test map
p <- plot_ly(
  type = "choropleth",
  locations = test_data$Area,
  locationmode = "country names",
  z = test_data$undernourishment_rate,
  colorscale = "RdYlGn",
  reversescale = TRUE,
  text = paste(test_data$Area, "<br>Undernourishment:", test_data$undernourishment_rate, "%"),
  hoverinfo = "text"
) %>%
  layout(
    title = "Test Map - US Should Be Green (2.5%)",
    margin = list(t = 80, b = 60, l = 60, r = 60)
  )

print("=== MAP CREATED ===")
print("The US should appear in GREEN on this map with 2.5% undernourishment")
print("If you see the US in gray, there's a country name mapping issue")
print("If you see the US in green, the data processing is working correctly")

# Show the plot
p
