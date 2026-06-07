# Multiple Regression Analysis Guide

## Overview

This document explains how to run and interpret the multiple regression analysis to determine the true impact of each variable on hunger vulnerability.

## How to Run the Analysis

Simply run:
```r
source('regression_analysis.R')
```

Or from command line:
```bash
Rscript regression_analysis.R
```

The script will:
1. Load all your data
2. Run 4 different regression models
3. Test statistical significance
4. Calculate standardized coefficients
5. Save results to CSV files

## Key Findings from the Analysis

### Statistically Significant Variables (p < 0.05)

Based on Model 4 (Full Model with Regional Fixed Effects):

1. **Historical Hunger Outbreaks** (p < 0.001) ***
   - Coefficient: +10.06 percentage points
   - **Interpretation**: Countries with major hunger outbreaks in the 21st century have, on average, 10% higher undernourishment rates
   - **Current weight in formula**: 20 points (out of 100)
   - **Recommendation**: This is correctly weighted - it's highly significant

2. **Poverty Rate** (p = 0.030) *
   - Coefficient: +9.06 percentage points per 1 unit increase in poverty (0-1 scale)
   - **Interpretation**: For each 10% increase in poverty rate, undernourishment increases by ~0.9 percentage points
   - **Current weight in formula**: 20 points (out of 100)
   - **Recommendation**: Weight seems appropriate

3. **East Asia & Pacific Region** (p = 0.012) *
   - Coefficient: -5.78 percentage points (compared to Africa baseline)
   - **Interpretation**: Countries in East Asia & Pacific have 5.78% lower undernourishment than Africa
   - **Current weight in formula**: 5 points (out of 100)
   - **Recommendation**: Regional effects are significant and should be considered

### Variables NOT Statistically Significant

1. **GDP per Capita** (p = 0.22)
   - Not significant in the model
   - **Possible reasons**: 
     - High correlation with poverty (multicollinearity)
     - Non-linear relationship (log transformation helps slightly)
   - **Current weight in formula**: 15 points
   - **Recommendation**: Consider reducing weight or using log transformation

2. **Life Expectancy** (p = 0.82)
   - Not significant when controlling for other factors
   - **Possible reasons**: 
     - Captured by other variables (poverty, GDP)
     - Indirect relationship
   - **Current weight in formula**: 10 points
   - **Recommendation**: Consider reducing weight

3. **Gini Coefficient (Inequality)** (p = 0.007) **
   - **Significant in Model 2** (when included)
   - Coefficient: +21.82 percentage points per 1 unit increase in Gini
   - **Current weight in formula**: 8 points
   - **Recommendation**: Increase weight - it's statistically significant

## Model Comparison

| Model | R² | Adjusted R² | AIC | Sample Size |
|-------|----|-------------|-----|-------------|
| Model 1: Basic | 0.554 | 0.541 | 937.4 | 139 |
| Model 2: + Inequality | 0.577 | 0.561 | 926.0 | 138 |
| Model 3: Log GDP | 0.557 | 0.544 | 936.4 | 139 |
| **Model 4: + Regions** | **0.592** | **0.560** | **937.2** | **139** |

**Best Model**: Model 4 (Full Model with Regional Fixed Effects)
- Highest R² (explains 59.2% of variance)
- Includes regional fixed effects
- All key variables included

## Standardized Coefficients (Relative Importance)

These show which factors have the strongest impact when all variables are on the same scale:

1. **Historical Outbreaks**: 26.6% relative importance
2. **South Asia Region**: 15.8% relative importance  
3. **East Asia & Pacific Region**: 15.3% relative importance
4. **Europe Region**: 12.8% relative importance
5. **Poverty**: 8.8% relative importance
6. **GDP (log)**: 5.0% relative importance
7. **Life Expectancy**: 0.9% relative importance

## Recommendations for Updating the Vulnerability Formula

### Current Weights vs. Statistical Significance

| Factor | Current Weight | Statistical Significance | Recommendation |
|--------|---------------|-------------------------|----------------|
| Undernourishment | 40 points | N/A (dependent variable) | Keep as primary |
| Historical Outbreaks | 20 points | *** (highly significant) | ✅ Appropriate |
| Regional Risk | 15 points | * (significant) | ✅ Appropriate |
| Poverty | 20 points | * (significant) | ✅ Appropriate |
| GDP per Capita | 15 points | Not significant | ⚠️ Consider reducing |
| Life Expectancy | 10 points | Not significant | ⚠️ Consider reducing |
| Inequality (Gini) | 8 points | ** (significant) | ⬆️ Consider increasing |
| Market Access | 7 points | Not tested (limited data) | Keep for now |
| Population | 5 points | Not tested | Keep for now |

### Suggested Weight Adjustments

Based on standardized coefficients and statistical significance:

1. **Increase Inequality weight** from 8 to 12-15 points (it's statistically significant)
2. **Reduce GDP weight** from 15 to 8-10 points (not significant when controlling for poverty)
3. **Reduce Life Expectancy weight** from 10 to 5 points (not significant)
4. **Keep Historical Outbreaks at 20** (highly significant)
5. **Keep Regional Risk at 15** (significant)
6. **Keep Poverty at 20** (significant)

### Alternative: Use Regression Coefficients Directly

You could also use the regression coefficients to create a data-driven formula:

```
Predicted Undernourishment = 
  15.89 + 
  (9.06 × poverty_rate) + 
  (-1.37 × log(GDP)) + 
  (0.05 × life_expectancy) + 
  (10.06 × outbreak_binary) + 
  (regional_effects)
```

Then convert this to a 0-100 vulnerability scale.

## Next Steps

1. **Review the CSV files** generated:
   - `regression_coefficients.csv` - All coefficients with confidence intervals
   - `model_comparison.csv` - Comparison of all models
   - `standardized_coefficients.csv` - Relative importance of each factor

2. **Consider model diagnostics**:
   - Check residual plots for model assumptions
   - Test for heteroscedasticity
   - Check for outliers

3. **Update the vulnerability formula** based on:
   - Statistical significance (p-values)
   - Standardized coefficients (relative importance)
   - Your domain knowledge

4. **Validate the updated formula**:
   - Compare predictions to actual undernourishment rates
   - Check if rankings make sense
   - Ensure the scale remains 0-100

## Statistical Interpretation Guide

- **p < 0.001 (***)**: Highly significant - very strong evidence
- **p < 0.01 (**)**: Very significant - strong evidence  
- **p < 0.05 (*)**: Significant - moderate evidence
- **p < 0.1 (.)**: Marginally significant - weak evidence
- **p ≥ 0.1**: Not significant - no strong evidence

- **R²**: Proportion of variance explained (0-1, higher is better)
- **Adjusted R²**: R² adjusted for number of predictors (better for comparing models)
- **Coefficient**: Change in dependent variable per 1-unit change in predictor
- **Standardized Coefficient**: Coefficient when all variables are standardized (allows comparison)

## Files Generated

- `regression_results.txt` - Full output of the analysis
- `regression_coefficients.csv` - Detailed coefficient table
- `model_comparison.csv` - Model comparison metrics
- `standardized_coefficients.csv` - Relative importance of factors

