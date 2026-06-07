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

missing <- pkgs[!vapply(pkgs, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}
