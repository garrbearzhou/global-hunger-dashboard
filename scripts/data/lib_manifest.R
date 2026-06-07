# Shared helpers for data fetch manifests (sourced by fetch_*.R)

write_manifest <- function(files, urls, dest_dir) {
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  artifacts <- list()
  for (i in seq_along(files)) {
    fp <- files[[i]]
    fi <- if (file.exists(fp)) file.info(fp)[1, , drop = FALSE] else NULL
    artifacts[[i]] <- list(
      path = normalizePath(fp, mustWork = FALSE),
      url = if (length(urls) >= i && !is.na(urls[[i]])) as.character(urls[[i]]) else NA_character_,
      size_bytes = if (!is.null(fi)) unname(fi$size) else NA_real_,
      mtime_utc = if (!is.null(fi)) format(fi$mtime, tz = "UTC", usetz = TRUE) else NA_character_
    )
    if (requireNamespace("digest", quietly = TRUE) && file.exists(fp)) {
      artifacts[[i]]$file_sha256 <- digest::digest(file = fp, algo = "sha256", serialize = FALSE)
    }
  }
  out <- list(
    downloaded_at_utc = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"),
    artifacts = artifacts
  )
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    jsonlite::write_json(out, file.path(dest_dir, "manifest.json"), pretty = TRUE, auto_unbox = TRUE)
  } else {
    writeLines(capture.output(str(out)), file.path(dest_dir, "manifest.txt"))
    warning("Install jsonlite for manifest.json output.")
  }
  invisible(out)
}
