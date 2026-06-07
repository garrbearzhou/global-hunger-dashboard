# Launcher for the working hunger research website
# This version properly handles data collection and column names

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

cat("🌍 Global Hunger Research Website Launcher\n")
cat("==========================================\n")
cat("Starting the working version of your hunger research dashboard...\n")
cat("This version properly handles data collection and visualization.\n\n")

# Run the working app
runApp("working_app.R", launch.browser = TRUE, port = 3838)
