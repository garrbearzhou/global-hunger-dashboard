#!/usr/bin/env Rscript
# Build ISO3-centric crosswalk: canonical country name (standardized) ↔ iso3c from World Bank panel.
# Run from project root: Rscript scripts/build_crosswalk_iso3.R

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

root <- if (file.exists("data/raw/world_bank_data.csv")) getwd() else if (file.exists("../data/raw/world_bank_data.csv")) normalizePath("..") else stop("Run from project root")
setwd(root)

wb <- read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE)
if (!all(c("country", "iso3c") %in% names(wb))) stop("world_bank_data.csv needs country, iso3c")

cw <- wb %>%
  filter(!is.na(iso3c), !is.na(country), iso3c != "") %>%
  distinct(country, iso3c, .keep_all = FALSE) %>%
  mutate(
    country = trimws(as.character(country)),
    iso3c = trimws(as.character(iso3c))
  ) %>%
  arrange(iso3c, country)

dir.create("data/metadata", showWarnings = FALSE, recursive = TRUE)
write_csv(cw, "data/metadata/crosswalk_country_iso3.csv")
message("Wrote data/metadata/crosswalk_country_iso3.csv (", nrow(cw), " rows)")
