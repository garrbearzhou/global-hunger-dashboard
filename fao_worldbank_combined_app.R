# FAO-World Bank Combined Global Hunger Research Website
# This version integrates FAO food security data with World Bank economic and health indicators

library(shiny)
library(plotly)
library(DT)
library(tidyverse)
library(readr)

# Set working directory and load data
cat("🌍 Loading FAO Food Security Data and World Bank Indicators...\n")

# Load FAO data files
fao_main <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data_NOFLAG.csv", show_col_types = FALSE)
area_codes <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_AreaCodes.csv", show_col_types = FALSE)
element_codes <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_Elements.csv", show_col_types = FALSE)
item_codes <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_ItemCodes.csv", show_col_types = FALSE)

# Load World Bank data
world_bank_data <- read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE)

cat("✅ FAO data loaded successfully!\n")
cat("📊 Total FAO records:", nrow(fao_main), "\n")
cat("🌍 Countries in FAO data:", length(unique(fao_main$Area)), "\n")
cat("✅ World Bank data loaded successfully!\n")
cat("📊 Total World Bank records:", nrow(world_bank_data), "\n")
cat("🌍 Countries in World Bank data:", length(unique(world_bank_data$country)), "\n")

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
  
  cat("✅ FAO data processed successfully!\n")
  cat("📊 Records after processing:", nrow(fao_processed), "\n")
  
  return(fao_processed)
}

# Process World Bank data
process_worldbank_data <- function() {
  cat("🔄 Processing World Bank data...\n")
  
  # Create summary data for latest available year per country
  wb_summary <- world_bank_data %>%
    filter(!is.na(country) & country != "") %>%  # Remove empty countries
    group_by(country) %>%
    summarise(
      latest_year = max(year, na.rm = TRUE),
      population = last(SP.POP.TOTL, order_by = year),
      gdp_per_capita = last(NY.GDP.PCAP.CD, order_by = year),
      poverty_rate = last(SI.POV.DDAY, order_by = year),
      life_expectancy = last(SP.DYN.LE00.IN, order_by = year),
      agriculture_land = last(AG.LND.AGRI.ZS, order_by = year),
      rural_population = last(SP.RUR.TOTL.ZS, order_by = year),
      region = last(region, order_by = year),
      income_level = last(income, order_by = year),
      .groups = "drop"
    ) %>%
    filter(!is.na(country)) %>%
    mutate(
      # Create economic development categories
      development_level = case_when(
        gdp_per_capita >= 20000 ~ "High Income",
        gdp_per_capita >= 10000 ~ "Upper Middle Income",
        gdp_per_capita >= 3000 ~ "Lower Middle Income",
        gdp_per_capita >= 1000 ~ "Low Income",
        TRUE ~ "Very Low Income"
      ),
      development_level = factor(development_level, levels = c("Very Low Income", "Low Income", "Lower Middle Income", "Upper Middle Income", "High Income")),
      
      # Create poverty risk categories
      poverty_risk = case_when(
        poverty_rate >= 30 ~ "Critical",
        poverty_rate >= 15 ~ "High",
        poverty_rate >= 5 ~ "Medium",
        poverty_rate >= 1 ~ "Low",
        TRUE ~ "Very Low"
      ),
      poverty_risk = factor(poverty_risk, levels = c("Very Low", "Low", "Medium", "High", "Critical"))
    )
  
  cat("✅ World Bank data processed successfully!\n")
  cat("📊 Countries with World Bank data:", nrow(wb_summary), "\n")
  
  return(wb_summary)
}

# Process the data
fao_processed <- process_fao_data()
wb_summary <- process_worldbank_data()

# Create FAO summary data
fao_summary <- fao_processed %>%
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
    hunger_risk = factor(hunger_risk, levels = c("Very Low", "Low", "Medium", "High", "Critical"))
  )

# Create a mapping between FAO and World Bank country names
country_mapping <- data.frame(
  fao_name = c("Afghanistan", "Albania", "Algeria", "Angola", "Argentina", "Armenia", "Australia", "Austria", "Azerbaijan", "Bangladesh", "Belarus", "Belgium", "Benin", "Bolivia (Plurinational State of)", "Brazil", "Bulgaria", "Burkina Faso", "Burundi", "Cambodia", "Cameroon", "Canada", "Central African Republic", "Chad", "Chile", "China, mainland", "Colombia", "Congo", "Costa Rica", "Côte d'Ivoire", "Croatia", "Cuba", "Czechia", "Democratic Republic of the Congo", "Denmark", "Dominican Republic", "Ecuador", "Egypt", "El Salvador", "Ethiopia", "Finland", "France", "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Greece", "Guatemala", "Guinea", "Guinea-Bissau", "Haiti", "Honduras", "Hungary", "India", "Indonesia", "Iran (Islamic Republic of)", "Iraq", "Ireland", "Israel", "Italy", "Jamaica", "Japan", "Jordan", "Kazakhstan", "Kenya", "Kyrgyzstan", "Lao People's Democratic Republic", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Lithuania", "Luxembourg", "Madagascar", "Malawi", "Malaysia", "Mali", "Malta", "Mauritania", "Mauritius", "Mexico", "Mongolia", "Morocco", "Mozambique", "Myanmar", "Namibia", "Nepal", "Netherlands (Kingdom of the)", "New Zealand", "Nicaragua", "Niger", "Nigeria", "Norway", "Pakistan", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Poland", "Portugal", "Republic of Korea", "Republic of Moldova", "Romania", "Russian Federation", "Rwanda", "Saudi Arabia", "Senegal", "Serbia", "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "South Africa", "Spain", "Sri Lanka", "Sudan", "Sweden", "Switzerland", "Syrian Arab Republic", "Tajikistan", "Thailand", "Togo", "Tunisia", "Türkiye", "Turkmenistan", "Uganda", "Ukraine", "United Kingdom of Great Britain and Northern Ireland", "United States of America", "Uruguay", "Uzbekistan", "Venezuela (Bolivarian Republic of)", "Viet Nam", "Yemen", "Zambia", "Zimbabwe"),
  wb_name = c("Afghanistan", "Albania", "Algeria", "Angola", "Argentina", "Armenia", "Australia", "Austria", "Azerbaijan", "Bangladesh", "Belarus", "Belgium", "Benin", "Bolivia", "Brazil", "Bulgaria", "Burkina Faso", "Burundi", "Cambodia", "Cameroon", "Canada", "Central African Republic", "Chad", "Chile", "China", "Colombia", "Congo, Rep.", "Costa Rica", "Cote d'Ivoire", "Croatia", "Cuba", "Czech Republic", "Congo, Dem. Rep.", "Denmark", "Dominican Republic", "Ecuador", "Egypt, Arab Rep.", "El Salvador", "Ethiopia", "Finland", "France", "Gabon", "Gambia, The", "Georgia", "Germany", "Ghana", "Greece", "Guatemala", "Guinea", "Guinea-Bissau", "Haiti", "Honduras", "Hungary", "India", "Indonesia", "Iran, Islamic Rep.", "Iraq", "Ireland", "Israel", "Italy", "Jamaica", "Japan", "Jordan", "Kazakhstan", "Kenya", "Kyrgyz Republic", "Lao PDR", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Lithuania", "Luxembourg", "Madagascar", "Malawi", "Malaysia", "Mali", "Malta", "Mauritania", "Mauritius", "Mexico", "Mongolia", "Morocco", "Mozambique", "Myanmar", "Namibia", "Nepal", "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "Norway", "Pakistan", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Poland", "Portugal", "Korea, Rep.", "Moldova", "Romania", "Russian Federation", "Rwanda", "Saudi Arabia", "Senegal", "Serbia", "Sierra Leone", "Singapore", "Slovak Republic", "Slovenia", "South Africa", "Spain", "Sri Lanka", "Sudan", "Sweden", "Switzerland", "Syrian Arab Republic", "Tajikistan", "Thailand", "Togo", "Tunisia", "Turkey", "Turkmenistan", "Uganda", "Ukraine", "United Kingdom", "United States", "Uruguay", "Uzbekistan", "Venezuela, RB", "Vietnam", "Yemen, Rep.", "Zambia", "Zimbabwe"),
  stringsAsFactors = FALSE
)

# Combine the datasets
cat("🔄 Combining FAO and World Bank data...\n")

combined_data <- fao_summary %>%
  left_join(country_mapping, by = c("Area" = "fao_name")) %>%
  left_join(wb_summary, by = c("wb_name" = "country")) %>%
  filter(!is.na(wb_name)) %>%
  mutate(
    # Create combined risk assessment
    combined_risk = case_when(
      hunger_risk == "Critical" | poverty_risk == "Critical" ~ "Critical",
      hunger_risk == "High" | poverty_risk == "High" ~ "High",
      hunger_risk == "Medium" | poverty_risk == "Medium" ~ "Medium",
      hunger_risk == "Low" | poverty_risk == "Low" ~ "Low",
      TRUE ~ "Very Low"
    ),
    combined_risk = factor(combined_risk, levels = c("Very Low", "Low", "Medium", "High", "Critical"))
  )

cat("✅ Combined dataset created successfully!\n")
cat("📊 Countries with both FAO and World Bank data:", nrow(combined_data), "\n")

# UI
ui <- fluidPage(
  titlePanel("🌍 FAO-World Bank Combined Global Hunger Research Dashboard"),
  
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
                 choices = c("All", sort(unique(combined_data$Area))),
                 selected = "All", multiple = TRUE),
      selectInput("risk_level", "Combined Risk Level:", 
                 choices = c("All", "Very Low", "Low", "Medium", "High", "Critical"),
                 selected = "All"),
      selectInput("development_level", "Development Level:", 
                 choices = c("All", "Very Low Income", "Low Income", "Lower Middle Income", "Upper Middle Income", "High Income"),
                 selected = "All"),
      selectInput("region", "Region:", 
                 choices = c("All", sort(unique(combined_data$region[!is.na(combined_data$region)]))),
                 selected = "All"),
      br(),
      h4("📊 Key Statistics", style = "color: #2c3e50; font-weight: bold;"),
      verbatimTextOutput("stats_summary"),
      br(),
      h4("ℹ️ About", style = "color: #2c3e50; font-weight: bold;"),
      p("This dashboard combines FAO food security data with World Bank economic and health indicators."),
      p("Data sources: FAO + World Bank"),
      p("Research by: Garrett Zhou"),
      br(),
      h4("🎯 Risk Levels:", style = "color: #2c3e50; font-weight: bold;"),
      p("🔴 Critical: High hunger OR poverty risk"),
      p("🟠 High: Significant hunger OR poverty issues"),
      p("🟡 Medium: Moderate concerns"),
      p("🟢 Low: Minor issues"),
      p("⚪ Very Low: Minimal concerns")
    ),
    
    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel("📊 Overview",
          fluidRow(
            column(6, 
              h4("Countries by Combined Risk"),
              p("This chart shows how countries are distributed across different combined risk levels, which considers both hunger (undernourishment) and poverty indicators. Countries are categorized from Very Low to Critical risk based on their FAO hunger data and World Bank poverty data.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              plotlyOutput("risk_plot", height = "400px")
            ),
            column(6,
              h4("Hunger vs Poverty Correlation"),
              p("This scatter plot examines the relationship between undernourishment rates (FAO data) and poverty rates (World Bank data). Each point represents a country, and the color indicates the combined risk level. This helps identify whether hunger and poverty are correlated.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              plotlyOutput("hunger_poverty_plot", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(6,
              h4("GDP vs Undernourishment"),
              p("This chart explores the relationship between economic development (GDP per capita from World Bank) and hunger levels (undernourishment rates from FAO). Generally, higher GDP countries should have lower hunger rates, but this chart reveals any exceptions to this pattern.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              plotlyOutput("gdp_hunger_plot", height = "350px")
            ),
            column(6,
              h4("Life Expectancy by Risk Level"),
              p("This box plot shows how life expectancy (World Bank data) varies across different combined risk levels. It demonstrates the health impact of hunger and poverty, as countries with higher combined risk typically have lower life expectancy.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              plotlyOutput("life_expectancy_plot", height = "350px")
            )
          ),
          br(),
          fluidRow(
            column(12,
              h4("📋 Combined Data Table"),
              DT::dataTableOutput("data_table")
            )
          )
        ),
        
        tabPanel("🏥 Health & Development",
          fluidRow(
            column(6,
              h4("Life Expectancy vs GDP per Capita"),
              p("This scatter plot shows the relationship between economic development (GDP per capita) and health outcomes (life expectancy). Countries with higher GDP generally have longer life expectancy, but this chart reveals any outliers or exceptions to this pattern.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              plotlyOutput("life_gdp_plot", height = "400px")
            ),
            column(6,
              h4("Poverty Rates by Region"),
              p("This box plot compares poverty rates across different world regions using World Bank data. It helps identify which regions have the highest poverty levels and shows the variation within each region. The boxes show the median and quartiles for each region.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              plotlyOutput("poverty_region_plot", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(6,
              h4("Agricultural Land vs Rural Population"),
              p("This scatter plot examines the relationship between agricultural land use and rural population percentage. Countries with more agricultural land might have different rural population patterns, which can indicate agricultural development and urbanization trends.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              plotlyOutput("agriculture_rural_plot", height = "350px")
            ),
            column(6,
              h4("Development Level Distribution"),
              p("This bar chart shows how countries are distributed across different development levels based on GDP per capita. The World Bank classifies countries into income groups from Very Low Income to High Income, which helps understand global economic development patterns.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              plotlyOutput("development_plot", height = "350px")
            )
          )
        ),
        
        tabPanel("🌍 World Map",
          fluidRow(
            column(12,
              h4("Interactive World Map - Combined Risk Analysis"),
              p("This interactive world map displays countries colored by their undernourishment rates (FAO data), with comprehensive hover information that combines both FAO food security indicators and World Bank economic/health data. Hover over any country to see detailed statistics including hunger rates, poverty levels, life expectancy, GDP, and combined risk assessments.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
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
            column(12,
              p("This time series analysis allows you to compare different indicators across countries or view global averages. Select from FAO hunger indicators (undernourishment rate) or World Bank economic/health indicators (GDP, poverty, life expectancy, population, agricultural land). Choose 'All' countries to see global averages, or select specific countries for comparison.", style = "color: #666; font-size: 14px; margin-bottom: 15px;")
            )
          ),
          fluidRow(
            column(8,
              plotlyOutput("timeseries_plot", height = "500px")
            ),
            column(4,
              h4("Variable Selection"),
              selectInput("variable", "Select Indicator:", 
                         choices = c("Undernourishment Rate" = "undernourishment_rate",
                                   "GDP per Capita" = "gdp_per_capita",
                                   "Poverty Rate" = "poverty_rate",
                                   "Life Expectancy" = "life_expectancy",
                                   "Population" = "population",
                                   "Agricultural Land" = "agriculture_land")),
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
              h4("Interactive Combined Data Explorer"),
              p("This comprehensive data table contains all the combined FAO and World Bank indicators for each country. You can filter, sort, and search through the data to explore specific countries, risk levels, or development categories. The table includes hunger indicators from FAO, economic indicators from World Bank, and our combined risk assessments.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
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
              h3("🌍 FAO-World Bank Combined Global Hunger Research Project"),
              p("This interactive dashboard integrates data from both the Food and Agriculture Organization (FAO) and the World Bank to provide comprehensive analysis of global hunger, food security, and economic development patterns."),
              
              h4("🎯 Research Question:"),
              p("What factors drive hunger and how do they correlate with economic development and health outcomes?"),
              
              h4("📊 Data Sources:"),
              tags$ul(
                tags$li("FAO - Food security and undernourishment data"),
                tags$li("World Bank - Economic indicators (GDP, poverty, life expectancy)"),
                tags$li("World Bank - Demographic indicators (population, rural population)"),
                tags$li("World Bank - Agricultural indicators (agricultural land use)")
              ),
              
              h4("🔧 Key Indicators:"),
              tags$ul(
                tags$li("Undernourishment Rate: FAO measure of hunger"),
                tags$li("GDP per Capita: World Bank economic development indicator"),
                tags$li("Poverty Rate: World Bank measure of extreme poverty"),
                tags$li("Life Expectancy: World Bank health indicator"),
                tags$li("Population: World Bank demographic indicator"),
                tags$li("Agricultural Land: World Bank agricultural indicator")
              ),
              
              h4("📈 Methodology:"),
              tags$ul(
                tags$li("Multi-dimensional risk assessment combining hunger and poverty"),
                tags$li("Correlation analysis between food security and economic development"),
                tags$li("Geographic pattern analysis by region"),
                tags$li("Economic development correlation studies")
              ),
              
              h4("👨‍💻 Author:"),
              p("Garrett Zhou - Research Project 2024"),
              
              h4("🛠️ Technology Stack:"),
              tags$ul(
                tags$li("R and RStudio for data analysis"),
                tags$li("Shiny for web application"),
                tags$li("Plotly for interactive visualizations"),
                tags$li("FAO Food Security Indicators database"),
                tags$li("World Bank Development Indicators")
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
    data <- combined_data
    
    if(!("All" %in% input$countries)) {
      data <- data %>% filter(Area %in% input$countries)
    }
    
    if(input$risk_level != "All") {
      data <- data %>% filter(combined_risk == input$risk_level)
    }
    
    if(input$development_level != "All") {
      data <- data %>% filter(development_level == input$development_level)
    }
    
    if(input$region != "All") {
      data <- data %>% filter(region == input$region)
    }
    
    return(data)
  })
  
  # Statistics summary
  output$stats_summary <- renderText({
    data <- filtered_data()
    paste(
      "Countries:", nrow(data), "\n",
      "Critical Risk Countries:", sum(data$combined_risk == "Critical", na.rm = TRUE), "\n",
      "Avg Undernourishment:", round(mean(data$undernourishment_rate, na.rm = TRUE), 1), "%\n",
      "Avg Poverty Rate:", round(mean(data$poverty_rate, na.rm = TRUE), 1), "%\n",
      "Avg Life Expectancy:", round(mean(data$life_expectancy, na.rm = TRUE), 1), "years\n",
      "Avg GDP per Capita: $", round(mean(data$gdp_per_capita, na.rm = TRUE), 0)
    )
  })
  
  # Risk distribution plot
  output$risk_plot <- renderPlotly({
    risk_counts <- filtered_data() %>%
      count(combined_risk) %>%
      mutate(percentage = n / sum(n) * 100)
    
    plot_ly(risk_counts, x = ~combined_risk, y = ~n, type = "bar",
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Count:", n, "<br>Percentage:", round(percentage, 1), "%"),
            hoverinfo = "text") %>%
      layout(
        title = list(
          text = "Combined Hunger & Poverty Risk Distribution",
          font = list(size = 16)
        ),
        xaxis = list(title = "Combined Risk Level"),
        yaxis = list(title = "Number of Countries"),
        showlegend = FALSE,
        margin = list(t = 80, b = 60, l = 60, r = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Hunger vs Poverty correlation plot
  output$hunger_poverty_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~undernourishment_rate, 
            y = ~poverty_rate,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Country:", Area, 
                         "<br>Undernourishment:", round(undernourishment_rate, 1), "%",
                         "<br>Poverty Rate:", round(poverty_rate, 1), "%"),
            hoverinfo = "text",
            type = "scatter", mode = "markers") %>%
      layout(
        title = list(
          text = "Undernourishment vs Poverty Rate",
          font = list(size = 16)
        ),
        xaxis = list(title = "Undernourishment Rate (%)"),
        yaxis = list(title = "Poverty Rate (%)"),
        margin = list(t = 80, b = 60, l = 60, r = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # GDP vs Hunger plot
  output$gdp_hunger_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~gdp_per_capita, 
            y = ~undernourishment_rate,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Country:", Area, 
                         "<br>GDP per Capita: $", round(gdp_per_capita, 0),
                         "<br>Undernourishment:", round(undernourishment_rate, 1), "%"),
            hoverinfo = "text",
            type = "scatter", mode = "markers") %>%
      layout(
        title = list(
          text = "GDP per Capita vs Undernourishment Rate",
          font = list(size = 16)
        ),
        xaxis = list(title = "GDP per Capita (USD)"),
        yaxis = list(title = "Undernourishment Rate (%)"),
        margin = list(t = 80, b = 60, l = 60, r = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Life expectancy plot
  output$life_expectancy_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~combined_risk, 
            y = ~life_expectancy,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            type = "box") %>%
      layout(
        title = list(
          text = "Life Expectancy by Combined Risk Level",
          font = list(size = 16)
        ),
        xaxis = list(title = "Combined Risk Level"),
        yaxis = list(title = "Life Expectancy (years)"),
        showlegend = FALSE,
        margin = list(t = 80, b = 60, l = 60, r = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Life expectancy vs GDP plot
  output$life_gdp_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~gdp_per_capita, 
            y = ~life_expectancy,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Country:", Area, 
                         "<br>GDP per Capita: $", round(gdp_per_capita, 0),
                         "<br>Life Expectancy:", round(life_expectancy, 1), "years"),
            hoverinfo = "text",
            type = "scatter", mode = "markers") %>%
      layout(
        title = list(
          text = "Life Expectancy vs GDP per Capita",
          font = list(size = 16)
        ),
        xaxis = list(title = "GDP per Capita (USD)"),
        yaxis = list(title = "Life Expectancy (years)"),
        margin = list(t = 80, b = 60, l = 60, r = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Poverty by region plot
  output$poverty_region_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~region, 
            y = ~poverty_rate,
            color = ~region,
            type = "box") %>%
      layout(
        title = list(
          text = "Poverty Rates by Region",
          font = list(size = 16)
        ),
        xaxis = list(title = "Region"),
        yaxis = list(title = "Poverty Rate (%)"),
        showlegend = FALSE,
        margin = list(t = 80, b = 60, l = 60, r = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Agriculture vs Rural plot
  output$agriculture_rural_plot <- renderPlotly({
    plot_ly(filtered_data(), 
            x = ~agriculture_land, 
            y = ~rural_population,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Country:", Area, 
                         "<br>Agricultural Land:", round(agriculture_land, 1), "%",
                         "<br>Rural Population:", round(rural_population, 1), "%"),
            hoverinfo = "text",
            type = "scatter", mode = "markers") %>%
      layout(
        title = list(
          text = "Agricultural Land vs Rural Population",
          font = list(size = 16)
        ),
        xaxis = list(title = "Agricultural Land (% of total land)"),
        yaxis = list(title = "Rural Population (% of total)"),
        margin = list(t = 80, b = 60, l = 60, r = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Development level plot
  output$development_plot <- renderPlotly({
    dev_counts <- filtered_data() %>%
      count(development_level) %>%
      mutate(percentage = n / sum(n) * 100)
    
    plot_ly(dev_counts, x = ~development_level, y = ~n, type = "bar",
            color = ~development_level,
            text = ~paste("Count:", n, "<br>Percentage:", round(percentage, 1), "%"),
            hoverinfo = "text") %>%
      layout(
        title = list(
          text = "Development Level Distribution",
          font = list(size = 16)
        ),
        xaxis = list(title = "Development Level"),
        yaxis = list(title = "Number of Countries"),
        showlegend = FALSE,
        margin = list(t = 80, b = 60, l = 60, r = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Data table
  output$data_table <- DT::renderDataTable({
    DT::datatable(
      filtered_data() %>%
        select(Area, undernourishment_rate, poverty_rate, 
               life_expectancy, gdp_per_capita, population, 
               combined_risk, development_level, region) %>%
        mutate(
          undernourishment_rate = round(undernourishment_rate, 1),
          poverty_rate = round(poverty_rate, 1),
          life_expectancy = round(life_expectancy, 1),
          gdp_per_capita = round(gdp_per_capita, 0),
          population = round(population / 1e6, 1)
        ) %>%
        rename(
          Country = Area,
          "Undernourishment (%)" = undernourishment_rate,
          "Poverty Rate (%)" = poverty_rate,
          "Life Expectancy (years)" = life_expectancy,
          "GDP per Capita ($)" = gdp_per_capita,
          "Population (M)" = population,
          "Combined Risk" = combined_risk,
          "Development Level" = development_level,
          "Region" = region
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
  
  # World map
  output$world_map <- renderPlotly({
    # Create map data with combined information
    map_data <- filtered_data() %>%
      mutate(
        # Create hover text with combined FAO-World Bank information
        hover_text = paste(
          "<b>", Area, "</b><br>",
          "Undernourishment Rate: ", round(undernourishment_rate, 1), "%<br>",
          "Poverty Rate: ", round(poverty_rate, 1), "%<br>",
          "Life Expectancy: ", round(life_expectancy, 1), " years<br>",
          "GDP per Capita: $", format(round(gdp_per_capita, 0), big.mark = ","), "<br>",
          "Population: ", format(round(population / 1e6, 1), big.mark = ","), "M<br>",
          "Combined Risk Level: ", combined_risk, "<br>",
          "Development Level: ", development_level, "<br>",
          "Region: ", region
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
          text = "Combined FAO-World Bank Global Risk Map (Hover for Details)",
          font = list(size = 16)
        ),
        geo = list(
          showframe = FALSE,
          showcoastlines = TRUE,
          projection = list(type = "natural earth"),
          bgcolor = "#f8f9fa"
        ),
        margin = list(t = 80, b = 60, l = 60, r = 60)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Country details
  output$country_details <- renderUI({
    HTML("
    <div style='background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-top: 20px;'>
      <h4>🌍 Combined FAO-World Bank World Map Instructions</h4>
      <p><strong>How to use this map:</strong></p>
      <ul>
        <li><strong>Hover over any country</strong> to see detailed FAO and World Bank information:</li>
        <ul>
          <li>🍽️ Undernourishment rate (FAO hunger measure)</li>
          <li>💰 Poverty rate (World Bank economic indicator)</li>
          <li>⏰ Life expectancy (World Bank health indicator)</li>
          <li>💵 GDP per capita (World Bank economic indicator)</li>
          <li>👥 Population (World Bank demographic indicator)</li>
          <li>⚠️ Combined risk assessment</li>
          <li>🏗️ Development level classification</li>
          <li>🌍 Regional classification</li>
        </ul>
        <li><strong>Color coding:</strong> Countries are colored by undernourishment rate</li>
        <li><strong>Green:</strong> Low hunger risk (undernourishment < 10%)</li>
        <li><strong>Yellow:</strong> Medium hunger risk (undernourishment 10-15%)</li>
        <li><strong>Red:</strong> High hunger risk (undernourishment 15-25%)</li>
        <li><strong>Dark Red:</strong> Critical hunger risk (undernourishment ≥ 25%)</li>
      </ul>
      <p><em>This map combines real FAO food security data with World Bank economic and health indicators, providing the most comprehensive view of global hunger and development patterns.</em></p>
    </div>
    ")
  })
  
  # Time series plot
  output$timeseries_plot <- renderPlotly({
    # For time series, we'll use the latest available data
    data <- filtered_data()
    
    if("All" %in% input$countries) {
      # Global average
      global_avg <- data %>%
        summarise(
          variable_value = mean(get(input$variable), na.rm = TRUE),
          .groups = "drop"
        )
      
      p <- plot_ly(x = 2022, y = global_avg$variable_value, 
                   type = "scatter", mode = "markers",
                   marker = list(color = "#3c8dbc", size = 10),
                   name = "Global Average",
                   text = paste("Global Average:", round(global_avg$variable_value, 2)),
                   hoverinfo = "text") %>%
        layout(
          title = list(
            text = paste("Global Average:", input$variable),
            font = list(size = 16)
          ),
          xaxis = list(title = "Year", range = c(2021, 2023)),
          yaxis = list(title = input$variable),
          margin = list(t = 80, b = 60, l = 60, r = 60)
        ) %>%
        config(displayModeBar = FALSE)
      
    } else {
      # Selected countries
      country_data <- data %>%
        filter(Area %in% input$countries)
      
      p <- plot_ly(country_data, x = rep(2022, nrow(country_data)), 
                   y = ~get(input$variable),
                   color = ~Area, type = "scatter", mode = "markers",
                   text = ~paste("Country:", Area, "<br>Value:", round(get(input$variable), 2)),
                   hoverinfo = "text") %>%
        layout(
          title = list(
            text = paste("Country Comparison:", input$variable),
            font = list(size = 16)
          ),
          xaxis = list(title = "Year", range = c(2021, 2023)),
          yaxis = list(title = input$variable),
          margin = list(t = 80, b = 60, l = 60, r = 60)
        ) %>%
        config(displayModeBar = FALSE)
    }
    
    p
  })
  
  # Data summary
  output$data_summary <- renderText({
    summary_text <- capture.output(summary(filtered_data() %>%
                                           select(undernourishment_rate, poverty_rate, 
                                                  life_expectancy, gdp_per_capita, 
                                                  population, agriculture_land)))
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
cat("🌍 Starting FAO-World Bank Combined Global Hunger Research Website...\n")
cat("====================================================================\n")
cat("✅ FAO data loaded successfully!\n")
cat("✅ World Bank data loaded successfully!\n")
cat("📊 Countries with combined data:", nrow(combined_data), "\n")
cat("\n🌐 WEBSITE URL: http://localhost:3840\n")
cat("📱 Alternative: http://127.0.0.1:3840\n")
cat("🔗 Copy and paste this URL into your browser!\n")
cat("🛑 To stop the server, press Ctrl+C in the terminal.\n\n")

shinyApp(ui = ui, server = server)
