# Quick Start Script for Hunger Research Project
# This script sets up the environment and collects initial data

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install and load required packages
required_packages <- c("tidyverse", "WDI", "here", "lubridate")

# Install missing packages
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) {
  cat("Installing packages:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages, dependencies = TRUE)
}

# Load packages
library(tidyverse)
library(WDI)
library(here)
library(lubridate)

cat("Packages loaded successfully!\n")

# Set working directory
setwd(here())

# Create data directories if they don't exist
dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

cat("Directories created successfully!\n")

# Collect World Bank data
cat("Collecting World Bank data...\n")

# Key indicators for hunger research
indicators <- c(
  "SP.POP.TOTL",           # Population, total
  "NY.GDP.MKTP.CD",        # GDP (current US$)
  "NY.GDP.PCAP.CD",        # GDP per capita (current US$)
  "FP.CPI.TOTL.ZG",        # Inflation, consumer prices (annual %)
  "SI.POV.DDAY",           # Poverty headcount ratio at $1.90/day
  "AG.LND.AGRI.ZS",        # Agricultural land (% of land area)
  "AG.PRD.CROP.XD",        # Crop production index
  "SP.RUR.TOTL.ZS",        # Rural population (% of total population)
  "SP.URB.TOTL.IN.ZS",     # Urban population (% of total)
  "SE.ADT.LITR.ZS",        # Literacy rate, adult total (% of people ages 15+)
  "SP.DYN.LE00.IN",        # Life expectancy at birth, total (years)
  "SP.DYN.IMRT.IN",        # Mortality rate, infant (per 1,000 live births)
  "AG.CON.FERT.ZS",        # Fertilizer consumption (kilograms per hectare of arable land)
  "AG.LND.ARBL.ZS",        # Arable land (% of land area)
  "SP.POP.GROW",           # Population growth (annual %)
  "NY.GDP.MKTP.KD.ZG",     # GDP growth (annual %)
  "NE.TRD.GNFS.ZS",        # Trade (% of GDP)
  "NE.EXP.GNFS.ZS",        # Exports of goods and services (% of GDP)
  "NE.IMP.GNFS.ZS"         # Imports of goods and services (% of GDP)
)

# Collect data for all countries
wb_data <- WDI(country = "all", 
               indicator = indicators,
               start = 2000, 
               end = 2023,
               extra = TRUE)

# Clean column names
names(wb_data) <- gsub("^SP\\.", "pop_", names(wb_data))
names(wb_data) <- gsub("^NY\\.", "gdp_", names(wb_data))
names(wb_data) <- gsub("^FP\\.", "inflation_", names(wb_data))
names(wb_data) <- gsub("^SI\\.", "poverty_", names(wb_data))
names(wb_data) <- gsub("^AG\\.", "agriculture_", names(wb_data))
names(wb_data) <- gsub("^SE\\.", "education_", names(wb_data))
names(wb_data) <- gsub("^NE\\.", "trade_", names(wb_data))

# Save raw data
write_csv(wb_data, "data/raw/world_bank_data.csv")

cat("World Bank data collected and saved!\n")
cat("Total records:", nrow(wb_data), "\n")
cat("Countries:", length(unique(wb_data$country)), "\n")
cat("Years:", min(wb_data$year, na.rm = TRUE), "to", max(wb_data$year, na.rm = TRUE), "\n")

# Create basic summary statistics
cat("Creating summary statistics...\n")

summary_stats <- wb_data %>%
  group_by(country) %>%
  summarise(
    latest_population = last(pop_TOTL, order_by = year),
    latest_gdp = last(gdp_MKTP.CD, order_by = year),
    latest_gdp_per_capita = last(gdp_PCAP.CD, order_by = year),
    latest_inflation = last(inflation_TOTL.ZG, order_by = year),
    latest_poverty = last(poverty_DDAY, order_by = year),
    latest_agriculture_land = last(agriculture_LND.AGRI.ZS, order_by = year),
    latest_crop_production = last(agriculture_PRD.CROP.XD, order_by = year),
    latest_rural_pop = last(pop_RUR.TOTL.ZS, order_by = year),
    latest_life_expectancy = last(pop_DYN.LE00.IN, order_by = year),
    latest_infant_mortality = last(pop_DYN.IMRT.IN, order_by = year),
    .groups = "drop"
  ) %>%
  filter(!is.na(latest_population)) %>%
  arrange(desc(latest_population))

# Save summary
write_csv(summary_stats, "data/processed/world_bank_summary.csv")

cat("Summary statistics created and saved!\n")
cat("Top 10 countries by population:\n")
print(head(summary_stats, 10))

# Create basic visualization
cat("Creating basic visualization...\n")

# GDP vs Population scatter plot
p1 <- ggplot(summary_stats %>% filter(!is.na(latest_gdp) & !is.na(latest_population)), 
             aes(x = latest_population/1000000, y = latest_gdp/1000000000)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(
    title = "GDP vs Population by Country (Latest Available Data)",
    x = "Population (Millions)",
    y = "GDP (Billions USD)",
    subtitle = "Data from World Bank"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )

# Save plot
ggsave("outputs/figures/gdp_vs_population.png", p1, width = 10, height = 6, dpi = 300)

# Poverty vs GDP per capita
p2 <- ggplot(summary_stats %>% filter(!is.na(latest_poverty) & !is.na(latest_gdp_per_capita)), 
             aes(x = latest_gdp_per_capita, y = latest_poverty)) +
  geom_point(alpha = 0.6, color = "darkgreen") +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(
    title = "Poverty Rate vs GDP per Capita by Country",
    x = "GDP per Capita (USD)",
    y = "Poverty Rate (% living on <$1.90/day)",
    subtitle = "Data from World Bank"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )

# Save plot
ggsave("outputs/figures/poverty_vs_gdp_per_capita.png", p2, width = 10, height = 6, dpi = 300)

cat("Visualizations created and saved!\n")
cat("Files created:\n")
cat("- data/raw/world_bank_data.csv\n")
cat("- data/processed/world_bank_summary.csv\n")
cat("- outputs/figures/gdp_vs_population.png\n")
cat("- outputs/figures/poverty_vs_gdp_per_capita.png\n")

# Create data quality report
cat("Creating data quality report...\n")

missing_summary <- wb_data %>%
  summarise_all(~sum(is.na(.))) %>%
  gather(key = "variable", value = "missing_count") %>%
  arrange(desc(missing_count))

write_csv(missing_summary, "data/processed/missing_data_summary.csv")

cat("Data quality report saved to data/processed/missing_data_summary.csv\n")

# Print some interesting findings
cat("\nINTERESTING FINDINGS:\n")
cat("====================\n")

# Countries with highest poverty rates
high_poverty <- summary_stats %>%
  filter(!is.na(latest_poverty)) %>%
  arrange(desc(latest_poverty)) %>%
  head(5)

cat("Top 5 countries with highest poverty rates:\n")
for(i in 1:nrow(high_poverty)) {
  cat(sprintf("%d. %s: %.1f%%\n", i, high_poverty$country[i], high_poverty$latest_poverty[i]))
}

# Countries with lowest GDP per capita
low_gdp <- summary_stats %>%
  filter(!is.na(latest_gdp_per_capita)) %>%
  arrange(latest_gdp_per_capita) %>%
  head(5)

cat("\nTop 5 countries with lowest GDP per capita:\n")
for(i in 1:nrow(low_gdp)) {
  cat(sprintf("%d. %s: $%.0f\n", i, low_gdp$country[i], low_gdp$latest_gdp_per_capita[i]))
}

# Countries with highest agricultural land percentage
high_ag <- summary_stats %>%
  filter(!is.na(latest_agriculture_land)) %>%
  arrange(desc(latest_agriculture_land)) %>%
  head(5)

cat("\nTop 5 countries with highest agricultural land percentage:\n")
for(i in 1:nrow(high_ag)) {
  cat(sprintf("%d. %s: %.1f%%\n", i, high_ag$country[i], high_ag$latest_agriculture_land[i]))
}

cat("\nInitial data collection and analysis completed successfully!\n")
cat("You now have a solid foundation to build your hunger research project.\n")
cat("Next steps:\n")
cat("1. Explore the data files created\n")
cat("2. Review the visualizations\n")
cat("3. Begin learning R following the roadmap\n")
cat("4. Collect additional data from FAO, WFP, and EM-DAT\n")
