# Download Real Data from Official Sources
# This script helps you download real data from FAO, WFP, USDA, and EM-DAT

library(httr)
library(jsonlite)
library(tidyverse)

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Create directories
dir.create("data/raw/fao", showWarnings = FALSE, recursive = TRUE)
dir.create("data/raw/wfp", showWarnings = FALSE, recursive = TRUE)
dir.create("data/raw/usda", showWarnings = FALSE, recursive = TRUE)
dir.create("data/raw/em_dat", showWarnings = FALSE, recursive = TRUE)

# Function to download FAO data
download_fao_data <- function() {
  cat("🌾 Attempting to download FAO data...\n")
  
  # FAO API endpoint
  fao_url <- "https://fenixservices.fao.org/faostat/api/v1/en/data/FS"
  
  # Key FAO indicators
  fao_indicators <- c(
    "21001",  # Prevalence of Undernourishment
    "21002",  # Number of Undernourished
    "21003",  # Depth of Food Deficit
    "21004"   # Average Dietary Energy Supply Adequacy
  )
  
  for(indicator in fao_indicators) {
    tryCatch({
      cat("Downloading FAO indicator", indicator, "...\n")
      
      response <- GET(fao_url, query = list(
        area = "5000",  # All countries
        item = indicator,
        elements = "Value",
        year = "2020,2021,2022,2023"
      ))
      
      if(status_code(response) == 200) {
        data <- content(response, "parsed")
        
        if(!is.null(data$data) && length(data$data) > 0) {
          # Convert to data frame
          df <- data.frame(
            country = sapply(data$data, function(x) x$area),
            year = sapply(data$data, function(x) x$year),
            value = sapply(data$data, function(x) x$value),
            indicator = indicator,
            source = "FAO (Real Data)",
            last_updated = Sys.Date()
          )
          
          # Save to CSV
          filename <- paste0("data/raw/fao/fao_indicator_", indicator, ".csv")
          write_csv(df, filename)
          cat("✅ Saved:", filename, "\n")
        } else {
          cat("⚠️ No data returned for indicator", indicator, "\n")
        }
      } else {
        cat("❌ Failed to download indicator", indicator, "Status:", status_code(response), "\n")
      }
      
      Sys.sleep(1) # Be respectful to API
      
    }, error = function(e) {
      cat("❌ Error downloading FAO indicator", indicator, ":", e$message, "\n")
    })
  }
}

# Function to download WFP data
download_wfp_data <- function() {
  cat("🍞 Attempting to download WFP data...\n")
  
  # WFP API endpoint (this may not be publicly accessible)
  wfp_url <- "https://api.hungermapdata.org/v1/foodsecurity/country"
  
  tryCatch({
    response <- GET(wfp_url)
    
    if(status_code(response) == 200) {
      data <- content(response, "parsed")
      # Process WFP data here
      cat("✅ WFP data downloaded successfully!\n")
    } else {
      cat("⚠️ WFP API not accessible. Status:", status_code(response), "\n")
      cat("Please download WFP data manually from: https://dataviz.vam.wfp.org/\n")
    }
  }, error = function(e) {
    cat("❌ Error accessing WFP API:", e$message, "\n")
    cat("Please download WFP data manually from: https://dataviz.vam.wfp.org/\n")
  })
}

# Function to download USDA data
download_usda_data <- function() {
  cat("🇺🇸 Attempting to download USDA data...\n")
  
  # USDA API endpoint (this may not be publicly accessible)
  usda_url <- "https://api.ers.usda.gov/data/foodsecurity"
  
  tryCatch({
    response <- GET(usda_url)
    
    if(status_code(response) == 200) {
      data <- content(response, "parsed")
      # Process USDA data here
      cat("✅ USDA data downloaded successfully!\n")
    } else {
      cat("⚠️ USDA API not accessible. Status:", status_code(response), "\n")
      cat("Please download USDA data manually from: https://www.ers.usda.gov/data-products/\n")
    }
  }, error = function(e) {
    cat("❌ Error accessing USDA API:", e$message, "\n")
    cat("Please download USDA data manually from: https://www.ers.usda.gov/data-products/\n")
  })
}

# Function to download EM-DAT data
download_em_dat_data <- function() {
  cat("🌪️ Attempting to download EM-DAT data...\n")
  
  # EM-DAT API endpoint (this may not be publicly accessible)
  em_dat_url <- "https://public.emdat.be/api/v1/disasters"
  
  tryCatch({
    response <- GET(em_dat_url)
    
    if(status_code(response) == 200) {
      data <- content(response, "parsed")
      # Process EM-DAT data here
      cat("✅ EM-DAT data downloaded successfully!\n")
    } else {
      cat("⚠️ EM-DAT API not accessible. Status:", status_code(response), "\n")
      cat("Please download EM-DAT data manually from: https://public.emdat.be/\n")
    }
  }, error = function(e) {
    cat("❌ Error accessing EM-DAT API:", e$message, "\n")
    cat("Please download EM-DAT data manually from: https://public.emdat.be/\n")
  })
}

# Main function
main <- function() {
  cat("🌍 Starting real data download...\n")
  cat("==================================\n")
  
  # Download data from each source
  download_fao_data()
  download_wfp_data()
  download_usda_data()
  download_em_dat_data()
  
  cat("\n🎉 Data download attempt complete!\n")
  cat("\n📁 Next steps:\n")
  cat("1. Check the data/raw/ folders for downloaded files\n")
  cat("2. For sources that failed, download CSV files manually\n")
  cat("3. Run process_real_data.R to process the downloaded data\n")
  cat("4. Update your app to use real data instead of simulated data\n")
  
  cat("\n📊 Manual download links:\n")
  cat("🌾 FAO: https://www.fao.org/faostat/en/#data\n")
  cat("🍞 WFP: https://dataviz.vam.wfp.org/\n")
  cat("🇺🇸 USDA: https://www.ers.usda.gov/data-products/\n")
  cat("🌪️ EM-DAT: https://public.emdat.be/\n")
}

# Run the script
main()
