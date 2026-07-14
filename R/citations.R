# Data Sources tab: catalog + file detection under data/raw

raw_archive_detect <- function(raw_root, paths = character(), dirs = character(), patterns = character()) {
  if (!dir.exists(raw_root)) return(FALSE)
  if (length(paths) > 0) {
    if (any(file.exists(file.path(raw_root, paths)))) return(TRUE)
  }
  if (length(dirs) > 0) {
    if (any(dir.exists(file.path(raw_root, dirs)))) return(TRUE)
  }
  if (length(patterns) > 0) {
    hits <- unlist(lapply(patterns, function(pat) {
      Sys.glob(file.path(raw_root, pat))
    }))
    if (length(hits) > 0) return(TRUE)
  }
  FALSE
}

build_dashboard_citations <- function(raw_root = file.path("data", "raw")) {
  raw_root <- normalizePath(raw_root, mustWork = FALSE)
  accessed_date <- format(Sys.Date(), "%B %d, %Y")
  accessed_year <- format(Sys.Date(), "%Y")

  entry <- function(id, category, organization, title, description, url = NULL, year = NULL,
                    paths = character(), dirs = character(), patterns = character()) {
    list(
      id = id,
      category = category,
      organization = organization,
      title = title,
      url = url,
      year = if (is.null(year) || !nzchar(year)) accessed_year else year,
      accessed_date = accessed_date,
      description = description,
      detected = raw_archive_detect(raw_root, paths = paths, dirs = dirs, patterns = patterns)
    )
  }

  list(
    entry(
      "world_bank_wdi", "Economic & Demographic Indicators", "World Bank",
      "World Development Indicators (WDI)",
      "Core country indicators: population, GDP, GDP per capita, poverty, life expectancy, infant mortality, literacy, agricultural land, and related series.",
      url = "https://databank.worldbank.org/source/world-development-indicators",
      paths = "world_bank_data.csv", dirs = "world bank"
    ),
    entry(
      "world_bank_pip", "Economic & Demographic Indicators", "World Bank",
      "Poverty and Inequality Platform (PIP)",
      "Supplemental poverty and inequality measures when standard WDI poverty series are missing.",
      url = "https://pip.worldbank.org/",
      patterns = c("world bank/pip*.csv")
    ),
    entry(
      "fao_faostat", "Food Security & Nutrition",
      "Food and Agriculture Organization of the United Nations (FAO)",
      "FAOSTAT — Food Security and Nutrition (undernourishment)",
      "Prevalence of undernourishment and related nutrition indicators; powers country trend charts and the undernourishment pillar.",
      url = "https://www.fao.org/faostat/",
      paths = c("fao/fao_data.csv", "fao/FAO_Data/Food_Security_Data_E_All_Data.csv"),
      dirs = "fao"
    ),
    entry(
      "fao_fpma", "Food Systems & Agriculture",
      "Food and Agriculture Organization of the United Nations (FAO)",
      "FAO Food Price Monitoring and Analysis (FPMA)",
      "Commodity and market price context (not merged into the vulnerability score).",
      url = "https://fpma.apps.fao.org/",
      patterns = c("fao/**/fao fpma data.csv", "fao/**/fpma*.csv")
    ),
    entry(
      "wfp_grfc", "Food Security & Nutrition",
      "Food Security Information Network (FSIN) and World Food Programme (WFP)",
      "Global Report on Food Crises (GRFC) — acute food insecurity",
      "IPC phase and population in crisis; used for acute food insecurity context in country profiles.",
      url = "https://www.fsinplatform.org/global-report-food-crises",
      year = "2025",
      patterns = c("wfp/grfc*_data.csv", "wfp/grfc*.xlsx"),
      dirs = "wfp"
    ),
    entry(
      "ipc_general", "Food Security & Nutrition",
      "Integrated Food Security Phase Classification (IPC) Global Partnership",
      "IPC/CH general country data",
      "Country-level IPC phases and phase 3+ population where GRFC coverage is incomplete.",
      url = "https://www.ipcinfo.org/",
      paths = "ipc/ipc data general data.csv",
      dirs = "ipc"
    ),
    entry(
      "ipc_population", "Food Security & Nutrition",
      "Integrated Food Security Phase Classification (IPC) Global Partnership",
      "IPC Population Tracking Tool (analysis workbook)",
      "Latest IPC population analysis per country from the Population Tracking Tool export.",
      url = "https://www.ipcinfo.org/",
      patterns = c("ipc/*population*.xlsx", "ipc/*Population*.xlsx")
    ),
    entry(
      "ipc_historical", "Food Security & Nutrition",
      "Integrated Food Security Phase Classification (IPC) Global Partnership",
      "IPC historical analyses (2017–2025)",
      "Country-year IPC panel for the GRFC & IPC trends tab.",
      url = "https://www.ipcinfo.org/",
      patterns = c("ipc/ipc all data*.csv", "ipc/*2017*.csv")
    ),
    entry(
      "who_stunting", "Food Security & Nutrition", "World Health Organization (WHO)",
      "Global Health Observatory (GHO) — child stunting",
      "Child stunting prevalence used in the vulnerability score.",
      url = "https://www.who.int/data/gho",
      paths = "who/child_stunting_data.csv",
      dirs = "who"
    ),
    entry(
      "owid_poverty", "Environment, Resources & Development", "Our World in Data",
      "Poverty below international lines",
      "Poverty series (including $3/day) for poverty_display when World Bank poverty is missing.",
      url = "https://ourworldindata.org/poverty",
      patterns = c("our_world_in_data/poverty*.csv")
    ),
    entry(
      "owid_food_supply", "Food Systems & Agriculture", "Our World in Data",
      "Food supply (kcal per capita per day)",
      "Dietary energy supply proxy used in the food supply pillar.",
      url = "https://ourworldindata.org/food-supply",
      patterns = c("our_world_in_data/food supply*.csv")
    ),
    entry(
      "owid_water", "Environment, Resources & Development", "Our World in Data",
      "Renewable freshwater resources per capita",
      "Water stress pillar input (m³ per capita per year).",
      url = "https://ourworldindata.org/freshwater",
      patterns = c("our_world_in_data/**/renewable-water*.csv", "our_world_in_data/**/freshwater*.csv")
    ),
    entry(
      "climate_cv", "Environment, Resources & Development",
      "Climate vulnerability project (CV indicators)",
      "Climate vulnerability index (exposure, sensitivity, capacity, food, water, health)",
      "Primary climate vulnerability index when available; preferred over Global Data Lab in merges.",
      paths = "climate vulnerability/cv/vulnerability/vulnerability.csv",
      dirs = "climate vulnerability"
    ),
    entry(
      "global_data_lab", "Environment, Resources & Development", "Global Data Lab",
      "Climate and health vulnerability indices",
      "Fallback climate and health vulnerability scores when CV project files are absent.",
      url = "https://globaldatalab.org/",
      patterns = c("global_data_lab/**/*.csv"),
      dirs = "global_data_lab"
    ),
    entry(
      "unhcr", "Displacement, Conflict & Disasters",
      "United Nations High Commissioner for Refugees (UNHCR)",
      "Refugee statistics and persons of concern",
      "Refugees and displaced populations for displacement context and country profiles.",
      url = "https://www.unhcr.org/refugee-statistics/",
      patterns = c("un/unhcr/**/*.csv"),
      dirs = c("un", "un/unhcr")
    ),
    entry(
      "hdx_idu", "Displacement, Conflict & Disasters",
      "Humanitarian Data Exchange (HDX) / Internal Displacement Monitoring Centre",
      "Internal Displacement Updates (IDU)",
      "Internal displacement event data used alongside UNHCR totals where available.",
      url = "https://data.humdata.org/",
      dirs = c("hdx/idu", "hdx", "idu")
    ),
    entry(
      "acled", "Displacement, Conflict & Disasters",
      "Armed Conflict Location & Event Data Project (ACLED)",
      "Conflict event and fatality data",
      "Conflict intensity inputs (fatalities, political violence, attacks on civilians).",
      url = "https://acleddata.com/",
      patterns = c("acled - conflict data/*.xlsx", "acled - conflict data/*.csv"),
      dirs = "acled - conflict data"
    ),
    entry(
      "emdat", "Displacement, Conflict & Disasters",
      "Centre for Research on the Epidemiology of Disasters (CRED)",
      "EM-DAT: International Disaster Database",
      "Disaster frequency and recency indicators.",
      url = "https://www.emdat.be/",
      paths = "em_dat/em_dat_data.csv",
      dirs = "em_dat"
    ),
    entry(
      "usda", "Food Systems & Agriculture",
      "United States Department of Agriculture (USDA)",
      "Agricultural productivity / production data",
      "Agricultural productivity proxy for production capacity.",
      url = "https://www.usda.gov/",
      patterns = c("usda/*.csv"),
      dirs = "usda"
    ),
    entry(
      "food_trade", "Food Systems & Agriculture", "Garrett Zhou (compiled)",
      "Food trade dependency (import share)",
      "Average and maximum food import dependency used in the trade pillar.",
      paths = "food trade dependency/data overview.csv",
      dirs = "food trade dependency"
    ),
    entry(
      "germanwatch", "Environment, Resources & Development", "Germanwatch",
      "Global Climate Risk Index (CRI)",
      "Climate risk context and documentation in the research archive.",
      url = "https://www.germanwatch.org/en/cri",
      patterns = c("germanwatch/**/*.pdf", "germanwatch/**/*.csv"),
      dirs = "germanwatch"
    ),
    entry(
      "ghi", "Comparison Indices",
      "Welthungerhilfe and Concern Worldwide",
      "Global Hunger Index (GHI)",
      "Benchmark hunger index for comparison with the composite vulnerability score.",
      url = "https://www.globalhungerindex.org/",
      year = "2025",
      patterns = c("global hunger index/*.xlsx", "global hunger index/*.csv"),
      dirs = "global hunger index"
    ),
    entry(
      "wpr_malnutrition", "Food Security & Nutrition", "World Population Review",
      "Malnutrition rate by country",
      "Supplemental malnutrition context in country profiles.",
      url = "https://worldpopulationreview.com/",
      year = "2025",
      patterns = c("wpr/malnutrition*.csv"),
      dirs = "wpr"
    ),
    entry(
      "historical_outbreaks", "Displacement, Conflict & Disasters", "Garrett Zhou (compiled)",
      "Historical hunger outbreaks (21st century)",
      "Curated major hunger crises used in the outbreak / IPC pillar of the vulnerability score.",
      paths = "historical_hunger_outbreaks.csv"
    )
  )
}

format_citation_chicago <- function(citation) {
  org <- citation$organization
  title <- citation$title
  year <- citation$year
  accessed <- citation$accessed_date
  url <- citation$url

  if (!is.null(url) && !is.na(url) && nzchar(url)) {
    htmltools::HTML(paste0(
      org, ". ", year, ". ",
      "&ldquo;", title, "&rdquo;. ",
      "Accessed ", accessed, ". ",
      "<a href='", url, "' target='_blank' rel='noopener noreferrer'>", url, "</a>."
    ))
  } else {
    htmltools::HTML(paste0(
      org, ". ", year, ". ",
      "&ldquo;", title, "&rdquo;. ",
      "Local research archive copy."
    ))
  }
}

render_citations_ui <- function(citations_data) {
  n_detected <- sum(vapply(citations_data, function(x) isTRUE(x$detected), logical(1)))
  n_total <- length(citations_data)

  categories <- unique(vapply(citations_data, function(x) x$category, character(1)))
  categories <- sort(categories)

  category_style <- list(
    "Economic & Demographic Indicators" = list(color = "#3c8dbc", icon = "chart-bar"),
    "Food Security & Nutrition" = list(color = "#28a745", icon = "seedling"),
    "Food Systems & Agriculture" = list(color = "#f39c12", icon = "tractor"),
    "Displacement, Conflict & Disasters" = list(color = "#dc3545", icon = "exclamation-triangle"),
    "Environment, Resources & Development" = list(color = "#6f42c1", icon = "globe"),
    "Comparison Indices" = list(color = "#17a2b8", icon = "balance-scale")
  )

  shiny::tagList(
    tags$div(
      style = "margin-top: 14px; padding: 12px 16px; background: #e8f4fc; border-radius: 8px; border: 1px solid #bee5eb;",
      tags$p(
        style = "margin: 0; font-size: 14px; color: #0c5460;",
        tags$strong(paste0(n_detected, " of ", n_total)),
        " integrated sources have matching files under ",
        tags$code("data/raw"),
        " on this machine. All sources below are used or supported by the dashboard; badges show local availability."
      )
    ),
    lapply(categories, function(cat) {
      style_meta <- category_style[[cat]]
      if (is.null(style_meta)) style_meta <- list(color = "#6c757d", icon = "folder-open")

      cat_items <- Filter(function(x) identical(x$category, cat), citations_data)

      tags$div(
        style = "margin-top: 18px;",
        tags$div(
          style = paste0(
            "display:flex; align-items:center; gap:10px; ",
            "padding: 10px 12px; border-radius: 8px; ",
            "background: #ffffff; border: 1px solid #e9ecef; ",
            "border-left: 6px solid ", style_meta$color, ";"
          ),
          tags$span(shiny::icon(style_meta$icon), style = paste0("color:", style_meta$color, ";")),
          tags$h3(cat, style = "margin: 0; font-size: 16px; color: #2c3e50;"),
          tags$span(
            paste0(length(cat_items), " source", if (length(cat_items) == 1) "" else "s"),
            style = "margin-left:auto; font-size: 12px; color: #6c757d;"
          )
        ),
        tags$div(
          style = "margin-top: 10px;",
          shiny::tagList(lapply(seq_along(cat_items), function(i) {
            citation <- cat_items[[i]]
            badge_bg <- if (isTRUE(citation$detected)) "#d4edda" else "#f8f9fa"
            badge_col <- if (isTRUE(citation$detected)) "#155724" else "#6c757d"
            badge_txt <- if (isTRUE(citation$detected)) "In data/raw" else "Not in archive"

            tags$div(
              style = paste0(
                "background: white; padding: 14px 16px; border-radius: 10px; ",
                "margin-bottom: 12px; border: 1px solid #eef1f4; ",
                "box-shadow: 0 2px 6px rgba(0,0,0,0.06);"
              ),
              tags$div(
                style = "display:flex; align-items:flex-start; gap:10px;",
                tags$div(
                  style = paste0(
                    "width: 28px; height: 28px; border-radius: 8px; ",
                    "background: ", style_meta$color, "15; ",
                    "display:flex; align-items:center; justify-content:center; flex: 0 0 auto;"
                  ),
                  tags$span(shiny::icon("bookmark"), style = paste0("color:", style_meta$color, "; font-size: 12px;"))
                ),
                tags$div(
                  style = "flex: 1 1 auto;",
                  tags$div(
                    style = "display:flex; align-items:flex-start; justify-content:space-between; gap:10px; flex-wrap:wrap;",
                    tags$div(
                      style = "font-size: 14px; color: #2c3e50; line-height: 1.6; flex: 1 1 240px;",
                      format_citation_chicago(citation)
                    ),
                    tags$span(
                      badge_txt,
                      style = paste0(
                        "font-size: 11px; font-weight: 600; padding: 3px 8px; border-radius: 999px; ",
                        "background:", badge_bg, "; color:", badge_col, "; white-space: nowrap;"
                      )
                    )
                  ),
                  tags$div(
                    style = "margin-top: 8px; background: #f8f9fa; border-radius: 8px; padding: 10px 12px; border-left: 4px solid #dee2e6;",
                    tags$div(style = "font-size: 12px; color: #6c757d; font-weight: 600; margin-bottom: 3px;", "What we use it for"),
                    tags$div(style = "font-size: 13px; color: #495057; line-height: 1.5;", citation$description)
                  )
                )
              )
            )
          }))
        )
      )
    })
  )
}
