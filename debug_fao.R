library(tidyverse)
library(readr)

# Load FAO data
fao_main <- read_csv("data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data_NOFLAG.csv", show_col_types = FALSE)

# Check column names
cat("Column names:\n")
print(names(fao_main))

# Check key indicators
year_cols <- paste0("Y", 2000:2023)
key_indicators <- c("210041", "210011", "210401", "210091", "21010", "22013", "21035", "21033", "21032")

# Filter data
fao_filtered <- fao_main %>% 
  filter(`Item Code` %in% key_indicators & `Element Code` == 6121)

cat("\nFiltered records:", nrow(fao_filtered), "\n")
cat("Unique Item Codes:", paste(unique(fao_filtered$`Item Code`), collapse=", "), "\n")

# Convert to long format
fao_long <- fao_filtered %>% 
  select(Area, `Item Code`, Item, Element, Unit, all_of(year_cols)) %>% 
  pivot_longer(cols = all_of(year_cols), names_to = "Year", values_to = "Value") %>% 
  mutate(Year = as.numeric(gsub("Y", "", Year))) %>% 
  filter(!is.na(Value) & Value != 0)

cat("Long format records:", nrow(fao_long), "\n")
cat("Sample data:\n")
print(head(fao_long, 10))

# Try pivot_wider
fao_wide <- fao_long %>% 
  pivot_wider(names_from = `Item Code`, values_from = Value, names_prefix = "ind_")

cat("Wide format records:", nrow(fao_wide), "\n")
cat("Wide format columns:", paste(names(fao_wide), collapse=", "), "\n")
