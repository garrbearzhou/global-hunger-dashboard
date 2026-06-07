# Simplified version of the hunger research website
# This version focuses on core functionality without complex features

library(shiny)
library(plotly)
library(DT)
library(tidyverse)
library(WDI)

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Simple data loading function
load_data <- function() {
  # Try to load existing data first
  if(file.exists("data/raw/world_bank_data.csv")) {
    return(read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE))
  }
  
  # If no existing data, collect new data
  cat("Collecting World Bank data...\n")
  indicators <- c("SP.POP.TOTL", "NY.GDP.PCAP.CD", "SI.POV.DDAY", "SP.DYN.LE00.IN")
  
  data <- WDI(country = "all", indicator = indicators, start = 2020, end = 2023)
  
  # Create directories and save data
  dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)
  write_csv(data, "data/raw/world_bank_data.csv")
  
  return(data)
}

# Load data
wb_data <- load_data()

# Create summary data
summary_data <- wb_data %>%
  group_by(country) %>%
  summarise(
    latest_year = max(year, na.rm = TRUE),
    population = last(SP.POP.TOTL, order_by = year),
    gdp_per_capita = last(NY.GDP.PCAP.CD, order_by = year),
    poverty = last(SI.POV.DDAY, order_by = year),
    life_expectancy = last(SP.DYN.LE00.IN, order_by = year),
    .groups = "drop"
  ) %>%
  filter(!is.na(population)) %>%
  mutate(
    hunger_risk = case_when(
      poverty > 30 ~ "High",
      poverty > 15 ~ "Medium", 
      poverty > 5 ~ "Low",
      TRUE ~ "Very Low"
    ),
    hunger_risk = factor(hunger_risk, levels = c("Very Low", "Low", "Medium", "High"))
  )

# UI
ui <- fluidPage(
  titlePanel("🌍 Global Hunger Research Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Filters"),
      selectInput("countries", "Countries:", 
                 choices = c("All", sort(unique(summary_data$country))),
                 selected = "All", multiple = TRUE),
      selectInput("risk_level", "Hunger Risk:", 
                 choices = c("All", "Very Low", "Low", "Medium", "High"),
                 selected = "All"),
      br(),
      h4("About"),
      p("This dashboard shows global hunger risk based on poverty rates as a proxy indicator."),
      p("Data source: World Bank")
    ),
    
    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel("Overview",
          fluidRow(
            column(6, 
              h4("Countries by Hunger Risk"),
              plotlyOutput("risk_plot")
            ),
            column(6,
              h4("GDP vs Poverty"),
              plotlyOutput("gdp_poverty_plot")
            )
          ),
          br(),
          fluidRow(
            column(12,
              h4("Data Table"),
              DT::dataTableOutput("data_table")
            )
          )
        ),
        
        tabPanel("Time Series",
          plotlyOutput("timeseries_plot"),
          br(),
          selectInput("variable", "Variable:", 
                     choices = c("Population" = "SP.POP.TOTL",
                               "GDP per Capita" = "NY.GDP.PCAP.CD",
                               "Poverty Rate" = "SI.POV.DDAY",
                               "Life Expectancy" = "SP.DYN.LE00.IN"))
        ),
        
        tabPanel("About",
          h3("Global Hunger Research Project"),
          p("This is a simplified version of the hunger research dashboard."),
          p("Research Question: What factors drive hunger and hunger outbreaks?"),
          br(),
          h4("Key Features:"),
          tags$ul(
            tags$li("Interactive data visualization"),
            tags$li("Global hunger risk assessment"),
            tags$li("Time series analysis"),
            tags$li("Data exploration tools")
          ),
          br(),
          h4("Data Sources:"),
          tags$ul(
            tags$li("World Bank - Economic indicators"),
            tags$li("More sources coming soon...")
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output) {
  
  # Filtered data
  filtered_data <- reactive({
    data <- summary_data
    
    if(!("All" %in% input$countries)) {
      data <- data %>% filter(country %in% input$countries)
    }
    
    if(input$risk_level != "All") {
      data <- data %>% filter(hunger_risk == input$risk_level)
    }
    
    return(data)
  })
  
  # Risk distribution plot
  output$risk_plot <- renderPlotly({
    risk_counts <- filtered_data() %>%
      count(hunger_risk) %>%
      mutate(percentage = n / sum(n) * 100)
    
    plot_ly(risk_counts, x = ~hunger_risk, y = ~n, type = "bar",
            color = ~hunger_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500"),
            text = ~paste("Count:", n, "<br>Percentage:", round(percentage, 1), "%"),
            hoverinfo = "text") %>%
      layout(
        title = "Hunger Risk Distribution",
        xaxis = list(title = "Risk Level"),
        yaxis = list(title = "Number of Countries"),
        showlegend = FALSE
      )
  })
  
  # GDP vs Poverty plot
  output$gdp_poverty_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~gdp_per_capita, 
            y = ~poverty,
            color = ~hunger_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500"),
            text = ~paste("Country:", country, 
                         "<br>GDP per Capita: $", round(gdp_per_capita, 0),
                         "<br>Poverty Rate:", round(poverty, 1), "%"),
            hoverinfo = "text",
            type = "scatter", mode = "markers") %>%
      layout(
        title = "GDP per Capita vs Poverty Rate",
        xaxis = list(title = "GDP per Capita (USD)"),
        yaxis = list(title = "Poverty Rate (%)")
      )
  })
  
  # Data table
  output$data_table <- DT::renderDataTable({
    DT::datatable(
      filtered_data() %>%
        select(country, latest_year, population, gdp_per_capita, poverty, 
               life_expectancy, hunger_risk) %>%
        mutate(
          population = round(population / 1e6, 1),
          gdp_per_capita = round(gdp_per_capita, 0),
          poverty = round(poverty, 1),
          life_expectancy = round(life_expectancy, 1)
        ) %>%
        rename(
          Country = country,
          Year = latest_year,
          "Population (M)" = population,
          "GDP per Capita ($)" = gdp_per_capita,
          "Poverty Rate (%)" = poverty,
          "Life Expectancy" = life_expectancy,
          "Hunger Risk" = hunger_risk
        ),
      options = list(pageLength = 25, scrollX = TRUE),
      filter = 'top'
    )
  })
  
  # Time series plot
  output$timeseries_plot <- renderPlotly({
    if("All" %in% input$countries) {
      # Global average
      global_data <- wb_data %>%
        group_by(year) %>%
        summarise(
          variable_value = mean(get(input$variable), na.rm = TRUE),
          .groups = "drop"
        )
      
      plot_ly(global_data, x = ~year, y = ~variable_value, 
              type = "scatter", mode = "lines+markers",
              line = list(color = "#3c8dbc", width = 3)) %>%
        layout(
          title = paste("Global Average:", input$variable),
          xaxis = list(title = "Year"),
          yaxis = list(title = input$variable)
        )
    } else {
      # Selected countries
      country_data <- wb_data %>%
        filter(country %in% input$countries)
      
      plot_ly(country_data, x = ~year, y = ~get(input$variable),
              color = ~country, type = "scatter", mode = "lines+markers") %>%
        layout(
          title = paste("Trend by Country:", input$variable),
          xaxis = list(title = "Year"),
          yaxis = list(title = input$variable)
        )
    }
  })
}

# Run the app
shinyApp(ui = ui, server = server)
