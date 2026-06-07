# FAO-Integrated Global Hunger Research Website
# This version integrates real FAO food security data

library(shiny)
library(plotly)
library(DT)
library(tidyverse)
library(readr)

# Set working directory and load FAO data
cat("🌍 Loading FAO Food Security Data...\n")

# Load FAO data files
fao_main <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data_NOFLAG.csv", show_col_types = FALSE)
area_codes <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_AreaCodes.csv", show_col_types = FALSE)
element_codes <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_Elements.csv", show_col_types = FALSE)
item_codes <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_ItemCodes.csv", show_col_types = FALSE)

cat("✅ FAO data loaded successfully!\n")
cat("📊 Total FAO records:", nrow(fao_main), "\n")
cat("🌍 Countries in FAO data:", length(unique(fao_main$Area)), "\n")

# Process FAO data for analysis
process_fao_data <- function() {
  cat("🔄 Processing FAO data for analysis...\n")
  
  # Get year columns (3-year averages)
  year_cols <- c("Y20002002", "Y20012003", "Y20022004", "Y20032005", "Y20042006", "Y20052007", 
                 "Y20062008", "Y20072009", "Y20082010", "Y20092011", "Y20102012", "Y20112013", 
                 "Y20122014", "Y20132015", "Y20142016", "Y20152017", "Y20162018", "Y20172019", 
                 "Y20182020", "Y20192021", "Y20202022", "Y20212023", "Y20222024")
  
  # Key indicators we want to extract
  key_indicators <- c(
    "210041",  # Prevalence of undernourishment (percent) (3-year average)
    "210011",  # Number of people undernourished (million) (3-year average)
    "210401",  # Prevalence of severe food insecurity in the total population (percent) (3-year average)
    "210091",  # Prevalence of moderate or severe food insecurity in the total population (percent) (3-year average)
    "21010",   # Average dietary energy supply adequacy (percent) (3-year average)
    "22013",   # Gross domestic product per capita, PPP, (constant 2021 international $)
    "21035",   # Cereal import dependency ratio (percent) (3-year average)
    "21033",   # Value of food imports in total merchandise exports (percent) (3-year average)
    "21032"    # Political stability and absence of violence/terrorism (index)
  )
  
  # Filter for key indicators and value elements only
  fao_processed <- fao_main %>%
    filter(`Item Code` %in% key_indicators & `Element Code` == 6121) %>%  # Value elements only
    select(Area, `Item Code`, Item, Element, Unit, all_of(year_cols)) %>%
    pivot_longer(cols = all_of(year_cols), 
                 names_to = "Year", 
                 values_to = "Value") %>%
    mutate(Year = as.numeric(substr(Year, 2, 5)),  # Extract start year from Y20002002 format
           Value = as.numeric(Value)) %>%  # Convert values to numeric
    filter(!is.na(Value) & Value != 0) %>%
    pivot_wider(names_from = `Item Code`, values_from = Value, names_prefix = "ind_")
  
  # Create summary data for latest available year per country
  summary_data <- fao_processed %>%
    group_by(Area) %>%
    summarise(
      latest_year = max(Year, na.rm = TRUE),
      undernourishment_rate = last(ind_210041, order_by = Year),
      severe_food_insecurity = last(ind_210401, order_by = Year),
      moderate_severe_food_insecurity = last(ind_210091, order_by = Year),
      dietary_energy_adequacy = last(ind_21010, order_by = Year),
      cereal_import_dependency = last(ind_21035, order_by = Year),
      food_import_value = last(ind_21033, order_by = Year),
      .groups = "drop"
    ) %>%
    filter(!is.na(undernourishment_rate)) %>%
    mutate(
      # Create hunger risk categories based on undernourishment rate
      hunger_risk = case_when(
        undernourishment_rate >= 25 ~ "Critical",
        undernourishment_rate >= 15 ~ "High",
        undernourishment_rate >= 10 ~ "Medium", 
        undernourishment_rate >= 5 ~ "Low",
        TRUE ~ "Very Low"
      ),
      hunger_risk = factor(hunger_risk, levels = c("Very Low", "Low", "Medium", "High", "Critical")),
      
      # Create food insecurity categories
      food_insecurity_level = case_when(
        moderate_severe_food_insecurity >= 50 ~ "Very High",
        moderate_severe_food_insecurity >= 30 ~ "High",
        moderate_severe_food_insecurity >= 15 ~ "Medium",
        moderate_severe_food_insecurity >= 5 ~ "Low",
        TRUE ~ "Very Low"
      ),
      food_insecurity_level = factor(food_insecurity_level, levels = c("Very Low", "Low", "Medium", "High", "Very High")),
      
      # Economic development categories (based on food import value as proxy)
      development_level = case_when(
        food_import_value >= 50 ~ "High Income",
        food_import_value >= 30 ~ "Upper Middle Income",
        food_import_value >= 15 ~ "Lower Middle Income",
        food_import_value >= 5 ~ "Low Income",
        TRUE ~ "Very Low Income"
      ),
      development_level = factor(development_level, levels = c("Very Low Income", "Low Income", "Lower Middle Income", "Upper Middle Income", "High Income"))
    )
  
  cat("✅ FAO data processed successfully!\n")
  cat("📊 Countries with complete data:", nrow(summary_data), "\n")
  cat("📅 Latest year range:", min(summary_data$latest_year), "to", max(summary_data$latest_year), "\n")
  
  return(list(
    summary = summary_data,
    time_series = fao_processed
  ))
}

# Process the data
fao_data <- process_fao_data()
summary_data <- fao_data$summary
time_series_data <- fao_data$time_series

# UI
ui <- fluidPage(
  titlePanel("🌍 Global Hunger Research Dashboard - FAO Data Integration"),
  
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
      .hunger-critical { color: #8B0000; font-weight: bold; }
      .hunger-high { color: #FF4500; font-weight: bold; }
      .hunger-medium { color: #FFD700; font-weight: bold; }
      .hunger-low { color: #32CD32; font-weight: bold; }
      .hunger-very-low { color: #2E8B57; font-weight: bold; }
    "))
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("🔍 Filters", style = "color: #2c3e50; font-weight: bold;"),
      selectInput("countries", "Select Countries:", 
                 choices = c("All", sort(unique(summary_data$Area))),
                 selected = "All", multiple = TRUE),
      selectInput("risk_level", "Hunger Risk Level:", 
                 choices = c("All", "Very Low", "Low", "Medium", "High", "Critical"),
                 selected = "All"),
      selectInput("development_level", "Development Level:", 
                 choices = c("All", "Very Low Income", "Low Income", "Lower Middle Income", "Upper Middle Income", "High Income"),
                 selected = "All"),
      br(),
      h4("📊 Key Statistics", style = "color: #2c3e50; font-weight: bold;"),
      verbatimTextOutput("stats_summary"),
      br(),
      h4("ℹ️ About", style = "color: #2c3e50; font-weight: bold;"),
      p("This dashboard uses real FAO food security data to analyze global hunger patterns."),
      p("Data source: FAO Food Security Indicators"),
      p("Research by: Garrett Zhou"),
      br(),
      h4("🎯 Hunger Risk Levels:", style = "color: #2c3e50; font-weight: bold;"),
      p("🔴 Critical: Undernourishment ≥ 25%"),
      p("🟠 High: Undernourishment 15-25%"),
      p("🟡 Medium: Undernourishment 10-15%"),
      p("🟢 Low: Undernourishment 5-10%"),
      p("⚪ Very Low: Undernourishment < 5%")
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
              h4("Undernourishment vs Food Import Value"),
              plotlyOutput("gdp_undernourishment_plot", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(6,
              h4("Food Insecurity Levels"),
              plotlyOutput("food_insecurity_plot", height = "350px")
            ),
            column(6,
              h4("Dietary Energy Adequacy"),
              plotlyOutput("dietary_energy_plot", height = "350px")
            )
          ),
          br(),
          fluidRow(
            column(12,
              h4("📋 FAO Data Table"),
              DT::dataTableOutput("data_table")
            )
          )
        ),
        
        tabPanel("🌍 World Map",
          fluidRow(
            column(12,
              h4("Interactive World Map - FAO Hunger Data"),
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
              plotlyOutput("timeseries_plot", height = "500px")
            ),
            column(4,
              h4("Variable Selection"),
              selectInput("variable", "Select FAO Indicator:", 
                         choices = c("Undernourishment Rate" = "ind_210041",
                                   "Severe Food Insecurity" = "ind_210401",
                                   "Moderate/Severe Food Insecurity" = "ind_210091",
                                   "Dietary Energy Adequacy" = "ind_21010",
                                   "Cereal Import Dependency" = "ind_21035",
                                   "Food Import Value" = "ind_21033")),
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
              h4("Interactive FAO Data Explorer"),
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
              h3("🌍 Global Hunger Research Project - FAO Integration"),
              p("This interactive dashboard integrates real FAO (Food and Agriculture Organization) data to provide comprehensive analysis of global hunger and food security patterns."),
              
              h4("🎯 Research Question:"),
              p("What factors drive hunger and hunger outbreaks, and how will these factors change in the future?"),
              
              h4("📊 FAO Data Sources:"),
              tags$ul(
                tags$li("Prevalence of undernourishment - Direct measure of hunger"),
                tags$li("Number of people undernourished - Absolute hunger burden"),
                tags$li("Food insecurity prevalence - Broader food access issues"),
                tags$li("Dietary energy supply adequacy - Nutritional sufficiency"),
                tags$li("GDP per capita - Economic development indicator"),
                tags$li("Cereal import dependency - Food system vulnerability"),
                tags$li("Political stability - Governance and conflict factors")
              ),
              
              h4("🔧 Key Indicators:"),
              tags$ul(
                tags$li("Undernourishment Rate: Percentage of population below minimum dietary energy requirements"),
                tags$li("Food Insecurity: Moderate or severe lack of access to adequate food"),
                tags$li("Dietary Energy Adequacy: Percentage of dietary energy requirements met"),
                tags$li("Import Dependency: Reliance on food imports for basic needs")
              ),
              
              h4("📈 Methodology:"),
              tags$ul(
                tags$li("Real FAO data from 2000-2023"),
                tags$li("Multi-dimensional hunger risk assessment"),
                tags$li("Economic development correlation analysis"),
                tags$li("Time series trend identification"),
                tags$li("Geographic pattern analysis")
              ),
              
              h4("👨‍💻 Author:"),
              p("Garrett Zhou - Research Project 2024"),
              
              h4("🛠️ Technology Stack:"),
              tags$ul(
                tags$li("R and RStudio for data analysis"),
                tags$li("Shiny for web application"),
                tags$li("Plotly for interactive visualizations"),
                tags$li("FAO Food Security Indicators database")
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
      data <- data %>% filter(Area %in% input$countries)
    }
    
    if(input$risk_level != "All") {
      data <- data %>% filter(hunger_risk == input$risk_level)
    }
    
    if(input$development_level != "All") {
      data <- data %>% filter(development_level == input$development_level)
    }
    
    return(data)
  })
  
  # Statistics summary
  output$stats_summary <- renderText({
    data <- filtered_data()
    paste(
      "Countries:", nrow(data), "\n",
      "Critical Risk Countries:", sum(data$hunger_risk == "Critical", na.rm = TRUE), "\n",
      "Avg Undernourishment:", round(mean(data$undernourishment_rate, na.rm = TRUE), 1), "%\n",
      "Avg Food Insecurity:", round(mean(data$moderate_severe_food_insecurity, na.rm = TRUE), 1), "%\n",
      "Avg Dietary Energy:", round(mean(data$dietary_energy_adequacy, na.rm = TRUE), 1), "%\n",
      "Avg Import Dependency:", round(mean(data$cereal_import_dependency, na.rm = TRUE), 1), "%"
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
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Count:", n, "<br>Percentage:", round(percentage, 1), "%"),
            hoverinfo = "text") %>%
      layout(
        title = list(
          text = "Hunger Risk Distribution (FAO Data)",
          font = list(size = 16)
        ),
        xaxis = list(title = "Hunger Risk Level"),
        yaxis = list(title = "Number of Countries"),
        showlegend = FALSE
      )
  })
  
  # Food Import Value vs Undernourishment plot
  output$gdp_undernourishment_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~food_import_value, 
            y = ~undernourishment_rate,
            color = ~hunger_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Country:", Area, 
                         "<br>Food Import Value: ", round(food_import_value, 1), "%",
                         "<br>Undernourishment Rate:", round(undernourishment_rate, 1), "%"),
            hoverinfo = "text",
            type = "scatter", mode = "markers") %>%
      layout(
        title = list(
          text = "Food Import Value vs Undernourishment Rate",
          font = list(size = 16)
        ),
        xaxis = list(title = "Food Import Value (% of exports)"),
        yaxis = list(title = "Undernourishment Rate (%)")
      )
  })
  
  # Food insecurity plot
  output$food_insecurity_plot <- renderPlotly({
    insecurity_counts <- filtered_data() %>%
      count(food_insecurity_level) %>%
      mutate(percentage = n / sum(n) * 100)
    
    plot_ly(insecurity_counts, x = ~food_insecurity_level, y = ~n, type = "bar",
            color = ~food_insecurity_level,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Very High" = "#8B0000"),
            text = ~paste("Count:", n, "<br>Percentage:", round(percentage, 1), "%"),
            hoverinfo = "text") %>%
      layout(
        title = list(
          text = "Food Insecurity Distribution",
          font = list(size = 16)
        ),
        xaxis = list(title = "Food Insecurity Level"),
        yaxis = list(title = "Number of Countries"),
        showlegend = FALSE
      )
  })
  
  # Dietary energy plot
  output$dietary_energy_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~hunger_risk, 
            y = ~dietary_energy_adequacy,
            color = ~hunger_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            type = "box") %>%
      layout(
        title = list(
          text = "Dietary Energy Adequacy by Hunger Risk",
          font = list(size = 16)
        ),
        xaxis = list(title = "Hunger Risk Level"),
        yaxis = list(title = "Dietary Energy Adequacy (%)"),
        showlegend = FALSE
      )
  })
  
  # Data table
  output$data_table <- DT::renderDataTable({
    DT::datatable(
      filtered_data() %>%
        select(Area, latest_year, undernourishment_rate, 
               moderate_severe_food_insecurity, dietary_energy_adequacy, 
               cereal_import_dependency, food_import_value, hunger_risk, development_level) %>%
        mutate(
          undernourishment_rate = round(undernourishment_rate, 1),
          moderate_severe_food_insecurity = round(moderate_severe_food_insecurity, 1),
          dietary_energy_adequacy = round(dietary_energy_adequacy, 1),
          cereal_import_dependency = round(cereal_import_dependency, 1),
          food_import_value = round(food_import_value, 1)
        ) %>%
        rename(
          Country = Area,
          Year = latest_year,
          "Undernourishment (%)" = undernourishment_rate,
          "Food Insecurity (%)" = moderate_severe_food_insecurity,
          "Dietary Energy (%)" = dietary_energy_adequacy,
          "Cereal Import Dep. (%)" = cereal_import_dependency,
          "Food Import Value (%)" = food_import_value,
          "Hunger Risk" = hunger_risk,
          "Development Level" = development_level
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
      global_data <- time_series_data %>%
        group_by(Year) %>%
        summarise(
          variable_value = mean(get(input$variable), na.rm = TRUE),
          .groups = "drop"
        )
      
      p <- plot_ly(global_data, x = ~Year, y = ~variable_value, 
                   type = "scatter", mode = "lines+markers",
                   line = list(color = "#3c8dbc", width = 3),
                   name = "Global Average",
                   text = ~paste("Year:", Year, "<br>Value:", round(variable_value, 2)),
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
        p <- p %>% add_trace(y = ~fitted(loess(variable_value ~ Year, data = global_data)),
                           name = "Trend", line = list(dash = "dash"))
      }
      
    } else {
      # Selected countries
      country_data <- time_series_data %>%
        filter(Area %in% input$countries)
      
      p <- plot_ly(country_data, x = ~Year, y = ~get(input$variable),
                   color = ~Area, type = "scatter", mode = "lines+markers",
                   text = ~paste("Country:", Area, "<br>Year:", Year, "<br>Value:", round(get(input$variable), 2)),
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
  
  # World map
  output$world_map <- renderPlotly({
    # Create map data with FAO information
    map_data <- filtered_data() %>%
      mutate(
        # Create hover text with FAO information
        hover_text = paste(
          "<b>", Area, "</b><br>",
          "Undernourishment Rate: ", round(undernourishment_rate, 1), "%<br>",
          "Food Insecurity: ", round(moderate_severe_food_insecurity, 1), "%<br>",
          "Dietary Energy Adequacy: ", round(dietary_energy_adequacy, 1), "%<br>",
          "Cereal Import Dependency: ", round(cereal_import_dependency, 1), "%<br>",
          "Food Import Value: ", round(food_import_value, 1), "%<br>",
          "Hunger Risk Level: ", hunger_risk, "<br>",
          "Development Level: ", development_level
        )
      )
    
    # Create choropleth map
    plot_ly(
      type = "choropleth",
      locations = map_data$Area,
      locationmode = "country names",
      z = map_data$undernourishment_rate,
      colorscale = list(
        c(0, "#2E8B57"),    # Very Low - Green
        c(0.2, "#32CD32"),  # Low - Light Green  
        c(0.4, "#FFD700"),  # Medium - Yellow
        c(0.7, "#FF4500"),  # High - Red
        c(1, "#8B0000")     # Critical - Dark Red
      ),
      text = map_data$hover_text,
      hoverinfo = "text",
      colorbar = list(
        title = "Undernourishment Rate (%)",
        len = 0.8
      )
    ) %>%
      layout(
        title = list(
          text = "Global Undernourishment Map - FAO Data (Hover for Details)",
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
      <h4>🌍 FAO World Map Instructions</h4>
      <p><strong>How to use this map:</strong></p>
      <ul>
        <li><strong>Hover over any country</strong> to see detailed FAO food security information:</li>
        <ul>
          <li>📊 Undernourishment rate (direct hunger measure)</li>
          <li>👥 Number of undernourished people</li>
          <li>🍽️ Food insecurity prevalence</li>
          <li>⚡ Dietary energy adequacy</li>
          <li>💰 GDP per capita</li>
          <li>⚠️ Hunger risk classification</li>
          <li>🏗️ Development level</li>
        </ul>
        <li><strong>Color coding:</strong> Countries are colored by undernourishment rate</li>
        <li><strong>Green:</strong> Low hunger risk (undernourishment < 10%)</li>
        <li><strong>Yellow:</strong> Medium hunger risk (undernourishment 10-15%)</li>
        <li><strong>Red:</strong> High hunger risk (undernourishment 15-25%)</li>
        <li><strong>Dark Red:</strong> Critical hunger risk (undernourishment ≥ 25%)</li>
      </ul>
      <p><em>This map uses real FAO data from the Food Security Indicators database, providing the most accurate and comprehensive view of global hunger patterns.</em></p>
    </div>
    ")
  })
  
  # Data summary
  output$data_summary <- renderText({
    summary_text <- capture.output(summary(filtered_data() %>%
                                           select(undernourishment_rate, 
                                                  moderate_severe_food_insecurity, dietary_energy_adequacy, 
                                                  cereal_import_dependency, food_import_value)))
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
cat("🌍 Starting FAO-Integrated Global Hunger Research Website...\n")
cat("============================================================\n")
cat("✅ FAO data loaded successfully!\n")
cat("📊 Countries available:", length(unique(summary_data$Area)), "\n")
cat("\n🌐 WEBSITE URL: http://localhost:3838\n")
cat("📱 Alternative: http://127.0.0.1:3838\n")
cat("🔗 Copy and paste this URL into your browser!\n")
cat("🛑 To stop the server, press Ctrl+C in the terminal.\n\n")

shinyApp(ui = ui, server = server)
