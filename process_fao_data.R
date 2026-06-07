# FAO Data Processing Script
# This script processes and analyzes the FAO food security data

library(tidyverse)
library(readr)

cat("🌍 Processing FAO Food Security Data...\n")
cat("=====================================\n")

# Load FAO data files
fao_main <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data_NOFLAG.csv", show_col_types = FALSE)
area_codes <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_AreaCodes.csv", show_col_types = FALSE)
element_codes <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_Elements.csv", show_col_types = FALSE)
item_codes <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_ItemCodes.csv", show_col_types = FALSE)

cat("✅ FAO data loaded successfully!\n")
cat("📊 Total FAO records:", nrow(fao_main), "\n")
cat("🌍 Countries in FAO data:", length(unique(fao_main$Area)), "\n")
cat("📅 Years covered:", min(grep("^Y[0-9]", names(fao_main), value = TRUE)), "to", max(grep("^Y[0-9]", names(fao_main), value = TRUE)), "\n")

# Get year columns (3-year averages)
year_cols <- c("Y20002002", "Y20012003", "Y20022004", "Y20032005", "Y20042006", "Y20052007", 
               "Y20062008", "Y20072009", "Y20082010", "Y20092011", "Y20102012", "Y20112013", 
               "Y20122014", "Y20132015", "Y20142016", "Y20152017", "Y20162018", "Y20172019", 
               "Y20182020", "Y20192021", "Y20202022", "Y20212023", "Y20222024")

# Key indicators for hunger research
key_indicators <- c(
  "210041" = "Prevalence of undernourishment (percent) (3-year average)",
  "210011" = "Number of people undernourished (million) (3-year average)",
  "210401" = "Prevalence of severe food insecurity in the total population (percent) (3-year average)",
  "210091" = "Prevalence of moderate or severe food insecurity in the total population (percent) (3-year average)",
  "21010" = "Average dietary energy supply adequacy (percent) (3-year average)",
  "22013" = "Gross domestic product per capita, PPP, (constant 2021 international $)",
  "21035" = "Cereal import dependency ratio (percent) (3-year average)",
  "21033" = "Value of food imports in total merchandise exports (percent) (3-year average)",
  "21032" = "Political stability and absence of violence/terrorism (index)"
)

cat("\n🔍 Key indicators found:\n")
for(code in names(key_indicators)) {
  count <- sum(fao_main$`Item Code` == code, na.rm = TRUE)
  cat("  ", code, ":", key_indicators[code], "(", count, "records )\n")
}

# Process data for analysis
process_fao_data <- function() {
  cat("\n🔄 Processing FAO data for analysis...\n")
  
  # Filter for key indicators and value elements only
  fao_processed <- fao_main %>%
    filter(`Item Code` %in% names(key_indicators) & `Element Code` == 6121) %>%  # Value elements only
    select(Area, `Item Code`, Item, Element, Unit, all_of(year_cols)) %>%
    pivot_longer(cols = all_of(year_cols), 
                 names_to = "Year", 
                 values_to = "Value") %>%
    mutate(Year = as.numeric(substr(Year, 2, 5)),  # Extract start year from Y20002002 format
           Value = as.numeric(Value)) %>%  # Convert values to numeric
    filter(!is.na(Value) & Value != 0) %>%
    pivot_wider(names_from = `Item Code`, values_from = Value, names_prefix = "ind_")
  
  cat("✅ Data processed successfully!\n")
  cat("📊 Records after processing:", nrow(fao_processed), "\n")
  
  return(fao_processed)
}

# Create summary data for latest available year per country
create_summary_data <- function(fao_processed) {
  cat("\n🔄 Creating summary data...\n")
  
  summary_data <- fao_processed %>%
    group_by(Area) %>%
    summarise(
      latest_year = max(Year, na.rm = TRUE),
      undernourishment_rate = last(ind_210041, order_by = Year),
      severe_food_insecurity = last(ind_210401, order_by = Year),
      moderate_severe_food_insecurity = last(ind_210091, order_by = Year),
      dietary_energy_adequacy = last(ind_21010, order_by = Year),
      cereal_import_dependency = last(ind_21035, order_by = Year),
      food_import_value = last(ind_21033, order_by = Year),
      .groups = "drop"
    ) %>%
    filter(!is.na(undernourishment_rate)) %>%
    mutate(
      # Create hunger risk categories based on undernourishment rate
      hunger_risk = case_when(
        undernourishment_rate >= 25 ~ "Critical",
        undernourishment_rate >= 15 ~ "High",
        undernourishment_rate >= 10 ~ "Medium", 
        undernourishment_rate >= 5 ~ "Low",
        TRUE ~ "Very Low"
      ),
      hunger_risk = factor(hunger_risk, levels = c("Very Low", "Low", "Medium", "High", "Critical")),
      
      # Create food insecurity categories
      food_insecurity_level = case_when(
        moderate_severe_food_insecurity >= 50 ~ "Very High",
        moderate_severe_food_insecurity >= 30 ~ "High",
        moderate_severe_food_insecurity >= 15 ~ "Medium",
        moderate_severe_food_insecurity >= 5 ~ "Low",
        TRUE ~ "Very Low"
      ),
      food_insecurity_level = factor(food_insecurity_level, levels = c("Very Low", "Low", "Medium", "High", "Very High")),
      
      # Economic development categories (based on food import value as proxy)
      development_level = case_when(
        food_import_value >= 50 ~ "High Income",
        food_import_value >= 30 ~ "Upper Middle Income",
        food_import_value >= 15 ~ "Lower Middle Income",
        food_import_value >= 5 ~ "Low Income",
        TRUE ~ "Very Low Income"
      ),
      development_level = factor(development_level, levels = c("Very Low Income", "Low Income", "Lower Middle Income", "Upper Middle Income", "High Income"))
    )
  
  cat("✅ Summary data created successfully!\n")
  cat("📊 Countries with complete data:", nrow(summary_data), "\n")
  cat("📅 Latest year range:", min(summary_data$latest_year), "to", max(summary_data$latest_year), "\n")
  
  return(summary_data)
}

# Generate data insights
generate_insights <- function(summary_data) {
  cat("\n📊 Generating data insights...\n")
  
  # Global statistics
  avg_undernourishment <- mean(summary_data$undernourishment_rate, na.rm = TRUE)
  critical_countries <- sum(summary_data$hunger_risk == "Critical", na.rm = TRUE)
  high_risk_countries <- sum(summary_data$hunger_risk %in% c("Critical", "High"), na.rm = TRUE)
  
  cat("\n🌍 Global Hunger Statistics:\n")
  cat("  Average undernourishment rate:", round(avg_undernourishment, 1), "%\n")
  cat("  Countries with critical hunger risk:", critical_countries, "\n")
  cat("  Countries with high/critical hunger risk:", high_risk_countries, "\n")
  
  # Top countries by undernourishment
  top_undernourished <- summary_data %>%
    arrange(desc(undernourishment_rate)) %>%
    head(10)
  
  cat("\n🔴 Top 10 Countries by Undernourishment Rate:\n")
  for(i in 1:nrow(top_undernourished)) {
    cat("  ", i, ".", top_undernourished$Area[i], ":", round(top_undernourished$undernourishment_rate[i], 1), "%\n")
  }
  
  # Countries with highest food insecurity
  top_food_insecure <- summary_data %>%
    arrange(desc(moderate_severe_food_insecurity)) %>%
    head(10)
  
  cat("\n🍽️ Top 10 Countries by Food Insecurity Rate:\n")
  for(i in 1:nrow(top_food_insecure)) {
    cat("  ", i, ".", top_food_insecure$Area[i], ":", round(top_food_insecure$moderate_severe_food_insecurity[i], 1), "%\n")
  }
  
  # Risk distribution
  risk_distribution <- summary_data %>%
    count(hunger_risk) %>%
    mutate(percentage = n / sum(n) * 100)
  
  cat("\n📊 Hunger Risk Distribution:\n")
  for(i in 1:nrow(risk_distribution)) {
    cat("  ", risk_distribution$hunger_risk[i], ":", risk_distribution$n[i], "countries (", round(risk_distribution$percentage[i], 1), "%)\n")
  }
  
  # Development level distribution
  dev_distribution <- summary_data %>%
    count(development_level) %>%
    mutate(percentage = n / sum(n) * 100)
  
  cat("\n🏗️ Development Level Distribution:\n")
  for(i in 1:nrow(dev_distribution)) {
    cat("  ", dev_distribution$development_level[i], ":", dev_distribution$n[i], "countries (", round(dev_distribution$percentage[i], 1), "%)\n")
  }
}

# Save processed data
save_processed_data <- function(fao_processed, summary_data) {
  cat("\n💾 Saving processed data...\n")
  
  # Create processed data directory
  dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
  
  # Save processed data
  write_csv(fao_processed, "data/processed/fao_time_series_data.csv")
  write_csv(summary_data, "data/processed/fao_summary_data.csv")
  
  cat("✅ Processed data saved to:\n")
  cat("  data/processed/fao_time_series_data.csv\n")
  cat("  data/processed/fao_summary_data.csv\n")
}

# Main execution
fao_processed <- process_fao_data()
summary_data <- create_summary_data(fao_processed)
generate_insights(summary_data)
save_processed_data(fao_processed, summary_data)

cat("\n🎉 FAO data processing completed successfully!\n")
cat("=============================================\n")
cat("✅ Data is ready for the website integration\n")
cat("🚀 Run 'launch_fao_app.R' to start the website\n")
