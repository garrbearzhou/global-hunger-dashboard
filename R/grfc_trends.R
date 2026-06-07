# GRFC / IPC trends panel helpers

parse_trends_num <- function(x) {
  if (is.numeric(x)) return(x)
  ch <- as.character(x)
  ch[ch %in% c("", "NA", "N/A", "n/a", "-", "—")] <- NA_character_
  suppressWarnings(as.numeric(gsub(",", "", ch)))
}

normalize_trends_panel <- function(df) {
  if (is.null(df) || nrow(df) == 0) {
    return(tibble::tibble(
      country = character(),
      assessment_year = integer(),
      ipc_phase = numeric(),
      population_phase3_plus = numeric(),
      population_phase4_plus = numeric(),
      population_phase5 = numeric(),
      primary_driver = character(),
      secondary_driver = character()
    ))
  }
  out <- df %>%
    dplyr::mutate(
      country = trimws(as.character(.data$country)),
      assessment_year = as.integer(.data$assessment_year),
      ipc_phase = parse_trends_num(.data$ipc_phase),
      population_phase3_plus = parse_trends_num(.data$population_phase3_plus),
      population_phase4_plus = if ("population_phase4_plus" %in% names(.)) parse_trends_num(.data$population_phase4_plus) else NA_real_,
      population_phase5 = if ("population_phase5" %in% names(.)) parse_trends_num(.data$population_phase5) else NA_real_,
      primary_driver = if ("primary_driver" %in% names(.)) as.character(.data$primary_driver) else NA_character_,
      secondary_driver = if ("secondary_driver" %in% names(.)) as.character(.data$secondary_driver) else NA_character_
    ) %>%
    dplyr::filter(!is.na(.data$country), nzchar(.data$country), !is.na(.data$assessment_year))

  if (exists("standardize_country_names", mode = "function")) {
    out <- out %>% dplyr::mutate(country = standardize_country_names(.data$country))
  }
  out
}

read_grfc_master_xlsx <- function(xlsx_path) {
  if (!file.exists(xlsx_path) || !requireNamespace("readxl", quietly = TRUE)) return(NULL)
  sheet <- "GFRC MYU 2024_Master"
  sheets <- readxl::excel_sheets(xlsx_path)
  if (!sheet %in% sheets) return(NULL)

  raw <- readxl::read_excel(xlsx_path, sheet = sheet)
  if (!all(c("Countries/ territories", "Year of reference") %in% names(raw))) return(NULL)

  p1 <- parse_trends_num(raw[["Population in Phase 1 #"]])
  p2 <- parse_trends_num(raw[["Population in Phase 2 #"]])
  p3 <- parse_trends_num(raw[["Population in Phase 3 #"]])
  p4 <- parse_trends_num(raw[["Population in Phase 4 #"]])
  p5 <- parse_trends_num(raw[["Population Phase 5 #"]])

  raw %>%
    dplyr::mutate(
      country = trimws(as.character(.data$`Countries/ territories`)),
      assessment_year = as.integer(.data$`Year of reference`),
      population_analysed = parse_trends_num(.data$`Population analysed`),
      population_phase3_plus = parse_trends_num(.data$`Population in Phase 3 or above #`),
      population_phase4_plus = p4,
      population_phase5 = p5,
      primary_driver = as.character(.data$`Primary driver`),
      row_phase = dplyr::case_when(
        dplyr::coalesce(p5, 0) > 0 ~ 5,
        dplyr::coalesce(p4, 0) > 0 ~ 4,
        dplyr::coalesce(p3, 0) > 0 ~ 3,
        dplyr::coalesce(p2, 0) > 0 ~ 2,
        dplyr::coalesce(p1, 0) > 0 ~ 1,
        TRUE ~ NA_real_
      )
    ) %>%
    dplyr::filter(!is.na(.data$country), nzchar(.data$country), !is.na(.data$assessment_year)) %>%
    dplyr::group_by(.data$country, .data$assessment_year) %>%
    dplyr::slice_max(dplyr::coalesce(.data$population_analysed, 0), n = 1, with_ties = FALSE) %>%
    dplyr::ungroup() %>%
    dplyr::transmute(
      country = .data$country,
      assessment_year = .data$assessment_year,
      ipc_phase = .data$row_phase,
      population_phase3_plus = .data$population_phase3_plus,
      population_phase4_plus = .data$population_phase4_plus,
      population_phase5 = .data$population_phase5,
      primary_driver = .data$primary_driver,
      secondary_driver = NA_character_
    )
}

default_trend_countries <- function(df, metric = "ipc_phase", n = 6L) {
  if (is.null(df) || nrow(df) == 0) return(character())
  n <- max(1L, as.integer(n))
  if (identical(metric, "population_phase3_plus")) {
    df %>%
      dplyr::filter(!is.na(.data$population_phase3_plus), .data$population_phase3_plus > 0) %>%
      dplyr::group_by(.data$country) %>%
      dplyr::summarise(score = max(.data$population_phase3_plus, na.rm = TRUE), .groups = "drop") %>%
      dplyr::arrange(dplyr::desc(.data$score)) %>%
      dplyr::slice_head(n = n) %>%
      dplyr::pull(.data$country)
  } else {
    df %>%
      dplyr::filter(!is.na(.data$ipc_phase)) %>%
      dplyr::count(.data$country, name = "n_years") %>%
      dplyr::arrange(dplyr::desc(.data$n_years), .data$country) %>%
      dplyr::slice_head(n = n) %>%
      dplyr::pull(.data$country)
  }
}

trends_panel_summary_text <- function(df, source_label) {
  if (is.null(df) || nrow(df) == 0) {
    return("No panel rows loaded for this source. Check data/raw/wfp and data/raw/ipc, then restart the app.")
  }
  yrs <- range(df$assessment_year, na.rm = TRUE)
  n_ipc <- sum(!is.na(df$ipc_phase))
  paste0(
    source_label,
    ": ", nrow(df), " country–year rows, ",
    length(unique(df$country)), " countries, years ",
    yrs[1], "–", yrs[2],
    " (", n_ipc, " rows with IPC phase)."
  )
}
