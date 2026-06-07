#!/usr/bin/env Rscript
# Fetch World Bank WDI indicators into data/raw/incoming/YYYYMMDD/world_bank_data.csv
# Requires: WDI package — install.packages("WDI")
# Usage: Rscript scripts/data/fetch_world_bank_wdi.R [YYYYMMDD]

args <- commandArgs(trailingOnly = TRUE)
root <- if (file.exists("app.R")) getwd() else if (file.exists("../app.R")) normalizePath("..") else stop("Run from project root")
setwd(root)

date_tag <- if (length(args) >= 1) args[1] else format(Sys.Date(), "%Y%m%d")
incoming <- file.path("data/raw/incoming", date_tag)
dir.create(incoming, showWarnings = FALSE, recursive = TRUE)

if (!requireNamespace("WDI", quietly = TRUE)) {
  stop("Install WDI: install.packages('WDI')")
}

# Match indicators used in load_hunger_data() when collecting via API
indicators <- c(
  "SP.POP.TOTL", "NY.GDP.MKTP.CD", "NY.GDP.PCAP.CD", "FP.CPI.TOTL.ZG", "SI.POV.DDAY",
  "AG.LND.AGRI.ZS", "AG.PRD.CROP.XD", "SP.RUR.TOTL.ZS", "SP.URB.TOTL.IN.ZS",
  "SE.ADT.LITR.ZS", "SP.DYN.LE00.IN", "SP.DYN.IMRT.IN", "AG.CON.FERT.ZS",
  "AG.LND.ARBL.ZS", "SP.POP.GROW", "NY.GDP.MKTP.KD.ZG"
)

message("Fetching WDI (all countries, 2000–", format(Sys.Date(), "%Y"), ") ...")
wb <- WDI::WDI(country = "all", indicator = indicators, start = 2000, end = as.integer(format(Sys.Date(), "%Y")), extra = TRUE)

out_file <- file.path(incoming, "world_bank_data.csv")
readr::write_csv(wb, out_file)
message("Wrote ", out_file, " (", nrow(wb), " rows)")

source("scripts/data/lib_manifest.R", local = TRUE)
write_manifest(
  list(out_file),
  list("WDI::WDI(country='all', indicators=..., extra=TRUE)"),
  incoming
)
