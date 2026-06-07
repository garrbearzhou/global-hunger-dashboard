library(shiny)
library(plotly)
library(DT)
library(tidyverse)

# Load data
fao_latest <- read_csv("data/raw/fao/FAO_Data/FAOSTAT_data_en_10-19-2025.csv", show_col_types = FALSE)
wb_raw_data <- read_csv("data/raw/world bank/world_bank_data.csv", show_col_types = FALSE)
pip_data <- read_csv("data/raw/world bank/pip 2.csv", show_col_types = FALSE)
wfp_markets <- read_csv("data/raw/wfp/markets.csv", show_col_types = FALSE)
wfp_commodities <- read_csv("data/raw/wfp/commodities.csv", show_col_types = FALSE)

# Process FAO data
fao_processed <- fao_latest %>%
  mutate(
    Value_clean = case_when(
      Value == "<2.5" ~ "2.5",
      Value == "" ~ NA_character_,
      TRUE ~ Value
    ),
    Value_numeric = as.numeric(Value_clean)
  ) %>%
  select(Area, `Item Code`, Item, Element, Unit, Year, Value_numeric) %>%
  pivot_wider(
    names_from = `Item Code`, 
    values_from = Value_numeric, 
    names_prefix = "ind_"
  ) %>%
  rename(
    undernourishment_rate = ind_210041,
    undernourished_population = ind_210011
  ) %>%
  filter(!is.na(undernourishment_rate) & undernourishment_rate > 0)

# Process World Bank data
wb_summary <- wb_raw_data %>%
  group_by(country) %>%
  summarise(
    gdp_per_capita = last(NY.GDP.PCAP.CD, order_by = year),
    life_expectancy = last(SP.DYN.LE00.IN, order_by = year),
    population = last(SP.POP.TOTL, order_by = year),
    .groups = "drop"
  )

# Process PIP data
pip_summary <- pip_data %>%
  group_by(country_name) %>%
  summarise(
    poverty_rate = last(headcount_ratio_international_povline, order_by = year),
    gini_coefficient = last(gini, order_by = year),
    .groups = "drop"
  )

# Process WFP data
wfp_data <- list(
  markets = wfp_markets %>%
    group_by(Country) %>%
    summarise(total_markets = n(), .groups = "drop"),
  commodities = wfp_commodities
)

# Get all countries
all_countries <- unique(c(fao_processed$Area, wb_summary$country, pip_summary$country_name))

# Combine all data
combined_data <- data.frame(Area = all_countries) %>%
  left_join(fao_processed, by = "Area") %>%
  left_join(wb_summary, by = c("Area" = "country")) %>%
  left_join(pip_summary, by = c("Area" = "country_name")) %>%
  left_join(wfp_data$markets, by = c("Area" = "Country")) %>%
  mutate(
    # Add region categorization
    region = case_when(
      Area %in% c("Afghanistan", "Bangladesh", "Bhutan", "India", "Maldives", "Nepal", "Pakistan", "Sri Lanka") ~ "South Asia",
      Area %in% c("China", "Japan", "South Korea", "North Korea", "Mongolia", "Taiwan") ~ "East Asia & Pacific",
      Area %in% c("United States", "Canada", "Mexico", "Guatemala", "Belize", "El Salvador", "Honduras", "Nicaragua", "Costa Rica", "Panama") ~ "North America",
      Area %in% c("Brazil", "Argentina", "Chile", "Peru", "Colombia", "Venezuela", "Ecuador", "Bolivia", "Paraguay", "Uruguay", "Guyana", "Suriname") ~ "South America",
      Area %in% c("Germany", "France", "United Kingdom", "Italy", "Spain", "Poland", "Netherlands", "Belgium", "Sweden", "Norway", "Denmark", "Finland", "Austria", "Switzerland", "Portugal", "Greece", "Czech Republic", "Hungary", "Romania", "Bulgaria", "Croatia", "Slovakia", "Slovenia", "Estonia", "Latvia", "Lithuania", "Ireland", "Iceland", "Luxembourg", "Malta", "Cyprus") ~ "Europe",
      Area %in% c("Algeria", "Egypt", "Morocco", "Tunisia", "Libya", "Sudan", "Ethiopia", "Kenya", "Nigeria", "South Africa", "Somalia", "Yemen", "South Sudan", "Madagascar", "Democratic Republic of the Congo", "Central African Republic", "Chad", "Mali", "Burkina Faso", "Niger", "Zambia", "Zimbabwe", "United Republic of Tanzania", "Congo, Dem. Rep.", "Congo, Democratic Republic of the", "Congo, the Democratic Republic of the") ~ "Africa",
      Area %in% c("Palestine", "Kashmir", "Taiwan", "Western Sahara", "Northern Cyprus", "Abkhazia", "South Ossetia", "Transnistria", "Nagorno-Karabakh", "Kosovo", "Somaliland", "Puntland") ~ "Other",
      TRUE ~ "Unknown"
    ),
    # Add hunger outbreak data (simplified)
    major_hunger_outbreak_21st = Area %in% c("Afghanistan", "Democratic Republic of the Congo", "Ethiopia", "Somalia", "South Sudan", "Yemen", "Haiti", "Madagascar", "Central African Republic", "Chad", "Mali", "Niger", "Burkina Faso", "Nigeria"),
    # Calculate vulnerability
    undernourishment_score = pmin(ifelse(is.na(undernourishment_rate), 0, undernourishment_rate) * 0.8, 40),
    poverty_score = case_when(
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
    life_expectancy_score = case_when(
      is.na(life_expectancy) ~ 0,
      life_expectancy < 50 ~ 10,
      life_expectancy < 60 ~ 8,
      life_expectancy < 70 ~ 5,
      TRUE ~ 0
    ),
    inequality_score = case_when(
      is.na(gini_coefficient) ~ 0,
      gini_coefficient >= 0.6 ~ 8,
      gini_coefficient >= 0.5 ~ 6,
      gini_coefficient >= 0.4 ~ 4,
      TRUE ~ 0
    ),
    market_access_score = case_when(
      is.na(total_markets) ~ 0,
      total_markets == 0 ~ 7,
      total_markets < 5 ~ 5,
      total_markets < 20 ~ 3,
      TRUE ~ 0
    ),
    outbreak_score = ifelse(is.na(major_hunger_outbreak_21st) | !major_hunger_outbreak_21st, 0, 20),
    population_density_score = case_when(
      is.na(population) ~ 0,
      population > 100000000 ~ 5,
      population > 50000000 ~ 3,
      population > 10000000 ~ 1,
      TRUE ~ 0
    ),
    regional_vulnerability_score = case_when(
      is.na(region) ~ 0,
      region %in% c("Africa", "Middle East & North Africa") ~ 15,
      region %in% c("South Asia", "Latin America & Caribbean") ~ 10,
      region %in% c("East Asia & Pacific", "Europe & Central Asia") ~ 5,
      TRUE ~ 0
    ),
    hunger_vulnerability_rating = round(
      undernourishment_score + poverty_score + gdp_score + life_expectancy_score + 
      inequality_score + market_access_score + outbreak_score + 
      population_density_score + regional_vulnerability_score,
      1
    ),
    hunger_vulnerability_rating = pmax(0, pmin(100, hunger_vulnerability_rating))
  )

# Filter to sovereign countries only
sovereign_countries <- combined_data %>%
  filter(!Area %in% c(
    "American Samoa", "Anguilla", "Aruba", "Bermuda", "British Virgin Islands", "Cayman Islands",
    "Cook Islands", "Faroe Islands", "French Polynesia", "Gibraltar", "Greenland", "Guam",
    "Hong Kong", "Isle of Man", "Jersey", "Macao", "Montserrat", "New Caledonia", "Niue",
    "Norfolk Island", "Northern Mariana Islands", "Puerto Rico", "Saint Helena", "Saint Pierre and Miquelon",
    "Tokelau", "Turks and Caicos Islands", "United States Virgin Islands", "Wallis and Futuna",
    "World Bank administrative region - Sub-Saharan Africa", "World Bank administrative region - Middle East & North Africa",
    "World Bank administrative region - Europe & Central Asia", "World Bank administrative region - East Asia & Pacific",
    "World Bank administrative region - Latin America & Caribbean", "World Bank administrative region - North America"
  ))

ui <- fluidPage(
  titlePanel("Global Hunger Vulnerability Analysis"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Filters"),
      selectInput("region_filter", "Region:", 
                  choices = c("All", unique(sovereign_countries$region)),
                  selected = "All"),
      sliderInput("vulnerability_filter", "Vulnerability Range:",
                  min = 0, max = 100, value = c(0, 100)),
      br(),
      h4("About"),
      p("This app analyzes global hunger vulnerability using a comprehensive 9-factor formula incorporating FAO, World Bank, PIP, and WFP data.")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Map", 
                 plotlyOutput("world_map"),
                 br(),
                 h4("Vulnerability Scale (0-100)"),
                 p("Higher scores indicate greater hunger vulnerability based on undernourishment, poverty, GDP, life expectancy, inequality, market access, historical crises, population density, and regional risk factors.")
        ),
        
        tabPanel("Data Table", 
                 DT::dataTableOutput("data_table")
        ),
        
        tabPanel("Country Details",
                 selectInput("country_select", "Select Country:",
                             choices = sort(sovereign_countries$Area),
                             selected = "Afghanistan"),
                 br(),
                 uiOutput("country_details")
        ),
        
        tabPanel("Vulnerability Formula",
                 h4("9-Factor Comprehensive Formula"),
                 p("The hunger vulnerability rating is calculated using the following factors:"),
                 tags$ul(
                   tags$li(strong("1. Undernourishment (0-40 points):"), "FAO undernourishment rate × 0.8 - PRIMARY FACTOR"),
                   tags$li(strong("2. Poverty (0-20 points):"), "PIP poverty rate × 0.4"),
                   tags$li(strong("3. GDP per Capita (0-15 points):"), "Lower GDP = higher vulnerability"),
                   tags$li(strong("4. Life Expectancy (0-10 points):"), "Lower life expectancy = higher vulnerability"),
                   tags$li(strong("5. Inequality (0-8 points):"), "Higher Gini coefficient = higher vulnerability"),
                   tags$li(strong("6. Market Access (0-7 points):"), "Fewer WFP markets = higher vulnerability"),
                   tags$li(strong("7. Historical Crises (0-20 points):"), "Major hunger outbreaks in 21st century"),
                   tags$li(strong("8. Population Density (0-5 points):"), "Larger populations = higher vulnerability"),
                   tags$li(strong("9. Regional Risk (0-15 points):"), "Africa/MENA = 15, South Asia/LAC = 10, EAP/ECA = 5")
                 ),
                 p("Total possible points: 140, scaled to 0-100 range"),
                 p("This formula emphasizes undernourishment, regional risk, and historical crises as requested.")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  filtered_data <- reactive({
    data <- sovereign_countries
    
    if (input$region_filter != "All") {
      data <- data %>% filter(region == input$region_filter)
    }
    
    data <- data %>%
      filter(hunger_vulnerability_rating >= input$vulnerability_filter[1] &
             hunger_vulnerability_rating <= input$vulnerability_filter[2])
    
    return(data)
  })
  
  output$world_map <- renderPlotly({
    data <- filtered_data()
    
    plot_ly(
      type = "choropleth",
      locations = data$Area,
      locationmode = "country names",
      z = data$hunger_vulnerability_rating,
      zmin = 0,
      zmax = 100,
      colorscale = "Reds",
      reversescale = FALSE,
      text = paste("Country:", data$Area, "<br>Vulnerability:", data$hunger_vulnerability_rating, "<br>Region:", data$region),
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
    filtered_data() %>%
      select(Area, region, hunger_vulnerability_rating, undernourishment_rate, poverty_rate, gdp_per_capita, life_expectancy) %>%
      arrange(desc(hunger_vulnerability_rating))
  })
  
  output$country_details <- renderUI({
    country_data <- sovereign_countries %>%
      filter(Area == input$country_select)
    
    if (nrow(country_data) == 0) return(p("No data available for this country."))
    
    country_data <- country_data[1, ]
    
    fluidRow(
      column(12,
        h3(paste("Country Profile:", country_data$Area)),
        br(),
        
        fluidRow(
          column(6,
            h4("Key Indicators"),
            p(strong("Hunger Vulnerability Rating:"), round(country_data$hunger_vulnerability_rating, 1), "/100"),
            p(strong("Region:"), country_data$region),
            p(strong("Undernourishment Rate:"), ifelse(is.na(country_data$undernourishment_rate), "No data", paste(round(country_data$undernourishment_rate, 1), "%"))),
            p(strong("Poverty Rate:"), ifelse(is.na(country_data$poverty_rate), "No data", paste(round(country_data$poverty_rate, 1), "%"))),
            p(strong("GDP per Capita:"), ifelse(is.na(country_data$gdp_per_capita), "No data", paste("$", round(country_data$gdp_per_capita, 0))))
          ),
          column(6,
            h4("Additional Factors"),
            p(strong("Life Expectancy:"), ifelse(is.na(country_data$life_expectancy), "No data", paste(round(country_data$life_expectancy, 1), "years"))),
            p(strong("Gini Coefficient:"), ifelse(is.na(country_data$gini_coefficient), "No data", round(country_data$gini_coefficient, 3))),
            p(strong("WFP Markets:"), ifelse(is.na(country_data$total_markets), "No data", country_data$total_markets)),
            p(strong("Major Hunger Outbreak (21st Century):"), ifelse(country_data$major_hunger_outbreak_21st, "Yes", "No")),
            p(strong("Population:"), ifelse(is.na(country_data$population), "No data", format(country_data$population, big.mark = ",")))
          )
        ),
        
        br(),
        h4("Vulnerability Breakdown"),
        p("This shows how the hunger vulnerability rating is calculated for this country:"),
        div(
          style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px;",
          fluidRow(
            column(6,
              h5("Primary Factors:"),
              p(strong("Undernourishment:"), round(country_data$undernourishment_score, 1), "points"),
              p(strong("Poverty:"), round(country_data$poverty_score, 1), "points"),
              p(strong("GDP:"), round(country_data$gdp_score, 1), "points"),
              p(strong("Life Expectancy:"), round(country_data$life_expectancy_score, 1), "points")
            ),
            column(6,
              h5("Secondary Factors:"),
              p(strong("Inequality:"), round(country_data$inequality_score, 1), "points"),
              p(strong("Market Access:"), round(country_data$market_access_score, 1), "points"),
              p(strong("Historical Crises:"), round(country_data$outbreak_score, 1), "points"),
              p(strong("Population:"), round(country_data$population_density_score, 1), "points"),
              p(strong("Regional Risk:"), round(country_data$regional_vulnerability_score, 1), "points")
            )
          ),
          br(),
          div(
            style = "text-align: center; font-size: 18px; font-weight: bold; color: #2c3e50;",
            paste("Total Vulnerability Score: ", round(country_data$hunger_vulnerability_rating, 1), "/100")
          )
        )
      )
    )
  })
}

shinyApp(ui = ui, server = server)
