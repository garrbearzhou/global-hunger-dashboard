#!/bin/bash

# Launch script for Global Hunger Research Website
# Author: Garrett Zhou
# Date: October 2024

echo "🌍 Global Hunger Research Website Launcher"
echo "=========================================="
echo ""

# Check if R is installed
if ! command -v R &> /dev/null; then
    echo "❌ Error: R is not installed or not in PATH"
    echo "Please install R from https://www.r-project.org/"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "app.R" ]; then
    echo "❌ Error: app.R not found"
    echo "Please run this script from the hunger_research_project directory"
    exit 1
fi

echo "✅ R is installed"
echo "✅ Project files found"
echo ""

# Install required packages if needed
echo "📦 Checking and installing required packages..."
Rscript -e "
required_packages <- c('shiny', 'shinydashboard', 'plotly', 'leaflet', 'DT', 'tidyverse', 'WDI', 'here', 'lubridate', 'RColorBrewer')
new_packages <- required_packages[!(required_packages %in% installed.packages()[,'Package'])]
if(length(new_packages)) {
  cat('Installing packages:', paste(new_packages, collapse = ', '), '\n')
  install.packages(new_packages, dependencies = TRUE, repos = 'https://cran.rstudio.com/')
} else {
  cat('All required packages are already installed.\n')
}
"

echo ""
echo "🚀 Starting the website..."
echo "The website will open in your default web browser."
echo "To stop the server, press Ctrl+C"
echo ""

# Launch the website
Rscript run_website.R
