# =============================================================================
# LEARNING ROADMAP FOR HUNGER RESEARCH PROJECT
# Author: Garrett Zhou
# Date: October 2024
# 
# This script provides a structured learning path for developing the skills
# needed for the global hunger research project.
# =============================================================================

# =============================================================================
# 1. LEARNING PHASES OVERVIEW
# =============================================================================

learning_phases <- list(
  "Phase 1: R Fundamentals (Weeks 1-4)" = list(
    duration = "4 weeks",
    focus = "Basic R programming and data manipulation",
    resources = c(
      "edX: Introduction to R Programming",
      "Coursera: R Programming (Johns Hopkins)",
      "DataCamp: Introduction to R",
      "R for Data Science (book by Hadley Wickham)"
    ),
    skills = c(
      "R syntax and basic operations",
      "Data types and structures",
      "Functions and control flow",
      "Data import/export",
      "Basic data manipulation with dplyr",
      "Basic visualization with ggplot2"
    ),
    practice_projects = c(
      "Analyze World Bank data with basic R",
      "Create simple hunger trend plots",
      "Clean and explore sample datasets"
    )
  ),
  
  "Phase 2: Data Analysis and Statistics (Weeks 5-8)" = list(
    duration = "4 weeks",
    focus = "Statistical analysis and data exploration",
    resources = c(
      "edX: Statistics and R",
      "Coursera: Statistical Inference",
      "DataCamp: Statistical Thinking in R",
      "Introduction to Statistical Learning (book)"
    ),
    skills = c(
      "Descriptive statistics",
      "Hypothesis testing",
      "Correlation and regression",
      "Data visualization best practices",
      "Exploratory data analysis",
      "Statistical modeling basics"
    ),
    practice_projects = c(
      "Correlation analysis of hunger factors",
      "Regression models for hunger prediction",
      "Statistical significance testing"
    )
  ),
  
  "Phase 3: Advanced R and Time Series (Weeks 9-12)" = list(
    duration = "4 weeks",
    focus = "Advanced R techniques and time series analysis",
    resources = c(
      "edX: Advanced R Programming",
      "Coursera: Time Series Analysis",
      "DataCamp: Time Series Analysis in R",
      "Forecasting: Principles and Practice (book)"
    ),
    skills = c(
      "Advanced data manipulation",
      "Time series analysis",
      "Forecasting techniques",
      "Data cleaning and preprocessing",
      "Package development basics",
      "Reproducible research"
    ),
    practice_projects = c(
      "Time series analysis of hunger trends",
      "Forecast future hunger scenarios",
      "Create reproducible analysis pipeline"
    )
  ),
  
  "Phase 4: Machine Learning (Weeks 13-16)" = list(
    duration = "4 weeks",
    focus = "Machine learning and predictive modeling",
    resources = c(
      "Coursera: Machine Learning",
      "DataCamp: Machine Learning in R",
      "Applied Predictive Modeling (book)",
      "The Elements of Statistical Learning (book)"
    ),
    skills = c(
      "Supervised learning algorithms",
      "Model validation and testing",
      "Feature engineering",
      "Cross-validation",
      "Model selection",
      "Performance metrics"
    ),
    practice_projects = c(
      "Build hunger prediction models",
      "Compare different ML algorithms",
      "Feature importance analysis"
    )
  ),
  
  "Phase 5: Geospatial Analysis (Weeks 17-20)" = list(
    duration = "4 weeks",
    focus = "Geospatial data analysis and mapping",
    resources = c(
      "HarvardX: Digital Humanities",
      "DataCamp: Geospatial Analysis in R",
      "Spatial Data Science (book)",
      "Geocomputation with R (book)"
    ),
    skills = c(
      "Spatial data handling",
      "Interactive mapping",
      "Geospatial statistics",
      "Coordinate systems",
      "Spatial visualization",
      "Web mapping"
    ),
    practice_projects = c(
      "Create hunger hotspot maps",
      "Interactive world hunger visualization",
      "Spatial analysis of hunger patterns"
    )
  ),
  
  "Phase 6: Web Applications and Dashboards (Weeks 21-24)" = list(
    duration = "4 weeks",
    focus = "Interactive web applications and dashboards",
    resources = c(
      "DataCamp: Building Web Applications with Shiny",
      "Mastering Shiny (book)",
      "R Markdown: The Definitive Guide (book)",
      "Web development basics (HTML, CSS, JavaScript)"
    ),
    skills = c(
      "Shiny application development",
      "Interactive dashboards",
      "Web design principles",
      "User experience design",
      "Deployment and hosting",
      "Documentation and reporting"
    ),
    practice_projects = c(
      "Build hunger research dashboard",
      "Create interactive data explorer",
      "Deploy web application"
    )
  )
)

# =============================================================================
# 2. WEEKLY LEARNING SCHEDULE
# =============================================================================

weekly_schedule <- list(
  "Week 1-2: R Basics" = c(
    "Day 1-3: R syntax, data types, basic operations",
    "Day 4-7: Functions, control flow, data structures",
    "Practice: Complete 5-10 basic R exercises daily"
  ),
  
  "Week 3-4: Data Manipulation" = c(
    "Day 1-3: dplyr package, data filtering, grouping",
    "Day 4-7: Data import/export, data cleaning",
    "Practice: Work with World Bank dataset"
  ),
  
  "Week 5-6: Visualization" = c(
    "Day 1-3: ggplot2 basics, plot types",
    "Day 4-7: Advanced ggplot2, plot customization",
    "Practice: Create hunger trend visualizations"
  ),
  
  "Week 7-8: Statistics" = c(
    "Day 1-3: Descriptive statistics, hypothesis testing",
    "Day 4-7: Correlation, regression analysis",
    "Practice: Statistical analysis of hunger data"
  ),
  
  "Week 9-10: Time Series" = c(
    "Day 1-3: Time series basics, decomposition",
    "Day 4-7: Forecasting, ARIMA models",
    "Practice: Forecast hunger trends"
  ),
  
  "Week 11-12: Advanced R" = c(
    "Day 1-3: Advanced data manipulation, functions",
    "Day 4-7: Package development, reproducible research",
    "Practice: Build analysis pipeline"
  ),
  
  "Week 13-14: Machine Learning Basics" = c(
    "Day 1-3: Supervised learning, train/test split",
    "Day 4-7: Linear regression, decision trees",
    "Practice: Build simple prediction models"
  ),
  
  "Week 15-16: Advanced ML" = c(
    "Day 1-3: Random forest, cross-validation",
    "Day 4-7: Model evaluation, feature selection",
    "Practice: Optimize hunger prediction models"
  ),
  
  "Week 17-18: Geospatial Basics" = c(
    "Day 1-3: Spatial data, coordinate systems",
    "Day 4-7: Basic mapping, spatial visualization",
    "Practice: Create basic hunger maps"
  ),
  
  "Week 19-20: Interactive Mapping" = c(
    "Day 1-3: Leaflet, interactive maps",
    "Day 4-7: Spatial analysis, advanced mapping",
    "Practice: Build interactive hunger dashboard"
  ),
  
  "Week 21-22: Shiny Basics" = c(
    "Day 1-3: Shiny structure, reactive programming",
    "Day 4-7: UI design, server logic",
    "Practice: Create simple Shiny app"
  ),
  
  "Week 23-24: Advanced Shiny" = c(
    "Day 1-3: Advanced Shiny features, deployment",
    "Day 4-7: Dashboard design, user experience",
    "Practice: Deploy hunger research dashboard"
  )
)

# =============================================================================
# 3. PRACTICE EXERCISES AND PROJECTS
# =============================================================================

practice_exercises <- list(
  "Beginner Exercises" = c(
    "Load World Bank data and explore structure",
    "Calculate basic statistics for hunger indicators",
    "Create simple bar charts and line plots",
    "Filter data by country and year",
    "Calculate correlation between variables"
  ),
  
  "Intermediate Exercises" = c(
    "Build regression model to predict hunger",
    "Create time series plot of hunger trends",
    "Perform statistical tests on hunger data",
    "Clean and preprocess messy datasets",
    "Create publication-quality visualizations"
  ),
  
  "Advanced Exercises" = c(
    "Build machine learning model for hunger prediction",
    "Create interactive map of hunger hotspots",
    "Develop Shiny dashboard for data exploration",
    "Implement time series forecasting",
    "Deploy web application for public access"
  ),
  
  "Project Milestones" = c(
    "Week 4: Basic data analysis of World Bank hunger data",
    "Week 8: Statistical analysis and visualization of hunger trends",
    "Week 12: Time series analysis and forecasting",
    "Week 16: Machine learning model for hunger prediction",
    "Week 20: Interactive map of global hunger",
    "Week 24: Complete web dashboard for hunger research"
  )
)

# =============================================================================
# 4. RESOURCE LINKS AND REFERENCES
# =============================================================================

learning_resources <- list(
  "Online Courses" = list(
    "edX" = c(
      "Introduction to R Programming",
      "Statistics and R",
      "Advanced R Programming",
      "HarvardX Digital Humanities"
    ),
    "Coursera" = c(
      "R Programming (Johns Hopkins)",
      "Statistical Inference",
      "Time Series Analysis",
      "Machine Learning"
    ),
    "DataCamp" = c(
      "Introduction to R",
      "Statistical Thinking in R",
      "Time Series Analysis in R",
      "Machine Learning in R",
      "Geospatial Analysis in R",
      "Building Web Applications with Shiny"
    )
  ),
  
  "Books" = list(
    "R Programming" = c(
      "R for Data Science (Hadley Wickham)",
      "Advanced R (Hadley Wickham)",
      "The Art of R Programming (Norman Matloff)"
    ),
    "Statistics" = c(
      "Introduction to Statistical Learning",
      "The Elements of Statistical Learning",
      "Applied Predictive Modeling"
    ),
    "Time Series" = c(
      "Forecasting: Principles and Practice",
      "Time Series Analysis and Its Applications"
    ),
    "Geospatial" = c(
      "Geocomputation with R",
      "Spatial Data Science"
    ),
    "Web Development" = c(
      "Mastering Shiny",
      "R Markdown: The Definitive Guide"
    )
  ),
  
  "Online Resources" = list(
    "Documentation" = c(
      "R Documentation: https://www.r-project.org/",
      "CRAN Task Views: https://cran.r-project.org/web/views/",
      "R-bloggers: https://www.r-bloggers.com/"
    ),
    "Communities" = c(
      "Stack Overflow: https://stackoverflow.com/questions/tagged/r",
      "RStudio Community: https://community.rstudio.com/",
      "Reddit r/rstats: https://www.reddit.com/r/rstats/"
    ),
    "Data Sources" = c(
      "World Bank: https://data.worldbank.org/",
      "FAO: http://www.fao.org/faostat/en/#data",
      "WFP: https://dataviz.vam.wfp.org/",
      "EM-DAT: https://www.emdat.be/"
    )
  )
)

# =============================================================================
# 5. PROGRESS TRACKING FUNCTIONS
# =============================================================================

create_learning_log <- function() {
  log_data <- data.frame(
    date = as.Date(character()),
    phase = character(),
    topic = character(),
    time_spent = numeric(),
    resources_used = character(),
    skills_practiced = character(),
    notes = character(),
    stringsAsFactors = FALSE
  )
  
  write_csv(log_data, here("docs/learning_log.csv"))
  cat("Learning log created at docs/learning_log.csv\n")
}

log_learning_session <- function(phase, topic, time_spent, resources, skills, notes) {
  log_entry <- data.frame(
    date = Sys.Date(),
    phase = phase,
    topic = topic,
    time_spent = time_spent,
    resources_used = resources,
    skills_practiced = skills,
    notes = notes,
    stringsAsFactors = FALSE
  )
  
  # Append to existing log
  if(file.exists(here("docs/learning_log.csv"))) {
    existing_log <- read_csv(here("docs/learning_log.csv"))
    updated_log <- rbind(existing_log, log_entry)
  } else {
    updated_log <- log_entry
  }
  
  write_csv(updated_log, here("docs/learning_log.csv"))
  cat("Learning session logged successfully!\n")
}

# =============================================================================
# 6. SKILL ASSESSMENT CHECKLIST
# =============================================================================

skill_checklist <- list(
  "R Fundamentals" = c(
    "□ Understand R syntax and basic operations",
    "□ Work with different data types and structures",
    "□ Write and use functions effectively",
    "□ Implement control flow (if/else, loops)",
    "□ Import and export data from various formats"
  ),
  
  "Data Manipulation" = c(
    "□ Use dplyr for data filtering and transformation",
    "□ Handle missing data appropriately",
    "□ Merge and join datasets",
    "□ Reshape data (wide to long, long to wide)",
    "□ Create and modify variables"
  ),
  
  "Data Visualization" = c(
    "□ Create basic plots with ggplot2",
    "□ Customize plot appearance and themes",
    "□ Create publication-quality visualizations",
    "□ Use appropriate plot types for different data",
    "□ Add annotations and labels effectively"
  ),
  
  "Statistical Analysis" = c(
    "□ Calculate descriptive statistics",
    "□ Perform hypothesis testing",
    "□ Conduct correlation and regression analysis",
    "□ Interpret statistical results",
    "□ Validate statistical assumptions"
  ),
  
  "Time Series Analysis" = c(
    "□ Handle time series data structures",
    "□ Perform time series decomposition",
    "□ Build forecasting models",
    "□ Validate time series models",
    "□ Interpret time series results"
  ),
  
  "Machine Learning" = c(
    "□ Split data into training and testing sets",
    "□ Build and evaluate predictive models",
    "□ Use cross-validation techniques",
    "□ Compare different algorithms",
    "□ Interpret model results and feature importance"
  ),
  
  "Geospatial Analysis" = c(
    "□ Work with spatial data formats",
    "□ Create static and interactive maps",
    "□ Perform spatial analysis",
    "□ Handle coordinate systems",
    "□ Visualize spatial patterns"
  ),
  
  "Web Applications" = c(
    "□ Build basic Shiny applications",
    "□ Design user interfaces",
    "□ Implement reactive programming",
    "□ Deploy web applications",
    "□ Create interactive dashboards"
  )
)

# =============================================================================
# 7. PRINTING FUNCTIONS
# =============================================================================

print_learning_phases <- function() {
  cat("LEARNING PHASES FOR HUNGER RESEARCH PROJECT\n")
  cat("===========================================\n\n")
  
  for(phase in names(learning_phases)) {
    cat(phase, "\n")
    cat("Duration:", learning_phases[[phase]]$duration, "\n")
    cat("Focus:", learning_phases[[phase]]$focus, "\n")
    cat("Resources:\n")
    for(resource in learning_phases[[phase]]$resources) {
      cat("  -", resource, "\n")
    }
    cat("Skills to develop:\n")
    for(skill in learning_phases[[phase]]$skills) {
      cat("  -", skill, "\n")
    }
    cat("Practice projects:\n")
    for(project in learning_phases[[phase]]$practice_projects) {
      cat("  -", project, "\n")
    }
    cat("\n")
  }
}

print_weekly_schedule <- function() {
  cat("WEEKLY LEARNING SCHEDULE\n")
  cat("========================\n\n")
  
  for(week in names(weekly_schedule)) {
    cat(week, ":\n")
    for(day in weekly_schedule[[week]]) {
      cat("  ", day, "\n")
    }
    cat("\n")
  }
}

print_skill_checklist <- function() {
  cat("SKILL ASSESSMENT CHECKLIST\n")
  cat("==========================\n\n")
  
  for(category in names(skill_checklist)) {
    cat(category, ":\n")
    for(skill in skill_checklist[[category]]) {
      cat("  ", skill, "\n")
    }
    cat("\n")
  }
}

# =============================================================================
# 8. MAIN EXECUTION
# =============================================================================

# Create learning log
create_learning_log()

# Print learning information
print_learning_phases()
print_weekly_schedule()
print_skill_checklist()

cat("Learning roadmap loaded successfully!\n")
cat("Use log_learning_session() to track your progress.\n")
cat("Example: log_learning_session('Phase 1', 'R Basics', 2, 'edX course', 'R syntax', 'Completed first module')\n")
