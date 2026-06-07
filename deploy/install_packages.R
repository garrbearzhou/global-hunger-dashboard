pkgs <- c(
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

repos <- "https://cloud.r-project.org"

for (pkg in pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installing ", pkg, "...")
    install.packages(pkg, repos = repos, dependencies = TRUE, Ncpus = 2L)
  }
}

still_missing <- pkgs[!vapply(pkgs, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(still_missing) > 0) {
  stop(
    "Failed to install required packages: ",
    paste(still_missing, collapse = ", "),
    call. = FALSE
  )
}

# Verify leaflet loads (pulls in sf/sp stack used by the map)
suppressPackageStartupMessages(library(leaflet))
message("All required packages installed successfully.")
