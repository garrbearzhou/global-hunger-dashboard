suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

clamp_timeseries_forecast <- function(values, variable_code) {
  v <- as.numeric(values)
  if (variable_code %in% c("SI.POV.DDAY", "AG.LND.AGRI.ZS", "SP.RUR.TOTL.ZS")) {
    pmin(pmax(v, 0), 100)
  } else if (variable_code == "SP.DYN.LE00.IN") {
    pmin(pmax(v, 20), 95)
  } else if (variable_code == "SP.DYN.IMRT.IN") {
    pmax(v, 0)
  } else if (variable_code == "FP.CPI.TOTL.ZG") {
    pmin(pmax(v, -30), 75)
  } else if (variable_code == "hunger_vulnerability_rating") {
    pmin(pmax(v, 0), 100)
  } else {
    v
  }
}

build_timeseries_forecast <- function(ts_data, variable_code, forecast_years, scale = 1) {
  if (is.null(forecast_years) || forecast_years < 1 || nrow(ts_data) < 3) return(NULL)
  fit_data <- ts_data %>% filter(!is.na(variable_value), is.finite(variable_value)) %>% arrange(year)
  if (nrow(fit_data) < 3) return(NULL)
  max_y <- max(fit_data$year, na.rm = TRUE)
  recent_data <- fit_data %>% filter(year >= max_y - 14)
  if (nrow(recent_data) < 5) recent_data <- fit_data %>% slice_tail(n = min(5, nrow(fit_data)))
  last_year <- max(recent_data$year, na.rm = TRUE)
  last_value <- recent_data$variable_value[recent_data$year == last_year][1]
  if (is.na(last_value) || !is.finite(last_value)) return(NULL)
  k_seq <- seq_len(forecast_years)
  future_years <- last_year + k_seq
  use_log <- variable_code %in% c("SP.POP.TOTL", "NY.GDP.MKTP.CD")
  forecast_vals <- if (use_log) {
    positive <- recent_data %>% filter(variable_value > 0)
    if (nrow(positive) < 3 || last_value <= 0) return(NULL)
    model <- lm(log(variable_value) ~ year, data = positive)
    log_slope <- unname(coef(model)[["year"]])
    if (is.na(log_slope) || !is.finite(log_slope)) return(NULL)
    last_value * exp(log_slope * k_seq)
  } else {
    model <- lm(variable_value ~ year, data = recent_data)
    slope <- unname(coef(model)[["year"]])
    if (is.na(slope) || !is.finite(slope)) return(NULL)
    last_value + slope * k_seq
  }
  forecast_vals <- clamp_timeseries_forecast(forecast_vals, variable_code)
  if (use_log) forecast_vals <- forecast_vals[forecast_vals > 0]
  if (length(forecast_vals) == 0) return(NULL)
  out <- data.frame(year = future_years[seq_along(forecast_vals)], display_value = forecast_vals / scale)
  bridge <- fit_data %>% filter(year == last_year) %>%
    transmute(year = as.numeric(year), display_value = variable_value / scale) %>% slice(1)
  if (nrow(bridge) == 1) out <- bind_rows(bridge, out)
  out
}

wb_data <- read_csv("data/raw/world_bank_data.csv", show_col_types = FALSE)
col_mapping <- c(
  "pop_POP.TOTL" = "SP.POP.TOTL",
  "gdp_GDP.MKTP.CD" = "NY.GDP.MKTP.CD",
  "poverty_POV.DDAY" = "SI.POV.DDAY",
  "inflation_CPI.TOTL.ZG" = "FP.CPI.TOTL.ZG"
)
for (old_name in names(col_mapping)) {
  if (old_name %in% names(wb_data)) names(wb_data)[names(wb_data) == old_name] <- col_mapping[old_name]
}

world_bank_timeseries <- wb_data %>%
  filter(iso3c == "WLD") %>%
  mutate(year = as.integer(as.numeric(year))) %>%
  group_by(year) %>% slice(1L) %>% ungroup() %>% arrange(year)

show_fc <- function(code, scale, label) {
  ts <- world_bank_timeseries %>% transmute(year, variable_value = .data[[code]]) %>%
    filter(!is.na(variable_value), is.finite(variable_value))
  fc <- build_timeseries_forecast(ts, code, 5, scale)
  cat("\n", label, " last=", round(tail(ts$variable_value, 1) / scale, 3), "\n", sep = "")
  print(round(fc, 3))
}

show_fc("SP.POP.TOTL", 1e9, "Population (B)")
show_fc("NY.GDP.MKTP.CD", 1e12, "GDP (T)")
show_fc("SI.POV.DDAY", 1, "Poverty (%)")
show_fc("FP.CPI.TOTL.ZG", 1, "Inflation (%)")
