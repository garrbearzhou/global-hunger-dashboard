# Extract GRFC 2025 Data from PDF
library(tidyverse)
library(pdftools)
library(stringr)

cat("📊 Extracting GRFC 2025 Data from PDF\n")
cat("======================================\n\n")

pdf_file <- "data/raw/wfp/GRFC2025 Hunger Crises Data.pdf"

if(!file.exists(pdf_file)) {
  stop("PDF file not found: ", pdf_file)
}

cat("✅ Found PDF:", pdf_file, "\n")
cat("📄 Extracting text from PDF (this may take a moment for 32MB file)...\n\n")

# Extract text from PDF
pdf_text <- pdf_text(pdf_file)
cat("✅ Extracted text from", length(pdf_text), "pages\n\n")

# Save raw text for reference
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
writeLines(pdf_text, "data/processed/grfc2025_full_text.txt")
cat("💾 Saved full text to: data/processed/grfc2025_full_text.txt\n\n")

# Combine all pages
full_text <- paste(pdf_text, collapse = "\n")

# Look for data tables - common patterns in GRFC reports
cat("🔍 Searching for data tables...\n\n")

# Common country names in food crises
crisis_countries <- c(
  "Afghanistan", "Yemen", "Somalia", "South Sudan", "Ethiopia", "Nigeria",
  "Haiti", "Madagascar", "Democratic Republic of the Congo", "DRC", "Congo",
  "Central African Republic", "CAR", "Chad", "Mali", "Burkina Faso", "Niger",
  "Sudan", "Syria", "Myanmar", "Venezuela", "Zimbabwe", "Zambia", "Kenya",
  "Uganda", "Tanzania", "Mozambique", "Cameroon", "Senegal", "Mauritania",
  "Libya", "Iraq", "Lebanon", "Jordan", "Palestine", "Gaza", "West Bank",
  "Pakistan", "Bangladesh", "Sri Lanka", "Nepal", "Philippines", "Indonesia"
)

# Look for IPC phase patterns
ipc_patterns <- c(
  "Phase 3", "Phase 4", "Phase 5",
  "IPC 3", "IPC 4", "IPC 5",
  "Crisis", "Emergency", "Famine"
)

# Extract pages that likely contain data tables
cat("📋 Analyzing content structure...\n")

# Look for table indicators
table_indicators <- c(
  "Country", "Territory", "Population", "Phase", "IPC",
  "million", "thousand", "people", "assessment"
)

# Find pages with potential data
data_pages <- c()
for(i in seq_along(pdf_text)) {
  page_lower <- tolower(pdf_text[i])
  if(any(str_detect(page_lower, table_indicators)) && 
     any(str_detect(page_lower, tolower(crisis_countries)))) {
    data_pages <- c(data_pages, i)
  }
}

cat("📄 Found potential data on", length(data_pages), "pages\n")
if(length(data_pages) > 0) {
  cat("Pages:", paste(head(data_pages, 10), collapse = ", "), 
      if(length(data_pages) > 10) "..." else "", "\n\n")
}

# Try to extract structured data
cat("🔧 Attempting to extract structured data...\n\n")

# Method 1: Look for country names followed by numbers (population data)
extracted_data <- data.frame()

# Split text into lines
all_lines <- unlist(str_split(full_text, "\n"))

# Look for patterns like: Country Name | Number | Phase | etc.
# This is a simplified extraction - may need refinement

cat("📊 Extracting country data...\n")

# Try to find country entries with numbers
for(country in crisis_countries) {
  # Find lines mentioning this country
  country_lines <- all_lines[str_detect(all_lines, regex(country, ignore_case = TRUE))]
  
  if(length(country_lines) > 0) {
    # Look for numbers (population, percentages)
    for(line in country_lines) {
      # Extract numbers from line
      numbers <- str_extract_all(line, "\\d{1,3}(?:[,\\.]\\d{3})*(?:\\.\\d+)?")[[1]]
      numbers_clean <- as.numeric(str_replace_all(numbers, ",", ""))
      
      # Look for IPC phase
      phase <- NA
      if(str_detect(line, "(?i)phase\\s*[345]|ipc\\s*[345]")) {
        phase_match <- str_extract(line, "(?i)phase\\s*([345])|ipc\\s*([345])")
        phase <- str_extract(phase_match, "[345]")
      }
      
      # Look for year
      year <- NA
      year_match <- str_extract(line, "20[0-9]{2}")
      if(!is.na(year_match)) {
        year <- as.numeric(year_match)
      }
      
      # If we found meaningful data, add it
      if(length(numbers_clean) > 0 && !all(is.na(numbers_clean)) && any(numbers_clean > 1000, na.rm = TRUE)) {
        extracted_data <- rbind(extracted_data, data.frame(
          country = country,
          line_text = substr(line, 1, 200),
          numbers_found = paste(numbers_clean[!is.na(numbers_clean)], collapse = ", "),
          ipc_phase = ifelse(is.na(phase), NA, as.numeric(phase)),
          year = year,
          stringsAsFactors = FALSE
        ))
      }
    }
  }
}

if(nrow(extracted_data) > 0) {
  cat("✅ Found", nrow(extracted_data), "potential data entries\n\n")
  
  # Save preliminary extraction
  write_csv(extracted_data, "data/processed/grfc2025_preliminary_extraction.csv")
  cat("💾 Saved preliminary extraction to: data/processed/grfc2025_preliminary_extraction.csv\n\n")
  
  # Show sample
  cat("📋 Sample extracted data:\n")
  print(head(extracted_data, 10))
} else {
  cat("⚠️ Could not automatically extract structured data\n")
  cat("💡 The PDF may use complex table formatting\n\n")
}

# Create a more detailed analysis
cat("\n📈 Content Analysis:\n")
cat("===================\n\n")

# Count mentions
cat("Country mentions:\n")
for(country in head(crisis_countries, 15)) {
  count <- sum(str_detect(tolower(full_text), tolower(country)))
  if(count > 0) {
    cat(sprintf("  %-30s: %3d mentions\n", country, count))
  }
}

cat("\nIPC Phase mentions:\n")
for(phase in c("Phase 3", "Phase 4", "Phase 5", "IPC 3", "IPC 4", "IPC 5")) {
  count <- sum(str_detect(full_text, regex(phase, ignore_case = TRUE)))
  if(count > 0) {
    cat(sprintf("  %-15s: %3d mentions\n", phase, count))
  }
}

cat("\n📝 Recommendations:\n")
cat("==================\n")
cat("1. Review the full text file: data/processed/grfc2025_full_text.txt\n")
cat("2. Search for 'Country' or 'Territory' to find data tables\n")
cat("3. Look for pages with numbers in millions (e.g., '15.8 million')\n")
cat("4. Manual extraction may be needed for complex tables\n")
cat("5. Check if WFP/FAO provides CSV/Excel version of the data\n\n")

cat("✅ Extraction complete! Review the output files for data.\n")

