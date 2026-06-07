# Enhanced Global Hunger Research Website with Country Details
# Combines FAO and World Bank data with individual country analysis

library(shiny)
library(plotly)
library(DT)
library(tidyverse)
library(readr)

# Load and process data
cat("🌍 Loading FAO Food Security Data and World Bank Indicators...\n")

# Load FAO data
fao_main <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data_NOFLAG.csv", show_col_types = FALSE)

# Load World Bank data
wb_raw_data <- read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE)

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
        country %in% c("China", "Japan", "Korea, Rep.", "Mongolia", "Thailand", "Vietnam", "Indonesia", "Malaysia", "Philippines", "Singapore") ~ "East Asia & Pacific",
        country %in% c("Algeria", "Egypt", "Morocco", "Tunisia", "Libya", "Sudan", "Ethiopia", "Kenya", "Nigeria", "South Africa") ~ "Africa",
        country %in% c("Brazil", "Argentina", "Chile", "Colombia", "Mexico", "Peru", "Venezuela") ~ "Latin America & Caribbean",
        country %in% c("United States", "Canada") ~ "North America",
        country %in% c("Germany", "France", "United Kingdom", "Italy", "Spain", "Poland", "Russia") ~ "Europe & Central Asia",
        TRUE ~ "Other"
      )
    )
  
  return(wb_summary)
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

# Create comprehensive country mapping
# We'll use a more robust approach by matching countries directly
country_mapping <- data.frame(
  fao_name = unique(fao_summary$Area),
  wb_name = unique(fao_summary$Area)  # Start with same names, will be updated
)

# Update with known mappings where names differ
known_mappings <- data.frame(
  fao_name = c("United States of America", "United Kingdom", "Russian Federation", "Iran (Islamic Republic of)", "Venezuela (Bolivarian Republic of)", "Republic of Korea", "Republic of Moldova", "Bolivia (Plurinational State of)", "United Republic of Tanzania", "Democratic Republic of the Congo", "Republic of the Congo", "Lao People's Democratic Republic", "Syrian Arab Republic", "Viet Nam", "Côte d'Ivoire", "Cabo Verde", "Eswatini", "Timor-Leste", "North Macedonia", "Republic of North Macedonia"),
  wb_name = c("United States", "United Kingdom", "Russia", "Iran, Islamic Rep.", "Venezuela, RB", "Korea, Rep.", "Moldova", "Bolivia", "Tanzania", "Congo, Dem. Rep.", "Congo, Rep.", "Lao PDR", "Syrian Arab Republic", "Vietnam", "Cote d'Ivoire", "Cape Verde", "Eswatini", "Timor-Leste", "North Macedonia", "North Macedonia")
)

# Apply known mappings
for(i in 1:nrow(known_mappings)) {
  country_mapping$wb_name[country_mapping$fao_name == known_mappings$fao_name[i]] <- known_mappings$wb_name[i]
}

# Create comprehensive country list from both datasets
all_countries <- unique(c(fao_summary$Area, wb_summary$country))

# Create base dataset with all countries
all_countries_data <- data.frame(Area = all_countries) %>%
  # Add FAO data
  left_join(fao_summary, by = "Area") %>%
  # Add World Bank data
  left_join(wb_summary, by = c("Area" = "country")) %>%
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
cat("📊 Countries with both FAO and World Bank data:", sum(!is.na(combined_data$undernourishment_rate) & !is.na(combined_data$population)), "\n")
cat("📈 Time series records:", nrow(timeseries_data), "\n")

# UI
ui <- fluidPage(
  titlePanel("🌍 Enhanced Global Hunger Research Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("🌍 Global Overview"),
      p("This dashboard combines FAO hunger data with World Bank economic indicators to provide comprehensive analysis of global hunger patterns."),
      
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
              p("Click on any country to view detailed analysis. Countries are colored by undernourishment rate. Hover for key statistics.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              plotlyOutput("world_map", height = "600px")
            )
          )
        ),
        
        tabPanel("📈 Key Insights",
          fluidRow(
            column(12,
              h4("Global Hunger & Development Insights"),
              p("Key visualizations revealing patterns and relationships in global hunger, poverty, and development data.", style = "color: #666; font-size: 14px; margin-bottom: 15px;")
            )
          ),
          fluidRow(
            column(6,
              h4("Hunger vs Poverty: The Critical Relationship"),
              p("This scatter plot reveals the strong correlation between undernourishment and poverty rates. Countries with higher poverty tend to have higher hunger rates, but there are notable exceptions that warrant further investigation.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_hunger_poverty", height = "400px")
            ),
            column(6,
              h4("Economic Development vs Hunger"),
              p("GDP per capita shows a strong inverse relationship with hunger rates. Higher-income countries generally have lower hunger, but the relationship is not linear - some middle-income countries still face significant hunger challenges.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_gdp_hunger", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(6,
              h4("Life Expectancy by Hunger Risk Level"),
              p("Countries with higher hunger risk levels show significantly lower life expectancy. This visualization demonstrates the profound health impact of hunger and food insecurity on populations.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_life_expectancy", height = "400px")
            ),
            column(6,
              h4("21st Century Hunger Crisis Countries"),
              p("Countries that experienced major hunger outbreaks in the 21st century are concentrated in specific regions, particularly Africa and conflict zones. This highlights the geographic clustering of hunger crises.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_crisis_countries", height = "400px")
            )
          ),
          br(),
          fluidRow(
            column(12,
              h4("Regional Hunger Patterns"),
              p("Different world regions show distinct patterns in hunger prevalence. This analysis reveals which regions face the greatest challenges and where progress has been made.", style = "color: #666; font-size: 12px; margin-bottom: 10px;"),
              plotlyOutput("insight_regional_patterns", height = "400px")
            )
          )
        ),
        
        tabPanel("📊 Country Details",
          fluidRow(
            column(12,
              h4("Country Analysis"),
              p("Select a country from the map or dropdown to view detailed analysis including trends and hunger outbreak history.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
              selectInput("selected_country", "Select Country:",
                         choices = c("Select a country..." = "", sort(unique(combined_data$Area))),
                         selected = ""),
              uiOutput("country_analysis")
            )
          )
        ),
        
        tabPanel("📈 Data Explorer",
          fluidRow(
            column(12,
              h4("Complete Dataset"),
              p("Explore the full dataset with filtering and export capabilities.", style = "color: #666; font-size: 14px; margin-bottom: 15px;"),
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
      "Avg GDP per Capita: $", round(mean(data$gdp_per_capita, na.rm = TRUE), 0)
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
  
  # GDP vs Hunger insight
  output$insight_gdp_hunger <- renderPlotly({
    data <- combined_data %>%
      filter(!is.na(gdp_per_capita) & !is.na(undernourishment_rate))
    
    plot_ly(data, 
            x = ~gdp_per_capita, 
            y = ~undernourishment_rate,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            text = ~paste("Country:", Area, 
                         "<br>GDP per Capita: $", format(round(gdp_per_capita, 0), big.mark = ","),
                         "<br>Undernourishment:", round(undernourishment_rate, 1), "%",
                         "<br>Risk Level:", combined_risk),
            hoverinfo = "text",
            type = "scatter", mode = "markers",
            marker = list(size = 8, opacity = 0.7)) %>%
      layout(
        title = "Economic Development vs Hunger",
        xaxis = list(title = "GDP per Capita (USD)", type = "log"),
        yaxis = list(title = "Undernourishment Rate (%)"),
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Life Expectancy by Risk Level insight
  output$insight_life_expectancy <- renderPlotly({
    data <- combined_data %>%
      filter(!is.na(life_expectancy) & !is.na(combined_risk))
    
    plot_ly(data, 
            x = ~combined_risk, 
            y = ~life_expectancy,
            color = ~combined_risk,
            colors = c("Very Low" = "#2E8B57", "Low" = "#32CD32", 
                      "Medium" = "#FFD700", "High" = "#FF4500", "Critical" = "#8B0000"),
            type = "box",
            text = ~paste("Country:", Area, 
                         "<br>Life Expectancy:", round(life_expectancy, 1), "years",
                         "<br>Risk Level:", combined_risk),
            hoverinfo = "text") %>%
      layout(
        title = "Life Expectancy by Hunger Risk Level",
        xaxis = list(title = "Combined Risk Level"),
        yaxis = list(title = "Life Expectancy (years)"),
        showlegend = FALSE,
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Crisis Countries insight
  output$insight_crisis_countries <- renderPlotly({
    crisis_data <- combined_data %>%
      filter(major_hunger_outbreak_21st == TRUE) %>%
      count(region) %>%
      mutate(region = ifelse(is.na(region), "Unknown", region))
    
    plot_ly(crisis_data, 
            x = ~region, 
            y = ~n,
            type = "bar",
            color = ~region,
            text = ~paste("Region:", region, "<br>Countries with Major Hunger Outbreaks:", n),
            hoverinfo = "text") %>%
      layout(
        title = "21st Century Hunger Crisis by Region",
        xaxis = list(title = "Region"),
        yaxis = list(title = "Number of Countries"),
        showlegend = FALSE,
        margin = list(t = 50, b = 50, l = 50, r = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Regional Patterns insight
  output$insight_regional_patterns <- renderPlotly({
    regional_data <- combined_data %>%
      filter(!is.na(undernourishment_rate) & !is.na(region)) %>%
      group_by(region) %>%
      summarise(
        avg_undernourishment = mean(undernourishment_rate, na.rm = TRUE),
        avg_poverty = mean(poverty_rate, na.rm = TRUE),
        avg_gdp = mean(gdp_per_capita, na.rm = TRUE),
        avg_life_expectancy = mean(life_expectancy, na.rm = TRUE),
        country_count = n(),
        .groups = "drop"
      ) %>%
      filter(country_count >= 3)  # Only show regions with at least 3 countries
    
    plot_ly(regional_data, 
            x = ~avg_undernourishment, 
            y = ~avg_poverty,
            size = ~country_count,
            color = ~region,
            text = ~paste("Region:", region, 
                         "<br>Avg Undernourishment:", round(avg_undernourishment, 1), "%",
                         "<br>Avg Poverty:", round(avg_poverty, 1), "%",
                         "<br>Countries:", country_count),
            hoverinfo = "text",
            type = "scatter", mode = "markers",
            marker = list(opacity = 0.7)) %>%
      layout(
        title = "Regional Hunger and Poverty Patterns",
        xaxis = list(title = "Average Undernourishment Rate (%)"),
        yaxis = list(title = "Average Poverty Rate (%)"),
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
               major_hunger_outbreak_21st, outbreak_years) %>%
        mutate(
          undernourishment_rate = ifelse(is.na(undernourishment_rate), NA, round(undernourishment_rate, 1)),
          poverty_rate = ifelse(is.na(poverty_rate), NA, round(poverty_rate, 1)),
          life_expectancy = ifelse(is.na(life_expectancy), NA, round(life_expectancy, 1)),
          gdp_per_capita = ifelse(is.na(gdp_per_capita), NA, round(gdp_per_capita, 0)),
          population = ifelse(is.na(population), NA, round(population / 1e6, 1))
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
          "Outbreak Years" = outbreak_years
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
cat("🌍 Starting Enhanced Global Hunger Research Website...\n")
cat("====================================================================\n")
cat("✅ FAO data loaded successfully!\n")
cat("✅ World Bank data loaded successfully!\n")
cat("📊 Total countries in dataset:", nrow(combined_data), "\n")
cat("📊 Countries with FAO data:", sum(!is.na(combined_data$undernourishment_rate)), "\n")
cat("📊 Countries with World Bank data:", sum(!is.na(combined_data$population)), "\n")
cat("📊 Countries with both FAO and World Bank data:", sum(!is.na(combined_data$undernourishment_rate) & !is.na(combined_data$population)), "\n")
cat("🌐 WEBSITE URL: http://localhost:3840\n")
cat("📱 Alternative: http://127.0.0.1:3840\n")
cat("🔗 Copy and paste this URL into your browser!\n")
cat("🛑 To stop the server, press Ctrl+C in the terminal.\n\n")

shinyApp(ui = ui, server = server)
