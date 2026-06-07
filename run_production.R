#!/usr/bin/env Rscript

Sys.setenv(OMP_NUM_THREADS = Sys.getenv("OMP_NUM_THREADS", "1"))
.GlobalEnv$SKIP_SHINY_APP <- TRUE

cat("Loading app for production...\n")
source("app.R", local = .GlobalEnv)

if (!exists("ui", envir = .GlobalEnv) || !exists("server", envir = .GlobalEnv)) {
  stop("ui/server not found after loading app.R")
}

port <- as.integer(Sys.getenv("PORT", "3838"))
host <- Sys.getenv("HOST", "0.0.0.0")

cat("Starting Shiny on", paste0(host, ":", port), "\n")
shiny::shinyApp(
  ui = .GlobalEnv$ui,
  server = .GlobalEnv$server,
  options = list(port = port, host = host)
)
