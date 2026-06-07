# =============================================================================
# GLOBAL HUNGER RESEARCH PROJECT
# Author: Garrett Zhou
# Date: October 2024
# Version: 1.0
# 
# Research Question: What factors drive hunger and hunger outbreaks, 
# and how will these factors change in the future?
# =============================================================================

# PROJECT OVERVIEW
# This script serves as the main framework for a comprehensive research project
# on global hunger, food insecurity, and predictive modeling. The project aims
# to identify patterns in historical hunger data and forecast future hunger crises.

# =============================================================================
# 1. ENVIRONMENT SETUP AND PACKAGE INSTALLATION
# =============================================================================

# Check if required packages are installed, install if not
required_packages <- c(
  # Data manipulation and analysis
  "tidyverse",      # dplyr, ggplot2, readr, etc.
  "data.table",     # Fast data manipulation
  "lubridate",      # Date/time handling
  
  # Statistical modeling
  "caret",          # Classification and regression training
  "randomForest",   # Random forest models
  "glmnet",         # Regularized regression
  "forecast",       # Time series forecasting
  "prophet",        # Facebook's time series forecasting
  
  # Geospatial analysis
  "sf",             # Simple features for R
  "rnaturalearth",  # World map data
  "leaflet",        # Interactive maps
  "mapview",        # Quick map visualization
  "tmap",           # Thematic maps
  
  # Data visualization
  "plotly",         # Interactive plots
  "shiny",          # Web applications
  "DT",             # Data tables
  "RColorBrewer",   # Color palettes
  
  # Data sources and APIs
  "jsonlite",       # JSON data handling
  "httr",           # HTTP requests
  "WDI",            # World Bank data
  "FAOSTAT",        # FAO data (if available)
  
  # Utilities
  "here",           # Project-relative paths
  "conflicted",     # Resolve package conflicts
  "janitor",        # Data cleaning
  "skimr"           # Data summary
)

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    cat("Installing missing packages:", paste(new_packages, collapse = ", "), "\n")
    install.packages(new_packages, dependencies = TRUE)
  } else {
    cat("All required packages are already installed.\n")
  }
}

# Install missing packages
install_if_missing(required_packages)

# Load core packages
library(tidyverse)
library(here)
library(conflicted)

# Resolve common conflicts
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")

# =============================================================================
# 2. PROJECT STRUCTURE SETUP
# =============================================================================

# Create project directories if they don't exist
project_dirs <- c(
  "data/raw",           # Raw data files
  "data/processed",     # Cleaned and processed data
  "data/external",      # External data sources
  "scripts",            # R scripts
  "models",             # Saved models
  "outputs/figures",    # Plots and visualizations
  "outputs/maps",       # Map outputs
  "outputs/reports",    # Generated reports
  "docs"                # Documentation
)

create_directories <- function(dirs) {
  for(dir in dirs) {
    if(!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE)
      cat("Created directory:", dir, "\n")
    }
  }
}

create_directories(project_dirs)

# =============================================================================
# 3. DATA SOURCES AND COLLECTION FRAMEWORK
# =============================================================================

# Define key data sources for the project
data_sources <- list(
  # Food and Agriculture Organization (FAO)
  fao = list(
    name = "Food and Agriculture Organization",
    url = "http://www.fao.org/faostat/en/#data",
    key_datasets = c("Food Security Indicators", "Food Balance Sheets", 
                     "Production", "Trade", "Prices"),
    variables = c("undernourishment", "food_supply", "production", 
                  "imports", "exports", "prices")
  ),
  
  # World Food Programme (WFP)
  wfp = list(
    name = "World Food Programme",
    url = "https://dataviz.vam.wfp.org/",
    key_datasets = c("Food Security", "Market Prices", "Vulnerability Analysis"),
    variables = c("food_security", "market_prices", "vulnerability_index")
  ),
  
  # World Bank
  world_bank = list(
    name = "World Bank",
    url = "https://data.worldbank.org/",
    key_datasets = c("World Development Indicators", "Global Economic Monitor"),
    variables = c("gdp", "inflation", "population", "poverty_rate", 
                  "agricultural_value_added")
  ),
  
  # EM-DAT (Emergency Events Database)
  emdat = list(
    name = "EM-DAT International Disaster Database",
    url = "https://www.emdat.be/",
    key_datasets = c("Natural Disasters", "Technological Disasters"),
    variables = c("drought", "flood", "conflict", "disaster_frequency")
  ),
  
  # Additional sources
  additional = list(
    name = "Additional Sources",
    sources = c("UNHCR (Refugee data)", "OECD", "CIA World Factbook", 
                "Global Conflict Database", "Climate Data")
  )
)

# Function to document data collection progress
document_data_source <- function(source_name, status = "planned") {
  cat("Data Source:", source_name, "- Status:", status, "\n")
}

# =============================================================================
# 4. INITIAL DATA COLLECTION FUNCTIONS
# =============================================================================

# Function to collect World Bank data
collect_world_bank_data <- function() {
  library(WDI)
  
  # Key indicators for hunger research
  indicators <- c(
    "SP.POP.TOTL",           # Population, total
    "NY.GDP.MKTP.CD",        # GDP (current US$)
    "FP.CPI.TOTL.ZG",        # Inflation, consumer prices (annual %)
    "SI.POV.DDAY",           # Poverty headcount ratio at $1.90/day
    "AG.LND.AGRI.ZS",        # Agricultural land (% of land area)
    "AG.PRD.CROP.XD",        # Crop production index
    "SP.RUR.TOTL.ZS"         # Rural population (% of total population)
  )
  
  # Collect data for all countries
  wb_data <- WDI(country = "all", 
                 indicator = indicators,
                 start = 2000, 
                 end = 2023,
                 extra = TRUE)
  
  return(wb_data)
}

# Function to collect FAO data (placeholder - requires specific API setup)
collect_fao_data <- function() {
  cat("FAO data collection requires specific API setup.\n")
  cat("Consider using FAOSTAT R package or manual download from FAO website.\n")
  return(NULL)
}

# =============================================================================
# 5. DATA CLEANING AND PREPROCESSING FRAMEWORK
# =============================================================================

# Function to clean and standardize country names
standardize_countries <- function(data, country_col = "country") {
  # Common country name standardization
  country_mapping <- data.frame(
    original = c("United States", "United Kingdom", "Russian Federation", 
                 "Korea, Rep.", "Korea, Dem. People's Rep.", "Iran, Islamic Rep.",
                 "Venezuela, RB", "Egypt, Arab Rep.", "Yemen, Rep."),
    standardized = c("USA", "UK", "Russia", "South Korea", "North Korea", 
                     "Iran", "Venezuela", "Egypt", "Yemen"),
    stringsAsFactors = FALSE
  )
  
  # Apply standardization
  for(i in 1:nrow(country_mapping)) {
    data[[country_col]] <- gsub(country_mapping$original[i], 
                               country_mapping$standardized[i], 
                               data[[country_col]])
  }
  
  return(data)
}

# Function to handle missing data
handle_missing_data <- function(data, method = "interpolation") {
  library(zoo)
  
  if(method == "interpolation") {
    # Linear interpolation for time series data
    numeric_cols <- sapply(data, is.numeric)
    data[numeric_cols] <- lapply(data[numeric_cols], function(x) {
      if(sum(!is.na(x)) > 1) {
        na.approx(x, na.rm = FALSE)
      } else {
        x
      }
    })
  }
  
  return(data)
}

# =============================================================================
# 6. EXPLORATORY DATA ANALYSIS FRAMEWORK
# =============================================================================

# Function to create summary statistics
create_data_summary <- function(data) {
  library(skimr)
  
  summary_stats <- skim(data)
  return(summary_stats)
}

# Function to identify hunger hotspots
identify_hunger_hotspots <- function(data, threshold = 0.2) {
  # This is a placeholder function - will be refined based on actual data
  hotspots <- data %>%
    filter(undernourishment_rate > threshold) %>%
    arrange(desc(undernourishment_rate))
  
  return(hotspots)
}

# =============================================================================
# 7. MODELING FRAMEWORK
# =============================================================================

# Function to prepare data for modeling
prepare_modeling_data <- function(data) {
  # Remove rows with too many missing values
  clean_data <- data %>%
    filter(rowSums(is.na(.)) < ncol(.) * 0.5)
  
  # Create lagged variables for time series analysis
  # This will be expanded based on specific modeling needs
  
  return(clean_data)
}

# Function to train hunger prediction model
train_hunger_model <- function(data, target_variable = "hunger_outbreak") {
  library(caret)
  library(randomForest)
  
  # Split data into training and testing sets
  set.seed(123)
  trainIndex <- createDataPartition(data[[target_variable]], 
                                   p = 0.8, list = FALSE)
  train_data <- data[trainIndex, ]
  test_data <- data[-trainIndex, ]
  
  # Train random forest model (placeholder)
  model <- randomForest(
    as.formula(paste(target_variable, "~ .")),
    data = train_data,
    ntree = 100,
    importance = TRUE
  )
  
  # Make predictions
  predictions <- predict(model, test_data)
  
  # Calculate performance metrics
  performance <- postResample(predictions, test_data[[target_variable]])
  
  return(list(
    model = model,
    predictions = predictions,
    performance = performance,
    test_data = test_data
  ))
}

# =============================================================================
# 8. VISUALIZATION FRAMEWORK
# =============================================================================

# Function to create hunger trend plots
plot_hunger_trends <- function(data, country = NULL) {
  library(ggplot2)
  
  if(!is.null(country)) {
    data <- data %>% filter(country == !!country)
  }
  
  p <- ggplot(data, aes(x = year, y = undernourishment_rate)) +
    geom_line(aes(color = country), size = 1) +
    geom_point(aes(color = country), size = 2) +
    labs(
      title = "Hunger Trends Over Time",
      x = "Year",
      y = "Undernourishment Rate (%)",
      color = "Country"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      axis.title = element_text(size = 12),
      legend.position = "bottom"
    )
  
  return(p)
}

# Function to create world hunger map
create_hunger_map <- function(data, year = 2020) {
  library(sf)
  library(rnaturalearth)
  library(ggplot2)
  
  # Get world map data
  world <- ne_countries(scale = "medium", returnclass = "sf")
  
  # Filter data for specific year
  year_data <- data %>% filter(year == !!year)
  
  # Merge with world map
  world_hunger <- world %>%
    left_join(year_data, by = c("name" = "country"))
  
  # Create map
  p <- ggplot(world_hunger) +
    geom_sf(aes(fill = undernourishment_rate), color = "white", size = 0.1) +
    scale_fill_viridis_c(
      name = "Undernourishment\nRate (%)",
      na.value = "grey90",
      option = "plasma"
    ) +
    labs(
      title = paste("Global Hunger Map -", year),
      subtitle = "Undernourishment rates by country"
    ) +
    theme_void() +
    theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5),
      legend.position = "bottom"
    )
  
  return(p)
}

# =============================================================================
# 9. INTERACTIVE DASHBOARD FRAMEWORK
# =============================================================================

# Function to create Shiny dashboard (placeholder)
create_interactive_dashboard <- function() {
  library(shiny)
  library(leaflet)
  
  # This is a placeholder for the interactive dashboard
  # Will be expanded in future iterations
  
  ui <- fluidPage(
    titlePanel("Global Hunger Research Dashboard"),
    sidebarLayout(
      sidebarPanel(
        h3("Controls"),
        selectInput("country", "Select Country:", 
                   choices = c("All", "Afghanistan", "Ethiopia", "Yemen")),
        sliderInput("year", "Year:", 
                   min = 2000, max = 2023, value = 2020)
      ),
      mainPanel(
        h3("Hunger Analysis"),
        plotOutput("hunger_plot"),
        leafletOutput("hunger_map")
      )
    )
  )
  
  server <- function(input, output) {
    # Placeholder server logic
    output$hunger_plot <- renderPlot({
      # Placeholder plot
      plot(1:10, 1:10, main = "Hunger Trends")
    })
    
    output$hunger_map <- renderLeaflet({
      # Placeholder map
      leaflet() %>%
        addTiles() %>%
        setView(lng = 0, lat = 20, zoom = 2)
    })
  }
  
  return(list(ui = ui, server = server))
}

# =============================================================================
# 10. MAIN EXECUTION FUNCTION
# =============================================================================

# Main function to run the research project
run_hunger_research <- function() {
  cat("Starting Global Hunger Research Project...\n")
  cat("==========================================\n\n")
  
  # Step 1: Collect data
  cat("Step 1: Collecting data from various sources...\n")
  wb_data <- collect_world_bank_data()
  
  # Step 2: Clean and process data
  cat("Step 2: Cleaning and processing data...\n")
  clean_data <- standardize_countries(wb_data)
  clean_data <- handle_missing_data(clean_data)
  
  # Step 3: Exploratory analysis
  cat("Step 3: Performing exploratory data analysis...\n")
  summary_stats <- create_data_summary(clean_data)
  print(summary_stats)
  
  # Step 4: Create visualizations
  cat("Step 4: Creating visualizations...\n")
  hunger_plot <- plot_hunger_trends(clean_data)
  print(hunger_plot)
  
  # Step 5: Save outputs
  cat("Step 5: Saving outputs...\n")
  ggsave("outputs/figures/hunger_trends.png", hunger_plot, 
         width = 12, height = 8, dpi = 300)
  
  cat("\nResearch project framework initialized successfully!\n")
  cat("Next steps:\n")
  cat("1. Collect additional data from FAO, WFP, and EM-DAT\n")
  cat("2. Refine data cleaning and preprocessing\n")
  cat("3. Develop predictive models\n")
  cat("4. Create interactive visualizations\n")
  cat("5. Build web dashboard\n")
  
  return(list(
    world_bank_data = wb_data,
    clean_data = clean_data,
    summary_stats = summary_stats
  ))
}

# =============================================================================
# 11. LEARNING ROADMAP AND NEXT STEPS
# =============================================================================

learning_roadmap <- list(
  "Phase 1: R Fundamentals" = c(
    "Complete R basics course (edX, Coursera)",
    "Practice data manipulation with dplyr",
    "Learn ggplot2 for visualization",
    "Understand statistical concepts"
  ),
  
  "Phase 2: Advanced R" = c(
    "Time series analysis with forecast package",
    "Machine learning with caret and randomForest",
    "Geospatial analysis with sf and leaflet",
    "Web applications with Shiny"
  ),
  
  "Phase 3: Data Collection" = c(
    "Set up APIs for FAO, WFP, World Bank",
    "Learn web scraping techniques",
    "Data cleaning and preprocessing",
    "Database management"
  ),
  
  "Phase 4: Modeling" = c(
    "Statistical modeling techniques",
    "Time series forecasting",
    "Machine learning algorithms",
    "Model validation and testing"
  ),
  
  "Phase 5: Visualization" = c(
    "Interactive maps with leaflet",
    "Dashboard development with Shiny",
    "Web design and user experience",
    "Data storytelling"
  )
)

# Print learning roadmap
print_learning_roadmap <- function() {
  cat("LEARNING ROADMAP FOR HUNGER RESEARCH PROJECT\n")
  cat("============================================\n\n")
  
  for(phase in names(learning_roadmap)) {
    cat(phase, ":\n")
    for(item in learning_roadmap[[phase]]) {
      cat("  -", item, "\n")
    }
    cat("\n")
  }
}

# =============================================================================
# EXECUTION
# =============================================================================

# Uncomment the line below to run the main research function
# results <- run_hunger_research()

# Print learning roadmap
print_learning_roadmap()

cat("\nProject framework loaded successfully!\n")
cat("To start the research project, run: results <- run_hunger_research()\n")
