# Quick check to see if the website is running
library(httr)

# Check if the website is accessible
tryCatch({
  response <- GET("http://localhost:3838", timeout(5))
  if(response$status_code == 200) {
    cat("✅ Website is running successfully!\n")
    cat("🌍 Open your browser and go to: http://localhost:3838\n")
    cat("📊 Your Global Hunger Research Dashboard is ready!\n")
  } else {
    cat("⚠️  Website responded with status code:", response$status_code, "\n")
  }
}, error = function(e) {
  cat("❌ Website is not accessible. Error:", e$message, "\n")
  cat("💡 Make sure you've run: Rscript run_website.R\n")
})
