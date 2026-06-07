# ENHANCED VERSION - Global Hunger Research Website with Hover Explanations and World Map
# This version includes detailed hover explanations and comprehensive world map functionality

library(shiny)
library(plotly)
library(DT)
library(tidyverse)
library(WDI)

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Force fresh data collection
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
  titlePanel("🌍 Global Hunger Research Dashboard - Enhanced Version"),
  
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
      .hover-explanation {
        background-color: #e8f4f8;
        padding: 10px;
        border-radius: 5px;
        margin-bottom: 10px;
        border-left: 4px solid #3498db;
        font-size: 12px;
        color: #2c3e50;
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
              div(class = "hover-explanation", 
                  "💡 Hover over bars to see exact counts and percentages. This chart shows how countries are distributed across different hunger risk levels."),
              plotlyOutput("risk_plot", height = "400px")
            ),
            column(6,
              h4("GDP per Capita vs Poverty Rate"),
              div(class = "hover-explanation", 
                  "💡 Hover over points to see country details. This scatter plot shows the relationship between economic development and poverty rates."),
              plotlyOutput("gdp_poverty_plot", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(6,
              h4("Life Expectancy by Risk Level"),
              div(class = "hover-explanation", 
                  "💡 Hover over boxes to see statistical details. This box plot shows how life expectancy varies across different hunger risk levels."),
              plotlyOutput("life_expectancy_plot", height = "350px")
            ),
            column(6,
              h4("Agricultural Land vs Poverty"),
              div(class = "hover-explanation", 
                  "💡 Hover over points to see country details. This scatter plot explores the relationship between agricultural land use and poverty rates."),
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
        
        tabPanel("🌍 World Map",
          fluidRow(
            column(12,
              h4("Interactive World Map - Hunger Risk Analysis"),
              div(class = "hover-explanation", 
                  "💡 Hover over any country to see detailed information including food insecurity data, GDP, population, and historical hunger outbreaks."),
              plotlyOutput("world_map", height = "600px")
            )
          ),
          fluidRow(
            column(12,
              h4("Country Details"),
              htmlOutput("country_details")
            )
          )
        ),
        
        tabPanel("📈 Time Series",
          fluidRow(
            column(8,
              div(class = "hover-explanation", 
                  "💡 Hover over points to see exact values. This chart shows trends over time and helps identify whether indicators are improving or worsening."),
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
        title = list(
          text = "Hunger Risk Distribution",
          font = list(size = 16)
        ),
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
        title = list(
          text = "GDP per Capita vs Poverty Rate",
          font = list(size = 16)
        ),
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
        title = list(
          text = "Life Expectancy by Hunger Risk Level",
          font = list(size = 16)
        ),
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
        title = list(
          text = "Agricultural Land vs Poverty Rate",
          font = list(size = 16)
        ),
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
                   name = "Global Average",
                   text = ~paste("Year:", year, "<br>Value:", round(variable_value, 2)),
                   hoverinfo = "text") %>%
        layout(
          title = list(
            text = paste("Global Average:", input$variable),
            font = list(size = 16)
          ),
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
                   color = ~country, type = "scatter", mode = "lines+markers",
                   text = ~paste("Country:", country, "<br>Year:", year, "<br>Value:", round(get(input$variable), 2)),
                   hoverinfo = "text") %>%
        layout(
          title = list(
            text = paste("Trend by Country:", input$variable),
            font = list(size = 16)
          ),
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
  
  # World map
  output$world_map <- renderPlotly({
    # Create map data with enhanced information
    map_data <- filtered_data() %>%
      mutate(
        # Simulate food insecurity data (in real implementation, this would come from FAO/WFP)
        food_insecure_pop = round(population * (poverty / 100) * 0.8, 0), # Estimate 80% of poor are food insecure
        food_insecurity_growth = round(runif(n(), -5, 15), 1), # Simulated growth rate
        hunger_outbreaks = case_when(
          poverty > 40 ~ "Multiple outbreaks (3+)",
          poverty > 25 ~ "Some outbreaks (1-2)",
          poverty > 15 ~ "Rare outbreaks",
          TRUE ~ "No major outbreaks"
        ),
        # Create hover text with all requested information
        hover_text = paste(
          "<b>", country, "</b><br>",
          "Population: ", format(population, big.mark = ","), "<br>",
          "GDP per Capita: $", format(round(gdp_per_capita, 0), big.mark = ","), "<br>",
          "Food Insecure: ", format(food_insecure_pop, big.mark = ","), " people<br>",
          "Food Insecurity Growth: ", food_insecurity_growth, "% (past decade)<br>",
          "Hunger Outbreaks: ", hunger_outbreaks, "<br>",
          "Hunger Risk Level: ", hunger_risk
        )
      )
    
    # Create choropleth map
    plot_ly(
      type = "choropleth",
      locations = map_data$country,
      locationmode = "country names",
      z = map_data$poverty,
      colorscale = list(
        c(0, "#2E8B57"),    # Very Low - Green
        c(0.25, "#32CD32"), # Low - Light Green  
        c(0.5, "#FFD700"),  # Medium - Yellow
        c(1, "#FF4500")     # High - Red
      ),
      text = map_data$hover_text,
      hoverinfo = "text",
      colorbar = list(
        title = "Poverty Rate (%)",
        len = 0.8
      )
    ) %>%
      layout(
        title = list(
          text = "Global Hunger Risk Map - Hover for Detailed Country Information",
          font = list(size = 16)
        ),
        geo = list(
          showframe = FALSE,
          showcoastlines = TRUE,
          projection = list(type = "natural earth"),
          bgcolor = "#f8f9fa"
        )
      )
  })
  
  # Country details
  output$country_details <- renderUI({
    HTML("
    <div style='background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-top: 20px;'>
      <h4>🌍 World Map Instructions</h4>
      <p><strong>How to use this map:</strong></p>
      <ul>
        <li><strong>Hover over any country</strong> to see detailed information including:</li>
        <ul>
          <li>📊 Number of food insecure people</li>
          <li>📈 Food insecurity growth over the past decade</li>
          <li>💰 GDP per capita</li>
          <li>👥 Population</li>
          <li>⚠️ Historical hunger outbreaks in the past century</li>
        </ul>
        <li><strong>Color coding:</strong> Countries are colored by poverty rate (proxy for hunger risk)</li>
        <li><strong>Green:</strong> Low hunger risk (poverty < 15%)</li>
        <li><strong>Yellow:</strong> Medium hunger risk (poverty 15-30%)</li>
        <li><strong>Red:</strong> High hunger risk (poverty > 30%)</li>
      </ul>
      <p><em>Note: Food insecurity data and hunger outbreak information are simulated for demonstration purposes. In a real implementation, this would come from FAO, WFP, and EM-DAT databases.</em></p>
    </div>
    ")
  })
}

# Run the app
cat("🌍 Starting Enhanced Global Hunger Research Website...\n")
cat("====================================================\n")
cat("✅ Data loaded successfully!\n")
cat("📊 Countries available:", length(unique(summary_data$country)), "\n")
cat("🌐 The website will open in your default web browser.\n")
cat("🛑 To stop the server, press Ctrl+C in the terminal.\n\n")

shinyApp(ui = ui, server = server)
