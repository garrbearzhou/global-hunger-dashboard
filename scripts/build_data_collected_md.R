#!/usr/bin/env Rscript
# Build DATA_Collected.md: list all data sources in data/raw with country coverage and holes.
# Run from project root: Rscript scripts/build_data_collected_md.R

library(readr)
library(dplyr)
library(tidyr)

# Run from project root (parent of scripts/)
if (file.exists("data/raw")) setwd(getwd()) else if (file.exists("../data/raw")) setwd("..")
raw <- "data/raw"
if (!dir.exists(raw)) stop("Run from project root: Rscript scripts/build_data_collected_md.R")

# Helper: get unique country/ISO3 from a CSV (guess country column)
get_countries_from_csv <- function(path, country_col = NULL, iso3_col = NULL, skip = 0) {
  if (!file.exists(path)) return(character(0))
  x <- tryCatch(
    read_csv(path, show_col_types = FALSE, n_max = 1e5, skip = skip),
    error = function(e) NULL
  )
  if (is.null(x) || nrow(x) == 0) return(character(0))
  nm <- names(x)
  if (!is.null(country_col) && country_col %in% nm) return(unique(na.omit(trimws(as.character(x[[country_col]])))))
  if (!is.null(iso3_col) && iso3_col %in% nm) return(unique(na.omit(trimws(x[[iso3_col]]))))
  for (c in c("country", "Country", "Name", "Area", "Entity", "country_std", "GEO_NAME_SHORT", "importer_country_name")) {
    if (c %in% nm) return(unique(na.omit(trimws(as.character(x[[c]])))))
  }
  if ("ISO3" %in% nm) return(unique(na.omit(trimws(x$ISO3))))
  if ("iso3c" %in% nm) return(unique(na.omit(trimws(x$iso3c))))
  if ("Country (ISO3)" %in% nm) return(unique(na.omit(trimws(x$`Country (ISO3)`))))
  character(0)
}

# Helper: get countries from CSV with year columns (e.g. climate vulnerability)
get_countries_from_csv_year_cols <- function(path, name_col = "Name") {
  if (!file.exists(path)) return(character(0))
  x <- tryCatch(
    read_csv(path, show_col_types = FALSE, n_max = 500),
    error = function(e) NULL
  )
  if (is.null(x) || nrow(x) == 0) return(character(0))
  if (name_col %in% names(x)) return(unique(na.omit(trimws(as.character(x[[name_col]])))))
  if ("Country" %in% names(x)) return(unique(na.omit(trimws(as.character(x$Country)))))
  character(0)
}

# Define all known data sources: path (relative to raw) and how to get countries
sources <- list(
  list(name = "World Bank", path = "world_bank_data.csv", col = "country"),
  list(name = "FAO (fao_data)", path = "fao/fao_data.csv", col = "country"),
  list(name = "FAO Food Security (Food_Security_Data_E_All_Data)", path = "fao/FAO_Data/Food_Security_Data_E_All_Data.csv", col = "Area"),
  list(name = "FAO FPMA", path = "fao/FAO_Data/fao fpma data.csv", col = NULL),
  list(name = "WFP GRFC (xlsx)", path = "wfp/grfc2016-2024_data.xlsx", xlsx = TRUE),
  list(name = "IPC general", path = "ipc/ipc data general data.csv", col = "Country", skip = 1),
  list(name = "IPC historical (2017-2025)", path = "ipc/ipc all data 2017-2025.csv", col = "Country"),  # ISO3
  list(name = "Historical hunger outbreaks", path = "historical_hunger_outbreaks.csv", col = "country"),
  list(name = "WHO stunting", path = "who/child_stunting_data.csv", col = "GEO_NAME_SHORT"),
  list(name = "OWID poverty", path = "our_world_in_data/poverty data.csv", col = "Country"),
  list(name = "Climate vulnerability (cv/vulnerability)", path = "climate vulnerability/cv/vulnerability/vulnerability.csv", year_cols = TRUE, name_col = "Name"),
  list(name = "Climate cv exposure", path = "climate vulnerability/cv/vulnerability/exposure.csv", year_cols = TRUE, name_col = "Name"),
  list(name = "Climate cv sensitivity", path = "climate vulnerability/cv/vulnerability/sensitivity.csv", year_cols = TRUE, name_col = "Name"),
  list(name = "Climate cv capacity", path = "climate vulnerability/cv/vulnerability/capacity.csv", year_cols = TRUE, name_col = "Name"),
  list(name = "Climate cv food", path = "climate vulnerability/cv/vulnerability/food.csv", year_cols = TRUE, name_col = "Name"),
  list(name = "Climate cv water", path = "climate vulnerability/cv/vulnerability/water.csv", year_cols = TRUE, name_col = "Name"),
  list(name = "Climate cv health", path = "climate vulnerability/cv/vulnerability/health.csv", year_cols = TRUE, name_col = "Name"),
  list(name = "Climate (Global Data Lab)", path = "global_data_lab/climate/climate vunerability index.csv", year_cols = TRUE, name_col = "Country"),
  list(name = "Health vulnerability (Global Data Lab)", path = "global_data_lab/health/health vunerability data.csv", col = "country"),
  list(name = "UNHCR displaced", path = "un/unhcr/displaced people data/persons_of_concern.csv", col = "Country of Asylum"),
  list(name = "IDU (HDX)", path = "hdx/idu", idu_dir = TRUE),
  list(name = "EM-DAT disasters", path = "em_dat/em_dat_data.csv", col = "country"),
  list(name = "Food trade dependency", path = "food trade dependency/data overview.csv", col = "importer_country_name"),
  list(name = "Food supply (OWID)", path = "our_world_in_data/food supply data.csv", col = "Entity"),
  list(name = "Water per capita (OWID)", path = "our_world_in_data/freshwater resources per capita/renewable-water-resources-per-capita.csv", col = "Entity"),
  list(name = "Agriculture water withdrawals (OWID)", path = "our_world_in_data/agriculture water withdrawals/agricultural-water-withdrawals.csv", col = "Entity"),
  list(name = "USDA agricultural", path = "usda/agricultural_production_1.csv", col = "country"),
  list(name = "GHI (Global Hunger Index)", path = "global hunger index/2025 csv.xlsx", xlsx = TRUE),
  list(name = "ACLED conflict", path = "acled - conflict data/fatalities per country.xlsx", xlsx = TRUE),
  list(name = "WPR malnutrition", path = "wpr/malnutrition-rate-by-country-2025.csv", col = "country")
)

# IDU: aggregate from all idu *.csv in directory
get_idu_countries <- function(dir_path) {
  if (!dir.exists(dir_path)) return(character(0))
  f <- list.files(dir_path, pattern = "^idu .+\\.csv$", ignore.case = TRUE, full.names = TRUE)
  out <- character(0)
  for (fp in f) {
    x <- tryCatch(read_csv(fp, show_col_types = FALSE, col_types = cols(.default = col_character())), error = function(e) NULL)
    if (!is.null(x) && nrow(x) > 0 && "country" %in% names(x)) out <- c(out, unique(na.omit(trimws(x$country))))
  }
  unique(out)
}

# XLSX: try first column or common names; GHI file has title+header+footnote so use skip=3 and column 2
get_countries_from_xlsx <- function(path) {
  if (!file.exists(path)) return(character(0))
  if (!requireNamespace("readxl", quietly = TRUE)) return(character(0))
  # GHI 2025 csv.xlsx: row 1 title, row 2 header (Rank1, Country, ...), row 3 footnote; country in column B
  if (grepl("global hunger index|2025 csv\\.xlsx", path, ignore.case = TRUE)) {
    x <- tryCatch(readxl::read_excel(path, sheet = 1, skip = 3, col_names = FALSE, n_max = 150), error = function(e) NULL)
    if (!is.null(x) && ncol(x) >= 2) return(unique(na.omit(trimws(as.character(x[[2]])))))
    return(character(0))
  }
  x <- tryCatch(readxl::read_excel(path, sheet = 1, n_max = 500), error = function(e) NULL)
  if (is.null(x) || nrow(x) == 0) return(character(0))
  nm <- names(x)
  for (c in c("country", "Country", "Country Name", "Name", "country name")) {
    if (any(grepl(c, nm, ignore.case = TRUE))) {
      cc <- nm[grepl(c, nm, ignore.case = TRUE)][1]
      return(unique(na.omit(trimws(as.character(x[[cc]])))))
    }
  }
  if (ncol(x) >= 1) return(unique(na.omit(trimws(as.character(x[[1]])))))
  character(0)
}

# Run collectors
results <- list()
backbone_set <- character(0)

for (s in sources) {
  path <- file.path(raw, s$path)
  countries <- character(0)
  if (!is.null(s$idu_dir) && s$idu_dir) {
    countries <- get_idu_countries(path)
  } else if (!is.null(s$xlsx) && s$xlsx) {
    countries <- get_countries_from_xlsx(path)
  } else if (!is.null(s$year_cols) && s$year_cols) {
    name_col <- if (!is.null(s$name_col)) s$name_col else "Name"
    countries <- get_countries_from_csv_year_cols(path, name_col)
  } else if (!is.null(s$col)) {
    skip <- if (!is.null(s$skip)) s$skip else 0
    countries <- get_countries_from_csv(path, country_col = s$col, skip = skip)
  } else {
    countries <- get_countries_from_csv(path)
  }
  # Filter out empty strings and obvious non-countries
  countries <- setdiff(unique(trimws(as.character(countries))), c("", "NA", "World", "Total"))
  # Drop obvious non-country values (numbers, long footnotes, headers)
  countries <- countries[nchar(countries) >= 2 & nchar(countries) <= 60 & !grepl("^[0-9]+$", countries) & !grepl("=", countries, fixed = TRUE) & !grepl("ranked|designated|insert|please|note:", tolower(countries))]
  if (length(countries) > 0 && !(s$name %in% c("GHI (Global Hunger Index)"))) backbone_set <- unique(c(backbone_set, countries))
  results[[length(results) + 1]] <- list(name = s$name, path = s$path, countries = sort(countries), n = length(countries))
}

# Backbone: use World Bank countries as reference (so "holes" = WB countries missing from each source)
wb_path <- file.path(raw, "world_bank_data.csv")
backbone <- character(0)
if (file.exists(wb_path)) {
  wb_c <- get_countries_from_csv(wb_path, country_col = "country")
  # Drop regions, aggregates, and non-country strings
  drop <- c("World", "Total", "Africa", "Americas", "Europe", "Asia", "Oceania", "Africa (FAO)", "Americas (FAO)",
    "Africa Eastern and Southern", "Africa Western and Central", "Arab World", "East Asia and Pacific", "Europe and Central Asia",
    "Latin America and Caribbean", "Middle East and North Africa", "South Asia", "Sub-Saharan Africa", "European Union",
    "Analysis period", "Antarctica", "Anguilla", "Akrotiri and Dhekelia", "IDA & IBRD", "Low & middle income", "Middle income", "High income",
    "IBRD only", "IDA only", "IDA total", "Early-demographic", "Late-demographic", "OECD members", "Fragile and conflict affected",
    "Pre-demographic dividend", "Post-demographic dividend", "Small states", "Other small states", "Pacific island small states",
    "Caribbean small states", "East Asia & Pacific", "Europe & Central Asia", "Latin America & Caribbean", "North America",
    "Sub-Saharan Africa (IDA & IBRD)", "East Asia & Pacific (IDA & IBRD)", "South Asia (IDA & IBRD)", "Euro area",
    "Central Europe and the Baltics", "Channel Islands", "Kosovo", "Not classified", "St. Martin (French part)")
  # Exclude corrupted country names (e.g. Barb994.64806074889 = text concatenated with number)
  backbone <- sort(setdiff(unique(wb_c[nchar(wb_c) >= 2 & nchar(wb_c) <= 55 & !grepl("^[0-9.]+$", wb_c) & !grepl("^[A-Za-z]+[0-9.]+$", trimws(wb_c))]), drop))
}

# Build markdown
md <- c(
  "# Data Collected",
  "",
  "This document lists **all data sources** under `data/raw` that are integrated or available in the project, with **country coverage** and **holes** (countries missing from each source).",
  "",
  "**Backbone:** The reference country list is **World Bank** (so *holes* = WB countries that do not appear in that source). Sources that use different naming (e.g. ISO3) may show more holes unless names are standardized.",
  "",
  "Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M"), "",
  "---",
  ""
)

# Summary table
md <- c(md, "## Summary", "")
md <- c(md, "| Data source | Path | Countries with data | Holes (count) |", "|-------------|------|---------------------|----------------|")
for (r in results) {
  holes <- setdiff(backbone, r$countries)
  n_holes <- length(holes)
  md <- c(md, sprintf("| %s | `%s` | %d | %d |", r$name, r$path, r$n, n_holes))
}
md <- c(md, "")

# Per-source detail: countries with data + list of holes
md <- c(md, "---", "", "## Detail by source", "")
for (r in results) {
  holes <- setdiff(backbone, r$countries)
  md <- c(md, paste0("### ", r$name), "", sprintf("- **Path:** `%s`", r$path), "")
  md <- c(md, sprintf("- **Countries with data:** %d", r$n), "")
  if (r$n <= 80) {
    md <- c(md, "  - ", paste(r$countries, collapse = ", "), "", "")
  } else {
    md <- c(md, "  - *(too many to list; see backbone below)*", "", "")
  }
  md <- c(md, sprintf("- **Holes (countries in backbone but missing from this source):** %d", length(holes)), "")
  if (length(holes) > 0 && length(holes) <= 150) {
    md <- c(md, "  - ", paste(holes, collapse = ", "), "", "")
  } else if (length(holes) > 150) {
    md <- c(md, "  - *(first 100)* ", paste(head(holes, 100), collapse = ", "), " ...", "", "")
  }
  md <- c(md, "")
}

md <- c(md, "---", "", "## Backbone (World Bank countries used as reference)", "", sprintf("Total: %d countries.", length(backbone)), "")
if (length(backbone) <= 250) {
  md <- c(md, "", paste(backbone, collapse = ", "), "")
} else {
  md <- c(md, "", paste(head(backbone, 150), collapse = ", "), "", "*(and more)*", "")
}

writeLines(md, "DATA_Collected.md")
message("Wrote DATA_Collected.md")
