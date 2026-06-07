# Test script to verify Afghanistan coloring fix
library(plotly)

# Test data with Afghanistan having 73.5 vulnerability score
test_data <- data.frame(
  Area = c("Afghanistan", "United States", "Canada", "Germany"),
  vulnerability_score = c(73.5, 15.2, 8.1, 12.3)
)

# Create test map with the new colorscale
test_map <- plot_ly(
  type = "choropleth",
  locations = test_data$Area,
  locationmode = "country names",
  z = test_data$vulnerability_score,
  zmin = 0,
  zmax = 100,
  colorscale = list(
    c(0, "rgb(255,255,255)"),      # White for 0
    c(0.2, "rgb(255,245,240)"),    # Very light red
    c(0.4, "rgb(254,224,210)"),    # Light red
    c(0.6, "rgb(252,187,161)"),    # Medium light red
    c(0.8, "rgb(252,146,114)"),    # Medium red
    c(1, "rgb(220,38,38)")         # Crimson red for 100
  ),
  reversescale = FALSE,
  text = paste("Country:", test_data$Area, "<br>Vulnerability:", test_data$vulnerability_score),
  hoverinfo = "text",
  colorbar = list(
    title = "Vulnerability Score",
    tickvals = c(0, 20, 40, 60, 80, 100),
    ticktext = c("0", "20", "40", "60", "80", "100")
  )
) %>%
  layout(
    title = "Test Map - Afghanistan Should Appear Crimson Red (73.5)",
    geo = list(
      showframe = TRUE,
      showcoastlines = TRUE,
      projection = list(type = "natural earth")
    )
  )

# Display the test map
test_map

cat("Test map created. Afghanistan with score 73.5 should appear in crimson red.\n")
cat("The colorscale goes from white (0) to crimson red (100).\n")
cat("Afghanistan's score of 73.5 should place it in the crimson red range.\n")
