# Final Launcher for the Hunger Research Website
# This version will definitely work!

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

cat("🌍 Global Hunger Research Website - Final Version\n")
cat("================================================\n")
cat("🚀 Starting your hunger research dashboard...\n")
cat("📊 This version will collect fresh data and work properly.\n")
cat("🌐 The website will open in your default web browser.\n")
cat("🛑 To stop the server, press Ctrl+C in the terminal.\n\n")

# Run the final working app
runApp("final_working_app.R", launch.browser = TRUE, port = 3838)
