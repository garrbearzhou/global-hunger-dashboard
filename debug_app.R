library(shiny)
library(plotly)
library(DT)
library(tidyverse)

# Simple data loading
cat("Loading FAO data...\n")
fao_latest <- read_csv("data/raw/fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv", show_col_types = FALSE)
cat("FAO data loaded:", nrow(fao_latest), "rows\n")

cat("Loading World Bank data...\n")
wb_raw_data <- read_csv("data/raw/world bank/world_bank_data.csv", show_col_types = FALSE)
cat("World Bank data loaded:", nrow(wb_raw_data), "rows\n")

# Simple vulnerability calculation
calculate_simple_vulnerability <- function(data) {
  cat("Calculating vulnerability...\n")
  result <- data %>%
    mutate(
      undernourishment_score = pmin(ifelse(is.na(undernourishment_rate), 0, undernourishment_rate) * 0.8, 40),
      poverty_score = case_when(
        !is.na(poverty_headcount) ~ pmin(poverty_headcount * 0.4, 20),
        !is.na(poverty_rate) ~ pmin(poverty_rate * 0.4, 20),
        TRUE ~ 0
      ),
      gdp_score = case_when(
        is.na(gdp_per_capita) ~ 0,
        gdp_per_capita < 1000 ~ 15, 
        gdp_per_capita < 3000 ~ 12, 
        gdp_per_capita < 10000 ~ 8, 
        gdp_per_capita < 20000 ~ 4, 
        TRUE ~ 0
      ),
      hunger_vulnerability_rating = round(
        undernourishment_score + poverty_score + gdp_score,
        1
      ),
      hunger_vulnerability_rating = pmax(0, pmin(100, hunger_vulnerability_rating))
    )
  cat("Vulnerability calculated for", nrow(result), "countries\n")
  return(result)
}

# Process data
cat("Processing data...\n")
processed_data <- calculate_simple_vulnerability(fao_latest)
cat("Data processing complete!\n")

ui <- fluidPage(
  titlePanel("Simple Hunger Vulnerability Map"),
  plotlyOutput("world_map"),
  DT::dataTableOutput("data_table")
)

server <- function(input, output) {
  output$world_map <- renderPlotly({
    cat("Rendering map...\n")
    plot_ly(
      type = "choropleth",
      locations = processed_data$Area,
      locationmode = "country names",
      z = processed_data$hunger_vulnerability_rating,
      zmin = 0,
      zmax = 100,
      colorscale = "Reds",
      reversescale = FALSE,
      text = paste("Country:", processed_data$Area, "<br>Vulnerability:", processed_data$hunger_vulnerability_rating),
      hoverinfo = "text"
    ) %>%
      layout(
        title = "Global Hunger Vulnerability Map",
        geo = list(showframe = TRUE)
      )
  })
  
  output$data_table <- DT::renderDataTable({
    processed_data %>%
      select(Area, hunger_vulnerability_rating, undernourishment_rate, poverty_headcount, gdp_per_capita) %>%
      arrange(desc(hunger_vulnerability_rating))
  })
}

cat("Starting Shiny app...\n")
shinyApp(ui = ui, server = server)
