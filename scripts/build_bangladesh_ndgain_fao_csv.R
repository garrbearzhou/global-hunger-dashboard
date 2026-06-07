#!/usr/bin/env Rscript
# Build Bangladesh_NDGAIN_FAO_timeseries.csv: multi-year ND-GAIN vulnerability + FAO undernourishment for Bangladesh.
# Run from project root: Rscript scripts/build_bangladesh_ndgain_fao_csv.R

library(readr)
library(dplyr)
library(tidyr)

raw <- "data/raw"

# ---- 1. ND-GAIN vulnerability (climate vulnerability/cv/vulnerability/vulnerability.csv) ----
v_path <- file.path(raw, "climate vulnerability/cv/vulnerability/vulnerability.csv")
ndgain <- NULL
if (file.exists(v_path)) {
  v <- read_csv(v_path, show_col_types = FALSE, col_types = cols(.default = col_character()))
  bdg <- v %>% filter(ISO3 == "BGD" | Name == "Bangladesh")
  if (nrow(bdg) > 0) {
    year_cols <- setdiff(names(bdg), c("ISO3", "Name"))
    year_cols <- year_cols[grepl("^[0-9]{4}$", year_cols)]
    ndgain <- bdg %>%
      select(all_of(year_cols)) %>%
      pivot_longer(everything(), names_to = "year", values_to = "ndgain_vulnerability") %>%
      mutate(year = as.integer(year), ndgain_vulnerability = as.numeric(ndgain_vulnerability)) %>%
      filter(!is.na(ndgain_vulnerability))
  }
}

# ---- 2. FAO undernourishment across years ----
# Use fao_data.csv (has year-by-year) and Food_Security 3-year average for longer series
fao_ts <- NULL

# 2a. fao_data.csv: single-year Prevalence of Undernourishment for Bangladesh
fao_path <- file.path(raw, "fao/fao_data.csv")
if (file.exists(fao_path)) {
  fao1 <- read_csv(fao_path, show_col_types = FALSE, col_types = cols(.default = col_character()))
  fao1 <- fao1 %>%
    filter(country == "Bangladesh", indicator == "Prevalence of Undernourishment (%)") %>%
    transmute(year = as.integer(year), fao_undernourishment_pct = as.numeric(value))
  if (nrow(fao1) > 0) fao_ts <- fao1
}

# 2b. If we want longer series: Food_Security_Data 210041 (3-year avg) - use end year of period
fs_path <- file.path(raw, "fao/FAO_Data/Food_Security_Data_E_All_Data.csv")
if (file.exists(fs_path) && (is.null(fao_ts) || nrow(fao_ts) < 10)) {
  fs <- read_csv(fs_path, show_col_types = FALSE, col_types = cols(.default = col_character()))
  bd_fs <- fs %>% filter(Area == "Bangladesh", `Item Code` == "210041")
  if (nrow(bd_fs) > 0) {
    # Columns like Y2000, Y20002002, Y2001, ...; take every 3rd col from 9 (first value col)
    nm <- names(bd_fs)
    idx <- which(grepl("^Y[0-9]", nm) & !grepl("F$|N$", nm))
    val_cols <- nm[idx]
    fao_fs <- bd_fs %>%
      select(all_of(val_cols)) %>%
      pivot_longer(everything(), names_to = "period", values_to = "fao_undernourishment_pct") %>%
      mutate(
        fao_undernourishment_pct = suppressWarnings(as.numeric(fao_undernourishment_pct)),
        year = case_when(
          nchar(period) == 5L ~ as.integer(substr(period, 2, 5)),
          nchar(period) >= 9L ~ as.integer(substr(period, 6, 9))
        )
      ) %>%
      filter(!is.na(fao_undernourishment_pct), !is.na(year)) %>%
      select(year, fao_undernourishment_pct) %>%
      distinct(year, .keep_all = TRUE)
    if (nrow(fao_fs) > 0) fao_ts <- fao_fs
  }
}

# ---- 3. Combine by year ----
years <- unique(c(ndgain$year, fao_ts$year))
years <- sort(years[!is.na(years)])
out <- tibble(year = years)
if (!is.null(ndgain)) {
  out <- out %>% left_join(ndgain, by = "year")
} else {
  out$ndgain_vulnerability <- NA_real_
}
if (!is.null(fao_ts)) {
  out <- out %>% left_join(fao_ts, by = "year")
} else {
  out$fao_undernourishment_pct <- NA_real_
}
out <- out %>% arrange(year)

write_csv(out, "Bangladesh_NDGAIN_FAO_timeseries.csv")
message("Wrote Bangladesh_NDGAIN_FAO_timeseries.csv with ", nrow(out), " years (", sum(!is.na(out$ndgain_vulnerability)), " ND-GAIN, ", sum(!is.na(out$fao_undernourishment_pct)), " FAO).")
