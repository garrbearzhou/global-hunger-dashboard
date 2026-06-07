#!/usr/bin/env Rscript
# Profile integrated raw datasets: dimensions, geo keys, time range, type/coding issues.
# Run from project root: Rscript scripts/analyze_data_discrepancies.R
# Writes: docs/data_discrepancy_profile.csv and docs/data_source_discrepancies.md

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
})


if (file.exists("data/raw")) {
  root <- getwd()
} else if (file.exists("../data/raw")) {
  root <- normalizePath("..")
  setwd(root)
} else {
  stop("Run from project root")
}

raw <- file.path(root, "data/raw")
out_csv <- file.path(root, "docs/data_discrepancy_profile.csv")
out_md <- file.path(root, "docs/data_source_discrepancies.md")

# Year-like column names
year_rx <- "^(year|Year|Y[0-9]{4}|time|Time|assessment_year|Assessment_Year)$|^[Yy][0-9]{4}$"

guess_year_cols <- function(nm) {
  nm[grepl("^[Yy][12][0-9]{3}$", nm) | grepl("^year$|^Year$|^time$|^assessment_year$", nm, ignore.case = TRUE)]
}

# Sample scan for "<2.5" style censoring in first char cols
scan_censored <- function(df, max_cols = 8) {
  cnt <- 0L
  for (cn in names(df)[1:min(ncol(df), max_cols)]) {
    v <- df[[cn]]
    if (!is.character(v)) next
    s <- v[!is.na(v) & nzchar(v)]
    if (length(s) == 0) next
    if (any(grepl("^<|^>|^[0-9]+[–-][0-9]", head(s, 200)))) cnt <- cnt + 1L
  }
  cnt
}

profile_csv <- function(path, name, n_max = 8000, skip = 0) {
  if (!file.exists(path)) {
    return(tibble(
      source_name = name, file = path, exists = FALSE, n_rows = NA_integer_, n_cols = NA_integer_,
      geo_column = NA_character_, geo_kind = NA_character_, year_min = NA_integer_, year_max = NA_integer_,
      has_censor_like_strings = NA, notes = "file missing"
    ))
  }
  x <- tryCatch(
    read_csv(path, show_col_types = FALSE, skip = skip, n_max = n_max,
             guess_max = min(5000L, n_max)),
    error = function(e) NULL
  )
  if (is.null(x) || nrow(x) == 0) {
    return(tibble(
      source_name = name, file = path, exists = TRUE, n_rows = 0L, n_cols = if (is.null(x)) 0L else ncol(x),
      geo_column = NA_character_, geo_kind = NA_character_, year_min = NA_integer_, year_max = NA_integer_,
      has_censor_like_strings = NA, notes = "empty or parse error"
    ))
  }
  nr <- nrow(x)
  nm <- names(x)
  geo_candidates <- c(
    "country", "Country", "Area", "Entity", "Name", "GEO_NAME_SHORT", "importer_country_name",
    "Country of Asylum", "country name", "Country Name"
  )
  gc <- geo_candidates[geo_candidates %in% nm][1]
  if (is.na(gc)) {
    iso <- intersect(c("ISO3", "iso3c", "iso3", "Country (ISO3)"), nm)
    gc <- if (length(iso)) iso[1] else NA_character_
  }
  gkind <- if (!is.na(gc)) {
    if (gc %in% c("ISO3", "iso3c", "iso3", "Country (ISO3)")) "ISO3_code" else "country_name"
  } else NA_character_

  yc <- guess_year_cols(nm)
  ymin <- ymax <- NA_integer_
  if (length(yc)) {
    for (ycol in yc) {
      yv <- suppressWarnings(as.integer(as.numeric(gsub("[^0-9.]", "", as.character(x[[ycol]])))))
      yv <- yv[is.finite(yv) & yv >= 1960 & yv <= 2100]
      if (length(yv)) {
        ymin <- min(c(ymin, min(yv)), na.rm = TRUE)
        ymax <- max(c(ymax, max(yv)), na.rm = TRUE)
      }
    }
  }
  cens <- scan_censored(x)
  tibble(
    source_name = name,
    file = path,
    exists = TRUE,
    n_rows = nr,
    n_cols = ncol(x),
    geo_column = gc,
    geo_kind = gkind,
    year_min = ymin,
    year_max = ymax,
    has_censor_like_strings = cens > 0,
    notes = if (nr >= n_max) sprintf("sampled first %d rows", n_max) else NA_character_
  )
}

# --- sources aligned with app.R / build_data_collected_md.R ---
jobs <- list(
  list(name = "World Bank (WDI CSV)", path = "world_bank_data.csv"),
  list(name = "FAO fao_data.csv", path = "fao/fao_data.csv"),
  list(name = "FAO Food Security bulk", path = "fao/FAO_Data/Food_Security_Data_E_All_Data.csv"),
  list(name = "FAO FPMA", path = "fao/FAO_Data/fao fpma data.csv"),
  list(name = "IPC general", path = "ipc/ipc data general data.csv", skip = 1),
  list(name = "IPC historical 2017-2025", path = "ipc/ipc all data 2017-2025.csv"),
  list(name = "Historical outbreaks", path = "historical_hunger_outbreaks.csv"),
  list(name = "WHO stunting", path = "who/child_stunting_data.csv"),
  list(name = "OWID poverty", path = "our_world_in_data/poverty data.csv"),
  list(name = "ND-GAIN climate vulnerability", path = "climate vulnerability/cv/vulnerability/vulnerability.csv"),
  list(name = "GDL health vulnerability", path = "global_data_lab/health/health vunerability data.csv"),
  list(name = "UNHCR PoC", path = "un/unhcr/displaced people data/persons_of_concern.csv"),
  list(name = "EM-DAT", path = "em_dat/em_dat_data.csv"),
  list(name = "Food trade dependency", path = "food trade dependency/data overview.csv"),
  list(name = "OWID food supply", path = "our_world_in_data/food supply data.csv"),
  list(name = "OWID water per cap", path = "our_world_in_data/freshwater resources per capita/renewable-water-resources-per-capita.csv"),
  list(name = "USDA ag", path = "usda/agricultural_production_1.csv"),
  list(name = "WPR malnutrition", path = "wpr/malnutrition-rate-by-country-2025.csv"),
  list(name = "IDU global (HDX)", path = "hdx/idu/idu global.csv")
)

rows <- list()
for (j in jobs) {
  p <- file.path(raw, j$path)
  sk <- if (!is.null(j$skip)) j$skip else 0
  rows[[length(rows) + 1]] <- profile_csv(p, j$name, skip = sk)
}

prof <- bind_rows(rows)

dir.create(dirname(out_csv), showWarnings = FALSE, recursive = TRUE)
write_csv(prof, out_csv)

tbl_lines <- c(
  "| Source | Exists | n_rows (sample) | n_cols | geo_column | geo_kind | year_min | year_max | censor-like strings | notes |",
  "|---|---:|---:|---:|---|---|---:|---:|---|---|"
)
for (i in seq_len(nrow(prof))) {
  r <- prof[i, ]
  tbl_lines <- c(tbl_lines, sprintf(
    "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |",
    r$source_name,
    r$exists,
    ifelse(is.na(r$n_rows), "—", as.character(r$n_rows)),
    ifelse(is.na(r$n_cols), "—", as.character(r$n_cols)),
    ifelse(is.na(r$geo_column), "—", gsub("|", "\\|", r$geo_column, fixed = TRUE)),
    ifelse(is.na(r$geo_kind), "—", r$geo_kind),
    ifelse(is.na(r$year_min), "—", as.character(r$year_min)),
    ifelse(is.na(r$year_max), "—", as.character(r$year_max)),
    ifelse(is.na(r$has_censor_like_strings), "—", as.character(r$has_censor_like_strings)),
    ifelse(is.na(r$notes), "—", r$notes)
  ))
}

lines <- c(
  "# Data source discrepancies and harmonization notes",
  "",
  paste("**Generated:**", format(Sys.time(), "%Y-%m-%d %H:%M")),
  "",
  "This report summarizes **structural** differences across raw files (geography key, time coverage, sampling) and **semantic** differences between indicators that sound similar but are **not** interchangeable.",
  "",
  "---",
  "",
  "## 1. Automated file profile",
  "",
  tbl_lines,
  "",
  "---",
  "",
  "## 2. Geographic identifier mismatches",
  "",
  "- **Country names vs ISO3:** IPC files often store **ISO3 codes** in a column named `Country`, while FAO/WB/OWID use **full area names**. The profile may say `geo_kind = country_name` from the column name alone — inspect **values**. The app uses `country_name_mapping.csv` and `standardize_country_names()`; **residual join failures** remain for contested territories and variants.",
  "- **UNHCR:** `Country of Asylum` is the unit of aggregation (host state), not always the hunger-affected population's origin — interpret displacement metrics accordingly.",
  "- **EM-DAT / IDU:** Event- or crisis-level rows may duplicate country-year appearances when aggregated.",
  "",
  "## 3. Conceptual / definitional discrepancies (same word, different meaning)",
  "",
  "| Topic | Sources in this project | Discrepancy |",
  "|--------|-------------------------|-------------|",
  "| **Undernourishment / hunger** | FAO PoU (%); WFP GRFC IPC phase; WHO stunting | **PoU** = national calorie inadequacy prevalence; **IPC** = phase classification in analysed areas (not always national); **stunting** = chronic malnutrition in children under five — different populations and scales. |",
  "| **Poverty** | World Bank `SI.POV.DDAY`; OWID poverty series | WB uses **international poverty lines** (e.g. $2.15 2017 PPP); OWID may use **multiple definitions** — compare variable notes before merging. |",
  "| **Climate vulnerability** | ND-GAIN-style CSVs (0–1 index); sub-indices | Indices are **ordinal composites** — not comparable in levels to PoU or IPC without harmonization. |",
  "| **Conflict** | ACLED fatalities | Fatality counts **≠** conflict risk index; annual sums mask seasonality. |",
  "| **Displacement** | UNHCR PoC; IDU | Different **definitions** (refugees vs IDPs); **host** vs **origin** in UNHCR tables. |",
  "| **Food trade** | Trade dependency extract | Units depend on source — not always comparable to FAO balances. |",
  "",
  "## 4. Statistical / coding issues visible in raw extracts",
  "",
  "- **Censored FAO values:** Prevalence often reported as `\"<2.5\"` — parsed in code as a numeric floor where needed; statistically this is **interval-censored**.",
  "- **Mixed types:** Some CSVs mix text and numbers — causes `readr` **parse warnings** during app load.",
  "- **Year alignment:** Merged \"latest\" profiles combine indicators from **different reference years** — not a single survey wave.",
  "",
  "## 5. Suggested next steps",
  "",
  "1. Maintain a **data dictionary** (one row per variable): source, unit, reference period, intended use in the score.",
  "2. Prefer **ISO3** as internal join key with a reviewed crosswalk.",
  "3. For updates, use **APIs or scheduled bulk downloads** — see `docs/dynamic_data_apis.md` — and version snapshots (e.g. `data/raw/YYYYMMDD/`).",
  "",
  "Machine-readable: `docs/data_discrepancy_profile.csv`",
  ""
)

writeLines(lines, out_md)
message("Wrote ", out_csv, " and ", out_md)
