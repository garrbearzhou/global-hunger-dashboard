# Final Working Version of the Hunger Research Website
# This version will collect fresh data and work properly

library(shiny)
library(plotly)
library(DT)
library(tidyverse)
library(WDI)

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Function to collect fresh data
collect_fresh_data <- function() {
  cat("🌍 Collecting fresh World Bank data...\n")
  
  # Key indicators for hunger research
  indicators <- c(
    "SP.POP.TOTL",           # Population, total
    "NY.GDP.PCAP.CD",        # GDP per capita (current US$)
    "SI.POV.DDAY",           # Poverty headcount ratio at $1.90/day
    "SP.DYN.LE00.IN",        # Life expectancy at birth, total (years)
    "AG.LND.AGRI.ZS",        # Agricultural land (% of land area)
    "SP.RUR.TOTL.ZS"         # Rural population (% of total population)
  )
  
  # Collect data for all countries
  wb_data <- WDI(country = "all", 
                 indicator = indicators,
                 start = 2020, 
                 end = 2023,
                 extra = TRUE)
  
  # Create directories and save data
  dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)
  write_csv(wb_data, "data/raw/world_bank_data.csv")
  
  cat("✅ Data collected successfully!\n")
  cat("📊 Total records:", nrow(wb_data), "\n")
  cat("🌍 Countries:", length(unique(wb_data$country)), "\n")
  cat("📅 Years:", min(wb_data$year, na.rm = TRUE), "to", max(wb_data$year, na.rm = TRUE), "\n")
  
  return(wb_data)
}

# Load or collect data
if(file.exists("data/raw/world_bank_data.csv")) {
  cat("📂 Loading existing data...\n")
  wb_data <- read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE)
} else {
  wb_data <- collect_fresh_data()
}

# Create summary data for latest year
cat("🔄 Creating summary data...\n")
summary_data <- wb_data %>%
  group_by(country) %>%
  summarise(
    latest_year = max(year, na.rm = TRUE),
    population = last(SP.POP.TOTL, order_by = year),
    gdp_per_capita = last(NY.GDP.PCAP.CD, order_by = year),
    poverty = last(SI.POV.DDAY, order_by = year),
    life_expectancy = last(SP.DYN.LE00.IN, order_by = year),
    agriculture_land = last(AG.LND.AGRI.ZS, order_by = year),
    rural_pop = last(SP.RUR.TOTL.ZS, order_by = year),
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

cat("✅ Summary data created successfully!\n")
cat("📊 Countries in summary:", nrow(summary_data), "\n")

# UI
ui <- fluidPage(
  titlePanel("🌍 Global Hunger Research Dashboard"),
  
  # Custom CSS
  tags$head(
    tags$style(HTML("
      body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        background-color: #f8f9fa;
      }
      .main-header .logo {
        background-color: #2c3e50 !important;
        color: white !important;
        font-weight: bold;
      }
      .box {
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        border: none;
      }
      .info-box {
        border-radius: 8px;
      }
      .btn-primary {
        background-color: #3498db;
        border-color: #3498db;
        border-radius: 6px;
      }
      .btn-primary:hover {
        background-color: #2980b9;
        border-color: #2980b9;
      }
    "))
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("🔍 Filters", style = "color: #2c3e50; font-weight: bold;"),
      selectInput("countries", "Select Countries:", 
                 choices = c("All", sort(unique(summary_data$country))),
                 selected = "All", multiple = TRUE),
      selectInput("risk_level", "Hunger Risk Level:", 
                 choices = c("All", "Very Low", "Low", "Medium", "High"),
                 selected = "All"),
      br(),
      h4("📊 Key Statistics", style = "color: #2c3e50; font-weight: bold;"),
      verbatimTextOutput("stats_summary"),
      br(),
      h4("ℹ️ About", style = "color: #2c3e50; font-weight: bold;"),
      p("This dashboard shows global hunger risk based on poverty rates as a proxy indicator."),
      p("Data source: World Bank"),
      p("Research by: Garrett Zhou"),
      br(),
      h4("🎯 Risk Levels:", style = "color: #2c3e50; font-weight: bold;"),
      p("🔴 High: Poverty > 30%"),
      p("🟡 Medium: Poverty 15-30%"),
      p("🟢 Low: Poverty 5-15%"),
      p("⚪ Very Low: Poverty < 5%")
    ),
    
    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel("📊 Overview",
          fluidRow(
            column(6, 
              h4("Countries by Hunger Risk"),
              plotlyOutput("risk_plot", height = "400px")
            ),
            column(6,
              h4("GDP per Capita vs Poverty Rate"),
              plotlyOutput("gdp_poverty_plot", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(6,
              h4("Life Expectancy by Risk Level"),
              plotlyOutput("life_expectancy_plot", height = "350px")
            ),
            column(6,
              h4("Agricultural Land vs Poverty"),
              plotlyOutput("agriculture_plot", height = "350px")
            )
          ),
          br(),
          fluidRow(
            column(12,
              h4("📋 Data Table"),
              DT::dataTableOutput("data_table")
            )
          )
        ),
        
        tabPanel("📈 Time Series",
          fluidRow(
            column(8,
              plotlyOutput("timeseries_plot", height = "500px")
            ),
            column(4,
              h4("Variable Selection"),
              selectInput("variable", "Select Variable:", 
                         choices = c("Population" = "SP.POP.TOTL",
                                   "GDP per Capita" = "NY.GDP.PCAP.CD",
                                   "Poverty Rate" = "SI.POV.DDAY",
                                   "Life Expectancy" = "SP.DYN.LE00.IN",
                                   "Agricultural Land" = "AG.LND.AGRI.ZS",
                                   "Rural Population" = "SP.RUR.TOTL.ZS")),
              br(),
              h4("Analysis Options"),
              checkboxInput("show_trend", "Show Trend Line", value = TRUE),
              checkboxInput("show_global_avg", "Show Global Average", value = FALSE)
            )
          )
        ),
        
        tabPanel("🔍 Data Explorer",
          fluidRow(
            column(12,
              h4("Interactive Data Explorer"),
              DT::dataTableOutput("explorer_table")
            )
          ),
          br(),
          fluidRow(
            column(6,
              h4("Data Summary"),
              verbatimTextOutput("data_summary")
            ),
            column(6,
              h4("Missing Data Analysis"),
              verbatimTextOutput("missing_data")
            )
          )
        ),
        
        tabPanel("📚 About",
          fluidRow(
            column(12,
              h3("🌍 Global Hunger Research Project"),
              p("This interactive dashboard is part of a comprehensive research project focused on global hunger, food insecurity, and predictive modeling."),
              
              h4("🎯 Research Question:"),
              p("What factors drive hunger and hunger outbreaks, and how will these factors change in the future?"),
              
              h4("📊 Project Goals:"),
              tags$ul(
                tags$li("Identify patterns in historical hunger data"),
                tags$li("Develop predictive models for hunger risk"),
                tags$li("Create interactive visualizations for policymakers"),
                tags$li("Build tools for early warning systems")
              ),
              
              h4("📈 Data Sources:"),
              tags$ul(
                tags$li("World Bank - Economic and demographic indicators"),
                tags$li("FAO - Food security data (coming soon)"),
                tags$li("WFP - Market and vulnerability data (coming soon)"),
                tags$li("EM-DAT - Disaster and conflict data (coming soon)")
              ),
              
              h4("🔧 Methodology:"),
              tags$ul(
                tags$li("Statistical analysis and correlation studies"),
                tags$li("Time series forecasting"),
                tags$li("Machine learning for risk prediction"),
                tags$li("Geospatial analysis and mapping")
              ),
              
              h4("👨‍💻 Author:"),
              p("Garrett Zhou - Research Project 2024"),
              
              h4("🛠️ Technology Stack:"),
              tags$ul(
                tags$li("R and RStudio for data analysis"),
                tags$li("Shiny for web application"),
                tags$li("Plotly for interactive visualizations"),
                tags$li("World Bank API for data collection")
              )
            )
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
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
  
  # Statistics summary
  output$stats_summary <- renderText({
    data <- filtered_data()
    paste(
      "Countries:", nrow(data), "\n",
      "Total Population:", round(sum(data$population, na.rm = TRUE)/1e9, 1), "B\n",
      "High Risk Countries:", sum(data$hunger_risk == "High", na.rm = TRUE), "\n",
      "Avg GDP per Capita: $", round(mean(data$gdp_per_capita, na.rm = TRUE), 0), "\n",
      "Avg Poverty Rate:", round(mean(data$poverty, na.rm = TRUE), 1), "%"
    )
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
  
  # Life expectancy plot
  output$life_expectancy_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~hunger_risk, 
            y = ~life_expectancy,
            color = ~hunger_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500"),
            type = "box") %>%
      layout(
        title = "Life Expectancy by Hunger Risk Level",
        xaxis = list(title = "Hunger Risk Level"),
        yaxis = list(title = "Life Expectancy (years)"),
        showlegend = FALSE
      )
  })
  
  # Agriculture plot
  output$agriculture_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~agriculture_land, 
            y = ~poverty,
            color = ~hunger_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500"),
            text = ~paste("Country:", country, 
                         "<br>Agricultural Land:", round(agriculture_land, 1), "%",
                         "<br>Poverty Rate:", round(poverty, 1), "%"),
            hoverinfo = "text",
            type = "scatter", mode = "markers") %>%
      layout(
        title = "Agricultural Land vs Poverty Rate",
        xaxis = list(title = "Agricultural Land (% of total land)"),
        yaxis = list(title = "Poverty Rate (%)")
      )
  })
  
  # Data table
  output$data_table <- DT::renderDataTable({
    DT::datatable(
      filtered_data() %>%
        select(country, latest_year, population, gdp_per_capita, poverty, 
               life_expectancy, agriculture_land, hunger_risk) %>%
        mutate(
          population = round(population / 1e6, 1),
          gdp_per_capita = round(gdp_per_capita, 0),
          poverty = round(poverty, 1),
          life_expectancy = round(life_expectancy, 1),
          agriculture_land = round(agriculture_land, 1)
        ) %>%
        rename(
          Country = country,
          Year = latest_year,
          "Population (M)" = population,
          "GDP per Capita ($)" = gdp_per_capita,
          "Poverty Rate (%)" = poverty,
          "Life Expectancy" = life_expectancy,
          "Agricultural Land (%)" = agriculture_land,
          "Hunger Risk" = hunger_risk
        ),
      options = list(pageLength = 25, scrollX = TRUE),
      filter = 'top'
    )
  })
  
  # Explorer table
  output$explorer_table <- DT::renderDataTable({
    DT::datatable(
      filtered_data(),
      options = list(pageLength = 50, scrollX = TRUE, dom = 'Bfrtip',
                    buttons = c('copy', 'csv', 'excel')),
      extensions = 'Buttons',
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
      
      p <- plot_ly(global_data, x = ~year, y = ~variable_value, 
                   type = "scatter", mode = "lines+markers",
                   line = list(color = "#3c8dbc", width = 3),
                   name = "Global Average") %>%
        layout(
          title = paste("Global Average:", input$variable),
          xaxis = list(title = "Year"),
          yaxis = list(title = input$variable)
        )
      
      if(input$show_trend) {
        p <- p %>% add_trace(y = ~fitted(loess(variable_value ~ year, data = global_data)),
                           name = "Trend", line = list(dash = "dash"))
      }
      
    } else {
      # Selected countries
      country_data <- wb_data %>%
        filter(country %in% input$countries)
      
      p <- plot_ly(country_data, x = ~year, y = ~get(input$variable),
                   color = ~country, type = "scatter", mode = "lines+markers") %>%
        layout(
          title = paste("Trend by Country:", input$variable),
          xaxis = list(title = "Year"),
          yaxis = list(title = input$variable)
        )
    }
    
    p
  })
  
  # Data summary
  output$data_summary <- renderText({
    summary_text <- capture.output(summary(filtered_data() %>%
                                           select(population, gdp_per_capita, poverty, 
                                                  life_expectancy, agriculture_land)))
    paste(summary_text, collapse = "\n")
  })
  
  # Missing data analysis
  output$missing_data <- renderText({
    missing_summary <- filtered_data() %>%
      summarise_all(~sum(is.na(.))) %>%
      gather(key = "variable", value = "missing_count") %>%
      arrange(desc(missing_count))
    
    paste("Missing values per variable:\n", 
          paste(missing_summary$variable, ":", missing_summary$missing_count, collapse = "\n"))
  })
}

# Run the app
cat("🌍 Starting Global Hunger Research Website...\n")
cat("============================================\n")
cat("✅ Data loaded successfully!\n")
cat("📊 Countries available:", length(unique(summary_data$country)), "\n")
cat("🌐 The website will open in your default web browser.\n")
cat("🛑 To stop the server, press Ctrl+C in the terminal.\n\n")

shinyApp(ui = ui, server = server)
