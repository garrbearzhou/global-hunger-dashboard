#!/usr/bin/env Rscript
# Template: copy a pinned URL or document manual download steps into incoming/YYYYMMDD/.
# Replace MY_URL and paths for FAO bulk, OWID GitHub raw, etc.

args <- commandArgs(trailingOnly = TRUE)
root <- if (file.exists("app.R")) getwd() else normalizePath("..")
setwd(root)
date_tag <- if (length(args) >= 1) args[1] else format(Sys.Date(), "%Y%m%d")
incoming <- file.path("data/raw/incoming", date_tag)
dir.create(incoming, showWarnings = FALSE, recursive = TRUE)

readme <- c(
  "# Manual or scripted fetch",
  "",
  "Add provider-specific download logic here, or:",
  "- Use FAOSTAT R package get_faostat_bulk_api()",
  "- Use curl::curl_download(url, destfile)",
  "- Pin OWID GitHub raw URLs",
  "",
  paste("Incoming folder:", incoming),
  paste("Created:", Sys.time())
)
writeLines(readme, file.path(incoming, "README_fetch_placeholder.txt"))
message("Wrote placeholder: ", file.path(incoming, "README_fetch_placeholder.txt"))
