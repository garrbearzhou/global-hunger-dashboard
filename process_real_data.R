# Process Real Data from FAO, WFP, USDA, and EM-DAT
# This script processes real CSV files downloaded from official sources

library(tidyverse)
library(readr)
library(here)

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Create directories for real data
create_real_data_directories <- function() {
  cat("📁 Creating directories for real data...\n")
  
  dirs_to_create <- c(
    "data/raw/fao",
    "data/raw/wfp", 
    "data/raw/usda",
    "data/raw/em_dat",
    "data/processed/fao",
    "data/processed/wfp",
    "data/processed/usda",
    "data/processed/em_dat"
  )
  
  for(dir in dirs_to_create) {
    if(!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
      cat("✅ Created:", dir, "\n")
    }
  }
}

# Process FAO data
process_fao_data <- function() {
  cat("🌾 Processing FAO data...\n")
  
  # Check if FAO data files exist
  fao_files <- list.files("data/raw/fao", pattern = "\\.csv$", full.names = TRUE)
  
  if(length(fao_files) == 0) {
    cat("⚠️ No FAO CSV files found in data/raw/fao/\n")
    cat("Please download FAO data from: https://www.fao.org/faostat/en/#data\n")
    return(NULL)
  }
  
  cat("📊 Found", length(fao_files), "FAO data files\n")
  
  # Process each FAO file
  fao_data_list <- list()
  
  for(file in fao_files) {
    tryCatch({
      cat("Processing:", basename(file), "\n")
      
      # Read the CSV file
      data <- read_csv(file, show_col_types = FALSE)
      
      # Standardize column names
      data <- data %>%
        rename_with(~tolower(gsub("[^A-Za-z0-9]", "_", .x))) %>%
        mutate(
          source = "FAO (Real Data)",
          last_updated = Sys.Date(),
          file_name = basename(file)
        )
      
      fao_data_list[[basename(file)]] <- data
      
    }, error = function(e) {
      cat("❌ Error processing", basename(file), ":", e$message, "\n")
    })
  }
  
  # Combine all FAO data
  if(length(fao_data_list) > 0) {
    fao_combined <- bind_rows(fao_data_list, .id = "dataset")
    write_csv(fao_combined, "data/processed/fao/fao_combined_data.csv")
    cat("✅ FAO data processed and saved!\n")
    return(fao_combined)
  } else {
    cat("❌ No FAO data could be processed\n")
    return(NULL)
  }
}

# Process WFP data
process_wfp_data <- function() {
  cat("🍞 Processing WFP data...\n")
  
  # Check if WFP data files exist
  wfp_files <- list.files("data/raw/wfp", pattern = "\\.csv$", full.names = TRUE)
  
  if(length(wfp_files) == 0) {
    cat("⚠️ No WFP CSV files found in data/raw/wfp/\n")
    cat("Please download WFP data from: https://dataviz.vam.wfp.org/\n")
    return(NULL)
  }
  
  cat("📊 Found", length(wfp_files), "WFP data files\n")
  
  # Process each WFP file
  wfp_data_list <- list()
  
  for(file in wfp_files) {
    tryCatch({
      cat("Processing:", basename(file), "\n")
      
      # Read the CSV file
      data <- read_csv(file, show_col_types = FALSE)
      
      # Standardize column names
      data <- data %>%
        rename_with(~tolower(gsub("[^A-Za-z0-9]", "_", .x))) %>%
        mutate(
          source = "WFP (Real Data)",
          last_updated = Sys.Date(),
          file_name = basename(file)
        )
      
      wfp_data_list[[basename(file)]] <- data
      
    }, error = function(e) {
      cat("❌ Error processing", basename(file), ":", e$message, "\n")
    })
  }
  
  # Combine all WFP data
  if(length(wfp_data_list) > 0) {
    wfp_combined <- bind_rows(wfp_data_list, .id = "dataset")
    write_csv(wfp_combined, "data/processed/wfp/wfp_combined_data.csv")
    cat("✅ WFP data processed and saved!\n")
    return(wfp_combined)
  } else {
    cat("❌ No WFP data could be processed\n")
    return(NULL)
  }
}

# Process USDA data
process_usda_data <- function() {
  cat("🇺🇸 Processing USDA data...\n")
  
  # Check if USDA data files exist
  usda_files <- list.files("data/raw/usda", pattern = "\\.csv$", full.names = TRUE)
  
  if(length(usda_files) == 0) {
    cat("⚠️ No USDA CSV files found in data/raw/usda/\n")
    cat("Please download USDA data from: https://www.ers.usda.gov/data-products/\n")
    return(NULL)
  }
  
  cat("📊 Found", length(usda_files), "USDA data files\n")
  
  # Process each USDA file
  usda_data_list <- list()
  
  for(file in usda_files) {
    tryCatch({
      cat("Processing:", basename(file), "\n")
      
      # Read the CSV file
      data <- read_csv(file, show_col_types = FALSE)
      
      # Standardize column names
      data <- data %>%
        rename_with(~tolower(gsub("[^A-Za-z0-9]", "_", .x))) %>%
        mutate(
          source = "USDA (Real Data)",
          last_updated = Sys.Date(),
          file_name = basename(file)
        )
      
      usda_data_list[[basename(file)]] <- data
      
    }, error = function(e) {
      cat("❌ Error processing", basename(file), ":", e$message, "\n")
    })
  }
  
  # Combine all USDA data
  if(length(usda_data_list) > 0) {
    usda_combined <- bind_rows(usda_data_list, .id = "dataset")
    write_csv(usda_combined, "data/processed/usda/usda_combined_data.csv")
    cat("✅ USDA data processed and saved!\n")
    return(usda_combined)
  } else {
    cat("❌ No USDA data could be processed\n")
    return(NULL)
  }
}

# Process EM-DAT data
process_em_dat_data <- function() {
  cat("🌪️ Processing EM-DAT data...\n")
  
  # Check if EM-DAT data files exist
  em_dat_files <- list.files("data/raw/em_dat", pattern = "\\.csv$", full.names = TRUE)
  
  if(length(em_dat_files) == 0) {
    cat("⚠️ No EM-DAT CSV files found in data/raw/em_dat/\n")
    cat("Please download EM-DAT data from: https://public.emdat.be/\n")
    return(NULL)
  }
  
  cat("📊 Found", length(em_dat_files), "EM-DAT data files\n")
  
  # Process each EM-DAT file
  em_dat_data_list <- list()
  
  for(file in em_dat_files) {
    tryCatch({
      cat("Processing:", basename(file), "\n")
      
      # Read the CSV file
      data <- read_csv(file, show_col_types = FALSE)
      
      # Standardize column names
      data <- data %>%
        rename_with(~tolower(gsub("[^A-Za-z0-9]", "_", .x))) %>%
        mutate(
          source = "EM-DAT (Real Data)",
          last_updated = Sys.Date(),
          file_name = basename(file)
        )
      
      em_dat_data_list[[basename(file)]] <- data
      
    }, error = function(e) {
      cat("❌ Error processing", basename(file), ":", e$message, "\n")
    })
  }
  
  # Combine all EM-DAT data
  if(length(em_dat_data_list) > 0) {
    em_dat_combined <- bind_rows(em_dat_data_list, .id = "dataset")
    write_csv(em_dat_combined, "data/processed/em_dat/em_dat_combined_data.csv")
    cat("✅ EM-DAT data processed and saved!\n")
    return(em_dat_combined)
  } else {
    cat("❌ No EM-DAT data could be processed\n")
    return(NULL)
  }
}

# Create data summary
create_data_summary <- function(fao_data, wfp_data, usda_data, em_dat_data) {
  cat("📊 Creating data summary...\n")
  
  summary_data <- data.frame(
    Source = c("FAO", "WFP", "USDA", "EM-DAT"),
    Status = c(
      ifelse(!is.null(fao_data), "✅ Real Data", "❌ No Data"),
      ifelse(!is.null(wfp_data), "✅ Real Data", "❌ No Data"),
      ifelse(!is.null(usda_data), "✅ Real Data", "❌ No Data"),
      ifelse(!is.null(em_dat_data), "✅ Real Data", "❌ No Data")
    ),
    Records = c(
      ifelse(!is.null(fao_data), nrow(fao_data), 0),
      ifelse(!is.null(wfp_data), nrow(wfp_data), 0),
      ifelse(!is.null(usda_data), nrow(usda_data), 0),
      ifelse(!is.null(em_dat_data), nrow(em_dat_data), 0)
    ),
    Files_Processed = c(
      ifelse(!is.null(fao_data), length(unique(fao_data$file_name)), 0),
      ifelse(!is.null(wfp_data), length(unique(wfp_data$file_name)), 0),
      ifelse(!is.null(usda_data), length(unique(usda_data$file_name)), 0),
      ifelse(!is.null(em_dat_data), length(unique(em_dat_data$file_name)), 0)
    )
  )
  
  write_csv(summary_data, "data/processed/data_sources_summary.csv")
  cat("✅ Data summary created!\n")
  
  return(summary_data)
}

# Main processing function
main <- function() {
  cat("🌍 Starting real data processing...\n")
  cat("====================================\n")
  
  # Create directories
  create_real_data_directories()
  
  # Process each data source
  fao_data <- process_fao_data()
  wfp_data <- process_wfp_data()
  usda_data <- process_usda_data()
  em_dat_data <- process_em_dat_data()
  
  # Create summary
  summary_data <- create_data_summary(fao_data, wfp_data, usda_data, em_dat_data)
  
  cat("\n🎉 Real data processing complete!\n")
  cat("📊 Data sources summary:\n")
  print(summary_data)
  
  cat("\n📁 Next steps:\n")
  cat("1. Download CSV files from official sources\n")
  cat("2. Place them in the appropriate data/raw/ folders\n")
  cat("3. Run this script again to process the real data\n")
  cat("4. Update your app to use real data instead of simulated data\n")
}

# Run the script
main()
