# =============================================================================
# GLOBAL HUNGER RESEARCH WEBSITE
# Shiny Web Application for Hunger Data Visualization and Analysis
# Author: Garrett Zhou
# Date: October 2024
# =============================================================================

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
library(readxl)  # For reading Excel files (GHI data)

# Set working directory
setwd(here())

if (file.exists("R/country_flags.R")) {
  source("R/country_flags.R", local = FALSE)
}
if (file.exists("R/citations.R")) {
  source("R/citations.R", local = FALSE)
}
if (file.exists("R/data_coverage.R")) {
  source("R/data_coverage.R", local = FALSE)
}
if (file.exists("R/grfc_trends.R")) {
  source("R/grfc_trends.R", local = FALSE)
}
if (file.exists("R/scenario_country_map.R")) {
  source("R/scenario_country_map.R", local = FALSE)
}

# Serve static assets from /www when running via shinyApp() (run_app.R)
# Note: shinyApp(ui, server) does NOT automatically expose the /www folder like runApp(appDir) does.
if (dir.exists("www")) {
  shiny::addResourcePath("assets", normalizePath("www"))
}

# =============================================================================
# DATA LOADING AND PREPARATION
# =============================================================================

# Function to load and prepare data
load_hunger_data <- function() {
  # Try to load existing data, if not available, collect new data
  if(file.exists("data/raw/world_bank_data.csv")) {
    cat("Loading existing World Bank data...\n")
    wb_data <- read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE)
    # Drop corrupted rows where country name is text concatenated with a number (e.g. Barb994.64806074889)
    if ("country" %in% names(wb_data)) {
      wb_data <- wb_data %>%
        filter(is.na(country) | !grepl("^[A-Za-z]+[0-9.]+$", trimws(as.character(country))))
    }
    # Normalize column names back to original WDI format if they were renamed
    # Map renamed columns back to original names
    col_mapping <- c(
      "pop_POP.TOTL" = "SP.POP.TOTL",
      "gdp_GDP.MKTP.CD" = "NY.GDP.MKTP.CD",
      "gdp_GDP.PCAP.CD" = "NY.GDP.PCAP.CD",
      "inflation_CPI.TOTL.ZG" = "FP.CPI.TOTL.ZG",
      "poverty_POV.DDAY" = "SI.POV.DDAY",
      "agriculture_LND.AGRI.ZS" = "AG.LND.AGRI.ZS",
      "agriculture_PRD.CROP.XD" = "AG.PRD.CROP.XD",
      "pop_RUR.TOTL.ZS" = "SP.RUR.TOTL.ZS",
      "pop_URB.TOTL.IN.ZS" = "SP.URB.TOTL.IN.ZS",
      "education_ADT.LITR.ZS" = "SE.ADT.LITR.ZS",
      "pop_DYN.LE00.IN" = "SP.DYN.LE00.IN",
      "pop_DYN.IMRT.IN" = "SP.DYN.IMRT.IN",
      "agriculture_CON.FERT.ZS" = "AG.CON.FERT.ZS",
      "agriculture_LND.ARBL.ZS" = "AG.LND.ARBL.ZS",
      "agriculture_LND.TOTL.K2" = "AG.LND.TOTL.K2",
      "pop_POP.GROW" = "SP.POP.GROW",
      "gdp_GDP.MKTP.KD.ZG" = "NY.GDP.MKTP.KD.ZG"
    )
    
    # Rename columns if they exist
    for(old_name in names(col_mapping)) {
      if(old_name %in% names(wb_data)) {
        names(wb_data)[names(wb_data) == old_name] <- col_mapping[old_name]
      }
    }
  } else {
    cat("Collecting World Bank data...\n")
    # Key indicators for hunger research
    indicators <- c(
      "SP.POP.TOTL",           # Population, total
      "NY.GDP.MKTP.CD",        # GDP (current US$)
      "NY.GDP.PCAP.CD",        # GDP per capita (current US$)
      "FP.CPI.TOTL.ZG",        # Inflation, consumer prices (annual %)
      "SI.POV.DDAY",           # Poverty headcount ratio at $1.90/day
      "AG.LND.AGRI.ZS",        # Agricultural land (% of land area)
      "AG.PRD.CROP.XD",        # Crop production index
      "SP.RUR.TOTL.ZS",        # Rural population (% of total population)
      "SP.URB.TOTL.IN.ZS",     # Urban population (% of total)
      "SE.ADT.LITR.ZS",        # Literacy rate, adult total (% of people ages 15+)
      "SP.DYN.LE00.IN",        # Life expectancy at birth, total (years)
      "SP.DYN.IMRT.IN",        # Mortality rate, infant (per 1,000 live births)
      "AG.CON.FERT.ZS",        # Fertilizer consumption
      "AG.LND.ARBL.ZS",        # Arable land (% of land area)
      "AG.LND.TOTL.K2",        # Land area (sq. km)
      "SP.POP.GROW",           # Population growth (annual %)
      "NY.GDP.MKTP.KD.ZG",     # GDP growth (annual %)
      "NE.TRD.GNFS.ZS",        # Trade (% of GDP)
      "NE.EXP.GNFS.ZS",        # Exports of goods and services (% of GDP)
      "NE.IMP.GNFS.ZS"         # Imports of goods and services (% of GDP)
    )
    
    wb_data <- WDI(country = "all", 
                   indicator = indicators,
                   start = 2000, 
                   end = 2023,
                   extra = TRUE)
    
    # Save data (keeping original column names)
    dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)
    write_csv(wb_data, "data/raw/world_bank_data.csv")
  }
  
  return(wb_data)
}

# Country name standardization: load mapping table (200+ variants) then apply inline overrides
country_name_mapping_table <- NULL
if (file.exists("country_name_mapping.csv")) {
  tryCatch({
    country_name_mapping_table <- read_csv("country_name_mapping.csv", show_col_types = FALSE)
    country_name_mapping_table <- country_name_mapping_table %>%
      filter(!is.na(original_name) & !is.na(standardized_name) & nzchar(trimws(original_name))) %>%
      distinct(original_name, .keep_all = TRUE)
    cat("Loaded country name mapping:", nrow(country_name_mapping_table), "variants\n")
  }, error = function(e) cat("Could not load country_name_mapping.csv:", e$message, "\n"))
}

standardize_country_names <- function(country_names) {
  # Trim and normalize
  out <- trimws(as.character(country_names))
  out[out == "" | is.na(country_names)] <- NA_character_

  # 1) Apply CSV mapping if loaded
  if (!is.null(country_name_mapping_table) && nrow(country_name_mapping_table) > 0) {
    map_vec <- setNames(
      country_name_mapping_table$standardized_name,
      country_name_mapping_table$original_name
    )
    for (i in seq_along(out)) {
      if (is.na(out[i])) next
      if (out[i] %in% names(map_vec)) out[i] <- unname(map_vec[out[i]])
    }
  }

  # 2) Inline overrides (WB/UN variants not in CSV)
  inline_mapping <- c(
    "United States of America" = "United States",
    "United Kingdom of Great Britain and Northern Ireland" = "United Kingdom",
    "Venezuela, RB" = "Venezuela",
    "Yemen, Rep." = "Yemen",
    "Egypt, Arab Rep." = "Egypt",
    "Gambia, The" = "Gambia",
    "Bahamas, The" = "Bahamas",
    "Korea, Dem. People's Rep." = "North Korea",
    "Korea, Republic of" = "South Korea",
    "Congo, Dem. Rep." = "Democratic Republic of the Congo",
    "Congo, Rep." = "Republic of the Congo",
    "Macedonia, FYR" = "North Macedonia",
    "Micronesia, Fed. Sts." = "Micronesia",
    "Lao PDR" = "Laos",
    "Syrian Arab Republic" = "Syria",
    "Brunei Darussalam" = "Brunei",
    "Czech Republic" = "Czechia",
    "Slovak Republic" = "Slovakia",
    "São Tomé and Príncipe" = "Sao Tome and Principe",
    "St. Vincent and the Grenadines" = "Saint Vincent and the Grenadines",
    "St. Lucia" = "Saint Lucia",
    "St. Kitts and Nevis" = "Saint Kitts and Nevis",
    "Eswatini" = "Eswatini",
    "Swaziland" = "Eswatini"
  )
  for (old_name in names(inline_mapping)) {
    out[out == old_name] <- unname(inline_mapping[old_name])
  }

  out
}

# Fuzzy match a vector of country names to a backbone (canonical) list; returns same-length vector
match_country_to_backbone <- function(names_vec, backbone, max_dist = 4L) {
  backbone <- unique(trimws(as.character(backbone)))
  backbone <- backbone[!is.na(backbone) & nzchar(backbone)]
  out <- trimws(as.character(names_vec))
  lb <- tolower(backbone)
  for (i in seq_along(out)) {
    if (is.na(out[i]) || out[i] %in% backbone) next
    # Case-insensitive: compare lower case; use length for max_dist if short names
    d <- adist(tolower(out[i]), lb, partial = FALSE)
    min_d <- min(d, na.rm = TRUE)
    if (length(min_d) && is.finite(min_d) && min_d <= max_dist) {
      out[i] <- backbone[which.min(d)[1]]
    }
  }
  out
}

# Map a data frame's country column to backbone and keep one row per backbone country (first row wins)
map_data_countries_to_backbone <- function(df, backbone_countries, country_col = "country") {
  if (is.null(df) || nrow(df) == 0) return(df)
  if (!country_col %in% names(df)) return(df)
  backbone <- unique(trimws(as.character(backbone_countries)))
  backbone <- backbone[!is.na(backbone) & nzchar(backbone)]
  if (length(backbone) == 0) return(df)
  df <- df %>% mutate(!!sym(country_col) := match_country_to_backbone(!!sym(country_col), backbone))
  df %>% group_by(!!sym(country_col)) %>% slice(1) %>% ungroup()
}

# ISO3 codes for countries that may appear in FAO/OWID but not in WB, or for map backbone (Pacific islands etc.)
# Include PRK, ERI, TKM so they appear on map (grey = inaccurate data)
country_iso3_fallback <- function() {
  tribble(
    ~country, ~iso3c,
    "Korea, Dem. People's Rep.", "PRK",
    "Eritrea", "ERI",
    "Turkmenistan", "TKM",
    "Venezuela", "VEN",
    "Cuba", "CUB",
    "Yemen", "YEM",
    "Ethiopia", "ETH",
    "South Sudan", "SSD",
    "Kiribati", "KIR",
    "Tuvalu", "TUV",
    "Marshall Islands", "MHL",
    "Micronesia", "FSM",
    "Palau", "PLW",
    "Samoa", "WSM",
    "Tonga", "TON",
    "Solomon Islands", "SLB",
    "Vanuatu", "VUT",
    "Fiji", "FJI",
    "Nauru", "NRU",
    "Cook Islands", "COK",
    "Niue", "NIU",
    "Tokelau", "TKL",
    "American Samoa", "ASM",
    "Northern Mariana Islands", "MNP",
    "Guam", "GUM",
    "French Polynesia", "PYF",
    "New Caledonia", "NCL",
    "Timor-Leste", "TLS",
    "Sao Tome and Principe", "STP",
    "Saint Lucia", "LCA",
    "Saint Vincent and the Grenadines", "VCT",
    "Eswatini", "SWZ"
  )
}

# =============================================================================
# LOAD ALL DATA SOURCES
# =============================================================================

cat("🌍 Loading all data sources from data/raw...\n")

# Load World Bank data
hunger_data <- load_hunger_data()

# World Bank "World" (ISO WLD) — used for global time-series (not sum/mean of countries)
world_bank_timeseries <- hunger_data %>%
  filter(iso3c == "WLD" | tolower(trimws(country)) == "world") %>%
  mutate(year = as.integer(as.numeric(year))) %>%
  group_by(year) %>%
  slice(1L) %>%
  ungroup() %>%
  arrange(year)
if (nrow(world_bank_timeseries) > 0) {
  cat("✅ World Bank World (WLD) time series:", nrow(world_bank_timeseries), "years\n")
} else {
  cat("⚠️ No World Bank World (WLD) rows found; global time series will use population-weighted country aggregates\n")
}

# Load FAO data (latest year only for summary)
load_fao_data <- function() {
  cat("Loading FAO data...\n")
  tryCatch({
    if(file.exists("data/raw/fao/fao_data.csv")) {
      fao_data <- read_csv("data/raw/fao/fao_data.csv", show_col_types = FALSE)
      # Get latest undernourishment rate per country
      fao_summary <- fao_data %>%
        filter(indicator == "Prevalence of Undernourishment (%)") %>%
        group_by(country) %>%
        slice_max(year, n = 1) %>%
        select(country, year, undernourishment_rate = value) %>%
        mutate(
          country = standardize_country_names(country),
          undernourishment_rate = as.numeric(undernourishment_rate),
          # FAO reports very low prevalence as "<2.5"; raw zeros in extracts are usually missing/censored or bad joins — do not plot as 0%
          undernourishment_rate = if_else(!is.na(undernourishment_rate) & undernourishment_rate <= 0, NA_real_, undernourishment_rate),
          # Simulated extracts may be numeric only; bulk FAO marks <2.5 separately (see other branch)
          undernourishment_interval_censored = FALSE
        )
      cat("✅ Loaded FAO data for", nrow(fao_summary), "countries\n")
      return(fao_summary)
    } else if(file.exists("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data.csv")) {
      fao_raw <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data.csv", show_col_types = FALSE, col_types = cols(.default = col_character())) %>%
        mutate(Year = as.numeric(Year), `Item Code` = as.numeric(`Item Code`))
      # Process FAO data (Item Code 210041 = Prevalence of undernourishment)
      fao_processed <- fao_raw %>%
        filter(`Item Code` == 210041) %>%
        mutate(
          Value_clean = case_when(
            Value == "<2.5" ~ "2.5",
            Value == "" ~ NA_character_,
            TRUE ~ Value
          ),
          Value_numeric = as.numeric(Value_clean),
          undernourishment_interval_censored = (Value == "<2.5")
        ) %>%
        group_by(Area) %>%
        slice_max(Year, n = 1) %>%
        select(country = Area, year = Year, undernourishment_rate = Value_numeric, undernourishment_interval_censored) %>%
        mutate(
          country = standardize_country_names(country),
          undernourishment_rate = if_else(!is.na(undernourishment_rate) & undernourishment_rate <= 0, NA_real_, undernourishment_rate)
        ) %>%
        filter(!is.na(undernourishment_rate))
      cat("✅ Loaded FAO data for", nrow(fao_processed), "countries\n")
      return(fao_processed)
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading FAO data:", e$message, "\n")
    return(NULL)
  })
}

# Load FAO time series data for trend charts
load_fao_timeseries <- function() {
  cat("Loading FAO time series data...\n")
  tryCatch({
    if(file.exists("data/raw/fao/fao_data.csv")) {
      fao_data <- read_csv("data/raw/fao/fao_data.csv", show_col_types = FALSE)
      # Get all years of undernourishment data
      fao_timeseries <- fao_data %>%
        filter(indicator == "Prevalence of Undernourishment (%)") %>%
        select(country, year, undernourishment_rate = value) %>%
        mutate(
          country = standardize_country_names(country),
          undernourishment_rate = as.numeric(undernourishment_rate),
          undernourishment_rate = if_else(!is.na(undernourishment_rate) & undernourishment_rate <= 0, NA_real_, undernourishment_rate)
        ) %>%
        filter(!is.na(undernourishment_rate) & !is.na(year)) %>%
        arrange(country, year)
      cat("✅ Loaded FAO time series data for", length(unique(fao_timeseries$country)), "countries\n")
      return(fao_timeseries)
    } else if(file.exists("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data.csv")) {
      fao_raw <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data.csv", show_col_types = FALSE, col_types = cols(.default = col_character())) %>%
        mutate(Year = as.numeric(Year), `Item Code` = as.numeric(`Item Code`))
      # Process FAO data (Item Code 210041 = Prevalence of undernourishment)
      # Extract year columns (Y20002002, Y20032005, etc.)
      year_cols <- colnames(fao_raw)[grepl("^Y[0-9]{8}$", colnames(fao_raw))]
      
      if(length(year_cols) > 0) {
        fao_timeseries <- fao_raw %>%
          filter(`Item Code` == 210041) %>%
          select(Area, all_of(year_cols)) %>%
          pivot_longer(cols = all_of(year_cols), names_to = "year_range", values_to = "value") %>%
          mutate(
            # Extract start year from Y20002002 format
            year = as.numeric(substr(year_range, 2, 5)),
            Value_clean = case_when(
              value == "<2.5" ~ "2.5",
              value == "" ~ NA_character_,
              TRUE ~ as.character(value)
            ),
            undernourishment_rate = as.numeric(Value_clean),
            country = standardize_country_names(Area),
            undernourishment_rate = if_else(!is.na(undernourishment_rate) & undernourishment_rate <= 0, NA_real_, undernourishment_rate)
          ) %>%
          filter(!is.na(undernourishment_rate) & !is.na(year)) %>%
          select(country, year, undernourishment_rate) %>%
          arrange(country, year)
        cat("✅ Loaded FAO time series data for", length(unique(fao_timeseries$country)), "countries\n")
        return(fao_timeseries)
      }
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading FAO time series data:", e$message, "\n")
    return(NULL)
  })
}

# Internal: read all GRFC sources (xlsx + CSV) into one tibble, all years, for latest merge and panel/trends.
.read_grfc_sources <- function() {
  wfp_dir <- "data/raw/wfp"
  if (!dir.exists(wfp_dir)) return(NULL)
  grfc_list <- list()
  xlsx_path <- file.path(wfp_dir, "grfc2016-2024_data.xlsx")
  master_panel <- read_grfc_master_xlsx(xlsx_path)
  if (!is.null(master_panel) && nrow(master_panel) > 0) {
    grfc_list <- c(grfc_list, list(master_panel))
  }
  grfc_files <- list.files(wfp_dir, pattern = "^grfc[0-9]{4}_data\\.csv$", full.names = TRUE)
  for (f in grfc_files) {
    d <- read_csv(f, show_col_types = FALSE, col_types = cols(.default = col_character()))
    if (!"assessment_year" %in% names(d)) {
      yr <- as.integer(sub("^grfc([0-9]{4})_data\\.csv$", "\\1", basename(f)))
      if (!is.na(yr)) d$assessment_year <- yr
    }
    grfc_list <- c(grfc_list, list(d))
  }
  if (length(grfc_list) == 0) return(NULL)
  dplyr::bind_rows(lapply(grfc_list, normalize_trends_panel)) %>%
    dplyr::distinct(.data$country, .data$assessment_year, .keep_all = TRUE)
}

# Load WFP GRFC data: returns list(latest = one row per country, panel = all year-country rows for trends/export).
load_wfp_data <- function() {
  cat("Loading WFP GRFC data...\n")
  tryCatch({
    raw <- .read_grfc_sources()
    if (is.null(raw) || nrow(raw) == 0) return(list(latest = NULL, panel = NULL))
    latest <- raw %>% group_by(country) %>% slice_max(assessment_year, n = 1, with_ties = FALSE) %>% ungroup()
    cat("✅ Loaded WFP GRFC data for", nrow(latest), "countries (panel:", nrow(raw), "rows)\n")
    return(list(latest = latest, panel = raw))
  }, error = function(e) {
    cat("⚠️ Error loading WFP data:", e$message, "\n")
    return(list(latest = NULL, panel = NULL))
  })
}

# Load IPC (Integrated Food Security Phase Classification / Cadre Harmonisé) data
# Source: IPC/CH country analyses (supplements WFP GRFC for acute food insecurity)
load_ipc_data <- function() {
  cat("Loading IPC data...\n")
  tryCatch({
    path <- "data/raw/ipc/ipc data general data.csv"
    if (!file.exists(path)) return(NULL)
    raw <- read_csv(path, skip = 1, show_col_types = FALSE)
    # Drop footer rows (footer text in Country column)
    raw <- raw %>% filter(!is.na(Country), nchar(trimws(Country)) > 0, !grepl("^The data combines|^initiatives that use|^These figures|^Country analyses", Country, ignore.case = TRUE))
    # Parse numeric columns (remove commas)
    parse_num <- function(x) as.numeric(gsub(",", "", as.character(x)))
    ipc_data <- raw %>%
      rename(
        country = Country,
        phase1 = `Phase 1`,
        phase2 = `Phase 2`,
        phase3 = `Phase 3`,
        phase4 = `Phase 4`,
        phase5 = `Phase 5`,
        phase3_plus = `Phase 3+`
      ) %>%
      mutate(
        across(c(phase1, phase2, phase3, phase4, phase5, phase3_plus), parse_num),
        phase1 = replace_na(phase1, 0),
        phase2 = replace_na(phase2, 0),
        phase3 = replace_na(phase3, 0),
        phase4 = replace_na(phase4, 0),
        phase5 = replace_na(phase5, 0),
        phase3_plus = replace_na(phase3_plus, 0),
        # Derive single IPC phase: highest phase with non-zero population
        ipc_phase = case_when(
          phase5 > 0 ~ 5,
          phase4 > 0 ~ 4,
          phase3 > 0 ~ 3,
          phase2 > 0 ~ 2,
          TRUE ~ 1
        ),
        country = standardize_country_names(country)
      ) %>%
      select(country, ipc_phase, population_phase3_plus = phase3_plus)
    # Exclude non-country entries (e.g. Gaza Strip if not in backbone)
    ipc_data <- ipc_data %>% filter(nchar(country) > 0)
    cat("✅ Loaded IPC data for", nrow(ipc_data), "countries\n")
    return(ipc_data)
  }, error = function(e) {
    cat("⚠️ Error loading IPC data:", e$message, "\n")
    return(NULL)
  })
}

# Load IPC Population Analysis (xlsx) — historical/latest IPC by country from Population Tracking Tool
# Uses ISO2 prefix in "Country/Analysis Name/Area Name"; takes latest analysis per country.
load_ipc_population_data <- function() {
  cat("Loading IPC population analysis data...\n")
  tryCatch({
    path <- "data/raw/ipc/IPC data population analysis.xlsx"
    if (!file.exists(path)) return(NULL)
    raw <- read_excel(path, sheet = 1)
    # Country-level rows have non-NA Country Population
    raw <- raw %>% filter(!is.na(`Country Population`))
    if (nrow(raw) == 0) return(NULL)
    # Extract ISO2 from first column (e.g. "AF: Acute Food Insecurity..." -> "AF")
    raw <- raw %>%
      mutate(
        iso2 = trimws(substr(`Country/Analysis Name/Area Name`, 1, 2)),
        analysis_date = as.Date(substr(`Date of Analysis`, 1, 10)),
        phase3_plus = as.numeric(`Current - Phase 3+ Pop`),
        overall_phase = as.numeric(`Current - Overall Phase`)
      )
    # ISO2 to country name (for codes present in this file)
    iso2_country <- c(
      "AF" = "Afghanistan", "AO" = "Angola", "BD" = "Bangladesh", "BF" = "Burkina Faso",
      "CF" = "Central African Republic", "TD" = "Chad", "CD" = "Democratic Republic of the Congo",
      "ET" = "Ethiopia", "HT" = "Haiti", "KE" = "Kenya", "MW" = "Malawi", "ML" = "Mali",
      "MR" = "Mauritania", "NE" = "Niger", "NG" = "Nigeria", "SO" = "Somalia", "SS" = "South Sudan",
      "SD" = "Sudan", "SY" = "Syria", "YE" = "Yemen", "ZW" = "Zimbabwe"
    )
    raw <- raw %>%
      filter(iso2 %in% names(iso2_country)) %>%
      mutate(country = unname(iso2_country[iso2])) %>%
      group_by(country) %>%
      slice_max(analysis_date, n = 1, with_ties = FALSE) %>%
      ungroup() %>%
      mutate(
        overall_phase = ifelse(is.na(overall_phase), 1, overall_phase),
        ipc_phase = as.integer(pmin(5, pmax(1, round(overall_phase)))),
        country = standardize_country_names(country)
      ) %>%
      select(country, ipc_phase, population_phase3_plus = phase3_plus)
    cat("✅ Loaded IPC population analysis for", nrow(raw), "countries\n")
    return(raw)
  }, error = function(e) {
    cat("⚠️ Error loading IPC population analysis:", e$message, "\n")
    return(NULL)
  })
}

# Load IPC historical panel: ipc all data 2017-2025.csv (subnational; aggregate to country-year).
# Returns list(latest = one row per country for merge, panel = all country-year rows for trends/export).
load_ipc_historical_data <- function() {
  cat("Loading IPC historical data (2017-2025)...\n")
  tryCatch({
    path <- "data/raw/ipc/ipc all data 2017-2025.csv"
    if (!file.exists(path)) return(list(latest = NULL, panel = NULL))
    raw <- read_csv(path, show_col_types = FALSE, col_types = cols(.default = col_character()))
    # Expected columns: Date of analysis, Country (ISO3), Phase 3+ number current, Phase 1-5 number current
    need <- c("Date of analysis", "Country", "Phase 3+ number current")
    if (!all(need %in% names(raw))) return(list(latest = NULL, panel = NULL))
    # Parse year from "Oct 2025" or "Feb 2019"
    p1 <- if ("Phase 1 number current" %in% names(raw)) as.numeric(raw[["Phase 1 number current"]]) else rep(NA_real_, nrow(raw))
    p2 <- if ("Phase 2 number current" %in% names(raw)) as.numeric(raw[["Phase 2 number current"]]) else rep(NA_real_, nrow(raw))
    p3 <- if ("Phase 3 number current" %in% names(raw)) as.numeric(raw[["Phase 3 number current"]]) else rep(NA_real_, nrow(raw))
    p4 <- if ("Phase 4 number current" %in% names(raw)) as.numeric(raw[["Phase 4 number current"]]) else rep(NA_real_, nrow(raw))
    p5 <- if ("Phase 5 number current" %in% names(raw)) as.numeric(raw[["Phase 5 number current"]]) else rep(NA_real_, nrow(raw))
    raw <- raw %>%
      mutate(
        assessment_year = as.integer(sub(".*([0-9]{4}).*", "\\1", `Date of analysis`)),
        phase3_plus = as.numeric(`Phase 3+ number current`),
        phase1 = replace_na(p1, 0), phase2 = replace_na(p2, 0), phase3 = replace_na(p3, 0),
        phase4 = replace_na(p4, 0), phase5 = replace_na(p5, 0)
      )
    raw <- raw %>%
      mutate(row_phase = case_when(phase5 > 0 ~ 5L, phase4 > 0 ~ 4L, phase3 > 0 ~ 3L, phase2 > 0 ~ 2L, TRUE ~ 1L))
    # ISO3 -> country name from hunger_data + fallback
    iso3_map <- hunger_data %>% distinct(iso3c, country) %>% filter(!is.na(iso3c))
    fb <- country_iso3_fallback()
    for (i in seq_len(nrow(fb))) {
      if (!fb$iso3c[i] %in% iso3_map$iso3c) iso3_map <- bind_rows(iso3_map, fb[i,] %>% select(iso3c, country))
    }
    # Aggregate by country (ISO3) and year
    by_cy <- raw %>%
      group_by(Country, assessment_year) %>%
      summarise(
        population_phase3_plus = sum(phase3_plus, na.rm = TRUE),
        ipc_phase = max(row_phase, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      left_join(iso3_map, by = c("Country" = "iso3c")) %>%
      filter(!is.na(country)) %>%
      select(country, assessment_year, ipc_phase, population_phase3_plus) %>%
      mutate(country = standardize_country_names(country))
    latest <- by_cy %>% group_by(country) %>% slice_max(assessment_year, n = 1, with_ties = FALSE) %>% ungroup()
    cat("✅ Loaded IPC historical: ", nrow(by_cy), " country-year rows (", nrow(latest), " countries)\n", sep = "")
    panel_norm <- normalize_trends_panel(by_cy)
    return(list(latest = latest, panel = panel_norm))
  }, error = function(e) {
    cat("⚠️ Error loading IPC historical:", e$message, "\n")
    return(list(latest = NULL, panel = NULL))
  })
}

# Load FAO FPMA (Food Price Monitoring and Analysis) — market/commodity prices
# Used for citation and optional future use; not merged into country summary.
load_fao_fpma_data <- function() {
  cat("Loading FAO FPMA data...\n")
  tryCatch({
    path <- "data/raw/fao/FAO_Data/fao fpma data.csv"
    if (!file.exists(path)) return(NULL)
    fpma <- read_csv(path, show_col_types = FALSE)
    cat("✅ Loaded FAO FPMA data (", nrow(fpma), " market-commodity records)\n")
    return(fpma)
  }, error = function(e) {
    cat("⚠️ Error loading FAO FPMA data:", e$message, "\n")
    return(NULL)
  })
}

# Load historical hunger outbreaks
load_outbreaks_data <- function() {
  cat("Loading historical hunger outbreaks...\n")
  tryCatch({
    if(file.exists("data/raw/historical_hunger_outbreaks.csv")) {
      outbreaks <- read_csv("data/raw/historical_hunger_outbreaks.csv", show_col_types = FALSE) %>%
        mutate(country = standardize_country_names(country)) %>%
        filter(outbreak_start_year >= 2000) %>%  # 21st century only
        group_by(country) %>%
        summarise(
          major_hunger_outbreak_21st = TRUE,
          latest_outbreak_year = max(outbreak_end_year, na.rm = TRUE),
          total_outbreaks = n(),
          .groups = "drop"
        )
      cat("✅ Loaded outbreak data for", nrow(outbreaks), "countries\n")
      return(outbreaks)
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading outbreaks data:", e$message, "\n")
    return(NULL)
  })
}

# Load WHO stunting data
load_who_stunting <- function() {
  cat("Loading WHO stunting data...\n")
  tryCatch({
    if(file.exists("data/raw/who/child_stunting_data.csv")) {
      stunting <- read_csv("data/raw/who/child_stunting_data.csv", show_col_types = FALSE)
      # Process WHO data - get latest stunting rate per country
      stunting_summary <- stunting %>%
        filter(!is.na(RATE_PER_100_N)) %>%
        group_by(GEO_NAME_SHORT) %>%
        slice_max(DIM_TIME, n = 1) %>%
        select(country = GEO_NAME_SHORT, stunting_rate = RATE_PER_100_N) %>%
        mutate(country = standardize_country_names(country))
      cat("✅ Loaded WHO stunting data for", nrow(stunting_summary), "countries\n")
      return(stunting_summary)
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading WHO data:", e$message, "\n")
    return(NULL)
  })
}

# Load Our World in Data poverty data
load_owid_poverty <- function() {
  cat("Loading Our World in Data poverty data...\n")
  tryCatch({
    if(file.exists("data/raw/our_world_in_data/poverty data.csv")) {
      owid_pov <- read_csv("data/raw/our_world_in_data/poverty data.csv", show_col_types = FALSE) %>%
        rename(country = Country, year = Year, poverty_below_3usd = `Share below $3 a day`) %>%
        group_by(country) %>%
        slice_max(year, n = 1) %>%
        select(country, poverty_below_3usd) %>%
        mutate(country = standardize_country_names(country))
      cat("✅ Loaded OWID poverty data for", nrow(owid_pov), "countries\n")
      return(owid_pov)
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading OWID poverty data:", e$message, "\n")
    return(NULL)
  })
}

# Load climate vulnerability: prefer data/raw/climate vulnerability/cv/vulnerability/vulnerability.csv (ISO3, Name, year cols), else Global Data Lab
load_climate_vulnerability <- function() {
  cat("Loading climate vulnerability data...\n")
  tryCatch({
    cv_path <- "data/raw/climate vulnerability/cv/vulnerability/vulnerability.csv"
    if (file.exists(cv_path)) {
      climate <- read_csv(cv_path, show_col_types = FALSE, col_types = cols(.default = col_character()))
      year_cols <- colnames(climate)[grepl("^[0-9]{4}$", colnames(climate))]
      if (length(year_cols) > 0 && "Name" %in% colnames(climate)) {
        climate_long <- climate %>%
          select(Name, all_of(year_cols)) %>%
          pivot_longer(cols = all_of(year_cols), names_to = "year", values_to = "climate_vulnerability_index") %>%
          mutate(year = as.numeric(year), climate_vulnerability_index = as.numeric(climate_vulnerability_index)) %>%
          filter(!is.na(climate_vulnerability_index)) %>%
          group_by(Name) %>%
          slice_max(year, n = 1, with_ties = FALSE) %>%
          ungroup() %>%
          select(country = Name, climate_vulnerability_index) %>%
          mutate(country = standardize_country_names(country))
        cat("✅ Loaded climate vulnerability (cv/vulnerability) for", nrow(climate_long), "countries\n")
        return(climate_long)
      }
    }
    if (file.exists("data/raw/global_data_lab/climate/climate vunerability index.csv")) {
      climate <- read_csv("data/raw/global_data_lab/climate/climate vunerability index.csv", show_col_types = FALSE)
      year_cols <- colnames(climate)[grepl("^[0-9]{4}$", colnames(climate))]
      if (length(year_cols) > 0 && "Country" %in% colnames(climate)) {
        climate_long <- climate %>%
          select(Country, all_of(year_cols)) %>%
          pivot_longer(cols = all_of(year_cols), names_to = "year", values_to = "climate_vulnerability_index") %>%
          mutate(year = as.numeric(year)) %>%
          filter(!is.na(climate_vulnerability_index)) %>%
          group_by(Country) %>%
          slice_max(year, n = 1) %>%
          ungroup() %>%
          select(country = Country, climate_vulnerability_index) %>%
          mutate(country = standardize_country_names(country))
        cat("✅ Loaded climate vulnerability (Global Data Lab) for", nrow(climate_long), "countries\n")
        return(climate_long)
      }
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading climate data:", e$message, "\n")
    return(NULL)
  })
}

# Load Global Data Lab health vulnerability
load_health_vulnerability <- function() {
  cat("Loading health vulnerability data...\n")
  tryCatch({
    if(file.exists("data/raw/global_data_lab/health/health vunerability data.csv")) {
      health <- read_csv("data/raw/global_data_lab/health/health vunerability data.csv", show_col_types = FALSE)
      # Check column names and get latest data per country
      col_names <- colnames(health)
      country_col <- col_names[grepl("country|name", col_names, ignore.case = TRUE)][1]
      year_col <- col_names[grepl("year", col_names, ignore.case = TRUE)][1]
      
      if(!is.na(country_col)) {
        health_summary <- health %>%
          rename(country = !!sym(country_col))
        
        if(!is.na(year_col)) {
          health_summary <- health_summary %>%
            rename(year = !!sym(year_col)) %>%
            group_by(country) %>%
            slice_max(year, n = 1) %>%
            ungroup()
        }
        
        health_summary <- health_summary %>%
          mutate(country = standardize_country_names(country))
        
        cat("✅ Loaded health vulnerability data for", nrow(health_summary), "countries\n")
        return(health_summary)
      }
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading health data:", e$message, "\n")
    return(NULL)
  })
}

# Load UNHCR refugee data
load_refugee_data <- function() {
  cat("Loading UNHCR refugee data...\n")
  tryCatch({
    if(file.exists("data/raw/un/unhcr/displaced people data/persons_of_concern.csv")) {
      unhcr <- read_csv("data/raw/un/unhcr/displaced people data/persons_of_concern.csv", show_col_types = FALSE)
      # UNHCR data has Country of Asylum - aggregate by country
      if("Country of Asylum" %in% colnames(unhcr) && "Year" %in% colnames(unhcr)) {
        # Column names in CSV: Refugees, Asylum-seekers, IDPs, Other people in need of international protection
        disp_cols <- c("Refugees", "Asylum-seekers", "Asylum.seekers", "IDPs",
                       "Other people in need of international protection",
                       "Other.people.in.need.of.international.protection")
        disp_cols <- intersect(disp_cols, colnames(unhcr))
        if (length(disp_cols) == 0) {
          cat("⚠️ UNHCR CSV: no displacement columns found\n")
          return(NULL)
        }
        refugee_summary <- unhcr %>%
          rename(country = "Country of Asylum", year = "Year") %>%
          mutate(
            total_displaced = rowSums(select(., any_of(disp_cols)), na.rm = TRUE)
          ) %>%
          group_by(country, year) %>%
          summarise(total_displaced = sum(total_displaced, na.rm = TRUE), .groups = "drop") %>%
          group_by(country) %>%
          slice_max(year, n = 1) %>%
          ungroup() %>%
          select(country, total_displaced_latest = total_displaced) %>%
          mutate(country = standardize_country_names(country)) %>%
          filter(total_displaced_latest > 0)
        
        cat("✅ Loaded UNHCR data for", nrow(refugee_summary), "countries\n")
        return(refugee_summary)
      }
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading UNHCR data:", e$message, "\n")
    return(NULL)
  })
}

# Load IDU (Internal Displacement Updates) data from data/raw/hdx/idu/ or data/raw/idu/
# Files named "idu country name.csv"; skip empty files; dedupe by event within file and by country across files.
load_idu_data <- function() {
  cat("Loading IDU (Internal Displacement Updates) data...\n")
  tryCatch({
    idu_dirs <- c("data/raw/hdx/idu", "data/raw/idu")
    idu_dir <- idu_dirs[dir.exists(idu_dirs)][1]
    if (is.na(idu_dir)) return(NULL)
    files <- list.files(idu_dir, pattern = "^idu .+\\.csv$", ignore.case = TRUE, full.names = TRUE)
    if (length(files) == 0) return(NULL)
    need_cols <- c("country", "figure")
    out_list <- list()
    for (f in files) {
      d <- read_csv(f, show_col_types = FALSE, col_types = cols(.default = col_character()))
      if (is.null(d) || nrow(d) < 1) next
      if (!all(need_cols %in% names(d))) next
      d <- d %>% filter(!is.na(country), trimws(as.character(country)) != "")
      if (nrow(d) == 0) next
      figure_num <- as.numeric(gsub(",", "", as.character(d$figure)))
      if (all(is.na(figure_num))) next
      d <- d %>% mutate(figure = figure_num)
      if ("event_id" %in% names(d) && "displacement_start_date" %in% names(d)) {
        d <- d %>% distinct(event_id, displacement_start_date, figure, .keep_all = TRUE)
      } else if ("id" %in% names(d)) {
        d <- d %>% distinct(id, .keep_all = TRUE)
      }
      out_list <- c(out_list, list(d %>% select(country, figure)))
    }
    if (length(out_list) == 0) return(NULL)
    idu_all <- bind_rows(out_list) %>%
      mutate(country = standardize_country_names(country)) %>%
      filter(!is.na(country)) %>%
      group_by(country) %>%
      summarise(idu_displacement_total = sum(figure, na.rm = TRUE), .groups = "drop") %>%
      filter(idu_displacement_total > 0)
    cat("✅ Loaded IDU data for", nrow(idu_all), "countries\n")
    return(idu_all)
  }, error = function(e) {
    cat("⚠️ Error loading IDU data:", e$message, "\n")
    return(NULL)
  })
}

# Load EM-DAT disaster data
load_em_dat_data <- function() {
  cat("Loading EM-DAT disaster data...\n")
  tryCatch({
    if(file.exists("data/raw/em_dat/em_dat_data.csv")) {
      em_dat <- read_csv("data/raw/em_dat/em_dat_data.csv", show_col_types = FALSE)
      
      # Process disaster data - aggregate by country
      if("country" %in% colnames(em_dat) && "year" %in% colnames(em_dat)) {
        disaster_summary <- em_dat %>%
          filter(!is.na(country)) %>%
          mutate(country = standardize_country_names(country)) %>%
          group_by(country) %>%
          summarise(
            total_disasters_5yr = sum(year >= (max(year, na.rm = TRUE) - 5), na.rm = TRUE),
            latest_disaster_year = max(year, na.rm = TRUE),
            .groups = "drop"
          ) %>%
          filter(total_disasters_5yr > 0)
        
        cat("✅ Loaded EM-DAT data for", nrow(disaster_summary), "countries\n")
        return(disaster_summary)
      }
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading EM-DAT data:", e$message, "\n")
    return(NULL)
  })
}

# Load food trade dependency data
load_trade_dependency_data <- function() {
  cat("Loading food trade dependency data...\n")
  tryCatch({
    if(file.exists("data/raw/food trade dependency/data overview.csv")) {
      trade_data <- read_csv("data/raw/food trade dependency/data overview.csv", show_col_types = FALSE)
      
      # Process trade dependency - aggregate by importer country
      if("importer_country_name" %in% colnames(trade_data)) {
        trade_summary <- trade_data %>%
          rename(country = importer_country_name) %>%
          mutate(country = standardize_country_names(country)) %>%
          group_by(country) %>%
          summarise(
            avg_import_share = mean(import_share, na.rm = TRUE),
            max_import_share = max(import_share, na.rm = TRUE),
            .groups = "drop"
          ) %>%
          filter(!is.na(avg_import_share))
        
        cat("✅ Loaded trade dependency data for", nrow(trade_summary), "countries\n")
        return(trade_summary)
      }
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading trade dependency data:", e$message, "\n")
    return(NULL)
  })
}

# Load food supply data (Our World in Data)
load_food_supply_data <- function() {
  cat("Loading food supply data...\n")
  tryCatch({
    if(file.exists("data/raw/our_world_in_data/food supply data.csv")) {
      food_supply <- read_csv("data/raw/our_world_in_data/food supply data.csv", show_col_types = FALSE)
      
      # Get latest food supply per country
      if("Entity" %in% colnames(food_supply) && "Year" %in% colnames(food_supply)) {
        # Find the column with kcal data
        kcal_col <- colnames(food_supply)[grepl("kilocalories|kcal", colnames(food_supply), ignore.case = TRUE)][1]
        
        if(!is.na(kcal_col)) {
          food_supply_summary <- food_supply %>%
            rename(country = Entity, year = Year) %>%
            rename(food_supply_kcal = !!sym(kcal_col)) %>%
            mutate(
              country = standardize_country_names(country),
              food_supply_kcal = as.numeric(food_supply_kcal)
            ) %>%
            filter(!is.na(food_supply_kcal)) %>%
            group_by(country) %>%
            slice_max(year, n = 1) %>%
            ungroup() %>%
            select(country, food_supply_kcal)
          
          cat("✅ Loaded food supply data for", nrow(food_supply_summary), "countries\n")
          return(food_supply_summary)
        }
      }
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading food supply data:", e$message, "\n")
    return(NULL)
  })
}

# Load water resources data (Our World in Data)
load_water_resources_data <- function() {
  cat("Loading water resources data...\n")
  tryCatch({
    water_data_list <- list()
    
    # Freshwater resources per capita
    if(file.exists("data/raw/our_world_in_data/freshwater resources per capita/renewable-water-resources-per-capita.csv")) {
      water_per_capita <- read_csv("data/raw/our_world_in_data/freshwater resources per capita/renewable-water-resources-per-capita.csv", show_col_types = FALSE)
      if("Entity" %in% colnames(water_per_capita) && "Year" %in% colnames(water_per_capita)) {
        water_col <- colnames(water_per_capita)[grepl("renewable|water|per.capita", colnames(water_per_capita), ignore.case = TRUE)][1]
        if(!is.na(water_col)) {
          water_data_list[["per_capita"]] <- water_per_capita %>%
            rename(country = Entity, year = Year) %>%
            rename(water_per_capita = !!sym(water_col)) %>%
            mutate(country = standardize_country_names(country)) %>%
            filter(!is.na(water_per_capita)) %>%
            group_by(country) %>%
            slice_max(year, n = 1) %>%
            ungroup() %>%
            select(country, water_per_capita)
        }
      }
    }
    
    # Agricultural water withdrawals
    if(file.exists("data/raw/our_world_in_data/agriculture water withdrawals/agricultural-water-withdrawals.csv")) {
      ag_water <- read_csv("data/raw/our_world_in_data/agriculture water withdrawals/agricultural-water-withdrawals.csv", show_col_types = FALSE)
      if("Entity" %in% colnames(ag_water) && "Year" %in% colnames(ag_water)) {
        water_col <- colnames(ag_water)[grepl("withdrawal|water", colnames(ag_water), ignore.case = TRUE)][1]
        if(!is.na(water_col)) {
          water_data_list[["ag_withdrawals"]] <- ag_water %>%
            rename(country = Entity, year = Year) %>%
            rename(ag_water_withdrawals = !!sym(water_col)) %>%
            mutate(country = standardize_country_names(country)) %>%
            filter(!is.na(ag_water_withdrawals)) %>%
            group_by(country) %>%
            slice_max(year, n = 1) %>%
            ungroup() %>%
            select(country, ag_water_withdrawals)
        }
      }
    }
    
    # Combine water data
    if(length(water_data_list) > 0) {
      water_summary <- water_data_list[[1]]
      if(length(water_data_list) > 1) {
        for(i in 2:length(water_data_list)) {
          water_summary <- water_summary %>%
            full_join(water_data_list[[i]], by = "country")
        }
      }
      cat("✅ Loaded water resources data for", nrow(water_summary), "countries\n")
      return(water_summary)
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading water resources data:", e$message, "\n")
    return(NULL)
  })
}

# Load USDA agricultural production data
load_usda_agricultural_data <- function() {
  cat("Loading USDA agricultural production data...\n")
  tryCatch({
    if(file.exists("data/raw/usda/agricultural_production_1.csv")) {
      usda_data <- read_csv("data/raw/usda/agricultural_production_1.csv", show_col_types = FALSE)
      
      # Process USDA data - look for TFP or productivity indicators
      country_col <- colnames(usda_data)[grepl("country|name|area", colnames(usda_data), ignore.case = TRUE)][1]
      
      if(!is.na(country_col)) {
        # Try to find TFP or productivity columns
        tfp_col <- colnames(usda_data)[grepl("tfp|productivity|index", colnames(usda_data), ignore.case = TRUE)][1]
        
        if(!is.na(tfp_col)) {
          usda_summary <- usda_data %>%
            rename(country = !!sym(country_col)) %>%
            rename(usda_tfp_index = !!sym(tfp_col)) %>%
            mutate(
              country = standardize_country_names(country),
              usda_tfp_index = as.numeric(usda_tfp_index)
            ) %>%
            filter(!is.na(usda_tfp_index)) %>%
            select(country, usda_tfp_index) %>%
            distinct(country, .keep_all = TRUE)
          
          cat("✅ Loaded USDA data for", nrow(usda_summary), "countries\n")
          return(usda_summary)
        }
      }
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading USDA data:", e$message, "\n")
    return(NULL)
  })
}

# Load Global Hunger Index (GHI) data for comparison
# Excel layout: row 1 = title (merged), row 2 = header (Rank1, Country, 2000, 2008, 2016, 2025), row 3 = footnote text + first country (Armenia), then one row per country. Column A = rank/notes, B = country, C–F = year scores.
load_ghi_data <- function() {
  cat("Loading Global Hunger Index (GHI) data...\n")
  tryCatch({
    ghi_path <- "data/raw/global hunger index/2025 csv.xlsx"
    if (!file.exists(ghi_path)) {
      alt <- file.path(getwd(), "data/raw/global hunger index/2025 csv.xlsx")
      if (file.exists(alt)) ghi_path <- alt
    }
    if (!file.exists(ghi_path)) {
      cat("⚠️ GHI file not found:", ghi_path, "\n")
      return(NULL)
    }
    if (!requireNamespace("readxl", quietly = TRUE)) {
      cat("⚠️ readxl package not available for GHI data\n")
      return(NULL)
    }
    library(readxl)
    # Skip 3 rows: title, header, and footnote row so first row read is a real country (e.g. Armenia or Belarus)
    ghi_data <- read_excel(ghi_path, sheet = 1, skip = 3, col_names = FALSE)
    if (is.null(ghi_data) || ncol(ghi_data) < 6) {
      cat("⚠️ GHI file has unexpected structure\n")
      return(NULL)
    }
    # Column 2 = country name, column 6 = 2025 score (by position to avoid header/merged-cell issues)
    ghi_data <- ghi_data %>%
      rename(country = ...2, ghi_raw = ...6) %>%
      filter(!is.na(country), nzchar(trimws(as.character(country))),
             !grepl("^Rank|^Country$|collectively|GHI scores less", tolower(trimws(as.character(country)))))
    ghi_data <- ghi_data %>%
      mutate(
        ghi_score = suppressWarnings(as.numeric(ghi_raw)),
        ghi_score = case_when(
          !is.na(ghi_score) ~ ghi_score,
          grepl("<\\s*5", as.character(ghi_raw), ignore.case = TRUE) ~ 5,
          TRUE ~ NA_real_
        )
      ) %>%
      filter(!is.na(ghi_score)) %>%
      mutate(country = standardize_country_names(country)) %>%
      select(country, ghi_score) %>%
      distinct(country, .keep_all = TRUE)
    if (nrow(ghi_data) == 0) {
      cat("⚠️ No valid GHI scores found after parsing\n")
      return(NULL)
    }
    cat("✅ Loaded GHI data for", nrow(ghi_data), "countries\n")
    return(ghi_data)
  }, error = function(e) {
    cat("⚠️ Error loading GHI data:", e$message, "\n")
    return(NULL)
  })
}

# Load ACLED conflict data (simplified - process key files)
load_acled_conflict_data <- function() {
  cat("Loading ACLED conflict data...\n")
  tryCatch({
    conflict_data_list <- list()
    
    # Try to load fatalities per country (most important)
    if(file.exists("data/raw/acled - conflict data/fatalities per country.xlsx")) {
      if(requireNamespace("readxl", quietly = TRUE)) {
        library(readxl)
        fatalities <- read_excel("data/raw/acled - conflict data/fatalities per country.xlsx")
        
        # Find country and fatality columns
        country_col <- colnames(fatalities)[grepl("country|name", colnames(fatalities), ignore.case = TRUE)][1]
        fatality_col <- colnames(fatalities)[grepl("fatalit|death|killed", colnames(fatalities), ignore.case = TRUE)][1]
        
        if(!is.na(country_col) && !is.na(fatality_col)) {
          conflict_data_list[["fatalities"]] <- fatalities %>%
            rename(country = !!sym(country_col), total_fatalities = !!sym(fatality_col)) %>%
            mutate(
              country = standardize_country_names(country),
              total_fatalities = as.numeric(total_fatalities)
            ) %>%
            filter(!is.na(total_fatalities) & total_fatalities > 0) %>%
            group_by(country) %>%
            summarise(total_fatalities = sum(total_fatalities, na.rm = TRUE), .groups = "drop")
        }
      }
    }
    
    # Combine conflict data
    if(length(conflict_data_list) > 0) {
      conflict_summary <- conflict_data_list[[1]]
      if(length(conflict_data_list) > 1) {
        for(i in 2:length(conflict_data_list)) {
          conflict_summary <- conflict_summary %>%
            full_join(conflict_data_list[[i]], by = "country")
        }
      }
      
      # Create conflict indicator
      conflict_summary <- conflict_summary %>%
        mutate(
          has_active_conflict = !is.na(total_fatalities) & total_fatalities > 0,
          conflict_intensity = case_when(
            !is.na(total_fatalities) & total_fatalities >= 10000 ~ "Very High",
            !is.na(total_fatalities) & total_fatalities >= 1000 ~ "High",
            !is.na(total_fatalities) & total_fatalities >= 100 ~ "Medium",
            !is.na(total_fatalities) & total_fatalities > 0 ~ "Low",
            TRUE ~ "None"
          )
        )
      
      cat("✅ Loaded ACLED conflict data for", nrow(conflict_summary), "countries\n")
      return(conflict_summary)
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading ACLED conflict data:", e$message, "\n")
    return(NULL)
  })
}

# Load WPR malnutrition data
load_wpr_malnutrition_data <- function() {
  cat("Loading WPR malnutrition data...\n")
  tryCatch({
    if(file.exists("data/raw/wpr/malnutrition-rate-by-country-2025.csv")) {
      wpr_data <- read_csv("data/raw/wpr/malnutrition-rate-by-country-2025.csv", show_col_types = FALSE)
      
      # Process WPR data
      country_col <- colnames(wpr_data)[grepl("country|name|entity", colnames(wpr_data), ignore.case = TRUE)][1]
      rate_col <- colnames(wpr_data)[grepl("rate|malnutrition|prevalence", colnames(wpr_data), ignore.case = TRUE)][1]
      
      if(!is.na(country_col) && !is.na(rate_col)) {
        wpr_summary <- wpr_data %>%
          rename(country = !!sym(country_col), wpr_malnutrition_rate = !!sym(rate_col)) %>%
          mutate(
            country = standardize_country_names(country),
            wpr_malnutrition_rate = as.numeric(wpr_malnutrition_rate)
          ) %>%
          filter(!is.na(wpr_malnutrition_rate)) %>%
          select(country, wpr_malnutrition_rate) %>%
          distinct(country, .keep_all = TRUE)
        
        cat("✅ Loaded WPR malnutrition data for", nrow(wpr_summary), "countries\n")
        return(wpr_summary)
      }
    }
    return(NULL)
  }, error = function(e) {
    cat("⚠️ Error loading WPR malnutrition data:", e$message, "\n")
    return(NULL)
  })
}

# Load all additional data sources
fao_data <- load_fao_data()
fao_timeseries <- load_fao_timeseries()  # Time series for trend charts
wfp_result <- load_wfp_data()
wfp_data <- wfp_result$latest
grfc_panel <- wfp_result$panel
outbreaks_data <- load_outbreaks_data()
who_stunting <- load_who_stunting()
owid_poverty <- load_owid_poverty()
climate_data <- load_climate_vulnerability()
health_data <- load_health_vulnerability()
refugee_data <- load_refugee_data()
idu_data <- load_idu_data()

# Load NEW data sources
em_dat_data <- load_em_dat_data()
trade_dependency_data <- load_trade_dependency_data()
food_supply_data <- load_food_supply_data()
water_resources_data <- load_water_resources_data()
usda_agricultural_data <- load_usda_agricultural_data()
ghi_data <- load_ghi_data()
acled_conflict_data <- load_acled_conflict_data()
wpr_malnutrition_data <- load_wpr_malnutrition_data()
ipc_data <- load_ipc_data()
ipc_population_data <- load_ipc_population_data()
ipc_historical_result <- load_ipc_historical_data()
ipc_panel <- ipc_historical_result$panel
fao_fpma_data <- load_fao_fpma_data()

cat("✅ All data sources loaded!\n")

# Filter out regions and aggregates (keep only actual countries with ISO codes)
# Exclude World Bank aggregate categories and regions
hunger_data <- hunger_data %>%
  filter(!is.na(iso3c)) %>%
  # Exclude World Bank income/region aggregates
  filter(!grepl("IDA & IBRD", country, ignore.case = TRUE)) %>%
  filter(!grepl("Low & middle income", country, ignore.case = TRUE)) %>%
  filter(!grepl("Middle income", country, ignore.case = TRUE)) %>%
  filter(!grepl("High income", country, ignore.case = TRUE)) %>%
  filter(!grepl("IBRD only", country, ignore.case = TRUE)) %>%
  filter(!grepl("IDA only", country, ignore.case = TRUE)) %>%
  filter(!grepl("IDA total", country, ignore.case = TRUE)) %>%
  filter(!grepl("Early-demographic", country, ignore.case = TRUE)) %>%
  filter(!grepl("Late-demographic", country, ignore.case = TRUE)) %>%
  filter(!grepl("^Africa", country, ignore.case = TRUE)) %>%
  filter(!grepl("^Arab", country, ignore.case = TRUE)) %>%
  filter(!grepl("^East Asia", country, ignore.case = TRUE)) %>%
  filter(!grepl("^Europe", country, ignore.case = TRUE)) %>%
  filter(!grepl("^Latin America", country, ignore.case = TRUE)) %>%
  filter(!grepl("^Middle East", country, ignore.case = TRUE)) %>%
  filter(!grepl("^North America", country, ignore.case = TRUE)) %>%
  filter(!grepl("^South Asia", country, ignore.case = TRUE)) %>%
  filter(!grepl("^Sub-Saharan", country, ignore.case = TRUE)) %>%
  filter(!grepl("^World", country, ignore.case = TRUE)) %>%
  filter(!grepl("^Euro", country, ignore.case = TRUE)) %>%
  filter(!grepl("^Pacific", country, ignore.case = TRUE)) %>%
  filter(country != "Central Europe and the Baltics") %>%
  filter(country != "Caribbean small states") %>%
  filter(country != "East Asia & Pacific (excluding high income)") %>%
  filter(country != "East Asia & Pacific (IDA & IBRD countries)") %>%
  filter(country != "Europe & Central Asia (excluding high income)") %>%
  filter(country != "Europe & Central Asia (IDA & IBRD countries)") %>%
  filter(country != "Latin America & Caribbean (excluding high income)") %>%
  filter(country != "Latin America & Caribbean (IDA & IBRD countries)") %>%
  filter(country != "Middle East & North Africa (excluding high income)") %>%
  filter(country != "Middle East & North Africa (IDA & IBRD countries)") %>%
  filter(country != "North America") %>%
  filter(country != "OECD members") %>%
  filter(country != "Other small states") %>%
  filter(country != "Pacific island small states") %>%
  filter(country != "Small island developing states") %>%
  filter(country != "South Asia (IDA & IBRD)") %>%
  filter(country != "Sub-Saharan Africa (excluding high income)") %>%
  filter(country != "Sub-Saharan Africa (IDA & IBRD countries)") %>%
  filter(!grepl("IDA blend", country, ignore.case = TRUE)) %>%
  filter(!grepl("Fragile and conflict affected", country, ignore.case = TRUE)) %>%
  filter(!grepl("Pre-demographic dividend", country, ignore.case = TRUE)) %>%
  filter(!grepl("Post-demographic dividend", country, ignore.case = TRUE)) %>%
  filter(!grepl("UN classification", country, ignore.case = TRUE))

# Standardize country names and drop invalid/test entries (e.g. ".9237466833915", Barb994.64806074889)
hunger_data <- hunger_data %>%
  mutate(country = standardize_country_names(country)) %>%
  filter(!grepl("^[0-9.]+$", country)) %>%
  filter(!grepl("^[A-Za-z]+[0-9.]+$", trimws(as.character(country)))) %>%  # drop corrupted text+number country names
  # One row per ISO3 per year (raw WDI can contain duplicate country labels for the same code)
  group_by(iso3c, year) %>%
  slice_max(order_by = SP.POP.TOTL, n = 1, with_ties = FALSE) %>%
  ungroup()

# Create summary data for latest year (one row per standardized country)
hunger_summary_from_wb <- hunger_data %>%
  group_by(country) %>%
  summarise(
    latest_year = max(year, na.rm = TRUE),
    population = last(SP.POP.TOTL, order_by = year),
    gdp = last(NY.GDP.MKTP.CD, order_by = year),
    gdp_per_capita = last(NY.GDP.PCAP.CD, order_by = year),
    inflation = last(FP.CPI.TOTL.ZG, order_by = year),
    poverty = last(SI.POV.DDAY, order_by = year),
    agriculture_land = last(AG.LND.AGRI.ZS, order_by = year),
    crop_production = last(AG.PRD.CROP.XD, order_by = year),
    rural_pop = last(SP.RUR.TOTL.ZS, order_by = year),
    life_expectancy = last(SP.DYN.LE00.IN, order_by = year),
    infant_mortality = last(SP.DYN.IMRT.IN, order_by = year),
    literacy = last(SE.ADT.LITR.ZS, order_by = year),
    land_area_km2 = if ("AG.LND.TOTL.K2" %in% names(hunger_data)) last(AG.LND.TOTL.K2, order_by = year) else NA_real_,
    iso3c = first(iso3c),
    region = first(region),
    .groups = "drop"
  )

# Country backbone: all WB countries with iso3c, plus Pacific/other from fallback, plus any country only in FAO/OWID
wb_countries <- hunger_summary_from_wb %>%
  filter(!is.na(iso3c)) %>%
  select(country, iso3c)
fallback_iso <- country_iso3_fallback() %>%
  filter(!(country %in% wb_countries$country))
extra_from_sources <- tibble(country = character(0L))
if(!is.null(fao_data) && nrow(fao_data) > 0) extra_from_sources <- bind_rows(extra_from_sources, fao_data %>% distinct(country))
if(!is.null(owid_poverty) && nrow(owid_poverty) > 0) extra_from_sources <- bind_rows(extra_from_sources, owid_poverty %>% distinct(country))
extra_from_sources <- extra_from_sources %>%
  distinct(country) %>%
  filter(!(country %in% wb_countries$country)) %>%
  left_join(country_iso3_fallback(), by = "country") %>%
  filter(!is.na(iso3c)) %>%
  select(country, iso3c)
country_backbone <- bind_rows(
  wb_countries,
  fallback_iso,
  extra_from_sources
) %>%
  distinct(country, .keep_all = TRUE)

# Start latest_summary from backbone so every country (including Pacific islands) has a row
latest_summary <- country_backbone %>%
  left_join(hunger_summary_from_wb %>% select(-iso3c), by = "country")

if (file.exists("data/raw/land_area_km2.csv")) {
  land_area_lookup <- readr::read_csv("data/raw/land_area_km2.csv", show_col_types = FALSE) %>%
    dplyr::filter(!is.na(iso3c) & nchar(trimws(iso3c)) == 3) %>%
    dplyr::distinct(iso3c, .keep_all = TRUE)
  if (nrow(land_area_lookup) > 0) {
    latest_summary <- latest_summary %>%
      dplyr::left_join(land_area_lookup, by = "iso3c", relationship = "many-to-one")
    if ("land_area_km2.x" %in% names(latest_summary)) {
      latest_summary <- latest_summary %>%
        dplyr::mutate(land_area_km2 = dplyr::coalesce(land_area_km2.x, land_area_km2.y)) %>%
        dplyr::select(-land_area_km2.x, -land_area_km2.y)
    }
  }
}

# Merge all additional data sources - ensure one row per country
# Map each source's country names to backbone (fuzzy match fallback) before joining
backbone_countries <- unique(latest_summary$country)
if(!is.null(fao_data)) {
  fao_data_unique <- fao_data %>%
    group_by(country) %>%
    slice_max(year, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(country, undernourishment_rate, fao_latest_year = year, any_of("undernourishment_interval_censored")) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(fao_data_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$undernourishment_rate <- NA_real_
  latest_summary$fao_latest_year <- NA_real_
  latest_summary$undernourishment_interval_censored <- NA
}

# Any non-positive PoU is not a valid prevalence for plotting (FAO uses "<2.5" for low values; zeros are artifacts)
if ("undernourishment_rate" %in% names(latest_summary)) {
  latest_summary <- latest_summary %>%
    mutate(undernourishment_rate = if_else(!is.na(undernourishment_rate) & undernourishment_rate <= 0, NA_real_, undernourishment_rate))
}

if(!is.null(wfp_data)) {
  wfp_data_unique <- wfp_data %>%
    group_by(country) %>%
    slice_max(assessment_year, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(country, grfc_ipc_phase = ipc_phase, 
           grfc_population_phase3_plus = population_phase3_plus,
           grfc_latest_year = assessment_year) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(wfp_data_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$grfc_ipc_phase <- NA_real_
  latest_summary$grfc_population_phase3_plus <- NA_real_
  latest_summary$grfc_latest_year <- NA_real_
}
# Supplement with IPC/CH data where WFP GRFC is missing (general CSV first, then population analysis xlsx)
if(!is.null(ipc_data)) {
  ipc_mapped <- ipc_data %>%
    select(country, ipc_phase, population_phase3_plus) %>%
    map_data_countries_to_backbone(backbone_countries) %>%
    rename(grfc_ipc_phase_ipc = ipc_phase, grfc_population_phase3_plus_ipc = population_phase3_plus)
  latest_summary <- latest_summary %>%
    left_join(ipc_mapped, by = "country", relationship = "one-to-one") %>%
    mutate(
      grfc_ipc_phase = coalesce(as.numeric(as.character(grfc_ipc_phase)), as.numeric(grfc_ipc_phase_ipc)),
      grfc_population_phase3_plus = coalesce(as.numeric(as.character(grfc_population_phase3_plus)), as.numeric(grfc_population_phase3_plus_ipc))
    ) %>%
    select(-grfc_ipc_phase_ipc, -grfc_population_phase3_plus_ipc)
}
if(!is.null(ipc_population_data)) {
  ipc_pop_mapped <- ipc_population_data %>%
    select(country, ipc_phase, population_phase3_plus) %>%
    map_data_countries_to_backbone(backbone_countries) %>%
    rename(grfc_ipc_phase_pop = ipc_phase, grfc_population_phase3_plus_pop = population_phase3_plus)
  latest_summary <- latest_summary %>%
    left_join(ipc_pop_mapped, by = "country", relationship = "one-to-one") %>%
    mutate(
      grfc_ipc_phase = coalesce(as.numeric(as.character(grfc_ipc_phase)), as.numeric(grfc_ipc_phase_pop)),
      grfc_population_phase3_plus = coalesce(as.numeric(as.character(grfc_population_phase3_plus)), as.numeric(grfc_population_phase3_plus_pop))
    ) %>%
    select(-grfc_ipc_phase_pop, -grfc_population_phase3_plus_pop)
}
if (!is.null(ipc_historical_result$latest)) {
  ipc_hist_mapped <- ipc_historical_result$latest %>%
    select(country, ipc_phase, population_phase3_plus, assessment_year) %>%
    map_data_countries_to_backbone(backbone_countries) %>%
    rename(grfc_ipc_phase_hist = ipc_phase, grfc_population_phase3_plus_hist = population_phase3_plus, ipc_latest_year = assessment_year)
  latest_summary <- latest_summary %>%
    left_join(ipc_hist_mapped, by = "country", relationship = "one-to-one") %>%
    mutate(
      grfc_ipc_phase = coalesce(as.numeric(as.character(grfc_ipc_phase)), as.numeric(grfc_ipc_phase_hist)),
      grfc_population_phase3_plus = coalesce(as.numeric(as.character(grfc_population_phase3_plus)), as.numeric(grfc_population_phase3_plus_hist))
    ) %>%
    select(-grfc_ipc_phase_hist, -grfc_population_phase3_plus_hist)
} else {
  latest_summary$ipc_latest_year <- NA_real_
}

if(!is.null(outbreaks_data)) {
  outbreaks_mapped <- map_data_countries_to_backbone(outbreaks_data, backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(outbreaks_mapped, by = "country", relationship = "one-to-one")
} else {
  latest_summary$major_hunger_outbreak_21st <- FALSE
  latest_summary$latest_outbreak_year <- NA_real_
  latest_summary$total_outbreaks <- 0
}

if(!is.null(who_stunting)) {
  who_stunting_unique <- who_stunting %>%
    group_by(country) %>%
    slice(1) %>%
    ungroup() %>%
    select(country, stunting_rate) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(who_stunting_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$stunting_rate <- NA_real_
}

if(!is.null(owid_poverty)) {
  owid_mapped <- map_data_countries_to_backbone(owid_poverty, backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(owid_mapped, by = "country", relationship = "one-to-one")
} else {
  latest_summary$poverty_below_3usd <- NA_real_
}

if(!is.null(climate_data)) {
  climate_data_unique <- climate_data %>%
    group_by(country) %>%
    slice(1) %>%
    ungroup() %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(climate_data_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$climate_vulnerability_index <- NA_real_
}

if(!is.null(health_data)) {
  health_data_unique <- health_data %>%
    group_by(country) %>%
    slice(1) %>%  # Take first row per country
    ungroup()
  # Only join if it doesn't create duplicates - we'll add specific columns we need
  # For now, skip health_data join to avoid duplicates
}

if(!is.null(refugee_data)) {
  refugee_data_unique <- refugee_data %>%
    group_by(country) %>%
    slice(1) %>%
    ungroup() %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(refugee_data_unique, by = "country", relationship = "one-to-one")
  latest_summary$unhcr_metric_scope <- "UNHCR persons of concern total (country of asylum / host state; not origin country)"
} else {
  latest_summary$total_displaced_latest <- NA_real_
  latest_summary$unhcr_metric_scope <- NA_character_
}

if(!is.null(idu_data)) {
  idu_mapped <- idu_data %>%
    map_data_countries_to_backbone(backbone_countries) %>%
    select(country, idu_displacement_total)
  latest_summary <- latest_summary %>%
    left_join(idu_mapped, by = "country", relationship = "one-to-one")
} else {
  latest_summary$idu_displacement_total <- NA_real_
}

# Join NEW data sources
if(!is.null(em_dat_data)) {
  em_dat_unique <- em_dat_data %>%
    distinct(country, .keep_all = TRUE) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(em_dat_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$total_disasters_5yr <- NA_real_
  latest_summary$latest_disaster_year <- NA_real_
}

if(!is.null(trade_dependency_data)) {
  trade_unique <- trade_dependency_data %>%
    distinct(country, .keep_all = TRUE) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(trade_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$avg_import_share <- NA_real_
  latest_summary$max_import_share <- NA_real_
}

if(!is.null(food_supply_data)) {
  food_supply_unique <- food_supply_data %>%
    distinct(country, .keep_all = TRUE) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(food_supply_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$food_supply_kcal <- NA_real_
}

if(!is.null(water_resources_data)) {
  water_unique <- water_resources_data %>%
    distinct(country, .keep_all = TRUE) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(water_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$water_per_capita <- NA_real_
  latest_summary$ag_water_withdrawals <- NA_real_
}

if(!is.null(usda_agricultural_data)) {
  usda_unique <- usda_agricultural_data %>%
    distinct(country, .keep_all = TRUE) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(usda_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$usda_tfp_index <- NA_real_
}

if(!is.null(ghi_data)) {
  ghi_unique <- ghi_data %>%
    distinct(country, .keep_all = TRUE) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(ghi_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$ghi_score <- NA_real_
}

if(!is.null(acled_conflict_data)) {
  acled_unique <- acled_conflict_data %>%
    distinct(country, .keep_all = TRUE) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(acled_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$has_active_conflict <- FALSE
  latest_summary$total_fatalities <- NA_real_
  latest_summary$conflict_intensity <- "None"
}

if(!is.null(wpr_malnutrition_data)) {
  wpr_unique <- wpr_malnutrition_data %>%
    distinct(country, .keep_all = TRUE) %>%
    map_data_countries_to_backbone(backbone_countries)
  latest_summary <- latest_summary %>%
    left_join(wpr_unique, by = "country", relationship = "one-to-one")
} else {
  latest_summary$wpr_malnutrition_rate <- NA_real_
}

# Latest data year = max across WB, FAO, GRFC, IPC, disasters (so Country Details shows newest data)
if (!"fao_latest_year" %in% names(latest_summary)) latest_summary$fao_latest_year <- NA_real_
if (!"grfc_latest_year" %in% names(latest_summary)) latest_summary$grfc_latest_year <- NA_real_
if (!"ipc_latest_year" %in% names(latest_summary)) latest_summary$ipc_latest_year <- NA_real_
if (!"latest_disaster_year" %in% names(latest_summary)) latest_summary$latest_disaster_year <- NA_real_
latest_summary <- latest_summary %>%
  mutate(
    coverage_wfp_grfc = !is.na(grfc_latest_year),
    coverage_ipc_historical = !is.na(ipc_latest_year),
    latest_year = as.integer(pmax(
      as.numeric(latest_year),
      as.numeric(fao_latest_year),
      as.numeric(grfc_latest_year),
      as.numeric(ipc_latest_year),
      as.numeric(latest_disaster_year),
      na.rm = TRUE
    ))
  ) %>%
  select(-any_of(c("fao_latest_year", "grfc_latest_year", "ipc_latest_year")))

# Optional: report merge coverage (how many countries have key indicators)
if (interactive()) {
  n <- nrow(latest_summary)
  n_und <- sum(!is.na(latest_summary$undernourishment_rate))
  n_pov <- sum(!is.na(latest_summary$poverty_display))
  n_ghi <- sum(!is.na(latest_summary$ghi_score))
  n_disp <- sum(!is.na(latest_summary$total_displaced_latest))
  cat("Merge coverage:", n, "countries; undernourishment:", n_und, "| poverty:", n_pov, "| GHI:", n_ghi, "| displaced:", n_disp, "\n")
}

# Remove any duplicate rows and invalid/test entries; exclude WB aggregate/classification "countries"
latest_summary <- latest_summary %>%
  distinct(country, .keep_all = TRUE) %>%
  filter(!is.na(iso3c)) %>%
  filter(!grepl("^[0-9.]+$", country)) %>%
  filter(!grepl("IDA blend", country, ignore.case = TRUE)) %>%
  filter(!grepl("Fragile and conflict affected", country, ignore.case = TRUE)) %>%
  filter(!grepl("Pre-demographic dividend", country, ignore.case = TRUE)) %>%
  filter(!grepl("Post-demographic dividend", country, ignore.case = TRUE)) %>%
  filter(!grepl("UN classification", country, ignore.case = TRUE))

# Best available poverty for display (World Bank $1.90/day or OWID $3/day)
latest_summary <- latest_summary %>%
  mutate(poverty_display = coalesce(poverty, poverty_below_3usd))

# Score component columns (weighted sum = default 0–100 index). Used by map + scenario lab.
HUNGER_SCORE_COMPONENT_COLS <- c(
  "undernourishment_score", "poverty_score", "gdp_score", "life_expectancy_score",
  "stunting_score", "climate_score", "conflict_score", "outbreak_score",
  "trade_dependency_score", "food_supply_score", "water_stress_score", "displacement_score"
)

# Shared logic: raw indicator columns in `d` → component scores + capped total (same as dashboard formula).
add_vulnerability_score_breakdown <- function(d) {
  dplyr::mutate(
    d,
    undernourishment_score = case_when(
      !is.na(undernourishment_rate) ~ pmin(undernourishment_rate * 0.25, 25),
      !is.na(poverty) ~ pmin(poverty * 0.25, 25),
      TRUE ~ 0
    ),
    poverty_score = case_when(
      !is.na(poverty) ~ pmin(poverty * 0.16, 8),
      !is.na(poverty_below_3usd) ~ pmin(poverty_below_3usd * 0.16, 8),
      TRUE ~ 0
    ),
    gdp_score = case_when(
      is.na(gdp_per_capita) ~ 0,
      gdp_per_capita < 1000 ~ 7,
      gdp_per_capita < 3000 ~ 5,
      gdp_per_capita < 10000 ~ 3,
      gdp_per_capita < 20000 ~ 1,
      TRUE ~ 0
    ),
    life_expectancy_score = case_when(
      is.na(life_expectancy) ~ 0,
      life_expectancy < 50 ~ 5,
      life_expectancy < 60 ~ 4,
      life_expectancy < 70 ~ 2,
      TRUE ~ 0
    ),
    stunting_score = case_when(
      !is.na(stunting_rate) ~ pmin(stunting_rate * 0.05, 5),
      TRUE ~ 0
    ),
    climate_score = case_when(
      !is.na(climate_vulnerability_index) & climate_vulnerability_index >= 80 ~ 10,
      !is.na(climate_vulnerability_index) & climate_vulnerability_index >= 70 ~ 7,
      !is.na(climate_vulnerability_index) & climate_vulnerability_index >= 60 ~ 3,
      TRUE ~ 0
    ),
    conflict_score = case_when(
      !is.na(has_active_conflict) & has_active_conflict & conflict_intensity == "Very High" ~ 10,
      !is.na(has_active_conflict) & has_active_conflict & conflict_intensity == "High" ~ 7,
      !is.na(has_active_conflict) & has_active_conflict & conflict_intensity == "Medium" ~ 4,
      !is.na(has_active_conflict) & has_active_conflict & conflict_intensity == "Low" ~ 2,
      TRUE ~ 0
    ),
    outbreak_score = case_when(
      !is.na(major_hunger_outbreak_21st) & major_hunger_outbreak_21st ~ 15,
      !is.na(grfc_ipc_phase) & grfc_ipc_phase >= 4 ~ 15,
      !is.na(grfc_ipc_phase) & grfc_ipc_phase == 3 ~ 8,
      TRUE ~ 0
    ),
    trade_dependency_score = case_when(
      !is.na(avg_import_share) & avg_import_share >= 0.5 ~ 5,
      !is.na(avg_import_share) & avg_import_share >= 0.3 ~ 4,
      !is.na(avg_import_share) & avg_import_share >= 0.2 ~ 2,
      !is.na(avg_import_share) & avg_import_share > 0 ~ 1,
      TRUE ~ 0
    ),
    food_supply_score = case_when(
      is.na(food_supply_kcal) ~ 0,
      food_supply_kcal < 2000 ~ 5,
      food_supply_kcal < 2200 ~ 3,
      food_supply_kcal < 2400 ~ 1,
      TRUE ~ 0
    ),
    water_stress_score = case_when(
      is.na(water_per_capita) ~ 0,
      water_per_capita < 500 ~ 5,
      water_per_capita < 1000 ~ 3,
      water_per_capita < 1700 ~ 1,
      TRUE ~ 0
    ),
    displacement_score = case_when(
      is.na(total_displaced_latest) | total_displaced_latest <= 0 ~ 0,
      !is.na(population) & population > 0 & (total_displaced_latest / population) >= 0.10 ~ 5,
      !is.na(population) & population > 0 & (total_displaced_latest / population) >= 0.05 ~ 4,
      !is.na(population) & population > 0 & (total_displaced_latest / population) >= 0.01 ~ 3,
      !is.na(population) & population > 0 & (total_displaced_latest / population) >= 0.001 ~ 1,
      total_displaced_latest >= 1e6 ~ 4,
      total_displaced_latest >= 5e5 ~ 3,
      total_displaced_latest >= 1e5 ~ 1,
      TRUE ~ 0
    ),
    hunger_vulnerability_rating = round(
      pmax(
        0,
        pmin(
          100,
          undernourishment_score + poverty_score + gdp_score +
            life_expectancy_score + stunting_score + climate_score +
            conflict_score + outbreak_score +
            trade_dependency_score + food_supply_score + water_stress_score +
            displacement_score
        )
      ),
      1
    )
  )
}

latest_summary <- add_vulnerability_score_breakdown(latest_summary)
hunger_score_components <- latest_summary %>%
  select(country, iso3c, dplyr::all_of(HUNGER_SCORE_COMPONENT_COLS))
latest_summary <- latest_summary %>%
  dplyr::select(-dplyr::all_of(HUNGER_SCORE_COMPONENT_COLS))

MAP_FORMULA_WEIGHT_IDS <- c(
  "map_w_undernourishment", "map_w_poverty", "map_w_gdp", "map_w_life_expectancy",
  "map_w_stunting", "map_w_climate", "map_w_conflict", "map_w_outbreak",
  "map_w_trade", "map_w_food_supply", "map_w_water", "map_w_displacement"
)

map_hover_weighted_pts <- function(score, weight) {
  s <- suppressWarnings(as.numeric(score))
  w <- suppressWarnings(as.numeric(weight))
  if (!is.finite(s)) s <- 0
  if (!is.finite(w)) w <- 1
  sprintf("%.1f pts", s * w)
}

build_map_formula_hover_body <- function(row, weights) {
  row_val <- function(nm, default = NA) {
    if (!nm %in% names(row)) return(default)
    row[[nm]]
  }
  scores <- vapply(HUNGER_SCORE_COMPONENT_COLS, function(nm) {
    v <- suppressWarnings(as.numeric(row_val(nm, 0)))
    if (!is.finite(v)) 0 else v
  }, numeric(1))
  w <- weights
  if (length(w) != length(scores)) w <- rep(1, length(scores))

  unr <- suppressWarnings(as.numeric(row_val("undernourishment_rate")))
  unr_show <- if (is.finite(unr)) {
    sprintf("%.1f%%", unr)
  } else {
    pov <- suppressWarnings(as.numeric(row_val("poverty")))
    if (is.finite(pov)) sprintf("%.1f%% (poverty proxy)", pov) else "No data"
  }

  poverty <- suppressWarnings(as.numeric(row_val("poverty_display")))
  poverty_show <- if (is.finite(poverty)) sprintf("%.1f%%", poverty) else "No data"

  gdp <- suppressWarnings(as.numeric(row_val("gdp_per_capita")))
  gdp_show <- if (is.finite(gdp)) {
    paste0("$", format(round(gdp, 0), big.mark = ",", trim = TRUE, scientific = FALSE))
  } else "No data"

  life <- suppressWarnings(as.numeric(row_val("life_expectancy")))
  life_show <- if (is.finite(life)) sprintf("%.1f yrs", life) else "No data"

  stunt <- suppressWarnings(as.numeric(row_val("stunting_rate")))
  stunt_show <- if (is.finite(stunt)) sprintf("%.1f%%", stunt) else "No data"

  clim <- suppressWarnings(as.numeric(row_val("climate_vulnerability_index")))
  clim_show <- if (is.finite(clim)) sprintf("%.0f", clim) else "No data"

  conflict_show <- if (isTRUE(row_val("has_active_conflict"))) {
    ci <- row_val("conflict_intensity")
    if (!is.null(ci) && !is.na(ci) && nzchar(as.character(ci)) && ci != "None") as.character(ci) else "Active"
  } else "None"

  outbreak_show <- if (isTRUE(row_val("major_hunger_outbreak_21st"))) {
    "Major outbreak"
  } else {
    ipc <- suppressWarnings(as.numeric(row_val("grfc_ipc_phase")))
    if (is.finite(ipc) && ipc >= 1) sprintf("IPC phase %.0f", ipc) else "None"
  }

  trade <- suppressWarnings(as.numeric(row_val("avg_import_share")))
  trade_show <- if (is.finite(trade)) sprintf("%.0f%% food imports", trade * 100) else "No data"

  food <- suppressWarnings(as.numeric(row_val("food_supply_kcal")))
  food_show <- if (is.finite(food)) sprintf("%.0f kcal/day", food) else "No data"

  water <- suppressWarnings(as.numeric(row_val("water_per_capita")))
  water_show <- if (is.finite(water)) sprintf("%.0f m³/cap", water) else "No data"

  displaced <- suppressWarnings(as.numeric(row_val("total_displaced_latest")))
  pop <- suppressWarnings(as.numeric(row_val("population")))
  disp_show <- if (is.finite(displaced) && displaced > 0 && is.finite(pop) && pop > 0) {
    sprintf("%.2f%% of population", 100 * displaced / pop)
  } else if (is.finite(displaced) && displaced > 0) {
    sprintf("%s people", format(round(displaced), big.mark = ",", trim = TRUE, scientific = FALSE))
  } else "No data"

  paste(
    sprintf("<b>Undernourishment:</b> %s · %s", unr_show, map_hover_weighted_pts(scores[1], w[1])),
    sprintf("<b>Poverty:</b> %s · %s", poverty_show, map_hover_weighted_pts(scores[2], w[2])),
    sprintf("<b>Income (GDP/cap):</b> %s · %s", gdp_show, map_hover_weighted_pts(scores[3], w[3])),
    sprintf("<b>Life expectancy:</b> %s · %s", life_show, map_hover_weighted_pts(scores[4], w[4])),
    sprintf("<b>Child stunting:</b> %s · %s", stunt_show, map_hover_weighted_pts(scores[5], w[5])),
    sprintf("<b>Climate vulnerability:</b> %s · %s", clim_show, map_hover_weighted_pts(scores[6], w[6])),
    sprintf("<b>Conflict:</b> %s · %s", conflict_show, map_hover_weighted_pts(scores[7], w[7])),
    sprintf("<b>Hunger crisis / IPC:</b> %s · %s", outbreak_show, map_hover_weighted_pts(scores[8], w[8])),
    sprintf("<b>Food imports:</b> %s · %s", trade_show, map_hover_weighted_pts(scores[9], w[9])),
    sprintf("<b>Food supply:</b> %s · %s", food_show, map_hover_weighted_pts(scores[10], w[10])),
    sprintf("<b>Water stress:</b> %s · %s", water_show, map_hover_weighted_pts(scores[11], w[11])),
    sprintf("<b>Displacement:</b> %s · %s", disp_show, map_hover_weighted_pts(scores[12], w[12])),
    sep = "<br>"
  )
}

# Merged latest_year can exceed the World Bank CSV end year (e.g. IPC "Oct 2025"). The map filters by
# this field; a fixed slider max of 2023 hid every country with latest_year 2024+ from the choropleth.
.map_year_slider_max <- suppressWarnings(max(latest_summary$latest_year, na.rm = TRUE))
if (!is.finite(.map_year_slider_max)) .map_year_slider_max <- 2023L
.map_year_slider_max <- as.integer(max(2023L, .map_year_slider_max))

# Merge validation: per-country and per-indicator coverage (Data Coverage tab)
.merge_validation <- build_merge_validation(latest_summary)
merge_validation_report <- .merge_validation$report
merge_validation_summary <- .merge_validation$summary
has_cols <- .merge_validation$has_cols

# =============================================================================
# UI COMPONENTS
# =============================================================================

# Optional: data refresh stamp (scripts/run_data_refresh_pipeline.sh writes data/metadata/last_refresh.txt)
.data_refresh_banner <- tryCatch({
  f <- "data/metadata/last_refresh.txt"
  if (file.exists(f)) {
    paste("Data refresh log:", paste(trimws(readLines(f, warn = FALSE)), collapse = " "))
  } else ""
}, error = function(e) "")

# Page tab headers (primary box titles — white text on colored header bar)
page_tab_header <- function(title_text, subtitle_text = NULL, icon_name = NULL) {
  tags$div(
    class = "page-tab-header",
    tags$div(
      class = "page-tab-header__title-row",
      if (!is.null(icon_name)) icon(icon_name, class = "page-tab-header__icon"),
      tags$span(class = "page-tab-header__title", title_text)
    ),
    if (!is.null(subtitle_text) && nzchar(subtitle_text)) {
      tags$div(class = "page-tab-header__subtitle", subtitle_text)
    }
  )
}

ncyi_gallery_image_files <- function() {
  thumb_dir <- here::here("www", "ncyi_gallery", "thumbs")
  if (!dir.exists(thumb_dir)) {
    legacy_dir <- here::here("www", "ncyi_gallery")
    if (!dir.exists(legacy_dir)) return(character(0))
    return(sort(list.files(legacy_dir, pattern = "\\.(jpe?g|png|webp)$", ignore.case = TRUE)))
  }
  sort(list.files(thumb_dir, pattern = "\\.(jpe?g|png|webp)$", ignore.case = TRUE))
}

ncyi_gallery_ui <- function() {
  files <- ncyi_gallery_image_files()
  if (length(files) == 0) {
    return(tags$p(
      style = "color: #64748b; font-size: 14px; margin: 0;",
      "Conference photos will appear here once they are added to ",
      tags$code("www/ncyi_gallery/thumbs/"), "."
    ))
  }
  thumb_base <- "assets/ncyi_gallery/thumbs/"
  full_base <- "assets/ncyi_gallery/full/"
  legacy_flat <- !dir.exists(here::here("www", "ncyi_gallery", "thumbs"))
  tags$div(
    class = "ncyi-gallery",
    lapply(files, function(f) {
      thumb_src <- if (legacy_flat) paste0("assets/ncyi_gallery/", f) else paste0(thumb_base, f)
      full_src <- if (legacy_flat) thumb_src else paste0(full_base, f)
      tags$a(
        href = full_src,
        target = "_blank",
        rel = "noopener noreferrer",
        class = "ncyi-gallery__link",
        title = "Open photo full size",
        tags$img(
          src = thumb_src,
          alt = "NC Youth Institute conference photo",
          class = "ncyi-gallery__img",
          loading = "lazy",
          decoding = "async"
        )
      )
    })
  )
}

# Header
header <- dashboardHeader(
  title = "Global Hunger Research Dashboard",
  titleWidth = 350
)

# Sidebar
sidebar <- dashboardSidebar(
  width = 300,
  sidebarMenu(
    id = "tabs",
    menuItem("Introduction", tabName = "introduction", icon = icon("book"), selected = TRUE),
    menuItem("Interactive Map", tabName = "map", icon = icon("map")),
    menuItem("Scenario lab", tabName = "scenario_lab", icon = icon("flask")),
    menuItem("Overview", tabName = "overview", icon = icon("globe")),
    menuItem("Country Details", tabName = "country_details", icon = icon("flag")),
    menuItem("Time Series", tabName = "timeseries", icon = icon("chart-line")),
    menuItem("Statistical Analysis", tabName = "analysis", icon = icon("calculator")),
    menuItem("Data Sources", tabName = "citations", icon = icon("file-text")),
    menuItem("Data Coverage", tabName = "data_coverage", icon = icon("table")),
    menuItem("GRFC Trends", tabName = "grfc_trends", icon = icon("chart-line")),
    menuItem("Bangladesh Research", tabName = "bangladesh_research", icon = icon("seedling")),
    menuItem("GHI Comparison", tabName = "ghi_comparison", icon = icon("balance-scale")),
    menuItem("Data Explorer", tabName = "explorer", icon = icon("search")),
    menuItem("About", tabName = "about", icon = icon("info-circle")),
    
    # Filters (map-only)
    conditionalPanel(
      condition = "input.tabs == 'map'",
      tags$div(
        style = "padding: 8px 14px 8px 14px;",
        tags$div(
          style = "display: flex; align-items: center; justify-content: space-between; gap: 8px;",
          h4("Filters", style = "color: #7dd3fc; margin-top: 0; margin-bottom: 0; font-weight: 600; letter-spacing: 0.02em;"),
          actionLink(
            "filters_help",
            label = NULL,
            icon = icon("question-circle"),
            title = "How to use filters",
            style = "font-size: 16px; color: #7dd3fc; padding-top: 2px;"
          )
        ),
    selectInput(
      "selected_countries",
      "Select Countries:",
      choices = c("All", sort(unique(latest_summary$country))),
      selected = "All",
      multiple = TRUE
    ),
        tags$p(
          style = "font-size: 11px; color: #94a3b8; margin-top: 12px; line-height: 1.45;",
          icon("info-circle"),
          " Country selection applies here. Year, vulnerability, and other map filters are under the map (multipliers first, then Map Filters)."
        )
      )
    )

  ),
  tags$div(
    class = "sidebar-github-link",
    style = "padding: 14px 18px 18px; border-top: 1px solid rgba(255,255,255,0.12); margin-top: 8px;",
    tags$a(
      href = "https://github.com/garrbearzhou/global-hunger-dashboard",
      target = "_blank",
      rel = "noopener noreferrer",
      title = "Global Hunger Dashboard — source code on GitHub",
      icon("github"),
      " GitHub repository"
    )
  )
)

# Body
body <- dashboardBody(
  # Custom CSS
  tags$head(
    tags$meta(name = "description", content = "Interactive global hunger vulnerability map with country profiles, population and climate risk indicators, and food security analysis."),
    tags$meta(name = "robots", content = "index, follow"),
    tags$link(rel = "canonical", href = "https://globalhungerdashboard.com/"),
    tags$meta(property = "og:type", content = "website"),
    tags$meta(property = "og:url", content = "https://globalhungerdashboard.com/"),
    tags$meta(property = "og:title", content = "Global Hunger Vulnerability Dashboard"),
    tags$meta(property = "og:description", content = "Interactive global hunger vulnerability map with country hunger profiles, undernourishment data, and food security indicators."),
    tags$meta(property = "og:image", content = "https://globalhungerdashboard.com/assets/og-social-preview.png?v=12"),
    tags$meta(property = "og:image:width", content = "1200"),
    tags$meta(property = "og:image:height", content = "630"),
    tags$meta(property = "og:image:alt", content = "Global Hunger Vulnerability Dashboard — interactive food security map and country profiles"),
    tags$meta(property = "og:site_name", content = "Global Hunger Dashboard"),
    tags$meta(name = "twitter:card", content = "summary_large_image"),
    tags$meta(name = "twitter:title", content = "Global Hunger Vulnerability Dashboard"),
    tags$meta(name = "twitter:description", content = "Explore the global hunger vulnerability map and country-level food security profiles."),
    tags$meta(name = "twitter:image", content = "https://globalhungerdashboard.com/assets/og-social-preview.png?v=12"),
    tags$script(HTML("
      (function() {
        const SEO_BY_TAB = {
          introduction: {
            title: 'Global Hunger Vulnerability Dashboard',
            description: 'Explore the global hunger vulnerability map, country-level indicators, and food security trends.'
          },
          map: {
            title: 'Global Hunger Vulnerability Map',
            description: 'Interactive global hunger vulnerability map with country score, population, and total land area.'
          },
          country_details: {
            title: 'Country Hunger Profile | Global Hunger Dashboard',
            description: 'Country hunger profile with vulnerability score trends, drivers, and detailed food security indicators.'
          },
          overview: {
            title: 'Global Hunger Overview',
            description: 'Cross-country overview of vulnerability, undernourishment, population, and key risk relationships.'
          },
          timeseries: {
            title: 'Hunger Time Series Analysis',
            description: 'Analyze multi-year hunger and vulnerability trends with global time-series visualizations.'
          },
          analysis: {
            title: 'Hunger Statistical Analysis',
            description: 'Adaptation buffer research: OLS models, global buffer rankings, and Monte Carlo uncertainty across 143 countries.'
          },
          citations: {
            title: 'Data Sources & Citations | Global Hunger Dashboard',
            description: 'Chicago-style citations for FAO, World Bank, WFP, WHO, and other datasets used in the hunger vulnerability dashboard.'
          },
          data_coverage: {
            title: 'Data Coverage | Global Hunger Dashboard',
            description: 'Country and indicator coverage across integrated hunger, climate, conflict, and governance datasets.'
          },
          bangladesh_research: {
            title: 'Bangladesh Climate & Food Security Research',
            description: 'North Carolina Youth Institute research on Bangladesh floods, cyclones, sea-level rise, and food security.'
          },
          about: {
            title: 'About | Global Hunger Research Project',
            description: 'Meet Garrett Zhou and Professor Hannah Jacobs — Duke University research on global hunger and food insecurity.'
          },
          scenario_lab: {
            title: 'Scenario Lab | Global Hunger Dashboard',
            description: 'Adjust vulnerability pillar weights and explore how rankings change across countries.'
          },
          grfc_trends: {
            title: 'GRFC Trends | Global Hunger Dashboard',
            description: 'Trends from the Global Report on Food Crises — acute food insecurity and crisis severity over time.'
          },
          ghi_comparison: {
            title: 'Global Hunger Index Comparison',
            description: 'Compare Global Hunger Index metrics with dashboard vulnerability scores across countries.'
          },
          explorer: {
            title: 'Data Explorer | Global Hunger Dashboard',
            description: 'Search and browse country-level hunger, nutrition, climate, and governance indicators.'
          }
        };

        function setCanonical(url) {
          let el = document.querySelector('link[rel=\"canonical\"]');
          if (!el) {
            el = document.createElement('link');
            el.setAttribute('rel', 'canonical');
            document.head.appendChild(el);
          }
          el.setAttribute('href', url);
        }

        function setMeta(attr, key, value) {
          let el = document.querySelector('meta[' + attr + '=\"' + key + '\"]');
          if (!el) {
            el = document.createElement('meta');
            el.setAttribute(attr, key);
            document.head.appendChild(el);
          }
          el.setAttribute('content', value);
        }

        function applySeoForTab(tab) {
          const key = (tab && SEO_BY_TAB[tab]) ? tab : 'introduction';
          const seo = SEO_BY_TAB[key];
          const pageUrl = 'https://globalhungerdashboard.com/' + (tab && tab !== 'introduction' ? '?tab=' + tab : '');
          document.title = seo.title;
          setMeta('name', 'description', seo.description);
          setMeta('property', 'og:title', seo.title);
          setMeta('property', 'og:description', seo.description);
          setMeta('property', 'og:url', pageUrl);
          setMeta('name', 'twitter:title', seo.title);
          setMeta('name', 'twitter:description', seo.description);
          setCanonical(pageUrl);
        }

        function syncTabParam(tab) {
          if (!tab) return;
          const url = new URL(window.location.href);
          url.searchParams.set('tab', tab);
          history.replaceState({}, '', url.pathname + url.search);
        }

        document.addEventListener('shiny:connected', function() {
          const params = new URLSearchParams(window.location.search);
          const tab = params.get('tab') || 'introduction';
          applySeoForTab(tab);
          syncTabParam(tab);
          if (window.Shiny && typeof window.Shiny.setInputValue === 'function') {
            window.Shiny.setInputValue('initial_tab_from_url', tab, {priority: 'event'});
          }
        });

        document.addEventListener('shown.bs.tab', function(ev) {
          const target = ev && ev.target;
          if (!target) return;
          const href = target.getAttribute('href') || '';
          if (!href.startsWith('#shiny-tab-')) return;
          const tab = href.replace('#shiny-tab-', '');
          applySeoForTab(tab);
          syncTabParam(tab);
        });
      })();
    ")),
    tags$style(HTML("
      /* Design tokens + base typography */
      :root {
        --gh-primary: #0e7490;
        --gh-primary-dark: #155e75;
        --gh-accent: #0891b2;
        --gh-surface: #f1f5f9;
        --gh-surface-elevated: #ffffff;
        --gh-border: #e2e8f0;
        --gh-text: #0f172a;
        --gh-text-secondary: #475569;
        --gh-muted: #64748b;
      }
      body {
        font-family: 'Segoe UI', system-ui, -apple-system, BlinkMacSystemFont, Roboto, 'Helvetica Neue', Arial, sans-serif;
        -webkit-font-smoothing: antialiased;
        color: var(--gh-text);
        font-size: 14px;
        line-height: 1.5;
      }
      .seo-intro-block {
        background: var(--gh-surface-elevated);
        border: 1px solid var(--gh-border);
        border-radius: 10px;
        padding: 20px 22px;
        margin-bottom: 18px;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.06);
      }
      .seo-intro-block h1 {
        font-size: 1.65rem;
        font-weight: 700;
        color: var(--gh-text);
        margin: 0 0 8px;
        letter-spacing: -0.02em;
      }
      .seo-intro-block h2 {
        font-size: 1.05rem;
        font-weight: 600;
        color: var(--gh-primary);
        margin: 0 0 12px;
      }
      .seo-intro-block p {
        font-size: 14px;
        line-height: 1.65;
        color: var(--gh-text-secondary);
        margin: 0 0 10px;
      }
      .seo-intro-block p:last-child { margin-bottom: 0; }
      .intro-preview-hero {
        text-align: center;
        margin-bottom: 24px;
      }
      .intro-preview-hero img {
        max-width: 100%;
        height: auto;
        display: block;
        margin: 0 auto;
        border-radius: 10px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 4px 14px rgba(15, 23, 42, 0.08);
      }
      .site-brand-preview {
        position: fixed;
        top: 58px;
        right: 14px;
        z-index: 1040;
        width: 128px;
      }
      .site-brand-preview a {
        display: block;
        line-height: 0;
      }
      .site-brand-preview img {
        width: 100%;
        height: auto;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 2px 10px rgba(15, 23, 42, 0.14);
        background: #faf9f7;
      }
      .site-brand-preview a:hover img {
        box-shadow: 0 4px 14px rgba(15, 23, 42, 0.2);
      }
      @media (max-width: 768px) {
        .site-brand-preview { width: 96px; top: 52px; right: 8px; }
      }
      .sidebar-github-link a {
        color: #bae6fd !important;
        font-size: 13px;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 8px;
      }
      .sidebar-github-link a:hover {
        color: #ffffff !important;
        text-decoration: underline;
      }
      .sr-only {
        position: absolute;
        width: 1px;
        height: 1px;
        padding: 0;
        margin: -1px;
        overflow: hidden;
        clip: rect(0, 0, 0, 0);
        white-space: nowrap;
        border: 0;
      }
      .content-wrapper, .right-side {
        background-color: var(--gh-surface) !important;
      }
      .content-wrapper > .content {
        padding: 22px 26px 36px;
        max-width: 1920px;
        margin-left: auto;
        margin-right: auto;
      }
      /* Top bar */
      .main-header .logo,
      .main-header .navbar {
        background: linear-gradient(135deg, #0f172a 0%, #1e3a5f 100%) !important;
        border-bottom: 1px solid rgba(15, 23, 42, 0.5) !important;
        box-shadow: 0 2px 8px rgba(15, 23, 42, 0.12);
      }
      .main-header .logo {
        font-weight: 600 !important;
        letter-spacing: -0.02em !important;
        font-size: 15px !important;
      }
      .main-header .navbar .nav > li > a {
        color: rgba(255,255,255,0.9) !important;
      }
      .main-header .navbar .nav > li > a:hover,
      .main-header .navbar .nav > li > a:focus {
        background: rgba(255,255,255,0.08) !important;
      }
      /* Sidebar */
      .main-sidebar {
        background: #1e293b !important;
        box-shadow: inset -1px 0 0 rgba(15, 23, 42, 0.35);
      }
      .sidebar-menu > li > a {
        border-radius: 0 10px 10px 0;
        margin: 2px 8px 2px 0;
        padding: 10px 12px 10px 14px !important;
        color: #cbd5e1 !important;
        font-weight: 500;
        font-size: 13px;
        border-left: 3px solid transparent;
        transition: background 0.15s ease, color 0.15s ease, border-color 0.15s ease;
      }
      .sidebar-menu > li > a:hover {
        background: rgba(255,255,255,0.07) !important;
        color: #f8fafc !important;
      }
      .sidebar-menu > li.active > a {
        background: rgba(8, 145, 178, 0.22) !important;
        color: #fff !important;
        border-left-color: #22d3ee;
        font-weight: 600;
      }
      .sidebar-menu > li > a .fa {
        margin-right: 10px;
        width: 18px;
        text-align: center;
        opacity: 0.92;
      }
      .sidebar-form, .sidebar-menu .treeview-menu > li > a { color: #94a3b8 !important; }
      .sidebar hr, .sidebar-menu hr { border-color: rgba(148, 163, 184, 0.25) !important; }
      .sidebar .shiny-input-container label, .sidebar .control-label {
        color: #e2e8f0 !important;
        font-weight: 500;
        font-size: 12px;
        letter-spacing: 0.02em;
      }
      .sidebar .selectize-control { margin-bottom: 10px; }
      .sidebar .irs-line,
      .sidebar .irs-bar { background: rgba(148, 163, 184, 0.35) !important; }
      .sidebar .irs-bar-edge { background: rgba(148, 163, 184, 0.35) !important; }
      .sidebar .irs-from, .sidebar .irs-to, .sidebar .irs-single { background: #0e7490 !important; }
      
      /* Welcome modal styling */
      .modal-dialog {
        max-width: 800px;
      }
      .modal-body {
        padding: 25px;
      }
      .modal-body h4 {
        margin-top: 20px;
        margin-bottom: 10px;
      }
      .modal-body ul {
        margin-left: 20px;
      }
      .modal-body li {
        margin-bottom: 8px;
      }
      
      /* Cards: radius, subtle elevation */
      .box {
        border-radius: 10px;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.06);
        border: 1px solid var(--gh-border);
        background: var(--gh-surface-elevated);
        transition: box-shadow 0.25s ease, transform 0.25s ease;
      }
      .box:hover {
        box-shadow: 0 4px 14px rgba(15, 23, 42, 0.1);
      }
      .box-header {
        border-radius: 10px 10px 0 0;
        cursor: pointer;
        transition: background-color 0.2s ease;
        padding: 12px 18px;
        min-height: 48px;
        display: flex;
        align-items: center;
      }
      .box-header .box-title {
        font-size: 14px;
        font-weight: 600;
        letter-spacing: 0.01em;
      }
      .box-header .box-tools {
        margin-top: 0;
        margin-right: 2px;
      }
      .box-header .box-tools .btn-box-tool {
        padding: 6px 10px;
        font-size: 16px;
        color: rgba(0,0,0,0.4);
        transition: color 0.2s ease, background 0.2s ease;
        border-radius: 6px;
      }
      .box-header .box-tools .btn-box-tool:hover {
        color: rgba(0,0,0,0.7);
        background: rgba(0,0,0,0.05);
      }
      .box.collapsed-box .box-header {
        border-radius: 10px;
      }
      .box-header:hover {
        background-color: rgba(0,0,0,0.03);
      }
      .box.box-solid > .box-header {
        border-radius: 9px 9px 0 0;
      }
      .box.box-solid.box-primary > .box-header .box-title {
        width: 100%;
      }
      .page-tab-header {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 5px;
        width: 100%;
        padding: 2px 0;
      }
      .page-tab-header__title-row {
        display: flex;
        align-items: center;
        gap: 10px;
      }
      .page-tab-header__icon {
        color: #e0f2fe;
        font-size: 17px;
        flex-shrink: 0;
      }
      .page-tab-header__title {
        font-size: 18px;
        font-weight: 700;
        color: #ffffff;
        letter-spacing: 0.01em;
        line-height: 1.25;
      }
      .page-tab-header__subtitle {
        font-size: 13px;
        font-weight: 400;
        color: rgba(255, 255, 255, 0.88);
        line-height: 1.45;
        max-width: 100%;
      }
      .box.box-solid .box-header .box-tools .btn-box-tool {
        color: rgba(255,255,255,0.85);
      }
      .box.box-solid .box-header .box-tools .btn-box-tool:hover {
        color: #fff;
        background: rgba(255,255,255,0.15);
      }
      .info-box {
        border-radius: 10px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.06);
        transition: box-shadow 0.25s ease, transform 0.25s ease;
      }
      .info-box:hover {
        box-shadow: 0 4px 12px rgba(0,0,0,0.08);
      }
      .small-box {
        border-radius: 10px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.08);
        transition: box-shadow 0.25s ease, transform 0.2s ease;
      }
      .small-box:hover {
        box-shadow: 0 4px 14px rgba(0,0,0,0.12);
        transform: translateY(-2px);
      }
      .nav-tabs-custom > .nav-tabs > li.active {
        border-top-color: var(--gh-accent) !important;
      }
      .nav-tabs-custom > .nav-tabs > li > a {
        transition: color 0.2s ease, background 0.2s ease;
      }

      /* Sidebar: prevent overflow + subtle polish */
      .main-sidebar {
        overflow-x: hidden;
        box-shadow: 1px 0 8px rgba(0,0,0,0.04);
      }
      .main-sidebar .sidebar {
        overflow-y: auto;
        overflow-x: hidden;
      }
      .main-sidebar .sidebar h4,
      .main-sidebar .sidebar p,
      .main-sidebar .sidebar label,
      .main-sidebar .sidebar .control-label,
      .main-sidebar .sidebar .help-block {
        white-space: normal;
        word-break: break-word;
      }
      .main-sidebar .sidebar p {
        padding-right: 12px;
      }
      .main-sidebar .sidebar-menu li a {
        border-left: 3px solid transparent;
        transition: background-color 0.2s ease, border-left-color 0.2s ease, padding-left 0.2s ease;
      }
      .main-sidebar .sidebar-menu li a:hover {
        background-color: rgba(255,255,255,0.08);
      }
      .main-sidebar .sidebar-menu li.active > a {
        border-left-color: #22d3ee !important;
        background-color: rgba(8, 145, 178, 0.22) !important;
      }
      
      /* Header nav links (navbar is dark in theme) */
      .main-header .navbar .nav > li > a:hover {
        background-color: rgba(255,255,255,0.08) !important;
      }
      .main-header .navbar .nav > li > a {
        transition: background-color 0.2s ease;
      }
      
      /* Header: subtle bottom shadow */
      .main-header {
        box-shadow: 0 1px 4px rgba(0,0,0,0.06);
      }
      
      /* Overview tab: report-style layout */
      #shiny-tab-overview {
        padding: 6px 2px 20px 2px;
      }
      #shiny-tab-overview .overview-section-head {
        margin: 8px 0 14px 0;
        padding: 0 4px;
      }
      #shiny-tab-overview .overview-section-head h4 {
        margin: 0 0 4px 0;
        font-size: 17px;
        font-weight: 600;
        color: #0f172a;
        letter-spacing: -0.02em;
      }
      #shiny-tab-overview .overview-section-head p {
        margin: 0;
        font-size: 13px;
        color: #64748b;
        line-height: 1.45;
        max-width: 720px;
      }
      #shiny-tab-overview .box {
        border-radius: 10px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.06);
        overflow: visible;
        background: #fff;
      }
      #shiny-tab-overview .box-body {
        overflow: visible;
      }
      /* Plotly defaults to capturing wheel for zoom; static charts should not trap scroll */
      #shiny-tab-overview .plotly,
      #shiny-tab-overview .js-plotly-plot {
        touch-action: pan-y;
      }
      #shiny-tab-overview .box.box-solid > .box-header {
        background: #f8fafc !important;
        color: #0f172a !important;
        border-bottom: 1px solid #e2e8f0 !important;
      }
      #shiny-tab-overview .box.box-solid > .box-header .box-title,
      #shiny-tab-overview .box.box-solid.box-primary > .box-header .box-title {
        color: #0f172a !important;
        font-weight: 600;
        font-size: 15px;
        letter-spacing: -0.01em;
      }
      #shiny-tab-overview .box.box-solid > .box-header .box-title small {
        color: #64748b !important;
        font-weight: 400;
      }
      #shiny-tab-overview .box.box-solid .box-header .box-tools .btn-box-tool {
        color: rgba(15, 23, 42, 0.45) !important;
      }
      #shiny-tab-overview .box.box-solid .box-header .box-tools .btn-box-tool:hover {
        color: rgba(15, 23, 42, 0.85) !important;
        background: rgba(15, 23, 42, 0.06) !important;
      }
      #shiny-tab-overview .box-body {
        background: #fff;
      }
      #shiny-tab-overview .overview-scatter-toolbar {
        display: flex;
        flex-wrap: wrap;
        align-items: flex-end;
        gap: 14px 22px;
        margin-bottom: 14px;
        padding: 12px 14px;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
      }
      #shiny-tab-overview .overview-scatter-control label {
        display: block;
        margin: 0 0 4px 0;
        font-size: 12px;
        font-weight: 600;
        color: #64748b;
      }
      #shiny-tab-overview .overview-scatter-control .selectize-control {
        margin-bottom: 0;
      }
      #shiny-tab-overview .overview-kpi-row {
        margin-bottom: 8px;
      }
      #shiny-tab-overview .overview-caption {
        font-size: 12px;
        color: #64748b;
        line-height: 1.5;
        margin: 0 0 12px 0;
      }
      #shiny-tab-overview .js-plotly-plot .plotly {
        border-radius: 6px;
      }
      #shiny-tab-overview .dataTables_wrapper {
        font-size: 13px;
      }
      #shiny-tab-overview table.dataTable thead th {
        background: #f8fafc !important;
        color: #334155 !important;
        font-weight: 600 !important;
        border-bottom: 2px solid #e2e8f0 !important;
      }
      #shiny-tab-overview table.dataTable tbody tr:hover {
        background: #f1f5f9 !important;
      }

      /* Data Explorer — interactive visualization charts */
      #shiny-tab-explorer .explorer-viz-banner {
        background: linear-gradient(135deg, #f8fafc 0%, #eef6fc 100%);
        border: 1px solid #dbeafe;
        border-left: 4px solid #3c8dbc;
        border-radius: 10px;
        padding: 16px 18px;
        margin-bottom: 16px;
        color: #334155;
      }
      #shiny-tab-explorer .explorer-viz-banner h4 {
        color: #0f172a;
        font-size: 16px;
        font-weight: 600;
      }
      #shiny-tab-explorer .explorer-viz-banner p {
        font-size: 13px;
        color: #64748b;
        line-height: 1.55;
      }
      #shiny-tab-explorer .explorer-viz-panel > .box-body {
        background: #f8fafc;
        padding: 18px 16px 12px;
      }
      #shiny-tab-explorer .explorer-plot-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        padding: 8px 6px 4px;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.05);
        margin-bottom: 12px;
      }
      #shiny-tab-explorer .explorer-plot-card .js-plotly-plot .plotly {
        border-radius: 6px;
      }
      #shiny-tab-explorer .explorer-plot-card .modebar {
        opacity: 0.35;
        transition: opacity 0.15s ease;
      }
      #shiny-tab-explorer .explorer-plot-card:hover .modebar {
        opacity: 1;
      }
      
      /* Info icon styling */
      .info-icon {
        display: inline-block;
        width: 16px;
        height: 16px;
        line-height: 16px;
        text-align: center;
        border-radius: 50%;
        background-color: #3c8dbc;
        color: white;
        font-size: 11px;
        font-weight: bold;
        cursor: help;
        margin-left: 5px;
        vertical-align: middle;
        position: relative;
      }
      .info-icon {
        transition: background-color 0.2s ease, transform 0.15s ease;
      }
      .info-icon:hover {
        background-color: #2a6fa5;
        transform: scale(1.1);
      }
      
      /* Country profile metric cards */
      .country-details-stats {
        display: grid;
        grid-template-columns: repeat(5, minmax(0, 1fr));
        gap: 14px;
        margin: 0 0 20px 0;
        padding: 0;
      }
      @media (max-width: 1200px) {
        .country-details-stats {
          grid-template-columns: repeat(3, minmax(0, 1fr));
        }
      }
      @media (max-width: 768px) {
        .country-details-stats {
          grid-template-columns: repeat(2, minmax(0, 1fr));
        }
      }
      .country-metric-card {
        --metric-accent: #0891b2;
        --metric-icon-bg: rgba(8, 145, 178, 0.12);
        --metric-bg: linear-gradient(145deg, #ffffff 0%, #f8fafc 100%);
        display: flex;
        align-items: flex-start;
        gap: 14px;
        padding: 18px 16px;
        min-height: 118px;
        background: var(--metric-bg);
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.06), 0 4px 14px rgba(15, 23, 42, 0.04);
        border-left: 4px solid var(--metric-accent);
        transition: box-shadow 0.2s ease, transform 0.15s ease;
      }
      .country-metric-card:hover {
        box-shadow: 0 4px 16px rgba(15, 23, 42, 0.1);
        transform: translateY(-1px);
      }
      .country-metric-card__icon {
        flex-shrink: 0;
        width: 44px;
        height: 44px;
        border-radius: 10px;
        background: var(--metric-icon-bg);
        color: var(--metric-accent);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 18px;
      }
      .country-metric-card__body {
        flex: 1;
        min-width: 0;
      }
      .country-metric-card__value {
        font-size: 1.65rem;
        font-weight: 700;
        line-height: 1.15;
        color: var(--metric-accent);
        letter-spacing: -0.02em;
        margin: 0 0 6px 0;
      }
      .country-metric-card__label {
        font-size: 12px;
        font-weight: 600;
        line-height: 1.35;
        color: #64748b;
        margin: 0;
      }
      .country-details-stats .info-icon {
        background-color: #e2e8f0;
        color: #475569;
      }
      .country-details-stats .info-icon:hover {
        background-color: #cbd5e1;
        color: #1e293b;
      }
      .country-metric-card--low { --metric-accent: #16a34a; --metric-icon-bg: rgba(22, 163, 74, 0.18); --metric-bg: linear-gradient(145deg, #ffffff 0%, #f0fdf4 100%); }
      .country-metric-card--moderate { --metric-accent: #ca8a04; --metric-icon-bg: rgba(202, 138, 4, 0.18); --metric-bg: linear-gradient(145deg, #ffffff 0%, #fefce8 100%); }
      .country-metric-card--high { --metric-accent: #ea580c; --metric-icon-bg: rgba(234, 88, 12, 0.18); --metric-bg: linear-gradient(145deg, #ffffff 0%, #fff7ed 100%); }
      .country-metric-card--critical { --metric-accent: #dc2626; --metric-icon-bg: rgba(220, 38, 38, 0.18); --metric-bg: linear-gradient(145deg, #ffffff 0%, #fef2f2 100%); }
      .country-metric-card--sky { --metric-accent: #0284c7; --metric-icon-bg: rgba(2, 132, 199, 0.18); --metric-bg: linear-gradient(145deg, #ffffff 0%, #f0f9ff 100%); }
      .country-metric-card--emerald { --metric-accent: #059669; --metric-icon-bg: rgba(5, 150, 105, 0.18); --metric-bg: linear-gradient(145deg, #ffffff 0%, #ecfdf5 100%); }
      .country-metric-card--violet { --metric-accent: #7c3aed; --metric-icon-bg: rgba(124, 58, 237, 0.18); --metric-bg: linear-gradient(145deg, #ffffff 0%, #f5f3ff 100%); }
      .country-metric-card--amber { --metric-accent: #d97706; --metric-icon-bg: rgba(217, 119, 6, 0.18); --metric-bg: linear-gradient(145deg, #ffffff 0%, #fffbeb 100%); }
      .country-details-footnote {
        margin: 0 0 16px 0;
        padding: 10px 14px;
        font-size: 13px;
        color: #64748b;
        background: linear-gradient(90deg, #f0f9ff 0%, #ffffff 100%);
        border: 1px solid #bae6fd;
        border-radius: 8px;
        border-left: 3px solid #0891b2;
      }
      .country-details-notices {
        margin: 0 0 16px 0;
        padding: 14px 18px;
        font-size: 13px;
        line-height: 1.6;
        color: #475569;
        background: linear-gradient(90deg, #fffbeb 0%, #ffffff 100%);
        border: 1px solid #fde68a;
        border-left: 4px solid #d97706;
        border-radius: 10px;
        box-shadow: 0 1px 4px rgba(217, 119, 6, 0.08);
      }
      .country-details-notices__title {
        display: flex;
        align-items: center;
        gap: 8px;
        margin: 0 0 8px 0;
        font-size: 14px;
        font-weight: 700;
        color: #92400e;
      }
      .country-details-notices__body {
        margin: 0 0 10px 0;
      }
      .country-details-notices__footnote {
        margin: 0;
        padding-top: 10px;
        border-top: 1px solid rgba(217, 119, 6, 0.2);
        font-size: 12px;
        color: #64748b;
      }
      .country-details-notices__footnote strong {
        color: #0891b2;
      }
      .country-details-footnote strong {
        color: #0891b2;
      }
      
      /* Country details: prevent dropdowns/categories from shifting when opening one */
      #shiny-tab-country_details .box-header {
        flex-shrink: 0;
      }
      #shiny-tab-country_details .row:not(.country-details-stats) {
        align-items: flex-start;
      }
      #shiny-tab-country_details .box {
        min-height: 48px;
      }
      #shiny-tab-country_details {
        padding: 8px 15px 28px 15px;
        background: linear-gradient(165deg, #e0f2fe 0%, #f0f9ff 18%, #f8fafc 45%, #ffffff 100%);
      }
      #shiny-tab-country_details > .row,
      #shiny-tab-country_details .country-details-content-row,
      #shiny-tab-country_details #country_details_panels > .row {
        margin-left: -15px;
        margin-right: -15px;
      }
      #shiny-tab-country_details > .row > [class*='col-'],
      #shiny-tab-country_details .country-details-content-row > [class*='col-'],
      #shiny-tab-country_details #country_details_panels > .row > [class*='col-'] {
        padding-left: 15px;
        padding-right: 15px;
      }
      #shiny-tab-country_details .country-details-select-wrapper .box.box-solid {
        border: 1px solid #93c5fd;
        box-shadow: 0 4px 16px rgba(37, 99, 235, 0.08);
      }
      #shiny-tab-country_details .country-details-select-wrapper .box-header {
        background: linear-gradient(135deg, #1d4ed8 0%, #2563eb 55%, #3b82f6 100%) !important;
        color: #ffffff !important;
        border-bottom: none !important;
        border-radius: 12px 12px 0 0;
      }
      #shiny-tab-country_details .country-details-select-wrapper .box-title {
        color: #ffffff !important;
        font-weight: 600;
      }
      #shiny-tab-country_details .box.box-solid {
        border-radius: 12px;
        border: 1px solid #dbe3ee;
        box-shadow: 0 2px 8px rgba(15, 23, 42, 0.06);
        overflow: visible;
        margin-bottom: 14px;
      }
      #shiny-tab-country_details #country_details_panels .box.box-solid > .box-header {
        background: linear-gradient(180deg, #ffffff 0%, #f1f5f9 100%) !important;
        color: #0f172a !important;
        border-bottom: 1px solid #e2e8f0 !important;
        border-left: 4px solid #3c8dbc;
        padding: 14px 18px;
        cursor: pointer;
      }
      #country_details_panels .row > div:nth-child(1) .box-header {
        border-left-color: #2563eb !important;
        background: linear-gradient(90deg, #eff6ff 0%, #ffffff 100%) !important;
      }
      #country_details_panels .row > div:nth-child(1) .box-title i { color: #2563eb !important; }
      #country_details_panels .row > div:nth-child(2) .box-header {
        border-left-color: #d97706 !important;
        background: linear-gradient(90deg, #fffbeb 0%, #ffffff 100%) !important;
      }
      #country_details_panels .row > div:nth-child(2) .box-title i { color: #d97706 !important; }
      #country_details_panels .row > div:nth-child(3) .box-header {
        border-left-color: #0891b2 !important;
        background: linear-gradient(90deg, #ecfeff 0%, #ffffff 100%) !important;
      }
      #country_details_panels .row > div:nth-child(3) .box-title i { color: #0891b2 !important; }
      #country_details_panels .row > div:nth-child(4) .box-header {
        border-left-color: #7c3aed !important;
        background: linear-gradient(90deg, #f5f3ff 0%, #ffffff 100%) !important;
      }
      #country_details_panels .row > div:nth-child(4) .box-title i { color: #7c3aed !important; }
      #country_details_panels .row > div:nth-child(5) .box-header {
        border-left-color: #059669 !important;
        background: linear-gradient(90deg, #ecfdf5 0%, #ffffff 100%) !important;
      }
      #country_details_panels .row > div:nth-child(5) .box-title i { color: #059669 !important; }
      #country_details_panels .row > div:nth-child(6) .box-header {
        border-left-color: #4f46e5 !important;
        background: linear-gradient(90deg, #eef2ff 0%, #ffffff 100%) !important;
      }
      #country_details_panels .row > div:nth-child(6) .box-title i { color: #4f46e5 !important; }
      #shiny-tab-country_details .country-detail-panel.box.box-solid > .box-header .box-title,
      #shiny-tab-country_details .country-detail-panel.box.box-solid > .box-header .box-title span,
      #shiny-tab-country_details .country-detail-panel.box.box-solid > .box-header .box-title i,
      #shiny-tab-country_details #country_details_panels .box.box-solid > .box-header .box-title,
      #shiny-tab-country_details #country_details_panels .box.box-solid > .box-header .box-title span,
      #shiny-tab-country_details #country_details_panels .box.box-solid > .box-header .box-title i {
        color: #0f172a !important;
        font-weight: 600;
        font-size: 15px;
        letter-spacing: -0.01em;
      }
      #shiny-tab-country_details .country-detail-panel.box.box-solid .box-header .box-tools .btn-box-tool,
      #shiny-tab-country_details #country_details_panels .box.box-solid .box-header .box-tools .btn-box-tool {
        color: #475569 !important;
      }
      #shiny-tab-country_details .country-detail-panel.box.box-solid .box-header .box-tools .btn-box-tool:hover,
      #shiny-tab-country_details #country_details_panels .box.box-solid .box-header .box-tools .btn-box-tool:hover {
        color: #0f172a !important;
        background: rgba(15, 23, 42, 0.08) !important;
      }
      #shiny-tab-country_details #country_details_panels .box.collapsed-box > .box-body {
        display: none !important;
      }
      #shiny-tab-country_details #country_details_panels .box:not(.collapsed-box) > .box-body {
        display: block !important;
      }
      #shiny-tab-country_details #country_details_panels .box.collapsed-box > .box-header {
        border-radius: 12px;
        border-bottom: none !important;
      }
      #shiny-tab-country_details .country-detail-panel.collapsed-box > .box-body {
        display: none !important;
      }
      #shiny-tab-country_details .country-detail-panel:not(.collapsed-box) > .box-body {
        display: block;
      }
      #shiny-tab-country_details .country-detail-panel.collapsed-box > .box-header {
        border-radius: 12px;
        border-bottom: none !important;
      }
      #shiny-tab-country_details .country-detail-panel > .box-body,
      #shiny-tab-country_details #country_details_panels .box > .box-body {
        color: #334155;
        line-height: 1.55;
        background: #ffffff;
        padding: 18px 20px 20px;
        border-radius: 0 0 12px 12px;
      }
      #shiny-tab-country_details .country-detail-panel.country-detail-chart > .box-body {
        background: linear-gradient(180deg, #fafbfd 0%, #ffffff 100%);
      }
      #shiny-tab-country_details .country-chart-slot {
        min-height: 300px;
      }
      #shiny-tab-country_details .country-chart-slot .plotly.html-widget,
      #shiny-tab-country_details .country-chart-slot .js-plotly-plot {
        width: 100% !important;
      }
      #shiny-tab-country_details .country-history-table-slot {
        min-height: 200px;
        width: 100%;
      }
      #shiny-tab-country_details .country-history-table-slot .dataTables_wrapper {
        width: 100% !important;
      }
      #shiny-tab-country_details .country-details-section-hint {
        margin: 0 0 12px 0;
        padding: 12px 16px;
        font-size: 13px;
        color: #475569;
        background: linear-gradient(90deg, #f0fdf4 0%, #ffffff 100%);
        border: 1px solid #bbf7d0;
        border-left: 4px solid #22c55e;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(34, 197, 94, 0.08);
      }
      #shiny-tab-country_details .country-profile-banner {
        margin: 0 0 16px 0;
        padding: 20px 24px;
        background: linear-gradient(135deg, #ffffff 0%, #f8fafc 55%, #eef6fc 100%);
        border: 1px solid #dbe3ee;
        border-radius: 14px;
        border-left: 6px solid #3c8dbc;
        box-shadow: 0 4px 18px rgba(15, 23, 42, 0.08);
        position: relative;
        overflow: hidden;
      }
      #shiny-tab-country_details .country-profile-banner::before {
        content: '';
        position: absolute;
        top: -40%;
        right: -5%;
        width: 220px;
        height: 220px;
        border-radius: 50%;
        background: radial-gradient(circle, rgba(59, 130, 246, 0.12) 0%, transparent 70%);
        pointer-events: none;
      }
      #shiny-tab-country_details .country-profile-banner--low {
        border-left-color: #16a34a;
        background: linear-gradient(135deg, #ffffff 0%, #f0fdf4 45%, #ecfdf5 100%);
      }
      #shiny-tab-country_details .country-profile-banner--low::before {
        background: radial-gradient(circle, rgba(22, 163, 74, 0.14) 0%, transparent 70%);
      }
      #shiny-tab-country_details .country-profile-banner--moderate {
        border-left-color: #ca8a04;
        background: linear-gradient(135deg, #ffffff 0%, #fefce8 45%, #fef9c3 100%);
      }
      #shiny-tab-country_details .country-profile-banner--moderate::before {
        background: radial-gradient(circle, rgba(202, 138, 4, 0.14) 0%, transparent 70%);
      }
      #shiny-tab-country_details .country-profile-banner--high {
        border-left-color: #ea580c;
        background: linear-gradient(135deg, #ffffff 0%, #fff7ed 45%, #ffedd5 100%);
      }
      #shiny-tab-country_details .country-profile-banner--high::before {
        background: radial-gradient(circle, rgba(234, 88, 12, 0.14) 0%, transparent 70%);
      }
      #shiny-tab-country_details .country-profile-banner--critical {
        border-left-color: #dc2626;
        background: linear-gradient(135deg, #ffffff 0%, #fef2f2 45%, #fee2e2 100%);
      }
      #shiny-tab-country_details .country-profile-banner--critical::before {
        background: radial-gradient(circle, rgba(220, 38, 38, 0.14) 0%, transparent 70%);
      }
      .country-profile-vuln-badge {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        margin-top: 8px;
        padding: 5px 12px;
        border-radius: 999px;
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 0.02em;
        text-transform: uppercase;
      }
      .country-profile-vuln-badge--low { background: #dcfce7; color: #166534; border: 1px solid #86efac; }
      .country-profile-vuln-badge--moderate { background: #fef9c3; color: #854d0e; border: 1px solid #fde047; }
      .country-profile-vuln-badge--high { background: #ffedd5; color: #9a3412; border: 1px solid #fdba74; }
      .country-profile-vuln-badge--critical { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }
      .country-profile-region-badge {
        display: inline-flex;
        align-items: center;
        gap: 5px;
        margin-left: 8px;
        padding: 4px 10px;
        border-radius: 999px;
        font-size: 11px;
        font-weight: 600;
        background: #e0e7ff;
        color: #3730a3;
        border: 1px solid #c7d2fe;
      }
      #shiny-tab-country_details .country-profile-flag {
        flex-shrink: 0;
      }
      #shiny-tab-country_details .country-profile-flag-img {
        display: block;
        width: 96px;
        height: 64px;
        object-fit: cover;
        border-radius: 8px;
        border: 2px solid #ffffff;
        box-shadow: 0 4px 14px rgba(15, 23, 42, 0.18);
        background: #f1f5f9;
      }
      /* Fixed height so selector area never resizes when dropdown opens */
      .country-details-select-wrapper {
        height: 165px;
        min-height: 165px;
        max-height: 165px;
        overflow: visible;
      }
      /* Fixed-height scroll area: only this section scrolls; page layout stays stable */
      .country-details-collapsible-wrapper {
        height: auto;
        min-height: 0;
        max-height: none;
        overflow: visible;
        padding: 0 0 8px 0;
        flex-shrink: 0;
      }
      .selectize-dropdown {
        position: absolute !important;
        z-index: 9999;
        background: #fff !important;
        border: 1px solid #dde2e8;
        border-radius: 6px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      }
      .selectize-dropdown .selectize-dropdown-content {
        background: #fff !important;
      }
      .selectize-dropdown .option,
      .selectize-dropdown .optgroup-header {
        background: #fff !important;
        color: #333;
      }
      .selectize-dropdown .option.active {
        background: var(--gh-primary) !important;
        color: #fff;
      }
      .selectize-input.focus + .selectize-dropdown,
      .selectize-dropdown-content {
        position: absolute !important;
      }
      
      /* Tooltip styling — opens below the icon so content is not clipped at top of page/viewport */
      .info-tooltip {
        position: relative;
        display: inline-block;
        overflow: visible;
        vertical-align: middle;
      }
      .info-tooltip .tooltip-text {
        visibility: hidden;
        width: min(320px, 92vw);
        max-width: 320px;
        background-color: #1e293b;
        color: #f1f5f9;
        text-align: left;
        border-radius: 8px;
        padding: 12px 14px;
        position: absolute;
        z-index: 10050;
        top: calc(100% + 10px);
        bottom: auto;
        left: 50%;
        right: auto;
        transform: translateX(-50%);
        margin-left: 0;
        opacity: 0;
        transition: opacity 0.2s ease, visibility 0.2s ease;
        font-size: 13px;
        line-height: 1.5;
        box-shadow: 0 8px 24px rgba(15, 23, 42, 0.25);
        white-space: normal;
        pointer-events: none;
      }
      .info-tooltip .tooltip-text__title {
        display: block;
        font-weight: 700;
        font-size: 13px;
        line-height: 1.35;
        margin: 0 0 6px 0;
        color: #f8fafc;
      }
      .info-tooltip .tooltip-text__body {
        display: block;
        font-weight: 400;
        font-size: 13px;
        line-height: 1.55;
        margin: 0;
        color: #e2e8f0;
      }
      .info-tooltip .tooltip-text::after {
        content: '';
        position: absolute;
        bottom: 100%;
        left: 50%;
        margin-left: -7px;
        border-width: 7px;
        border-style: solid;
        border-color: transparent transparent #1e293b transparent;
      }
      .info-tooltip:hover .tooltip-text,
      .info-tooltip:focus-within .tooltip-text {
        visibility: visible;
        opacity: 1;
      }
      .info-icon:focus {
        outline: 2px solid var(--gh-accent);
        outline-offset: 2px;
      }
      
      /* Form controls: polish + transition */
      .form-control, .selectize-input {
        border-radius: 6px;
        border-color: #dde2e8;
        background: #fff !important;
        transition: border-color 0.2s ease, box-shadow 0.2s ease;
      }
      .form-control:focus, .selectize-input.focus {
        border-color: var(--gh-accent);
        box-shadow: 0 0 0 2px rgba(8, 145, 178, 0.2);
      }
      .form-control:hover, .selectize-input:hover {
        border-color: #b8c4ce;
      }
      .btn {
        transition: background-color 0.2s ease, border-color 0.2s ease, transform 0.15s ease;
      }
      .btn:hover {
        transform: translateY(-1px);
      }
      .btn:active {
        transform: translateY(0);
      }
      
      /* Tables: clearer row hover */
      .dataTables_wrapper .table {
        border-radius: 8px;
        overflow: hidden;
      }
      .dataTables_wrapper .table tbody tr {
        transition: background-color 0.15s ease;
      }
      .dataTables_wrapper .table tbody tr:hover {
        background-color: rgba(8, 145, 178, 0.07);
      }
      
      /* Scenario lab: illustrated country map */
      .scenario-country-wrap {
        text-align: center;
        padding: 12px 12px 20px;
      }
      .scenario-country-svg-host {
        min-height: 200px;
      }
      .scenario-country-svg-host svg,
      .scenario-country-svg-host .scenario-country-map-img {
        width: min(100%, 580px);
        max-width: 580px;
        height: auto;
        display: block;
        margin: 0 auto;
        filter: drop-shadow(0 12px 28px rgba(15, 23, 42, 0.22));
        border-radius: 14px;
        background: #0369a1;
      }
      .scenario-country-shape {
        transition: fill 0.45s ease;
      }

      /* Data Coverage tab */
      .coverage-kpi-card {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        padding: 16px 14px;
        text-align: center;
        box-shadow: 0 1px 4px rgba(15, 23, 42, 0.05);
        margin-bottom: 12px;
      }
      .coverage-kpi-value {
        font-size: 28px;
        font-weight: 800;
        color: #0f172a;
        line-height: 1.1;
      }
      .coverage-kpi-label {
        font-size: 12px;
        color: #64748b;
        margin-top: 6px;
        line-height: 1.4;
      }
      #shiny-tab-data_coverage .coverage-section-head {
        margin: 8px 0 12px 0;
        font-size: 13px;
        color: #64748b;
        line-height: 1.5;
      }

      /* GRFC Trends tab */
      #shiny-tab-grfc_trends .grfc-trends-controls {
        margin: 4px 0 18px 0;
        padding: 14px 16px;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
      }
      #shiny-tab-grfc_trends .grfc-trends-controls .control-label {
        font-size: 12px;
        font-weight: 600;
        color: #64748b;
        margin-bottom: 6px;
      }
      #shiny-tab-grfc_trends .grfc-trends-countries .selectize-input {
        min-height: 44px;
        height: auto !important;
        padding: 8px 10px;
        line-height: 1.45;
        border-radius: 8px;
        border-color: #cbd5e1;
        background: #fff;
      }
      #shiny-tab-grfc_trends .grfc-trends-countries .selectize-input.focus {
        border-color: #6366f1;
        box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.15);
      }
      #shiny-tab-grfc_trends .grfc-trends-countries .selectize-input > div.item {
        margin: 3px 6px 3px 0;
        padding: 4px 10px;
        border-radius: 999px;
        background: #eef2ff;
        border: 1px solid #c7d2fe;
        color: #3730a3;
        font-size: 12px;
        font-weight: 500;
      }
      #shiny-tab-grfc_trends .grfc-trends-download {
        display: flex;
        align-items: flex-end;
        height: 100%;
        padding-bottom: 2px;
      }
      #shiny-tab-grfc_trends .grfc-trends-chart-wrap {
        margin-top: 4px;
        padding: 12px 8px 4px 8px;
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
      }
      #shiny-tab-grfc_trends .grfc-trends-chart-title {
        margin: 0 0 4px 4px;
        font-size: 15px;
        font-weight: 600;
        color: #334155;
      }

      /* Leaflet map: stronger hover cue for clickable areas */
      .leaflet-container {
        border-radius: 10px;
      }
      .leaflet-interactive:hover {
        stroke-width: 2;
      }
      
      /* Solid status box headers (applies across tabs) */
      .box.box-solid.box-primary > .box-header {
        background: linear-gradient(135deg, var(--gh-primary-dark) 0%, var(--gh-primary) 100%) !important;
        border-bottom: none !important;
      }
      .box.box-solid.box-primary {
        border-top-color: var(--gh-primary-dark) !important;
      }
      .box.box-solid.box-info > .box-header {
        background: linear-gradient(135deg, #334155 0%, #475569 100%) !important;
        border-bottom: none !important;
      }
      .box.box-solid.box-success > .box-header {
        background: linear-gradient(135deg, #166534 0%, #15803d 100%) !important;
        border-bottom: none !important;
      }
      .box.box-solid.box-warning > .box-header {
        background: linear-gradient(135deg, #a16207 0%, #ca8a04 100%) !important;
        border-bottom: none !important;
      }
      .box.box-solid.box-danger > .box-header {
        background: linear-gradient(135deg, #b91c1c 0%, #dc2626 100%) !important;
        border-bottom: none !important;
      }
      .box-header.with-border {
        border-bottom: 1px solid var(--gh-border) !important;
      }
      .box-header .box-title {
        color: rgba(15, 23, 42, 0.92);
        font-weight: 600;
        letter-spacing: -0.01em;
      }
      .box.box-solid .box-header .box-title {
        color: #fff !important;
      }
      .nav-tabs-custom {
        background: var(--gh-surface-elevated);
        border: 1px solid var(--gh-border);
        border-radius: 12px;
        overflow: hidden;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.06);
      }
      .nav-tabs-custom > .nav-tabs {
        border-bottom: 1px solid var(--gh-border) !important;
      }
      .nav-tabs-custom > .nav-tabs > li > a {
        font-weight: 500;
        color: var(--gh-muted) !important;
      }
      .nav-tabs-custom > .nav-tabs > li.active > a {
        font-weight: 600 !important;
        color: var(--gh-text) !important;
      }
      .nav-tabs-custom > .tab-content {
        background: var(--gh-surface-elevated);
        padding: 18px 16px 22px;
      }
      .small-box {
        border: 1px solid var(--gh-border);
      }
      .small-box .inner h3 {
        font-weight: 700;
        letter-spacing: -0.02em;
      }
      .modal-content {
        border: none;
        border-radius: 12px;
        box-shadow: 0 20px 50px rgba(15, 23, 42, 0.2);
      }
      .modal-header {
        border-bottom: 1px solid var(--gh-border);
        font-weight: 600;
      }
      .content h1, .content h2, .content h3, .content h4 {
        color: var(--gh-text);
        font-weight: 600;
        letter-spacing: -0.02em;
      }
      .content a { color: var(--gh-primary); }
      .content a:hover { color: var(--gh-primary-dark); }
      .btn-primary {
        background-color: var(--gh-primary) !important;
        border-color: var(--gh-primary-dark) !important;
        font-weight: 500;
      }
      .btn-primary:hover, .btn-primary:focus {
        background-color: var(--gh-primary-dark) !important;
        border-color: #0c4a5e !important;
      }
      /* Plotly chart containers */
      .plotly.html-widget {
        transition: opacity 0.2s ease;
      }
      .box:hover .plotly.html-widget {
        opacity: 1;
      }
      /* NC Youth Institute photo gallery (Bangladesh research tab) */
      .ncyi-gallery {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
        gap: 14px;
        margin-top: 4px;
      }
      .ncyi-gallery__link {
        display: block;
        border-radius: 10px;
        overflow: hidden;
        box-shadow: 0 2px 10px rgba(15, 23, 42, 0.12);
        transition: transform 0.18s ease, box-shadow 0.18s ease;
        background: #f8fafc;
      }
      .ncyi-gallery__link:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 22px rgba(15, 23, 42, 0.18);
      }
      .ncyi-gallery__img {
        width: 100%;
        height: 220px;
        object-fit: cover;
        display: block;
      }

      /* Statistical Analysis: near-zero regression cells */
      .regression-near-zero {
        cursor: pointer;
        color: #0369a1;
        border-bottom: 1px dashed #94a3b8;
        font-weight: 500;
        white-space: nowrap;
      }
      .regression-near-zero:hover {
        color: #0c4a6e;
        border-bottom-color: #0369a1;
      }
      .regression-near-zero--revealed {
        color: #0f172a;
        border-bottom: none;
        font-weight: 400;
        font-variant-numeric: tabular-nums;
      }
    ")),
    tags$script(HTML("
      // Collapsible shinydashboard boxes inside uiOutput never get AdminLTE's boxWidget binding.
      // Toggle the same CSS class the static boxes use so charts/tables inside Country Details expand/collapse.
      (function() {
        function refreshOutputsInCountryBox(boxEl) {
          if (!boxEl || !window.jQuery) return;
          var $box = window.jQuery(boxEl);
          function run() {
            if ($box.hasClass('collapsed-box')) return;
            $box.find('.box-body').css('display', '');
            if (window.Plotly) {
              $box.find('.js-plotly-plot').each(function() {
                try { window.Plotly.Plots.resize(this); } catch (err) {}
              });
            }
            $box.find('table.dataTable').each(function() {
              try {
                if (window.jQuery.fn.dataTable && window.jQuery.fn.dataTable.isDataTable(this)) {
                  window.jQuery(this).DataTable().columns.adjust().draw(false);
                }
              } catch (err) {}
            });
          }
          [0, 120, 350, 700, 1200].forEach(function(ms) {
            setTimeout(run, ms);
          });
        }
        function setCountryBoxCollapsed(box, collapsed) {
          box.toggleClass('collapsed-box', collapsed);
          var body = box.children('.box-body');
          if (body.length) {
            body.css('display', collapsed ? 'none' : '');
          }
        }
        function toggleCountryDetailBox(el) {
          var box = window.jQuery(el).closest('.box');
          if (!box.length) return;
          var wasCollapsed = box.hasClass('collapsed-box');
          setCountryBoxCollapsed(box, !wasCollapsed);
          if (wasCollapsed) {
            refreshOutputsInCountryBox(box[0]);
            var panelId = box.find('.box-body[data-panel-id]').attr('data-panel-id');
            if (panelId === 'history_table' && window.Shiny) {
              window.Shiny.setInputValue('country_history_table_refresh', Date.now(), {priority: 'event'});
            }
          }
        }
        window.jQuery(document).on('click', '#country_details_content [data-widget=\"collapse\"], #country_details_panels [data-widget=\"collapse\"]', function(e) {
          e.preventDefault();
          e.stopPropagation();
          e.stopImmediatePropagation();
          toggleCountryDetailBox(this);
          return false;
        });
        window.jQuery(document).on('click', '#country_details_content .box.box-solid:has([data-widget=\"collapse\"]) > .box-header, #country_details_panels .box.box-solid:has([data-widget=\"collapse\"]) > .box-header', function(e) {
          if (window.jQuery(e.target).closest('.box-tools, a, button, .info-tooltip, input, select, label').length) return;
          e.preventDefault();
          e.stopPropagation();
          e.stopImmediatePropagation();
          toggleCountryDetailBox(this);
          return false;
        });
        // Plotly/DT are often sized while the box body is display:none; resize when outputs update if section is open.
        function resizeAllCountryDetailPlots() {
          if (!window.Plotly || !window.jQuery) return;
          window.jQuery('#country_details_content .js-plotly-plot, #country_details_panels .js-plotly-plot').each(function() {
            try { window.Plotly.Plots.resize(this); } catch (err) {}
          });
        }
        function adjustAllCountryDetailDataTables() {
          if (!window.jQuery || !window.jQuery.fn || !window.jQuery.fn.dataTable) return;
          window.jQuery('#country_details_content table, #country_details_panels table').each(function() {
            try {
              if (window.jQuery.fn.dataTable.isDataTable(this)) {
                window.jQuery(this).DataTable().columns.adjust().draw(false);
              }
            } catch (err) {}
          });
        }
        window.jQuery(document).on('shiny:value', function(e) {
          if (!e.target || !e.target.id) return;
          var id = e.target.id;
          // uiOutput rebuild: replot after DOM swap (Plotly often first-paints at 0×0 inside scroll/collapse)
          if (id === 'country_details_content') {
            [200, 500, 900].forEach(function(ms) {
              setTimeout(function() {
                resizeAllCountryDetailPlots();
                adjustAllCountryDetailDataTables();
              }, ms);
            });
            return;
          }
          if (id !== 'vulnerability_trend_chart' && id !== 'country_factor_contribution_chart' &&
              id !== 'country_data_table' && id !== 'country_breakdown_body' &&
              id !== 'country_insights_body' && id !== 'country_summary_body' &&
              id !== 'country_history_table_body') return;
          var $box = window.jQuery(e.target).closest('#country_details_content .box, #country_details_panels .box');
          if ($box.length && !$box.hasClass('collapsed-box')) {
            refreshOutputsInCountryBox($box[0]);
          }
        });
        function toggleRegressionNearZero(el) {
          var $el = window.jQuery(el);
          if ($el.hasClass('regression-near-zero--revealed')) {
            $el.text('~0').removeClass('regression-near-zero--revealed')
              .attr('title', 'Click to show exact value');
          } else {
            $el.text($el.attr('data-full')).addClass('regression-near-zero--revealed')
              .attr('title', 'Click to hide exact value');
          }
        }
        window.jQuery(document).on('click', '.regression-near-zero', function(e) {
          e.preventDefault();
          toggleRegressionNearZero(this);
        });
        window.jQuery(document).on('keydown', '.regression-near-zero', function(e) {
          if (e.key !== 'Enter' && e.key !== ' ') return;
          e.preventDefault();
          toggleRegressionNearZero(this);
        });
        if (window.Shiny && window.Shiny.addCustomMessageHandler) {
          window.Shiny.addCustomMessageHandler('country_detail_reset_panels', function(message) {
            window.jQuery('#country_details_panels .box').each(function() {
              setCountryBoxCollapsed(window.jQuery(this), true);
            });
          });
          window.Shiny.addCustomMessageHandler('country_detail_resize_plots', function(message) {
            [200, 600, 1200].forEach(function(ms) {
              setTimeout(function() {
                resizeAllCountryDetailPlots();
                adjustAllCountryDetailDataTables();
              }, ms);
            });
          });
        }
      })();
    "))
  ),

  conditionalPanel(
    condition = "input.tabs != 'introduction'",
    tags$div(
      class = "site-brand-preview",
      tags$a(
        href = "#shiny-tab-introduction",
        title = "Back to Introduction",
        tags$img(
          src = "assets/og-social-preview.png",
          alt = "Global Hunger Vulnerability Dashboard"
        )
      )
    )
  ),

  tabItems(
    # Introduction Tab (Landing Page)
    tabItem(
      tabName = "introduction",
      fluidRow(
        box(
          title = "Global Hunger Research Project", 
          status = "primary", 
          solidHeader = TRUE,
          width = 12,
          tags$div(
            style = "font-size: 16px; line-height: 1.8; padding: 20px;",
            tags$div(
              class = "intro-preview-hero",
              tags$img(
                src = "assets/og-social-preview.png",
                alt = "Global Hunger Vulnerability Dashboard — interactive food security research across countries"
              )
            ),
            tags$h2("Understanding Global Hunger: A Comprehensive Research Initiative", 
                   style = "color: #2c3e50; margin-bottom: 20px;"),
            tags$h3("Why this dashboard exists", style = "color: #3c8dbc; margin-top: 24px; margin-bottom: 12px;"),
            tags$p(
              "Hunger is rarely caused by one thing. This dashboard brings together economic, health, climate, and crisis indicators so you can explore how they relate to food insecurity across the world.",
              " It’s built for quick exploration and for deeper, country-by-country investigation."
            ),
            tags$p(
              tags$a(href = "/assets/landing.html", target = "_blank", "Read the static overview page"),
              " for a crawlable summary of the dashboard, vulnerability score methodology, and links to key sections."
            ),
            tags$div(
              style = "background-color: #f8f9fa; padding: 16px; border-radius: 8px; border: 1px solid #e9ecef; margin: 18px 0;",
              tags$p(strong("Core research question:"), style = "margin-bottom: 8px;"),
              tags$p(
                strong("What factors drive hunger and hunger outbreaks, and how will these factors change in the future?"),
                style = "font-size: 18px; color: #e74c3c; margin: 0;"
              )
            ),
            tags$h3("Where to start", style = "color: #3c8dbc; margin-top: 24px; margin-bottom: 12px;"),
            tags$ul(
              tags$li(strong("Interactive Map:"), " Explore global patterns and click countries for details."),
              tags$li(strong("Overview:"), " See global distributions, relationships, and top-risk countries."),
              tags$li(strong("Country Details:"), " Review the score breakdown and the latest indicators for a selected country."),
              tags$li(strong("Time Series:"), " Explore how key indicators change over time."),
              tags$li(strong("Data Explorer:"), " Browse the integrated dataset and download views."),
              tags$li(strong("Statistical Analysis:"), " Adaptation buffer research — correlation matrix, OLS models, rankings, and Monte Carlo results.")
            ),
            tags$h3("Hunger Vulnerability Score (0–100)", style = "color: #3c8dbc; margin-top: 24px; margin-bottom: 12px;"),
            tags$p(
              "The Hunger Vulnerability Score is a 0–100 composite that summarizes multiple risk dimensions (food security, poverty, economic capacity, health, climate vulnerability, and crisis exposure).",
              " For a full component-by-component breakdown, see ", tags$strong("Country Details"), "."
            ),
            tags$h3("Data Sources", style = "color: #3c8dbc; margin-top: 24px; margin-bottom: 12px;"),
            tags$p(
              "All dataset citations and short descriptions are listed on the ",
              tags$strong("Data Sources"),
              " page."
            ),
            
            tags$h3("Research Context", style = "color: #3c8dbc; margin-top: 30px; margin-bottom: 15px;"),
            tags$p("Hunger and food insecurity remain among the most significant challenges facing humanity. Despite global progress in reducing poverty and improving food production, millions of people worldwide still experience chronic hunger, and acute food crises continue to emerge in various regions."),
            tags$p("This research project aims to contribute to the global effort to understand and address hunger by:"),
            tags$ul(
              tags$li("Providing a comprehensive, data-driven assessment of hunger vulnerability"),
              tags$li("Identifying countries and regions at highest risk"),
              tags$li("Highlighting the multi-faceted nature of hunger (economic, health, climate, conflict)"),
              tags$li("Enabling evidence-based policy decisions and resource allocation")
            ),
            
            tags$h3("A quick note on missing data", style = "color: #3c8dbc; margin-top: 24px; margin-bottom: 12px;"),
            tags$div(
              style = "background-color: #fff3cd; padding: 16px; border-left: 4px solid #ffc107; border-radius: 4px; margin: 12px 0;",
              tags$p(
                style = "margin: 0; font-size: 14px;",
                strong("Note: "),
                "Some indicators may be missing or lagged for certain countries. Interpret scores as relative risk signals and use local context when making decisions."
              )
            ),
            
            tags$hr(style = "margin: 30px 0;"),
            tags$div(
              style = "text-align: center; color: #7f8c8d; font-size: 14px;",
              tags$p(strong("Author:"), " Garrett Zhou"),
              tags$p(strong("Project:"), " Global Hunger Research - 2024"),
              tags$p(strong("Last Updated:"), format(Sys.Date(), "%B %Y"))
            )
          )
        )
      )
    ),
    
    # Overview Tab
    tabItem(
      tabName = "overview",
      fluidRow(
        class = "overview-kpi-row",
        valueBoxOutput("total_countries", width = 4),
        valueBoxOutput("total_population", width = 4),
        valueBoxOutput("high_risk_countries", width = 4)
      ),
      fluidRow(
        column(
          12,
          tags$div(
            class = "overview-section-head",
            tags$h4("Risk summary"),
            tags$p("Distribution of countries across vulnerability tiers (left) and the five most vulnerable countries with scores above 50 (right). Interactive map filters do not apply on this tab.")
          )
        )
      ),
      fluidRow(
        box(
          title = tagList(
            "Countries by vulnerability tier",
            tags$br(),
            tags$small(
              style = "color:#64748b;font-weight:400;font-size:12px;",
              "Not affected by vulnerability or statistic filters on the map."
            )
          ),
          status = "primary",
          solidHeader = TRUE,
          width = 6,
          plotlyOutput("hunger_risk_plot", height = "340px")
        ),
        box(
          title = tagList(
            "Top 5 most vulnerable countries",
            tags$br(),
            tags$small(
              style = "color:#64748b;font-weight:400;font-size:12px;",
              "Highest scores among countries above 50; not affected by map filters."
            )
          ),
          status = "primary",
          solidHeader = TRUE,
          width = 6,
          DT::dataTableOutput("top_risk_table")
        )
      ),
      fluidRow(
        column(
          12,
          tags$div(
            class = "overview-section-head",
            tags$h4("Cross-country relationships"),
            tags$p("Each point is a country. Choose the outcome (Y), predictor (X), and axis scale; the scatter, least-squares line, and equation update automatically. Interactive map filters do not apply.")
          )
        )
      ),
      fluidRow(
        box(
          title = "Indicator scatter plot",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          tags$div(
            class = "overview-scatter-toolbar",
            tags$div(
              class = "overview-scatter-control",
              tags$label(`for` = "overview_scatter_y", "Y-axis (outcome)"),
              selectInput(
                "overview_scatter_y",
                NULL,
                choices = c(
                  "Undernourishment (%)" = "undernourishment_rate",
                  "Vulnerability score (0–100)" = "hunger_vulnerability_rating"
                ),
                selected = "undernourishment_rate",
                width = "240px"
              )
            ),
            tags$div(
              class = "overview-scatter-control",
              tags$label(`for` = "overview_scatter_x", "X-axis (predictor)"),
              selectInput(
                "overview_scatter_x",
                NULL,
                choices = c(
                  "Population" = "population",
                  "Agricultural land (%)" = "agriculture_land",
                  "GDP per capita (US$)" = "gdp_per_capita",
                  "Poverty rate (%)" = "poverty_display",
                  "Life expectancy (years)" = "life_expectancy",
                  "Global Hunger Index" = "ghi_score",
                  "Climate vulnerability index" = "climate_vulnerability_index"
                ),
                selected = "population",
                width = "240px"
              )
            ),
            conditionalPanel(
              condition = "input.overview_scatter_x == 'population' || input.overview_scatter_x == 'gdp_per_capita'",
              tags$div(
                class = "overview-scatter-control",
                tags$label(`for` = "overview_scatter_xscale", "X-axis scale"),
                selectInput(
                  "overview_scatter_xscale",
                  NULL,
                  choices = c("Linear" = "linear", "log₂" = "log2", "log e" = "loge", "log₁₀" = "log10"),
                  selected = "linear",
                  width = "140px"
                )
              )
            )
          ),
          plotlyOutput("overview_scatter_plot", height = "420px"),
          uiOutput("overview_scatter_note")
        )
      ),
      fluidRow(
        column(
          12,
          tags$div(
            class = "overview-section-head",
            tags$h4("Score distribution (full dataset)"),
            tags$p("Histogram uses all countries in the integrated dataset (not only filtered rows) for a stable global reference.")
          )
        )
      ),
      fluidRow(
        box(
          title = "Vulnerability score — global histogram",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput("overview_vulnerability_plot", height = "320px")
        )
      )
    ),
    
    # Data Explorer Tab
    tabItem(
      tabName = "explorer",
      fluidRow(
        box(
          title = page_tab_header("Data Explorer", "Explore all integrated datasets", "database"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          collapsible = FALSE,
          tabsetPanel(
            type = "tabs",
            id = "explorer_tabs",
            tabPanel(
              title = tags$span(icon("table"), " Data Table"),
              value = "data_table_tab",
              br(),
              fluidRow(
                column(12,
                  tags$div(
                    style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 15px; border-radius: 5px; margin-bottom: 15px; color: white;",
                    tags$h4(icon("info-circle"), " Complete Dataset", style = "margin: 0; color: white;"),
                    tags$p("Scroll horizontally to view all columns. Use filters to search and sort. Download as CSV or Excel.", 
                           style = "margin: 5px 0 0 0; color: rgba(255,255,255,0.9);")
                  )
                )
              ),
              fluidRow(
                column(12,
                  DT::dataTableOutput("data_table_full", height = "600px")
                )
              )
            ),
            tabPanel(
              title = tags$span(icon("chart-line"), " Interactive Visualizations"),
              value = "visualizations_tab",
              br(),
              fluidRow(
                column(12,
                  tags$div(
                    class = "explorer-viz-banner",
                    tags$h4(icon("chart-bar"), " Statistical visualizations", style = "margin: 0;"),
                    tags$p(
                      "Distribution histograms for key indicators. Hover a bar for bin details; use the camera icon to download a chart.",
                      style = "margin: 8px 0 0 0;"
                    )
                  )
                )
              ),
      fluidRow(
        box(
                  title = tags$span(icon("chart-bar"), " Distribution overview"),
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  collapsible = TRUE,
                  class = "explorer-viz-panel",
                  fluidRow(
                    column(6,
                      tags$div(class = "explorer-plot-card", plotlyOutput("summary_population_plot", height = "340px"))
                    ),
                    column(6,
                      tags$div(class = "explorer-plot-card", plotlyOutput("summary_gdp_plot", height = "340px"))
                    )
                  ),
                  br(),
                  fluidRow(
                    column(6,
                      tags$div(class = "explorer-plot-card", plotlyOutput("summary_poverty_plot", height = "340px"))
                    ),
                    column(6,
                      tags$div(class = "explorer-plot-card", plotlyOutput("summary_life_expectancy_plot", height = "340px"))
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = tags$span(icon("chart-pie"), " Additional indicators"),
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  collapsible = TRUE,
                  class = "explorer-viz-panel",
                  fluidRow(
                    column(6,
                      tags$div(class = "explorer-plot-card", plotlyOutput("summary_agriculture_plot", height = "340px"))
                    ),
                    column(6,
                      tags$div(class = "explorer-plot-card", plotlyOutput("summary_vulnerability_plot", height = "340px"))
                    )
                  ),
                  br(),
                  fluidRow(
                    column(6,
                      tags$div(class = "explorer-plot-card", plotlyOutput("summary_undernourishment_plot", height = "340px"))
                    ),
                    column(6,
                      tags$div(class = "explorer-plot-card", plotlyOutput("summary_infant_mortality_plot", height = "340px"))
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = tags$span(icon("table"), " Summary Statistics Table"),
          status = "info",
          solidHeader = TRUE,
          width = 12,
                  collapsible = TRUE,
                  DT::dataTableOutput("summary_stats_table", height = "400px")
                )
              )
            )
          )
        )
      )
    ),
    
    # Interactive Map Tab
    tabItem(
      tabName = "map",
      fluidRow(
        column(
          12,
          tags$section(
            class = "seo-intro-block",
            tags$h1("Global Hunger Vulnerability Map"),
            tags$h2("Explore food security risk by country"),
            tags$p(
              "This interactive global hunger vulnerability map shows how countries compare on a composite ",
              "food-security risk score from 0 to 100. Each country is colored by its hunger vulnerability ",
              "rating, which combines undernourishment, poverty, income, health, climate exposure, conflict, ",
              "and other structural indicators drawn from FAO, World Bank, and humanitarian data sources."
            ),
            tags$p(
              "Hover over a country to see its name, vulnerability score, population, and total land area. ",
              "Click a country to open its detailed hunger profile. Use the score multipliers below the map ",
              "to test how sensitive rankings are to each pillar, or apply map filters to focus on specific ",
              "years, score ranges, and economic or health statistics."
            ),
            tags$p(
              "The map is designed for quick global comparison and for identifying countries that may warrant ",
              "deeper review in the Country Details section, where you can inspect score drivers, trends over ",
              "time, and the full indicator set behind each vulnerability rating."
            )
          )
        )
      ),
      fluidRow(
        box(
          title = tagList(icon("book"), " How the vulnerability score is calculated (same rules as country profiles)"),
          status = "info",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          collapsed = TRUE,
          tags$p(
            style = "font-size: 13px; color: #334155; margin-bottom: 14px; line-height: 1.55;",
            "Read this while you explore the map. The score has ",
            tags$strong("twelve parts"),
            ". Each part adds points toward a total from 0 to 100. The final score is the sum of all parts, ",
            tags$strong("capped at 100"),
            " ",
            tags$span(style = "color: #64748b;", "(Formula: ", tags$code("min(100, sum of all pillars)"), "). "),
            tags$strong("Part multipliers"),
            " (below the map) change how much each part counts on ",
            tags$em("this map only"),
            ": multiplier 1 = published weights, 0 = that part turned off, 2 = double that part’s points."
          ),
          tags$div(
            style = "font-size: 13px; background: #f8fafc; padding: 16px 18px; border-radius: 8px; border: 1px solid #e2e8f0; line-height: 1.65; color: #0f172a;",
            tags$ol(
              style = "margin: 0; padding-left: 22px;",
              tags$li(
                tags$strong("Undernourishment (maximum 25 points): "),
                "Multiply the percentage of people who are undernourished by 0.25, then cap at 25. If undernourishment data are missing, use the poverty percentage the same way.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("min(PoU% × 0.25, 25); if PoU missing, min(poverty% × 0.25, 25)"))
              ),
              tags$li(
                tags$strong("Poverty (maximum 8 points): "),
                "Multiply the poverty percentage by 0.16, then cap at 8. Poverty uses the World Bank $1.90-per-day line or, when needed, the Our World in Data $3-per-day line.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("min(poverty% × 0.16, 8) (WB $1.90 or OWID $3 line)"))
              ),
              tags$li(
                tags$strong("Income per person (maximum 7 points): "),
                "Points depend on gross domestic product per person in United States dollars: below $1,000 → 7 points; below $3,000 → 5 points; below $10,000 → 3 points; below $20,000 → 1 point.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("GDP per-capita USD buckets — under 1k→7, under 3k→5, under 10k→3, under 20k→1"))
              ),
              tags$li(
                tags$strong("Life expectancy (maximum 5 points): "),
                "If life expectancy is under 50 years, add 5 points; under 60 years, add 4 points; under 70 years, add 2 points.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("under 50y→5, under 60→4, under 70→2"))
              ),
              tags$li(
                tags$strong("Child stunting (maximum 5 points): "),
                "Multiply the child stunting percentage by 0.05, then cap at 5.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("min(stunting% × 0.05, 5)"))
              ),
              tags$li(
                tags$strong("Climate vulnerability (maximum 10 points): "),
                "If the climate vulnerability index is at least 60, add 3 points; at least 70, add 7 points; at least 80, add 10 points.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("vulnerability index 60/70/80 thresholds → 3 / 7 / 10 pts"))
              ),
              tags$li(
                tags$strong("Conflict intensity (maximum 10 points): "),
                "If there is active conflict: very high intensity adds 10 points, high adds 7, medium adds 4, low adds 2.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("if active — Very High→10, High→7, Medium→4, Low→2"))
              ),
              tags$li(
                tags$strong("Major hunger crises and food security phase (maximum 15 points): "),
                "Add 15 points if the country had a major hunger crisis in the 21st century or is in food security phase 4 or higher. Add 8 points if it is in food security phase 3.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("major 21st-c. hunger crisis OR IPC phase 4+→15; phase 3→8"))
              ),
              tags$li(
                tags$strong("Food import dependency (maximum 5 points): "),
                "Points increase when average food import share reaches 50%, 30%, or 20% thresholds.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("avg food import share tiers (50% / 30% / 20%)"))
              ),
              tags$li(
                tags$strong("Food supply (maximum 5 points): "),
                "Points increase when daily food supply per person falls below 2,400, below 2,200, or below 2,000 calories.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("kcal/cap/day under 2000 / 2200 / 2400"))
              ),
              tags$li(
                tags$strong("Water stress (maximum 5 points): "),
                "Points increase when renewable water per person falls below 1,700, below 1,000, or below 500 cubic meters per year.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("renewable m³/cap under 500 / 1000 / 1700"))
              ),
              tags$li(
                style = "margin-bottom: 0;",
                tags$strong("Forced displacement (maximum 5 points): "),
                "Points are based on refugees and internally displaced people, using either their share of the population or absolute numbers.",
                tags$br(), tags$span(style = "color: #64748b;", "Formula: ", tags$code("refugees/IDPs as share of population or absolute size tiers"))
              )
            )
          )
        )
      ),
      fluidRow(
        box(
          title = "Global Hunger Vulnerability Map (0-100 Scale)",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput("hunger_map", height = "620px")
        )
      ),
      fluidRow(
        box(
          title = tagList(icon("sliders-h"), " Score part multipliers"),
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          collapsed = FALSE,
          tags$p(
            style = "font-size: 13px; color: #334155; margin-bottom: 14px; line-height: 1.55;",
            tags$strong("Map score shown"),
            " = sum of (multiplier × points for each part), capped at 100 ",
            tags$span(style = "color: #64748b;", "(Formula: ", tags$code("min(100, Σ (multiplier × pillar points))"), "). "),
            tags$strong("Multiplier 1"),
            " on every slider matches the ",
            tags$em("published"),
            " score. ",
            tags$strong("0"),
            " turns a part off on this map; ",
            tags$strong("2"),
            " doubles that part. Country profile pages always use the published score."
          ),
          fluidRow(
            column(3, sliderInput("map_w_undernourishment", "Undernourishment (max 25)", 0, 2, 1, 0.05)),
            column(3, sliderInput("map_w_poverty", "Poverty (max 8)", 0, 2, 1, 0.05)),
            column(3, sliderInput("map_w_gdp", "Income per person (max 7)", 0, 2, 1, 0.05)),
            column(3, sliderInput("map_w_life_expectancy", "Life expectancy (max 5)", 0, 2, 1, 0.05))
          ),
          fluidRow(
            column(3, sliderInput("map_w_stunting", "Child stunting (max 5)", 0, 2, 1, 0.05)),
            column(3, sliderInput("map_w_climate", "Climate vulnerability (max 10)", 0, 2, 1, 0.05)),
            column(3, sliderInput("map_w_conflict", "Conflict intensity (max 10)", 0, 2, 1, 0.05)),
            column(3, sliderInput("map_w_outbreak", "Major hunger crises (max 15)", 0, 2, 1, 0.05))
          ),
          fluidRow(
            column(3, sliderInput("map_w_trade", "Food import dependency (max 5)", 0, 2, 1, 0.05)),
            column(3, sliderInput("map_w_food_supply", "Food supply (max 5)", 0, 2, 1, 0.05)),
            column(3, sliderInput("map_w_water", "Water stress (max 5)", 0, 2, 1, 0.05)),
            column(3, sliderInput("map_w_displacement", "Forced displacement (max 5)", 0, 2, 1, 0.05))
          ),
          fluidRow(
            column(6, actionButton("map_formula_reset", "Reset all multipliers to 1", class = "btn-info", style = "margin-top: 8px; width: 100%;")),
            column(6, actionButton("map_formula_max", "Set all multipliers to 2", class = "btn-warning", style = "margin-top: 8px; width: 100%;"))
          )
        )
      ),
      fluidRow(
        box(
          title = tagList(icon("filter"), " Map Filters"),
          status = "info",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          collapsed = TRUE,
          tags$p(
            style = "font-size: 13px; color: #334155; margin-bottom: 14px; line-height: 1.55;",
            "Limit which countries appear on the map. Countries missing a selected statistic may be hidden when that filter is enabled."
          ),
          sliderInput(
            "year_range",
            "Latest Data Year:",
            min = 2000,
            max = .map_year_slider_max,
            value = c(2015, .map_year_slider_max),
            step = 1
          ),
          sliderInput(
            "vulnerability_range",
            "Vulnerability Score:",
            min = 0,
            max = 100,
            value = c(0, 100),
            step = 5
          ),
          selectInput(
            "map_active_filters",
            "Map Filters:",
            choices = c(
              "GDP per Capita" = "gdp_per_capita",
              "Poverty Rate" = "poverty",
              "Life Expectancy" = "life_expectancy",
              "Undernourishment" = "undernourishment_rate",
              "Infant Mortality" = "infant_mortality",
              "Agricultural Land" = "agriculture_land"
            ),
            selected = c("gdp_per_capita"),
            multiple = TRUE
          ),
          conditionalPanel(
            condition = "input.map_active_filters && input.map_active_filters.indexOf('gdp_per_capita') !== -1",
            sliderInput(
              "map_gdp_per_capita_range",
              "GDP per Capita ($):",
              min = 0,
              max = 250000,
              value = c(0, 250000),
              step = 500
            )
          ),
          conditionalPanel(
            condition = "input.map_active_filters && input.map_active_filters.indexOf('poverty') !== -1",
            sliderInput(
              "map_poverty_range",
              "Poverty Rate (%):",
              min = 0,
              max = 60,
              value = c(0, 60),
              step = 1
            )
          ),
          conditionalPanel(
            condition = "input.map_active_filters && input.map_active_filters.indexOf('life_expectancy') !== -1",
            sliderInput(
              "map_life_expectancy_range",
              "Life Expectancy (years):",
              min = 40,
              max = 90,
              value = c(40, 90),
              step = 1
            )
          ),
          conditionalPanel(
            condition = "input.map_active_filters && input.map_active_filters.indexOf('undernourishment_rate') !== -1",
            sliderInput(
              "map_undernourishment_range",
              "Undernourishment (%):",
              min = 0,
              max = 60,
              value = c(0, 60),
              step = 1
            )
          ),
          conditionalPanel(
            condition = "input.map_active_filters && input.map_active_filters.indexOf('infant_mortality') !== -1",
            sliderInput(
              "map_infant_mortality_range",
              "Infant Mortality (per 1,000):",
              min = 0,
              max = 120,
              value = c(0, 120),
              step = 2
            )
          ),
          conditionalPanel(
            condition = "input.map_active_filters && input.map_active_filters.indexOf('agriculture_land') !== -1",
            sliderInput(
              "map_agriculture_land_range",
              "Agricultural Land (%):",
              min = 0,
              max = 90,
              value = c(0, 90),
              step = 1
            )
          )
        )
      ),
      fluidRow(
        box(
          title = "Map Legend",
          status = "info",
          solidHeader = TRUE,
          width = 6,
          tags$div(
            style = "font-size: 14px;",
            tags$p(strong("Vulnerability Score (0-100):")),
            tags$p("🟢 0-25: Low Vulnerability (Green)"),
            tags$p("🟡 25-50: Moderate Vulnerability (Yellow)"),
            tags$p("🟠 50-75: High Vulnerability (Orange)"),
            tags$p("🔴 75-100: Critical Vulnerability (Red)"),
            br(),
            tags$p(strong("Note:"), " Map colors use the multipliers under the map; hover shows the vulnerability score and each formula pillar. Countries excluded by filters remain as outlines only (no fill or hover).")
          )
        ),
        
        box(
          title = "Instructions",
          status = "success",
          solidHeader = TRUE,
          width = 6,
          tags$div(
            style = "font-size: 14px;",
            tags$p(strong("How to use this map:")),
            tags$p("1. Use the formula box at the top for coefficients; adjust multipliers under the map to explore."),
            tags$p("2. Hover over countries for stats and the map score."),
            tags$p("3. Click a country for the full country profile."),
            tags$p("4. Use the sidebar to pick countries; open Map Filters below the multipliers for year, score, and statistic filters."),
            tags$p("5. Green → red = lower → higher displayed vulnerability.")
          )
        )
      )
    ),

    tabItem(
      tabName = "scenario_lab",
      fluidRow(
        box(
          title = tagList(icon("globe-americas"), " Your scenario — country landscape"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          fluidRow(
            column(
              4,
              selectInput(
                "sc_vis_shape",
                "Country shape (cosmetic only)",
                choices = scenario_country_shape_choices(),
                selected = "continental"
              )
            )
          ),
          uiOutput("scenario_country_silhouette")
        )
      ),
      fluidRow(
        box(
          title = tagList(icon("map-pin"), " Imaginary country — inputs"),
          status = "primary",
          solidHeader = TRUE,
          width = 6,
          tags$p(
            style = "font-size: 13px; color: #475569;",
            "Set raw statistics as if this were a single country. Pillars use the same rules and coefficients as the dashboard. Multipliers (right) scale each pillar’s points: ×1 = published index, ×0 = off, ×2 = double."
          ),
          sliderInput("sc_undernourishment", "Prevalence of undernourishment (%)", 0, 60, 0, 0.5),
          sliderInput("sc_poverty", "Poverty rate (% $1.90 line, or similar)", 0, 80, 0, 1),
          sliderInput("sc_gdp_pc", "GDP per capita (US$)", 0, 80000, 20000, 500),
          sliderInput("sc_life_exp", "Life expectancy (years)", 40, 90, 75, 0.5),
          sliderInput("sc_stunting", "Child stunting rate (%)", 0, 60, 0, 0.5),
          sliderInput("sc_climate", "Climate vulnerability index (0–100)", 0, 100, 30, 1),
          selectInput(
            "sc_conflict",
            "Conflict (intensity if active)",
            choices = c("None" = "None", "Low" = "Low", "Medium" = "Medium", "High" = "High", "Very High" = "Very High"),
            selected = "None"
          ),
          checkboxInput("sc_has_conflict", "Active conflict", value = FALSE),
          tags$p(style = "font-size: 11px; color: #64748b; margin: -6px 0 10px 0;", "Conflict points apply only when this is checked."),
          checkboxInput("sc_outbreak", "Major hunger outbreak (21st c.)", value = FALSE),
          sliderInput("sc_import_share", "Avg food import share (0–1)", 0, 1, 0.1, 0.01),
          sliderInput("sc_food_kcal", "Food supply (kcal/cap/day)", 1500, 4000, 2800, 10),
          sliderInput("sc_water", "Renewable water (m³/cap/year)", 0, 15000, 5000, 50),
          sliderInput("sc_pop_m", "Population (millions)", 0.1, 1500, 10, 0.1),
          sliderInput("sc_displaced_k", "Displaced people (thousands)", 0, 50000, 0, 10)
        ),
        box(
          title = tagList(icon("sliders-h"), " Pillar multipliers & result"),
          status = "info",
          solidHeader = TRUE,
          width = 6,
          tags$p(
            style = "font-size: 12px; color: #64748b; margin-bottom: 12px;",
            tags$strong("Displayed score"),
            " = ",
            tags$code("min(100, Σ multiplier × pillar)"),
            ". Default ×1 matches the published formula (same coefficients as the Map tab reference box)."
          ),
          sliderInput("sc_w_undernourishment", "Undernourishment pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_poverty", "Poverty pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_gdp", "GDP pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_life_expectancy", "Life expectancy pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_stunting", "Stunting pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_climate", "Climate pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_conflict", "Conflict pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_outbreak", "Outbreak pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_trade", "Trade pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_food_supply", "Food supply pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_water", "Water stress pillar", 0, 2, 1, 0.05),
          sliderInput("sc_w_displacement", "Displacement pillar", 0, 2, 1, 0.05),
          actionButton("sc_formula_reset", "Reset all multipliers to ×1", class = "btn-info btn-sm", style = "width: 100%; margin-bottom: 12px;"),
          uiOutput("scenario_score_ui"),
          plotlyOutput("scenario_component_plot", height = "320px")
        )
      )
    ),
    
    # Country Details Tab
    tabItem(
      tabName = "country_details",
      fluidRow(
        column(
          12,
          tags$section(
            class = "seo-intro-block",
            tags$h1("Country Hunger Profile"),
            tags$h2("Deep-dive food security indicators by country"),
            tags$p(
              "The country hunger profile page lets you search any country and review its full vulnerability ",
              "picture in one place. After selecting a country, you can explore how its hunger vulnerability ",
              "score is built from twelve pillars, including undernourishment, poverty, GDP per capita, life ",
              "expectancy, stunting, climate vulnerability, conflict, hunger crises, trade dependency, food ",
              "supply, water stress, and displacement."
            ),
            tags$p(
              "Each profile includes a score breakdown chart, key insights, vulnerability trends over time, ",
              "the main factors driving the total score, a current-year summary, and a historical data table. ",
              "This makes it easier to move from a global map view to country-specific analysis and to compare ",
              "structural drivers of food insecurity across regions."
            ),
            tags$p(
              "Use the search box below to choose a country. Profiles use the published default vulnerability ",
              "formula so scores remain consistent with the map and overview pages unless you adjust multipliers ",
              "on the Interactive Map tab for scenario exploration."
            )
          )
        )
      ),
      fluidRow(
        tags$div(class = "country-details-select-wrapper",
          box(
            title = "Select Country",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(10, selectizeInput(
                "selected_country",
                "Search or choose a country:",
                choices = c("Select a country..." = "", sort(unique(latest_summary$country))),
                selected = "",
                width = "100%",
                options = list(placeholder = "Type to search...", maxOptions = 500)
              )),
              column(2, br(), actionButton("clear_country", "Clear", icon = icon("times"), style = "margin-top: 25px;", title = "Clear selection to search again"))
            ),
            tags$p(style = "margin-top: 4px; font-size: 12px; color: #666;", "Click Clear to delete the search and type a new country name.")
          )
        )
      ),
      uiOutput("country_details_content"),
      conditionalPanel(
        condition = "input.selected_country != '' && input.selected_country != 'Select a country...' && output.country_details_has_data",
        tags$div(
          id = "country_details_panels",
          class = "country-details-collapsible-wrapper",
          fluidRow(
            box(
              title = tags$span(icon("chart-pie"), " Vulnerability score breakdown"),
              status = "primary",
              solidHeader = TRUE,
              width = 6,
              class = "country-detail-panel",
              collapsible = TRUE,
              collapsed = TRUE,
              uiOutput("country_breakdown_body")
            ),
            box(
              title = tags$span(icon("lightbulb"), " Key insights"),
              status = "primary",
              solidHeader = TRUE,
              width = 6,
              class = "country-detail-panel",
              collapsible = TRUE,
              collapsed = TRUE,
              uiOutput("country_insights_body")
            ),
            box(
              title = tags$span(icon("chart-line"), " Vulnerability over time"),
              status = "primary",
              solidHeader = TRUE,
              width = 6,
              class = "country-detail-panel country-detail-chart",
              collapsible = TRUE,
              collapsed = TRUE,
              tags$div(class = "country-chart-slot", plotlyOutput("vulnerability_trend_chart", height = "300px")),
              tags$p(class = "overview-caption", style = "margin-top: 10px; margin-bottom: 0;", "Based on indicators available by year. Not every score component has a full time series.")
            ),
            box(
              title = tags$span(icon("chart-bar"), " Main score drivers"),
              status = "primary",
              solidHeader = TRUE,
              width = 6,
              class = "country-detail-panel country-detail-chart",
              collapsible = TRUE,
              collapsed = TRUE,
              tags$div(class = "country-chart-slot", plotlyOutput("country_factor_contribution_chart", height = "320px")),
              tags$p(class = "overview-caption", style = "margin-top: 10px; margin-bottom: 0;", "Share of each factor in the total score. Zero-weight factors are omitted.")
            ),
            box(
              title = tags$span(icon("calendar-alt"), " Current year summary"),
              status = "primary",
              solidHeader = TRUE,
              width = 6,
              class = "country-detail-panel",
              collapsible = TRUE,
              collapsed = TRUE,
              uiOutput("country_summary_body")
            ),
            box(
              title = tags$span(icon("table"), " Historical time series"),
              status = "primary",
              solidHeader = TRUE,
              width = 12,
              class = "country-detail-panel",
              `data-panel-id` = "history_table",
              collapsible = TRUE,
              collapsed = TRUE,
              uiOutput("country_history_table_body")
            )
          )
        )
      )
    ),
    
    tabItem(
      tabName = "bangladesh_research",
      fluidRow(
        column(
          12,
          tags$section(
            class = "seo-intro-block",
            tags$h1("Bangladesh Climate Change & Food Security Research"),
            tags$h2("North Carolina Youth Institute and World Food Prize paper"),
            tags$p(
              "This page shares my research on how climate stressors — floods, cyclones, sea-level rise, ",
              "and salinity intrusion — interact with food security in Bangladesh. I developed the work for ",
              "the North Carolina Youth Institute / World Food Prize program, combining narrative evidence ",
              "from the Ganges–Brahmaputra–Meghna delta with cross-country regression, Bangladesh time-series ",
              "analysis, and a policy optimization model for nutrition and climate-resilient agriculture."
            ),
            tags$p(
              "The research asks how climate vulnerability relates to undernourishment globally, what that ",
              "implies for Bangladesh specifically, and which interventions — school feeding, saline-tolerant ",
              "rice, storage, irrigation, and early warning — offer the strongest returns under realistic ",
              "budget and political constraints. Open ",
              tags$a(href = "?tab=country_details", "Country Details"),
              " and select Bangladesh to compare dashboard indicators with the paper findings."
            )
          )
        )
      ),
      fluidRow(
        box(
          title = "Bangladesh, Climate Change & Food Security",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          tags$p(
            style = "font-size: 15px; line-height: 1.7; color: #333;",
            "I prepared this page to share my ",
            strong("North Carolina Youth Institute / World Food Prize"),
            " research on how climate stressors interact with food security in Bangladesh — a densely populated delta where I focused on floods, cyclones, and sea-level rise."
          )
        )
      ),
      fluidRow(
        box(
          title = tags$span(icon("camera"), " NC Youth Institute — Conference photos"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          tags$p(
            style = "font-size: 14px; line-height: 1.65; color: #475569; margin: 0 0 12px 0;",
            "Photos from my North Carolina Youth Institute / World Food Prize conference presentation. Click any image to open it full size."
          ),
          ncyi_gallery_ui()
        )
      ),
      fluidRow(
        box(
          title = tags$span(icon("bullseye"), " Goal"),
          status = "info",
          solidHeader = TRUE,
          width = 6,
          tags$ul(
            style = "font-size: 14px; line-height: 1.75;",
            tags$li("Explain how climate change undermines food security in Bangladesh, using both narrative evidence and quantitative analysis."),
            tags$li("Estimate how climate vulnerability relates to undernourishment across countries, then interpret what that implies for Bangladesh."),
            tags$li("Evaluate policy options — especially nutrition programs and climate-resilient agriculture — and outline a data-informed recommendation for investment priorities.")
          )
        ),
        box(
          title = tags$span(icon("book"), " Background"),
          status = "success",
          solidHeader = TRUE,
          width = 6,
          tags$p(
            style = "font-size: 14px; line-height: 1.75;",
            "Bangladesh sits on the Ganges–Brahmaputra–Meghna delta: extreme monsoon rainfall, river flooding, cyclones, and salinity intrusion threaten crops, drinking water, and livelihoods. Despite progress (e.g. lower undernourishment than a decade ago), the country remains highly exposed; vulnerability can rise quickly after major shocks, with hunger metrics following. The paper connects this geography to a ",
            em("typical family"),
            " narrative, national statistics, and international context (aid, delta planning, and political transitions)."
          )
        )
      ),
      fluidRow(
        box(
          title = tags$span(icon("flask"), " Methodology"),
          status = "warning",
          solidHeader = TRUE,
          width = 6,
          tags$ol(
            style = "font-size: 14px; line-height: 1.75;",
            tags$li(strong("Cross-country regression:"), " Relates climate vulnerability (e.g. ND-GAIN-style index) to national undernourishment rates to quantify the association (paper reports roughly 48% of variation explained in the sample used)."),
            tags$li(strong("Bangladesh time series:"), " Pairs historical climate vulnerability with FAO undernourishment for Bangladesh (2002–2022) to describe periods of stability, shock (e.g. post-Sidr/Aila), and recovery."),
            tags$li(strong("Policy optimization (Model 2):"), " A constrained nonlinear allocation model over ~13 interventions (school feeding, saline- and flood-tolerant rice, AWD irrigation, storage, insurance, early warning, etc.) with diminishing returns, synergy terms, budget caps, and rules such as a BNP funding floor — calibrated to Bangladesh’s approximate caloric deficit and undernourished population.")
          )
        ),
        box(
          title = tags$span(icon("chart-bar"), " Results (high level)"),
          status = "danger",
          solidHeader = TRUE,
          width = 6,
          tags$ul(
            style = "font-size: 14px; line-height: 1.75;",
            tags$li(strong("Regression:"), " A fitted relationship implies that at Bangladesh’s vulnerability level, undernourishment would be higher without strong adaptation and aid; actual undernourishment has remained below that “prediction,” illustrating an adaptation buffer that can shrink after shocks."),
            tags$li(strong("Time series:"), " Vulnerability spiked again in the early 2020s after a long recovery — a warning that headline hunger rates can lag vulnerability."),
            tags$li(strong("Optimization:"), " Under documented assumptions (~18M undernourished, ~700 kcal/day gap, ~4.6 trillion kcal annual deficit, $8B budget, 10-year horizon, synergies), the model allocates heavily to direct nutrition (fortified feeding), saline-tolerant rice, storage, and irrigation-style interventions while respecting policy constraints; BNP-scenario budgets show similar patterns with modest reallocation.")
          ),
          tags$p(style = "font-size: 12px; color: #666; margin-top: 14px;", "Full narrative, citations, and tables are in the project paper and supporting files (e.g. ", tags$code("Garrett Zhou WFP Bangladesh Paper D3.txt"), ", ", tags$code("model2 wfp.md"), ", ", tags$code("model2_results.txt"), ").")
        )
      ),
      fluidRow(
        box(
          title = tags$span(icon("map-marker-alt"), " In this dashboard"),
          width = 12,
          status = "info",
          solidHeader = FALSE,
          tags$p(
            style = "font-size: 14px;",
            "Open ",
            strong("Country Details"),
            " and select ",
            strong("Bangladesh"),
            " to see live indicators (undernourishment, GRFC/IPC, disasters, climate vulnerability, poverty, and more) that complement the paper."
          )
        )
      )
    ),
    
    # GHI Comparison Tab
    tabItem(
      tabName = "ghi_comparison",
      fluidRow(
        # Introduction and Background
        box(
          title = "About the Global Hunger Index (GHI)",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          tags$div(
            style = "font-size: 15px; line-height: 1.8; padding: 20px;",
            tags$h3("What is the Global Hunger Index?", style = "color: #2c3e50; margin-top: 0;"),
            tags$p("The Global Hunger Index (GHI) is a peer-reviewed annual report that comprehensively measures and tracks hunger at the global, regional, and national levels. The GHI is calculated annually by", 
                   tags$a(href = "https://www.ifpri.org/", target = "_blank", "Welthungerhilfe (WHH)"), "and", 
                   tags$a(href = "https://www.concern.net/", target = "_blank", "Concern Worldwide"), 
                   ", with data support from the International Food Policy Research Institute (IFPRI)."),
            tags$p("The GHI was first published in 2006 and has since become one of the most widely recognized tools for measuring hunger worldwide. It provides a standardized way to compare hunger levels across countries and track progress over time."),
            tags$br(),
            tags$h4("Purpose and Background", style = "color: #3c8dbc;"),
            tags$p("The GHI was created to:"),
            tags$ul(
              tags$li("Raise awareness and understanding of the problem of hunger"),
              tags$li("Provide a way to compare hunger levels across countries and regions"),
              tags$li("Track progress in reducing hunger over time"),
              tags$li("Encourage increased attention to and action against hunger"),
              tags$li("Provide policymakers with data to inform decision-making")
            ),
            tags$br(),
            tags$h4("How GHI Works", style = "color: #3c8dbc;"),
            tags$p("The GHI score is calculated using a formula that combines four equally weighted indicators:"),
            tags$div(
              style = "background-color: #e7f3ff; padding: 20px; border-radius: 8px; border-left: 4px solid #0066cc; margin: 15px 0;",
              tags$ul(
                tags$li(strong("Undernourishment (33.3%):"), " The proportion of the population that is undernourished (lacking sufficient caloric intake). This is the primary indicator of hunger."),
                tags$li(strong("Child Wasting (16.7%):"), " The proportion of children under five years old who are wasted (low weight for their height), indicating acute malnutrition."),
                tags$li(strong("Child Stunting (33.3%):"), " The proportion of children under five years old who are stunted (low height for their age), indicating chronic malnutrition."),
                tags$li(strong("Child Mortality (16.7%):"), " The mortality rate of children under five years old, which often reflects the fatal combination of inadequate nutrition and unhealthy environments.")
              )
            ),
            tags$p("The GHI score ranges from 0 to 100, where:"),
            tags$ul(
              tags$li("0-9.9: Low hunger"),
              tags$li("10-19.9: Moderate hunger"),
              tags$li("20-34.9: Serious hunger"),
              tags$li("35-49.9: Alarming hunger"),
              tags$li("50+: Extremely alarming hunger")
            ),
            tags$br(),
            tags$p(strong("Official GHI Website:"), 
                   tags$a(href = "https://www.globalhungerindex.org/", target = "_blank", "https://www.globalhungerindex.org/", 
                          style = "color: #0066cc; text-decoration: underline;"))
          )
        )
      ),
      fluidRow(
        # Comparison Section
        box(
          title = "Our Vulnerability Score vs. GHI: A Detailed Comparison",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          tags$div(
            style = "font-size: 15px; line-height: 1.8; padding: 20px;",
            tags$h4("Methodology Comparison", style = "color: #3c8dbc; margin-top: 0;"),
            tags$div(
              style = "display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 20px 0;",
              tags$div(
                style = "background-color: #fff3cd; padding: 20px; border-radius: 8px; border-left: 4px solid #ffc107;",
                tags$h5("🌍 Our Vulnerability Score", style = "color: #856404; margin-top: 0;"),
                tags$p(strong("Components (12 factors; max points sum to 100):")),
                tags$ul(
                  tags$li("Undernourishment: 25 points (25% of total score)"),
                  tags$li("Poverty and income per person: 15 points (15%)"),
                  tags$li("Life expectancy: 5 points (5%)"),
                  tags$li("Child stunting: 5 points (5%)"),
                  tags$li("Climate vulnerability: 10 points (10%)"),
                  tags$li("Conflict intensity: 10 points (10%)"),
                  tags$li("Historical hunger crises and food security phase: 15 points (15%)"),
                  tags$li("Food import dependency: 5 points (5%)"),
                  tags$li("Natural resources (food supply and water stress): 10 points (10%)")
                ),
                tags$p(strong("Scale:"), " 0-100"),
                tags$p(strong("Focus:"), " Comprehensive multi-factor assessment including economic, social, environmental, and crisis indicators")
              ),
              tags$div(
                style = "background-color: #d1ecf1; padding: 20px; border-radius: 8px; border-left: 4px solid #17a2b8;",
                tags$h5("📊 Global Hunger Index (GHI)", style = "color: #0c5460; margin-top: 0;"),
                tags$p(strong("Components (4 factors):")),
                tags$ul(
                  tags$li("Undernourishment (33.3%)"),
                  tags$li("Child wasting (16.7%)"),
                  tags$li("Child stunting (33.3%)"),
                  tags$li("Child mortality (16.7%)")
                ),
                tags$p(strong("Scale:"), " 0-100"),
                tags$p(strong("Focus:"), " Core nutrition and child health indicators")
              )
            ),
            tags$br(),
            tags$h4("Advantages and Disadvantages", style = "color: #3c8dbc;"),
            tags$div(
              style = "display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 20px 0;",
              tags$div(
                style = "background-color: #d4edda; padding: 20px; border-radius: 8px; border-left: 4px solid #28a745;",
                tags$h5("✅ Advantages of Our Vulnerability Score", style = "color: #155724; margin-top: 0;"),
                tags$ul(
                  tags$li(strong("Comprehensive:"), " Incorporates 12 factors; max points sum to 100, with percentages shown for clarity"),
                  tags$li(strong("Predictive:"), " Includes economic indicators (GDP, poverty) that can predict future vulnerability"),
                  tags$li(strong("Context-aware:"), " Considers conflict and disasters that directly impact food security"),
                  tags$li(strong("Forward-looking:"), " Can identify countries at risk before acute hunger crises occur"),
                  tags$li(strong("Multi-dimensional:"), " Captures economic, social, environmental, and crisis dimensions of hunger")
                )
              ),
              tags$div(
                style = "background-color: #f8d7da; padding: 20px; border-radius: 8px; border-left: 4px solid #dc3545;",
                tags$h5("⚠️ Limitations of Our Vulnerability Score", style = "color: #721c24; margin-top: 0;"),
                tags$ul(
                  tags$li(strong("Complexity:"), " More factors can make interpretation less straightforward"),
                  tags$li(strong("Data dependency:"), " Requires data from multiple sources, some of which may be incomplete"),
                  tags$li(strong("Weighting:"), " Subjective decisions about point allocations for different factors"),
                  tags$li(strong("Less established:"), " Not as widely recognized or validated as GHI"),
                  tags$li(strong("Update frequency:"), " Depends on multiple data sources with different update schedules")
                )
              )
            ),
            tags$div(
              style = "display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 20px 0;",
              tags$div(
                style = "background-color: #d1ecf1; padding: 20px; border-radius: 8px; border-left: 4px solid #17a2b8;",
                tags$h5("✅ Advantages of GHI", style = "color: #0c5460; margin-top: 0;"),
                tags$ul(
                  tags$li(strong("Established:"), " Widely recognized and trusted by policymakers and researchers"),
                  tags$li(strong("Focused:"), " Clear focus on core nutrition indicators"),
                  tags$li(strong("Standardized:"), " Consistent methodology since 2006, allowing for reliable trend analysis"),
                  tags$li(strong("Child-focused:"), " Emphasizes child nutrition, which is critical for long-term development"),
                  tags$li(strong("Peer-reviewed:"), " Annual publication with rigorous methodology review")
                )
              ),
              tags$div(
                style = "background-color: #fff3cd; padding: 20px; border-radius: 8px; border-left: 4px solid #ffc107;",
                tags$h5("⚠️ Limitations of GHI", style = "color: #856404; margin-top: 0;"),
                tags$ul(
                  tags$li(strong("Limited scope:"), " Only four indicators, may miss important contextual factors"),
                  tags$li(strong("Reactive:"), " Primarily measures current hunger rather than predicting future risk"),
                  tags$li(strong("Economic blind spot:"), " Does not directly incorporate economic indicators like GDP or poverty"),
                  tags$li(strong("Crisis factors:"), " Does not account for conflict, disasters, or trade disruptions"),
                  tags$li(strong("Data lag:"), " Annual publication means data may be 1-2 years old")
                )
              )
            ),
            tags$br(),
            tags$div(
              style = "background-color: #e8f4f8; padding: 20px; border-radius: 8px; border-left: 4px solid #3c8dbc; margin-top: 20px;",
              tags$h5("💡 Key Insight", style = "color: #3c8dbc; margin-top: 0;"),
              tags$p("Both measures serve important but complementary purposes. The GHI provides a focused, standardized measure of current hunger levels, while our vulnerability score offers a more comprehensive assessment that includes predictive factors and contextual risks. Using both together provides the most complete picture of a country's food security situation.")
            )
          )
        )
      ),
      fluidRow(
        # Comparison Chart
        box(
          title = "Score Comparison: Our Vulnerability Score vs. GHI",
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput("ghi_comparison_plot", height = "500px")
        )
      ),
      fluidRow(
        # Additional comparison visualizations
        box(
          title = "Score Distribution Comparison",
          status = "success",
          solidHeader = TRUE,
          width = 6,
          plotlyOutput("ghi_distribution_plot", height = "400px")
        ),
        box(
          title = "Score Correlation Analysis",
          status = "info",
          solidHeader = TRUE,
          width = 6,
          plotlyOutput("ghi_correlation_plot", height = "400px")
        )
      )
    ),
    
    # Time Series Tab
    tabItem(
      tabName = "timeseries",
      fluidRow(
        box(
          title = page_tab_header("Time Series Analysis", "Track trends and forecast future values", "chart-line"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          collapsible = FALSE,
          fluidRow(
            column(12,
              tags$div(
                style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 15px; border-radius: 5px; margin-bottom: 15px; color: white;",
                tags$h4(icon("info-circle"), " Interactive Time Series", style = "margin: 0; color: white;"),
                tags$p(
                  "Select a variable to view ",
                  tags$strong("global (World)"),
                  " trends from the World Bank ",
                  tags$em("World"),
                  " aggregate (ISO code WLD)—not a sum or unweighted average of countries. Enable forecasting to see projected values.",
                  style = "margin: 5px 0 0 0; color: rgba(255,255,255,0.9);"
                ),
              tags$div(
                style = "margin-top: 10px; padding: 10px; background: rgba(255,255,255,0.2); border-radius: 5px; font-size: 11px;",
                tags$p(strong("Toolbar Guide:"), style = "margin: 0 0 5px 0;"),
                tags$ul(style = "margin: 0; padding-left: 20px; list-style: none;",
                  tags$li("📷 Camera: Download graph as JPG"),
                  tags$li("🔍 Zoom: Click and drag to zoom, double-click to reset"),
                  tags$li("📊 Pan: Click and drag to pan around"),
                  tags$li("📐 Select: Select data points"),
                  tags$li("↔️ Auto-scale: Reset axes to fit data"),
                  tags$li("📋 Reset axes: Reset to default view")
                )
              )
              )
            )
          ),
          plotlyOutput("timeseries_plot", height = "550px")
        )
      ),
      
      fluidRow(
        box(
          title = tags$span(icon("sliders-h"), " Variable Selection"),
          status = "info",
          solidHeader = TRUE,
          width = 6,
          selectInput(
            "trend_variable",
            "Select Variable:",
            choices = c(
              "Global Population" = "SP.POP.TOTL",
              "GDP (Total)" = "NY.GDP.MKTP.CD",
              "GDP per Capita" = "NY.GDP.PCAP.CD",
              "Poverty Rate" = "SI.POV.DDAY",
              "Life Expectancy" = "SP.DYN.LE00.IN",
              "Infant Mortality" = "SP.DYN.IMRT.IN",
              "Agricultural Land (%)" = "AG.LND.AGRI.ZS",
              "Rural Population (%)" = "SP.RUR.TOTL.ZS",
              "Inflation Rate" = "FP.CPI.TOTL.ZG",
              "Average Vulnerability Score" = "hunger_vulnerability_rating"
            ),
            selected = "SP.POP.TOTL"
          ),
          br(),
          tags$div(
            style = "background: #f0f0f0; padding: 10px; border-radius: 5px; font-size: 12px; color: #666;",
            tags$p(strong("Tip:"), " Select different variables to compare trends across key indicators.")
          )
        ),
        
        box(
          title = tags$span(
            icon("magic"), " Forecast Options ",
            tags$span(
              class = "info-tooltip",
              tags$span(class = "info-icon", style = "cursor: help; font-weight: bold; color: #856404;", "?"),
              tags$span(
                class = "tooltip-text",
                "How it's calculated: Trends are fit on the most recent 15 years (minimum 5 points). Population and total GDP use log-linear (compound) growth; other variables use linear change per year. Each forecast step extends from the latest observed value using that recent trend—not from the full-history regression line—so the dashed line connects to the last data point. Illustrative only, not predictions."
              )
            )
          ),
          status = "warning",
          solidHeader = TRUE,
          width = 6,
          checkboxInput("show_forecast", "Show Forecast", value = FALSE),
          conditionalPanel(
            condition = "input.show_forecast == true",
            sliderInput("forecast_years", "Forecast Years:", min = 1, max = 10, value = 5, step = 1),
            tags$div(
              style = "background: #fff3cd; padding: 10px; border-radius: 5px; margin-top: 10px; font-size: 12px; color: #856404;",
              tags$p(strong("Note:"), " Projections are illustrative, not predictions.")
            )
          )
        )
      )
    ),
    
    # Statistical Analysis Tab
    tabItem(
      tabName = "analysis",
      # Page Header with Background and Purpose
      fluidRow(
        box(
          title = page_tab_header("Statistical Analysis", "Adaptation buffer research — OLS and Monte Carlo results", "calculator"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          collapsible = FALSE,
          tags$div(
            style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 5px; margin-bottom: 20px; color: white;",
            tags$h3(icon("info-circle"), " Background & Purpose", style = "margin: 0 0 15px 0; color: white;"),
            tags$p(
              "This tab presents results from our research paper ",
              tags$em("Climate Vulnerability Does Not Equal Hunger: Measuring the Global Adaptation Buffer"),
              ". We introduce the ",
              tags$strong("adaptation buffer"),
              " — the gap between climate-predicted and actual undernourishment — and analyze it across 143 countries using ND-GAIN vulnerability, FAO undernourishment, and World Bank development indicators.",
              style = "font-size: 14px; line-height: 1.6; margin-bottom: 15px; color: rgba(255,255,255,0.95);"
            ),
            tags$p(
              strong("Key finding:"),
              " Climate vulnerability alone explains 42% of cross-country hunger variation, but the residual is large and structured. ",
              "Countries like Bangladesh beat their climate odds by ~9 percentage points; conflict-affected states like Haiti fall far below prediction. ",
              "The correlation matrix below explores relationships among dashboard indicators; the sections that follow report the paper's OLS models, global buffer rankings, and Monte Carlo uncertainty analysis.",
              style = "font-size: 14px; line-height: 1.6; color: rgba(255,255,255,0.95);"
            )
          )
        )
      ),
      
      # Correlation Analysis Section
      fluidRow(
        box(
          title = tags$span(icon("project-diagram"), " Correlation Analysis"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          tags$div(
            style = "background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 15px;",
            tags$h4("What is a Correlation Matrix?", style = "color: #2c3e50; margin-top: 0;"),
            tags$p(
              "A correlation matrix is a table showing correlation coefficients between multiple variables. ",
              "Each cell shows how strongly two variables are related:",
              style = "font-size: 14px; line-height: 1.6; color: #555; margin-bottom: 10px;"
            ),
            tags$ul(
              style = "font-size: 14px; line-height: 1.8; color: #555;",
              tags$li(strong("Values range from -1 to +1:"), " +1 means perfect positive correlation (as one increases, so does the other), ",
                     "-1 means perfect negative correlation (as one increases, the other decreases), and 0 means no relationship."),
              tags$li(strong("Color coding:"), " Red indicates positive correlations, blue indicates negative correlations. ",
                     "Darker colors mean stronger relationships."),
              tags$li(strong("Why it matters:"), " Understanding correlations helps identify which factors move together, ",
                     "which can inform policy and intervention strategies.")
            )
          ),
          plotlyOutput("correlation_plot", height = "560px")
        )
      ),
      
      # Adaptation buffer — OLS models from research paper
      fluidRow(
        box(
          title = tags$span(icon("shield-alt"), " The Adaptation Buffer"),
          status = "info",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          tags$div(
            style = "background: #f0f9ff; padding: 16px; border-radius: 8px; border: 1px solid #bae6fd; margin-bottom: 16px;",
            tags$p(
              style = "font-size: 14px; line-height: 1.65; color: #0c4a6e; margin: 0 0 10px 0;",
              tags$strong("Definition:"),
              " Buffer = Predicted undernourishment − Actual undernourishment, where predicted values come from a cross-country OLS regression of FAO prevalence of undernourishment on ND-GAIN climate vulnerability."
            ),
            tags$p(
              style = "font-size: 14px; line-height: 1.65; color: #0c4a6e; margin: 0;",
              tags$strong("Interpretation:"),
              " A positive buffer means a country beats its climate odds (effective adaptation); a negative buffer means hunger exceeds what vulnerability alone predicts. ",
              "Sample: N = 143 countries. Buffer SD ≈ 7.5 pp (range −38.8 to +14.6)."
            )
          ),
          tabsetPanel(
            id = "adaptation_buffer_model_tabs",
            type = "tabs",
            tabPanel(
              title = "Model 1 — Baseline",
              br(),
              tags$p(
                style = "font-size: 13px; color: #475569; margin: 0 0 8px 0;",
                "How much hunger variation aligns with vulnerability alone? This sparse benchmark defines the adaptation buffer."
              ),
              uiOutput("paper_model1_meta"),
              DT::dataTableOutput("paper_model1_tbl", width = "100%"),
              tags$div(
                style = "background: #ecfdf5; border: 1px solid #a7f3d0; border-radius: 8px; padding: 16px; margin-top: 16px;",
                tags$h5(style = "margin: 0 0 10px 0; color: #065f46; font-size: 14px; font-weight: 700;", "What we discovered"),
                tags$ul(
                  style = "font-size: 13px; line-height: 1.7; color: #064e3b; margin: 0; padding-left: 18px;",
                  tags$li(strong("Climate vulnerability is a strong predictor of hunger — but only partly."),
                          " ND-GAIN vulnerability alone explains 42.3% of cross-country variation in undernourishment (R² = 0.423, p < 0.001). A 0.1-point rise in vulnerability (0–1 scale) is associated with ~6.9 percentage points higher undernourishment."),
                  tags$li(strong("Most hunger variation is not explained by climate exposure."),
                          " The remaining ~58% — with a residual spread of about 7.5 percentage points — is where adaptation, institutions, conflict, and policy matter. This unexplained gap is what we call the adaptation buffer."),
                  tags$li(strong("The benchmark is precise enough to use globally."),
                          " Bootstrap resampling (Model 4) puts a 90% interval of [58.3, 81.5] on the vulnerability slope, so the headline gradient is not driven by a handful of outliers."),
                  tags$li(strong("Worked example — Bangladesh:"),
                          " Vulnerability 0.569 predicts 19.4% undernourishment; actual is 10.4%. Buffer ≈ +9.0 pp — millions of people who, on climate fundamentals alone, would be expected to be hungrier than they are.")
                )
              )
            ),
            tabPanel(
              title = "Model 2 — Multivariate",
              br(),
              tags$p(
                style = "font-size: 13px; color: #475569; margin: 0 0 8px 0;",
                "Does the climate–hunger link survive controls for income, rurality, disasters, and conflict?"
              ),
              uiOutput("paper_model2_meta"),
              DT::dataTableOutput("paper_model2_tbl", width = "100%"),
              tags$div(
                style = "background: #ecfdf5; border: 1px solid #a7f3d0; border-radius: 8px; padding: 16px; margin-top: 16px;",
                tags$h5(style = "margin: 0 0 10px 0; color: #065f46; font-size: 14px; font-weight: 700;", "What we discovered"),
                tags$ul(
                  style = "font-size: 13px; line-height: 1.7; color: #064e3b; margin: 0; padding-left: 18px;",
                  tags$li(strong("The climate–hunger link is real, not just a poverty proxy."),
                          " Vulnerability stays large and highly significant (β ≈ 40, p < 0.001) after controlling for GDP per capita, rural share, disaster counts, and conflict fatalities."),
                  tags$li(strong("About 40% of the raw climate gradient runs through development channels."),
                          " The vulnerability coefficient falls from ~69 (Model 1) to ~40 (Model 2), meaning a substantial share of the bivariate association co-moves with income and shock observables."),
                  tags$li(strong("Income robustly predicts hunger levels."),
                          " Each log-point of GDP per capita is associated with ~2.8 percentage points lower undernourishment (p = 0.006)."),
                  tags$li(strong("Crude disaster and conflict aggregates show no linear signal here — but that does not mean shocks are irrelevant."),
                          " Underperformance in the buffer rankings (Haiti, Syria, Kenya) suggests conflict destroys food security through channels this simple cross-section cannot capture cleanly.")
                )
              )
            ),
            tabPanel(
              title = "Model 3 — Buffer determinants",
              br(),
              tags$p(
                style = "font-size: 13px; color: #475569; margin: 0 0 8px 0;",
                "What correlates with beating the climate-only benchmark? Vulnerability is excluded (it already enters the predicted value)."
              ),
              uiOutput("paper_model3_meta"),
              DT::dataTableOutput("paper_model3_tbl", width = "100%"),
              tags$div(
                style = "background: #ecfdf5; border: 1px solid #a7f3d0; border-radius: 8px; padding: 16px; margin-top: 16px;",
                tags$h5(style = "margin: 0 0 10px 0; color: #065f46; font-size: 14px; font-weight: 700;", "What we discovered"),
                tags$ul(
                  style = "font-size: 13px; line-height: 1.7; color: #064e3b; margin: 0; padding-left: 18px;",
                  tags$li(strong("Standard covariates barely explain who beats their climate odds."),
                          " The model explains only ~6% of buffer variation (R² = 0.057). The buffer is not a repackaging of GDP, readiness, rurality, disasters, or conflict in this form."),
                  tags$li(strong("ND-GAIN readiness is the most promising correlate."),
                          " Higher adaptive capacity is associated with larger buffers (β ≈ 13.4; a 0.1-point readiness increase ≈ +1.3 pp buffer), though p ≈ 0.12 at this sample size — hypothesis-generating, not definitive."),
                  tags$li(strong("Income does not predict the buffer after netting out vulnerability."),
                          " GDP predicts hunger levels (Model 2) but not residual over/under-performance, because the buffer already removes the part of hunger that tracks climate exposure."),
                  tags$li(strong("Policy implication: buffers must be monitored directly."),
                          " Because overperformance cannot be inferred from standard indicators, countries need annual buffer tracking — not vulnerability rankings alone.")
                )
              )
            )
          )
        )
      ),

      # Global buffer rankings
      fluidRow(
        box(
          title = tags$span(icon("trophy"), " Global Buffer Rankings"),
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          tags$p(
            style = "font-size: 14px; line-height: 1.6; color: #555; margin-bottom: 12px;",
            "Countries ranked by adaptation buffer (percentage points). ",
            tags$strong("Overperformers"),
            " report less hunger than climate vulnerability predicts; ",
            tags$strong("underperformers"),
            " report more."
          ),
          tabsetPanel(
            type = "tabs",
            tabPanel(
              title = "Top 15 overperformers",
              br(),
              tags$p(
                style = "font-size: 13px; color: #475569; margin: 0 0 12px 0;",
                "Countries reporting substantially less hunger than ND-GAIN vulnerability alone would predict."
              ),
              DT::dataTableOutput("buffer_top_tbl", width = "100%")
            ),
            tabPanel(
              title = "Bottom 10 underperformers",
              br(),
              tags$p(
                style = "font-size: 13px; color: #475569; margin: 0 0 12px 0;",
                "Countries reporting substantially more hunger than their climate burden alone would predict."
              ),
              DT::dataTableOutput("buffer_bottom_tbl", width = "100%")
            ),
            tabPanel(
              title = "Analyzed trends",
              br(),
              tags$div(
                style = "font-size: 13px; line-height: 1.7; color: #334155;",
                tags$div(
                  style = "background: #fef2f2; border: 1px solid #fecaca; border-radius: 8px; padding: 16px; margin-bottom: 16px;",
                  tags$h5(style = "margin: 0 0 10px 0; color: #991b1b; font-size: 14px; font-weight: 700;",
                          icon("exclamation-triangle"), " Trend 1 — Conflict and weak governance destroy buffers"),
                  tags$p(style = "margin: 0 0 8px 0;",
                         "The deepest underperformers are dominated by political violence and state fragility, not by being the most climate-exposed countries on Earth."),
                  tags$ul(style = "margin: 0; padding-left: 18px;",
                    tags$li(strong("Haiti"), " (−38.8 pp): institutional collapse and repeated crises; hunger far above climate prediction."),
                    tags$li(strong("Syria"), " (−25.2 pp), ", strong("Kenya"), " (−22.1 pp), ", strong("Madagascar"), " (−20.7 pp), ", strong("Liberia"), " (−18.1 pp): conflict, displacement, or governance breakdown eroding food systems."),
                    tags$li(strong("Central African Republic"), " (−9.7 pp) and ", strong("Afghanistan"), " (rank 129, −7.3 pp): hunger exceeds climate fundamentals where violence disrupts agriculture and aid."),
                    tags$li(tags$em("Significance:"), " Vulnerability-weighted aid would systematically miss the countries where hunger most exceeds climate exposure — and overlook that conflict destroys buffers faster than climate alone erodes them.")
                  )
                ),
                tags$div(
                  style = "background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 16px; margin-bottom: 16px;",
                  tags$h5(style = "margin: 0 0 10px 0; color: #166534; font-size: 14px; font-weight: 700;",
                          icon("seedling"), " Trend 2 — Overperformance clusters in two distinct groups"),
                  tags$ul(style = "margin: 0; padding-left: 18px;",
                    tags$li(strong("Pacific & Indian Ocean small island states"), " (Kiribati, Samoa, Vanuatu, Seychelles): very high exposure scores but low measured undernourishment — partly exposure-driven index mechanics; flagged for robustness."),
                    tags$li(strong("Agrarian states with sustained investment"), " (Bangladesh +9.0, Senegal +12.1, Nepal +8.7, Cambodia +8.1, Philippines +7.9, Viet Nam +7.1): agricultural progress, social protection, and disaster preparedness beating climate odds."),
                    tags$li(strong("Sahelian overperformers"), " (Senegal, Mauritania, Niger, Mali): among the world's most climate-exposed, yet hunger below prediction — suggesting adaptation can work even under extreme exposure."),
                    tags$li(tags$em("Significance:"), " Effective adaptation is visible in outcome data, not only in plans. These countries are candidates for studying what policies actually work.")
                  )
                ),
                tags$div(
                  style = "background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 16px; margin-bottom: 16px;",
                  tags$h5(style = "margin: 0 0 10px 0; color: #1e40af; font-size: 14px; font-weight: 700;",
                          icon("balance-scale"), " Trend 3 — Buffer and vulnerability diverge in the tails"),
                  tags$p(style = "margin: 0 0 8px 0;",
                         "A vulnerability ranking and a buffer ranking would direct aid to substantially different country lists."),
                  tags$ul(style = "margin: 0; padding-left: 18px;",
                    tags$li(strong("Niger"), " (V = 0.636, among the most vulnerable) posts a ", strong("+11.2 pp"), " buffer — beating its climate odds."),
                    tags$li(strong("Botswana"), " (V = 0.431, mid-range vulnerability) posts a ", strong("−14.1 pp"), " buffer — hunger far above its climate burden."),
                    tags$li(strong("Middle-income underperformers"), " (Botswana, Gabon): negative buffers point to inequality and distributional failure, not raw climate hazard."),
                    tags$li(tags$em("Significance:"), " Climate vulnerability does not equal hunger. The buffer makes performance — not just exposure — visible and trackable.")
                  )
                ),
                tags$div(
                  style = "background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 8px; padding: 16px;",
                  tags$h5(style = "margin: 0 0 10px 0; color: #6b21a8; font-size: 14px; font-weight: 700;",
                          icon("compass"), " Policy takeaway"),
                  tags$p(style = "margin: 0;",
                         "Aid and adaptation finance should use a two-axis screen: ",
                         strong("vulnerability level"), " × ", strong("buffer trend"),
                         ". Target countries with large but shrinking buffers (the Bangladesh-2007 cyclone pattern) for preventive finance — defending existing adaptive gains is often cheaper than rebuilding after collapse. Because Model 3 explains only ~6% of buffer variation, the watch-list must come from direct buffer monitoring each year, not from forecasting models alone.")
                )
              )
            )
          )
        )
      ),

      # Monte Carlo analysis
      fluidRow(
        box(
          title = tags$span(icon("dice"), " Monte Carlo Analysis"),
          status = "success",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          tags$div(
            style = "background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 15px;",
            tags$h4("Buffer uncertainty & collapse dynamics", style = "color: #2c3e50; margin-top: 0;"),
            tags$p(
              style = "font-size: 14px; line-height: 1.6; color: #555; margin-bottom: 10px;",
              tags$strong("Model 4 (uncertainty):"),
              " 20,000 bootstrap resamples with measurement noise on FAO undernourishment. ",
              "66 countries are robust over-performers (P(buffer > 0) ≥ 90%); 42 are robust under-performers."
            ),
            tags$p(
              style = "font-size: 14px; line-height: 1.6; color: #555; margin: 0 0 12px 0;",
              tags$strong("Model 5 (collapse):"),
              " Simulated 20-year buffer paths under random climate/conflict shocks. ",
              "A Bangladesh-like +9 pp buffer has a 41% chance of collapsing below zero within 20 years under baseline shocks, but only 4% once resilience investments soften shocks and speed recovery."
            )
          ),
          tags$div(
            style = "background: #ecfdf5; border: 1px solid #a7f3d0; border-radius: 8px; padding: 16px; margin-bottom: 20px;",
            tags$h5(style = "margin: 0 0 10px 0; color: #065f46; font-size: 14px; font-weight: 700;", "What the Monte Carlo simulations show"),
            tags$div(
              style = "font-size: 13px; line-height: 1.7; color: #064e3b;",
              tags$p(style = "margin: 0 0 10px 0; font-weight: 600;", "Model 4 — Are the rankings real, or statistical noise?"),
              tags$ul(style = "margin: 0 0 14px 0; padding-left: 18px;",
                tags$li("The benchmark regression line is precisely estimated: vulnerability slope 90% CI [58.3, 81.5]; R² CI [0.34, 0.53]."),
                tags$li("Nearly three-quarters of countries land in a clear camp: 66 robust over-performers, 42 robust under-performers, only 35 ambiguous."),
                tags$li(strong("Bangladesh"), " stays positive in 100% of 20,000 simulations (90% CI [+6.1, +12.1] pp); even the pessimistic tail leaves it a clear over-performer."),
                tags$li(strong("Haiti"), " and ", strong("Kenya"), " stay negative in 100% of simulations — the underperformer list is not a coin-flip."),
                tags$li(tags$em("Significance:"), " Point estimates from the rankings tables are trustworthy enough for policy prioritization; uncertainty is concentrated in countries near the benchmark line.")
              ),
              tags$p(style = "margin: 0 0 10px 0; font-weight: 600;", "Model 5 — How fragile is a healthy buffer?"),
              tags$ul(style = "margin: 0; padding-left: 18px;",
                tags$li("A +9 pp buffer (Bangladesh-like) has a 41% chance of falling below zero at least once within 20 years under severe shocks and slow recovery."),
                tags$li("The same starting buffer has only a 4.4% collapse probability once resilience investments reduce shock damage (~40%) and speed recovery."),
                tags$li("Expected years underwater drop from 1.01 to 0.05 per 20-year window — both countries face identical climate exposure; the difference is absorptive capacity."),
                tags$li(tags$em("Significance:"), " Buffers are assets that can be built and lost. Defending a buffer through early warning, storage, safety nets, and flood protection has far higher marginal return than waiting for hunger statistics to spike — and this risk is invisible to vulnerability indices alone.")
              )
            )
          ),
          tags$h5(style = "color: #2c3e50; margin-bottom: 8px;", "Selected countries — Monte Carlo buffer confidence"),
          DT::dataTableOutput("buffer_mc_key_tbl", width = "100%"),
          tags$h5(style = "color: #2c3e50; margin: 24px 0 8px 0;", "Buffer collapse simulation (Bangladesh-like starting buffer)"),
          DT::dataTableOutput("buffer_collapse_tbl", width = "100%")
        )
      ),
    ),
    
    # Predictive Model Tab
    tabItem(
      tabName = "model",
      fluidRow(
        box(
          title = "Hunger Risk Prediction Model",
          status = "primary",
          solidHeader = TRUE,
          width = 8,
          plotlyOutput("model_plot", height = "400px")
        ),
        
        box(
          title = "Model Parameters",
          status = "info",
          solidHeader = TRUE,
          width = 4,
          sliderInput("gdp_input", "GDP per Capita (USD):", 
                     min = 0, max = 100000, value = 5000),
          sliderInput("poverty_input", "Poverty Rate (%):", 
                     min = 0, max = 100, value = 20),
          sliderInput("agriculture_input", "Agricultural Land (%):", 
                     min = 0, max = 100, value = 30),
          actionButton("predict_button", "Predict Hunger Risk", 
                      class = "btn-primary")
        )
      ),
      
      fluidRow(
        box(
          title = "Model Performance",
          status = "warning",
          solidHeader = TRUE,
          width = 6,
          verbatimTextOutput("model_performance")
        ),
        
        box(
          title = "Feature Importance",
          status = "success",
          solidHeader = TRUE,
          width = 6,
          plotlyOutput("feature_importance", height = "300px")
        )
      )
    ),
    
    # About Tab
    tabItem(
      tabName = "about",
      fluidRow(
        column(
          12,
          tags$section(
            class = "seo-intro-block",
            tags$h1("About the Global Hunger Research Project"),
            tags$h2("Student-led hunger research at Duke University"),
            tags$p(
              "I am Garrett Zhou, a high school researcher at ",
              tags$a(href = "https://www.da.org/", target = "_blank", rel = "noopener noreferrer", "Durham Academy"),
              ", working with ",
              tags$a(href = "https://scholars.duke.edu/person/hannah.jacobs", target = "_blank", rel = "noopener noreferrer", "Professor Hannah Jacobs"),
              " at ",
              tags$a(href = "https://library.duke.edu/", target = "_blank", rel = "noopener noreferrer", "Duke Libraries"),
              " on this interactive dashboard. My interest in food security started when I volunteered at the ",
              tags$a(href = "https://foodbankcenc.org/locations/durham", target = "_blank", rel = "noopener noreferrer", "Durham Food Bank of Central & Eastern North Carolina"),
              " and saw how many people in my community were struggling with hunger."
            ),
            tags$p(
              "The project maps hunger-related risk across countries, runs statistical models on adaptation ",
              "buffers and undernourishment drivers, and includes my Bangladesh climate and food security ",
              "research from the North Carolina Youth Institute. Explore the ",
              tags$a(href = "?tab=map", "global hunger vulnerability map"),
              ", read the ",
              tags$a(href = "?tab=bangladesh_research", "Bangladesh research page"),
              ", or review ",
              tags$a(href = "?tab=analysis", "statistical analysis"),
              " for the adaptation-buffer models."
            )
          )
        )
      ),
      # Page Header
      fluidRow(
        box(
          title = page_tab_header("About Us", "Meet the research team", "users"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          collapsible = FALSE,
          tags$div(
            style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 5px; margin-bottom: 20px; color: white; text-align: center;",
            tags$h2("Global Hunger Research Project", style = "margin: 0 0 10px 0; color: white;"),
            tags$p("A collaborative research initiative at ", tags$a(href = "https://www.duke.edu/", target = "_blank", rel = "noopener noreferrer", "Duke University"), style = "font-size: 16px; margin: 0; color: rgba(255,255,255,0.9);")
          )
        )
      ),
      
      # Research Team - Two Column Layout
      fluidRow(
        # Student Researcher
        box(
          title = tags$span(icon("user-graduate"), " Student Researcher"),
          status = "info",
          solidHeader = TRUE,
          width = 6,
          collapsible = FALSE,
          tags$div(
            style = "text-align: center; padding: 20px;",
            tags$div(
              style = paste(
                "width: 150px; height: 150px; border-radius: 50%;",
                "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);",
                "margin: 0 auto 20px;",
                "display: flex; align-items: center; justify-content: center;",
                "position: relative; overflow: hidden;",
                "box-shadow: 0 8px 20px rgba(0,0,0,0.15);",
                "border: 4px solid rgba(255,255,255,0.85);"
              ),
              # Fallback icon (shows if image can't be loaded)
              tags$span(icon("user", class = "fa-4x"), style = "color: rgba(255,255,255,0.95);"),
              # Profile image (place file at www/garrett.jpg)
              tags$img(
                src = "assets/Garrett%20Zhou%20Headshot%20copy.JPG",
                alt = "Garrett Zhou",
                style = paste(
                  "position: absolute; inset: 0;",
                  "width: 100%; height: 100%;",
                  "object-fit: cover;",
                  "border-radius: 50%;"
                ),
                onerror = "this.style.display='none';"
              )
            ),
            tags$h3("Garrett Zhou", style = "color: #2c3e50; margin: 0 0 10px 0; font-size: 24px;"),
            tags$p(
              style = "font-size: 16px; color: #666; margin-bottom: 20px; font-style: italic;",
              "Class of 2027 High Schooler"
            ),
            tags$div(
              style = "background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: left; margin-top: 20px;",
              tags$h4(icon("university"), " Affiliation", style = "color: #3c8dbc; margin-top: 0;"),
              tags$p(
                tags$a(href = "https://www.da.org/", target = "_blank", rel = "noopener noreferrer", "Durham Academy"), tags$br(),
                tags$a(href = "https://www.durhamnc.gov/", target = "_blank", rel = "noopener noreferrer", "Durham"), ", ",
                tags$a(href = "https://www.nc.gov/", target = "_blank", rel = "noopener noreferrer", "North Carolina"),
                style = "font-size: 14px; color: #555; margin-bottom: 15px;"
              ),
              
              tags$h4(icon("graduation-cap"), " Background", style = "color: #3c8dbc;"),
              tags$p(
                "I'm a high school student passionate about addressing global hunger and food insecurity. ",
                "Through this research project, I aim to understand the complex factors driving hunger worldwide ",
                "and develop data-driven solutions to help combat this critical issue.",
                style = "font-size: 14px; color: #555; line-height: 1.6; margin-bottom: 10px;"
              ),
              tags$p(
                "I first got interested in food security when I started volunteering at the ",
                tags$a(href = "https://foodbankcenc.org/locations/durham", target = "_blank", rel = "noopener noreferrer", "Durham Food Bank of Central & Eastern North Carolina"),
                ". Seeing how many people in my own community were actually struggling made hunger feel real in a way I hadn't before.",
                style = "font-size: 14px; color: #555; line-height: 1.6; margin-bottom: 10px;"
              ),
              tags$p(
                "Outside the classroom, I play for the ",
                tags$a(href = "https://www.ncfcyouth.com/boys-academy", target = "_blank", rel = "noopener noreferrer", "NCFC Academy"),
                " ECNL boys soccer team, affiliated with ",
                tags$a(href = "https://www.northcarolinafc.com/", target = "_blank", rel = "noopener noreferrer", "NCFC"), ".",
                " NCFC youth teams participate in ",
                tags$a(href = "https://theecnl.com/sports/ecnl-boys", target = "_blank", rel = "noopener noreferrer", "ECNL"), ",",
                " and the NCFC pro team plays in ",
                tags$a(href = "https://www.uslleagueone.com/", target = "_blank", rel = "noopener noreferrer", "USL League One"), ".",
                style = "font-size: 14px; color: #555; line-height: 1.6; margin-bottom: 15px;"
              ),
              
              tags$h4(icon("heart"), " Research Interests", style = "color: #3c8dbc;"),
            tags$ul(
                style = "font-size: 14px; color: #555; line-height: 1.8;",
                tags$li("Digital and computational humanities"),
                tags$li("Global hunger and food insecurity"),
                tags$li("Data-driven policy solutions"),
                tags$li("Food systems and sustainability")
              ),
              
              tags$h4(icon("envelope"), " Contact & Links", style = "color: #3c8dbc;"),
              tags$p(
                tags$a(href = "mailto:garrettzhou09@gmail.com", "garrettzhou09@gmail.com", 
                       style = "color: #3c8dbc; text-decoration: none;"), tags$br(),
                tags$a(href = "https://garrbearsblog.wordpress.com/", target = "_blank", 
                       icon("blog", style = "margin-right: 5px;"), "Blog: A Grain Of Change", 
                       style = "color: #3c8dbc; text-decoration: none; display: inline-block; margin-top: 5px;"), tags$br(),
                tags$a(href = "https://www.youtube.com/@Academy-Bros", target = "_blank", 
                       icon("youtube", style = "margin-right: 5px;"), "YouTube Channel", 
                       style = "color: #3c8dbc; text-decoration: none; display: inline-block; margin-top: 5px;"),
                style = "font-size: 14px; color: #555;"
              )
            )
          )
        ),
        
        # Faculty Mentor
        box(
          title = tags$span(icon("chalkboard-teacher"), " Faculty Mentor"),
          status = "success",
          solidHeader = TRUE,
          width = 6,
          collapsible = FALSE,
          tags$div(
            style = "text-align: center; padding: 20px;",
            tags$div(
              style = paste(
                "width: 150px; height: 150px; border-radius: 50%;",
                "background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);",
                "margin: 0 auto 20px;",
                "display: flex; align-items: center; justify-content: center;",
                "position: relative; overflow: hidden;",
                "box-shadow: 0 8px 20px rgba(0,0,0,0.15);",
                "border: 4px solid rgba(255,255,255,0.85);"
              ),
              # Fallback icon (shows if image can't be loaded)
              tags$span(icon("user-tie", class = "fa-4x"), style = "color: rgba(255,255,255,0.95);"),
              # Profile image (place file at www/hannah_jacobs.jpg)
              tags$img(
                src = "assets/Image%201-2-26%20at%2010.24%E2%80%AFAM.jpeg",
                alt = "Professor Hannah Jacobs",
                style = paste(
                  "position: absolute; inset: 0;",
                  "width: 100%; height: 100%;",
                  "object-fit: cover;",
                  "border-radius: 50%;"
                ),
                onerror = "this.style.display='none';"
              )
            ),
            tags$h3(
              tags$a(href = "https://scholars.duke.edu/person/hannah.jacobs", target = "_blank", rel = "noopener noreferrer", style = "color: #2c3e50; text-decoration: none;", "Professor Hannah Jacobs"),
              style = "margin: 0 0 10px 0; font-size: 24px;"
            ),
            tags$p(
              style = "font-size: 16px; color: #666; margin-bottom: 20px; font-style: italic;",
              "Professor of Duke Libraries"
            ),
            tags$div(
              style = "background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: left; margin-top: 20px;",
              tags$h4(icon("university"), " Affiliation", style = "color: #28a745; margin-top: 0;"),
              tags$p(
                tags$a(href = "https://library.duke.edu/", target = "_blank", rel = "noopener noreferrer", "Duke Libraries"), tags$br(),
                tags$a(href = "https://www.duke.edu/", target = "_blank", rel = "noopener noreferrer", "Duke University"),
                style = "font-size: 14px; color: #555; margin-bottom: 15px;"
              ),
              
              tags$h4(icon("book"), " Research Focus", style = "color: #28a745;"),
              tags$p(
                "Professor Jacobs specializes in Digital Humanities, bringing expertise in information science ",
                "and digital methodologies to support innovative research projects. Her work bridges traditional ",
                "humanities scholarship with modern digital tools and approaches.",
                style = "font-size: 14px; color: #555; line-height: 1.6; margin-bottom: 15px;"
              ),
              
              tags$h4(icon("award"), " Education & Expertise", style = "color: #28a745;"),
            tags$ul(
                style = "font-size: 14px; color: #555; line-height: 1.8;",
                tags$li(
                  "MS in Information Science, ",
                  tags$a(href = "https://www.unc.edu/", target = "_blank", rel = "noopener noreferrer", "UNC"),
                  " Chapel Hill"
                ),
                tags$li(
                  "MA in Digital Humanities, ",
                  tags$a(href = "https://www.kcl.ac.uk/", target = "_blank", rel = "noopener noreferrer", "King's College London")
                ),
                tags$li(
                  "BA in English and Theatre, ",
                  tags$a(href = "https://www.warren-wilson.edu/", target = "_blank", rel = "noopener noreferrer", "Warren Wilson College")
                ),
                tags$li("Digital Humanities topics broadly"),
                tags$li("Information science and data management"),
                tags$li("Digital scholarship and research methodologies")
              ),
              
              tags$h4(icon("envelope"), " Contact", style = "color: #28a745;"),
              tags$p(
                tags$a(href = "mailto:hj24@duke.edu", "hj24@duke.edu",
                       style = "color: #28a745; text-decoration: none;"),
                style = "font-size: 14px; color: #555; margin: 0;"
              )
            )
          )
        )
      ),
      
      # Project Collaboration Section
      fluidRow(
        box(
          title = tags$span(icon("handshake"), " Research Collaboration"),
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          tags$div(
            style = "padding: 20px;",
            tags$h3("About This Collaboration", style = "color: #2c3e50; margin-top: 0;"),
            tags$p(
              "I work with ",
              tags$a(href = "https://scholars.duke.edu/person/hannah.jacobs", target = "_blank", rel = "noopener noreferrer", "Professor Hannah Jacobs"),
              " at ",
              tags$a(href = "https://library.duke.edu/", target = "_blank", rel = "noopener noreferrer", "Duke Libraries"),
              " on this project. She helps me figure out how to turn a big question — why are people still hungry? — into something I can actually measure, analyze, and write about.",
              style = "font-size: 15px; line-height: 1.8; color: #555; margin-bottom: 20px;"
            ),
            tags$p(
              "The dashboard pulls together public data on hunger, conflict, climate, and governance. I built the maps and models because I wanted to see the patterns myself, not just read about them in a report. If it helps someone else understand the issue a little better, that's a win.",
              style = "font-size: 15px; line-height: 1.8; color: #555; margin-bottom: 0;"
            )
          )
        )
      ),
      
      # Acknowledgments Section
      fluidRow(
        box(
          title = tags$span(icon("heart"), " Acknowledgments"),
          status = "danger",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          tags$div(
            style = "padding: 20px;",
            tags$p(
              "We would like to express our gratitude to:",
              style = "font-size: 15px; color: #555; margin-bottom: 15px;"
            ),
            tags$ul(
              style = "font-size: 14px; color: #555; line-height: 1.8;",
              tags$li("Duke University and Duke Libraries for providing the resources and support for this research"),
              tags$li(
                "Professor Hannah Jacobs for her mentorship, guidance, and expertise in Digital Humanities"
              ),
              tags$li(
                tags$a(href = "https://globalhealth.duke.edu/people/ariely-sumedha", target = "_blank", rel = "noopener noreferrer", "Professor Sumedha Gupta Ariely"),
                " for her guidance on global health research"
              ),
              tags$li(
                tags$a(href = "https://directory.library.duke.edu/staff/eric.monson", target = "_blank", rel = "noopener noreferrer", "Eric Monson"),
                " and ",
                tags$a(href = "https://directory.library.duke.edu/staff/drew.keener", target = "_blank", rel = "noopener noreferrer", "Drew Keener"),
                " for a joint call that helped with data visualization and geospatial mapping"
              ),
              tags$li(
                "The ",
                tags$a(href = "https://www.worldfoodprize.org/index.cfm?nodeID=87698&audienceID=1", target = "_blank", rel = "noopener noreferrer", "North Carolina Youth Institute"),
                " and ",
                tags$a(href = "https://www.worldfoodprize.org/", target = "_blank", rel = "noopener noreferrer", "World Food Prize"),
                " for hosting a great research conference"
              ),
              tags$li(
                "The ",
                tags$a(href = "https://foodbankcenc.org/locations/durham", target = "_blank", rel = "noopener noreferrer", "Food Bank of Central & Eastern North Carolina"),
                " (Durham) for their work addressing hunger locally"
              ),
              tags$li("All data providers including the World Bank, FAO, WFP, WHO, and other organizations that make their data publicly available"),
              tags$li("The global research community working to address hunger and food insecurity")
            ),
            tags$p(
              style = "font-size: 14px; color: #555; margin: 18px 0 0 0; line-height: 1.6;",
              "Learn more about Professor Jacobs at ",
              tags$a(
                href = "https://hannahlangstonjacobs.com/",
                target = "_blank",
                rel = "noopener noreferrer",
                "hannahlangstonjacobs.com"
              ),
              "."
            )
          )
        )
      )
    ),
    
    # Data Sources Tab
    tabItem(
      tabName = "citations",
      fluidRow(
        box(
          title = page_tab_header("Data Sources", "Chicago style + quick descriptions", "database"),
          status = "primary", 
          solidHeader = TRUE,
          width = 12,
          tags$div(
            style = "font-size: 16px; line-height: 1.8; padding: 20px;",
            tags$div(
              style = "background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); padding: 18px; border-radius: 8px; color: white; margin-bottom: 18px;",
              tags$h2("Data Sources", style = "margin: 0 0 6px 0; color: white;"),
              tags$p(
                "This page lists every imported dataset currently integrated into the dashboard. ",
                "Sources are formatted in ", tags$strong("Chicago style"), " and each entry includes a short description of what we used it for.",
                style = "margin: 0; color: rgba(255,255,255,0.92); font-size: 14px;"
              )
            ),
            tags$div(
              style = "background: #f8f9fa; border-radius: 8px; padding: 14px 16px; border: 1px solid #e9ecef;",
              tags$p(
                style = "margin: 0; font-size: 13px; color: #555;",
                icon("info-circle"),
                " Sources are listed in Chicago style with a short description of how each dataset is used in this dashboard. ",
                tags$strong("In data/raw"),
                " badges show which files are present on this computer."
              )
            ),
            tags$div(style = "margin-top: 18px;", uiOutput("citations_display"))
          )
        )
      )
    ),
    tabItem(
      tabName = "data_coverage",
      fluidRow(
        box(
          title = tags$span(icon("database"), " Data pipeline"),
          status = "info",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          collapsed = FALSE,
          tags$p(
            style = "margin: 0; font-size: 13px; color: #334155;",
            if (nzchar(.data_refresh_banner)) .data_refresh_banner else {
              "No refresh log yet. Run scripts/run_data_refresh_pipeline.sh from the project root to update data/metadata/last_refresh.txt and refresh integrated datasets."
            }
          ),
          tags$p(
            style = "margin: 8px 0 0 0; font-size: 12px; color: #64748b;",
            "See ",
            tags$code("docs/data_pipeline_implementation_plan.md"),
            ", ",
            tags$code("data/metadata/data_dictionary.csv"),
            ", and ",
            tags$code("scripts/run_data_refresh_pipeline.sh"),
            "."
          )
        )
      ),
      fluidRow(
        box(
          title = tags$span(icon("table"), " Data Coverage"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          tags$div(
            style = "background: linear-gradient(135deg, #0e7490 0%, #0369a1 100%); padding: 16px 18px; border-radius: 8px; color: white; margin-bottom: 16px;",
            tags$h3(style = "margin: 0 0 6px 0; color: white; font-size: 18px;", "Where data exist — and where they do not"),
            tags$p(
              style = "margin: 0; font-size: 14px; color: rgba(255,255,255,0.92);",
              "This tab summarizes completeness across ",
              tags$strong("integrated countries"),
              " (World Bank backbone, excluding aggregates). ",
              tags$span(class = "coverage-check", "\u2713"),
              " = value present; ",
              tags$span(style = "opacity:0.85;", "\u2014"),
              " = missing. Use it to prioritize collection and to sanity-check merges."
            )
          ),
          uiOutput("coverage_summary_kpis"),
          tags$p(class = "coverage-section-head", strong("Coverage by indicator"), " — share of countries with a non-missing value (see ", tags$em("Source"), " column)."),
          plotlyOutput("coverage_by_indicator_chart", height = "420px"),
          fluidRow(
            column(
              7,
              h4("Indicator detail", style = "margin-top: 18px; color: #334155;"),
              DT::dataTableOutput("coverage_by_indicator_table")
            ),
            column(
              5,
              h4("Countries with fewest indicators", style = "margin-top: 18px; color: #334155;"),
              tags$p(class = "coverage-section-head", "Lowest completeness among integrated countries (top 20)."),
              tableOutput("coverage_worst_countries")
            )
          ),
          hr(),
          h4("Per-country matrix", style = "color: #334155;"),
          tags$p(class = "coverage-section-head", "Filter by country or region. Sort by ", tags$em("% coverage"), " to find sparse profiles quickly."),
          DT::dataTableOutput("coverage_by_country_table")
        )
      )
    ),
    tabItem(
      tabName = "grfc_trends",
      fluidRow(
        box(
          title = tags$span(icon("chart-line"), " GRFC & IPC trends over time"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          tags$div(
            style = "background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); padding: 14px 16px; border-radius: 8px; color: white; margin-bottom: 14px;",
            tags$h3(style = "margin: 0 0 6px 0; color: white; font-size: 17px;", "Acute food insecurity trajectories"),
            tags$p(
              style = "margin: 0; font-size: 13px; color: rgba(255,255,255,0.92);",
              "Compare countries on ",
              tags$strong("IPC phase"),
              " or ",
              tags$strong("population in phase 3+"),
              ". GRFC uses the 2016–2024 master workbook; IPC uses the 2017–2025 historical file."
            )
          ),
          uiOutput("grfc_trends_status"),
          tags$div(
            class = "grfc-trends-controls",
            fluidRow(
              column(3,
                selectInput("grfc_trends_datasource", "Data source", choices = c("GRFC (2016–2024)" = "grfc", "IPC (2017–2025)" = "ipc"), selected = "grfc")
              ),
              column(5,
                tags$div(
                  class = "grfc-trends-countries",
                  selectizeInput(
                    "grfc_trends_countries",
                    "Countries (select one or more)",
                    choices = character(),
                    selected = character(),
                    multiple = TRUE,
                    options = list(placeholder = "Choose countries to plot...")
                  )
                )
              ),
              column(2,
                selectInput("grfc_trends_metric", "Metric", choices = c("IPC Phase" = "ipc_phase", "Phase 3+ Population (millions)" = "population_phase3_plus"), selected = "ipc_phase")
              ),
              column(2,
                tags$div(
                  class = "grfc-trends-download",
                  downloadButton("grfc_panel_download", "Download CSV", class = "btn-default btn-block")
                )
              )
            )
          ),
          tags$div(
            class = "grfc-trends-chart-wrap",
            uiOutput("grfc_trends_chart_title"),
            plotlyOutput("grfc_trends_plot", height = "520px")
          ),
          tags$p(style = "font-size: 12px; color: #64748b; margin: 10px 0 0 0;",
                 "Tip: If the chart is empty, pick countries above or switch data source. Phase 3+ population is shown in millions.")
        )
      ),
      fluidRow(
        box(
          title = "Panel dataset preview",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          tags$p("Country–year rows for the selected data source. Filter, sort, or export the full panel."),
          DT::dataTableOutput("grfc_panel_table")
        )
      )
    )
  )
)

# Plotly defaults for Overview tab (aligned typography and grid styling)
overview_plot_font <- list(family = "system-ui, -apple-system, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif", size = 11, color = "#334155")
overview_plot_margin <- list(l = 58, r = 22, t = 10, b = 58)
overview_ov_axis <- function(title_text, tick_angle = NULL, extras = list()) {
  ax <- list(
    title = list(text = title_text, font = list(size = 12, color = "#475569"), standoff = 10),
    tickfont = list(size = 11, color = "#64748b"),
    showgrid = TRUE,
    gridcolor = "#eceff3",
    zeroline = FALSE,
    showline = TRUE,
    linecolor = "#cbd5e1",
    mirror = FALSE
  )
  if (!is.null(tick_angle)) ax$tickangle <- tick_angle
  modifyList(ax, extras)
}

# Overview charts: do not capture mouse wheel (lets the page scroll over plot areas).
overview_plotly_config <- function(p, displayModeBar = FALSE, modeBarButtonsToRemove = NULL, ...) {
  cfg <- list(
    p = p,
    displayModeBar = displayModeBar,
    displaylogo = FALSE,
    scrollZoom = FALSE,
    doubleClick = FALSE
  )
  if (!is.null(modeBarButtonsToRemove)) {
    cfg$modeBarButtonsToRemove <- modeBarButtonsToRemove
  }
  extra <- list(...)
  if (length(extra) > 0) {
    cfg <- utils::modifyList(cfg, extra)
  }
  do.call(plotly::config, cfg)
}

overview_ov_axis_static <- function(title_text, tick_angle = NULL, extras = list()) {
  overview_ov_axis(title_text, tick_angle, modifyList(extras, list(fixedrange = TRUE)))
}

# Data Explorer — distribution histogram styling (aligned with Overview tab)
explorer_hist_colors <- list(
  population       = "rgba(37, 99, 235, 0.78)",
  gdp              = "rgba(99, 102, 241, 0.78)",
  poverty          = "rgba(13, 148, 136, 0.78)",
  life_expectancy  = "rgba(22, 163, 74, 0.78)",
  agriculture      = "rgba(217, 119, 6, 0.78)",
  vulnerability    = "rgba(220, 38, 38, 0.78)",
  undernourishment = "rgba(8, 145, 178, 0.78)",
  infant_mortality = "rgba(190, 24, 93, 0.78)"
)

explorer_plot_empty <- function(message = "No data available") {
  plot_ly() %>%
    add_annotations(
      text = message,
      x = 0.5, y = 0.5,
      xref = "paper", yref = "paper",
      showarrow = FALSE,
      font = list(size = 13, color = "#64748b", family = overview_plot_font$family)
    ) %>%
    layout(
      paper_bgcolor = "transparent",
      plot_bgcolor = "#ffffff",
      xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
      yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE, range = c(0, 1))
    ) %>%
    config(displayModeBar = FALSE)
}

explorer_hist_plot <- function(x_vals, title, x_label, color, filename,
                               nbinsx = 28, x_extras = list()) {
  x_vals <- suppressWarnings(as.numeric(x_vals))
  x_vals <- x_vals[is.finite(x_vals)]
  if (length(x_vals) == 0) {
    return(explorer_plot_empty())
  }
  plot_ly(
    x = x_vals,
    type = "histogram",
    nbinsx = nbinsx,
    marker = list(color = color, line = list(color = "#ffffff", width = 1)),
    hovertemplate = paste0("<b>", x_label, ":</b> %{x}<br><b>Countries in bin:</b> %{y}<extra></extra>")
  ) %>%
    layout(
      title = list(
        text = title,
        font = list(size = 13, color = "#1e293b", family = overview_plot_font$family),
        x = 0.02,
        xanchor = "left"
      ),
      paper_bgcolor = "transparent",
      plot_bgcolor = "#ffffff",
      font = overview_plot_font,
      margin = modifyList(overview_plot_margin, list(t = 48, b = 52, l = 56, r = 16)),
      bargap = 0.08,
      xaxis = overview_ov_axis(x_label, extras = x_extras),
      yaxis = overview_ov_axis("Number of countries", extras = list(rangemode = "tozero", tickformat = ",d"))
    ) %>%
    config(
      displayModeBar = TRUE,
      displaylogo = FALSE,
      modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d", "toggleSpikelines", "zoomIn2d", "zoomOut2d", "pan2d"),
      toImageButtonOptions = list(format = "png", filename = filename, height = 520, width = 760, scale = 2)
    )
}

explorer_hist_from_col <- function(data, col, title, x_label, color, filename,
                                   nbinsx = 28, x_extras = list(), transform = NULL) {
  if (is.null(data) || nrow(data) == 0 || !col %in% names(data)) {
    return(explorer_plot_empty())
  }
  x_vals <- suppressWarnings(as.numeric(data[[col]]))
  x_vals <- x_vals[is.finite(x_vals)]
  if (!is.null(transform)) {
    x_vals <- transform(x_vals)
    x_vals <- x_vals[is.finite(x_vals)]
  }
  explorer_hist_plot(
    x_vals = x_vals,
    title = title,
    x_label = x_label,
    color = color,
    filename = filename,
    nbinsx = nbinsx,
    x_extras = x_extras
  )
}

overview_pop_millions <- function(population) population / 1e6

overview_pop_xvals <- function(population, scale) {
  pop_m <- overview_pop_millions(population)
  scale <- if (is.null(scale) || !nzchar(scale)) "linear" else scale
  switch(scale,
    "log2"  = log2(pmax(pop_m, 0.01)),
    "loge"  = log(pmax(pop_m, 0.01)),
    "log10" = log10(pmax(pop_m, 0.01)),
    pop_m
  )
}

overview_pop_xlab <- function(scale) {
  scale <- if (is.null(scale) || !nzchar(scale)) "linear" else scale
  switch(scale,
    "log2"  = "Population (millions, log₂ scale)",
    "loge"  = "Population (millions, log e scale)",
    "log10" = "Population (millions, log₁₀ scale)",
    "Population (millions)"
  )
}

OVERVIEW_SCATTER_LOG_X <- c("population", "gdp_per_capita")

overview_scatter_xscale_choices <- c(
  "Linear" = "linear",
  "log₂" = "log2",
  "log e" = "loge",
  "log₁₀" = "log10"
)

overview_scatter_get_x <- function(values, var_key, scale = "linear") {
  scale <- if (is.null(scale) || !nzchar(scale)) "linear" else scale
  if (!var_key %in% OVERVIEW_SCATTER_LOG_X) scale <- "linear"
  v <- as.numeric(values)
  switch(var_key,
    population = overview_pop_xvals(v, scale),
    gdp_per_capita = switch(scale,
      "log2"  = log2(pmax(v, 1)),
      "loge"  = log(pmax(v, 1)),
      "log10" = log10(pmax(v, 1)),
      v
    ),
    v
  )
}

overview_scatter_x_label <- function(var_key, scale = "linear") {
  scale <- if (is.null(scale) || !nzchar(scale)) "linear" else scale
  if (!var_key %in% OVERVIEW_SCATTER_LOG_X) scale <- "linear"
  switch(var_key,
    population = overview_pop_xlab(scale),
    gdp_per_capita = switch(scale,
      "log2"  = "GDP per capita (US$, log₂ scale)",
      "loge"  = "GDP per capita (US$, log e scale)",
      "log10" = "GDP per capita (US$, log₁₀ scale)",
      "GDP per capita (current US$)"
    ),
    agriculture_land = "Agricultural land (% of land area)",
    poverty_display = "Poverty rate (%)",
    life_expectancy = "Life expectancy (years)",
    ghi_score = "Global Hunger Index score",
    climate_vulnerability_index = "Climate vulnerability index",
    var_key
  )
}

overview_scatter_y_label <- function(var_key) {
  switch(var_key,
    undernourishment_rate = "Undernourishment (%)",
    hunger_vulnerability_rating = "Vulnerability score (0–100)",
    var_key
  )
}

overview_scatter_format_x <- function(values, var_key) {
  v <- as.numeric(values)
  switch(var_key,
    population = paste0(round(v / 1e6, 2), "M"),
    gdp_per_capita = paste0("$", format(round(v, 0), big.mark = ",", scientific = FALSE)),
    agriculture_land = paste0(round(v, 1), "%"),
    poverty_display = paste0(round(v, 1), "%"),
    life_expectancy = paste0(round(v, 1), " yrs"),
    ghi_score = as.character(round(v, 2)),
    climate_vulnerability_index = as.character(round(v, 2)),
    as.character(round(v, 2))
  )
}

overview_scatter_format_y <- function(values, var_key) {
  v <- as.numeric(values)
  switch(var_key,
    undernourishment_rate = paste0(round(v, 1), "%"),
    hunger_vulnerability_rating = as.character(round(v, 1)),
    as.character(round(v, 2))
  )
}

overview_scatter_x_axis_extras <- function(var_key) {
  switch(var_key,
    population = list(rangemode = "tozero"),
    gdp_per_capita = list(rangemode = "tozero"),
    agriculture_land = list(range = c(0, 100), dtick = 25),
    poverty_display = list(range = c(0, 100), dtick = 25),
    life_expectancy = list(rangemode = "tozero"),
    list(rangemode = "tozero")
  )
}

overview_scatter_hover_text <- function(d, x_var, y_var) {
  x_lab <- overview_scatter_x_label(x_var, "linear")
  y_lab <- overview_scatter_y_label(y_var)
  mapply(
    function(ctry, xr, yr) {
      paste0(
        "Country: ", ctry,
        "<br>", x_lab, ": ", overview_scatter_format_x(xr, x_var),
        "<br>", y_lab, ": ", overview_scatter_format_y(yr, y_var)
      )
    },
    d$country,
    d[[x_var]],
    d[[y_var]],
    USE.NAMES = FALSE
  )
}

overview_ols_equation_text <- function(fit, digits = 3) {
  b <- stats::coef(fit)
  if (length(b) < 2L) return("")
  fmt <- function(v) {
    v <- signif(v, digits)
    format(v, trim = TRUE, scientific = (abs(v) < 1e-4 | abs(v) >= 1e4))
  }
  intercept <- as.numeric(b[1])
  slope <- as.numeric(b[2])
  eq <- if (abs(slope) < 1e-12) {
    paste0("y = ", fmt(intercept))
  } else if (intercept >= 0) {
    paste0("y = ", fmt(intercept), " + ", fmt(slope), "x")
  } else {
    paste0("y = ", fmt(intercept), " − ", fmt(abs(slope)), "x")
  }
  r2 <- summary(fit)$r.squared
  if (is.finite(r2)) paste0(eq, "  (R² = ", format(round(r2, 3), nsmall = 3, trim = TRUE), ")") else eq
}

# Scenario lab: SVG landscape with vulnerability-colored land (see www/scenario_country_landscape.svg)
read_regression_csv_safe <- function(rel_path) {
  p <- here::here(rel_path)
  if (!file.exists(p)) {
    return(data.frame(
      Message = paste(
        "File not found:", rel_path,
        "— run Rscript scripts/vulnerability_undernourishment_regressions.R from the project root."
      ),
      stringsAsFactors = FALSE
    ))
  }
  as.data.frame(readr::read_csv(p, show_col_types = FALSE), stringsAsFactors = FALSE)
}

read_global_paper_csv <- function(rel_path) {
  p <- here::here("Global Research Paper", rel_path)
  if (!file.exists(p)) {
    return(data.frame(
      Message = paste(
        "File not found:", rel_path,
        "— run scripts in Global Research Paper/scripts/ from the project root."
      ),
      stringsAsFactors = FALSE
    ))
  }
  as.data.frame(readr::read_csv(p, show_col_types = FALSE), stringsAsFactors = FALSE)
}

PAPER_MODEL_TERM_LABELS <- c(
  const = "Intercept",
  vulnerability = "ND-GAIN vulnerability",
  ln_gdp_pcap = "ln(GDP per capita)",
  rural_pct = "Rural population share (%)",
  disaster_count = "Disaster count (2013–2022)",
  ln1_fatalities = "ln(1 + conflict fatalities)",
  readiness = "ND-GAIN readiness"
)

paper_term_to_label <- function(term) {
  term <- as.character(term)
  if (identical(term, "(Intercept)") || identical(term, "const")) return("Intercept")
  if (term %in% names(PAPER_MODEL_TERM_LABELS)) return(unname(PAPER_MODEL_TERM_LABELS[[term]]))
  gsub("_", " ", term, fixed = TRUE)
}

prepare_global_paper_model_tbl <- function(d, model_id) {
  if ("Message" %in% names(d)) {
    return(list(table = d, meta = NULL))
  }
  if (!all(c("model", "term", "coef", "std_err", "pvalue") %in% names(d))) {
    return(list(table = d, meta = NULL))
  }
  sub <- d[d$model == model_id, , drop = FALSE]
  if (nrow(sub) == 0) {
    return(list(
      table = data.frame(Message = paste("Model not found:", model_id), stringsAsFactors = FALSE),
      meta = NULL
    ))
  }
  meta <- list(
    n = sub$n[1],
    r2 = sub$r2[1],
    r2_adj = sub$r2_adj[1]
  )
  out <- data.frame(
    term = sub$term,
    estimate = sub$coef,
    std_error = sub$std_err,
    t_value = if ("t" %in% names(sub)) sub$t else NA_real_,
    p_value = sub$pvalue,
    stringsAsFactors = FALSE
  )
  out$term <- vapply(out$term, paper_term_to_label, character(1))
  html_num_cols <- intersect(c("estimate", "std_error", "t_value"), names(out))
  for (col in html_num_cols) {
    out[[col]] <- regression_col_to_display(out[[col]], digits = 4L)
  }
  p_num <- suppressWarnings(as.numeric(out$p_value))
  out$`p value (formatted)` <- format_regression_p_display(p_num)
  out$p_value <- NULL
  names(out) <- gsub("_", " ", names(out))
  names(out)[names(out) == "term"] <- "Predictor"
  names(out)[names(out) == "estimate"] <- "Coefficient"
  names(out)[names(out) == "std error"] <- "Std. error"
  names(out)[names(out) == "t value"] <- "t statistic"
  names(out)[names(out) == "p value (formatted)"] <- "p value"
  list(table = out, meta = meta)
}

paper_model_meta_html <- function(meta) {
  if (is.null(meta) || is.null(meta$n)) return(NULL)
  tags$p(
    style = "font-size: 13px; color: #475569; margin: 0 0 12px 0;",
    tags$strong("N = "),
    formatC(round(meta$n, 0), format = "f", digits = 0),
    " · ",
    tags$strong("R² = "),
    sprintf("%.3f", meta$r2),
    if (!is.null(meta$r2_adj)) {
      tagList(" · ", tags$strong("Adj. R² = "), sprintf("%.3f", meta$r2_adj))
    }
  )
}

prepare_buffer_rankings_tbl <- function(d, ranks) {
  if ("Message" %in% names(d)) return(d)
  needed <- c("rank", "country", "vulnerability", "predicted", "undernourishment", "buffer")
  if (!all(needed %in% names(d))) return(d)
  sub <- d[d$rank %in% ranks, needed, drop = FALSE]
  sub <- sub[order(sub$rank), , drop = FALSE]
  sub$vulnerability <- sprintf("%.3f", sub$vulnerability)
  sub$predicted <- sprintf("%.1f", sub$predicted)
  sub$undernourishment <- sprintf("%.1f", sub$undernourishment)
  sub$buffer <- sprintf("%+.1f", sub$buffer)
  names(sub) <- c(
    "Rank", "Country", "Vulnerability", "Predicted PoU (%)",
    "Actual PoU (%)", "Buffer (pp)"
  )
  sub
}

prepare_buffer_mc_key_tbl <- function(d) {
  if ("Message" %in% names(d)) return(d)
  keys <- c("Senegal", "Bangladesh", "Viet Nam", "Kenya", "Haiti")
  needed <- c(
    "country", "buffer_mc_mean", "buffer_ci_low", "buffer_ci_high", "prob_overperformer"
  )
  if (!all(needed %in% names(d))) return(d)
  sub <- d[d$country %in% keys, needed, drop = FALSE]
  sub <- sub[match(keys, sub$country), , drop = FALSE]
  sub <- sub[!is.na(sub$country), , drop = FALSE]
  sub$buffer_mc_mean <- sprintf("%+.1f", sub$buffer_mc_mean)
  sub$buffer_ci_low <- sprintf("%+.1f", sub$buffer_ci_low)
  sub$buffer_ci_high <- sprintf("%+.1f", sub$buffer_ci_high)
  sub$prob_overperformer <- sprintf("%.0f%%", 100 * sub$prob_overperformer)
  names(sub) <- c(
    "Country", "Buffer (MC mean)", "90% CI low", "90% CI high", "P(over-performer)"
  )
  sub
}

prepare_buffer_collapse_tbl <- function(d) {
  if ("Message" %in% names(d)) return(d)
  needed <- c(
    "scenario", "P_collapse_within_10y", "P_collapse_within_20y",
    "expected_years_negative_of_20", "buffer_p05_year20", "buffer_median_year20"
  )
  if (!all(needed %in% names(d))) return(d)
  labels <- c(
    baseline = "Baseline (large shocks, slow recovery)",
    resilience_investment = "Resilience investment (smaller shocks, faster recovery)"
  )
  out <- d[, needed, drop = FALSE]
  out$scenario <- ifelse(
    out$scenario %in% names(labels),
    unname(labels[out$scenario]),
    out$scenario
  )
  pct_cols <- c("P_collapse_within_10y", "P_collapse_within_20y")
  for (col in pct_cols) {
    out[[col]] <- sprintf("%.1f%%", 100 * out[[col]])
  }
  out$expected_years_negative_of_20 <- sprintf("%.2f", out$expected_years_negative_of_20)
  out$buffer_p05_year20 <- sprintf("%+.1f", out$buffer_p05_year20)
  out$buffer_median_year20 <- sprintf("%+.1f", out$buffer_median_year20)
  names(out) <- c(
    "Scenario", "P(collapse ≤ 10y)", "P(collapse ≤ 20y)",
    "Expected years underwater (of 20)", "Buffer at year 20 (5th pct)", "Buffer at year 20 (median)"
  )
  out
}

REGRESSION_NEAR_ZERO_THRESHOLD <- 1e-4

regression_format_display_value <- function(v, digits = 4) {
  v_num <- suppressWarnings(as.numeric(v))
  if (length(v_num) != 1L || !is.finite(v_num)) return(as.character(v))
  if (v_num == 0) return("0")
  if (abs(v_num) >= 1 || abs(v_num) >= 10^(-digits)) {
    return(formatC(round(v_num, digits), format = "f", digits = digits))
  }
  formatC(v_num, format = "g", digits = digits + 2L)
}

regression_cell_html <- function(v, digits = 4) {
  v_num <- suppressWarnings(as.numeric(v))
  if (length(v_num) != 1L || !is.finite(v_num)) return(as.character(v))
  if (v_num == 0) return("0")
  if (abs(v_num) < REGRESSION_NEAR_ZERO_THRESHOLD) {
    full_txt <- format(v_num, digits = 12, scientific = FALSE, trim = TRUE)
    if (!nzchar(full_txt)) full_txt <- as.character(v_num)
    full_attr <- htmltools::htmlEscape(full_txt, attribute = TRUE)
    return(sprintf(
      '<span class="regression-near-zero" role="button" tabindex="0" title="Click to show exact value" data-full="%s">~0</span>',
      full_attr
    ))
  }
  htmltools::htmlEscape(regression_format_display_value(v_num, digits))
}

regression_col_to_display <- function(x, digits = 4) {
  vapply(x, regression_cell_html, character(1), digits = digits)
}

format_regression_p_display <- function(p) {
  p <- suppressWarnings(as.numeric(p))
  out <- rep(NA_character_, length(p))
  ok <- is.finite(p)
  out[ok & p < 0.001] <- "<0.001"
  out[ok & p >= 0.001] <- formatC(p[ok & p >= 0.001], format = "f", digits = 4)
  out
}

prepare_regression_univariate_tbl <- function(d) {
  if ("Message" %in% names(d)) return(d)
  if (!all(c("predictor", "label", "n", "estimate", "std_error", "p_value") %in% names(d))) {
    return(d)
  }
  d <- d[, intersect(
    c("label", "n", "estimate", "std_error", "p_value", "r_squared", "r_squared_adj", "beta_std"),
    names(d)
  ), drop = FALSE]
  if ("n" %in% names(d)) {
    d$n <- vapply(d$n, function(v) {
      n <- suppressWarnings(as.numeric(v))
      if (!is.finite(n)) return(as.character(v))
      formatC(round(n, 0), format = "f", digits = 0)
    }, character(1))
  }
  html_num_cols <- intersect(c("estimate", "std_error", "r_squared", "r_squared_adj", "beta_std"), names(d))
  for (col in html_num_cols) {
    d[[col]] <- regression_col_to_display(d[[col]], digits = 4L)
  }
  p_num <- suppressWarnings(as.numeric(d$p_value))
  d$`p value (formatted)` <- format_regression_p_display(p_num)
  d$p_value <- NULL
  names(d) <- gsub("_", " ", names(d))
  names(d)[names(d) == "label"] <- "Predictor"
  names(d)[names(d) == "n"] <- "Sample size (n)"
  names(d)[names(d) == "estimate"] <- "Estimate"
  names(d)[names(d) == "r squared adj"] <- "Adjusted R squared"
  names(d)[names(d) == "r squared"] <- "R squared"
  names(d)[names(d) == "beta std"] <- "Standardized coefficient"
  names(d)[names(d) == "std error"] <- "Standard error"
  names(d)[names(d) == "p value (formatted)"] <- "p value"
  d
}

regression_predictor_label_lookup <- function() {
  path <- here::here("docs/regression_univariate_undernourishment.csv")
  if (!file.exists(path)) {
    return(c("(Intercept)" = "Intercept"))
  }
  uv <- readr::read_csv(path, show_col_types = FALSE)
  if (!all(c("predictor", "label") %in% names(uv))) {
    return(c("(Intercept)" = "Intercept"))
  }
  labs <- stats::setNames(as.character(uv$label), as.character(uv$predictor))
  labs["(Intercept)"] <- "Intercept"
  labs
}

regression_term_to_predictor_label <- function(term, lookup = regression_predictor_label_lookup()) {
  term <- as.character(term)
  if (term %in% names(lookup)) return(unname(lookup[[term]]))
  if (identical(term, "(Intercept)")) return("Intercept")
  gsub("_", " ", term, fixed = TRUE)
}

prepare_regression_multivariate_tbl <- function(d) {
  if ("Message" %in% names(d)) return(d)
  if (!all(c("term", "estimate", "std_error", "p_value") %in% names(d))) {
    return(d)
  }
  keep <- intersect(c("term", "estimate", "std_error", "t_value", "p_value"), names(d))
  d <- d[, keep, drop = FALSE]
  label_lookup <- regression_predictor_label_lookup()
  d$term <- vapply(d$term, regression_term_to_predictor_label, character(1), lookup = label_lookup)
  html_num_cols <- intersect(c("estimate", "std_error", "t_value"), names(d))
  for (col in html_num_cols) {
    d[[col]] <- regression_col_to_display(d[[col]], digits = 4L)
  }
  p_num <- suppressWarnings(as.numeric(d$p_value))
  d$`p value (formatted)` <- format_regression_p_display(p_num)
  d$p_value <- NULL
  names(d) <- gsub("_", " ", names(d))
  names(d)[names(d) == "estimate"] <- "Estimate"
  names(d)[names(d) == "std error"] <- "Standard error"
  names(d)[names(d) == "t value"] <- "t statistic"
  names(d)[names(d) == "p value (formatted)"] <- "p value"
  names(d)[names(d) == "term"] <- "Predictor"
  d
}

regression_dt_options <- function(page_length = 15) {
  list(
    scrollX = TRUE,
    pageLength = page_length,
    dom = "ftip",
    search = list(regex = FALSE, smart = FALSE, caseInsensitive = TRUE)
  )
}

render_regression_dt <- function(d, page_length = 15) {
  DT::datatable(
    d,
    options = regression_dt_options(page_length),
    rownames = FALSE,
    escape = FALSE,
    class = "cell-border stripe hover"
  )
}

# OLS best-fit line in the same coordinates as the scatter axes (linear or log-transformed x).
overview_add_ols_line <- function(p, x, y, line_color = "#1e293b") {
  ok <- is.finite(x) & is.finite(y)
  x <- x[ok]
  y <- y[ok]
  if (length(x) < 2L) return(p)
  fit <- stats::lm(y ~ x)
  x_line <- seq(min(x), max(x), length.out = 120L)
  y_line <- stats::predict(fit, newdata = data.frame(x = x_line))
  eq_text <- overview_ols_equation_text(fit)
  p %>%
    plotly::add_lines(
      x = x_line,
      y = y_line,
      inherit = FALSE,
      line = list(color = line_color, width = 2.2, dash = "dash"),
      hoverinfo = "skip",
      showlegend = FALSE,
      name = "Least squares fit"
    ) %>%
    plotly::add_annotations(
      text = eq_text,
      xref = "paper",
      yref = "paper",
      x = 0.02,
      y = 0.98,
      xanchor = "left",
      yanchor = "top",
      showarrow = FALSE,
      font = list(size = 11, color = line_color),
      bgcolor = "rgba(255, 255, 255, 0.92)",
      bordercolor = line_color,
      borderwidth = 1,
      borderpad = 4
    )
}

# Time-series forecast: anchor at last observation, fit trend on recent years only
clamp_timeseries_forecast <- function(values, variable_code) {
  v <- as.numeric(values)
  if (variable_code %in% c("SI.POV.DDAY", "AG.LND.AGRI.ZS", "SP.RUR.TOTL.ZS")) {
    pmin(pmax(v, 0), 100)
  } else if (variable_code == "SP.DYN.LE00.IN") {
    pmin(pmax(v, 20), 95)
  } else if (variable_code == "SP.DYN.IMRT.IN") {
    pmax(v, 0)
  } else if (variable_code == "FP.CPI.TOTL.ZG") {
    pmin(pmax(v, -30), 75)
  } else if (variable_code == "hunger_vulnerability_rating") {
    pmin(pmax(v, 0), 100)
  } else {
    v
  }
}

build_timeseries_forecast <- function(ts_data, variable_code, forecast_years, scale = 1) {
  if (is.null(forecast_years) || forecast_years < 1 || nrow(ts_data) < 3) {
    return(NULL)
  }

  fit_data <- ts_data %>%
    filter(!is.na(variable_value), is.finite(variable_value)) %>%
    arrange(year)

  if (nrow(fit_data) < 3) {
    return(NULL)
  }

  # Emphasize recent dynamics (last 15 years, at least 5 points)
  max_y <- max(fit_data$year, na.rm = TRUE)
  recent_data <- fit_data %>% filter(year >= max_y - 14)
  if (nrow(recent_data) < 5) {
    recent_data <- fit_data %>% slice_tail(n = min(5, nrow(fit_data)))
  }

  last_year <- max(recent_data$year, na.rm = TRUE)
  last_value <- recent_data$variable_value[recent_data$year == last_year][1]
  if (is.na(last_value) || !is.finite(last_value)) {
    return(NULL)
  }

  k_seq <- seq_len(forecast_years)
  future_years <- last_year + k_seq
  use_log <- variable_code %in% c("SP.POP.TOTL", "NY.GDP.MKTP.CD")

  forecast_vals <- if (use_log) {
    positive <- recent_data %>% filter(variable_value > 0)
    if (nrow(positive) < 3 || last_value <= 0) {
      return(NULL)
    }
    model <- lm(log(variable_value) ~ year, data = positive)
    log_slope <- unname(coef(model)[["year"]])
    if (is.na(log_slope) || !is.finite(log_slope)) {
      return(NULL)
    }
    last_value * exp(log_slope * k_seq)
  } else {
    model <- lm(variable_value ~ year, data = recent_data)
    slope <- unname(coef(model)[["year"]])
    if (is.na(slope) || !is.finite(slope)) {
      return(NULL)
    }
    last_value + slope * k_seq
  }

  forecast_vals <- clamp_timeseries_forecast(forecast_vals, variable_code)
  if (use_log) {
    forecast_vals <- forecast_vals[forecast_vals > 0]
  }
  if (length(forecast_vals) == 0) {
    return(NULL)
  }

  out <- data.frame(
    year = future_years[seq_along(forecast_vals)],
    display_value = forecast_vals / scale,
    stringsAsFactors = FALSE
  )

  # Bridge from last historical point so the dashed line connects visually
  bridge <- fit_data %>%
    filter(year == last_year) %>%
    transmute(year = as.numeric(year), display_value = variable_value / scale) %>%
    slice(1)

  if (nrow(bridge) == 1) {
    out <- dplyr::bind_rows(bridge, out)
  }

  out
}

# =============================================================================
# SERVER LOGIC
# =============================================================================

server <- function(input, output, session) {

  # Minimal plotly fallback to avoid client "Error: [object Object]" (must be valid htmlwidget)
  minimal_plotly <- function() {
    tryCatch({
      p <- plot_ly(type = "scatter", mode = "markers")
      p <- layout(p, title = list(text = "Chart unavailable"), xaxis = list(visible = FALSE), yaxis = list(visible = FALSE), margin = list(t = 60))
      p <- config(p, displayModeBar = FALSE)
      p
    }, error = function(e) plot_ly() %>% config(displayModeBar = FALSE))
  }

  # Helper function to create info icon with tooltip
  info_icon <- function(term, definition) {
    tags$span(
      class = "info-tooltip",
      tags$span(
        class = "info-icon",
        role = "button",
        tabindex = "0",
        `aria-label` = paste0("Help: ", term),
        "?"
      ),
      tags$span(
        class = "tooltip-text",
        tags$span(class = "tooltip-text__title", term),
        tags$span(class = "tooltip-text__body", definition)
      )
    )
  }

  country_metric_card <- function(value, label, icon_name, accent = "sky", help_term = NULL, help_text = NULL) {
    label_content <- if (!is.null(help_text) && nzchar(help_text)) {
      tagList(label, info_icon(if (is.null(help_term)) label else help_term, help_text))
    } else {
      label
    }
    tags$div(
      class = paste("country-metric-card", paste0("country-metric-card--", accent)),
      tags$div(class = "country-metric-card__icon", icon(icon_name)),
      tags$div(
        class = "country-metric-card__body",
        tags$div(class = "country-metric-card__value", value),
        tags$div(class = "country-metric-card__label", label_content)
      )
    )
  }

  # Clear country selection so user can search again
  observeEvent(input$clear_country, {
    updateSelectInput(session, "selected_country", selected = "")
  })

  observeEvent(input$go_bangladesh_research, {
    updateTabItems(session, "tabs", "bangladesh_research")
  })

  valid_dashboard_tabs <- c(
    "introduction", "map", "scenario_lab", "overview", "country_details",
    "timeseries", "analysis", "citations", "data_coverage", "grfc_trends",
    "bangladesh_research", "ghi_comparison", "explorer", "about", "model"
  )

  observeEvent(input$initial_tab_from_url, {
    tab <- as.character(input$initial_tab_from_url)
    if (!is.null(tab) && length(tab) == 1 && nzchar(tab) && tab %in% valid_dashboard_tabs) {
      updateTabItems(session, "tabs", selected = tab)
    }
  }, ignoreInit = TRUE)

  observeEvent(input$tabs, {
    tab <- as.character(input$tabs)
    if (!is.null(tab) && length(tab) == 1 && nzchar(tab) && tab %in% valid_dashboard_tabs) {
      shiny::updateQueryString(paste0("?tab=", utils::URLencode(tab, reserved = TRUE)), mode = "replace")
    }
  }, ignoreInit = TRUE)

  # Sidebar Filters help (map-only)
  observeEvent(input$filters_help, {
    showModal(modalDialog(
      title = "How to use filters",
      easyClose = TRUE,
      size = "m",
      tags$div(
        style = "line-height: 1.7;",
        tags$p("Filters change what you see on the ", strong("Interactive Map"), " and related visuals."),
        tags$ul(
          tags$li(strong("Select Countries:"), " Pick one or more countries, or keep 'All' to show everything."),
          tags$li(strong("Map Filters:"), " Under the map (below score multipliers): set latest data year, vulnerability score range, and optional statistic filters; only enabled statistic sliders appear."),
          tags$li(em("Note: Countries missing a selected metric may be hidden by that filter."))
        )
      ),
      footer = tagList(modalButton("Close"))
    ))
  })
  
  # Data Sources tab (full catalog; file detection via here::here)
  output$citations_display <- renderUI({
    raw_root <- here::here("data", "raw")
    citations_data <- build_dashboard_citations(raw_root)
    render_citations_ui(citations_data)
  })
  outputOptions(output, "citations_display", suspendWhenHidden = FALSE)
  
  # Data Coverage tab
  coverage_validation <- reactive({
    build_merge_validation(latest_summary)
  })

  output$coverage_summary_kpis <- renderUI({
    coverage_summary_tags(coverage_validation())
  })

  output$coverage_by_indicator_chart <- renderPlotly({
    val <- coverage_validation()
    sm <- val$summary
    if (nrow(sm) == 0) {
      return(plot_ly() %>%
               add_annotations(text = "No coverage data", x = 0.5, y = 0.5, showarrow = FALSE) %>%
               layout(xaxis = list(visible = FALSE), yaxis = list(visible = FALSE)))
    }
    sm <- sm %>% arrange(pct)
    plot_ly(
      data = sm,
      y = ~label,
      x = ~pct,
      type = "bar",
      orientation = "h",
      text = ~paste0(pct, "% (", n_countries, "/", total, ")"),
      hoverinfo = "text",
      marker = list(
        color = ~pct,
        colorscale = list(c(0, "#ef4444"), c(0.5, "#eab308"), c(1, "#22c55e")),
        cmin = 0,
        cmax = 100,
        line = list(color = "rgba(255,255,255,0.6)", width = 0.5)
      )
    ) %>%
      layout(
        paper_bgcolor = "#f8fafc",
        plot_bgcolor = "#ffffff",
        margin = list(l = 200, r = 24, t = 12, b = 48),
        xaxis = list(title = "Countries with data (%)", range = c(0, 100), dtick = 25),
        yaxis = list(title = "", automargin = TRUE),
        showlegend = FALSE
      ) %>%
      config(displayModeBar = FALSE)
  })

  output$coverage_by_indicator_table <- DT::renderDataTable({
    val <- coverage_validation()
    sm <- val$summary
    if (nrow(sm) == 0) return(DT::datatable(data.frame(Message = "No indicators")))
    disp <- sm %>%
      transmute(
        Indicator = label,
        Category = category,
        Source = source,
        `Countries with data` = n_countries,
        Total = total,
        `%` = paste0(pct, "%")
      )
    DT::datatable(
      disp,
      options = list(pageLength = 15, dom = "tip", order = list(list(3, "desc"))),
      rownames = FALSE,
      class = "compact stripe hover"
    )
  })

  output$coverage_worst_countries <- renderTable({
    val <- coverage_validation()
    val$report %>%
      select(country, region, n_indicators, pct_indicators) %>%
      arrange(n_indicators, pct_indicators, country) %>%
      head(20) %>%
      rename(
        Country = country,
        Region = region,
        `# indicators` = n_indicators,
        `% coverage` = pct_indicators
      ) %>%
      mutate(`% coverage` = paste0(`% coverage`, "%"))
  }, striped = TRUE, hover = TRUE, width = "100%")

  output$coverage_by_country_table <- DT::renderDataTable({
    val <- coverage_validation()
    catalog <- val$catalog
    label_map <- stats::setNames(catalog$label, catalog$column)

    disp <- val$report %>%
      select(country, region, iso3c, n_indicators, pct_indicators, any_of(val$has_cols))

    for (hc in val$has_cols) {
      if (!hc %in% names(disp)) next
      col <- gsub("^has_", "", hc)
      disp[[hc]] <- ifelse(disp[[hc]], "\u2713", "\u2014")
      names(disp)[names(disp) == hc] <- if (col %in% names(label_map)) {
        label_map[[col]]
      } else {
        gsub("_", " ", col, fixed = TRUE)
      }
    }

    names(disp)[names(disp) == "n_indicators"] <- "# indicators"
    names(disp)[names(disp) == "pct_indicators"] <- "% coverage"
    names(disp)[names(disp) == "iso3c"] <- "ISO3"

    DT::datatable(
      disp,
      filter = "top",
      options = list(pageLength = 25, scrollX = TRUE, order = list(list(4, "asc"))),
      rownames = FALSE,
      class = "compact stripe hover"
    )
  })

  outputOptions(output, "coverage_summary_kpis", suspendWhenHidden = FALSE)
  outputOptions(output, "coverage_by_indicator_chart", suspendWhenHidden = FALSE)
  outputOptions(output, "coverage_by_indicator_table", suspendWhenHidden = FALSE)
  outputOptions(output, "coverage_worst_countries", suspendWhenHidden = FALSE)
  outputOptions(output, "coverage_by_country_table", suspendWhenHidden = FALSE)

  # GRFC/IPC Trends tab
  trends_panel_raw <- reactive({
    src <- input$grfc_trends_datasource
    if (is.null(src)) src <- "grfc"
    if (src == "ipc") ipc_panel else grfc_panel
  })

  trends_panel <- reactive({
    normalize_trends_panel(trends_panel_raw())
  })

  sync_grfc_trends_country_choices <- function(metric = NULL) {
    pan <- trends_panel()
    choices <- sort(unique(pan$country))
    if (length(choices) == 0) {
      updateSelectizeInput(session, "grfc_trends_countries", choices = c(), selected = character())
      return(invisible(NULL))
    }
    m <- if (!is.null(metric) && nzchar(metric)) metric else if (!is.null(input$grfc_trends_metric)) input$grfc_trends_metric else "ipc_phase"
    defs <- default_trend_countries(pan, metric = m, n = 6L)
    defs <- intersect(defs, choices)
    if (length(defs) == 0) defs <- head(choices, 6L)
    updateSelectizeInput(session, "grfc_trends_countries", choices = choices, selected = defs, server = FALSE)
  }

  observeEvent(input$grfc_trends_datasource, {
    sync_grfc_trends_country_choices()
  }, ignoreInit = FALSE)

  observeEvent(input$grfc_trends_metric, {
    if (is.null(input$grfc_trends_countries) || length(input$grfc_trends_countries) == 0) {
      sync_grfc_trends_country_choices(input$grfc_trends_metric)
    }
  }, ignoreInit = FALSE)

  output$grfc_trends_status <- renderUI({
    src <- input$grfc_trends_datasource
    if (is.null(src)) src <- "grfc"
    pan <- trends_panel()
    label <- if (src == "ipc") "IPC historical panel" else "GRFC master panel"
    tags$p(
      style = "margin: 0 0 12px 0; padding: 10px 12px; background: #f1f5f9; border-radius: 8px; font-size: 13px; color: #475569; border-left: 4px solid #6366f1;",
      icon("info-circle"),
      " ",
      trends_panel_summary_text(pan, label)
    )
  })

  output$grfc_trends_chart_title <- renderUI({
    src <- input$grfc_trends_datasource
    if (is.null(src)) src <- "grfc"
    label <- if (src == "ipc") "IPC acute food insecurity over time" else "GRFC acute food insecurity over time"
    tags$h4(class = "grfc-trends-chart-title", label)
  })

  output$grfc_trends_plot <- renderPlotly({
    df <- trends_panel()
    if (nrow(df) == 0) {
      return(
        plot_ly(type = "scatter", mode = "markers") %>%
          add_annotations(
            text = "No trend data loaded. Check data/raw/wfp/grfc2016-2024_data.xlsx and data/raw/ipc/, then restart the app.",
            x = 0.5, y = 0.5, xref = "paper", yref = "paper", showarrow = FALSE,
            font = list(size = 13, color = "#64748b")
          ) %>%
          layout(xaxis = list(visible = FALSE), yaxis = list(visible = FALSE), margin = list(t = 40, b = 20))
      )
    }
    sel <- input$grfc_trends_countries
    if (!is.null(sel) && length(sel) > 0) df <- df %>% filter(country %in% sel)
    metric <- input$grfc_trends_metric
    if (is.null(metric)) metric <- "ipc_phase"
    if (metric == "population_phase3_plus") {
      df <- df %>%
        mutate(yval = population_phase3_plus / 1e6) %>%
        filter(!is.na(yval), is.finite(yval), yval > 0)
    } else {
      df <- df %>%
        mutate(yval = ipc_phase) %>%
        filter(!is.na(yval), is.finite(yval))
    }
    if (nrow(df) == 0) {
      return(
        plot_ly(type = "scatter", mode = "markers") %>%
          add_annotations(
            text = "No values for this metric in the selected countries. Try Phase 3+ population or other countries.",
            x = 0.5, y = 0.5, xref = "paper", yref = "paper", showarrow = FALSE,
            font = list(size = 13, color = "#64748b")
          ) %>%
          layout(xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
      )
    }
    n_series <- length(unique(df$country))
    legend_rows <- max(1L, ceiling(n_series / 4L))
    legend_bottom <- -0.12 - (legend_rows - 1L) * 0.07
    bottom_margin <- 72L + legend_rows * 22L

    plot_ly(df, x = ~assessment_year, y = ~yval, color = ~country, type = "scatter", mode = "lines+markers",
            text = ~paste0(country, "<br>Year: ", assessment_year, "<br>Value: ", round(yval, 2)),
            hoverinfo = "text",
            line = list(width = 2.2), marker = list(size = 7)) %>%
      layout(
        paper_bgcolor = "#f8fafc",
        plot_bgcolor = "#ffffff",
        font = overview_plot_font,
        xaxis = overview_ov_axis("Year", extras = list(dtick = 1)),
        yaxis = overview_ov_axis(
          if (metric == "population_phase3_plus") "Phase 3+ population (millions)" else "IPC Phase (1–5)",
          extras = list(rangemode = if (metric == "ipc_phase") "tozero" else "normal")
        ),
        showlegend = TRUE,
        legend = list(
          orientation = "h",
          x = 0.5,
          xanchor = "center",
          y = legend_bottom,
          yanchor = "top",
          bgcolor = "rgba(255, 255, 255, 0.95)",
          bordercolor = "#e2e8f0",
          borderwidth = 1,
          font = list(size = 11, color = "#475569")
        ),
        margin = list(t = 24, r = 24, b = bottom_margin, l = 58)
      ) %>%
      config(displayModeBar = TRUE, modeBarButtonsToRemove = c("lasso2d", "select2d"))
  })

  output$grfc_panel_download <- downloadHandler(
    filename = function() {
      src <- input$grfc_trends_datasource
      if (is.null(src)) src <- "grfc"
      paste0(if (src == "ipc") "ipc" else "grfc", "_panel.csv")
    },
    content = function(file) {
      df <- trends_panel()
      if (is.null(df) || nrow(df) == 0) return()
      export_cols <- c("country", "assessment_year", "ipc_phase", "population_phase3_plus", "population_phase4_plus", "population_phase5", "primary_driver", "secondary_driver")
      out <- df %>% select(any_of(export_cols))
      write_csv(out, file)
    }
  )

  output$grfc_panel_table <- DT::renderDataTable({
    df <- trends_panel()
    if (nrow(df) == 0) {
      return(DT::datatable(data.frame(Message = "No panel data loaded for this source."), rownames = FALSE))
    }
    grfc_panel_col_labels <- c(
      country = "Country",
      assessment_year = "Assessment year",
      ipc_phase = "IPC phase",
      population_phase3_plus = "Phase 3+ population (M)",
      population_phase4_plus = "Phase 4+ population (M)",
      population_phase5 = "Phase 5 population (M)",
      primary_driver = "Primary driver",
      secondary_driver = "Secondary driver"
    )
    disp <- df %>%
      select(country, assessment_year, ipc_phase, population_phase3_plus, any_of(c("population_phase4_plus", "population_phase5", "primary_driver", "secondary_driver"))) %>%
      mutate(
        population_phase3_plus = round(population_phase3_plus / 1e6, 3),
        across(any_of(c("population_phase4_plus", "population_phase5")), ~ round(.x / 1e6, 3))
      )
    present <- intersect(names(disp), names(grfc_panel_col_labels))
    names(disp)[match(present, names(disp))] <- unname(grfc_panel_col_labels[present])
    DT::datatable(disp, filter = "top", options = list(pageLength = 15, scrollX = TRUE, order = list(list(1, "desc"))), rownames = FALSE)
  })

  outputOptions(output, "grfc_trends_chart_title", suspendWhenHidden = FALSE)
  outputOptions(output, "grfc_trends_status", suspendWhenHidden = FALSE)
  outputOptions(output, "grfc_trends_plot", suspendWhenHidden = FALSE)
  outputOptions(output, "grfc_panel_table", suspendWhenHidden = FALSE)
  
  # Reactive data filtering
  filtered_data <- reactive({
    data <- hunger_data %>%
      filter(year >= input$year_range[1] & year <= input$year_range[2])
    
    if(!("All" %in% input$selected_countries)) {
      data <- data %>% filter(country %in% input$selected_countries)
    }
    
    return(data)
  })
  
  filtered_summary <- reactive({
    summary <- latest_summary %>%
      distinct(country, .keep_all = TRUE)  # Ensure no duplicates
    
    if(!("All" %in% input$selected_countries)) {
      summary <- summary %>% filter(country %in% input$selected_countries)
    }
    
    return(summary)
  })
  
  # Value boxes - use base latest_summary for accurate counts (not filtered)
  output$total_countries <- renderValueBox({
    # Count unique countries only from base data (excluding aggregates)
    base_summary <- latest_summary %>%
      distinct(country, .keep_all = TRUE) %>%
      filter(!is.na(iso3c)) %>%  # Must have ISO code
      filter(!is.na(region) & region != "Aggregates") %>%  # Exclude aggregates like World/regions
      filter(grepl("[A-Za-z]", country)) %>%               # Drop malformed numeric “countries”
      filter(country != "World" & iso3c != "WLD") %>%      # Extra safety: exclude global aggregate
      filter(!is.na(population) | !is.na(gdp_per_capita))  # Must have some data
    
    unique_countries <- nrow(base_summary)
    valueBox(
      value = unique_countries,
      subtitle = "Countries Analyzed",
      icon = icon("globe"),
      color = "blue"
    )
  })
  
  output$total_population <- renderValueBox({
    # Prefer the World Bank "World" aggregate (WLD) for the global total (most accurate),
    # but do NOT count it as a country.
    world_row <- latest_summary %>%
      distinct(country, .keep_all = TRUE) %>%
      filter(iso3c == "WLD" | country == "World") %>%
      slice(1)
    
    if (nrow(world_row) == 1 && !is.na(world_row$population) && world_row$population > 0) {
      total_pop <- world_row$population / 1e9
    } else {
      # Fallback: sum across countries (may undercount if some populations missing)
      base_summary <- latest_summary %>%
        distinct(country, .keep_all = TRUE) %>%
        filter(!is.na(iso3c)) %>%
        filter(!is.na(region) & region != "Aggregates") %>%
        filter(grepl("[A-Za-z]", country)) %>%
        filter(country != "World" & iso3c != "WLD") %>%
        filter(!is.na(population) & population > 0)
      total_pop <- sum(base_summary$population, na.rm = TRUE) / 1e9
    }
    valueBox(
      value = paste0(round(total_pop, 1), "B"),
      subtitle = "Total Population",
      icon = icon("users"),
      color = "green"
    )
  })
  
  output$high_risk_countries <- renderValueBox({
    # High-risk = same band as "High (50–75)" elsewhere (50 ≤ score < 75; 75+ is Critical)
    high_risk_data <- filtered_summary() %>%
      distinct(country, .keep_all = TRUE) %>%
      filter(!is.na(region) & region != "Aggregates") %>%
      filter(country != "World" & iso3c != "WLD") %>%
      filter(grepl("[A-Za-z]", country))
    high_risk <- sum(
      !is.na(high_risk_data$hunger_vulnerability_rating) &
        high_risk_data$hunger_vulnerability_rating >= 50 &
        high_risk_data$hunger_vulnerability_rating < 75,
      na.rm = TRUE
    )
    valueBox(
      value = high_risk,
      subtitle = "High Risk Countries (50–75)",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  # Plots
  output$hunger_risk_plot <- renderPlotly({
    d <- filtered_summary() %>%
      distinct(country, .keep_all = TRUE) %>%
      filter(!is.na(hunger_vulnerability_rating)) %>%
      mutate(
        tier_short = case_when(
          hunger_vulnerability_rating >= 75 ~ "Critical",
          hunger_vulnerability_rating >= 50 ~ "High",
          hunger_vulnerability_rating >= 25 ~ "Moderate",
          TRUE ~ "Low"
        ),
        tier_short = factor(tier_short, levels = c("Critical", "High", "Moderate", "Low")),
        tier_full = case_when(
          tier_short == "Critical" ~ "Critical (75–100)",
          tier_short == "High" ~ "High (50–75)",
          tier_short == "Moderate" ~ "Moderate (25–50)",
          TRUE ~ "Low (0–25)"
        )
      )
    if (nrow(d) == 0) {
      return(
        plot_ly() %>%
          add_annotations(text = "No vulnerability data for current filters", x = 0.5, y = 0.5, showarrow = FALSE, font = list(size = 13, color = "#64748b")) %>%
          layout(
            paper_bgcolor = "#f8fafc",
            plot_bgcolor = "#ffffff",
            font = overview_plot_font,
            xaxis = list(visible = FALSE),
            yaxis = list(visible = FALSE),
            margin = overview_plot_margin
          ) %>%
          overview_plotly_config()
      )
    }
    vulnerability_data <- d %>%
      count(tier_short, .drop = FALSE) %>%
      left_join(d %>% distinct(tier_short, tier_full), by = "tier_short") %>%
      mutate(percentage = if (sum(n, na.rm = TRUE) > 0) 100 * n / sum(n, na.rm = TRUE) else 0)
    
    bar_colors <- c("Critical" = "#991b1b", "High" = "#c2410c", "Moderate" = "#a16207", "Low" = "#166534")
    p <- plot_ly(
      vulnerability_data,
      x = ~tier_short,
      y = ~n,
      type = "bar",
      color = ~tier_short,
      colors = bar_colors,
      text = ~paste0("Band: ", tier_full, "<br>Countries: ", n, "<br>Share: ", round(percentage, 1), "%"),
      hoverinfo = "text",
      marker = list(line = list(color = "rgba(255,255,255,0.85)", width = 1))
    ) %>%
      layout(
        paper_bgcolor = "#f8fafc",
        plot_bgcolor = "#ffffff",
        font = overview_plot_font,
        margin = overview_plot_margin,
        bargap = 0.28,
        showlegend = FALSE,
        dragmode = FALSE,
        xaxis = overview_ov_axis_static("Vulnerability tier", tick_angle = 0, extras = list(categoryorder = "array", categoryarray = c("Critical", "High", "Moderate", "Low"))),
        yaxis = overview_ov_axis_static("Number of countries", extras = list(rangemode = "tozero", tickformat = ",d"))
      ) %>%
      overview_plotly_config()
    p
  })
  
  output$overview_scatter_note <- renderUI({
    x_var <- input$overview_scatter_x
    scale <- if (!is.null(x_var) && x_var %in% OVERVIEW_SCATTER_LOG_X) input$overview_scatter_xscale else "linear"
    log_note <- if (is.null(scale) || scale == "linear" || is.null(x_var) || !x_var %in% OVERVIEW_SCATTER_LOG_X) {
      NULL
    } else {
      lab <- switch(as.character(scale), "log2" = "2", "loge" = "e", "log10" = "10", "2")
      paste0(" X-axis uses a logarithmic transform (base ", lab, ").")
    }
    tags$p(
      class = "overview-caption",
      style = "margin-top: 10px; margin-bottom: 0;",
      tags$strong("Note:"),
      " Dashed line = ordinary least squares best fit; equation and R² update with your selections (in axis coordinates).",
      log_note
    )
  })

  output$overview_scatter_plot <- renderPlotly({
    x_var <- input$overview_scatter_x
    y_var <- input$overview_scatter_y
    if (is.null(x_var) || is.null(y_var) || !nzchar(x_var) || !nzchar(y_var)) {
      return(plot_ly() %>% add_annotations(text = "Select variables", x = 0.5, y = 0.5, showarrow = FALSE) %>%
               layout(xaxis = list(showticklabels = FALSE), yaxis = list(showticklabels = FALSE)))
    }
    scale <- if (x_var %in% OVERVIEW_SCATTER_LOG_X) input$overview_scatter_xscale else "linear"
    d <- filtered_summary() %>%
      filter(!is.na(.data[[y_var]]), !is.na(.data[[x_var]]))
    if (x_var %in% c("population", "gdp_per_capita")) {
      d <- d %>% filter(.data[[x_var]] > 0)
    }
    if (nrow(d) == 0) {
      return(plot_ly() %>% add_annotations(text = "No data available", x = 0.5, y = 0.5, showarrow = FALSE) %>%
               layout(xaxis = list(showticklabels = FALSE), yaxis = list(showticklabels = FALSE)))
    }
    xvals <- overview_scatter_get_x(d[[x_var]], x_var, scale)
    yvals <- d[[y_var]]
    xlab <- overview_scatter_x_label(x_var, scale)
    ylab <- overview_scatter_y_label(y_var)
    line_color <- if (y_var == "undernourishment_rate") "#1e40af" else "#5b21b6"
    marker_color <- if (y_var == "undernourishment_rate") "#2563eb" else "#7c3aed"
    hover <- overview_scatter_hover_text(d, x_var, y_var)
    y_extras <- if (y_var %in% c("undernourishment_rate", "hunger_vulnerability_rating")) {
      list(range = c(0, 100), dtick = 25)
    } else {
      list(rangemode = "tozero")
    }
    plot_ly(
      x = xvals,
      y = yvals,
      text = hover,
      hoverinfo = "text",
      type = "scatter",
      mode = "markers",
      marker = list(size = 9, opacity = 0.78, color = marker_color, line = list(width = 0.5, color = "rgba(255,255,255,0.9)"))
    ) %>%
      overview_add_ols_line(xvals, yvals, line_color = line_color) %>%
      layout(
        paper_bgcolor = "#f8fafc",
        plot_bgcolor = "#ffffff",
        font = overview_plot_font,
        margin = overview_plot_margin,
        dragmode = FALSE,
        xaxis = overview_ov_axis_static(xlab, extras = overview_scatter_x_axis_extras(x_var)),
        yaxis = overview_ov_axis_static(ylab, extras = y_extras)
      ) %>%
      overview_plotly_config(
        displayModeBar = TRUE,
        modeBarButtonsToRemove = c("lasso2d", "select2d", "zoomIn2d", "zoomOut2d", "pan2d", "autoScale2d")
      )
  })

  output$gdp_poverty_plot <- renderPlotly({
    p <- plot_ly(
                 filtered_summary(),
                 x = ~gdp_per_capita, 
                 y = ~poverty_display,
                 text = ~paste("Country:", country, "<br>GDP per Capita: $", round(gdp_per_capita, 0),
                              "<br>Poverty Rate:", round(poverty_display, 1), "%<br>",
                              "Vulnerability Score:", round(hunger_vulnerability_rating, 1)),
                 hoverinfo = "text",
                 type = "scatter", mode = "markers",
                 marker = list(
                   size = 8,
                   opacity = 0.7,
                   color = ~hunger_vulnerability_rating,
                   colorscale = list(
                     c(0, "#2E8B57"),
                     c(0.5, "#FFD700"),
                     c(1, "#8B0000")
                   ),
                   showscale = TRUE,
                   colorbar = list(
                     title = "Vulnerability",
                     len = 0.6,
                     tickvals = c(0, 25, 50, 75, 100),
                     ticktext = c("0", "25", "50", "75", "100")
                   )
                 )
    ) %>%
      layout(
        title = list(text = "Economic Conditions and Hunger Vulnerability", font = list(size = 16)),
        xaxis = list(title = "GDP per Capita (USD, linear)", rangemode = "tozero"),
        yaxis = list(title = "Poverty Rate (%)", range = c(0, 100), dtick = 25)
      ) %>%
      config(displayModeBar = FALSE)
    p
  })
  
  output$agriculture_plot <- renderPlotly({
    plot_data <- filtered_summary() %>%
      distinct(country, .keep_all = TRUE)
    
    p <- plot_ly(plot_data,
                 x = ~agriculture_land, 
                 y = ~crop_production,
                 text = ~paste("Country:", country, "<br>Agricultural Land:", round(agriculture_land, 1), "%",
                              "<br>Crop Production Index:", round(crop_production, 1), "<br>",
                              "Vulnerability Score:", round(hunger_vulnerability_rating, 1)),
                 hoverinfo = "text",
                 type = "scatter", mode = "markers",
                 marker = list(
                   size = 8,
                   opacity = 0.7,
                   line = list(width = 0.5, color = 'rgba(0,0,0,0.1)'),
                   color = ~hunger_vulnerability_rating,
                   colorscale = list(
                     c(0, "#2E8B57"),
                     c(0.5, "#FFD700"),
                     c(1, "#8B0000")
                   ),
                   showscale = TRUE,
                   colorbar = list(
                     title = "Hunger Vulnerability Score",
                     len = 0.6,
                     tickvals = c(0, 25, 50, 75, 100),
                     ticktext = c("0", "25", "50", "75", "100")
                   )
                 )) %>%
      layout(
        title = list(text = "Agricultural Capacity and Hunger Vulnerability", font = list(size = 16)),
        xaxis = list(title = "Agricultural Land (% of total land)", range = c(0, 100), dtick = 25),
        yaxis = list(title = "Crop Production Index", rangemode = "tozero")
      ) %>%
      config(displayModeBar = FALSE)
    p
  })
  
  # Data table
  # Full data table with ALL columns
  output$data_table_full <- DT::renderDataTable({
    data_full <- filtered_summary() %>%
        mutate(
        # Format numeric columns
        population_millions = round(population / 1e6, 2),
        gdp_billions = round(gdp / 1e9, 2),
          gdp_per_capita = round(gdp_per_capita, 0),
        inflation = round(inflation, 2),
        poverty = round(poverty, 2),
        agriculture_land = round(agriculture_land, 2),
        crop_production = round(crop_production / 1e6, 2),
        rural_pop = round(rural_pop, 2),
        life_expectancy = round(life_expectancy, 2),
        infant_mortality = round(infant_mortality, 2),
        literacy = round(literacy, 2),
        undernourishment_rate = round(undernourishment_rate, 2),
        grfc_ipc_phase = round(grfc_ipc_phase, 1),
        grfc_population_phase3_plus = round(grfc_population_phase3_plus / 1e6, 2),
        stunting_rate = round(stunting_rate, 2),
        poverty_below_3usd = round(poverty_below_3usd, 2),
        climate_vulnerability_index = round(climate_vulnerability_index, 2),
        total_displaced_latest = round(total_displaced_latest / 1e6, 2),
        total_disasters_5yr = round(total_disasters_5yr, 1),
        avg_import_share = round(avg_import_share, 2),
        max_import_share = round(max_import_share, 2),
        food_supply_kcal = round(food_supply_kcal, 0),
        water_per_capita = round(water_per_capita, 0),
        ag_water_withdrawals = round(ag_water_withdrawals, 2),
        usda_tfp_index = round(usda_tfp_index, 2),
        ghi_score = round(ghi_score, 1),
        total_fatalities = round(total_fatalities, 0),
        wpr_malnutrition_rate = round(wpr_malnutrition_rate, 2),
        hunger_vulnerability_rating = round(hunger_vulnerability_rating, 2)
      ) %>%
      select(
        # Basic Info
        country, latest_year, iso3c, region,
        # Demographics
        population_millions, rural_pop, literacy,
        # Economy
        gdp_billions, gdp_per_capita, inflation, poverty, poverty_below_3usd,
        # Agriculture & Food
        agriculture_land, crop_production, food_supply_kcal, avg_import_share, max_import_share, usda_tfp_index,
        # Health
        life_expectancy, infant_mortality, stunting_rate, undernourishment_rate, wpr_malnutrition_rate,
        # Climate & Environment
        climate_vulnerability_index, water_per_capita, ag_water_withdrawals,
        # Crisis Indicators
        grfc_ipc_phase, grfc_population_phase3_plus, total_displaced_latest,
        has_active_conflict, conflict_intensity, total_fatalities,
        total_disasters_5yr, latest_disaster_year,
        major_hunger_outbreak_21st, latest_outbreak_year, total_outbreaks,
        # Comparison
        ghi_score,
        # Final Score
        hunger_vulnerability_rating
        ) %>%
        rename(
          Country = country,
          Year = latest_year,
        "ISO Code" = iso3c,
        Region = region,
        "Population (M)" = population_millions,
        "Rural Population (%)" = rural_pop,
        "Literacy Rate (%)" = literacy,
        "GDP (B $)" = gdp_billions,
          "GDP per Capita ($)" = gdp_per_capita,
        "Inflation (%)" = inflation,
          "Poverty Rate (%)" = poverty,
        "Poverty <$3/day (%)" = poverty_below_3usd,
          "Agricultural Land (%)" = agriculture_land,
        "Crop Production (M $)" = crop_production,
        "Food Supply (kcal/day)" = food_supply_kcal,
        "Avg Import Share (%)" = avg_import_share,
        "Max Import Share (%)" = max_import_share,
        "USDA TFP Index" = usda_tfp_index,
          "Life Expectancy" = life_expectancy,
        "Infant Mortality" = infant_mortality,
        "Stunting Rate (%)" = stunting_rate,
        "Undernourishment (%)" = undernourishment_rate,
        "WPR Malnutrition (%)" = wpr_malnutrition_rate,
        "Climate Vulnerability" = climate_vulnerability_index,
        "Water per Capita (m³)" = water_per_capita,
        "Ag Water Withdrawals (%)" = ag_water_withdrawals,
        "GRFC IPC Phase" = grfc_ipc_phase,
        "GRFC Phase 3+ Pop (M)" = grfc_population_phase3_plus,
        "Displaced People (M)" = total_displaced_latest,
        "Active Conflict" = has_active_conflict,
        "Conflict Intensity" = conflict_intensity,
        "Total Fatalities" = total_fatalities,
        "Disasters (5yr)" = total_disasters_5yr,
        "Latest Disaster Year" = latest_disaster_year,
        "Major Outbreak 21st C" = major_hunger_outbreak_21st,
        "Latest Outbreak Year" = latest_outbreak_year,
        "Total Outbreaks" = total_outbreaks,
        "GHI Score" = ghi_score,
        "Vulnerability Score" = hunger_vulnerability_rating
      )
    
    DT::datatable(
      data_full,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        scrollY = "600px",
        dom = 'Bfrtip',
        buttons = list(
          list(extend = 'copy', title = 'Global Hunger Data'),
          list(extend = 'csv', filename = 'hunger_data', title = 'Global Hunger Data'),
          list(extend = 'excel', filename = 'hunger_data', title = 'Global Hunger Data')
        ),
        columnDefs = list(
          list(width = '120px', targets = c(0, 1, 2, 3)),  # Country, Year, ISO, Region
          list(width = '100px', targets = c(4:length(names(data_full))-1))  # All other columns
        ),
        autoWidth = FALSE
      ),
      extensions = 'Buttons',
      filter = 'top',
      class = 'cell-border stripe hover',
      rownames = FALSE
    ) %>%
      formatStyle(
        columns = 1:ncol(data_full),
        padding = '8px',
        fontSize = '12px'
      ) %>%
      formatStyle(
        "Vulnerability Score",
        backgroundColor = styleInterval(
          c(25, 50, 75),
          c("#d4edda", "#fff3cd", "#ffeaa7", "#f8d7da")
        ),
        fontWeight = 'bold'
      )
  })
  
  # NOTE: Removed legacy output$data_table alias.
  # If you need another table output, define it as its own renderDataTable.
  
  # Countries with likely inaccurate or highly unreliable official data (grey on map, disclaimer on hover)
  # Match by ISO3 so we don't depend on country name variants (WB uses "Korea, Dem. People's Rep." etc.)
  iso3c_likely_inaccurate <- c("PRK", "ERI", "TKM")  # North Korea, Eritrea, Turkmenistan
  # Country-name fallback in case iso3c is missing for these in the data
  countries_likely_inaccurate_names <- c("North Korea", "Korea, Dem. People's Rep.", "Democratic People's Republic of Korea", "Eritrea", "Turkmenistan")
  countries_likely_inaccurate_data <- c(
    "North Korea", "Democratic People's Republic of Korea", "Korea, Dem. People's Rep.", "Eritrea", "Turkmenistan"
  )
  
  # Store map data for click handler (reactive)
  map_data_reactive <- reactive({
    # Map-specific filtering so sidebar map controls actually change the map
    data <- latest_summary %>%
      distinct(country, .keep_all = TRUE) %>%
      mutate(iso3c = toupper(trimws(as.character(iso3c)))) %>%
      filter(!is.na(iso3c) & nzchar(iso3c)) %>%
      dplyr::left_join(hunger_score_components, by = c("country", "iso3c"))

    w_map <- vapply(seq_along(MAP_FORMULA_WEIGHT_IDS), function(i) {
      x <- input[[MAP_FORMULA_WEIGHT_IDS[i]]]
      if (is.null(x) || length(x) != 1L) return(1)
      pmax(0, pmin(2, as.numeric(x)))
    }, numeric(1))
    mat_map <- as.matrix(data[, HUNGER_SCORE_COMPONENT_COLS, drop = FALSE])
    mat_map[is.na(mat_map)] <- 0
    data$hunger_vulnerability_rating <- pmax(
      0,
      pmin(100, round(rowSums(sweep(mat_map, 2L, w_map, `*`)), 1))
    )
    data <- dplyr::select(data, -dplyr::all_of(HUNGER_SCORE_COMPONENT_COLS))

    data <- data %>%
      mutate(
        hunger_vulnerability_rating = ifelse(is.na(hunger_vulnerability_rating), 0, hunger_vulnerability_rating),
        map_active = TRUE
      )

    passes_range <- function(vals, range) {
      if (is.null(range) || length(range) != 2) return(rep(TRUE, length(vals)))
      is.na(vals) | (vals >= range[1] & vals <= range[2])
    }

    # Excluded countries stay on the map as outlines only (no fill color, no hover).
    if (!is.null(input$selected_countries) && !("All" %in% input$selected_countries)) {
      data$map_active <- data$map_active & data$country %in% input$selected_countries
    }

    if (!is.null(input$year_range) && length(input$year_range) >= 2) {
      data$map_active <- data$map_active & (
        is.na(data$latest_year) |
          (data$latest_year >= input$year_range[1] & data$latest_year <= input$year_range[2])
      )
    }

    if (!is.null(input$vulnerability_range)) {
      data$map_active <- data$map_active & (
        data$hunger_vulnerability_rating >= input$vulnerability_range[1] &
          data$hunger_vulnerability_rating <= input$vulnerability_range[2]
      )
    }

    active_filters <- input$map_active_filters
    if (!is.null(active_filters) && length(active_filters) > 0) {
      if ("gdp_per_capita" %in% active_filters && "gdp_per_capita" %in% names(data)) {
        data$map_active <- data$map_active & passes_range(data$gdp_per_capita, input$map_gdp_per_capita_range)
      }
      if ("poverty" %in% active_filters && "poverty" %in% names(data)) {
        data$map_active <- data$map_active & passes_range(data$poverty, input$map_poverty_range)
      }
      if ("life_expectancy" %in% active_filters && "life_expectancy" %in% names(data)) {
        data$map_active <- data$map_active & passes_range(data$life_expectancy, input$map_life_expectancy_range)
      }
      if ("undernourishment_rate" %in% active_filters && "undernourishment_rate" %in% names(data)) {
        data$map_active <- data$map_active & passes_range(data$undernourishment_rate, input$map_undernourishment_range)
      }
      if ("infant_mortality" %in% active_filters && "infant_mortality" %in% names(data)) {
        data$map_active <- data$map_active & passes_range(data$infant_mortality, input$map_infant_mortality_range)
      }
      if ("agriculture_land" %in% active_filters && "agriculture_land" %in% names(data)) {
        data$map_active <- data$map_active & passes_range(data$agriculture_land, input$map_agriculture_land_range)
      }
    }

    data %>% arrange(country)
  })

  observeEvent(input$map_formula_reset, {
    for (id in MAP_FORMULA_WEIGHT_IDS) shiny::updateSliderInput(session, id, value = 1)
  })

  observeEvent(input$map_formula_max, {
    for (id in MAP_FORMULA_WEIGHT_IDS) shiny::updateSliderInput(session, id, value = 2)
  })

  sc_w_slider_ids <- c(
    "sc_w_undernourishment", "sc_w_poverty", "sc_w_gdp", "sc_w_life_expectancy",
    "sc_w_stunting", "sc_w_climate", "sc_w_conflict", "sc_w_outbreak",
    "sc_w_trade", "sc_w_food_supply", "sc_w_water", "sc_w_displacement"
  )

  observeEvent(input$sc_formula_reset, {
    for (id in sc_w_slider_ids) shiny::updateSliderInput(session, id, value = 1)
  })

  `%||%` <- function(x, y) if (is.null(x)) y else x

  scenario_lab_input_row <- reactive({
    tibble::tibble(
      undernourishment_rate = input$sc_undernourishment %||% 0,
      poverty = input$sc_poverty %||% 0,
      poverty_below_3usd = NA_real_,
      gdp_per_capita = input$sc_gdp_pc %||% 0,
      life_expectancy = input$sc_life_exp %||% 70,
      stunting_rate = input$sc_stunting %||% 0,
      climate_vulnerability_index = input$sc_climate %||% 0,
      has_active_conflict = isTRUE(input$sc_has_conflict),
      conflict_intensity = input$sc_conflict %||% "None",
      major_hunger_outbreak_21st = isTRUE(input$sc_outbreak),
      grfc_ipc_phase = NA_real_,
      avg_import_share = input$sc_import_share %||% 0,
      food_supply_kcal = input$sc_food_kcal %||% 2500,
      water_per_capita = input$sc_water %||% 0,
      population = (input$sc_pop_m %||% 1) * 1e6,
      total_displaced_latest = (input$sc_displaced_k %||% 0) * 1000
    )
  })

  scenario_lab_core <- reactive({
    bd <- add_vulnerability_score_breakdown(scenario_lab_input_row())
    comps <- as.numeric(bd[1, HUNGER_SCORE_COMPONENT_COLS])
    w_sc <- vapply(sc_w_slider_ids, function(nm) {
      x <- input[[nm]]
      if (is.null(x) || length(x) != 1L) return(1)
      pmax(0, pmin(2, as.numeric(x)))
    }, numeric(1))
    weighted <- pmax(0, pmin(100, round(sum(comps * w_sc, na.rm = TRUE), 1)))
    contrib <- comps * w_sc
    list(bd = bd, comps = comps, weighted = weighted, contrib = contrib, w_sc = w_sc)
  })

  output$scenario_country_silhouette <- renderUI({
    core <- scenario_lab_core()
    sc <- core$weighted
    u <- pmax(0, pmin(100, sc)) / 100
    fill_hex <- grDevices::rgb(
      grDevices::colorRamp(c("#2d8a54", "#e6c619", "#b91c1c"))(u),
      maxColorValue = 255
    )
    shape <- input$sc_vis_shape %||% "continental"
    tags$div(
      class = "scenario-country-wrap",
      tags$div(
        class = "scenario-country-svg-host",
        scenario_country_landscape_svg(fill_hex, list(shape = shape))
      ),
      tags$p(
        style = paste0(
          "margin: 16px 0 4px; font-size: 28px; font-weight: 800; color: ",
          if (sc >= 75) "#b91c1c" else if (sc >= 50) "#c2410c" else if (sc >= 25) "#a16207" else "#15803d",
          ";"
        ),
        round(sc, 1), tags$span(style = "font-size: 16px; font-weight: 600; color: #64748b;", " / 100")
      ),
      tags$p(
        style = "margin: 0; font-size: 13px; color: #64748b; max-width: 560px; margin-left: auto; margin-right: auto; line-height: 1.5;",
        "Land tint reflects your vulnerability score (green → yellow → red). ",
        "Country shape is cosmetic only and does not change the score."
      )
    )
  })

  output$scenario_score_ui <- renderUI({
    core <- scenario_lab_core()
    weighted <- core$weighted
    default_tot <- as.numeric(core$bd$hunger_vulnerability_rating[1])
    tags$div(
      style = "padding: 12px; background: #f8fafc; border-radius: 8px; border: 1px solid #e2e8f0;",
      tags$p(
        style = "margin: 0 0 8px 0; font-size: 18px; font-weight: 700; color: #0f172a;",
        "Weighted score: ", weighted, " / 100"
      ),
      tags$p(
        style = "margin: 0; font-size: 13px; color: #64748b;",
        "Published index (sum of pillar points, cap 100): ", default_tot, " / 100 — same as when every multiplier is ×1."
      )
    )
  })

  output$scenario_component_plot <- renderPlotly({
    core <- scenario_lab_core()
    contrib <- core$contrib
    labs <- c(
      "Undernourishment", "Poverty", "GDP", "Life exp.", "Stunting", "Climate",
      "Conflict", "Outbreak", "Trade", "Food", "Water", "Displacement"
    )
    plotly::plot_ly(
      x = labs,
      y = contrib,
      type = "bar",
      marker = list(color = "#0e7490")
    ) %>%
      plotly::layout(
        xaxis = list(title = "", tickangle = -35),
        yaxis = list(title = "Contribution (multiplier × points)"),
        margin = list(b = 120)
      )
  })

  outputOptions(output, "scenario_country_silhouette", suspendWhenHidden = FALSE)
  outputOptions(output, "scenario_score_ui", suspendWhenHidden = FALSE)
  outputOptions(output, "scenario_component_plot", suspendWhenHidden = FALSE)
  
  # Interactive map
  output$hunger_map <- renderPlotly({
    tryCatch({
    map_data <- map_data_reactive() %>%
      dplyr::left_join(hunger_score_components, by = c("country", "iso3c")) %>%
      mutate(
        display_country = ifelse(country == "Turkiye", "Turkey", country),
        likely_inaccurate = (!is.na(iso3c) & (iso3c %in% iso3c_likely_inaccurate)) | (country %in% countries_likely_inaccurate_names),
        .hover_score = ifelse(
          is.na(hunger_vulnerability_rating),
          "No data",
          sprintf("%.1f/100", hunger_vulnerability_rating)
        ),
        .hover_population = dplyr::case_when(
          is.na(population) ~ "No data",
          population >= 1e9 ~ paste0(round(population / 1e9, 2), "B"),
          population >= 1e6 ~ paste0(round(population / 1e6, 2), "M"),
          TRUE ~ format(round(population, 0), big.mark = ",", scientific = FALSE)
        ),
        .hover_area = dplyr::case_when(
          !is.na(land_area_km2) ~ paste0(
            format(round(land_area_km2, 0), big.mark = ",", scientific = FALSE), " km²"
          ),
          TRUE ~ "Not Reported by World Bank"
        ),
        hover_text = ifelse(
          !map_active,
          "",
          ifelse(
            likely_inaccurate,
            paste0(
              "<b>", display_country, "</b><br>",
              "<span style='color:#c62828;'><b>⚠️ Likely inaccurate data</b></span><br>",
              "<b>Vulnerability score:</b> ", .hover_score, " (may not reflect reality)<br>",
              "<b>Population:</b> ", .hover_population, "<br>",
              "<b>Area:</b> ", .hover_area
            ),
            paste0(
              "<b>", display_country, "</b><br>",
              "<b>Vulnerability score:</b> ", .hover_score, "<br>",
              "<b>Population:</b> ", .hover_population, "<br>",
              "<b>Area:</b> ", .hover_area
            )
          )
        ),
        map_z = ifelse(is.na(hunger_vulnerability_rating), 0, hunger_vulnerability_rating),
        # Single trace: inaccurate get z = -1 so they map to grey (colorscale position 0)
        map_z_draw = ifelse(likely_inaccurate, -1, map_z),
        country_for_click = country
      )
    
    # DEBUG: map grey countries — print when map tab is rendered
    inaccurate_rows <- map_data %>% filter(likely_inaccurate)
    message("[MAP DEBUG] Countries marked likely_inaccurate: ", nrow(inaccurate_rows))
    if (nrow(inaccurate_rows) > 0) {
      for (i in seq_len(nrow(inaccurate_rows))) {
        r <- inaccurate_rows %>% slice(i)
        message("  - country=", r$country, " | iso3c=", r$iso3c, " | map_z_draw=", r$map_z_draw, " | map_z=", r$map_z)
      }
    }
    # Check if PRK/ERI/TKM appear anywhere in map_data (even if not marked inaccurate)
    check_iso <- map_data %>% filter(iso3c %in% iso3c_likely_inaccurate)
    message("[MAP DEBUG] Rows with iso3c in PRK/ERI/TKM: ", nrow(check_iso))
    if (nrow(check_iso) > 0) {
      for (i in seq_len(nrow(check_iso))) {
        r <- check_iso %>% slice(i)
        message("  - country=", r$country, " | iso3c=", r$iso3c, " | likely_inaccurate=", r$likely_inaccurate, " | map_z_draw=", r$map_z_draw)
      }
    }
    message("[MAP DEBUG] map_z_draw range: ", min(map_data$map_z_draw, na.rm = TRUE), " to ", max(map_data$map_z_draw, na.rm = TRUE))
    
    zmin <- -1
    zmax <- 100
    map_score_colorscale <- list(
      c(0, "#6B6B6B"),
      c(0.005, "#2E8B57"),
      c(0.25, "#90EE90"),
      c(0.5, "#FFD700"),
      c(0.75, "#FF6347"),
      c(1, "#8B0000")
    )
    map_colorbar <- list(
      title = "Vulnerability Score (0–100)",
      tickvals = c(0, 25, 50, 75, 100),
      ticktext = c("0 (Low)", "25", "50", "75", "100 (High)"),
      len = 0.85,
      thickness = 16,
      y = 0.5,
      yanchor = "middle"
    )

    if (nrow(map_data) == 0) {
      p <- plot_ly(type = "choropleth", locations = character(0), locationmode = "ISO-3", z = numeric(0),
                   colorscale = list(c(0, "#2E8B57"), c(1, "#8B0000")), zmin = 0, zmax = 100, showscale = TRUE,
                   colorbar = map_colorbar)
    } else {
      df <- as.data.frame(map_data)
      outline_df <- df[!df$map_active, , drop = FALSE]
      active_df <- df[df$map_active, , drop = FALSE]

      p <- plot_ly()

      if (nrow(outline_df) > 0) {
        p <- p %>% plotly::add_trace(
          type = "choropleth",
          locations = outline_df$iso3c,
          locationmode = "ISO-3",
          z = rep(0, nrow(outline_df)),
          colorscale = list(c(0, "rgba(0,0,0,0)"), c(1, "rgba(0,0,0,0)")),
          zmin = 0,
          zmax = 1,
          zauto = FALSE,
          showscale = FALSE,
          hoverinfo = "skip",
          marker = list(line = list(color = "#64748b", width = 0.75)),
          inherit = FALSE
        )
      }

      if (nrow(active_df) > 0) {
        p <- p %>% plotly::add_trace(
          type = "choropleth",
          locations = active_df$iso3c,
          locationmode = "ISO-3",
          z = active_df$map_z_draw,
          text = active_df$hover_text,
          hoverinfo = "text",
          customdata = active_df$country_for_click,
          colorscale = map_score_colorscale,
          zmin = zmin,
          zmax = zmax,
          zauto = FALSE,
          showscale = TRUE,
          colorbar = map_colorbar,
          marker = list(line = list(color = "rgba(255,255,255,0.45)", width = 0.4)),
          inherit = FALSE
        )
      } else if (nrow(outline_df) == 0) {
        p <- plot_ly(type = "choropleth", locations = character(0), locationmode = "ISO-3", z = numeric(0),
                     colorscale = map_score_colorscale, zmin = zmin, zmax = zmax, showscale = TRUE, colorbar = map_colorbar)
      }
    }
    p <- p %>%
      layout(
        title = list(
          text = "Global Hunger Vulnerability Map (0–100) — multipliers below — Click country for details",
          font = list(size = 16),
          y = 0.98,
          yref = "paper"
        ),
        geo = list(
          showframe = FALSE,
          showcoastlines = TRUE,
          projection = list(type = "natural earth"),
          bgcolor = "#f8f9fa"
        ),
        margin = list(t = 80, b = 60, l = 20, r = 20)
      ) %>%
      config(displayModeBar = FALSE) %>%
      event_register("plotly_click")
    
    p
    }, error = function(e) {
      msg <- conditionMessage(e)
      message("[MAP ERROR] ", msg)
      plot_ly() %>%
        add_annotations(
          text = paste0("Map unavailable: ", msg),
          x = 0.5, y = 0.5, xref = "paper", yref = "paper",
          showarrow = FALSE, font = list(size = 13, color = "#b91c1c")
        ) %>%
        layout(
          xaxis = list(visible = FALSE),
          yaxis = list(visible = FALSE),
          margin = list(t = 40, b = 40, l = 40, r = 40)
        ) %>%
        config(displayModeBar = FALSE)
    })
  })
  
  # Handle map clicks to navigate to country details
  observeEvent(event_data("plotly_click"), {
    click_data <- event_data("plotly_click")
    if (!is.null(click_data)) {
      # Trace 0 = filtered-out outlines (no interaction); trace 1 = active countries
      if (!is.null(click_data$curveNumber) && click_data$curveNumber == 0) {
        return()
      }

      # Try customdata first (most reliable)
      country_name <- click_data$customdata
      
      # If customdata not available, try location
      if (is.null(country_name) || is.na(country_name) || country_name == "") {
        country_name <- click_data$location
      }
      
      # If still no country name, use point number as fallback
      if (is.null(country_name) || is.na(country_name) || country_name == "") {
        point_number <- click_data$pointNumber
        if (!is.null(point_number) && !is.na(point_number)) {
          map_data <- map_data_reactive() %>% filter(map_active)
          if (nrow(map_data) > 0 && point_number >= 0 && point_number < nrow(map_data)) {
            country_name <- map_data$country[point_number + 1]
          }
        }
      }
      
      # If we have a country name, try to match it
      if (!is.null(country_name) && !is.na(country_name) && country_name != "") {
        # Try exact match first
        country_match <- latest_summary %>%
          distinct(country, .keep_all = TRUE) %>%
          filter(tolower(country) == tolower(country_name))
        
        if (nrow(country_match) > 0) {
          matched_country <- country_match$country[1]
        } else {
          # Try fuzzy matching - find closest match
          all_countries <- unique(latest_summary$country)
          matched_country <- all_countries[which.min(adist(tolower(country_name), tolower(all_countries)))]
        }
        
        # Update UI if we found a match
        if (!is.null(matched_country) && !is.na(matched_country)) {
          # Check if this country exists in the dropdown
          available_countries <- sort(unique(latest_summary$country))
          if (matched_country %in% available_countries) {
            updateSelectInput(session, "selected_country", selected = matched_country)
            updateTabItems(session, "tabs", "country_details")
          }
        }
      }
    }
  })
  
  # Time series plot with forecast functionality
  output$timeseries_plot <- renderPlotly({
    # Variable name mapping: user-friendly names to column names and display info
    var_info <- list(
      "SP.POP.TOTL" = list(name = "Global Population", unit = "Billions", scale = 1e9, format = "B"),
      "NY.GDP.MKTP.CD" = list(name = "Global GDP", unit = "Trillions (US$)", scale = 1e12, format = "T"),
      "NY.GDP.PCAP.CD" = list(name = "GDP per Capita", unit = "US$", scale = 1, format = "$"),
      "SI.POV.DDAY" = list(name = "Poverty Rate", unit = "Percentage", scale = 1, format = "%"),
      "SP.DYN.LE00.IN" = list(name = "Life Expectancy", unit = "Years", scale = 1, format = ""),
      "SP.DYN.IMRT.IN" = list(name = "Infant Mortality", unit = "per 1,000 live births", scale = 1, format = ""),
      "AG.LND.AGRI.ZS" = list(name = "Agricultural Land", unit = "Percentage of land area", scale = 1, format = "%"),
      "SP.RUR.TOTL.ZS" = list(name = "Rural Population", unit = "Percentage", scale = 1, format = "%"),
      "FP.CPI.TOTL.ZG" = list(name = "Inflation Rate", unit = "Percentage", scale = 1, format = "%"),
      "hunger_vulnerability_rating" = list(name = "Average Vulnerability Score", unit = "Score (0-100)", scale = 1, format = "")
    )
    
    selected_var <- input$trend_variable
    var_details <- var_info[[selected_var]]
    
    if(is.null(var_details)) {
      # Fallback
      var_details <- list(name = selected_var, unit = "", scale = 1, format = "")
    }
    
    # Get data — World Bank WLD for standard indicators; population-weighted index for vulnerability
    if (selected_var == "hunger_vulnerability_rating") {
      ts_data <- hunger_data %>%
        filter(!is.na(SP.POP.TOTL), SP.POP.TOTL > 0) %>%
        group_by(year) %>%
        summarise(
          avg_poverty = weighted.mean(SI.POV.DDAY, SP.POP.TOTL, na.rm = TRUE),
          avg_gdp_pc = weighted.mean(NY.GDP.PCAP.CD, SP.POP.TOTL, na.rm = TRUE),
          avg_life_exp = weighted.mean(SP.DYN.LE00.IN, SP.POP.TOTL, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        mutate(
          poverty_score = pmin(ifelse(is.na(avg_poverty), 0, avg_poverty) * 0.4, 20),
          gdp_score = case_when(
            is.na(avg_gdp_pc) ~ 0,
            avg_gdp_pc < 1000 ~ 15,
            avg_gdp_pc < 3000 ~ 12,
            avg_gdp_pc < 10000 ~ 8,
            avg_gdp_pc < 20000 ~ 4,
            TRUE ~ 0
          ),
          life_expectancy_score = case_when(
            is.na(avg_life_exp) ~ 0,
            avg_life_exp < 50 ~ 10,
            avg_life_exp < 60 ~ 8,
            avg_life_exp < 70 ~ 5,
            TRUE ~ 0
          ),
          undernourishment_score = pmin(ifelse(is.na(avg_poverty), 0, avg_poverty) * 0.8, 40),
          variable_value = pmin(pmax(
            poverty_score + gdp_score + life_expectancy_score + undernourishment_score,
            0
          ), 98)
        ) %>%
        filter(!is.na(variable_value)) %>%
        select(year, variable_value) %>%
        arrange(year)
    } else if (nrow(world_bank_timeseries) > 0 && selected_var %in% names(world_bank_timeseries)) {
      ts_data <- world_bank_timeseries %>%
        transmute(
          year = as.numeric(year),
          variable_value = as.numeric(.data[[selected_var]])
        ) %>%
        filter(!is.na(variable_value), is.finite(variable_value))
      if (selected_var == "SP.DYN.LE00.IN") {
        ts_data <- ts_data %>% filter(variable_value >= 15, variable_value <= 100)
      }
      if (selected_var == "FP.CPI.TOTL.ZG") {
        ts_data <- ts_data %>% filter(variable_value >= -50, variable_value <= 100)
      }
    } else {
      # Fallback if WLD rows missing: population-weighted mean for rates, deduped sum for level totals
      use_sum <- selected_var %in% c("SP.POP.TOTL", "NY.GDP.MKTP.CD")
      if (selected_var == "SP.DYN.LE00.IN") {
        hunger_data_var <- hunger_data %>%
          filter(!is.na(.data[[selected_var]]), .data[[selected_var]] >= 15, .data[[selected_var]] <= 100)
      } else {
        hunger_data_var <- hunger_data %>% filter(!is.na(.data[[selected_var]]))
      }
      ts_data <- hunger_data_var %>%
        group_by(year) %>%
        summarise(
          variable_value = if (use_sum) {
            sum(.data[[selected_var]], na.rm = TRUE)
          } else if (any(!is.na(SP.POP.TOTL))) {
            weighted.mean(.data[[selected_var]], SP.POP.TOTL, na.rm = TRUE)
          } else {
            mean(.data[[selected_var]], na.rm = TRUE)
          },
          .groups = "drop"
        ) %>%
        filter(!is.na(variable_value), is.finite(variable_value))
    }
    
    # Scale the values for display
    ts_data <- ts_data %>%
      mutate(
        display_value = variable_value / var_details$scale,
        year = as.numeric(year)
      ) %>%
      arrange(year)
    
    # Check if we have data
    if(nrow(ts_data) == 0) {
      p <- plot_ly() %>%
        add_annotations(
          text = paste("No data available for", var_details$name),
          x = 0.5, y = 0.5,
          showarrow = FALSE,
          font = list(size = 16, color = "#666")
        ) %>%
        layout(
          xaxis = list(showgrid = FALSE, showticklabels = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        ) %>%
        config(displayModeBar = TRUE)
      return(p)
    }
    
    # Get year range
    min_year <- min(ts_data$year, na.rm = TRUE)
    max_year <- max(ts_data$year, na.rm = TRUE)
    
    # Create main plot
    p <- plot_ly(
      data = ts_data,
      x = ~year,
      y = ~display_value,
      type = "scatter",
      mode = "lines+markers",
      name = var_details$name,
      line = list(
        color = "#667eea",
        width = 4,
        shape = "spline"
      ),
      marker = list(
        color = "#764ba2",
        size = 8,
        line = list(color = "white", width = 2)
      ),
      hovertemplate = paste(
        "<b>%{x}</b><br>",
        var_details$name, ": %{y:.2f}", var_details$format,
        "<extra></extra>"
      )
    )
    
    # Add forecast if enabled (recent-window trend, anchored at last observation)
    if (input$show_forecast && nrow(ts_data) >= 3) {
      forecast_years <- input$forecast_years
      forecast_data <- build_timeseries_forecast(
        ts_data = ts_data %>% select(year, variable_value),
        variable_code = selected_var,
        forecast_years = forecast_years,
        scale = var_details$scale
      )
      if (!is.null(forecast_data) && nrow(forecast_data) > 1) {
        p <- p %>%
          add_trace(
            data = forecast_data,
            x = ~year,
            y = ~display_value,
            type = "scatter",
            mode = "lines+markers",
            name = paste("Forecast (", forecast_years, " years)"),
            line = list(color = "#f5576c", width = 3, dash = "dash"),
            marker = list(color = "#f5576c", size = 6, symbol = "diamond"),
            hovertemplate = paste("<b>%{x}</b><br>Forecast: %{y:.2f}", var_details$format, "<extra></extra>")
          )
      }
    }
    
    # Format y-axis based on variable type
    yaxis_title <- paste0(var_details$name, "<br><span style='font-size:11px; color:#666;'>(", var_details$unit, ")</span>")
    
    # Layout with improved aesthetics
    p <- p %>%
      layout(
        title = list(
          text = paste0(
            "<b>", var_details$name, " Over Time</b>",
            if (selected_var != "hunger_vulnerability_rating" && nrow(world_bank_timeseries) > 0) {
              "<br><span style='font-size:12px;color:#64748b;'>World Bank World aggregate (WLD)</span>"
            } else if (selected_var == "hunger_vulnerability_rating") {
              "<br><span style='font-size:12px;color:#64748b;'>Population-weighted country average (simplified index)</span>"
            } else {
              ""
            }
          ),
          font = list(size = 18, color = "#2c3e50"),
          x = 0.05,
          y = 0.95
        ),
        xaxis = list(
          title = list(text = "<b>Year</b>", font = list(size = 14, color = "#2c3e50")),
          showgrid = TRUE,
          gridcolor = "#e0e0e0",
          gridwidth = 1,
          showline = TRUE,
          linecolor = "#b0b0b0",
          linewidth = 2,
          mirror = TRUE,
          range = c(min_year - 0.5, ifelse(input$show_forecast, max_year + input$forecast_years + 0.5, max_year + 0.5))
        ),
        yaxis = list(
          title = list(text = yaxis_title, font = list(size = 14, color = "#2c3e50", standoff = 20)),
          showgrid = TRUE,
          gridcolor = "#e0e0e0",
          gridwidth = 1,
          showline = TRUE,
          linecolor = "#b0b0b0",
          linewidth = 2,
          mirror = TRUE,
          tickformat = ifelse(var_details$format == "$", "$,.0f", 
                             ifelse(var_details$format == "%", ".1f%",
                                   ifelse(var_details$format == "B", ".2fB",
                                         ifelse(var_details$format == "T", ".2fT", ".2f"))))
        ),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        margin = list(t = 80, b = 80, l = 100, r = 50),
        hovermode = "x unified",
        legend = list(
          orientation = "h",
          x = 0.5,
          xanchor = "center",
          y = -0.15,
          font = list(size = 12)
        )
      ) %>%
      config(
        displayModeBar = TRUE,
        modeBarButtonsToAdd = list("hoverClosestCartesian", "hoverCompareCartesian"),
        toImageButtonOptions = list(
          format = "jpeg",
          filename = paste0("timeseries_", gsub(" ", "_", tolower(var_details$name))),
          height = 600,
          width = 1000,
          scale = 2
        )
      )
    
    # Add custom tooltips for toolbar buttons (via HTML/CSS)
    p
  })
  
  # Data summary (kept for backward compatibility, but not displayed)
  output$data_summary <- renderText({
    summary_text <- capture.output(summary(filtered_summary() %>%
                                           select(population, gdp_per_capita, poverty, 
                                                  agriculture_land, life_expectancy)))
    paste(summary_text, collapse = "\n")
  })
  
  # Interactive Summary Visualizations
  output$summary_population_plot <- renderPlotly({
    tryCatch({
      data <- filtered_summary()
      x_vals <- data$population
      x_vals <- x_vals[!is.na(x_vals) & x_vals > 0] / 1e6
      explorer_hist_plot(
        x_vals = x_vals,
        title = "Population",
        x_label = "Population (millions)",
        color = explorer_hist_colors$population,
        filename = "population_distribution",
        nbinsx = 28,
        x_extras = list(rangemode = "tozero")
      )
    }, error = function(e) explorer_plot_empty(e$message))
  })

  output$summary_gdp_plot <- renderPlotly({
    tryCatch({
      data <- filtered_summary()
      x_vals <- data$gdp_per_capita
      x_vals <- log10(x_vals[!is.na(x_vals) & x_vals > 0])
      explorer_hist_plot(
        x_vals = x_vals,
        title = "GDP per capita (log scale)",
        x_label = "Log10(GDP per capita, USD)",
        color = explorer_hist_colors$gdp,
        filename = "gdp_distribution",
        nbinsx = 28
      )
    }, error = function(e) explorer_plot_empty(e$message))
  })
  
  # Overview tab: dedicated distribution plots (always use full dataset so they are never blank)
  output$overview_vulnerability_plot <- renderPlotly({
    tryCatch({
      data <- as.data.frame(latest_summary %>% distinct(country, .keep_all = TRUE) %>% filter(!is.na(hunger_vulnerability_rating)))
      if (nrow(data) == 0) {
        return(plot_ly() %>% add_annotations(text = "No vulnerability data available", x = 0.5, y = 0.5, showarrow = FALSE, font = list(size = 14)) %>%
                 layout(xaxis = list(showgrid = FALSE, showticklabels = FALSE), yaxis = list(showgrid = FALSE, showticklabels = FALSE, range = c(0, 1))) %>% config(displayModeBar = FALSE))
      }
      plot_ly(data = data, x = ~hunger_vulnerability_rating, type = "histogram", nbinsx = 28,
              marker = list(color = "rgba(60, 141, 188, 0.82)", line = list(color = "#ffffff", width = 1)), name = "Countries") %>%
        layout(
          paper_bgcolor = "#f8fafc",
          plot_bgcolor = "#ffffff",
          font = overview_plot_font,
          margin = modifyList(overview_plot_margin, list(t = 12, b = 52)),
          bargap = 0.06,
          dragmode = FALSE,
          xaxis = overview_ov_axis_static("Vulnerability score", extras = list(range = c(0, 100), dtick = 25)),
          yaxis = overview_ov_axis_static("Number of countries", extras = list(rangemode = "tozero", tickformat = ",d"))
        ) %>%
        overview_plotly_config()
    }, error = function(e) {
      plot_ly() %>% add_annotations(text = paste("Could not load:", e$message), x = 0.5, y = 0.5, showarrow = FALSE) %>%
        layout(xaxis = list(showticklabels = FALSE), yaxis = list(showticklabels = FALSE)) %>% overview_plotly_config()
    })
  })
  output$summary_poverty_plot <- renderPlotly({
    tryCatch({
      data <- latest_summary %>%
        distinct(country, .keep_all = TRUE)
      explorer_hist_from_col(
        data = data,
        col = "poverty_display",
        title = "Poverty rate",
        x_label = "Poverty rate (%)",
        color = explorer_hist_colors$poverty,
        filename = "poverty_distribution",
        nbinsx = 25,
        x_extras = list(range = c(0, 100), dtick = 25),
        transform = function(v) v[v >= 0]
      )
    }, error = function(e) explorer_plot_empty(e$message))
  })

  output$summary_life_expectancy_plot <- renderPlotly({
    tryCatch({
      data <- filtered_summary()
      explorer_hist_from_col(
        data = data,
        col = "life_expectancy",
        title = "Life expectancy",
        x_label = "Life expectancy (years)",
        color = explorer_hist_colors$life_expectancy,
        filename = "life_expectancy_distribution",
        nbinsx = 28,
        x_extras = list(range = c(45, 90), dtick = 5),
        transform = function(v) v[v > 0]
      )
    }, error = function(e) explorer_plot_empty(e$message))
  })

  output$summary_agriculture_plot <- renderPlotly({
    tryCatch({
      data <- filtered_summary()
      explorer_hist_from_col(
        data = data,
        col = "agriculture_land",
        title = "Agricultural land",
        x_label = "Agricultural land (%)",
        color = explorer_hist_colors$agriculture,
        filename = "agriculture_distribution",
        nbinsx = 28,
        x_extras = list(range = c(0, 100), dtick = 25),
        transform = function(v) v[v >= 0]
      )
    }, error = function(e) explorer_plot_empty(e$message))
  })

  output$summary_vulnerability_plot <- renderPlotly({
    tryCatch({
      data <- latest_summary %>%
        distinct(country, .keep_all = TRUE)
      explorer_hist_from_col(
        data = data,
        col = "hunger_vulnerability_rating",
        title = "Vulnerability score",
        x_label = "Vulnerability score (0–100)",
        color = explorer_hist_colors$vulnerability,
        filename = "vulnerability_distribution",
        nbinsx = 25,
        x_extras = list(range = c(0, 100), dtick = 25)
      )
    }, error = function(e) explorer_plot_empty(e$message))
  })

  output$summary_undernourishment_plot <- renderPlotly({
    tryCatch({
      data <- filtered_summary()
      explorer_hist_from_col(
        data = data,
        col = "undernourishment_rate",
        title = "Undernourishment rate",
        x_label = "Undernourishment (%)",
        color = explorer_hist_colors$undernourishment,
        filename = "undernourishment_distribution",
        nbinsx = 28,
        x_extras = list(rangemode = "tozero", dtick = 10),
        transform = function(v) v[v >= 0]
      )
    }, error = function(e) explorer_plot_empty(e$message))
  })

  output$summary_infant_mortality_plot <- renderPlotly({
    tryCatch({
      data <- filtered_summary()
      explorer_hist_from_col(
        data = data,
        col = "infant_mortality",
        title = "Infant mortality",
        x_label = "Infant mortality (per 1,000 live births)",
        color = explorer_hist_colors$infant_mortality,
        filename = "infant_mortality_distribution",
        nbinsx = 28,
        x_extras = list(rangemode = "tozero"),
        transform = function(v) v[v > 0]
      )
    }, error = function(e) explorer_plot_empty(e$message))
  })
  
  # Summary Statistics Table
  output$summary_stats_table <- DT::renderDataTable({
    data <- filtered_summary()
    
    # Calculate summary statistics for key numeric variables
    summary_stats <- data.frame(
      Variable = character(),
      Min = numeric(),
      Q1 = numeric(),
      Median = numeric(),
      Mean = numeric(),
      Q3 = numeric(),
      Max = numeric(),
      Missing = numeric(),
      stringsAsFactors = FALSE
    )
    
    # List of variables to summarize
    vars_to_summarize <- list(
      list(name = "Population (Millions)", col = "population", scale = 1e6),
      list(name = "GDP per Capita ($)", col = "gdp_per_capita", scale = 1),
      list(name = "Poverty Rate (%)", col = "poverty", scale = 1),
      list(name = "Agricultural Land (%)", col = "agriculture_land", scale = 1),
      list(name = "Life Expectancy (Years)", col = "life_expectancy", scale = 1),
      list(name = "Infant Mortality", col = "infant_mortality", scale = 1),
      list(name = "Undernourishment (%)", col = "undernourishment_rate", scale = 1),
      list(name = "Vulnerability Score", col = "hunger_vulnerability_rating", scale = 1)
    )
    
    for(var_info in vars_to_summarize) {
      var_name <- var_info$name
      var_col <- var_info$col
      var_scale <- var_info$scale
      
      if(var_col %in% names(data)) {
        values <- data[[var_col]] / var_scale
        values <- values[!is.na(values) & is.finite(values)]
        
        if(length(values) > 0) {
          summary_stats <- rbind(summary_stats, data.frame(
            Variable = var_name,
            Min = round(min(values, na.rm = TRUE), 2),
            Q1 = round(quantile(values, 0.25, na.rm = TRUE), 2),
            Median = round(median(values, na.rm = TRUE), 2),
            Mean = round(mean(values, na.rm = TRUE), 2),
            Q3 = round(quantile(values, 0.75, na.rm = TRUE), 2),
            Max = round(max(values, na.rm = TRUE), 2),
            Missing = sum(is.na(data[[var_col]])),
            stringsAsFactors = FALSE
          ))
        }
      }
    }
    
    DT::datatable(
      summary_stats,
      options = list(
        pageLength = 10,
        dom = 't',
        scrollX = TRUE
      ),
      rownames = FALSE,
      class = 'cell-border stripe hover'
    ) %>%
      formatStyle(
        columns = 1:ncol(summary_stats),
        padding = '10px',
        fontSize = '13px'
      ) %>%
      formatRound(columns = c("Min", "Q1", "Median", "Mean", "Q3", "Max"), digits = 2)
  })
  
  # Top risk table: top 5 countries with vulnerability > 50 (no scroll)
  output$top_risk_table <- DT::renderDataTable({
    base <- filtered_summary() %>%
      filter(!is.na(hunger_vulnerability_rating) & hunger_vulnerability_rating > 50) %>%
      arrange(desc(hunger_vulnerability_rating)) %>%
      slice_head(n = 5)
    if (nrow(base) == 0) {
      return(DT::datatable(
        data.frame(Message = "No countries in the current filter exceed a vulnerability score of 50."),
        rownames = FALSE,
        options = list(dom = "t", ordering = FALSE)
      ))
    }
    # Compute component scores (same logic as vulnerability calculation)
    scores <- base %>%
      mutate(
        undernourishment_pts = case_when(!is.na(undernourishment_rate) ~ pmin(undernourishment_rate * 0.25, 25), !is.na(poverty) ~ pmin(poverty * 0.25, 25), TRUE ~ 0),
        poverty_pts = case_when(!is.na(poverty) ~ pmin(poverty * 0.16, 8), !is.na(poverty_below_3usd) ~ pmin(poverty_below_3usd * 0.16, 8), TRUE ~ 0),
        gdp_pts = case_when(is.na(gdp_per_capita) ~ 0, gdp_per_capita < 1000 ~ 7, gdp_per_capita < 3000 ~ 5, gdp_per_capita < 10000 ~ 3, gdp_per_capita < 20000 ~ 1, TRUE ~ 0),
        life_exp_pts = case_when(is.na(life_expectancy) ~ 0, life_expectancy < 50 ~ 5, life_expectancy < 60 ~ 4, life_expectancy < 70 ~ 2, TRUE ~ 0),
        stunting_pts = case_when(!is.na(stunting_rate) ~ pmin(stunting_rate * 0.05, 5), TRUE ~ 0),
        climate_pts = case_when(!is.na(climate_vulnerability_index) & climate_vulnerability_index >= 80 ~ 10, !is.na(climate_vulnerability_index) & climate_vulnerability_index >= 70 ~ 7, !is.na(climate_vulnerability_index) & climate_vulnerability_index >= 60 ~ 3, TRUE ~ 0),
        outbreak_pts = case_when(!is.na(major_hunger_outbreak_21st) & major_hunger_outbreak_21st ~ 15, !is.na(grfc_ipc_phase) & grfc_ipc_phase >= 4 ~ 15, !is.na(grfc_ipc_phase) & grfc_ipc_phase == 3 ~ 8, TRUE ~ 0),
        conflict_pts = case_when(!is.na(has_active_conflict) & has_active_conflict & conflict_intensity == "Very High" ~ 10, !is.na(has_active_conflict) & has_active_conflict & conflict_intensity == "High" ~ 7, !is.na(has_active_conflict) & has_active_conflict & conflict_intensity == "Medium" ~ 4, !is.na(has_active_conflict) & has_active_conflict & conflict_intensity == "Low" ~ 2, TRUE ~ 0),
        trade_pts = case_when(!is.na(avg_import_share) & avg_import_share >= 0.5 ~ 5, !is.na(avg_import_share) & avg_import_share >= 0.3 ~ 4, !is.na(avg_import_share) & avg_import_share >= 0.2 ~ 2, !is.na(avg_import_share) & avg_import_share > 0 ~ 1, TRUE ~ 0),
        food_supply_pts = case_when(is.na(food_supply_kcal) ~ 0, food_supply_kcal < 2000 ~ 5, food_supply_kcal < 2200 ~ 3, food_supply_kcal < 2400 ~ 1, TRUE ~ 0),
        water_pts = case_when(is.na(water_per_capita) ~ 0, water_per_capita < 500 ~ 5, water_per_capita < 1000 ~ 3, water_per_capita < 1700 ~ 1, TRUE ~ 0),
        displacement_pts = case_when(
          is.na(total_displaced_latest) | total_displaced_latest <= 0 ~ 0,
          !is.na(population) & population > 0 & (total_displaced_latest / population) >= 0.10 ~ 5,
          !is.na(population) & population > 0 & (total_displaced_latest / population) >= 0.05 ~ 4,
          !is.na(population) & population > 0 & (total_displaced_latest / population) >= 0.01 ~ 3,
          !is.na(population) & population > 0 & (total_displaced_latest / population) >= 0.001 ~ 1,
          total_displaced_latest >= 1e6 ~ 4, total_displaced_latest >= 5e5 ~ 3, total_displaced_latest >= 1e5 ~ 1,
          TRUE ~ 0
        )
      )
    pt_cols <- c("undernourishment_pts", "poverty_pts", "gdp_pts", "life_exp_pts", "stunting_pts", "climate_pts", "outbreak_pts", "conflict_pts", "trade_pts", "food_supply_pts", "water_pts", "displacement_pts")
    factor_labels <- c("undernourishment_pts" = "Undernourishment", "poverty_pts" = "Poverty", "gdp_pts" = "GDP", "life_exp_pts" = "Life expectancy", "stunting_pts" = "Stunting", "climate_pts" = "Climate", "outbreak_pts" = "Outbreaks", "conflict_pts" = "Conflict", "trade_pts" = "Trade dependency", "food_supply_pts" = "Food supply", "water_pts" = "Water stress", "displacement_pts" = "Displacement")
    pt_cols <- intersect(pt_cols, names(scores))
    top3_str <- sapply(1:nrow(scores), function(i) {
      r <- unlist(scores[i, pt_cols]); r[is.na(r)] <- 0
      o <- order(r, decreasing = TRUE)
      n <- min(3, length(o))
      if (n == 0) return("—")
      paste0(sapply(seq_len(n), function(j) paste0(factor_labels[pt_cols[o[j]]], " (", round(r[o[j]], 1), " pts)")), collapse = ", ")
    })
    tbl <- scores %>%
      mutate(
        Rank = row_number(),
        Score = round(hunger_vulnerability_rating, 1),
        "Top 3 contributing factors" = top3_str
      ) %>%
      select(Rank, country, Score, "Top 3 contributing factors") %>%
      rename(Country = country)
    DT::datatable(
      tbl,
      options = list(
        pageLength = 5,
        dom = "t",
        ordering = FALSE,
        paging = FALSE,
        scrollX = FALSE,
        columnDefs = list(
          list(width = "6%", targets = 0),
          list(width = "18%", targets = 1),
          list(width = "8%", targets = 2),
          list(width = "68%", targets = 3)
        ),
        autoWidth = FALSE
      ),
      class = "cell-border stripe hover",
      rownames = FALSE
    ) %>%
      formatStyle(columns = 1:4, padding = '8px', fontSize = '13px') %>%
      formatStyle("Country", whiteSpace = "normal") %>%
      formatStyle("Top 3 contributing factors", whiteSpace = "normal")
  })
  
  # Country details — shared reactive (avoids nesting plot/table outputs inside renderUI)
  country_details_core <- reactive({
    req(input$selected_country)
    req(nzchar(input$selected_country))
    req(input$selected_country != "Select a country...")

    country_data <- latest_summary %>%
      distinct(country, .keep_all = TRUE) %>%
      filter(tolower(country) == tolower(input$selected_country))

    if (nrow(country_data) == 0) {
      all_countries <- unique(latest_summary$country)
      closest_match <- all_countries[which.min(adist(tolower(input$selected_country), tolower(all_countries)))]
      country_data <- latest_summary %>%
        distinct(country, .keep_all = TRUE) %>%
        filter(tolower(country) == tolower(closest_match))
    }

    if (nrow(country_data) == 0) {
      return(list(no_data = TRUE))
    }

    country_data <- country_data[1, ]

    data_category_cols <- c(
      "undernourishment_rate", "poverty_display", "gdp_per_capita", "life_expectancy", "stunting_rate",
      "climate_vulnerability_index", "food_supply_kcal", "water_per_capita", "avg_import_share",
      "population", "gdp", "agriculture_land", "infant_mortality", "literacy", "grfc_ipc_phase",
      "total_disasters_5yr", "total_displaced_latest", "ghi_score", "has_active_conflict", "major_hunger_outbreak_21st"
    )
    data_category_cols <- intersect(data_category_cols, names(country_data))
    n_categories <- length(data_category_cols)
    n_missing <- sum(sapply(data_category_cols, function(c) is.na(country_data[[c]])))
    pct_missing <- if (n_categories > 0) n_missing / n_categories else 0
    show_missing_data_note <- pct_missing > 0.25

    global_avgs <- latest_summary %>%
      distinct(country, .keep_all = TRUE) %>%
      summarise(
        across(any_of(c(
          "undernourishment_rate", "poverty_display", "gdp_per_capita", "life_expectancy", "stunting_rate",
          "climate_vulnerability_index", "food_supply_kcal", "water_per_capita", "avg_import_share",
          "population", "gdp", "agriculture_land", "infant_mortality", "literacy", "grfc_ipc_phase",
          "total_disasters_5yr", "total_displaced_latest", "ghi_score"
        )), ~ mean(as.numeric(.), na.rm = TRUE))
      )

    undernourishment_score <- case_when(
      !is.na(country_data$undernourishment_rate) ~ pmin(country_data$undernourishment_rate * 0.25, 25),
      !is.na(country_data$poverty) ~ pmin(country_data$poverty * 0.25, 25),
      TRUE ~ 0
    )
    poverty_score <- case_when(
      !is.na(country_data$poverty) ~ pmin(country_data$poverty * 0.16, 8),
      !is.na(country_data$poverty_below_3usd) ~ pmin(country_data$poverty_below_3usd * 0.16, 8),
      TRUE ~ 0
    )
    gdp_score <- case_when(
      is.na(country_data$gdp_per_capita) ~ 0,
      country_data$gdp_per_capita < 1000 ~ 7,
      country_data$gdp_per_capita < 3000 ~ 5,
      country_data$gdp_per_capita < 10000 ~ 3,
      country_data$gdp_per_capita < 20000 ~ 1,
      TRUE ~ 0
    )
    life_expectancy_score <- case_when(
      is.na(country_data$life_expectancy) ~ 0,
      country_data$life_expectancy < 50 ~ 5,
      country_data$life_expectancy < 60 ~ 4,
      country_data$life_expectancy < 70 ~ 2,
      TRUE ~ 0
    )
    stunting_score <- case_when(
      !is.na(country_data$stunting_rate) ~ pmin(country_data$stunting_rate * 0.05, 5),
      TRUE ~ 0
    )
    climate_score <- case_when(
      !is.na(country_data$climate_vulnerability_index) & country_data$climate_vulnerability_index >= 80 ~ 10,
      !is.na(country_data$climate_vulnerability_index) & country_data$climate_vulnerability_index >= 70 ~ 7,
      !is.na(country_data$climate_vulnerability_index) & country_data$climate_vulnerability_index >= 60 ~ 3,
      TRUE ~ 0
    )
    conflict_score <- case_when(
      !is.na(country_data$has_active_conflict) & country_data$has_active_conflict & country_data$conflict_intensity == "Very High" ~ 10,
      !is.na(country_data$has_active_conflict) & country_data$has_active_conflict & country_data$conflict_intensity == "High" ~ 7,
      !is.na(country_data$has_active_conflict) & country_data$has_active_conflict & country_data$conflict_intensity == "Medium" ~ 4,
      !is.na(country_data$has_active_conflict) & country_data$has_active_conflict & country_data$conflict_intensity == "Low" ~ 2,
      TRUE ~ 0
    )
    outbreak_score <- case_when(
      !is.na(country_data$major_hunger_outbreak_21st) & country_data$major_hunger_outbreak_21st ~ 15,
      !is.na(country_data$grfc_ipc_phase) & country_data$grfc_ipc_phase >= 4 ~ 15,
      !is.na(country_data$grfc_ipc_phase) & country_data$grfc_ipc_phase == 3 ~ 8,
      TRUE ~ 0
    )
    trade_dependency_score <- case_when(
      !is.na(country_data$avg_import_share) & country_data$avg_import_share >= 0.5 ~ 5,
      !is.na(country_data$avg_import_share) & country_data$avg_import_share >= 0.3 ~ 4,
      !is.na(country_data$avg_import_share) & country_data$avg_import_share >= 0.2 ~ 2,
      !is.na(country_data$avg_import_share) & country_data$avg_import_share > 0 ~ 1,
      TRUE ~ 0
    )
    food_supply_score <- case_when(
      is.na(country_data$food_supply_kcal) ~ 0,
      country_data$food_supply_kcal < 2000 ~ 5,
      country_data$food_supply_kcal < 2200 ~ 3,
      country_data$food_supply_kcal < 2400 ~ 1,
      TRUE ~ 0
    )
    water_stress_score <- case_when(
      is.na(country_data$water_per_capita) ~ 0,
      country_data$water_per_capita < 500 ~ 5,
      country_data$water_per_capita < 1000 ~ 3,
      country_data$water_per_capita < 1700 ~ 1,
      TRUE ~ 0
    )
    displacement_score <- case_when(
      is.na(country_data$total_displaced_latest) | country_data$total_displaced_latest <= 0 ~ 0,
      !is.na(country_data$population) & country_data$population > 0 & (country_data$total_displaced_latest / country_data$population) >= 0.10 ~ 5,
      !is.na(country_data$population) & country_data$population > 0 & (country_data$total_displaced_latest / country_data$population) >= 0.05 ~ 4,
      !is.na(country_data$population) & country_data$population > 0 & (country_data$total_displaced_latest / country_data$population) >= 0.01 ~ 3,
      !is.na(country_data$population) & country_data$population > 0 & (country_data$total_displaced_latest / country_data$population) >= 0.001 ~ 1,
      country_data$total_displaced_latest >= 1e6 ~ 4,
      country_data$total_displaced_latest >= 5e5 ~ 3,
      country_data$total_displaced_latest >= 1e5 ~ 1,
      TRUE ~ 0
    )

    country_inaccurate <- (!is.na(country_data$iso3c) && (country_data$iso3c %in% iso3c_likely_inaccurate)) ||
      (country_data$country %in% countries_likely_inaccurate_names)

    flag_code <- profile_country_flag_code(
      as.character(country_data$country[1]),
      as.character(country_data$iso3c[1])
    )

    list(
      no_data = FALSE,
      country_data = country_data,
      global_avgs = global_avgs,
      show_missing_data_note = show_missing_data_note,
      country_inaccurate = country_inaccurate,
      flag_code = flag_code,
      undernourishment_score = undernourishment_score,
      poverty_score = poverty_score,
      gdp_score = gdp_score,
      life_expectancy_score = life_expectancy_score,
      stunting_score = stunting_score,
      climate_score = climate_score,
      conflict_score = conflict_score,
      outbreak_score = outbreak_score,
      trade_dependency_score = trade_dependency_score,
      food_supply_score = food_supply_score,
      water_stress_score = water_stress_score,
      displacement_score = displacement_score
    )
  })

  output$country_details_has_data <- reactive({
    core <- country_details_core()
    !is.null(core) && !isTRUE(core$no_data)
  })
  outputOptions(output, "country_details_has_data", suspendWhenHidden = FALSE)

  country_history_table_key <- reactiveVal(0L)

  observeEvent(input$selected_country, {
    country_history_table_key(0L)
    session$sendCustomMessage("country_detail_reset_panels", list())
    session$sendCustomMessage("country_detail_resize_plots", list())
  }, ignoreInit = TRUE)

  observeEvent(input$country_history_table_refresh, {
    country_history_table_key(country_history_table_key() + 1L)
  }, ignoreInit = TRUE)

  output$country_history_table_body <- renderUI({
    req(country_details_core(), !isTRUE(country_details_core()$no_data))
    if (country_history_table_key() < 1L) {
      return(tags$div(
        style = "min-height: 100px; color: #94a3b8; text-align: center; padding: 36px 16px; font-size: 14px;",
        icon("table"), " Click the header to expand and load the historical data table."
      ))
    }
    tags$div(class = "country-history-table-slot", DT::dataTableOutput("country_data_table"))
  })

  # Country details profile (banner + stat cards only — panels are static UI)
  output$country_details_content <- renderUI({
    if(is.null(input$selected_country) || input$selected_country == "" || input$selected_country == "Select a country...") {
      return(
        div(
          style = "padding: 30px;",
          box(
            title = "How to Use the Country Details Page",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            tags$div(
              style = "font-size: 15px; line-height: 1.8;",
              tags$h4("📋 Quick Guide", style = "color: #3c8dbc; margin-top: 0;"),
              tags$ol(
                tags$li(strong("Select a Country:"), " Use the dropdown menu above or click on a country in the Interactive Map to view its detailed profile."),
                tags$li(strong("View Key Metrics:"), " The top value boxes show the country's vulnerability score, poverty rate, GDP per capita, and life expectancy at a glance."),
                tags$li(strong("Understand the Score:"), " The Vulnerability Score Breakdown shows how the total score (0-100) is calculated from multiple factors including undernourishment, poverty, economic conditions, health, climate, and more."),
                tags$li(strong("Explore Trends:"), " The undernourishment trend chart shows how hunger rates have changed over the past 10 years."),
                tags$li(strong("Review Data:"), " Scroll down to see comprehensive data including population, economic indicators, food security metrics, conflict status, disasters, and more."),
                tags$li(strong("Historical Data:"), " The time series table at the bottom shows all available historical data for the country, which you can sort, filter, and export.")
              ),
              tags$p(style = "margin-top: 12px; font-size: 14px; color: #555;", tags$span(icon("image"), style = "color: #3c8dbc;"), " ", strong("Add a country photo:"), " Place an image (e.g. ", tags$code("Angola.jpg"), ") in ", tags$code("www/country_photos/"), " and it will appear in the country profile banner when that country is selected."),
              tags$br(),
              tags$div(
                style = "background-color: #e8f4f8; padding: 15px; border-left: 4px solid #3c8dbc; border-radius: 4px; margin-top: 20px;",
                tags$p(strong("💡 Tip:"), " Hover over the", tags$span(icon("question-circle"), style = "color: #3c8dbc;"), "icons next to any metric to see detailed explanations and definitions.")
              )
            )
          )
        )
      )
    }
    
    core <- country_details_core()
    if (isTRUE(core$no_data)) {
      return(
        div(
          style = "text-align: center; padding: 50px; color: #666;",
          h4("No data available for this country"),
          p(paste("Country:", input$selected_country)),
          p("Please try selecting a different country from the dropdown.")
        )
      )
    }

    country_data <- core$country_data
    global_avgs <- core$global_avgs
    show_missing_data_note <- core$show_missing_data_note
    country_inaccurate <- core$country_inaccurate
    flag_code <- core$flag_code

    vuln_rating <- country_data$hunger_vulnerability_rating
    vuln_tier <- if (vuln_rating >= 75) {
      "critical"
    } else if (vuln_rating >= 50) {
      "high"
    } else if (vuln_rating >= 25) {
      "moderate"
    } else {
      "low"
    }
    vuln_label <- paste0(tools::toTitleCase(vuln_tier), " vulnerability")

    has_imputed_stats <- any(
      is.na(country_data$poverty_display),
      is.na(country_data$gdp_per_capita),
      is.na(country_data$life_expectancy),
      is.na(country_data$total_displaced_latest)
    )

    # Create country profile header + stat cards
    fluidRow(
      class = "country-details-content-row",
      # Warning when this country has likely inaccurate data (e.g. North Korea, Eritrea, Turkmenistan)
      if (country_inaccurate) {
        box(
          title = tags$span(icon("exclamation-triangle"), " Likely inaccurate data"),
          status = "danger",
          solidHeader = TRUE,
          width = 12,
          tags$p(strong("Official statistics from this country are often unreliable or unavailable."),
                 " Figures and scores on this page may not reflect reality. Use with caution and prefer other sources for assessment.")
        )
      },
      # Country profile header with flag and optional photo
      tags$div(
          class = paste("country-profile-banner", paste0("country-profile-banner--", vuln_tier)),
          style = "display: flex; align-items: center; gap: 16px; flex-wrap: wrap;",
          tags$div(
            class = "country-profile-flag",
            tags$img(
              src = country_flag_img_url(flag_code, 160L),
              srcset = paste0(country_flag_img_url(flag_code, 320L), " 2x"),
              alt = paste("Flag of", input$selected_country),
              class = "country-profile-flag-img",
              onerror = "this.onerror=null; this.src='https://flagcdn.com/w160/un.png';"
            )
          ),
          tags$div(style = "flex: 1; min-width: 0;",
            tags$h3(
              style = "margin: 0 0 4px 0; font-size: 22px; font-weight: 700; color: #0f172a; letter-spacing: -0.02em;",
              paste("Country profile:", input$selected_country)
            ),
            if (!is.na(country_data$region) && nzchar(as.character(country_data$region))) {
              tags$span(class = "country-profile-region-badge", icon("globe-americas"), country_data$region)
            },
            tags$div(
              class = paste("country-profile-vuln-badge", paste0("country-profile-vuln-badge--", vuln_tier)),
              icon("shield-alt"),
              vuln_label,
              tags$span(style = "font-weight: 800; margin-left: 4px;", paste0(round(vuln_rating, 1), "/100"))
            ),
            tags$p(style = "margin: 8px 0 0 0; font-size: 13px; color: #64748b;", "Summary metrics and expandable sections below."),
            if (tolower(as.character(country_data$country)) == "bangladesh") {
              tags$div(
                style = "margin-top: 12px; padding-top: 10px; border-top: 1px solid rgba(60, 141, 188, 0.25);",
                actionLink(
                  "go_bangladesh_research",
                  label = tagList(icon("seedling"), " Open Bangladesh climate & food security research project"),
                  style = "font-size: 14px; font-weight: 600;"
                )
              )
            }
          ),
          tags$img(
            src = paste0("country_photos/", gsub(" ", "_", input$selected_country), ".jpg"),
            alt = paste("Photo of", input$selected_country),
            style = "max-height: 100px; max-width: 180px; object-fit: cover; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);",
            onerror = "this.style.display='none'"
          )
      ),
      # Data availability + asterisk legend (grouped, below banner)
      if (show_missing_data_note) {
        tags$div(
          class = "country-details-notices",
          tags$p(class = "country-details-notices__title", icon("exclamation-triangle"), "Data availability notice"),
          tags$p(
            class = "country-details-notices__body",
            strong("More than 25% of data categories are missing for this country."),
            " Where data are missing below, we show the global average and note it so you can interpret the profile with appropriate caution."
          ),
          tags$p(
            class = "country-details-notices__footnote",
            tags$strong("*"),
            " No country-level data for this category; value shown is the global average for reference."
          )
        )
      } else if (has_imputed_stats) {
        tags$div(
          class = "country-details-notices",
          style = "background: linear-gradient(90deg, #f0f9ff 0%, #ffffff 100%); border-color: #bae6fd; border-left-color: #0891b2;",
          tags$p(
            class = "country-details-notices__footnote",
            style = "padding-top: 0; border-top: none;",
            tags$strong("*"),
            " No country-level data for this category; value shown is the global average for reference."
          )
        )
      },
      tags$div(
        class = "country-details-stats",
        country_metric_card(
          value = round(country_data$hunger_vulnerability_rating, 1),
          label = "Vulnerability score (0–100)",
          icon_name = "exclamation-triangle",
          accent = ifelse(
            country_data$hunger_vulnerability_rating >= 75, "critical",
            ifelse(country_data$hunger_vulnerability_rating >= 50, "high",
                   ifelse(country_data$hunger_vulnerability_rating >= 25, "moderate", "low"))
          ),
          help_term = "Vulnerability Score",
          help_text = "A composite score (0-100 scale) measuring hunger and food insecurity risk. 0-25: Low, 25-50: Moderate, 50-75: High, 75-100: Critical."
        ),
        country_metric_card(
          value = if (is.na(country_data$poverty_display)) {
            if (!is.na(global_avgs$poverty_display)) paste0(round(global_avgs$poverty_display, 1), "%*") else "N/A"
          } else paste0(round(country_data$poverty_display, 1), "%"),
          label = "Poverty rate",
          icon_name = "users",
          accent = "sky",
          help_term = "Poverty Rate",
          help_text = "Percentage below poverty line ($1.90/day or $3/day). Key indicator of food insecurity risk."
        ),
        country_metric_card(
          value = if (is.na(country_data$gdp_per_capita)) {
            if (!is.na(global_avgs$gdp_per_capita)) paste0("$", format(round(global_avgs$gdp_per_capita, 0), big.mark = ","), "*") else "N/A"
          } else paste0("$", format(round(country_data$gdp_per_capita, 0), big.mark = ",")),
          label = "GDP per capita",
          icon_name = "dollar-sign",
          accent = "emerald",
          help_term = "GDP per Capita",
          help_text = "Gross Domestic Product per capita in current US dollars. Indicates economic capacity to address food security."
        ),
        country_metric_card(
          value = if (is.na(country_data$life_expectancy)) {
            if (!is.na(global_avgs$life_expectancy)) paste0(round(global_avgs$life_expectancy, 1), " yrs*") else "N/A"
          } else paste0(round(country_data$life_expectancy, 1), " yrs"),
          label = "Life expectancy",
          icon_name = "heartbeat",
          accent = "violet",
          help_term = "Life Expectancy",
          help_text = "Average years a newborn is expected to live if current mortality patterns continue."
        ),
        country_metric_card(
          value = {
            v <- country_data$total_displaced_latest
            if (is.na(v)) {
              ga <- global_avgs$total_displaced_latest
              if (!is.na(ga)) paste0(round(ga / 1e6, 1), "M*") else "N/A"
            } else if (v >= 1e6) {
              paste0(round(v / 1e6, 1), "M")
            } else if (v >= 1e3) {
              paste0(round(v / 1e3, 1), "K")
            } else {
              as.character(round(v, 0))
            }
          },
          label = "Displaced people",
          icon_name = "people-arrows",
          accent = "amber",
          help_term = "Displaced People",
          help_text = "Refugees and internally displaced persons (UNHCR). Displacement increases hunger risk as people lose access to land and livelihoods."
        )
      ),
      
      tags$div(
        class = "country-details-section-hint",
        "Expand any section below to view score details, charts, and data tables."
      ),
    )
  })

  output$country_breakdown_body <- renderUI({
    core <- country_details_core()
    req(core, !isTRUE(core$no_data))
    country_data <- core$country_data
    tags$div(
      style = "font-size: 14px;",
      tags$h4(
        style = "margin-top: 0; color: #0f172a; font-weight: 600;",
        "Total score: ", round(country_data$hunger_vulnerability_rating, 1), "/100",
        info_icon(
          "Vulnerability score",
          paste0(
            "Composite index from 0–100. Higher values mean greater hunger and food-security risk. ",
            "It combines undernourishment, poverty, economic capacity, health, climate stress, conflict, ",
            "historical food crises, trade dependence, food and water resources, and displacement.\n\n",
            "How to read the score:\n",
            "• 0–25 — Low (green)\n",
            "• 25–50 — Moderate (yellow)\n",
            "• 50–75 — High (orange)\n",
            "• 75–100 — Critical (red)"
          )
        )
      ),
      tags$p(style = "margin: 12px 0 8px 0; color: #475569;", strong("Score components"), info_icon("Points", "Points are each factor’s contribution to the total (max 100). Higher points mean that factor adds more to vulnerability.")),
      tags$ul(
        tags$li("Undernourishment: ", round(core$undernourishment_score, 1), " points (25% of total score)", info_icon("Undernourishment", "Percentage of people who do not have regular access to enough calories. If this value is missing, poverty percentage is used as a fallback input.")),
        tags$li("Poverty and income per person: ", round(core$poverty_score + core$gdp_score, 1), " points (15% of total score)", info_icon("Poverty and income per person", "Poverty contributes up to 8 points, and income per person contributes up to 7 points. Together they represent economic capacity to reduce hunger risk.")),
        tags$li("Life expectancy: ", round(core$life_expectancy_score, 1), " points (5% of total score)", info_icon("Life expectancy", "Lower life expectancy often reflects weaker health systems and higher nutrition vulnerability.")),
        tags$li("Child stunting: ", round(core$stunting_score, 1), " points (5% of total score)", info_icon("Child stunting", "Percentage of children under 5 who are too short for their age, which indicates chronic undernutrition.")),
        tags$li("Climate vulnerability: ", round(core$climate_score, 1), " points (10% of total score)", info_icon("Climate vulnerability", "How exposed a country is to climate risks that can damage crop production and food access.")),
        tags$li("Conflict intensity: ", round(core$conflict_score, 1), " points (10% of total score)", info_icon("Conflict intensity", "Current armed conflict level, which is a major driver of food insecurity.")),
        tags$li("Historical hunger crises and food security phase: ", round(core$outbreak_score, 1), " points (15% of total score)", info_icon("Historical hunger crises and food security phase", "Countries with major hunger crises in the 21st century or severe current food security phase levels receive higher points.")),
        tags$li("Food import dependency: ", round(core$trade_dependency_score, 1), " points (5% of total score)", info_icon("Food import dependency", "Higher dependency on imported food increases vulnerability to trade disruptions and price shocks.")),
        tags$li("Natural resources (food supply and water stress): ", round(core$food_supply_score + core$water_stress_score, 1), " points (10% of total score)",
                info_icon("Natural resources", paste0("Food supply contribution: ", round(core$food_supply_score, 1), " points (max 5). Water stress contribution: ", round(core$water_stress_score, 1), " points (max 5). Combined maximum is 10 points."))),
        tags$li("Forced displacement: ", round(core$displacement_score, 1), " points (5% of total score)", info_icon("Forced displacement", "Refugees and internally displaced people increase hunger risk because households often lose land, income, and local food access."))
      ),
      if (is.na(country_data$poverty_display) || is.na(country_data$gdp_per_capita) || is.na(country_data$life_expectancy) || is.na(country_data$total_displaced_latest)) {
        tags$p(style = "font-size: 12px; color: #555; margin-top: 12px; padding: 8px; background: #f5f5f5; border-radius: 4px;",
               strong("Note on value boxes above: "),
               "When country-level data are missing for poverty, GDP per capita, life expectancy, or displaced people, those value boxes show the global average for reference (marked with *). The score components listed here use only available country data.")
      }
    )
  })

  output$country_insights_body <- renderUI({
    core <- country_details_core()
    req(core, !isTRUE(core$no_data))
    country_data <- core$country_data
    risk_items <- list()
    if (core$undernourishment_score >= 12) risk_items <- c(risk_items, list(tags$li("High undernourishment rate")))
    if (core$poverty_score + core$gdp_score >= 8) risk_items <- c(risk_items, list(tags$li("High poverty / low economic capacity")))
    if (core$conflict_score >= 4) risk_items <- c(risk_items, list(tags$li("Active conflict")))
    if (core$trade_dependency_score >= 2) risk_items <- c(risk_items, list(tags$li("High food import dependency")))
    if (core$food_supply_score + core$water_stress_score >= 4) risk_items <- c(risk_items, list(tags$li("Natural resource constraints (food/water)")))
    if (core$displacement_score >= 2) risk_items <- c(risk_items, list(tags$li("High displacement (refugees/IDPs)")))
    if (length(risk_items) == 0) risk_items <- list(tags$li("No major risk factors identified"))
    tags$div(
      style = "font-size: 14px; line-height: 1.65; color: #334155;",
      tags$p(strong("Vulnerability Assessment:")),
      tags$p(
        ifelse(country_data$hunger_vulnerability_rating >= 75,
               "This country is in critical condition and requires immediate humanitarian assistance. Multiple factors contribute to extreme food insecurity.",
               ifelse(country_data$hunger_vulnerability_rating >= 50,
                      "This country faces high vulnerability to hunger. Significant interventions are needed to address food security challenges.",
                      ifelse(country_data$hunger_vulnerability_rating >= 25,
                             "This country has moderate vulnerability. Monitoring and preventive measures are recommended.",
                             "This country has relatively low hunger vulnerability, though continued monitoring is important.")))
      ),
      tags$p(strong("Primary Risk Factors:")),
      tags$ul(risk_items)
    )
  })

  output$country_summary_body <- renderUI({
    core <- country_details_core()
    req(core, !isTRUE(core$no_data))
    country_data <- core$country_data
    global_avgs <- core$global_avgs
    tags$div(
      style = "font-size: 13px; line-height: 1.5;",
      tags$p(strong("Latest Data Year: "), country_data$latest_year),
      tags$br(),
      tags$p(strong("Population: "), {
        v <- country_data$population
        if (is.na(v) || v == 0) { ga <- global_avgs$population; if (!is.na(ga)) paste0(format(round(ga/1e6, 1), big.mark = ","), " million (global average — no country data)") else "No data" }
        else if (v < 100000) paste(format(round(v/1e3, 1), big.mark = ","), "thousand")
        else paste(format(round(v/1e6, 1), big.mark = ","), "million")
      }, info_icon("Population", "Total number of people living in the country. Larger populations may face greater challenges in ensuring food security for all citizens.")),
      tags$p(strong("GDP: "), {
        v <- country_data$gdp
        if (is.na(v)) { ga <- global_avgs$gdp; if (!is.na(ga)) paste0("$", format(round(ga/1e9, 1), big.mark = ","), " billion (global average — no country data)") else "No data" }
        else paste("$", format(round(v/1e9, 1), big.mark = ","), "billion")
      }, info_icon("GDP", "Gross Domestic Product - the total value of all goods and services produced in the country. Higher GDP indicates greater economic resources available for food security programs.")),
      tags$p(strong("Agriculture Land: "), {
        v <- country_data$agriculture_land
        if (is.na(v)) { ga <- global_avgs$agriculture_land; if (!is.na(ga)) paste0(round(ga, 1), "% (global average — no country data)") else "No data" }
        else paste(round(v, 1), "%")
      }, info_icon("Agriculture Land", "Percentage of total land area used for agricultural purposes. Higher percentages may indicate greater food production capacity, though productivity varies significantly.")),
      tags$p(strong("Infant Mortality: "), {
        v <- country_data$infant_mortality
        if (is.na(v)) { ga <- global_avgs$infant_mortality; if (!is.na(ga)) paste0(round(ga, 1), " per 1,000 live births (global average — no country data)") else "No data" }
        else paste(round(v, 1), "per 1,000 live births")
      }, info_icon("Infant Mortality", "Number of deaths of infants under one year old per 1,000 live births. High infant mortality often correlates with malnutrition and poor maternal nutrition.")),
      tags$p(strong("Literacy Rate: "), {
        v <- country_data$literacy
        if (is.na(v)) { ga <- global_avgs$literacy; if (!is.na(ga)) paste0(round(ga, 1), "% (global average — no country data)") else "No data" }
        else paste(round(v, 1), "%")
      }, info_icon("Literacy Rate", "Percentage of the population aged 15 and above who can read and write. Education is linked to better nutrition knowledge and food security.")),
      tags$p(strong("Region: "), ifelse(is.na(country_data$region), "No data", country_data$region)),
      tags$br(),
      tags$h5("Food Security Indicators:"),
      tags$p(strong("FAO Undernourishment: "), {
        v <- country_data$undernourishment_rate
        if (is.na(v)) { ga <- global_avgs$undernourishment_rate; if (!is.na(ga)) paste0(round(ga, 1), "% (global average — no country data)") else "No data" } else paste(round(v, 1), "%")
      }, info_icon("FAO Undernourishment", "Food and Agriculture Organization's measure of the percentage of the population that does not have regular access to sufficient calories. This is the primary global indicator of hunger.")),
      tags$p(strong("WHO Stunting Rate: "), {
        v <- country_data$stunting_rate
        if (is.na(v)) { ga <- global_avgs$stunting_rate; if (!is.na(ga)) paste0(round(ga, 1), "% (global average — no country data)") else "No data" } else paste(round(v, 1), "%")
      }, info_icon("WHO Stunting Rate", "World Health Organization's measure of the percentage of children under 5 years old who are too short for their age. Stunting indicates chronic malnutrition and is a key indicator of long-term food insecurity.")),
      tags$p(strong("WFP IPC Phase: "), {
        v <- country_data$grfc_ipc_phase
        if (is.na(v)) { ga <- global_avgs$grfc_ipc_phase; if (!is.na(ga)) paste0("Phase ", round(ga, 1), " (global average — no country data)") else "No data" } else paste("Phase", v)
      }, info_icon("WFP IPC Phase", "World Food Programme's Integrated Food Security Phase Classification. Phase 1 = Minimal, Phase 2 = Stressed, Phase 3 = Crisis, Phase 4 = Emergency, Phase 5 = Famine/Catastrophe. Higher phases indicate more severe food insecurity.")),
      tags$p(strong("Food Supply: "), {
        v <- country_data$food_supply_kcal
        if (is.na(v)) { ga <- global_avgs$food_supply_kcal; if (!is.na(ga)) paste0(round(ga, 0), " kcal/day/capita (global average — no country data)") else "No data" } else paste(round(v, 0), "kcal/day/capita")
      }, info_icon("Food Supply", "Daily food supply per capita in kilocalories. Recommended minimum is 2,500 kcal/day.")),
      tags$p(strong("Food Import Dependency: "), {
        v <- country_data$avg_import_share
        if (is.na(v)) { ga <- global_avgs$avg_import_share; if (!is.na(ga)) paste0(round(ga * 100, 1), "% (global average — no country data)") else "No data" } else paste(round(v * 100, 1), "%")
      }, info_icon("Food Import Dependency", "Average share of food imports. High dependency makes countries vulnerable to trade disruptions and price shocks.")),
      tags$br(),
      tags$h5("Crisis and Vulnerability Indicators:"),
      tags$p(strong("Active Conflict: "), ifelse(is.na(country_data$has_active_conflict) || !country_data$has_active_conflict, "No",
                                                 paste("Yes (", country_data$conflict_intensity, " intensity)")),
             info_icon("Active Conflict", "Indicates whether the country is experiencing active conflict based on ACLED data. Conflict is a major driver of food insecurity.")),
      tags$p(strong("Disasters (Past 5 Years): "), {
        v <- country_data$total_disasters_5yr
        if (is.na(v)) { ga <- global_avgs$total_disasters_5yr; if (!is.na(ga)) paste0(round(ga, 1), " disasters (global average — no country data)") else "No data" } else paste(v, "disasters")
      }, info_icon("Disasters", "Number of natural disasters in the past 5 years. Disasters can cause immediate food shortages and long-term agricultural damage.")),
      tags$p(strong("Historical Outbreaks (21st C): "), ifelse(is.na(country_data$major_hunger_outbreak_21st) || !country_data$major_hunger_outbreak_21st, "No",
                                                                 paste("Yes (", country_data$total_outbreaks, " outbreaks)")),
             info_icon("Historical Outbreaks", "Indicates whether the country has experienced major hunger crises or famines in the 21st century. Countries with historical outbreaks may be at higher risk for future crises.")),
      tags$p(strong("Displaced People: "), {
        v <- country_data$total_displaced_latest
        if (is.na(v)) { ga <- global_avgs$total_displaced_latest; if (!is.na(ga)) paste0(format(round(ga/1e6, 1), big.mark = ","), " million (global average — no country data)") else "No data" } else paste(format(round(v/1e6, 1), big.mark = ","), "million")
      }, info_icon("Displaced People", "Total number of refugees and internally displaced persons. Displacement often leads to food insecurity as people lose access to land, livelihoods, and food sources.")),
      tags$br(),
      tags$h5("Environmental and Resource Indicators:"),
      tags$p(strong("Climate Vulnerability Index: "), {
        v <- country_data$climate_vulnerability_index
        if (is.na(v)) { ga <- global_avgs$climate_vulnerability_index; if (!is.na(ga)) paste0(round(ga, 1), " (global average — no country data)") else "No data" } else paste(round(v, 1))
      }, info_icon("Climate Vulnerability Index", "A measure of how vulnerable a country is to climate change impacts, which can affect agricultural productivity, food availability, and food security. Higher values indicate greater vulnerability.")),
      tags$p(strong("Water Resources per Capita: "), {
        v <- country_data$water_per_capita
        if (is.na(v)) { ga <- global_avgs$water_per_capita; if (!is.na(ga)) paste0(format(round(ga, 0), big.mark = ","), " m³/year (global average — no country data)") else "No data" } else paste(format(round(v, 0), big.mark = ","), "m³/year")
      }, info_icon("Water Resources", "Renewable freshwater resources per capita. Below 1,700 m³/year indicates water stress.")),
      tags$br(),
      tags$h5("Comparison Data:"),
      tags$p(strong("GHI Score (2025): "), {
        v <- country_data$ghi_score
        if (is.na(v)) { ga <- global_avgs$ghi_score; if (!is.na(ga)) paste0(round(ga, 1), " (global average — no country data)") else "No data" } else paste(round(v, 1))
      }, info_icon("GHI Score", "Global Hunger Index score (0-100). Lower scores indicate less hunger. Used for comparison with our vulnerability score."))
    )
  })

  outputOptions(output, "country_breakdown_body", suspendWhenHidden = FALSE)
  outputOptions(output, "country_insights_body", suspendWhenHidden = FALSE)
  outputOptions(output, "country_summary_body", suspendWhenHidden = FALSE)
  outputOptions(output, "country_history_table_body", suspendWhenHidden = FALSE)

  # Vulnerability score trend over time (from indicators available by year)
  output$vulnerability_trend_chart <- renderPlotly({
    if(is.null(input$selected_country) || input$selected_country == "" || input$selected_country == "Select a country...") {
      return(plotly_empty() %>% layout(title = "Select a country to view trend"))
    }
    selected_country_name <- input$selected_country
    # Match country (same as country details)
    country_match <- latest_summary %>% distinct(country, .keep_all = TRUE) %>% filter(tolower(country) == tolower(selected_country_name))
    if(nrow(country_match) == 0) {
      all_countries <- unique(latest_summary$country)
      closest_match <- all_countries[which.min(adist(tolower(selected_country_name), tolower(all_countries)))]
      selected_country_name <- closest_match
    } else selected_country_name <- country_match$country[1]
    sel_std <- trimws(tolower(selected_country_name))
    # Time series: hunger_data has country, year, WDI cols. Join FAO undernourishment by year if available.
    current_year <- as.numeric(format(Sys.Date(), "%Y"))
    yrs <- (current_year - 10):current_year
    ts_wb <- hunger_data %>%
      filter(trimws(tolower(country)) == sel_std, year %in% yrs) %>%
      select(year, poverty = SI.POV.DDAY, gdp_per_capita = NY.GDP.PCAP.CD, life_expectancy = SP.DYN.LE00.IN)
    if(!is.null(fao_timeseries) && nrow(fao_timeseries) > 0) {
      fao_std <- fao_timeseries %>% mutate(country_std = standardize_country_names(country))
      match_c <- fao_std %>% filter(trimws(tolower(country_std)) == sel_std) %>% distinct(country_std) %>% pull(country_std)
      if(length(match_c) == 0) match_c <- fao_std$country_std[which.min(adist(sel_std, tolower(trimws(unique(fao_std$country_std)))))]
      fao_country <- fao_std %>% filter(country_std == match_c[1], year %in% yrs) %>% select(year, undernourishment_rate)
      ts_wb <- ts_wb %>% left_join(fao_country, by = "year")
    } else ts_wb$undernourishment_rate <- NA_real_
    if(nrow(ts_wb) == 0) {
      return(plotly_empty() %>% layout(title = paste("No time-series data for", selected_country_name), xaxis = list(title = "Year"), yaxis = list(title = "Vulnerability (0-100)")))
    }
    # Same scoring as latest_summary (subset we have by year)
    trend_data <- ts_wb %>%
      mutate(
        undernourishment_score = case_when(
          !is.na(undernourishment_rate) ~ pmin(undernourishment_rate * 0.25, 25),
          !is.na(poverty) ~ pmin(poverty * 0.25, 25),
          TRUE ~ 0
        ),
        poverty_score = case_when(!is.na(poverty) ~ pmin(poverty * 0.16, 8), TRUE ~ 0),
        gdp_score = case_when(
          is.na(gdp_per_capita) ~ 0,
          gdp_per_capita < 1000 ~ 7,
          gdp_per_capita < 3000 ~ 5,
          gdp_per_capita < 10000 ~ 3,
          gdp_per_capita < 20000 ~ 1,
          TRUE ~ 0
        ),
        life_expectancy_score = case_when(
          is.na(life_expectancy) ~ 0,
          life_expectancy < 50 ~ 5,
          life_expectancy < 60 ~ 4,
          life_expectancy < 70 ~ 2,
          TRUE ~ 0
        ),
        partial_sum = undernourishment_score + poverty_score + gdp_score + life_expectancy_score
      ) %>%
      mutate(vulnerability_score = pmin(100, round(partial_sum * (100 / 45), 1))) %>%
      arrange(year) %>%
      select(year, vulnerability_score)
    if(nrow(trend_data) == 0 || all(is.na(trend_data$vulnerability_score))) {
      return(plotly_empty() %>% layout(title = paste("No vulnerability trend data for", selected_country_name), xaxis = list(title = "Year"), yaxis = list(title = "Vulnerability (0-100)")))
    }
    df <- as.data.frame(trend_data)
    max_score <- max(df$vulnerability_score, na.rm = TRUE)
    y_max <- max(10, min(100, ceiling(max_score * 1.15)))
    p <- plot_ly(data = df, x = ~year, y = ~vulnerability_score, type = "scatter", mode = "lines+markers",
                 fill = "tozeroy",
                 line = list(color = "#2980b9", width = 4),
                 marker = list(color = "#2980b9", size = 10, symbol = "circle", line = list(color = "#1a5276", width = 1.5)),
                 fillcolor = "rgba(41, 128, 185, 0.25)",
                 hovertemplate = "<b>%{x}</b><br>Score: %{y:.1f}<extra></extra>") %>%
      layout(
        title = list(text = paste("Vulnerability Score over Time:", selected_country_name), font = list(size = 14)),
        xaxis = list(title = "Year", showgrid = TRUE, gridcolor = "#e8eaed"),
        yaxis = list(title = "Vulnerability Score (0-100)", showgrid = TRUE, gridcolor = "#e8eaed", range = c(0, y_max)),
        hovermode = "closest", plot_bgcolor = "#f0f4f8", paper_bgcolor = "#ffffff",
        margin = list(l = 60, r = 20, t = 60, b = 60)
      ) %>%
      config(displayModeBar = FALSE, responsive = TRUE)
    p
  })

  # Factor contribution bar chart (share of each factor in total score; exclude zero)
  output$country_factor_contribution_chart <- renderPlotly({
    if(is.null(input$selected_country) || input$selected_country == "" || input$selected_country == "Select a country...") {
      return(plotly_empty() %>% layout(title = "Select a country"))
    }
    country_match <- latest_summary %>% distinct(country, .keep_all = TRUE) %>% filter(tolower(country) == tolower(input$selected_country))
    if(nrow(country_match) == 0) {
      all_countries <- unique(latest_summary$country)
      closest_match <- all_countries[which.min(adist(tolower(input$selected_country), tolower(all_countries)))]
      country_match <- latest_summary %>% distinct(country, .keep_all = TRUE) %>% filter(tolower(country) == tolower(closest_match))
    }
    if(nrow(country_match) == 0) return(plotly_empty() %>% layout(title = "No data"))
    cd <- country_match[1, ]
    # Same component scores as country details breakdown
    u_score <- if (!is.na(cd$undernourishment_rate)) pmin(cd$undernourishment_rate * 0.25, 25) else if (!is.na(cd$poverty)) pmin(cd$poverty * 0.25, 25) else 0
    p_score <- if (!is.na(cd$poverty)) pmin(cd$poverty * 0.16, 8) else if (!is.na(cd$poverty_below_3usd)) pmin(cd$poverty_below_3usd * 0.16, 8) else 0
    g_score <- case_when(is.na(cd$gdp_per_capita) ~ 0, cd$gdp_per_capita < 1000 ~ 7, cd$gdp_per_capita < 3000 ~ 5, cd$gdp_per_capita < 10000 ~ 3, cd$gdp_per_capita < 20000 ~ 1, TRUE ~ 0)
    le_score <- case_when(is.na(cd$life_expectancy) ~ 0, cd$life_expectancy < 50 ~ 5, cd$life_expectancy < 60 ~ 4, cd$life_expectancy < 70 ~ 2, TRUE ~ 0)
    s_score <- if (!is.na(cd$stunting_rate)) pmin(cd$stunting_rate * 0.05, 5) else 0
    cl_score <- case_when(is.na(cd$climate_vulnerability_index) ~ 0, cd$climate_vulnerability_index >= 80 ~ 10, cd$climate_vulnerability_index >= 70 ~ 7, cd$climate_vulnerability_index >= 60 ~ 3, TRUE ~ 0)
    co_score <- case_when(!is.na(cd$has_active_conflict) & cd$has_active_conflict & cd$conflict_intensity == "Very High" ~ 10, !is.na(cd$has_active_conflict) & cd$has_active_conflict & cd$conflict_intensity == "High" ~ 7, !is.na(cd$has_active_conflict) & cd$has_active_conflict & cd$conflict_intensity == "Medium" ~ 4, !is.na(cd$has_active_conflict) & cd$has_active_conflict & cd$conflict_intensity == "Low" ~ 2, TRUE ~ 0)
    o_score <- case_when(!is.na(cd$major_hunger_outbreak_21st) & cd$major_hunger_outbreak_21st ~ 15, !is.na(cd$grfc_ipc_phase) & cd$grfc_ipc_phase >= 4 ~ 15, !is.na(cd$grfc_ipc_phase) & cd$grfc_ipc_phase == 3 ~ 8, TRUE ~ 0)
    tr_score <- case_when(!is.na(cd$avg_import_share) & cd$avg_import_share >= 0.5 ~ 5, !is.na(cd$avg_import_share) & cd$avg_import_share >= 0.3 ~ 4, !is.na(cd$avg_import_share) & cd$avg_import_share >= 0.2 ~ 2, !is.na(cd$avg_import_share) & cd$avg_import_share > 0 ~ 1, TRUE ~ 0)
    fs_score <- case_when(is.na(cd$food_supply_kcal) ~ 0, cd$food_supply_kcal < 2000 ~ 5, cd$food_supply_kcal < 2200 ~ 3, cd$food_supply_kcal < 2400 ~ 1, TRUE ~ 0)
    ws_score <- case_when(is.na(cd$water_per_capita) ~ 0, cd$water_per_capita < 500 ~ 5, cd$water_per_capita < 1000 ~ 3, cd$water_per_capita < 1700 ~ 1, TRUE ~ 0)
    d_score <- case_when(
      is.na(cd$total_displaced_latest) | cd$total_displaced_latest <= 0 ~ 0,
      !is.na(cd$population) & cd$population > 0 & (cd$total_displaced_latest / cd$population) >= 0.10 ~ 5,
      !is.na(cd$population) & cd$population > 0 & (cd$total_displaced_latest / cd$population) >= 0.05 ~ 4,
      !is.na(cd$population) & cd$population > 0 & (cd$total_displaced_latest / cd$population) >= 0.01 ~ 3,
      !is.na(cd$population) & cd$population > 0 & (cd$total_displaced_latest / cd$population) >= 0.001 ~ 1,
      cd$total_displaced_latest >= 1e6 ~ 4, cd$total_displaced_latest >= 5e5 ~ 3, cd$total_displaced_latest >= 1e5 ~ 1,
      TRUE ~ 0
    )
    total <- u_score + p_score + g_score + le_score + s_score + cl_score + co_score + o_score + tr_score + fs_score + ws_score + d_score
    if(total <= 0) return(plotly_empty() %>% layout(title = "No score components available"))
    factors_df <- data.frame(
      factor = c("Undernourishment", "Poverty", "GDP", "Life expectancy", "Stunting", "Climate", "Conflict", "Outbreaks", "Trade dependency", "Food supply", "Water stress", "Displacement"),
      pts = c(u_score, p_score, g_score, le_score, s_score, cl_score, co_score, o_score, tr_score, fs_score, ws_score, d_score),
      stringsAsFactors = FALSE
    ) %>%
      filter(pts > 0) %>%
      mutate(pct = round(100 * pts / total, 1)) %>%
      arrange(desc(pts))
    if(nrow(factors_df) == 0) return(plotly_empty() %>% layout(title = "No contributing factors"))
    # Distinct colors per factor (diverse palette)
    factor_colors <- c("#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6", "#1abc9c",
                       "#e67e22", "#34495e", "#16a085", "#27ae60", "#2980b9", "#8e44ad")
    factors_df$bar_color <- factor_colors[seq_len(nrow(factors_df))]
    factors_df$factor <- factor(factors_df$factor, levels = factors_df$factor)
    plot_ly(data = factors_df, x = ~factor, y = ~pct, type = "bar",
            marker = list(
              color = factors_df$bar_color,
              line = list(color = "rgba(0,0,0,0.25)", width = 1.2)
            ),
            text = paste0(factors_df$pct, "%"), textposition = "outside", textfont = list(size = 12),
            hovertext = paste0(factors_df$factor, ": ", round(factors_df$pts, 1), " pts"),
            hoverinfo = "text") %>%
      layout(
        title = list(text = paste("Contributing factors —", cd$country), font = list(size = 14)),
        xaxis = list(title = "", tickangle = -45),
        yaxis = list(title = "% of total score", range = c(0, max(factors_df$pct, na.rm = TRUE) * 1.15), ticksuffix = "%"),
        margin = list(l = 60, r = 50, t = 50, b = 100),
        showlegend = FALSE,
        plot_bgcolor = "#fafbfc",
        paper_bgcolor = "#ffffff"
      ) %>%
      config(displayModeBar = FALSE, responsive = TRUE)
  })
  
  # Country data table
  output$country_data_table <- renderDataTable({
    if(is.null(input$selected_country) || input$selected_country == "" || input$selected_country == "Select a country...") return(NULL)
    
    # Try flexible matching
    country_match <- latest_summary %>% 
      distinct(country, .keep_all = TRUE) %>%
      filter(tolower(country) == tolower(input$selected_country))
    
    if(nrow(country_match) == 0) {
      # Try fuzzy matching
      all_countries <- unique(latest_summary$country)
      closest_match <- all_countries[which.min(adist(tolower(input$selected_country), tolower(all_countries)))]
      country_match <- latest_summary %>%
        distinct(country, .keep_all = TRUE) %>%
        filter(tolower(country) == tolower(closest_match))
    }
    
    if(nrow(country_match) == 0) return(NULL)
    
    selected_country_name <- country_match$country[1]
    
    # Union of years from WB, FAO, GRFC, IPC so table includes 2025 and other recent data
    sel_std <- trimws(tolower(selected_country_name))
    yrs_wb <- hunger_data %>% filter(tolower(trimws(country)) == sel_std) %>% pull(year) %>% unique() %>% as.integer()
    yrs_fao <- integer(0)
    if (!is.null(fao_timeseries) && nrow(fao_timeseries) > 0) {
      fao_std <- fao_timeseries %>% mutate(country_std = standardize_country_names(country))
      match_fao <- fao_std %>% filter(tolower(trimws(country_std)) == sel_std) %>% distinct(country_std) %>% pull(country_std)
      if (length(match_fao) == 0) match_fao <- fao_std$country_std[which.min(adist(sel_std, tolower(trimws(unique(fao_std$country_std)))))]
      yrs_fao <- fao_std %>% filter(country_std == match_fao[1]) %>% pull(year) %>% unique() %>% as.integer()
    }
    yrs_grfc <- integer(0)
    if (!is.null(grfc_panel) && nrow(grfc_panel) > 0) {
      grfc_countries <- unique(grfc_panel$country)
      grfc_match <- grfc_countries[tolower(trimws(grfc_countries)) == sel_std]
      if (length(grfc_match) == 0) grfc_match <- grfc_countries[which.min(adist(sel_std, tolower(trimws(grfc_countries))))]
      yrs_grfc <- grfc_panel %>% filter(country == grfc_match[1]) %>% pull(assessment_year) %>% unique() %>% as.integer()
    }
    yrs_ipc <- integer(0)
    if (!is.null(ipc_panel) && nrow(ipc_panel) > 0) {
      ipc_countries <- unique(ipc_panel$country)
      ipc_match <- ipc_countries[tolower(trimws(ipc_countries)) == sel_std]
      if (length(ipc_match) == 0) ipc_match <- ipc_countries[which.min(adist(sel_std, tolower(trimws(ipc_countries))))]
      yrs_ipc <- ipc_panel %>% filter(country == ipc_match[1]) %>% pull(assessment_year) %>% unique() %>% as.integer()
    }
    all_years <- as.integer(sort(unique(c(yrs_wb, yrs_fao, yrs_grfc, yrs_ipc)), decreasing = TRUE))
    if (length(all_years) == 0) return(NULL)
    
    base <- tibble(Year = all_years)
    wb_country <- hunger_data %>%
      filter(tolower(trimws(country)) == sel_std) %>%
      mutate(year = as.integer(as.numeric(year))) %>%
      group_by(year) %>%
      slice_max(order_by = SP.POP.TOTL, n = 1, with_ties = FALSE) %>%
      ungroup() %>%
      select(year, SP.POP.TOTL, NY.GDP.MKTP.CD, NY.GDP.PCAP.CD, SI.POV.DDAY, SP.DYN.LE00.IN,
             AG.LND.AGRI.ZS, SP.DYN.IMRT.IN, SE.ADT.LITR.ZS, SP.RUR.TOTL.ZS, FP.CPI.TOTL.ZG)
    country_time_data <- base %>% left_join(wb_country, by = c("Year" = "year"))
    if (!is.null(fao_timeseries) && nrow(fao_timeseries) > 0) {
      fao_std <- fao_timeseries %>% mutate(country_std = standardize_country_names(country))
      match_fao <- fao_std %>% filter(tolower(trimws(country_std)) == sel_std) %>% distinct(country_std) %>% pull(country_std)
      if (length(match_fao) == 0) match_fao <- fao_std$country_std[which.min(adist(sel_std, tolower(trimws(unique(fao_std$country_std)))))]
      fao_country <- fao_std %>% filter(country_std == match_fao[1]) %>% mutate(year = as.integer(as.numeric(year))) %>% select(year, undernourishment_rate)
      country_time_data <- country_time_data %>% left_join(fao_country, by = c("Year" = "year"))
    } else country_time_data$undernourishment_rate <- NA_real_
    if (!is.null(grfc_panel) && nrow(grfc_panel) > 0) {
      grfc_match <- grfc_countries[tolower(trimws(grfc_countries)) == sel_std]
      if (length(grfc_match) == 0) grfc_match <- grfc_countries[which.min(adist(sel_std, tolower(trimws(grfc_countries))))]
      grfc_country <- grfc_panel %>%
        filter(country == grfc_match[1]) %>%
        mutate(assessment_year = as.integer(as.numeric(assessment_year))) %>%
        group_by(assessment_year) %>% slice(1) %>% ungroup() %>%
        select(assessment_year, ipc_phase, population_phase3_plus)
      country_time_data <- country_time_data %>% left_join(grfc_country, by = c("Year" = "assessment_year"))
    } else {
      country_time_data$ipc_phase <- NA_real_
      country_time_data$population_phase3_plus <- NA_real_
    }
    if (!is.null(ipc_panel) && nrow(ipc_panel) > 0) {
      ipc_match <- ipc_countries[tolower(trimws(ipc_countries)) == sel_std]
      if (length(ipc_match) == 0) ipc_match <- ipc_countries[which.min(adist(sel_std, tolower(trimws(ipc_countries))))]
      ipc_country <- ipc_panel %>%
        filter(country == ipc_match[1]) %>%
        mutate(assessment_year = as.integer(as.numeric(assessment_year))) %>%
        group_by(assessment_year) %>% slice(1) %>% ungroup() %>%
        select(assessment_year, ipc_phase_ipc = ipc_phase, population_phase3_plus_ipc = population_phase3_plus)
      country_time_data <- country_time_data %>%
        left_join(ipc_country, by = c("Year" = "assessment_year")) %>%
        mutate(
          ipc_phase = coalesce(as.numeric(as.character(ipc_phase)), as.numeric(ipc_phase_ipc)),
          population_phase3_plus = coalesce(as.numeric(as.character(population_phase3_plus)), as.numeric(population_phase3_plus_ipc))
        ) %>%
        select(-any_of(c("ipc_phase_ipc", "population_phase3_plus_ipc")))
    }
    # Fallback: for years beyond WB data, fill IPC/Phase 3+ from country's latest summary so recent rows aren't empty
    max_wb_year <- if (length(yrs_wb) > 0) max(yrs_wb, na.rm = TRUE) else 0L
    if (!is.finite(max_wb_year)) max_wb_year <- 0L
    latest_row <- country_match %>% select(grfc_ipc_phase, grfc_population_phase3_plus) %>% slice(1)
    if (nrow(latest_row) == 1 && (any(!is.na(latest_row$grfc_ipc_phase), !is.na(latest_row$grfc_population_phase3_plus)))) {
      country_time_data <- country_time_data %>%
        mutate(
          ipc_phase = if_else(Year > max_wb_year & is.na(ipc_phase), as.numeric(latest_row$grfc_ipc_phase[1]), ipc_phase),
          population_phase3_plus = if_else(Year > max_wb_year & is.na(population_phase3_plus), as.numeric(latest_row$grfc_population_phase3_plus[1]), population_phase3_plus)
        )
    }
    country_time_data <- country_time_data %>%
      rename(
        Population = SP.POP.TOTL,
        "GDP (billions)" = NY.GDP.MKTP.CD,
        "GDP per Capita" = NY.GDP.PCAP.CD,
        "Poverty Rate (%)" = SI.POV.DDAY,
        "Life Expectancy (years)" = SP.DYN.LE00.IN,
        "Agriculture Land (%)" = AG.LND.AGRI.ZS,
        "Infant Mortality (per 1,000)" = SP.DYN.IMRT.IN,
        "Literacy Rate (%)" = SE.ADT.LITR.ZS,
        "Rural Population (%)" = SP.RUR.TOTL.ZS,
        "Inflation (%)" = FP.CPI.TOTL.ZG
      ) %>%
      mutate(
        Population = round(Population / 1e6, 1),
        "GDP (billions)" = round(`GDP (billions)` / 1e9, 2),
        "GDP per Capita" = round(`GDP per Capita`, 0),
        "Poverty Rate (%)" = round(`Poverty Rate (%)`, 1),
        "Life Expectancy (years)" = round(`Life Expectancy (years)`, 1),
        "Agriculture Land (%)" = round(`Agriculture Land (%)`, 1),
        "Infant Mortality (per 1,000)" = round(`Infant Mortality (per 1,000)`, 1),
        "Literacy Rate (%)" = round(`Literacy Rate (%)`, 1),
        "Rural Population (%)" = round(`Rural Population (%)`, 1),
        "Inflation (%)" = round(`Inflation (%)`, 1),
        "Undernourishment (%)" = round(undernourishment_rate, 1),
        "IPC Phase" = as.character(ipc_phase),
        "Phase 3+ Population" = round(population_phase3_plus / 1e6, 2)
      ) %>%
      select(Year, Population, "GDP (billions)", "GDP per Capita", "Poverty Rate (%)", "Life Expectancy (years)",
             "Agriculture Land (%)", "Infant Mortality (per 1,000)", "Literacy Rate (%)", "Rural Population (%)",
             "Inflation (%)", "Undernourishment (%)", "IPC Phase", "Phase 3+ Population") %>%
      arrange(desc(Year))
    
    num_cols <- setdiff(names(country_time_data), "IPC Phase")
    DT::datatable(
      country_time_data,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons',
      rownames = FALSE,
      filter = 'top'
    ) %>%
      formatRound(columns = num_cols[num_cols != "Year"], digits = 1)
  })

  outputOptions(output, "vulnerability_trend_chart", suspendWhenHidden = FALSE)
  outputOptions(output, "country_factor_contribution_chart", suspendWhenHidden = FALSE)
  outputOptions(output, "country_data_table", suspendWhenHidden = FALSE)

  # GHI comparison plot: data-frame-based plot_ly + minimal fallback to avoid [object Object]
  output$ghi_comparison_plot <- renderPlotly({
    p <- tryCatch({
      tryCatch({
        raw <- latest_summary %>% distinct(country, .keep_all = TRUE) %>% filter(!is.na(hunger_vulnerability_rating))
        comparison_data <- as.data.frame(raw, stringsAsFactors = FALSE)
        if (nrow(comparison_data) == 0) return(plot_ly() %>% layout(title = "No data") %>% config(displayModeBar = FALSE))
        has_ghi <- !is.null(ghi_data) && "ghi_score" %in% names(comparison_data) && sum(!is.na(comparison_data$ghi_score)) > 0
        if (has_ghi) {
          comparison_data <- comparison_data[!is.na(comparison_data$ghi_score), , drop = FALSE]
          if (nrow(comparison_data) == 0) has_ghi <- FALSE
        }
        if (has_ghi) {
          xv <- as.numeric(comparison_data$hunger_vulnerability_rating)
          yv <- as.numeric(comparison_data$ghi_score)
          ok <- is.finite(xv) & is.finite(yv)
          if (sum(ok) == 0) return(plot_ly() %>% layout(title = "No valid GHI data") %>% config(displayModeBar = FALSE))
          xv_ok <- xv[ok]
          yv_ok <- yv[ok]
          fit <- stats::lm(yv_ok ~ xv_ok)
          r2 <- summary(fit)$r.squared
          if (!is.finite(r2)) r2 <- stats::cor(xv_ok, yv_ok, use = "complete.obs")^2
          if (!is.finite(r2)) r2 <- 0
          df <- data.frame(x = xv_ok, y = yv_ok, text = paste(round(xv_ok, 1), round(yv_ok, 1), sep = " | "), stringsAsFactors = FALSE)
          p <- plot_ly(data = df, x = ~x, y = ~y, type = "scatter", mode = "markers", text = ~text, hoverinfo = "text",
                      marker = list(size = 10, color = "#e74c3c", line = list(width = 1, color = "rgba(0,0,0,0.2)"), opacity = 0.7)) %>%
            layout(
              title = "Our Vulnerability Score vs. GHI",
              xaxis = list(title = "Our Score", range = c(0, 100)),
              yaxis = list(title = "GHI Score", range = c(0, 100)),
              margin = list(l = 70, r = 30, t = 80, b = 70),
              showlegend = FALSE,
              annotations = list(
                list(
                  text = paste0("<b>R² = ", format(round(r2, 3), nsmall = 3), "</b>"),
                  xref = "paper", yref = "paper",
                  x = 0.02, y = 0.98,
                  xanchor = "left", yanchor = "top",
                  showarrow = FALSE,
                  font = list(size = 13, color = "#1e293b"),
                  bgcolor = "rgba(255,255,255,0.92)",
                  bordercolor = "#cbd5e1",
                  borderwidth = 1
                )
              )
            ) %>%
            config(displayModeBar = FALSE)
          line_df <- data.frame(x = c(0, 100), y = c(0, 100))
          p <- p %>% add_trace(data = line_df, x = ~x, y = ~y, type = "scatter", mode = "lines",
                              line = list(color = "rgba(128,128,128,0.3)", width = 2, dash = "dash"), showlegend = FALSE, hoverinfo = "skip")
          if (length(xv_ok) > 2L) {
            x_line <- seq(0, 100, length.out = 100)
            y_line <- as.numeric(stats::predict(fit, newdata = data.frame(xv_ok = x_line)))
            y_line[!is.finite(y_line)] <- NA_real_
            ols_df <- data.frame(x = x_line, y = y_line)
            p <- p %>% add_trace(
              data = ols_df, x = ~x, y = ~y, type = "scatter", mode = "lines",
              line = list(color = "rgba(231,76,60,0.55)", width = 2, dash = "dot"),
              showlegend = FALSE, hoverinfo = "skip"
            )
          }
          return(p)
        }
        xv <- as.numeric(comparison_data$hunger_vulnerability_rating)
        xv <- xv[is.finite(xv)]
        if (length(xv) == 0) return(plot_ly() %>% layout(title = "No data") %>% config(displayModeBar = FALSE))
        df1 <- data.frame(x = xv)
        plot_ly(data = df1, x = ~x, type = "histogram", nbinsx = 25, marker = list(color = "#3c8dbc")) %>%
          layout(title = "Distribution of Our Vulnerability Scores", xaxis = list(title = "Score", range = c(0, 100)),
                 yaxis = list(title = "Count"), margin = list(l = 70, r = 30, t = 80, b = 70)) %>%
          config(displayModeBar = FALSE)
      }, error = function(e) minimal_plotly())
    }, error = function(e) minimal_plotly())
    if (!inherits(p, "plotly")) p <- minimal_plotly()
    p
  })
  
  # GHI distribution plot: data-frame-based + minimal fallback
  output$ghi_distribution_plot <- renderPlotly({
    p <- tryCatch({
      tryCatch({
        raw <- latest_summary %>% distinct(country, .keep_all = TRUE) %>% filter(!is.na(hunger_vulnerability_rating))
        comparison_data <- as.data.frame(raw, stringsAsFactors = FALSE)
        if (nrow(comparison_data) == 0) return(plot_ly() %>% layout(title = "No data") %>% config(displayModeBar = FALSE))
        has_ghi <- !is.null(ghi_data) && "ghi_score" %in% names(comparison_data) && sum(!is.na(comparison_data$ghi_score)) > 0
        if (has_ghi) {
          comparison_data <- comparison_data[!is.na(comparison_data$ghi_score), , drop = FALSE]
          if (nrow(comparison_data) == 0) has_ghi <- FALSE
        }
        if (has_ghi) {
          x1 <- as.numeric(comparison_data$hunger_vulnerability_rating)
          x2 <- as.numeric(comparison_data$ghi_score)
          x1 <- x1[is.finite(x1)]; x2 <- x2[is.finite(x2)]
          if (length(x1) == 0 && length(x2) == 0) return(plot_ly() %>% layout(title = "No valid data") %>% config(displayModeBar = FALSE))
          p <- plot_ly()
          if (length(x1) > 0) p <- p %>% add_trace(data = data.frame(x = x1), x = ~x, type = "histogram", name = "Our Score", marker = list(color = "#3c8dbc", opacity = 0.7), nbinsx = 20)
          if (length(x2) > 0) p <- p %>% add_trace(data = data.frame(x = x2), x = ~x, type = "histogram", name = "GHI Score", marker = list(color = "#17a2b8", opacity = 0.7), nbinsx = 20)
          p %>% layout(title = "Score Distribution Comparison", xaxis = list(title = "Score", range = c(0, 100)),
                      yaxis = list(title = "Count"), barmode = "overlay", margin = list(l = 60, r = 20, t = 60, b = 60), legend = list(x = 0.7, y = 0.95)) %>%
            config(displayModeBar = FALSE)
        } else {
          xv <- as.numeric(comparison_data$hunger_vulnerability_rating)
          xv <- xv[is.finite(xv)]
          if (length(xv) == 0) return(plot_ly() %>% layout(title = "No data") %>% config(displayModeBar = FALSE))
          plot_ly(data = data.frame(x = xv), x = ~x, type = "histogram", nbinsx = 20, marker = list(color = "#3c8dbc", opacity = 0.7)) %>%
            layout(title = "Our Vulnerability Score Distribution", xaxis = list(title = "Score", range = c(0, 100)), yaxis = list(title = "Count"),
                   margin = list(l = 60, r = 20, t = 60, b = 60)) %>% config(displayModeBar = FALSE)
        }
      }, error = function(e) minimal_plotly())
    }, error = function(e) minimal_plotly())
    if (!inherits(p, "plotly")) p <- minimal_plotly()
    p
  })
  
  # GHI correlation plot: data-frame-based + minimal fallback
  output$ghi_correlation_plot <- renderPlotly({
    p <- tryCatch({
      tryCatch({
        raw <- latest_summary %>% distinct(country, .keep_all = TRUE) %>% filter(!is.na(hunger_vulnerability_rating))
        comparison_data <- as.data.frame(raw, stringsAsFactors = FALSE)
        if (nrow(comparison_data) == 0) return(plot_ly() %>% layout(title = "No data") %>% config(displayModeBar = FALSE))
        has_ghi <- !is.null(ghi_data) && "ghi_score" %in% names(comparison_data) && sum(!is.na(comparison_data$ghi_score)) > 0
        if (has_ghi) {
          comparison_data <- comparison_data[!is.na(comparison_data$ghi_score), , drop = FALSE]
          if (nrow(comparison_data) < 2) return(plot_ly() %>% layout(title = "Not enough GHI data") %>% config(displayModeBar = FALSE))
          v <- as.numeric(comparison_data$hunger_vulnerability_rating)
          g <- as.numeric(comparison_data$ghi_score)
          ok <- is.finite(v) & is.finite(g)
          if (sum(ok) < 2) return(plot_ly() %>% layout(title = "Not enough points") %>% config(displayModeBar = FALSE))
          v <- v[ok]; g <- g[ok]
          fit <- stats::lm(g ~ v)
          r2 <- summary(fit)$r.squared
          if (!is.finite(r2)) r2 <- stats::cor(v, g, use = "complete.obs")^2
          if (!is.finite(r2)) r2 <- 0
          df <- data.frame(x = v, y = g, text = paste(round(v, 1), round(g, 1), sep = " | "), stringsAsFactors = FALSE)
          p <- plot_ly(data = df, x = ~x, y = ~y, type = "scatter", mode = "markers", text = ~text, hoverinfo = "text",
                       marker = list(size = 8, color = "#e74c3c", opacity = 0.6)) %>%
            layout(
              title = "Score correlation: our vulnerability score vs. GHI",
              xaxis = list(title = "Our Score", range = c(0, 100)),
              yaxis = list(title = "GHI Score", range = c(0, 100)),
              margin = list(l = 60, r = 20, t = 60, b = 60),
              annotations = list(
                list(
                  text = paste0("<b>R² = ", format(round(r2, 3), nsmall = 3), "</b>"),
                  xref = "paper", yref = "paper",
                  x = 0.02, y = 0.98,
                  xanchor = "left", yanchor = "top",
                  showarrow = FALSE,
                  font = list(size = 12, color = "#1e293b"),
                  bgcolor = "rgba(255,255,255,0.92)",
                  bordercolor = "#cbd5e1",
                  borderwidth = 1
                )
              )
            ) %>%
            config(displayModeBar = FALSE)
          if (length(v) > 2) {
            fit <- lm(g ~ v)
            x_line <- seq(0, 100, length.out = 100)
            y_line <- as.numeric(suppressWarnings(predict(fit, newdata = data.frame(v = x_line))))
            y_line[!is.finite(y_line)] <- 0
            line_df <- data.frame(x = x_line, y = y_line)
            p <- p %>% add_trace(data = line_df, x = ~x, y = ~y, type = "scatter", mode = "lines",
                                line = list(color = "rgba(231,76,60,0.5)", width = 2, dash = "dash"), showlegend = FALSE, hoverinfo = "skip")
          }
          return(p)
        }
        d <- as.data.frame(latest_summary %>% filter(!is.na(hunger_vulnerability_rating) & !is.na(undernourishment_rate)) %>% distinct(country, .keep_all = TRUE), stringsAsFactors = FALSE)
        if (nrow(d) > 0) {
          v <- as.numeric(d$hunger_vulnerability_rating)
          u <- as.numeric(d$undernourishment_rate)
          ok <- is.finite(v) & is.finite(u)
          if (sum(ok) < 2) return(plot_ly() %>% layout(title = "Not enough data") %>% config(displayModeBar = FALSE))
          v <- v[ok]; u <- u[ok]
          cor_alt <- cor(v, u, use = "complete.obs")
          if (!is.finite(cor_alt)) cor_alt <- 0
          df_alt <- data.frame(x = v, y = u, text = paste(round(v, 1), round(u, 1), sep = " | "), stringsAsFactors = FALSE)
          return(plot_ly(data = df_alt, x = ~x, y = ~y, type = "scatter", mode = "markers", text = ~text, hoverinfo = "text",
                         marker = list(size = 8, color = "#e74c3c", opacity = 0.6)) %>%
                   layout(title = paste0("Vulnerability vs Undernourishment r = ", round(cor_alt, 3)),
                          xaxis = list(title = "Our Score", range = c(0, 100)), yaxis = list(title = "Undernourishment %"),
                          margin = list(l = 60, r = 20, t = 60, b = 60)) %>% config(displayModeBar = FALSE))
        }
        plot_ly() %>% layout(title = "No data for correlation") %>% config(displayModeBar = FALSE)
      }, error = function(e) minimal_plotly())
    }, error = function(e) minimal_plotly())
    if (!inherits(p, "plotly")) p <- minimal_plotly()
    p
  })

  paper_models_tbl <- reactive({
    read_global_paper_csv("output/global_models_1_4_tables.csv")
  })

  buffer_rankings_tbl_data <- reactive({
    read_global_paper_csv("output/global_buffer_rankings.csv")
  })

  buffer_mc_tbl_data <- reactive({
    read_global_paper_csv("output/global_mc_buffer_uncertainty.csv")
  })

  buffer_collapse_tbl_data <- reactive({
    read_global_paper_csv("output/global_mc_collapse_dynamics.csv")
  })

  output$paper_model1_meta <- renderUI({
    res <- prepare_global_paper_model_tbl(paper_models_tbl(), "M1_baseline_vulnerability")
    paper_model_meta_html(res$meta)
  })

  output$paper_model2_meta <- renderUI({
    res <- prepare_global_paper_model_tbl(paper_models_tbl(), "M2_multivariate")
    paper_model_meta_html(res$meta)
  })

  output$paper_model3_meta <- renderUI({
    res <- prepare_global_paper_model_tbl(paper_models_tbl(), "M3_buffer_determinants")
    paper_model_meta_html(res$meta)
  })

  output$paper_model1_tbl <- DT::renderDataTable({
    res <- prepare_global_paper_model_tbl(paper_models_tbl(), "M1_baseline_vulnerability")
    render_regression_dt(res$table, page_length = 10)
  }, server = FALSE)

  output$paper_model2_tbl <- DT::renderDataTable({
    res <- prepare_global_paper_model_tbl(paper_models_tbl(), "M2_multivariate")
    render_regression_dt(res$table, page_length = 10)
  }, server = FALSE)

  output$paper_model3_tbl <- DT::renderDataTable({
    res <- prepare_global_paper_model_tbl(paper_models_tbl(), "M3_buffer_determinants")
    render_regression_dt(res$table, page_length = 10)
  }, server = FALSE)

  output$buffer_top_tbl <- DT::renderDataTable({
    d <- buffer_rankings_tbl_data()
    ranks <- if ("rank" %in% names(d)) seq_len(min(15, nrow(d))) else integer(0)
    d <- prepare_buffer_rankings_tbl(d, ranks)
    DT::datatable(
      d,
      options = list(dom = "t", pageLength = 15),
      rownames = FALSE,
      class = "cell-border stripe hover"
    )
  }, server = FALSE)

  output$buffer_bottom_tbl <- DT::renderDataTable({
    d <- buffer_rankings_tbl_data()
    if ("rank" %in% names(d) && nrow(d) > 0) {
      max_rank <- max(d$rank, na.rm = TRUE)
      ranks <- (max_rank - 9):max_rank
    } else {
      ranks <- integer(0)
    }
    d <- prepare_buffer_rankings_tbl(d, ranks)
    DT::datatable(
      d,
      options = list(dom = "t", pageLength = 10),
      rownames = FALSE,
      class = "cell-border stripe hover"
    )
  }, server = FALSE)

  output$buffer_mc_key_tbl <- DT::renderDataTable({
    d <- prepare_buffer_mc_key_tbl(buffer_mc_tbl_data())
    DT::datatable(
      d,
      options = list(dom = "t", pageLength = 10),
      rownames = FALSE,
      class = "cell-border stripe hover"
    )
  }, server = FALSE)

  output$buffer_collapse_tbl <- DT::renderDataTable({
    d <- prepare_buffer_collapse_tbl(buffer_collapse_tbl_data())
    DT::datatable(
      d,
      options = list(dom = "t", pageLength = 10),
      rownames = FALSE,
      class = "cell-border stripe hover"
    )
  }, server = FALSE)
  
  # Correlation plot (includes undernourishment % and vulnerability score)
  output$correlation_plot <- renderPlotly({
    tryCatch({
      df <- tryCatch({ filtered_summary() }, error = function(e) { latest_summary %>% distinct(country, .keep_all = TRUE) })
      df <- as.data.frame(df %>% select(population, gdp_per_capita, poverty, agriculture_land,
                                        life_expectancy, literacy, undernourishment_rate, hunger_vulnerability_rating))
      if (nrow(df) < 3) {
        return(plot_ly() %>% add_annotations(text = "Not enough data for correlation matrix", x = 0.5, y = 0.5, showarrow = FALSE) %>%
                 layout(xaxis = list(showticklabels = FALSE), yaxis = list(showticklabels = FALSE)) %>% config(displayModeBar = FALSE))
      }
      cor_data <- cor(df, use = "complete.obs")
      if (any(is.na(cor_data))) cor_data[is.na(cor_data)] <- 0

      var_labels <- c(
        "Population",
        "GDP per capita",
        "Poverty rate",
        "Agricultural land",
        "Life expectancy",
        "Literacy rate",
        "Undernourishment rate",
        "Vulnerability score"
      )
      colnames(cor_data) <- var_labels
      rownames(cor_data) <- var_labels

      corr_cell_text_color <- function(v) {
        if (is.na(v) || abs(v) < 0.38) "#0f172a" else "#ffffff"
      }

      annotations <- list()
      for (i in seq_len(nrow(cor_data))) {
        for (j in seq_len(ncol(cor_data))) {
          v <- cor_data[i, j]
          annotations[[length(annotations) + 1]] <- list(
            x = var_labels[j],
            y = var_labels[i],
            xref = "x",
            yref = "y",
            text = sprintf("%.2f", v),
            showarrow = FALSE,
            font = list(color = corr_cell_text_color(v), size = 13, family = "Arial, sans-serif")
          )
        }
      }

      plot_ly(
        x = var_labels,
        y = var_labels,
        z = cor_data,
        type = "heatmap",
        colorscale = list(
          c(0, "#2166ac"),
          c(0.25, "#92c5de"),
          c(0.5, "#f7f7f7"),
          c(0.75, "#f4a582"),
          c(1, "#b2182b")
        ),
        zmin = -1,
        zmax = 1,
        hovertemplate = "<b>%{y} vs %{x}</b><br>Correlation: %{z:.3f}<extra></extra>",
        showscale = TRUE
      ) %>%
        layout(
          title = list(
            text = "Correlation Matrix of Key Variables",
            font = list(size = 17, color = "#2c3e50"),
            x = 0.46,
            xanchor = "center",
            yref = "paper",
            yanchor = "bottom",
            y = 1,
            pad = list(t = 4, b = 12)
          ),
          xaxis = list(
            title = "",
            side = "bottom",
            tickangle = -40,
            tickfont = list(size = 10, color = "#334155"),
            automargin = TRUE,
            domain = c(0, 0.86)
          ),
          yaxis = list(
            title = "",
            autorange = "reversed",
            tickfont = list(size = 10, color = "#334155"),
            automargin = TRUE,
            domain = c(0, 0.90)
          ),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          margin = list(t = 90, b = 20, l = 20, r = 70),
          annotations = annotations,
          colorbar = list(
            title = list(text = "<b>Correlation</b>", font = list(size = 12)),
            len = 0.55,
            y = 0.5,
            yanchor = "middle",
            tickvals = c(-1, -0.5, 0, 0.5, 1),
            ticktext = c("-1.0", "-0.5", "0.0", "0.5", "1.0"),
            tickfont = list(size = 10)
          )
        ) %>%
        config(
          displayModeBar = TRUE,
          displaylogo = FALSE,
          modeBarButtonsToRemove = c("select2d", "lasso2d"),
          responsive = TRUE,
          toImageButtonOptions = list(
            format = "jpeg",
            filename = "correlation_matrix",
            height = 640,
            width = 900,
            scale = 2
          )
        )
    }, error = function(e) {
      plot_ly() %>% add_annotations(text = paste("Error:", if (is.character(e$message)) e$message else "loading matrix"), x = 0.5, y = 0.5, showarrow = FALSE) %>%
        layout(xaxis = list(showticklabels = FALSE), yaxis = list(showticklabels = FALSE)) %>% config(displayModeBar = FALSE)
    })
  })
  
  # Regression summary - now handled in UI with "coming soon" message
  output$regression_summary <- renderText({
    # This output is no longer used as we show "coming soon" in the UI
    # Keeping for backward compatibility
    ""
  })
  
  # Model plot
  output$model_plot <- renderPlotly({
    # Simple linear model for demonstration
    model_data <- filtered_summary() %>%
      select(poverty, gdp_per_capita, agriculture_land) %>%
      filter(!is.na(poverty) & !is.na(gdp_per_capita) & !is.na(agriculture_land))
    
    if(nrow(model_data) > 10) {
      model <- lm(poverty ~ gdp_per_capita + agriculture_land, data = model_data)
      
      # Create prediction plot
      p <- plot_ly(model_data, x = ~gdp_per_capita, y = ~poverty,
                   type = "scatter", mode = "markers",
                   text = ~paste("GDP per Capita: $", round(gdp_per_capita, 0),
                                "<br>Poverty Rate:", round(poverty, 1), "%"),
                   hoverinfo = "text") %>%
        layout(
          title = "Poverty Rate vs GDP per Capita",
          xaxis = list(title = "GDP per Capita (USD)"),
          yaxis = list(title = "Poverty Rate (%)")
        )
      
      p
    } else {
      plot_ly() %>%
        add_annotations(
          text = "Insufficient data for model visualization",
          x = 0.5, y = 0.5,
          showarrow = FALSE,
          font = list(size = 16)
        ) %>%
        layout(
          xaxis = list(showgrid = FALSE, showticklabels = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE)
        )
    }
  })
  
  # Model performance
  output$model_performance <- renderText({
    model_data <- filtered_summary() %>%
      select(poverty, gdp_per_capita, agriculture_land) %>%
      filter(!is.na(poverty) & !is.na(gdp_per_capita) & !is.na(agriculture_land))
    
    if(nrow(model_data) > 10) {
      model <- lm(poverty ~ gdp_per_capita + agriculture_land, data = model_data)
      performance_text <- capture.output(summary(model))
      paste(performance_text, collapse = "\n")
    } else {
      "Insufficient data for model performance evaluation"
    }
  })
  
  # Feature importance
  output$feature_importance <- renderPlotly({
    model_data <- filtered_summary() %>%
      select(poverty, gdp_per_capita, agriculture_land) %>%
      filter(!is.na(poverty) & !is.na(gdp_per_capita) & !is.na(agriculture_land))
    
    if(nrow(model_data) > 10) {
      model <- lm(poverty ~ gdp_per_capita + agriculture_land, data = model_data)
      
      # Extract coefficients (absolute values for importance)
      coefs <- abs(coef(model)[-1])  # Remove intercept
      features <- c("GDP per Capita", "Agriculture Land")
      
      p <- plot_ly(
        x = coefs,
        y = features,
        type = "bar",
        orientation = "h",
        marker = list(color = "#3c8dbc")
      ) %>%
        layout(
          title = "Feature Importance (Absolute Coefficients)",
          xaxis = list(title = "Absolute Coefficient Value"),
          yaxis = list(title = "Features")
        )
      
      p
    } else {
      plot_ly() %>%
        add_annotations(
          text = "Insufficient data for feature importance",
          x = 0.5, y = 0.5,
          showarrow = FALSE,
          font = list(size = 16)
        ) %>%
        layout(
          xaxis = list(showgrid = FALSE, showticklabels = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE)
        )
    }
  })
}

# =============================================================================
# RUN THE APPLICATION
# =============================================================================

# Create ui object for runApp() compatibility
ui <- dashboardPage(
  header, sidebar, body,
  title = "Global Hunger Vulnerability Map & Country Profiles",
  skin = "blue"
)

# Only run shinyApp if this file is executed directly (not sourced)
# This allows the app to be sourced for testing/debugging or used with runApp()
# Check in both global and calling environment
skip_app <- tryCatch({
  exists("SKIP_SHINY_APP", envir = .GlobalEnv) || 
  exists("SKIP_SHINY_APP", envir = parent.frame())
}, error = function(e) FALSE)

# Explicit static files path for shinyApp(ui, server) deployments.
# This exposes files in ./www at /static/<filename> (e.g., /static/sitemap.xml).
shiny::addResourcePath("static", "www")

if (!skip_app) {
  shinyApp(ui = ui, server = server)
}
