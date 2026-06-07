#!/usr/bin/env Rscript
# Validate key raw files: row counts, required columns, NA spikes vs optional baseline.
# Exit code 1 on failure. Usage: Rscript scripts/validate_raw_snapshot.R [baseline_csv]

suppressPackageStartupMessages({
  library(readr)
})

root <- if (file.exists("data/raw")) getwd() else if (file.exists("../data/raw")) normalizePath("..") else stop("Run from project root")
setwd(root)

args <- commandArgs(trailingOnly = TRUE)
baseline_path <- if (length(args) >= 1) args[1] else "data/metadata/validation_baseline.csv"

checks <- list()
fail <- FALSE

wb_path <- "data/raw/world_bank_data.csv"
if (!file.exists(wb_path)) {
  message("FAIL: missing ", wb_path)
  quit(status = 1)
}
wb <- read_csv(wb_path, show_col_types = FALSE, n_max = 500000)
need_cols <- c("country", "iso3c", "year")
miss <- setdiff(need_cols, names(wb))
if (length(miss)) {
  message("FAIL: world_bank_data.csv missing columns: ", paste(miss, collapse = ", "))
  fail <- TRUE
}
n_wb <- nrow(wb)
n_countries <- length(unique(stats::na.omit(wb$country)))
checks$world_bank_rows <- n_wb
checks$world_bank_countries <- n_countries

if (n_wb < 1000L) {
  message("WARN: world_bank_data.csv row count unexpectedly low: ", n_wb)
}

# NA spike: poverty column (either name)
pov_col <- if ("SI.POV.DDAY" %in% names(wb)) "SI.POV.DDAY" else if ("poverty_POV.DDAY" %in% names(wb)) "poverty_POV.DDAY" else NA_character_
if (!is.na(pov_col)) {
  na_rate <- mean(is.na(wb[[pov_col]]))
  checks$poverty_na_rate <- na_rate
  if (na_rate > 0.95) {
    message("WARN: poverty column NA rate > 95%: ", round(100 * na_rate, 1), "%")
  }
}

# Compare to baseline if exists
if (file.exists(baseline_path)) {
  base <- read_csv(baseline_path, show_col_types = FALSE)
  if ("world_bank_rows" %in% names(base) && nrow(base) > 0) {
    br <- base$world_bank_rows[1]
    if (!is.na(br) && n_wb < 0.5 * br) {
      message("FAIL: row count dropped >50% vs baseline (", n_wb, " vs ", br, ")")
      fail <- TRUE
    }
  }
} else {
  # Write current stats as baseline template
  dir.create(dirname(baseline_path), showWarnings = FALSE, recursive = TRUE)
  write_csv(
    data.frame(
      world_bank_rows = n_wb,
      world_bank_countries = n_countries,
      recorded_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      stringsAsFactors = FALSE
    ),
    baseline_path
  )
  message("Wrote baseline: ", baseline_path)
}

# FAO file presence
fao_ok <- file.exists("data/raw/fao/fao_data.csv") || file.exists("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data.csv")
if (!fao_ok) message("WARN: No FAO fao_data.csv or Food_Security bulk found.")

out <- data.frame(
  check = names(unlist(checks)),
  value = as.character(unlist(checks)),
  stringsAsFactors = FALSE
)
write_csv(out, "data/metadata/last_validation_summary.csv")
message("OK: validation summary -> data/metadata/last_validation_summary.csv")
if (fail) quit(status = 1)
