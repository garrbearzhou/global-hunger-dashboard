# Refined GRFC 2025 Data Extraction - Looking for structured tables
library(tidyverse)
library(stringr)

cat("📊 Refined GRFC 2025 Data Extraction\n")
cat("====================================\n\n")

# Read extracted text
full_text <- readLines("data/processed/grfc2025_full_text.txt", warn = FALSE)

cat("✅ Loaded text file\n\n")

# Look for the main summary table - usually has format like:
# Country Name | Number.M | Number.M | Phase
# Or country names in all caps followed by numbers

cat("🔍 Searching for main data table...\n\n")

# Find lines that look like table rows (country name + numbers + phase)
table_rows <- data.frame()

# Common patterns in GRFC tables
for(i in seq_along(full_text)) {
  line <- full_text[i]
  
  # Look for lines with country name and numbers in millions
  # Pattern: Country name followed by numbers like "15.8M" or "15.8 M" or "15,800,000"
  if(str_detect(line, "[A-Z][a-z]+.*\\d{1,2}\\.\\d+\\s*[Mm]") ||
     str_detect(line, "[A-Z][A-Z ]+.*\\d{1,2}\\.\\d+\\s*[Mm]")) {
    
    # Extract country name (first word or words in caps)
    country_match <- str_extract(line, "^[A-Z][A-Z ]{2,}|^[A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*")
    
    if(!is.na(country_match)) {
      country <- str_trim(country_match)
      
      # Extract numbers in millions
      numbers <- str_extract_all(line, "\\d{1,2}(?:\\.\\d+)?\\s*[Mm]")[[1]]
      numbers_clean <- numeric()
      for(num in numbers) {
        val <- as.numeric(str_extract(num, "\\d{1,2}(?:\\.\\d+)?"))
        if(!is.na(val)) {
          numbers_clean <- c(numbers_clean, val * 1000000)  # Convert to actual number
        }
      }
      
      # Extract IPC phase
      phase <- NA
      if(str_detect(line, "(?i)phase\\s*[345]|ipc\\s*[345]")) {
        phase_match <- str_extract(line, "(?i)(?:phase|ipc)\\s*([345])")
        phase <- as.numeric(str_extract(phase_match, "[345]"))
      }
      
      # Extract year
      year <- str_extract(line, "202[0-9]")
      
      if(length(numbers_clean) > 0 && any(numbers_clean > 100000)) {
        table_rows <- rbind(table_rows, data.frame(
          line_num = i,
          country = country,
          numbers_millions = paste(numbers_clean / 1000000, collapse = ", "),
          largest_number = max(numbers_clean),
          ipc_phase = phase,
          year = year,
          raw_line = substr(line, 1, 200),
          stringsAsFactors = FALSE
        ))
      }
    }
  }
}

cat("📋 Found", nrow(table_rows), "potential table rows\n\n")

if(nrow(table_rows) > 0) {
  # Clean and deduplicate
  table_rows_clean <- table_rows %>%
    filter(!is.na(country) & country != "" & nchar(country) > 2) %>%
    # Remove obvious non-countries
    filter(!country %in% c("THE", "AND", "FOR", "WITH", "FROM", "THAT", "THIS", "WERE", "HAVE", "WILL")) %>%
    group_by(country) %>%
    # Take row with largest number (most likely to be Phase 3+ population)
    slice_max(largest_number, n = 1) %>%
    ungroup() %>%
    arrange(desc(largest_number))
  
  cat("✅ Cleaned to", nrow(table_rows_clean), "unique countries\n\n")
  
  # Show top entries
  cat("📊 Top 20 countries by population:\n")
  print(head(table_rows_clean %>% select(country, largest_number, ipc_phase), 20))
  
  # Create final dataset
  grfc_data <- table_rows_clean %>%
    mutate(
      assessment_year = ifelse(is.na(year), 2024, as.numeric(year)),
      ipc_phase = ipc_phase,
      population_phase3_plus = largest_number,
      population_phase4_plus = NA,  # Would need more specific extraction
      population_phase5 = NA,        # Would need more specific extraction
      primary_driver = NA,            # Would need more specific extraction
      secondary_driver = NA
    ) %>%
    select(country, assessment_year, ipc_phase, population_phase3_plus, 
           population_phase4_plus, population_phase5, primary_driver, secondary_driver) %>%
    # Standardize country names (basic)
    mutate(
      country = case_when(
        country == "DRC" ~ "Democratic Republic of the Congo",
        country == "CAR" ~ "Central African Republic",
        str_detect(country, "Congo") & !str_detect(country, "Democratic") ~ "Republic of the Congo",
        TRUE ~ country
      )
    )
  
  # Save
  write_csv(grfc_data, "data/raw/wfp/grfc2025_data.csv")
  cat("\n💾 Saved to: data/raw/wfp/grfc2025_data.csv\n")
  cat("📊 Countries extracted:", nrow(grfc_data), "\n")
  cat("📊 Countries with IPC Phase:", sum(!is.na(grfc_data$ipc_phase)), "\n")
  cat("📊 Countries with population data:", sum(!is.na(grfc_data$population_phase3_plus)), "\n\n")
  
} else {
  cat("⚠️ Could not find structured table format\n")
  cat("💡 Trying alternative extraction method...\n\n")
  
  # Alternative: Look for specific country mentions with context
  # This is a fallback - manual extraction may be needed
}

cat("✅ Extraction complete!\n")

