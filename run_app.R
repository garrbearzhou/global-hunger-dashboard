#!/usr/bin/env Rscript
# Simple script to run the Shiny app
# Usage: Rscript run_app.R

cat("========================================\n")
cat("Global Hunger Research App\n")
cat("========================================\n\n")

# Load required library
if (!require("shiny", quietly = TRUE)) {
  stop("Please install the 'shiny' package: install.packages('shiny')")
}

# Set flag to prevent app.R from auto-running
# Use .GlobalEnv explicitly
.GlobalEnv$SKIP_SHINY_APP <- TRUE

cat("Loading app.R...\n")
# Source the app file in global environment so ui and server are accessible
tryCatch({
  source("app.R", local = .GlobalEnv)
  cat("✅ App loaded successfully!\n\n")
}, error = function(e) {
  cat("❌ Error loading app:\n")
  print(e)
  stop(e)
})

# Verify ui and server exist
if (!exists("ui", envir = .GlobalEnv)) {
  cat("ERROR: 'ui' object not found. Available objects:\n")
  print(ls(envir = .GlobalEnv))
  stop("ERROR: 'ui' object not found after loading app.R")
}
if (!exists("server", envir = .GlobalEnv)) {
  stop("ERROR: 'server' object not found after loading app.R")
}

# Function to find and kill process on a port
kill_port <- function(port) {
  if (.Platform$OS.type == "unix") {
    # Try to find process using the port
    cmd <- paste0("lsof -ti:", port)
    pid <- tryCatch({
      system(cmd, intern = TRUE)[1]
    }, error = function(e) NULL)
    
    if (!is.null(pid) && pid != "") {
      cat("Found process", pid, "using port", port, "- attempting to kill it...\n")
      system(paste0("kill -9 ", pid), ignore.stdout = TRUE, ignore.stderr = TRUE)
      Sys.sleep(2)  # Wait a moment for port to be released
      return(TRUE)
    }
  }
  return(FALSE)
}

# Check if port is in use and try to free it
port <- 3838
cat("Checking port", port, "...\n")
if (.Platform$OS.type == "unix") {
  cmd <- paste0("lsof -ti:", port, " > /dev/null 2>&1")
  port_in_use <- system(cmd) == 0
  
  if (port_in_use) {
    cat("⚠️  Port", port, "is already in use.\n")
    cat("Attempting to free the port...\n")
    kill_port(port)
    
    # Check again
    port_in_use <- system(cmd) == 0
    if (port_in_use) {
      cat("⚠️  Could not free port", port, "\n")
      cat("Trying alternative port 3839...\n")
      port <- 3839
    } else {
      cat("✅ Port", port, "is now available.\n")
    }
  }
}

cat("\nStarting Shiny server...\n")
cat("The app will be available at: http://127.0.0.1:", port, "\n", sep = "")
cat("Press Ctrl+C to stop\n\n")

# Now run the app
cat("Launching Shiny application...\n")
shinyApp(ui = .GlobalEnv$ui, server = .GlobalEnv$server, options = list(port = port, host = "127.0.0.1"))

