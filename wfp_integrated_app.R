# WFP-Enhanced Global Hunger Research Website
# Integrates FAO, World Bank, and WFP data for comprehensive analysis

library(shiny)
library(plotly)
library(DT)
library(tidyverse)
library(readr)

# Load and process data
cat("🌍 Loading FAO, World Bank, and WFP Data...\n")

# Load FAO data
fao_main <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data_NOFLAG.csv", show_col_types = FALSE)

# Load World Bank data
wb_raw_data <- read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE)

# Load WFP data
wfp_markets <- read_csv("data/raw/wfp/markets.csv", show_col_types = FALSE)
wfp_commodities <- read_csv("data/raw/wfp/commodities.csv", show_col_types = FALSE)

# Define key indicators and year columns
key_indicators <- c(
  "210041" = "Prevalence of undernourishment",
  "210401" = "Prevalence of severe food insecurity",
  "210091" = "Prevalence of moderate or severe food insecurity",
  "21010" = "Dietary energy supply adequacy",
  "21035" = "Cereal import dependency ratio",
  "21033" = "Food import value ratio"
)

# Get 3-year average columns from the data (where the actual data is)
year_cols <- c("Y20002002", "Y20012003", "Y20022004", "Y20032005", "Y20042006", "Y20052007", "Y20062008", "Y20072009", "Y20082010", "Y20092011", "Y20102012", "Y20112013", "Y20122014", "Y20132015", "Y20142016", "Y20152017", "Y20162018", "Y20172019", "Y20182020", "Y20192021", "Y20202022", "Y20212023", "Y20222024")

# Process FAO data
process_fao_data <- function() {
  fao_processed <- fao_main %>%
    filter(`Item Code` %in% names(key_indicators) & `Element Code` == 6121) %>%
    select(Area, `Item Code`, Item, Element, Unit, all_of(year_cols)) %>%
    pivot_longer(cols = all_of(year_cols), 
                 names_to = "Year", 
                 values_to = "Value") %>%
    mutate(Year = as.numeric(substr(Year, 2, 5)),  # Extract start year from Y20002002 format
           Value = as.numeric(Value)) %>%
    filter(!is.na(Value) & Value != 0) %>%
    pivot_wider(names_from = `Item Code`, values_from = Value, names_prefix = "ind_")
  
  return(fao_processed)
}

# Process World Bank data
process_worldbank_data <- function() {
  wb_summary <- wb_raw_data %>%
    group_by(country) %>%
    summarise(
      latest_year_wb = max(year, na.rm = TRUE),
      population = last(SP.POP.TOTL, order_by = year),
      gdp_per_capita = last(NY.GDP.PCAP.CD, order_by = year),
      poverty_rate = last(SI.POV.DDAY, order_by = year),
      life_expectancy = last(SP.DYN.LE00.IN, order_by = year),
      agriculture_land = last(AG.LND.AGRI.ZS, order_by = year),
      rural_population = last(SP.RUR.TOTL.ZS, order_by = year),
      .groups = "drop"
    ) %>%
    filter(!is.na(population)) %>%
    mutate(
      # Create development level categories
      development_level = case_when(
        gdp_per_capita < 1045 ~ "Very Low Income",
        gdp_per_capita < 4095 ~ "Low Income", 
        gdp_per_capita < 12695 ~ "Lower Middle Income",
        gdp_per_capita < 40955 ~ "Upper Middle Income",
        TRUE ~ "High Income"
      ),
      development_level = factor(development_level, levels = c("Very Low Income", "Low Income", "Lower Middle Income", "Upper Middle Income", "High Income")),
      
      # Create region categories
      region = case_when(
        country %in% c("Afghanistan", "Bangladesh", "Bhutan", "India", "Maldives", "Nepal", "Pakistan", "Sri Lanka") ~ "South Asia",
        country %in% c("China", "Japan", "Korea, Rep.", "Mongolia", "Thailand", "Vietnam", "Indonesia", "Malaysia", "Philippines", "Singapore", "Viet Nam", "Republic of Korea") ~ "East Asia & Pacific",
        country %in% c("Algeria", "Egypt", "Morocco", "Tunisia", "Libya", "Sudan", "Ethiopia", "Kenya", "Nigeria", "South Africa", "Somalia", "Yemen", "South Sudan", "Madagascar", "Democratic Republic of the Congo", "Central African Republic", "Chad", "Mali", "Burkina Faso", "Niger") ~ "Africa",
        country %in% c("Brazil", "Argentina", "Chile", "Colombia", "Mexico", "Peru", "Venezuela", "Haiti", "Bolivia", "Venezuela, RB", "Bolivia (Plurinational State of)") ~ "Latin America & Caribbean",
        country %in% c("United States", "Canada", "United States of America") ~ "North America",
        country %in% c("Germany", "France", "United Kingdom", "Italy", "Spain", "Poland", "Russia", "Russian Federation", "Albania", "Armenia", "Azerbaijan", "Belarus", "Bulgaria", "Croatia", "Czech Republic", "Estonia", "Georgia", "Hungary", "Kazakhstan", "Kyrgyz Republic", "Latvia", "Lithuania", "Moldova", "Montenegro", "North Macedonia", "Romania", "Serbia", "Slovak Republic", "Slovenia", "Tajikistan", "Turkey", "Turkmenistan", "Ukraine", "Uzbekistan") ~ "Europe & Central Asia",
        TRUE ~ "Other"
      )
    )
  
  return(wb_summary)
}

# Process WFP data
process_wfp_data <- function() {
  # Process market data
  wfp_market_summary <- wfp_markets %>%
    group_by(Country) %>%
    summarise(
      total_markets = n(),
      total_population_served = sum(Population, na.rm = TRUE),
      avg_market_population = mean(Population, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      # Create market access categories
      market_access = case_when(
        total_markets >= 100 ~ "High Market Access",
        total_markets >= 50 ~ "Medium Market Access",
        total_markets >= 10 ~ "Low Market Access",
        TRUE ~ "Very Low Market Access"
      ),
      market_access = factor(market_access, levels = c("Very Low Market Access", "Low Market Access", "Medium Market Access", "High Market Access"))
    )
  
  # Process commodity data
  wfp_commodity_summary <- wfp_commodities %>%
    mutate(
      # Categorize commodities
      commodity_category = case_when(
        str_detect(Name, "(Rice|Wheat|Maize|Corn|Cereal|Grain)") ~ "Cereals",
        str_detect(Name, "(Bean|Lentil|Pea|Pulse)") ~ "Pulses",
        str_detect(Name, "(Milk|Cheese|Dairy)") ~ "Dairy",
        str_detect(Name, "(Fish|Meat|Chicken|Beef)") ~ "Protein",
        str_detect(Name, "(Potato|Onion|Tomato|Vegetable)") ~ "Vegetables",
        str_detect(Name, "(Oil|Fat)") ~ "Fats & Oils",
        TRUE ~ "Other"
      )
    ) %>%
    count(commodity_category) %>%
    mutate(percentage = n / sum(n) * 100)
  
  return(list(
    markets = wfp_market_summary,
    commodities = wfp_commodity_summary,
    raw_markets = wfp_markets,
    raw_commodities = wfp_commodities
  ))
}

# Add 21st century hunger outbreak data
add_hunger_outbreaks <- function(data) {
  # Major hunger outbreaks in 21st century (based on historical data)
  hunger_outbreaks <- data.frame(
    Area = c("Somalia", "Yemen", "South Sudan", "Nigeria", "Ethiopia", 
             "Afghanistan", "Haiti", "Madagascar", "Democratic Republic of the Congo",
             "Central African Republic", "Chad", "Mali", "Burkina Faso", "Niger"),
    major_hunger_outbreak_21st = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
    outbreak_years = c("2011, 2017, 2022", "2016-2023", "2017-2023", "2016-2018", "2015-2016, 2020-2022",
                      "2001-2002, 2018-2021", "2008, 2010, 2016", "2021-2022", "2017-2019",
                      "2013-2014, 2018-2020", "2010, 2017-2018", "2012, 2018-2020", "2012, 2018-2020", "2005, 2010, 2018-2020")
  )
  
  data <- data %>%
    left_join(hunger_outbreaks, by = "Area") %>%
    mutate(
      major_hunger_outbreak_21st = ifelse(is.na(major_hunger_outbreak_21st), FALSE, major_hunger_outbreak_21st),
      outbreak_years = ifelse(is.na(outbreak_years), "None", outbreak_years)
    )
  
  return(data)
}

# Process the data
fao_processed <- process_fao_data()
wb_summary <- process_worldbank_data()
wfp_data <- process_wfp_data()

# Create FAO summary data
fao_summary <- fao_processed %>%
  group_by(Area) %>%
  summarise(
    latest_year_fao = max(Year, na.rm = TRUE),
    undernourishment_rate = last(ind_210041, order_by = Year),
    severe_food_insecurity = last(ind_210401, order_by = Year),
    moderate_severe_food_insecurity = last(ind_210091, order_by = Year),
    dietary_energy_adequacy = last(ind_21010, order_by = Year),
    cereal_import_dependency = last(ind_21035, order_by = Year),
    food_import_value = last(ind_21033, order_by = Year),
    .groups = "drop"
  ) %>%
  filter(!is.na(undernourishment_rate))

# Create comprehensive country list from all datasets
all_countries <- unique(c(fao_summary$Area, wb_summary$country, wfp_data$markets$Country))

# Create base dataset with all countries
all_countries_data <- data.frame(Area = all_countries) %>%
  # Add FAO data
  left_join(fao_summary, by = "Area") %>%
  # Add World Bank data
  left_join(wb_summary, by = c("Area" = "country")) %>%
  # Add WFP market data
  left_join(wfp_data$markets, by = c("Area" = "Country")) %>%
  # Add hunger outbreak data
  add_hunger_outbreaks() %>%
  mutate(
    # Create combined risk assessment (handle missing data)
    combined_risk = case_when(
      (!is.na(undernourishment_rate) & undernourishment_rate >= 25) | (!is.na(poverty_rate) & poverty_rate >= 30) ~ "Critical",
      (!is.na(undernourishment_rate) & undernourishment_rate >= 15) | (!is.na(poverty_rate) & poverty_rate >= 15) ~ "High",
      (!is.na(undernourishment_rate) & undernourishment_rate >= 10) | (!is.na(poverty_rate) & poverty_rate >= 5) ~ "Medium",
      (!is.na(undernourishment_rate) & undernourishment_rate >= 5) | (!is.na(poverty_rate) & poverty_rate >= 1) ~ "Low",
      TRUE ~ "Very Low"
    ),
    combined_risk = factor(combined_risk, levels = c("Very Low", "Low", "Medium", "High", "Critical")),
    
    # Create region categories for all countries
    region = case_when(
      Area %in% c("Afghanistan", "Bangladesh", "Bhutan", "India", "Maldives", "Nepal", "Pakistan", "Sri Lanka") ~ "South Asia",
      Area %in% c("China", "Japan", "Korea, Rep.", "Mongolia", "Thailand", "Vietnam", "Indonesia", "Malaysia", "Philippines", "Singapore", "Viet Nam", "Republic of Korea") ~ "East Asia & Pacific",
      Area %in% c("Algeria", "Egypt", "Morocco", "Tunisia", "Libya", "Sudan", "Ethiopia", "Kenya", "Nigeria", "South Africa", "Somalia", "Yemen", "South Sudan", "Madagascar", "Democratic Republic of the Congo", "Central African Republic", "Chad", "Mali", "Burkina Faso", "Niger") ~ "Africa",
      Area %in% c("Brazil", "Argentina", "Chile", "Colombia", "Mexico", "Peru", "Venezuela", "Haiti", "Bolivia", "Venezuela, RB", "Bolivia (Plurinational State of)") ~ "Latin America & Caribbean",
      Area %in% c("United States", "Canada", "United States of America") ~ "North America",
      Area %in% c("Germany", "France", "United Kingdom", "Italy", "Spain", "Poland", "Russia", "Russian Federation", "Albania", "Armenia", "Azerbaijan", "Belarus", "Bulgaria", "Croatia", "Czech Republic", "Estonia", "Georgia", "Hungary", "Kazakhstan", "Kyrgyz Republic", "Latvia", "Lithuania", "Moldova", "Montenegro", "North Macedonia", "Romania", "Serbia", "Slovak Republic", "Slovenia", "Tajikistan", "Turkey", "Turkmenistan", "Ukraine", "Uzbekistan") ~ "Europe & Central Asia",
      TRUE ~ "Other"
    ),
    
    # Create development level categories (handle missing GDP data)
    development_level = case_when(
      !is.na(gdp_per_capita) & gdp_per_capita < 1045 ~ "Very Low Income",
      !is.na(gdp_per_capita) & gdp_per_capita < 4095 ~ "Low Income", 
      !is.na(gdp_per_capita) & gdp_per_capita < 12695 ~ "Lower Middle Income",
      !is.na(gdp_per_capita) & gdp_per_capita < 40955 ~ "Upper Middle Income",
      !is.na(gdp_per_capita) ~ "High Income",
      TRUE ~ "Unknown"
    ),
    development_level = factor(development_level, levels = c("Very Low Income", "Low Income", "Lower Middle Income", "Upper Middle Income", "High Income", "Unknown"))
  )

# Use the comprehensive dataset
combined_data <- all_countries_data

# Create time series data for trends
create_time_series_data <- function() {
  # FAO time series - use the processed data directly
  fao_timeseries <- fao_processed %>%
    select(Area, Year, ind_210041) %>%
    rename(undernourishment_rate = ind_210041) %>%
    filter(!is.na(undernourishment_rate))
  
  # World Bank time series
  wb_timeseries <- wb_raw_data %>%
    select(country, year, SP.POP.TOTL, NY.GDP.PCAP.CD, SI.POV.DDAY, SP.DYN.LE00.IN) %>%
    rename(
      Area = country,
      Year = year,
      population = SP.POP.TOTL,
      gdp_per_capita = NY.GDP.PCAP.CD,
      poverty_rate = SI.POV.DDAY,
      life_expectancy = SP.DYN.LE00.IN
    ) %>%
    filter(!is.na(population))
  
  # Combine time series
  timeseries_data <- fao_timeseries %>%
    full_join(wb_timeseries, by = c("Area", "Year"))
  
  return(timeseries_data)
}

timeseries_data <- create_time_series_data()

cat("✅ Data processing completed!\n")
cat("📊 Total countries in dataset:", nrow(combined_data), "\n")
cat("📊 Countries with FAO data:", sum(!is.na(combined_data$undernourishment_rate)), "\n")
cat("📊 Countries with World Bank data:", sum(!is.na(combined_data$population)), "\n")
cat("📊 Countries with WFP market data:", sum(!is.na(combined_data$total_markets)), "\n")
cat("📊 Countries with both FAO and World Bank data:", sum(!is.na(combined_data$undernourishment_rate) & !is.na(combined_data$population)), "\n")
cat("📈 Time series records:", nrow(timeseries_data), "\n")
cat("🏪 Total WFP markets:", nrow(wfp_markets), "\n")
cat("🍽️ Total WFP commodities:", nrow(wfp_commodities), "\n")

# UI
ui <- fluidPage(
  titlePanel("🌍 WFP-Enhanced Global Hunger Research Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("🌍 Global Overview"),
      p("This dashboard combines FAO hunger data, World Bank economic indicators, and WFP market data for comprehensive analysis."),
      
      br(),
      h4("🎯 Quick Stats"),
      verbatimTextOutput("quick_stats"),
      
      br(),
      h4("🔍 Filters"),
      selectInput("risk_filter", "Risk Level:",
                  choices = c("All", "Very Low", "Low", "Medium", "High", "Critical"),
                  selected = "All"),
      
      selectInput("region_filter", "Region:",
                  choices = c("All", unique(combined_data$region)),
                  selected = "All"),
      
      selectInput("development_filter", "Development Level:",
                  choices = c("All", levels(combined_data$development_level)),
                  selected = "All"),
      
      selectInput("market_access_filter", "Market Access:",
                  choices = c("All", levels(combined_data$market_access)),
                  selected = "All")
    ),
    
    mainPanel(
      width = 9,
      tabsetPanel(
        id = "main_tabs",
        
        tabPanel("🗺️ World Map",
          fluidRow(
            column(12,
              h4("Global Hunger & Development Map"),
              p("Click on any country to view detailed analysis. Countries are colored by undernourishment rate. Hover for key statistics including WFP market data.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              plotlyOutput("world_map", height = "600px")
            )
          )
        ),
        
        tabPanel("📈 Key Insights",
          fluidRow(
            column(12,
              h4("Global Hunger & Development Insights"),
              p("Key visualizations revealing patterns and relationships in global hunger, poverty, development, and market access data.", style = "color: #666; font-size: 14px; margin-bottom: 15px;")
            )
          ),
          fluidRow(
            column(6,
              h4("Hunger vs Poverty: The Critical Relationship"),
              p("This scatter plot reveals the strong correlation between undernourishment and poverty rates. Countries with higher poverty tend to have higher hunger rates, but there are notable exceptions that warrant further investigation.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_hunger_poverty", height = "400px")
            ),
            column(6,
              h4("Market Access vs Hunger Risk"),
              p("This analysis shows the relationship between WFP market access and hunger risk levels. Countries with better market access tend to have lower hunger risk, highlighting the importance of market connectivity.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_market_hunger", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(6,
              h4("WFP Market Coverage by Region"),
              p("This chart shows the distribution of WFP markets across different world regions, providing insight into where food security monitoring and market access are most developed.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_market_coverage", height = "400px")
            ),
            column(6,
              h4("Food Commodity Categories"),
              p("This pie chart shows the distribution of food commodities tracked by WFP, revealing the focus on different food categories for hunger monitoring and food security analysis.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_commodity_categories", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(12,
              h4("Regional Market Access Patterns"),
              p("This analysis shows how market access varies across regions and its relationship with hunger and development indicators.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_regional_markets", height = "400px")
            )
          )
        ),
        
        tabPanel("📊 Country Details",
          fluidRow(
            column(12,
              h4("Country Analysis"),
              p("Select a country from the map or dropdown to view detailed analysis including trends, hunger outbreak history, and WFP market data.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              selectInput("selected_country", "Select Country:",
                         choices = c("Select a country..." = "", sort(unique(combined_data$Area))),
                         selected = ""),
              uiOutput("country_analysis")
            )
          )
        ),
        
        tabPanel("🏪 WFP Market Analysis",
          fluidRow(
            column(12,
              h4("WFP Market and Commodity Analysis"),
              p("Detailed analysis of WFP market coverage, commodity tracking, and food security monitoring infrastructure.", style = "color: #666; font-size: 14px; margin-bottom: 15px;")
            )
          ),
          fluidRow(
            column(6,
              h4("Market Distribution by Country"),
              plotlyOutput("wfp_market_distribution", height = "400px")
            ),
            column(6,
              h4("Population Served by Markets"),
              plotlyOutput("wfp_population_served", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(12,
              h4("WFP Markets Data Table"),
              DT::dataTableOutput("wfp_markets_table")
            )
          )
        ),
        
        tabPanel("📈 Data Explorer",
          fluidRow(
            column(12,
              h4("Complete Dataset"),
              p("Explore the full dataset with FAO, World Bank, and WFP data. Filter and export capabilities available.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              DT::dataTableOutput("data_table")
            )
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Filtered data reactive
  filtered_data <- reactive({
    data <- combined_data
    
    if (input$risk_filter != "All") {
      data <- data %>% filter(combined_risk == input$risk_filter)
    }
    
    if (input$region_filter != "All") {
      data <- data %>% filter(region == input$region_filter)
    }
    
    if (input$development_filter != "All") {
      data <- data %>% filter(development_level == input$development_filter)
    }
    
    if (input$market_access_filter != "All") {
      data <- data %>% filter(market_access == input$market_access_filter)
    }
    
    return(data)
  })
  
  # Quick stats
  output$quick_stats <- renderText({
    data <- filtered_data()
    paste0(
      "Countries: ", nrow(data), "\n",
      "Avg Undernourishment: ", round(mean(data$undernourishment_rate, na.rm = TRUE), 1), "%\n",
      "Avg Poverty Rate: ", round(mean(data$poverty_rate, na.rm = TRUE), 1), "%\n",
      "Avg Life Expectancy: ", round(mean(data$life_expectancy, na.rm = TRUE), 1), " years\n",
      "Avg GDP per Capita: $", round(mean(data$gdp_per_capita, na.rm = TRUE), 0), "\n",
      "Total WFP Markets: ", sum(data$total_markets, na.rm = TRUE)
    )
  })
  
  # World map
  output$world_map <- renderPlotly({
    data <- filtered_data()
    
    # Create hover text with essential information (handle missing data)
    hover_text <- paste(
      "<b>", data$Area, "</b><br>",
      "Population: ", ifelse(is.na(data$population), "No data", paste(format(round(data$population / 1e6, 1), big.mark = ","), "M")), "<br>",
      "GDP per Capita: ", ifelse(is.na(data$gdp_per_capita), "No data", paste("$", format(round(data$gdp_per_capita, 0), big.mark = ","))), "<br>",
      "Poverty Rate: ", ifelse(is.na(data$poverty_rate), "No data", paste(round(data$poverty_rate, 1), "%")), "<br>",
      "Undernourishment: ", ifelse(is.na(data$undernourishment_rate), "No data", paste(round(data$undernourishment_rate, 1), "%")), "<br>",
      "Life Expectancy: ", ifelse(is.na(data$life_expectancy), "No data", paste(round(data$life_expectancy, 1), "years")), "<br>",
      "WFP Markets: ", ifelse(is.na(data$total_markets), "No data", paste(data$total_markets, "markets")), "<br>",
      "Major Hunger Outbreak (21st C): ", ifelse(data$major_hunger_outbreak_21st, "Yes", "No"), "<br>",
      "Click for detailed analysis"
    )
    
    # Use undernourishment rate for coloring, but handle missing data
    map_z <- ifelse(is.na(data$undernourishment_rate), 0, data$undernourishment_rate)
    
    plot_ly(
      type = "choropleth",
      locations = data$Area,
      locationmode = "country names",
      z = map_z,
      colorscale = list(
        c(0, "#E0E0E0"),    # No data - Light Gray
        c(0.01, "#2E8B57"), # Very Low - Green
        c(0.2, "#32CD32"),  # Low - Light Green  
        c(0.4, "#FFD700"),  # Medium - Yellow
        c(0.7, "#FF4500"),  # High - Red
        c(1, "#8B0000")     # Critical - Dark Red
      ),
      text = hover_text,
      hoverinfo = "text",
      colorbar = list(
        title = "Undernourishment Rate (%)",
        len = 0.8,
        tickvals = c(0, 5, 10, 15, 25, 50),
        ticktext = c("No data", "5%", "10%", "15%", "25%", "50%")
      )
    ) %>%
      layout(
        title = list(
          text = "Global Hunger & Development Map (Click Country for Details)",
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
      config(displayModeBar = FALSE) %>%
      event_register("plotly_click")
  })
  
  # Handle map clicks
  observeEvent(event_data("plotly_click"), {
    click_data <- event_data("plotly_click")
    if (!is.null(click_data)) {
      country_name <- click_data$location
      updateSelectInput(session, "selected_country", selected = country_name)
      updateTabsetPanel(session, "main_tabs", selected = "📊 Country Details")
    }
  })
  
  # Key Insights Visualizations
  
  # Hunger vs Poverty insight
  output$insight_hunger_poverty <- renderPlotly({
    data <- combined_data %>%
      filter(!is.na(undernourishment_rate) & !is.na(poverty_rate))
    
    plot_ly(data, 
            x = ~poverty_rate, 
            y = ~undernourishment_rate,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Country:", Area, 
                         "<br>Poverty Rate:", round(poverty_rate, 1), "%",
                         "<br>Undernourishment:", round(undernourishment_rate, 1), "%",
                         "<br>Risk Level:", combined_risk),
            hoverinfo = "text",
            type = "scatter", mode = "markers",
            marker = list(size = 8, opacity = 0.7)) %>%
      layout(
        title = "Hunger vs Poverty: The Critical Relationship",
        xaxis = list(title = "Poverty Rate (%)"),
        yaxis = list(title = "Undernourishment Rate (%)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Market Access vs Hunger insight
  output$insight_market_hunger <- renderPlotly({
    data <- combined_data %>%
      filter(!is.na(market_access) & !is.na(combined_risk))
    
    market_hunger_data <- data %>%
      count(market_access, combined_risk) %>%
      group_by(market_access) %>%
      mutate(percentage = n / sum(n) * 100)
    
    plot_ly(market_hunger_data, 
            x = ~market_access, 
            y = ~percentage,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Market Access:", market_access, 
                         "<br>Risk Level:", combined_risk,
                         "<br>Percentage:", round(percentage, 1), "%"),
            hoverinfo = "text",
            type = "bar") %>%
      layout(
        title = "Market Access vs Hunger Risk",
        xaxis = list(title = "Market Access Level"),
        yaxis = list(title = "Percentage of Countries"),
        barmode = "stack",
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # WFP Market Coverage insight
  output$insight_market_coverage <- renderPlotly({
    market_coverage <- combined_data %>%
      filter(!is.na(region) & !is.na(total_markets)) %>%
      group_by(region) %>%
      summarise(
        total_markets = sum(total_markets, na.rm = TRUE),
        countries_with_markets = sum(!is.na(total_markets)),
        .groups = "drop"
      ) %>%
      filter(total_markets > 0)
    
    plot_ly(market_coverage, 
            x = ~region, 
            y = ~total_markets,
            type = "bar",
            text = ~paste("Region:", region, 
                         "<br>Total Markets:", total_markets,
                         "<br>Countries:", countries_with_markets),
            hoverinfo = "text") %>%
      layout(
        title = "WFP Market Coverage by Region",
        xaxis = list(title = "Region"),
        yaxis = list(title = "Total Number of Markets"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Food Commodity Categories insight
  output$insight_commodity_categories <- renderPlotly({
    plot_ly(wfp_data$commodities, 
            labels = ~commodity_category, 
            values = ~n,
            type = "pie",
            textinfo = "label+percent",
            text = ~paste("Category:", commodity_category, 
                         "<br>Count:", n,
                         "<br>Percentage:", round(percentage, 1), "%"),
            hoverinfo = "text") %>%
      layout(
        title = "Food Commodity Categories",
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Regional Market Access Patterns insight
  output$insight_regional_markets <- renderPlotly({
    regional_market_data <- combined_data %>%
      filter(!is.na(region) & !is.na(market_access)) %>%
      count(region, market_access) %>%
      group_by(region) %>%
      mutate(percentage = n / sum(n) * 100)
    
    plot_ly(regional_market_data, 
            x = ~region, 
            y = ~percentage,
            color = ~market_access,
            text = ~paste("Region:", region, 
                         "<br>Market Access:", market_access,
                         "<br>Percentage:", round(percentage, 1), "%"),
            hoverinfo = "text",
            type = "bar") %>%
      layout(
        title = "Regional Market Access Patterns",
        xaxis = list(title = "Region"),
        yaxis = list(title = "Percentage of Countries"),
        barmode = "stack",
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # WFP Market Analysis
  
  # Market Distribution by Country
  output$wfp_market_distribution <- renderPlotly({
    market_dist <- wfp_data$markets %>%
      arrange(desc(total_markets)) %>%
      head(20)  # Top 20 countries by market count
    
    plot_ly(market_dist, 
            x = ~reorder(Country, total_markets), 
            y = ~total_markets,
            type = "bar",
            text = ~paste("Country:", Country, 
                         "<br>Total Markets:", total_markets,
                         "<br>Population Served:", format(round(total_population_served / 1e6, 1), big.mark = ","), "M"),
            hoverinfo = "text") %>%
      layout(
        title = "Top 20 Countries by WFP Market Count",
        xaxis = list(title = "Country"),
        yaxis = list(title = "Number of Markets"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Population Served by Markets
  output$wfp_population_served <- renderPlotly({
    pop_served <- wfp_data$markets %>%
      arrange(desc(total_population_served)) %>%
      head(20)  # Top 20 countries by population served
    
    plot_ly(pop_served, 
            x = ~reorder(Country, total_population_served), 
            y = ~total_population_served / 1e6,  # Convert to millions
            type = "bar",
            text = ~paste("Country:", Country, 
                         "<br>Population Served:", format(round(total_population_served / 1e6, 1), big.mark = ","), "M",
                         "<br>Total Markets:", total_markets),
            hoverinfo = "text") %>%
      layout(
        title = "Top 20 Countries by Population Served",
        xaxis = list(title = "Country"),
        yaxis = list(title = "Population Served (Millions)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # WFP Markets Data Table
  output$wfp_markets_table <- DT::renderDataTable({
    DT::datatable(
      wfp_data$markets %>%
        select(Country, total_markets, total_population_served, avg_market_population, market_access) %>%
        mutate(
          total_population_served = round(total_population_served / 1e6, 1),
          avg_market_population = round(avg_market_population / 1e3, 1)
        ) %>%
        rename(
          "Total Markets" = total_markets,
          "Population Served (M)" = total_population_served,
          "Avg Market Population (K)" = avg_market_population,
          "Market Access Level" = market_access
        ),
      options = list(
        pageLength = 25, 
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons',
      filter = 'top'
    )
  })
  
  # Country analysis
  output$country_analysis <- renderUI({
    if (input$selected_country == "") {
      return(
        div(
          style = "text-align: center; padding: 50px; color: #666;",
          h4("Select a country to view detailed analysis"),
          p("Click on a country in the map above or select from the dropdown menu.")
        )
      )
    }
    
    country_data <- combined_data %>% filter(Area == input$selected_country)
    country_timeseries <- timeseries_data %>% filter(Area == input$selected_country)
    
    if (nrow(country_data) == 0) {
      return(
        div(
          style = "text-align: center; padding: 50px; color: #666;",
          h4("No data available for this country")
        )
      )
    }
    
    # Create country analysis UI
    fluidRow(
      # Country overview
      column(12,
        div(
          style = "background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
          h3(paste("🇺🇳", input$selected_country)),
          fluidRow(
            column(3, h5("Population"), h4(ifelse(is.na(country_data$population), "No data", paste(format(round(country_data$population / 1e6, 1), big.mark = ","), "M")))),
            column(3, h5("GDP per Capita"), h4(ifelse(is.na(country_data$gdp_per_capita), "No data", paste("$", format(round(country_data$gdp_per_capita, 0), big.mark = ","))))),
            column(3, h5("Poverty Rate"), h4(ifelse(is.na(country_data$poverty_rate), "No data", paste(round(country_data$poverty_rate, 1), "%")))),
            column(3, h5("Life Expectancy"), h4(ifelse(is.na(country_data$life_expectancy), "No data", paste(round(country_data$life_expectancy, 1), "years"))))
          ),
          br(),
          fluidRow(
            column(6, h5("Undernourishment Rate"), h4(ifelse(is.na(country_data$undernourishment_rate), "No data", paste(round(country_data$undernourishment_rate, 1), "%")))),
            column(6, h5("Combined Risk Level"), h4(as.character(country_data$combined_risk)))
          ),
          br(),
          fluidRow(
            column(6, h5("Major Hunger Outbreak (21st Century)"), h4(ifelse(country_data$major_hunger_outbreak_21st, "Yes", "No"))),
            column(6, h5("Outbreak Years"), h4(country_data$outbreak_years))
          ),
          br(),
          fluidRow(
            column(6, h5("Region"), h4(ifelse(is.na(country_data$region), "Unknown", as.character(country_data$region)))),
            column(6, h5("Development Level"), h4(ifelse(is.na(country_data$development_level), "Unknown", as.character(country_data$development_level))))
          ),
          br(),
          fluidRow(
            column(6, h5("WFP Markets"), h4(ifelse(is.na(country_data$total_markets), "No data", paste(country_data$total_markets, "markets")))),
            column(6, h5("Market Access Level"), h4(ifelse(is.na(country_data$market_access), "Unknown", as.character(country_data$market_access))))
          )
        )
      ),
      
      # Charts
      column(6,
        h4("Hunger Trend Over Time"),
        plotlyOutput("country_hunger_trend", height = "300px")
      ),
      column(6,
        h4("Economic Indicators Trend"),
        plotlyOutput("country_economic_trend", height = "300px")
      ),
      
      column(12,
        h4("Health & Development Indicators"),
        plotlyOutput("country_health_trend", height = "300px")
      )
    )
  })
  
  # Country hunger trend
  output$country_hunger_trend <- renderPlotly({
    if (input$selected_country == "") return(NULL)
    
    country_timeseries <- timeseries_data %>% 
      filter(Area == input$selected_country, !is.na(undernourishment_rate))
    
    if (nrow(country_timeseries) == 0) {
      return(plot_ly() %>% add_annotations(text = "No hunger data available", showarrow = FALSE))
    }
    
    plot_ly(country_timeseries, x = ~Year, y = ~undernourishment_rate,
            type = "scatter", mode = "lines+markers",
            line = list(color = "#FF4500", width = 3),
            marker = list(color = "#FF4500", size = 8),
            name = "Undernourishment Rate") %>%
      layout(
        title = "Undernourishment Rate Over Time",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Undernourishment Rate (%)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Country economic trend
  output$country_economic_trend <- renderPlotly({
    if (input$selected_country == "") return(NULL)
    
    country_timeseries <- timeseries_data %>% 
      filter(Area == input$selected_country, !is.na(gdp_per_capita))
    
    if (nrow(country_timeseries) == 0) {
      return(plot_ly() %>% add_annotations(text = "No economic data available", showarrow = FALSE))
    }
    
    plot_ly(country_timeseries, x = ~Year, y = ~gdp_per_capita,
            type = "scatter", mode = "lines+markers",
            line = list(color = "#32CD32", width = 3),
            marker = list(color = "#32CD32", size = 8),
            name = "GDP per Capita") %>%
      layout(
        title = "GDP per Capita Over Time",
        xaxis = list(title = "Year"),
        yaxis = list(title = "GDP per Capita (USD)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Country health trend
  output$country_health_trend <- renderPlotly({
    if (input$selected_country == "") return(NULL)
    
    country_timeseries <- timeseries_data %>% 
      filter(Area == input$selected_country, !is.na(life_expectancy))
    
    if (nrow(country_timeseries) == 0) {
      return(plot_ly() %>% add_annotations(text = "No health data available", showarrow = FALSE))
    }
    
    plot_ly(country_timeseries, x = ~Year, y = ~life_expectancy,
            type = "scatter", mode = "lines+markers",
            line = list(color = "#3c8dbc", width = 3),
            marker = list(color = "#3c8dbc", size = 8),
            name = "Life Expectancy") %>%
      layout(
        title = "Life Expectancy Over Time",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Life Expectancy (years)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Data table
  output$data_table <- DT::renderDataTable({
    DT::datatable(
      filtered_data() %>%
        select(Area, undernourishment_rate, poverty_rate, 
               life_expectancy, gdp_per_capita, population, 
               combined_risk, development_level, region,
               major_hunger_outbreak_21st, outbreak_years,
               total_markets, total_population_served, market_access) %>%
        mutate(
          undernourishment_rate = ifelse(is.na(undernourishment_rate), NA, round(undernourishment_rate, 1)),
          poverty_rate = ifelse(is.na(poverty_rate), NA, round(poverty_rate, 1)),
          life_expectancy = ifelse(is.na(life_expectancy), NA, round(life_expectancy, 1)),
          gdp_per_capita = ifelse(is.na(gdp_per_capita), NA, round(gdp_per_capita, 0)),
          population = ifelse(is.na(population), NA, round(population / 1e6, 1)),
          total_population_served = ifelse(is.na(total_population_served), NA, round(total_population_served / 1e6, 1))
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
          "Region" = region,
          "Major Hunger Outbreak (21st C)" = major_hunger_outbreak_21st,
          "Outbreak Years" = outbreak_years,
          "WFP Markets" = total_markets,
          "Population Served (M)" = total_population_served,
          "Market Access Level" = market_access
        ),
      options = list(
        pageLength = 25, 
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons',
      filter = 'top'
    )
  })
}

# Run the application
cat("🌍 Starting WFP-Enhanced Global Hunger Research Website...\n")
cat("====================================================================\n")
cat("✅ FAO data loaded successfully!\n")
cat("✅ World Bank data loaded successfully!\n")
cat("✅ WFP data loaded successfully!\n")
cat("📊 Total countries in dataset:", nrow(combined_data), "\n")
cat("📊 Countries with FAO data:", sum(!is.na(combined_data$undernourishment_rate)), "\n")
cat("📊 Countries with World Bank data:", sum(!is.na(combined_data$population)), "\n")
cat("📊 Countries with WFP market data:", sum(!is.na(combined_data$total_markets)), "\n")
cat("🌐 WEBSITE URL: http://localhost:3840\n")
cat("📱 Alternative: http://127.0.0.1:3840\n")
cat("🔗 Copy and paste this URL into your browser!\n")
cat("🛑 To stop the server, press Ctrl+C in the terminal.\n\n")

shinyApp(ui = ui, server = server)
