# Global Hunger Research Project

**Author:** Garrett Zhou  
**Live dashboard:** [https://globalhungerdashboard.com](https://globalhungerdashboard.com)  
**Overview page (SEO):** [https://globalhungerdashboard.com/assets/landing.html](https://globalhungerdashboard.com/assets/landing.html)  
**Repository:** [github.com/garrbearzhou/global-hunger-dashboard](https://github.com/garrbearzhou/global-hunger-dashboard)

Interactive Shiny app mapping **global hunger vulnerability** by country (0–100 score), with country hunger profiles, time-series analysis, and data from FAO, World Bank, climate indices, and crisis datasets.

## Project Overview

This research project aims to explore historical and recent hunger hotspots using data-driven techniques and mathematical modeling to identify patterns and forecast potential future hunger crises. The project combines elements of data science, statistical modeling, and geospatial analysis to produce both a predictive model and an interactive map that visualizes past data and highlights future at-risk regions.

## Project Structure

```
hunger_research_project/
├── data/
│   ├── raw/                 # Raw data files from various sources
│   ├── processed/           # Cleaned and processed data
│   └── external/            # External data sources
├── scripts/                 # R scripts for analysis
├── models/                  # Saved predictive models
├── outputs/
│   ├── figures/             # Plots and visualizations
│   ├── maps/                # Map outputs
│   └── reports/             # Generated reports
├── docs/                    # Documentation
└── hunger_research_project.R # Main project script
```

## Research Phases

### 1. Data Collection and Preparation
- **Sources:** FAO, World Food Programme, World Bank, EM-DAT
- **Key Variables:** Conflict data, crop yields, rainfall, GDP, inflation, population density
- **Focus:** Cleaning, organizing, and selecting relevant data

### 2. Learning R and Tool Development
- **Timeline:** Summer learning period
- **Platforms:** edX, HarvardX Digital Humanities course
- **Skills:** Data analysis, statistical modeling, data visualization, geospatial libraries

### 3. Modeling and Analysis
- **Techniques:** Logistic/linear regression, time series modeling, clustering/classification
- **Output:** Probability of hunger outbreaks or famine in given regions
- **Collaboration:** Faculty/researchers in statistical modeling and network analysis

### 4. Mapping and Visualization
- **Goal:** Interactive global map with historical hotspots and future projections
- **End Product:** Website with interactive and engaging information display

## Key Deliverables

1. **Predictive Model:** Estimates future hunger risk based on historical and socioeconomic variables
2. **Interactive Map:** Showcases historical hunger trends and future projections
3. **Research Paper:** Details methodology, findings, and implications

## Data Sources

### Primary Sources
- **FAO (Food and Agriculture Organization)**
  - Food Security Indicators
  - Food Balance Sheets
  - Production, Trade, and Price data

- **World Food Programme (WFP)**
  - Food Security data
  - Market Prices
  - Vulnerability Analysis

- **World Bank**
  - World Development Indicators
  - Global Economic Monitor
  - GDP, inflation, population, poverty data

- **EM-DAT (Emergency Events Database)**
  - Natural and technological disasters
  - Conflict data

### Key Variables
- Undernourishment rates
- Food supply and production
- Economic indicators (GDP, inflation)
- Population and demographic data
- Agricultural indicators
- Conflict and disaster data
- Climate and environmental factors

## Technical Requirements

### R Packages
- **Data Manipulation:** tidyverse, data.table, lubridate
- **Statistical Modeling:** caret, randomForest, glmnet, forecast, prophet
- **Geospatial:** sf, rnaturalearth, leaflet, mapview, tmap
- **Visualization:** plotly, shiny, DT, RColorBrewer
- **Data Sources:** WDI, jsonlite, httr
- **Utilities:** here, conflicted, janitor, skimr

### Skills Development
1. **R Programming Fundamentals**
2. **Statistical Analysis and Modeling**
3. **Time Series Forecasting**
4. **Geospatial Analysis**
5. **Interactive Visualization**
6. **Web Application Development**

## Getting Started

1. **Install R and RStudio**
2. **Run the main script:** `source("hunger_research_project.R")`
3. **Install required packages** (handled automatically by the script)
4. **Begin data collection** from the identified sources
5. **Follow the learning roadmap** for skill development

## Learning Roadmap

### Phase 1: R Fundamentals
- Complete R basics course (edX, Coursera)
- Practice data manipulation with dplyr
- Learn ggplot2 for visualization
- Understand statistical concepts

### Phase 2: Advanced R
- Time series analysis with forecast package
- Machine learning with caret and randomForest
- Geospatial analysis with sf and leaflet
- Web applications with Shiny

### Phase 3: Data Collection
- Set up APIs for FAO, WFP, World Bank
- Learn web scraping techniques
- Data cleaning and preprocessing
- Database management

### Phase 4: Modeling
- Statistical modeling techniques
- Time series forecasting
- Machine learning algorithms
- Model validation and testing

### Phase 5: Visualization
- Interactive maps with leaflet
- Dashboard development with Shiny
- Web design and user experience
- Data storytelling

## Next Steps

1. **Immediate (Week 1-2):**
   - Set up R environment and install packages
   - Begin R programming course
   - Start collecting World Bank data

2. **Short-term (Month 1):**
   - Complete R fundamentals
   - Collect data from FAO and WFP
   - Begin exploratory data analysis

3. **Medium-term (Months 2-3):**
   - Develop initial predictive models
   - Create basic visualizations
   - Start geospatial analysis

4. **Long-term (Months 4-6):**
   - Refine models and validate results
   - Build interactive dashboard
   - Write research paper

## Collaboration Opportunities

- **Statistical Modeling:** Faculty with expertise in regression, time series, machine learning
- **Network Analysis:** Researchers in social network analysis
- **Geospatial Analysis:** GIS specialists and cartographers
- **Web Development:** Front-end developers for dashboard creation
- **Domain Experts:** Food security and humanitarian aid specialists

## Expected Outcomes

- **Academic:** Research paper suitable for publication in food security or data science journals
- **Practical:** Interactive tool for policymakers and humanitarian organizations
- **Educational:** Learning experience in data science, statistics, and global issues
- **Impact:** Contribution to understanding and predicting global hunger crises

## Contact

For questions about this project or potential collaboration opportunities, please contact Garrett Zhou.

---

*This project represents a comprehensive approach to understanding global hunger through data science and predictive modeling. The combination of rigorous statistical analysis with accessible visualization tools aims to make complex global issues more understandable and actionable.*
