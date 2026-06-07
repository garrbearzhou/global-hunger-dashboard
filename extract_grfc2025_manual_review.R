# Create a manual review file with extracted data for verification
library(tidyverse)

cat("📊 Creating GRFC 2025 Data for Manual Review\n")
cat("============================================\n\n")

# Read the current extraction
current_data <- read_csv("data/raw/wfp/grfc2025_data.csv", show_col_types = FALSE)

cat("✅ Loaded current extraction:", nrow(current_data), "countries\n\n")

# Filter out obviously wrong data (populations that exceed country's total population)
# Use rough population estimates to filter
country_pop_limits <- data.frame(
  country = c("Gaza", "Sudan", "Uganda", "Chad", "Malawi", "Zimbabwe", 
              "Gambia", "Ghana", "Haiti", "Republic of the Congo"),
  max_pop = c(2500000, 50000000, 50000000, 20000000, 20000000, 16000000,
              3000000, 35000000, 12000000, 6000000),
  stringsAsFactors = FALSE
)

# Clean the data
cleaned_data <- current_data %>%
  left_join(country_pop_limits, by = "country") %>%
  mutate(
    # Flag suspiciously high populations
    population_phase3_plus = ifelse(
      !is.na(max_pop) & !is.na(population_phase3_plus) & population_phase3_plus > max_pop,
      NA,  # Set to NA if exceeds country's total population
      population_phase3_plus
    )
  ) %>%
  select(-max_pop) %>%
  # Remove rows with no useful data
  filter(!is.na(ipc_phase) | !is.na(population_phase3_plus))

cat("✅ Cleaned data:", nrow(cleaned_data), "countries with valid data\n\n")

# Show what we have
cat("📊 Current Data Summary:\n")
cat("=======================\n")
cat("Countries with IPC Phase 4 or 5:", sum(cleaned_data$ipc_phase >= 4, na.rm = TRUE), "\n")
cat("Countries with IPC Phase 3:", sum(cleaned_data$ipc_phase == 3, na.rm = TRUE), "\n")
cat("Countries with population data:", sum(!is.na(cleaned_data$population_phase3_plus)), "\n\n")

# Show countries that need manual verification
cat("⚠️ Countries needing manual verification (suspicious data):\n")
suspicious <- current_data %>%
  anti_join(cleaned_data, by = "country") %>%
  filter(!is.na(population_phase3_plus))
if(nrow(suspicious) > 0) {
  print(suspicious %>% select(country, population_phase3_plus, ipc_phase))
} else {
  cat("  None - all data looks reasonable\n")
}
cat("\n")

# Save cleaned version
write_csv(cleaned_data, "data/raw/wfp/grfc2025_data.csv")
cat("💾 Saved cleaned data to: data/raw/wfp/grfc2025_data.csv\n\n")

# Create a manual review checklist
cat("📋 Manual Review Checklist:\n")
cat("===========================\n")
cat("The following countries have data but may need verification:\n\n")

for(i in 1:nrow(cleaned_data)) {
  row <- cleaned_data[i, ]
  cat(sprintf("%d. %s\n", i, row$country))
  if(!is.na(row$ipc_phase)) {
    cat(sprintf("   IPC Phase: %d\n", row$ipc_phase))
  }
  if(!is.na(row$population_phase3_plus)) {
    cat(sprintf("   Population Phase 3+: %.1fM\n", row$population_phase3_plus / 1000000))
  }
  if(!is.na(row$primary_driver)) {
    cat(sprintf("   Primary Driver: %s\n", row$primary_driver))
  }
  cat("\n")
}

cat("✅ Review complete!\n")
cat("💡 Next step: Manually verify these numbers in the PDF and update as needed\n")

