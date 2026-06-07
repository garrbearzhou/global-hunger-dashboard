# Process GRFC 2025 Hunger Crises Data
# Global Report on Food Crises 2025 - Data Extraction and Analysis

library(tidyverse)

cat("📊 Processing GRFC 2025 Hunger Crises Data\n")
cat("==========================================\n\n")

# Check if PDF exists
pdf_file <- "data/raw/wfp/GRFC2025 Hunger Crises Data.pdf"

if(!file.exists(pdf_file)) {
  cat("❌ PDF file not found:", pdf_file, "\n")
  cat("Please ensure the file exists.\n")
  quit(status = 1)
}

cat("✅ Found GRFC 2025 PDF:", pdf_file, "\n")
cat("File size:", round(file.info(pdf_file)$size / 1024 / 1024, 2), "MB\n\n")

# Try to extract text from PDF
cat("Attempting to extract data from PDF...\n")
cat("(This may require pdftools package)\n\n")

# Check if pdftools is available
if(require("pdftools", quietly = TRUE)) {
  cat("✅ pdftools package available\n")
  
  tryCatch({
    # Extract text from PDF
    cat("Extracting text from PDF (this may take a moment)...\n")
    pdf_text <- pdf_text(pdf_file)
    
    cat("✅ Successfully extracted text from", length(pdf_text), "pages\n\n")
    
    # Save raw text for review
    writeLines(pdf_text, "data/processed/grfc2025_extracted_text.txt")
    cat("📄 Raw text saved to: data/processed/grfc2025_extracted_text.txt\n")
    
    # Look for tables and key data
    cat("\n🔍 Analyzing content...\n")
    
    # Search for common GRFC indicators
    indicators <- c(
      "Phase 3",
      "Phase 4", 
      "Phase 5",
      "IPC",
      "famine",
      "severe food insecurity",
      "acute food insecurity",
      "people in need",
      "crisis",
      "emergency"
    )
    
    # Count mentions
    full_text <- paste(pdf_text, collapse = " ")
    for(indicator in indicators) {
      count <- str_count(tolower(full_text), tolower(indicator))
      if(count > 0) {
        cat("  - '", indicator, "': ", count, " mentions\n", sep = "")
      }
    }
    
    # Look for country names (common countries in food crises)
    crisis_countries <- c(
      "Afghanistan", "Yemen", "Somalia", "South Sudan", "Ethiopia",
      "Nigeria", "Haiti", "Madagascar", "Democratic Republic of the Congo",
      "Central African Republic", "Chad", "Mali", "Burkina Faso", "Niger",
      "Sudan", "Syria", "Myanmar", "Venezuela", "Zimbabwe", "Zambia"
    )
    
    cat("\n🌍 Countries mentioned in report:\n")
    for(country in crisis_countries) {
      if(str_detect(full_text, country)) {
        cat("  ✓", country, "\n")
      }
    }
    
    cat("\n✅ PDF text extraction complete!\n")
    cat("📝 Review the extracted text file to identify data tables\n")
    cat("💡 Tip: Look for tables with country names, IPC phases, and population numbers\n")
    
  }, error = function(e) {
    cat("❌ Error extracting PDF:", e$message, "\n")
    cat("💡 Alternative: Manually extract data tables from PDF and save as CSV\n")
  })
  
} else {
  cat("⚠️ pdftools package not available\n")
  cat("\n📋 Manual Extraction Guide:\n")
  cat("===========================\n\n")
  cat("The GRFC 2025 report typically contains:\n\n")
  cat("1. **Country-Level Data Tables:**\n")
  cat("   - Country name\n")
  cat("   - IPC Phase classification (Phase 3, 4, or 5)\n")
  cat("   - Number of people in each phase\n")
  cat("   - Total population in crisis (Phase 3+)\n")
  cat("   - Year/period of assessment\n\n")
  
  cat("2. **Key Indicators to Extract:**\n")
  cat("   - Country\n")
  cat("   - IPC Phase (3 = Crisis, 4 = Emergency, 5 = Famine)\n")
  cat("   - Population in Phase 3+\n")
  cat("   - Population in Phase 4+\n")
  cat("   - Population in Phase 5 (Famine)\n")
  cat("   - Assessment year\n")
  cat("   - Primary drivers (Conflict, Climate, Economic)\n\n")
  
  cat("3. **Recommended CSV Format:**\n")
  cat("   country,assessment_year,ipc_phase,population_phase3_plus,population_phase4_plus,population_phase5,primary_driver\n")
  cat("   Afghanistan,2024,3,15800000,2800000,0,Conflict\n")
  cat("   Yemen,2024,4,18000000,6500000,0,Conflict\n")
  cat("   ...\n\n")
  
  cat("4. **Steps to Extract:**\n")
  cat("   a. Open the PDF\n")
  cat("   b. Find data tables (usually in appendices or country sections)\n")
  cat("   c. Copy tables to Excel/Google Sheets\n")
  cat("   d. Clean and standardize country names\n")
  cat("   e. Save as CSV: data/raw/wfp/grfc2025_data.csv\n")
  cat("   f. Re-run this script or update create_comprehensive_data_table.R\n\n")
  
  cat("5. **Where to Find Data in GRFC Report:**\n")
  cat("   - Executive Summary: Key numbers\n")
  cat("   - Country Profiles: Detailed country data\n")
  cat("   - Appendices: Comprehensive tables\n")
  cat("   - Regional Analysis: Regional aggregations\n\n")
}

cat("\n📚 About GRFC 2025:\n")
cat("==================\n")
cat("The Global Report on Food Crises (GRFC) is the reference document\n")
cat("for acute food insecurity worldwide. It provides:\n\n")
cat("• Country-level IPC classifications\n")
cat("• Population estimates by crisis severity\n")
cat("• Primary drivers of food crises\n")
cat("• Historical trends\n")
cat("• Regional analysis\n\n")

cat("This data is EXCELLENT for:\n")
cat("✓ Identifying countries in Phase 4 (Emergency) and Phase 5 (Famine)\n")
cat("✓ Getting accurate population numbers in crisis\n")
cat("✓ Understanding primary drivers (Conflict, Climate, Economic)\n")
cat("✓ Updating historical hunger outbreak data\n")
cat("✓ Validating other data sources\n\n")

cat("💡 Next Steps:\n")
cat("1. Extract data tables from PDF (manually or with pdftools)\n")
cat("2. Create CSV file: data/raw/wfp/grfc2025_data.csv\n")
cat("3. Update create_comprehensive_data_table.R to include GRFC data\n")
cat("4. Re-run comprehensive data table script\n\n")

