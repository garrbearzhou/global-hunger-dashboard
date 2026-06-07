# Launch FAO-World Bank Combined Global Hunger Research Website
# This script launches the website with both FAO and World Bank data

cat("🌍 Launching FAO-World Bank Combined Global Hunger Research Website...\n")
cat("====================================================================\n")

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

# Check if World Bank data exists
if(!file.exists("data/raw/world_bank_data.csv")) {
  cat("❌ Error: World Bank data not found!\n")
  cat("Please make sure the World Bank data file is in the correct location:\n")
  cat("data/raw/world_bank_data.csv\n")
  stop("World Bank data file missing")
}

cat("✅ All required packages loaded\n")
cat("✅ FAO data files found\n")
cat("✅ World Bank data file found\n")
cat("🚀 Starting the combined website...\n\n")

# Run the combined app
source("fao_worldbank_combined_app.R")
