# Multiple Regression Analysis for Hunger Vulnerability
# This script analyzes the relationship between hunger and various factors
# to determine true impact, statistical significance, and optimal coefficients

library(tidyverse)
library(broom)  # For tidy regression output

# Try to load car package for VIF, but make it optional
if (require(car, quietly = TRUE)) {
  has_car <- TRUE
} else {
  has_car <- FALSE
  cat("Note: 'car' package not available. VIF calculations will be skipped.\n")
  cat("Install with: install.packages('car')\n\n")
}

# Load the data (same as the app)
cat("📊 Loading data for regression analysis...\n")

# Source the data loading functions from the main app
source('enhanced_fao_wfp_app.R', local = TRUE)

# Prepare data for regression
# We'll use undernourishment_rate as the dependent variable (direct hunger measure)
# and all relevant factors as independent variables

regression_data <- sovereign_countries %>%
  select(
    Area,
    # Dependent variable
    undernourishment_rate,
    
    # Independent variables
    poverty_headcount,      # Poverty rate (0-1 scale from PIP)
    poverty_rate,           # Alternative poverty measure (%)
    gdp_per_capita,        # Economic development
    life_expectancy,       # Health indicator
    gini_coefficient,      # Inequality measure
    total_markets,         # Market access (WFP)
    population,            # Population size
    major_hunger_outbreak_21st,  # Historical crisis (binary)
    region                 # Regional factor (categorical)
  ) %>%
  # Create binary variable for historical outbreaks
  mutate(
    outbreak_binary = as.numeric(major_hunger_outbreak_21st),
    # Use poverty_headcount if available, otherwise poverty_rate/100
    poverty_combined = ifelse(!is.na(poverty_headcount), 
                              poverty_headcount, 
                              ifelse(!is.na(poverty_rate), poverty_rate/100, NA)),
    # Log transform GDP for better distribution (handle zeros)
    log_gdp = log1p(gdp_per_capita),  # log1p = log(1+x) to handle zeros
    # Log transform population
    log_population = log1p(population),
    # Market access: use inverse (fewer markets = higher vulnerability)
    market_access_inverse = ifelse(is.na(total_markets) | total_markets == 0, 
                                   100,  # High penalty for no markets
                                   100 / (total_markets + 1))  # Inverse relationship
  ) %>%
  # Keep only countries with undernourishment data (our dependent variable)
  filter(!is.na(undernourishment_rate))

cat(sprintf("✅ Data prepared: %d countries with undernourishment data\n", nrow(regression_data)))
complete_cases_count <- sum(complete.cases(regression_data %>% select(undernourishment_rate, poverty_combined, 
                                                                      gdp_per_capita, life_expectancy, 
                                                                      gini_coefficient, outbreak_binary)))
cat(sprintf("   Countries with complete data for all variables: %d\n", complete_cases_count))

# ============================================================================
# MODEL 1: Basic Multiple Regression (using most complete variables)
# ============================================================================

cat("\n", rep("=", 70), "\n", sep="")
cat("MODEL 1: Basic Multiple Regression\n")
cat(rep("=", 70), "\n", sep="")
cat("\n")

model1_data <- regression_data %>%
  filter(
    !is.na(undernourishment_rate),
    !is.na(poverty_combined),
    !is.na(gdp_per_capita),
    !is.na(life_expectancy),
    !is.na(outbreak_binary)
  )

cat(sprintf("Sample size: %d countries\n\n", nrow(model1_data)))

# Fit the model
model1 <- lm(undernourishment_rate ~ 
             poverty_combined + 
             gdp_per_capita + 
             life_expectancy + 
             outbreak_binary,
             data = model1_data)

# Summary
cat("REGRESSION SUMMARY:\n")
print(summary(model1))

# Tidy output for better formatting
cat("\nCOEFFICIENTS WITH STATISTICAL SIGNIFICANCE:\n")
coef_table <- tidy(model1, conf.int = TRUE) %>%
  mutate(
    significance = case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01 ~ "**",
      p.value < 0.05 ~ "*",
      p.value < 0.1 ~ ".",
      TRUE ~ ""
    ),
    interpretation = case_when(
      term == "(Intercept)" ~ "Baseline undernourishment rate",
      term == "poverty_combined" ~ "For each 1% increase in poverty, undernourishment increases by this amount",
      term == "gdp_per_capita" ~ "For each $1 increase in GDP per capita, undernourishment decreases by this amount",
      term == "life_expectancy" ~ "For each 1 year increase in life expectancy, undernourishment decreases by this amount",
      term == "outbreak_binary" ~ "Countries with historical hunger outbreaks have this much higher undernourishment",
      TRUE ~ ""
    )
  )

print(coef_table %>% 
      select(term, estimate, std.error, statistic, p.value, significance, conf.low, conf.high, interpretation))

# Model diagnostics
cat("\n\nMODEL DIAGNOSTICS:\n")
cat(sprintf("R-squared: %.4f (%.2f%% of variance explained)\n", 
            summary(model1)$r.squared, summary(model1)$r.squared * 100))
cat(sprintf("Adjusted R-squared: %.4f\n", summary(model1)$adj.r.squared))
cat(sprintf("F-statistic: %.2f (p-value: %.2e)\n", 
            summary(model1)$fstatistic[1], 
            pf(summary(model1)$fstatistic[1], 
               summary(model1)$fstatistic[2], 
               summary(model1)$fstatistic[3], 
               lower.tail = FALSE)))

# Check for multicollinearity (if car package available)
if (has_car) {
  cat("\n\nMULTICOLLINEARITY CHECK (VIF):\n")
  cat("Values > 5 indicate potential multicollinearity issues\n")
  vif_values <- vif(model1)
  print(vif_values)
} else {
  cat("\n\nMULTICOLLINEARITY CHECK:\n")
  cat("(VIF calculation skipped - install 'car' package for VIF values)\n")
  cat("Check correlation matrix instead:\n")
  cor_vars <- model1_data %>% select(poverty_combined, gdp_per_capita, life_expectancy, outbreak_binary)
  print(cor(cor_vars, use = "complete.obs"))
}

# ============================================================================
# MODEL 2: Extended Model (including inequality and market access)
# ============================================================================

cat("\n\n", rep("=", 70), "\n", sep="")
cat("MODEL 2: Extended Model (with Inequality & Market Access)\n")
cat(rep("=", 70), "\n", sep="")
cat("\n")

model2_data <- regression_data %>%
  filter(
    !is.na(undernourishment_rate),
    !is.na(poverty_combined),
    !is.na(gdp_per_capita),
    !is.na(life_expectancy),
    !is.na(gini_coefficient),
    !is.na(outbreak_binary)
  )

cat(sprintf("Sample size: %d countries\n\n", nrow(model2_data)))

model2 <- lm(undernourishment_rate ~ 
             poverty_combined + 
             gdp_per_capita + 
             life_expectancy + 
             gini_coefficient +
             outbreak_binary,
             data = model2_data)

cat("REGRESSION SUMMARY:\n")
print(summary(model2))

cat("\nCOEFFICIENTS WITH STATISTICAL SIGNIFICANCE:\n")
coef_table2 <- tidy(model2, conf.int = TRUE) %>%
  mutate(
    significance = case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01 ~ "**",
      p.value < 0.05 ~ "*",
      p.value < 0.1 ~ ".",
      TRUE ~ ""
    )
  )

print(coef_table2 %>% 
      select(term, estimate, std.error, statistic, p.value, significance, conf.low, conf.high))

cat(sprintf("\nR-squared: %.4f | Adjusted R-squared: %.4f\n", 
            summary(model2)$r.squared, summary(model2)$adj.r.squared))

# ============================================================================
# MODEL 3: Model with Log-Transformed Variables (for better fit)
# ============================================================================

cat("\n\n", rep("=", 70), "\n", sep="")
cat("MODEL 3: Model with Log-Transformed GDP (better distribution)\n")
cat(rep("=", 70), "\n", sep="")
cat("\n")

model3_data <- regression_data %>%
  filter(
    !is.na(undernourishment_rate),
    !is.na(poverty_combined),
    !is.na(gdp_per_capita),
    !is.na(life_expectancy),
    !is.na(outbreak_binary)
  )

model3 <- lm(undernourishment_rate ~ 
             poverty_combined + 
             log_gdp + 
             life_expectancy + 
             outbreak_binary,
             data = model3_data)

cat("REGRESSION SUMMARY:\n")
print(summary(model3))

cat("\nCOEFFICIENTS WITH STATISTICAL SIGNIFICANCE:\n")
coef_table3 <- tidy(model3, conf.int = TRUE) %>%
  mutate(
    significance = case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01 ~ "**",
      p.value < 0.05 ~ "*",
      p.value < 0.1 ~ ".",
      TRUE ~ ""
    )
  )

print(coef_table3 %>% 
      select(term, estimate, std.error, statistic, p.value, significance, conf.low, conf.high))

cat(sprintf("\nR-squared: %.4f | Adjusted R-squared: %.4f\n", 
            summary(model3)$r.squared, summary(model3)$adj.r.squared))

# ============================================================================
# MODEL 4: Full Model with Regional Dummies
# ============================================================================

cat("\n\n", rep("=", 70), "\n", sep="")
cat("MODEL 4: Full Model with Regional Fixed Effects\n")
cat(rep("=", 70), "\n", sep="")
cat("\n")

model4_data <- regression_data %>%
  filter(
    !is.na(undernourishment_rate),
    !is.na(poverty_combined),
    !is.na(gdp_per_capita),
    !is.na(life_expectancy),
    !is.na(outbreak_binary),
    !is.na(region)
  ) %>%
  # Create regional dummy variables (Africa as reference)
  mutate(
    region_south_asia = as.numeric(region == "South Asia"),
    region_east_asia = as.numeric(region == "East Asia & Pacific"),
    region_latin_america = as.numeric(region == "Latin America & Caribbean"),
    region_middle_east = as.numeric(region == "Middle East & North Africa"),
    region_europe = as.numeric(region == "Europe & Central Asia"),
    region_north_america = as.numeric(region == "North America")
  )

cat(sprintf("Sample size: %d countries\n\n", nrow(model4_data)))

model4 <- lm(undernourishment_rate ~ 
             poverty_combined + 
             log_gdp + 
             life_expectancy + 
             outbreak_binary +
             region_south_asia +
             region_east_asia +
             region_latin_america +
             region_middle_east +
             region_europe +
             region_north_america,
             data = model4_data)

cat("REGRESSION SUMMARY:\n")
print(summary(model4))

cat("\nCOEFFICIENTS WITH STATISTICAL SIGNIFICANCE:\n")
coef_table4 <- tidy(model4, conf.int = TRUE) %>%
  mutate(
    significance = case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01 ~ "**",
      p.value < 0.05 ~ "*",
      p.value < 0.1 ~ ".",
      TRUE ~ ""
    )
  )

print(coef_table4 %>% 
      select(term, estimate, std.error, statistic, p.value, significance, conf.low, conf.high))

cat(sprintf("\nR-squared: %.4f | Adjusted R-squared: %.4f\n", 
            summary(model4)$r.squared, summary(model4)$adj.r.squared))

# ============================================================================
# COMPARISON OF MODELS
# ============================================================================

cat("\n\n", rep("=", 70), "\n", sep="")
cat("MODEL COMPARISON\n")
cat(rep("=", 70), "\n", sep="")
cat("\n")

comparison <- data.frame(
  Model = c("Model 1: Basic", "Model 2: + Inequality", "Model 3: Log GDP", "Model 4: + Regions"),
  R_squared = c(summary(model1)$r.squared, 
                summary(model2)$r.squared,
                summary(model3)$r.squared,
                summary(model4)$r.squared),
  Adj_R_squared = c(summary(model1)$adj.r.squared,
                    summary(model2)$adj.r.squared,
                    summary(model3)$adj.r.squared,
                    summary(model4)$adj.r.squared),
  AIC = c(AIC(model1), AIC(model2), AIC(model3), AIC(model4)),
  BIC = c(BIC(model1), BIC(model2), BIC(model3), BIC(model4)),
  N = c(nrow(model1_data), nrow(model2_data), nrow(model3_data), nrow(model4_data))
)

print(comparison)

# ============================================================================
# RECOMMENDATIONS FOR VULNERABILITY FORMULA
# ============================================================================

cat("\n\n", rep("=", 70), "\n", sep="")
cat("RECOMMENDATIONS FOR VULNERABILITY FORMULA\n")
cat(rep("=", 70), "\n", sep="")
cat("\n")

cat("Based on the regression analysis, here are the statistically significant factors:\n\n")

# Get significant coefficients from best model
best_model <- model4  # Using model with regions
significant_vars <- tidy(best_model) %>%
  filter(p.value < 0.05, term != "(Intercept)") %>%
  arrange(p.value)

cat("STATISTICALLY SIGNIFICANT VARIABLES (p < 0.05):\n")
for(i in 1:nrow(significant_vars)) {
  var <- significant_vars$term[i]
  coef <- significant_vars$estimate[i]
  pval <- significant_vars$p.value[i]
  
  cat(sprintf("%d. %s: coefficient = %.4f (p = %.4f)\n", 
              i, var, coef, pval))
}

cat("\n\nSUGGESTED WEIGHTS FOR VULNERABILITY FORMULA:\n")
cat("(Based on standardized coefficients and statistical significance)\n\n")

# Calculate standardized coefficients
model4_std <- lm(scale(undernourishment_rate) ~ 
                 scale(poverty_combined) + 
                 scale(log_gdp) + 
                 scale(life_expectancy) + 
                 outbreak_binary +
                 region_south_asia +
                 region_east_asia +
                 region_latin_america +
                 region_middle_east +
                 region_europe +
                 region_north_america,
                 data = model4_data)

std_coefs <- tidy(model4_std) %>%
  filter(term != "(Intercept)") %>%
  mutate(
    abs_std_coef = abs(estimate),
    relative_importance = abs_std_coef / sum(abs_std_coef, na.rm = TRUE) * 100
  ) %>%
  arrange(desc(abs_std_coef))

print(std_coefs %>% 
      select(term, estimate, abs_std_coef, relative_importance, p.value) %>%
      mutate(relative_importance = round(relative_importance, 2)))

cat("\n\nINTERPRETATION:\n")
cat("- Standardized coefficients show the relative importance of each factor\n")
cat("- Larger absolute values indicate stronger impact on undernourishment\n")
cat("- Use these to adjust weights in your vulnerability formula\n")

# Save results to CSV
write_csv(coef_table4, "regression_coefficients.csv")
write_csv(comparison, "model_comparison.csv")
write_csv(std_coefs, "standardized_coefficients.csv")

cat("\n\n✅ Results saved to:\n")
cat("   - regression_coefficients.csv\n")
cat("   - model_comparison.csv\n")
cat("   - standardized_coefficients.csv\n")

