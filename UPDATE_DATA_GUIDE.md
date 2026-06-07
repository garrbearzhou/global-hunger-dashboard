## Quick Update Process

When you add new CSV files to the `data/` directory, follow these steps:

### 1. Run the Update Script

Simply run the data compilation script:

```bash
cd "/Users/27zhou/Documents/Research Project"
Rscript create_comprehensive_data_table.R
```

This will:
- Load all data sources from `data/raw/` and `data/processed/`
- Combine them into a single comprehensive table
- Calculate the hunger vulnerability rating
- Save to `comprehensive_country_data.csv`

### 2. Data Source Locations

The script automatically loads data from:

- **FAO Data:** `data/raw/fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv`
- **World Bank Data:** `data/raw/world bank/world_bank_data.csv`
- **PIP Poverty Data:** `data/raw/world bank/pip 2.csv`
- **WFP Market Data:** `data/raw/wfp/markets.csv`
- **New Data Sources:** `data/processed/new_data_sources_combined.csv`

### 3. Adding New Data Sources

To add a new data source:

1. **Place your CSV file** in the appropriate `data/raw/` or `data/processed/` folder
2. **Update the script** (`create_comprehensive_data_table.R`):
   - Add a section to load your new CSV
   - Process/standardize the data (country names, etc.)
   - Join it to the comprehensive_data table
   - Add the new columns to the final select() statement

3. **Re-run the script** to generate the updated CSV

### 4. Example: Adding a New Data Source

```r
# In create_comprehensive_data_table.R, add:

# Load your new data
cat("Loading new data source...\n")
new_source <- read_csv("data/raw/your_folder/your_data.csv", show_col_types = FALSE)

# Process it (standardize country names, etc.)
new_source_processed <- new_source %>%
  mutate(country = standardize_country_names(country)) %>%
  # ... your processing logic ...

# Join it to comprehensive_data
comprehensive_data <- comprehensive_data %>%
  left_join(
    new_source_processed %>% rename(Country = country),
    by = "Country"
  )

# Add to final select() statement
select(
  Country,
  # ... existing columns ...
  your_new_column_1,
  your_new_column_2
)
```
### 5. Data Format Requirements

For new data sources to integrate smoothly:

- **Country Name Column:** Should match standard country names (use `standardize_country_names()` function)
- **One Row Per Country:** If you have time series data, aggregate to most recent value per country
- **Numeric Columns:** Should be numeric type (not character)
- **Missing Data:** Use `NA` for missing values

### 6. Verification

After updating, verify the CSV:

```r
library(tidyverse)
df <- read_csv("comprehensive_country_data.csv", show_col_types = FALSE)
cat("Total countries:", nrow(df), "\n")
cat("Total columns:", ncol(df), "\n")
cat("Countries with new data:", sum(!is.na(df$your_new_column)), "\n")
```

## Troubleshooting

### Issue: Country names don't match
- **Solution:** Use the `standardize_country_names()` function or add mappings to `country_name_mapping.csv`

### Issue: Too many rows per country
- **Solution:** Aggregate your data to one row per country (use `group_by()` and `summarise()`)

### Issue: Column type errors
- **Solution:** Ensure numeric columns are actually numeric (use `as.numeric()` if needed)

### Issue: Script runs but data missing
- **Solution:** Check that the join keys match (country names are standardized)

---

## Data caveats / notes for reviewers

**Botswana and Gabon — undernourishment vs. GDP:** Both show moderately high undernourishment despite middle-income GDP per capita. This is plausible, not a data error: both have high inequality (e.g. Botswana has one of the world’s highest Gini coefficients), so national GDP per capita can mask severe food insecurity among the poor. Worth noting if a reviewer questions the pattern.

