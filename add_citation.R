# =============================================================================
# CITATION HELPER SCRIPT
# =============================================================================
# This script helps you add properly formatted citations to app.R
# 
# Usage:
# 1. Paste a URL below
# 2. Fill in any additional information (organization, title, year)
# 3. Run this script to generate the citation code
# 4. Copy the output and add it to the citations_data list in app.R
# =============================================================================

# Function to generate citation code from URL
generate_citation <- function(url, organization = NULL, title = NULL, year = NULL, description = NULL) {
  
  # Extract domain to help identify organization if not provided
  domain <- gsub("^https?://(www\\.)?", "", url)
  domain <- gsub("/.*$", "", domain)
  
  # Try to infer organization from domain
  if(is.null(organization)) {
    org_mapping <- list(
      "worldbank.org" = "World Bank",
      "fao.org" = "Food and Agriculture Organization of the United Nations (FAO)",
      "wfp.org" = "World Food Programme (WFP)",
      "who.int" = "World Health Organization (WHO)",
      "globaldatalab.org" = "Global Data Lab",
      "ourworldindata.org" = "Our World in Data",
      "unhcr.org" = "United Nations High Commissioner for Refugees (UNHCR)",
      "un.org" = "United Nations",
      "data.un.org" = "United Nations Statistics Division"
    )
    
    organization <- org_mapping[[domain]]
    if(is.null(organization)) {
      organization <- domain  # Use domain as fallback
    }
  }
  
  # Use current year if not provided
  if(is.null(year)) {
    year <- format(Sys.Date(), "%Y")
  }
  
  # Generate title if not provided
  if(is.null(title)) {
    # Try to extract from URL path
    path <- gsub("^https?://[^/]+", "", url)
    path <- gsub("^/", "", path)
    path <- gsub("/$", "", path)
    path <- gsub("-", " ", path)
    path <- gsub("_", " ", path)
    # Capitalize first letter of each word
    title <- paste(toupper(substring(strsplit(path, "/")[[1]], 1, 1)), 
                   substring(strsplit(path, "/")[[1]], 2), sep = "", collapse = " ")
    if(nchar(title) > 100) {
      title <- paste(substring(title, 1, 97), "...")
    }
    if(title == "" || is.na(title)) {
      title <- "Data Portal"
    }
  }
  
  # Generate description if not provided
  if(is.null(description)) {
    description <- paste("Data from", organization)
  }
  
  # Generate the R code for the citation
  citation_code <- paste0(
    "    list(\n",
    "      organization = \"", organization, "\",\n",
    "      title = \"", title, "\",\n",
    "      url = \"", url, "\",\n",
    "      year = \"", year, "\",\n",
    "      accessed_date = format(Sys.Date(), \"%B %d, %Y\"),\n",
    "      description = \"", description, "\"\n",
    "    )"
  )
  
  # Also generate a preview of the formatted citation
  citation_preview <- paste0(
    organization, ". (", year, "). ", title, ". Retrieved from ", url,
    " (accessed ", format(Sys.Date(), "%B %d, %Y"), ")."
  )
  
  cat("\n")
  cat(paste(rep("=", 70), collapse = ""))
  cat("\n")
  cat("CITATION CODE (copy this to app.R):\n")
  cat(paste(rep("=", 70), collapse = ""))
  cat("\n")
  cat(citation_code)
  cat("\n\n")
  cat("PREVIEW (how it will appear):\n")
  cat(paste(rep("=", 70), collapse = ""))
  cat("\n")
  cat(citation_preview)
  cat("\n\n")
  cat("DESCRIPTION:\n")
  cat(paste(rep("=", 70), collapse = ""))
  cat("\n")
  cat(description)
  cat("\n\n")
  
  return(list(
    code = citation_code,
    preview = citation_preview,
    organization = organization,
    title = title,
    year = year,
    description = description
  ))
}

# =============================================================================
# ADD YOUR CITATION INFORMATION HERE
# =============================================================================

# Example usage:
# citation <- generate_citation(
#   url = "https://data.worldbank.org/",
#   organization = "World Bank",
#   title = "World Development Indicators",
#   year = "2024",
#   description = "Economic indicators, GDP, poverty rates, population, life expectancy, and demographic data"
# )

# For quick addition, just paste the URL:
# citation <- generate_citation(url = "PASTE_URL_HERE")

# =============================================================================
# QUICK ADD FUNCTION - Just paste your URL here
# =============================================================================

# Uncomment and paste your URL:
# generate_citation(url = "https://example.com/data")

# Example with full details:
# generate_citation(
#   url = "https://data.worldbank.org/indicator/SI.POV.DDAY",
#   organization = "World Bank",
#   title = "Poverty headcount ratio at $1.90/day",
#   year = "2024",
#   description = "Percentage of population living below $1.90/day poverty line"
# )

# =============================================================================
# BATCH ADD MULTIPLE CITATIONS
# =============================================================================

# If you have multiple URLs, you can add them like this:
# 
# urls <- c(
#   "https://data.worldbank.org/",
#   "https://www.fao.org/faostat/en/#data",
#   "https://www.wfp.org/publications/global-report-food-crises-2025"
# )
# 
# for(url in urls) {
#   generate_citation(url = url)
#   cat("\n\n")
# }

cat("\n")
cat(paste(rep("=", 70), collapse = ""))
cat("\n")
cat("CITATION HELPER SCRIPT\n")
cat(paste(rep("=", 70), collapse = ""))
cat("\n")
cat("\n")
cat("To add a citation:\n")
cat("1. Uncomment the generate_citation() line below\n")
cat("2. Paste your URL in the url parameter\n")
cat("3. Optionally add organization, title, year, and description\n")
cat("4. Run this script\n")
cat("5. Copy the generated code to the citations_data list in app.R\n")
cat("\n")
cat("Example:\n")
cat('  generate_citation(url = "https://data.worldbank.org/")\n')
cat("\n")

