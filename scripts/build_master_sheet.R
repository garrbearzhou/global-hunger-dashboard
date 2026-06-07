#!/usr/bin/env Rscript
# Build Master_Sheet: one row per country (WB backbone), 8 variables for 2022, complete cases only, plus ln_gdp and ln_water.
# Run from project root: Rscript scripts/build_master_sheet.R

library(readr)
library(dplyr)
library(tidyr)

# Run from project root
if (!dir.exists("data/raw")) stop("Run from project root: Rscript scripts/build_master_sheet.R")
raw <- "data/raw"

# Fuzzy match country names to backbone (WB spelling)
match_country_to_backbone <- function(names_vec, backbone, max_dist = 4L) {
  backbone <- unique(trimws(as.character(backbone)))
  backbone <- backbone[!is.na(backbone) & nzchar(backbone)]
  out <- trimws(as.character(names_vec))
  lb <- tolower(backbone)
  for (i in seq_along(out)) {
    if (is.na(out[i]) || out[i] %in% backbone) next
    d <- adist(tolower(out[i]), lb, partial = FALSE)
    min_d <- min(d, na.rm = TRUE)
    if (length(min_d) && is.finite(min_d) && min_d <= max_dist)
      out[i] <- backbone[which.min(d)[1]]
  }
  out
}

# ---- 1. Backbone: World Bank countries (exclude regions/aggregates) ----
# Some WB rows have inconsistent column counts; read with character types to avoid guess warnings
wb <- suppressWarnings(read_csv(file.path(raw, "world_bank_data.csv"), show_col_types = FALSE, col_types = cols(.default = col_character())))
wb <- wb %>% mutate(year = suppressWarnings(as.integer(as.numeric(year))))
if ("country" %in% names(wb)) {
  wb <- wb %>% filter(is.na(country) | !grepl("^[A-Za-z]+[0-9.]+$", trimws(as.character(country))))
}
drop <- c("World", "Total", "Africa", "Americas", "Europe", "Asia", "Oceania",
  "Africa Eastern and Southern", "Africa Western and Central", "Arab World",
  "East Asia and Pacific", "Europe and Central Asia", "Latin America and Caribbean",
  "Middle East and North Africa", "South Asia", "Sub-Saharan Africa", "European Union",
  "IDA & IBRD", "Low & middle income", "Middle income", "High income", "IBRD only", "IDA only", "IDA total",
  "Early-demographic", "Late-demographic", "OECD members", "Fragile and conflict affected",
  "Pre-demographic dividend", "Post-demographic dividend", "Small states", "Other small states",
  "Pacific island small states", "Caribbean small states", "East Asia & Pacific", "Europe & Central Asia",
  "Latin America & Caribbean", "North America", "Sub-Saharan Africa (IDA & IBRD)",
  "East Asia & Pacific (IDA & IBRD)", "South Asia (IDA & IBRD)", "Euro area",
  "Central Europe and the Baltics", "Channel Islands", "Kosovo", "Not classified", "St. Martin (French part)")
backbone <- wb %>%
  filter(!is.na(iso3c), country %in% setdiff(unique(wb$country), drop)) %>%
  pull(country) %>%
  unique() %>%
  sort()

master <- tibble(country = backbone)

# ---- 2. FAO: Undernourishment (prefer official FAOSTAT; fao_data.csv is "Realistic Simulation" and has wrong values) ----
fao_faostat_path <- file.path(raw, "fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv")
fao_legacy_path <- file.path(raw, "fao/fao_data.csv")
fao <- NULL
if (file.exists(fao_faostat_path)) {
  faostat <- read_csv(fao_faostat_path, show_col_types = FALSE, col_types = cols(.default = col_character()))
  # Item Code 210041 = Prevalence of undernourishment (percent) (3-year average), 2022-2024
  faostat <- faostat %>%
    filter(`Item Code` == "210041", trimws(Value) != "") %>%
    mutate(
      country = match_country_to_backbone(Area, backbone),
      undernourishment = case_when(
        trimws(Value) == "<2.5" ~ 2.5,
        TRUE ~ suppressWarnings(as.numeric(Value))
      )
    ) %>%
    filter(!is.na(country), !is.na(undernourishment)) %>%
    select(country, undernourishment) %>%
    group_by(country) %>% slice(1) %>% ungroup()
  if (nrow(faostat) > 0) fao <- faostat
}
if (is.null(fao) && file.exists(fao_legacy_path)) {
  fao_legacy <- read_csv(fao_legacy_path, show_col_types = FALSE, col_types = cols(.default = col_character()))
  fao <- fao_legacy %>%
    mutate(year = as.integer(as.numeric(year))) %>%
    filter(year == 2022L, indicator == "Prevalence of Undernourishment (%)") %>%
    transmute(country = match_country_to_backbone(country, backbone), undernourishment = as.numeric(value)) %>%
    group_by(country) %>% slice(1) %>% ungroup() %>%
    mutate(undernourishment = if_else(country == "Japan" & undernourishment > 5, 2.5, undernourishment))
}
if (!is.null(fao)) {
  master <- master %>% left_join(fao, by = "country")
} else {
  master$undernourishment <- NA_real_
}

# ---- 3. Climate vulnerability: score 2022 ----
cv_path <- file.path(raw, "climate vulnerability/cv/vulnerability/vulnerability.csv")
if (file.exists(cv_path)) {
  cv <- read_csv(cv_path, show_col_types = FALSE, col_types = cols(.default = col_character()))
  ycol <- "2022"
  if (!ycol %in% names(cv)) ycol <- names(cv)[ncol(cv)]
  cv <- cv %>%
    rename(cc = all_of(ycol)) %>%
    mutate(country = match_country_to_backbone(Name, backbone), climate_vulnerability = as.numeric(cc)) %>%
    filter(!is.na(country), !is.na(climate_vulnerability)) %>%
    select(country, climate_vulnerability) %>%
    group_by(country) %>% slice(1) %>% ungroup()
  master <- master %>% left_join(cv, by = "country")
} else {
  master$climate_vulnerability <- NA_real_
}

# ---- 4. World Bank: GDP per capita, rural %, agricultural land % (2022 or latest available) ----
# Use latest year per country so countries without 2022 (e.g. Bangladesh) still get WB data
wb_latest <- wb %>%
  filter(country %in% backbone, !is.na(year)) %>%
  group_by(country) %>%
  slice_max(n = 1, order_by = year, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    country = country,
    gdp_per_capita = as.numeric(`gdp_GDP.PCAP.CD`),
    rural_pct = as.numeric(`pop_RUR.TOTL.ZS`),
    ag_land_pct = as.numeric(`agriculture_LND.AGRI.ZS`)
  )
master <- master %>%
  left_join(select(wb_latest, country, gdp_per_capita, rural_pct, ag_land_pct), by = "country")

# ---- 5. EM-DAT: Disaster count (2013–2022 total per country) ----
em_path <- file.path(raw, "em_dat/em_dat_data.csv")
if (file.exists(em_path)) {
  em <- read_csv(em_path, show_col_types = FALSE, col_types = cols(.default = col_character()))
  em <- em %>%
    mutate(year = as.integer(as.numeric(year))) %>%
    filter(indicator == "Number of Disasters", between(year, 2013L, 2022L)) %>%
    group_by(country) %>%
    summarise(disaster_count = sum(as.numeric(value), na.rm = TRUE), .groups = "drop") %>%
    mutate(country = match_country_to_backbone(country, backbone)) %>%
    group_by(country) %>% summarise(disaster_count = sum(disaster_count), .groups = "drop")
  master <- master %>% left_join(em, by = "country")
} else {
  master$disaster_count <- NA_real_
}

# ---- 6. OWID: Water per capita (2022 or latest; file has up to 2021) ----
water_path <- file.path(raw, "our_world_in_data/freshwater resources per capita/renewable-water-resources-per-capita.csv")
if (file.exists(water_path)) {
  water <- read_csv(water_path, show_col_types = FALSE, col_types = cols(.default = col_character()))
  nm <- names(water)
  val_col <- nm[ncol(water)]
  yr_col <- "Year"
  if (!"Year" %in% nm) yr_col <- nm[3]
  water <- water %>%
    mutate(..yr = as.integer(as.numeric(!!sym(yr_col)))) %>%
    filter(..yr %in% c(2022L, 2021L)) %>%
    group_by(Entity) %>%
    slice_max(n = 1, order_by = ..yr, with_ties = FALSE) %>%
    ungroup() %>%
    select(-..yr) %>%
    transmute(country = match_country_to_backbone(Entity, backbone), water_per_capita = as.numeric(!!sym(val_col))) %>%
    filter(!is.na(country), !is.na(water_per_capita)) %>%
    group_by(country) %>% slice(1) %>% ungroup()
  master <- master %>% left_join(water, by = "country")
} else {
  master$water_per_capita <- NA_real_
}

# ---- 7. OWID: kcal/capita/day 2022 ----
food_path <- file.path(raw, "our_world_in_data/food supply data.csv")
if (file.exists(food_path)) {
  food <- read_csv(food_path, show_col_types = FALSE, col_types = cols(.default = col_character()))
  nm <- names(food)
  val_col <- nm[ncol(food)]
  food <- food %>%
    filter(as.integer(as.numeric(Year)) == 2022L) %>%
    transmute(country = match_country_to_backbone(Entity, backbone), kcal_per_capita = as.numeric(!!sym(val_col))) %>%
    filter(!is.na(country), !is.na(kcal_per_capita)) %>%
    group_by(country) %>% slice(1) %>% ungroup()
  master <- master %>% left_join(food, by = "country")
} else {
  master$kcal_per_capita <- NA_real_
}

# ---- 8. Keep only complete cases across the 8 variables ----
vars <- c("undernourishment", "climate_vulnerability", "gdp_per_capita", "rural_pct", "ag_land_pct", "disaster_count", "water_per_capita", "kcal_per_capita")
for (v in vars) if (!v %in% names(master)) master[[v]] <- NA_real_
master <- master %>%
  filter(complete.cases(pick(all_of(vars))))

# ---- 9. Add transformed columns ----
master <- master %>%
  mutate(
    ln_gdp = log(gdp_per_capita),
    ln_water = log(water_per_capita)
  )

# Column order: country, 8 vars, ln_gdp, ln_water
master <- master %>% select(country, all_of(vars), ln_gdp, ln_water)

# ---- 10. Write CSV and XLSX ----
write_csv(master, "Master_Sheet.csv")
message("Wrote Master_Sheet.csv with ", nrow(master), " complete-case countries.")

if (requireNamespace("writexl", quietly = TRUE)) {
  writexl::write_xlsx(master, "Master_Sheet.xlsx")
  message("Wrote Master_Sheet.xlsx")
} else {
  message("Install writexl for Excel output: install.packages('writexl')")
}
