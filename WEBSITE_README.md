# Global Hunger Research Website

## 🌍 Interactive Dashboard for Hunger Research

This is a comprehensive Shiny web application that provides an interactive platform for exploring global hunger data, conducting statistical analysis, and visualizing hunger risk patterns worldwide.

## 🚀 Quick Start

### Option 1: Run the Website (Recommended)
```bash
cd /Users/27zhou/Downloads/hunger_research_project
Rscript run_website.R
```

### Option 2: Run from RStudio
1. Open RStudio
2. Navigate to the project directory
3. Run: `source("run_website.R")`

The website will automatically open in your default web browser at `http://localhost:3838`

## 📊 Features

### 1. **Overview Dashboard**
- Key statistics and metrics
- Global hunger risk distribution
- Economic indicators vs hunger risk
- Agricultural indicators analysis
- Top countries by hunger risk

### 2. **Interactive Data Explorer**
- Comprehensive data table with filtering
- Search and sort capabilities
- Export functionality (CSV, Excel)
- Data summary statistics

### 3. **Global Hunger Map**
- Interactive world map with hunger risk visualization
- Country-level data on hover
- Color-coded risk levels
- Population-weighted markers

### 4. **Time Series Analysis**
- Trend analysis over time
- Country comparison
- Global averages
- Forecast capabilities (coming soon)

### 5. **Statistical Analysis**
- Correlation matrix heatmap
- Regression analysis
- Statistical significance tests
- Feature importance analysis

### 6. **Predictive Model**
- Hunger risk prediction based on key factors
- Interactive parameter adjustment
- Model performance metrics
- Feature importance visualization

## 🎛️ Interactive Controls

### Filters
- **Country Selection**: Choose specific countries or view all
- **Year Range**: Filter data by time period
- **Hunger Risk Level**: Focus on specific risk categories

### Data Sources
- **World Bank**: Economic and demographic indicators
- **FAO**: Food security data (coming soon)
- **WFP**: Market and vulnerability data (coming soon)
- **EM-DAT**: Disaster and conflict data (coming soon)

## 📈 Key Metrics

### Hunger Risk Levels
- **🔴 High Risk**: Poverty > 30%
- **🟡 Medium Risk**: Poverty 15-30%
- **🟢 Low Risk**: Poverty 5-15%
- **⚪ Very Low Risk**: Poverty < 5%

*Note: Risk levels are currently based on poverty rates as a proxy for hunger risk. This will be refined with actual hunger data from FAO and WFP.*

### Key Variables
- Population and demographics
- GDP and economic indicators
- Poverty rates
- Agricultural indicators
- Health and education metrics
- Trade and development data

## 🛠️ Technical Details

### Built With
- **R Shiny**: Web application framework
- **Shiny Dashboard**: UI components
- **Plotly**: Interactive visualizations
- **Leaflet**: Interactive mapping
- **DT**: Data tables
- **Tidyverse**: Data manipulation
- **WDI**: World Bank data integration

### Data Processing
- Automatic data collection from World Bank
- Data cleaning and standardization
- Missing data handling
- Country name standardization
- Time series preparation

## 📁 File Structure

```
hunger_research_project/
├── app.R                 # Main Shiny application
├── run_website.R         # Website launcher script
├── www/
│   └── custom.css        # Custom styling
├── data/
│   ├── raw/              # Raw data files
│   └── processed/        # Processed data
├── outputs/
│   └── figures/          # Generated plots
└── WEBSITE_README.md     # This file
```

## 🔧 Customization

### Adding New Data Sources
1. Modify the `load_hunger_data()` function in `app.R`
2. Add new data collection functions
3. Update the data processing pipeline
4. Add new visualizations as needed

### Styling
- Edit `www/custom.css` for visual customization
- Modify the dashboard theme in `app.R`
- Add custom JavaScript if needed

### Adding New Features
- Create new tabs in the sidebar menu
- Add new reactive functions in the server
- Implement new visualizations with Plotly or Leaflet

## 📊 Data Sources

### Currently Integrated
- **World Bank**: Comprehensive economic and social indicators
  - GDP, population, poverty rates
  - Agricultural and health indicators
  - Trade and development data

### Coming Soon
- **FAO (Food and Agriculture Organization)**
  - Food security indicators
  - Production and trade data
  - Price information

- **WFP (World Food Programme)**
  - Food security assessments
  - Market price data
  - Vulnerability analysis

- **EM-DAT (Emergency Events Database)**
  - Natural disaster data
  - Conflict information
  - Emergency events

## 🎯 Use Cases

### For Researchers
- Explore global hunger patterns
- Conduct statistical analysis
- Identify research gaps
- Generate hypotheses

### For Policymakers
- Monitor hunger risk levels
- Identify priority countries
- Track progress over time
- Make data-driven decisions

### For Students
- Learn about global hunger
- Practice data analysis
- Understand statistical concepts
- Explore interactive visualizations

## 🚨 Troubleshooting

### Common Issues

1. **Website won't start**
   - Ensure all required packages are installed
   - Check that R and RStudio are up to date
   - Verify internet connection for data collection

2. **Data not loading**
   - Check internet connection
   - Verify World Bank API access
   - Look for error messages in the console

3. **Maps not displaying**
   - Ensure Leaflet package is installed
   - Check browser compatibility
   - Verify internet connection for map tiles

### Getting Help
- Check the R console for error messages
- Review the package documentation
- Consult the Shiny documentation
- Check the project GitHub repository

## 🔮 Future Enhancements

### Planned Features
- Real-time data updates
- Advanced forecasting models
- Machine learning integration
- Mobile-responsive design
- Multi-language support
- Export functionality for reports
- User authentication
- Collaborative features

### Data Integration
- FAO food security data
- WFP market and vulnerability data
- EM-DAT disaster and conflict data
- Climate and weather data
- Social media sentiment analysis

## 📝 License

This project is part of academic research on global hunger and food security. Please cite appropriately if used in research or publications.

## 👨‍💻 Author

**Garrett Zhou**  
Research Project 2024  
Global Hunger and Food Security Analysis

---

*This website represents a comprehensive tool for understanding and analyzing global hunger patterns through data science and interactive visualization.*
