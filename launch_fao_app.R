# Launch FAO-Integrated Global Hunger Research Website
# This script launches the website with real FAO data

cat("🌍 Launching FAO-Integrated Global Hunger Research Website...\n")
cat("============================================================\n")

# Check if required packages are installed
required_packages <- c("shiny", "plotly", "DT", "tidyverse", "readr")

for(pkg in required_packages) {
  if(!require(pkg, character.only = TRUE)) {
    cat("📦 Installing package:", pkg, "\n")
    install.packages(pkg, repos = "https://cran.rstudio.com/")
    library(pkg, character.only = TRUE)
  }
}

# Check if FAO data exists
if(!file.exists("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data_NOFLAG.csv")) {
  cat("❌ Error: FAO data not found!\n")
  cat("Please make sure the FAO data files are in the correct location:\n")
  cat("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data_NOFLAG.csv\n")
  stop("FAO data files missing")
}

cat("✅ All required packages loaded\n")
cat("✅ FAO data files found\n")
cat("🚀 Starting the website...\n\n")

# Run the FAO-integrated app
cat("🌐 Website will be available at: http://localhost:3838\n")
cat("📱 Alternative URL: http://127.0.0.1:3838\n")
cat("🔗 Copy and paste this URL into your browser if it doesn't open automatically\n\n")

source("fao_integrated_app.R")
