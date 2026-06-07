# Data Coverage tab: indicator and country-level completeness

coverage_indicator_catalog <- function() {
  tibble::tribble(
    ~column, ~label, ~source, ~category,
    "undernourishment_rate", "Undernourishment (%)", "FAO FAOSTAT", "Food security",
    "poverty_display", "Poverty rate (%)", "World Bank / OWID", "Economic",
    "gdp_per_capita", "GDP per capita (US$)", "World Bank WDI", "Economic",
    "life_expectancy", "Life expectancy (years)", "World Bank WDI", "Health",
    "population", "Population", "World Bank WDI", "Demographic",
    "stunting_rate", "Child stunting (%)", "WHO GHO", "Nutrition",
    "ghi_score", "Global Hunger Index", "GHI 2025", "Benchmark",
    "literacy", "Adult literacy (%)", "World Bank WDI", "Education",
    "grfc_ipc_phase", "GRFC / IPC phase", "WFP GRFC / IPC", "Crisis",
    "grfc_population_phase3_plus", "Population in IPC phase 3+", "WFP GRFC", "Crisis",
    "climate_vulnerability_index", "Climate vulnerability index", "CV / Global Data Lab", "Environment",
    "food_supply_kcal", "Food supply (kcal/cap/day)", "Our World in Data", "Food systems",
    "water_per_capita", "Renewable water (m³/cap/yr)", "Our World in Data", "Environment",
    "avg_import_share", "Food import dependency", "Compiled trade data", "Food systems",
    "total_displaced_latest", "Displaced people (UNHCR)", "UNHCR", "Displacement",
    "idu_displacement_total", "Internal displacement (IDU)", "HDX / IDMC", "Displacement",
    "agriculture_land", "Agricultural land (%)", "World Bank WDI", "Agriculture",
    "total_fatalities", "Conflict fatalities (ACLED)", "ACLED", "Conflict",
    "has_active_conflict", "Active conflict flag", "ACLED / derived", "Conflict",
    "major_hunger_outbreak_21st", "Major hunger outbreak (21st c.)", "Curated", "Historical",
    "hunger_vulnerability_rating", "Vulnerability score (computed)", "Dashboard composite", "Composite"
  )
}

value_present <- function(x) {
  if (is.logical(x)) return(!is.na(x))
  if (is.numeric(x)) return(!is.na(x) & is.finite(x))
  if (is.character(x)) return(!is.na(x) & nzchar(trimws(x)))
  !is.na(x)
}

build_merge_validation <- function(summary_df) {
  catalog <- coverage_indicator_catalog()
  key_indicators <- intersect(catalog$column, names(summary_df))
  catalog <- catalog %>% dplyr::filter(.data$column %in% key_indicators)

  if (length(key_indicators) == 0) {
    empty <- tibble::tibble(
      country = character(),
      region = character(),
      iso3c = character(),
      n_indicators = integer(),
      pct_indicators = numeric()
    )
    return(list(
      report = empty,
      summary = tibble::tibble(indicator = character(), label = character(), source = character(),
                               category = character(), n_countries = numeric(), total = 0L, pct = numeric()),
      has_cols = character(),
      catalog = catalog,
      n_indicators = 0L
    ))
  }

  report <- summary_df %>%
    dplyr::select(country, dplyr::any_of(c("region", "iso3c")), dplyr::all_of(key_indicators)) %>%
    dplyr::mutate(dplyr::across(
      dplyr::all_of(key_indicators),
      ~ value_present(.),
      .names = "has_{.col}"
    ))

  has_cols <- names(report)[grepl("^has_", names(report))]
  n_has <- length(has_cols)

  report <- report %>%
    dplyr::mutate(
      n_indicators = if (n_has > 0) rowSums(dplyr::select(., dplyr::any_of(has_cols)), na.rm = TRUE) else 0L,
      pct_indicators = if (n_has > 0) round(100 * .data$n_indicators / n_has, 1) else 0
    )

  ind_names <- gsub("^has_", "", has_cols)
  summary <- tibble::tibble(
    indicator = ind_names,
    n_countries = as.integer(colSums(report %>% dplyr::select(dplyr::any_of(has_cols)), na.rm = TRUE)),
    total = nrow(report),
    pct = round(100 * n_countries / nrow(report), 1)
  ) %>%
    dplyr::left_join(catalog, by = c("indicator" = "column")) %>%
    dplyr::mutate(
      label = dplyr::coalesce(.data$label, .data$indicator),
      source = dplyr::coalesce(.data$source, "—"),
      category = dplyr::coalesce(.data$category, "Other")
    ) %>%
    dplyr::arrange(dplyr::desc(.data$pct), .data$label)

  list(
    report = report,
    summary = summary,
    has_cols = has_cols,
    catalog = catalog,
    n_indicators = n_has
  )
}

coverage_summary_tags <- function(validation) {
  n_countries <- nrow(validation$report)
  n_ind <- validation$n_indicators
  if (n_countries == 0 || n_ind == 0) {
    return(shiny::tags$p(style = "color:#64748b;", "No coverage data available."))
  }
  avg_pct <- round(mean(validation$report$pct_indicators, na.rm = TRUE), 1)
  full_cov <- sum(validation$report$pct_indicators >= 99.9, na.rm = TRUE)
  low_cov <- sum(validation$report$pct_indicators < 50, na.rm = TRUE)

  shiny::fluidRow(
    shiny::column(
      4,
      shiny::tags$div(
        class = "coverage-kpi-card",
        shiny::tags$div(class = "coverage-kpi-value", n_countries),
        shiny::tags$div(class = "coverage-kpi-label", "Countries in integrated dataset")
      )
    ),
    shiny::column(
      4,
      shiny::tags$div(
        class = "coverage-kpi-card",
        shiny::tags$div(class = "coverage-kpi-value", paste0(avg_pct, "%")),
        shiny::tags$div(class = "coverage-kpi-label", paste0("Mean indicator coverage (of ", n_ind, " metrics)"))
      )
    ),
    shiny::column(
      4,
      shiny::tags$div(
        class = "coverage-kpi-card",
        shiny::tags$div(class = "coverage-kpi-value", low_cov),
        shiny::tags$div(
          class = "coverage-kpi-label",
          paste0("Countries below 50% coverage (", full_cov, " at ~100%)")
        )
      )
    )
  )
}
