# Advanced GRFC 2025 Data Extraction
library(tidyverse)
library(stringr)

cat("📊 Advanced GRFC 2025 Data Extraction\n")
cat("=====================================\n\n")

# Read the extracted text
text_file <- "data/processed/grfc2025_full_text.txt"
if(!file.exists(text_file)) {
  stop("Please run extract_grfc2025.R first to extract text from PDF")
}

full_text <- readLines(text_file, warn = FALSE)
full_text_combined <- paste(full_text, collapse = "\n")

cat("✅ Loaded extracted text\n")
cat("📄 Total lines:", length(full_text), "\n\n")

# Look for main data table - usually has headers like "Country", "Territory", "Population", "Phase"
cat("🔍 Searching for main data table...\n\n")

# Find lines that look like table headers
header_patterns <- c(
  "Country.*Territory",
  "Country.*Phase",
  "Territory.*Phase",
  "Population.*Phase",
  "IPC.*Phase",
  "Phase.*Population"
)

# Find potential table sections
table_sections <- c()
for(i in seq_along(full_text)) {
  line_lower <- tolower(full_text[i])
  if(any(str_detect(line_lower, c("country", "territory"))) && 
     any(str_detect(line_lower, c("phase", "ipc", "population", "million")))) {
    table_sections <- c(table_sections, i)
  }
}

cat("📋 Found", length(table_sections), "potential table header lines\n")
if(length(table_sections) > 0) {
  cat("Sample headers (first 5):\n")
  for(i in head(table_sections, 5)) {
    cat(sprintf("  Line %d: %s\n", i, substr(full_text[i], 1, 100)))
  }
  cat("\n")
}

# Try to extract data using common GRFC table patterns
cat("🔧 Extracting country data with IPC phases...\n\n")

# Common countries in food crises (expanded list)
all_countries <- c(
  "Afghanistan", "Yemen", "Somalia", "South Sudan", "Ethiopia", "Nigeria",
  "Haiti", "Madagascar", "Democratic Republic of the Congo", "DRC", 
  "Central African Republic", "CAR", "Chad", "Mali", "Burkina Faso", "Niger",
  "Sudan", "Syria", "Myanmar", "Venezuela", "Zimbabwe", "Zambia", "Kenya",
  "Uganda", "Tanzania", "United Republic of Tanzania", "Mozambique", 
  "Cameroon", "Senegal", "Mauritania", "Libya", "Iraq", "Lebanon", "Jordan",
  "Palestine", "Gaza", "West Bank", "Pakistan", "Bangladesh", "Sri Lanka",
  "Nepal", "Philippines", "Indonesia", "Colombia", "Peru", "Guatemala",
  "Honduras", "El Salvador", "Nicaragua", "Angola", "Malawi", "Burundi",
  "Rwanda", "Eritrea", "Djibouti", "Sierra Leone", "Liberia", "Guinea",
  "Guinea-Bissau", "Gambia", "Benin", "Togo", "Ghana", "Côte d'Ivoire",
  "Ivory Coast", "Cote d'Ivoire"
)

# Extract data for each country
extracted_countries <- data.frame()

for(country in all_countries) {
  # Find all lines mentioning this country
  country_lines <- full_text[str_detect(full_text, regex(paste0("\\b", country, "\\b"), ignore_case = TRUE))]
  
  if(length(country_lines) > 0) {
    # Look for the most data-rich line (usually has numbers and phase info)
    best_line <- NULL
    best_score <- 0
    
    for(line in country_lines) {
      score <- 0
      
      # Check for IPC phase
      if(str_detect(line, "(?i)phase\\s*[345]|ipc\\s*[345]")) score <- score + 10
      
      # Check for large numbers (population)
      numbers <- str_extract_all(line, "\\d{1,2}(?:\\.\\d+)?\\s*[Mm]illion|\\d{1,3}(?:,\\d{3})*(?:\\s*[Mm]illion)?")[[1]]
      if(length(numbers) > 0) score <- score + 5
      
      # Check for year
      if(str_detect(line, "202[0-9]")) score <- score + 2
      
      if(score > best_score) {
        best_score <- score
        best_line <- line
      }
    }
    
    if(!is.null(best_line) && best_score >= 5) {
      # Extract IPC phase
      phase <- NA
      phase_match <- str_extract(best_line, "(?i)(?:phase|ipc)\\s*([345])")
      if(!is.na(phase_match)) {
        phase <- as.numeric(str_extract(phase_match, "[345]"))
      }
      
      # Extract population numbers
      pop_numbers <- str_extract_all(best_line, "\\d{1,2}(?:\\.\\d+)?\\s*[Mm]illion|\\d{1,3}(?:,\\d{3})*(?:\\s*[Mm]illion)?")[[1]]
      pop_clean <- numeric()
      for(pop in pop_numbers) {
        # Convert to numeric (handle "15.8 million" format)
        num_str <- str_extract(pop, "\\d{1,2}(?:\\.\\d+)?")
        if(!is.na(num_str)) {
          num_val <- as.numeric(num_str)
          if(str_detect(pop, "[Mm]illion")) {
            num_val <- num_val * 1000000
          } else if(str_detect(pop, "[Kk]")) {
            num_val <- num_val * 1000
          }
          pop_clean <- c(pop_clean, num_val)
        }
      }
      
      # Extract year
      year <- NA
      year_match <- str_extract(best_line, "202[0-9]")
      if(!is.na(year_match)) {
        year <- as.numeric(year_match)
      }
      
      # Extract primary driver (Conflict, Climate, Economic)
      driver <- NA
      if(str_detect(tolower(best_line), "conflict")) driver <- "Conflict"
      else if(str_detect(tolower(best_line), "climate|drought|flood")) driver <- "Climate"
      else if(str_detect(tolower(best_line), "economic")) driver <- "Economic"
      
      # Determine population in Phase 3+ (largest number usually)
      pop_phase3_plus <- if(length(pop_clean) > 0) max(pop_clean, na.rm = TRUE) else NA
      
      extracted_countries <- rbind(extracted_countries, data.frame(
        country = country,
        assessment_year = ifelse(is.na(year), 2024, year),
        ipc_phase = phase,
        population_phase3_plus = pop_phase3_plus,
        population_phase4_plus = NA,  # Will need manual review
        population_phase5 = NA,       # Will need manual review
        primary_driver = driver,
        secondary_driver = NA,
        source_line = substr(best_line, 1, 300),
        stringsAsFactors = FALSE
      ))
    }
  }
}

# Remove duplicates (keep first occurrence)
extracted_countries <- extracted_countries %>%
  group_by(country) %>%
  slice(1) %>%
  ungroup()

cat("✅ Extracted data for", nrow(extracted_countries), "countries\n\n")

if(nrow(extracted_countries) > 0) {
  # Show summary
  cat("📊 Summary:\n")
  cat("==========\n")
  cat("Countries with IPC Phase 4 or 5:", sum(extracted_countries$ipc_phase >= 4, na.rm = TRUE), "\n")
  cat("Countries with IPC Phase 3:", sum(extracted_countries$ipc_phase == 3, na.rm = TRUE), "\n")
  cat("Countries with population data:", sum(!is.na(extracted_countries$population_phase3_plus)), "\n")
  cat("Countries with primary driver:", sum(!is.na(extracted_countries$primary_driver)), "\n\n")
  
  # Show countries with Phase 4 or 5
  phase45 <- extracted_countries %>% filter(ipc_phase >= 4)
  if(nrow(phase45) > 0) {
    cat("🚨 Countries in Phase 4 or 5 (Emergency/Famine):\n")
    for(i in 1:nrow(phase45)) {
      cat(sprintf("  %-30s: Phase %d, %.1fM people\n", 
                  phase45$country[i], 
                  phase45$ipc_phase[i],
                  phase45$population_phase3_plus[i] / 1000000))
    }
    cat("\n")
  }
  
  # Save extracted data
  output_file <- "data/raw/wfp/grfc2025_data.csv"
  extracted_countries %>%
    select(country, assessment_year, ipc_phase, population_phase3_plus, 
           population_phase4_plus, population_phase5, primary_driver, secondary_driver) %>%
    write_csv(output_file)
  
  cat("💾 Saved extracted data to:", output_file, "\n")
  cat("📝 Note: Some fields may need manual review/refinement\n\n")
  
  # Also save detailed version with source lines
  write_csv(extracted_countries, "data/processed/grfc2025_extracted_detailed.csv")
  cat("💾 Saved detailed version (with source lines) to: data/processed/grfc2025_extracted_detailed.csv\n\n")
  
  # Show sample
  cat("📋 Sample extracted data:\n")
  print(head(extracted_countries %>% select(country, ipc_phase, population_phase3_plus, primary_driver), 10))
  
} else {
  cat("⚠️ Could not extract structured data automatically\n")
  cat("💡 The PDF may use complex formatting. Try manual extraction.\n")
}

cat("\n✅ Extraction complete!\n")

