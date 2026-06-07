# Enhanced Launcher for the Hunger Research Website
# This version includes hover explanations and comprehensive world map

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install required packages if not already installed
required_packages <- c("shiny", "plotly", "DT", "tidyverse", "WDI")

new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) {
  cat("Installing missing packages:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages, dependencies = TRUE)
}

# Load required libraries
library(shiny)
library(plotly)
library(DT)
library(tidyverse)
library(WDI)

cat("🎉 ENHANCED VERSION - Global Hunger Research Website\n")
cat("==================================================\n")
cat("✨ Features included:\n")
cat("   • Hover explanations for all graphs\n")
cat("   • Interactive world map with detailed country information\n")
cat("   • Food insecurity data and hunger outbreak history\n")
cat("   • Enhanced visualizations and user experience\n")
cat("🚀 Starting your enhanced hunger research dashboard...\n")
cat("🌐 The website will open in your default web browser.\n")
cat("🛑 To stop the server, press Ctrl+C in the terminal.\n\n")

# Run the enhanced app
runApp("ENHANCED_APP.R", launch.browser = TRUE, port = 3838)
