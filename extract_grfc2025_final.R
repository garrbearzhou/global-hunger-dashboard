# Final GRFC 2025 Data Extraction - Targeted approach
library(tidyverse)
library(stringr)

cat("📊 Final GRFC 2025 Data Extraction\n")
cat("==================================\n\n")

# Read text
full_text <- readLines("data/processed/grfc2025_full_text.txt", warn = FALSE)
full_text_combined <- paste(full_text, collapse = " ")

cat("✅ Loaded text\n\n")

# Known countries that should be in GRFC 2025
target_countries <- c(
  "Afghanistan", "Yemen", "Somalia", "South Sudan", "Ethiopia", "Nigeria",
  "Haiti", "Madagascar", "Democratic Republic of the Congo", "DRC",
  "Central African Republic", "CAR", "Chad", "Mali", "Burkina Faso", "Niger",
  "Sudan", "Syria", "Syrian Arab Republic", "Myanmar", "Venezuela", 
  "Zimbabwe", "Zambia", "Kenya", "Uganda", "Tanzania", "United Republic of Tanzania",
  "Mozambique", "Cameroon", "Senegal", "Mauritania", "Libya", "Iraq", 
  "Lebanon", "Jordan", "Palestine", "Gaza", "Gaza Strip", "West Bank",
  "Pakistan", "Bangladesh", "Sri Lanka", "Nepal", "Philippines", "Indonesia",
  "Colombia", "Peru", "Guatemala", "Honduras", "El Salvador", "Nicaragua",
  "Angola", "Malawi", "Burundi", "Rwanda", "Eritrea", "Djibouti",
  "Sierra Leone", "Liberia", "Guinea", "Guinea-Bissau", "Gambia", "Benin",
  "Togo", "Ghana", "Côte d'Ivoire", "Ivory Coast", "Cote d'Ivoire",
  "Republic of the Congo", "Congo", "Ukraine", "Moldova"
)

cat("🔍 Extracting data for", length(target_countries), "target countries...\n\n")

extracted_data <- data.frame()

for(country in target_countries) {
  # Find all mentions of this country
  country_pattern <- paste0("\\b", str_replace_all(country, " ", "\\s+"), "\\b")
  matches <- str_locate_all(full_text_combined, regex(country_pattern, ignore_case = TRUE))[[1]]
  
  if(nrow(matches) > 0) {
    # Get context around each mention (500 characters before and after)
    best_match <- NULL
    best_score <- 0
    
    for(i in 1:min(nrow(matches), 10)) {  # Check first 10 mentions
      start <- max(1, matches[i, "start"] - 500)
      end <- min(nchar(full_text_combined), matches[i, "end"] + 500)
      context <- substr(full_text_combined, start, end)
      
      score <- 0
      
      # Look for IPC phase
      if(str_detect(context, "(?i)phase\\s*[345]|ipc\\s*[345]")) {
        score <- score + 20
        phase_match <- str_extract(context, "(?i)(?:phase|ipc)\\s*([345])")
        phase <- as.numeric(str_extract(phase_match, "[345]"))
      } else {
        phase <- NA
      }
      
      # Look for population numbers (in millions format like "15.8M" or "15.8 million")
      pop_patterns <- c(
        "\\d{1,2}(?:\\.\\d+)?\\s*[Mm]illion",
        "\\d{1,2}(?:\\.\\d+)?\\s*[Mm]"
      )
      
      pop_numbers <- numeric()
      for(pattern in pop_patterns) {
        matches_pop <- str_extract_all(context, pattern)[[1]]
        for(match in matches_pop) {
          num <- as.numeric(str_extract(match, "\\d{1,2}(?:\\.\\d+)?"))
          if(!is.na(num) && num > 0.1 && num < 200) {  # Reasonable range for millions
            if(str_detect(match, "[Mm]illion")) {
              pop_numbers <- c(pop_numbers, num * 1000000)
            } else if(str_detect(match, "[Mm]")) {
              pop_numbers <- c(pop_numbers, num * 1000000)
            }
            score <- score + 5
          }
        }
      }
      
      # Look for year
      year <- NA
      year_match <- str_extract(context, "202[0-9]")
      if(!is.na(year_match)) {
        year <- as.numeric(year_match)
        score <- score + 2
      }
      
      # Look for drivers
      driver <- NA
      if(str_detect(tolower(context), "conflict")) driver <- "Conflict"
      else if(str_detect(tolower(context), "climate|drought|flood")) driver <- "Climate"
      else if(str_detect(tolower(context), "economic")) driver <- "Economic"
      
      if(score > best_score) {
        best_score <- score
        best_match <- list(
          country = country,
          phase = phase,
          pop_numbers = pop_numbers,
          year = year,
          driver = driver,
          context = substr(context, 1, 300)
        )
      }
    }
    
    if(!is.null(best_match) && best_score >= 5) {
      extracted_data <- rbind(extracted_data, data.frame(
        country = best_match$country,
        assessment_year = ifelse(is.na(best_match$year), 2024, best_match$year),
        ipc_phase = best_match$phase,
        population_phase3_plus = if(length(best_match$pop_numbers) > 0) max(best_match$pop_numbers) else NA,
        population_phase4_plus = NA,
        population_phase5 = NA,
        primary_driver = best_match$driver,
        secondary_driver = NA,
        stringsAsFactors = FALSE
      ))
    }
  }
}

# Remove duplicates and clean
extracted_data <- extracted_data %>%
  group_by(country) %>%
  slice_max(population_phase3_plus, n = 1) %>%
  ungroup() %>%
  # Standardize country names
  mutate(
    country = case_when(
      country == "DRC" ~ "Democratic Republic of the Congo",
      country == "CAR" ~ "Central African Republic",
      country == "Syrian Arab Republic" ~ "Syria",
      country == "Gaza Strip" ~ "Gaza",
      country == "Ivory Coast" ~ "Côte d'Ivoire",
      country == "Cote d'Ivoire" ~ "Côte d'Ivoire",
      country == "United Republic of Tanzania" ~ "Tanzania",
      str_detect(country, "Congo") & !str_detect(country, "Democratic") ~ "Republic of the Congo",
      TRUE ~ country
    )
  ) %>%
  # Remove if population seems wrong (too small or too large)
  filter(is.na(population_phase3_plus) | (population_phase3_plus > 100000 & population_phase3_plus < 500000000))

cat("✅ Extracted data for", nrow(extracted_data), "countries\n\n")

if(nrow(extracted_data) > 0) {
  # Show summary
  cat("📊 Summary:\n")
  cat("==========\n")
  cat("Countries with IPC Phase 4 or 5:", sum(extracted_data$ipc_phase >= 4, na.rm = TRUE), "\n")
  cat("Countries with IPC Phase 3:", sum(extracted_data$ipc_phase == 3, na.rm = TRUE), "\n")
  cat("Countries with population data:", sum(!is.na(extracted_data$population_phase3_plus)), "\n\n")
  
  # Show countries with Phase 4 or 5
  phase45 <- extracted_data %>% filter(ipc_phase >= 4) %>% arrange(desc(ipc_phase), desc(population_phase3_plus))
  if(nrow(phase45) > 0) {
    cat("🚨 Countries in Phase 4 or 5 (Emergency/Famine):\n")
    for(i in 1:min(20, nrow(phase45))) {
      pop_display <- if(is.na(phase45$population_phase3_plus[i])) "N/A" else paste0(round(phase45$population_phase3_plus[i]/1000000, 1), "M")
      cat(sprintf("  %-30s: Phase %d, %s people\n", 
                  phase45$country[i], 
                  phase45$ipc_phase[i],
                  pop_display))
    }
    cat("\n")
  }
  
  # Show top countries by population
  cat("📊 Top 15 countries by population in crisis:\n")
  top_pop <- extracted_data %>% 
    filter(!is.na(population_phase3_plus)) %>%
    arrange(desc(population_phase3_plus)) %>%
    head(15)
  for(i in 1:nrow(top_pop)) {
    cat(sprintf("  %-30s: %.1fM people", top_pop$country[i], top_pop$population_phase3_plus[i]/1000000))
    if(!is.na(top_pop$ipc_phase[i])) cat(sprintf(", Phase %d", top_pop$ipc_phase[i]))
    cat("\n")
  }
  cat("\n")
  
  # Save
  write_csv(extracted_data, "data/raw/wfp/grfc2025_data.csv")
  cat("💾 Saved to: data/raw/wfp/grfc2025_data.csv\n\n")
  
  cat("📋 Sample data:\n")
  print(head(extracted_data, 10))
  
} else {
  cat("⚠️ No data extracted\n")
}

cat("\n✅ Extraction complete!\n")
cat("💡 Note: Population numbers and IPC phases may need manual verification\n")
cat("💡 Review the data and refine as needed\n")

