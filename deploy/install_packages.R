# Use prebuilt Linux binaries (avoids compiling sf/units/s2/leaflet from source).
repos <- Sys.getenv(
  "RSPM",
  "https://packagemanager.posit.co/cran/__linux__/noble/latest"
)
options(repos = c(CRAN = repos))

required <- c(
  "shiny",
  "shinydashboard",
  "plotly",
  "leaflet",
  "DT",
  "tidyverse",
  "WDI",
  "here",
  "lubridate",
  "RColorBrewer",
  "readxl"
)

missing <- required[!vapply(required, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing) > 0) {
  message("Installing from binary repo: ", paste(missing, collapse = ", "))
  install.packages(missing, dependencies = TRUE, Ncpus = 2L)
}

still_missing <- required[!vapply(required, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(still_missing) > 0) {
  stop(
    "Failed to install required packages: ",
    paste(still_missing, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages(library(leaflet))
message("All required packages installed successfully.")
