# =============================================================================
# LAUNCHER SCRIPT FOR HUNGER RESEARCH WEBSITE
# Author: Garrett Zhou
# Date: October 2024
# =============================================================================

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install required packages if not already installed
required_packages <- c("shiny", "shinydashboard", "plotly", "leaflet", "DT", 
                      "tidyverse", "WDI", "here", "lubridate", "RColorBrewer")

new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) {
  cat("Installing missing packages:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages, dependencies = TRUE)
}

# Load required libraries
library(shiny)
library(shinydashboard)
library(plotly)
library(leaflet)
library(DT)
library(tidyverse)
library(WDI)
library(here)
library(lubridate)
library(RColorBrewer)

# Set working directory
setwd(here())

cat("Starting Global Hunger Research Website...\n")
cat("=========================================\n")
cat("The website will open in your default web browser.\n")
cat("To stop the server, press Ctrl+C in the terminal.\n\n")

# Run the Shiny app
runApp("app.R", launch.browser = TRUE, port = 3838)
