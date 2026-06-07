library(shiny)
library(plotly)
library(DT)
library(tidyverse)

# Load data
fao_latest <- read_csv("data/raw/fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv", show_col_types = FALSE)
wb_raw_data <- read_csv("data/raw/world bank/world_bank_data.csv", show_col_types = FALSE)

# Simple vulnerability calculation
calculate_vulnerability <- function(data) {
  data %>%
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
}

# Process data
processed_data <- calculate_vulnerability(fao_latest)

ui <- fluidPage(
  titlePanel("Hunger Vulnerability Map - Fixed Colors"),
  plotlyOutput("world_map"),
  DT::dataTableOutput("data_table")
)

server <- function(input, output) {
  output$world_map <- renderPlotly({
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
      hoverinfo = "text",
      colorbar = list(
        title = "Vulnerability Score",
        tickvals = c(0, 20, 40, 60, 80, 100),
        ticktext = c("0", "20", "40", "60", "80", "100")
      )
    ) %>%
      layout(
        title = "Global Hunger Vulnerability Map (0-100 Scale)",
        geo = list(
          showframe = TRUE,
          showcoastlines = TRUE,
          projection = list(type = "natural earth")
        )
      )
  })
  
  output$data_table <- DT::renderDataTable({
    processed_data %>%
      select(Area, hunger_vulnerability_rating, undernourishment_rate, poverty_headcount, gdp_per_capita) %>%
      arrange(desc(hunger_vulnerability_rating))
  })
}

shinyApp(ui = ui, server = server)
