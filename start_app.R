# Quick start script for the Shiny app
# Run this with: Rscript start_app.R

cat("========================================\n")
cat("Starting Global Hunger Research App\n")
cat("========================================\n\n")

# Check for required packages
required_packages <- c("shiny", "shinydashboard", "plotly", "DT", "tidyverse", 
                       "WDI", "here", "lubridate", "RColorBrewer", "readxl")

cat("Checking required packages...\n")
missing_packages <- c()
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
    cat("  ❌ Missing:", pkg, "\n")
  } else {
    cat("  ✅ Found:", pkg, "\n")
  }
}

if (length(missing_packages) > 0) {
  cat("\n❌ ERROR: Missing required packages!\n")
  cat("Please install them with:\n")
  cat("install.packages(c(", paste0('"', missing_packages, '"', collapse = ", "), "))\n")
  stop("Missing packages")
}

cat("\n✅ All packages found!\n\n")

# Set flag to prevent app.R from running shinyApp immediately
SKIP_SHINY_APP <- TRUE

# Try to load the app
cat("Loading app.R...\n")
tryCatch({
  source("app.R", local = TRUE)
  cat("✅ app.R loaded successfully!\n\n")
}, error = function(e) {
  cat("❌ ERROR loading app.R:\n")
  cat(e$message, "\n")
  stop(e)
})

# Check if we can access the components
if (exists("header") && exists("sidebar") && exists("body") && exists("server")) {
  # Start the server
  cat("Starting Shiny server on http://127.0.0.1:3838...\n")
  cat("Press Ctrl+C to stop the server\n\n")
  
  ui <- dashboardPage(
    header = header,
    sidebar = sidebar,
    body = body
  )
  
  shinyApp(ui = ui, server = server)
} else {
  cat("❌ ERROR: Could not find required components (header, sidebar, body, server)\n")
  cat("Available objects:\n")
  print(ls())
  stop("Missing required components")
}

