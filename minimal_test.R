library(shiny)
library(plotly)

ui <- fluidPage(
  titlePanel("Minimal Test"),
  plotlyOutput("test_map")
)

server <- function(input, output) {
  output$test_map <- renderPlotly({
    plot_ly(
      type = "choropleth",
      locations = c("Afghanistan", "United States", "China"),
      locationmode = "country names",
      z = c(73.5, 15.2, 8.1),
      zmin = 0,
      zmax = 100,
      colorscale = "Reds",
      reversescale = FALSE
    ) %>%
      layout(
        title = "Test Map - Afghanistan should be RED",
        geo = list(showframe = TRUE)
      )
  })
}

shinyApp(ui = ui, server = server)
