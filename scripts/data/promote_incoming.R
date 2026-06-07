#!/usr/bin/env Rscript
# After validation: archive current data/raw key files, then promote incoming/YYYYMMDD/* into data/raw/.
# Usage: Rscript scripts/data/promote_incoming.R YYYYMMDD [--no-archive]

args <- commandArgs(trailingOnly = TRUE)
root <- if (file.exists("app.R")) getwd() else normalizePath("..")
setwd(root)

if (length(args) < 1) stop("Usage: Rscript scripts/data/promote_incoming.R YYYYMMDD [--no-archive]")
date_tag <- args[1]
no_archive <- "--no-archive" %in% args

src_dir <- file.path("data/raw/incoming", date_tag)
if (!dir.exists(src_dir)) stop("Missing: ", src_dir)

flist <- list.files(src_dir, pattern = "\\.(csv|xlsx|xls)$", ignore.case = TRUE, full.names = FALSE)
if (length(flist) == 0) stop("No csv/xlsx in ", src_dir)

archive_dir <- file.path("data/raw/archive", date_tag)
if (!no_archive) {
  dir.create(archive_dir, showWarnings = FALSE, recursive = TRUE)
  # Archive top-level csv in data/raw that would be overwritten (conservative: world_bank only by default)
  candidates <- c("world_bank_data.csv")
  for (c in candidates) {
    fp <- file.path("data/raw", c)
    if (file.exists(fp)) {
      file.copy(fp, file.path(archive_dir, c), overwrite = TRUE)
      message("Archived: ", c, " -> ", archive_dir)
    }
  }
}

for (f in flist) {
  from <- file.path(src_dir, f)
  # promote world bank to root of data/raw; others keep subdirs by name prefix — user can adjust
  if (grepl("^world_bank", f, ignore.case = TRUE)) {
    to <- file.path("data/raw", "world_bank_data.csv")
  } else {
    to <- file.path("data/raw/incoming", date_tag, "_promoted", f)
    dir.create(dirname(to), showWarnings = FALSE, recursive = TRUE)
  }
  file.copy(from, to, overwrite = TRUE)
  message("Promoted: ", from, " -> ", to)
}

dir.create("data/metadata", showWarnings = FALSE, recursive = TRUE)
writeLines(
  c(
    paste("promoted_from=", src_dir),
    paste("promoted_at_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
    paste("files=", paste(flist, collapse = ","))
  ),
  "data/metadata/last_promotion.txt"
)
message("Wrote data/metadata/last_promotion.txt")
