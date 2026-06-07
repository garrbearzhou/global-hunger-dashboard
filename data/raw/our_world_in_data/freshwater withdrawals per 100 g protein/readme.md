# Freshwater withdrawals per 100 grams of protein - Data package

This data package contains the data that powers the chart ["Freshwater withdrawals per 100 grams of protein"](https://ourworldindata.org/grapher/water-per-protein-poore?v=1&csvType=full&useColumnShortNames=false) on the Our World in Data website. It was downloaded on November 28, 2025.

### Active Filters

A filtered subset of the full data was downloaded. The following filters were applied:

## CSV Structure

The high level structure of the CSV file is that each row is an observation for an entity (usually a country or region) and a timepoint (usually a year).

The first two columns in the CSV file are "Entity" and "Code". "Entity" is the name of the entity (e.g. "United States"). "Code" is the OWID internal entity code that we use if the entity is a country or region. For normal countries, this is the same as the [iso alpha-3](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) code of the entity (e.g. "USA") - for non-standard countries like historical countries these are custom codes.

The third column is either "Year" or "Day". If the data is annual, this is "Year" and contains only the year as an integer. If the column is "Day", the column contains a date string in the form "YYYY-MM-DD".

The final column is the data column, which is the time series that powers the chart. If the CSV data is downloaded using the "full data" option, then the column corresponds to the time series below. If the CSV data is downloaded using the "only selected data visible in the chart" option then the data column is transformed depending on the chart type and thus the association with the time series might not be as straightforward.

## Metadata.json structure

The .metadata.json file contains metadata about the data package. The "charts" key contains information to recreate the chart, like the title, subtitle etc.. The "columns" key contains information about each of the columns in the csv, like the unit, timespan covered, citation for the data etc..

## About the data

Our World in Data is almost never the original producer of the data - almost all of the data we use has been compiled by others. If you want to re-use data, it is your responsibility to ensure that you adhere to the sources' license and to credit them correctly. Please note that a single time series may have more than one source - e.g. when we stich together data from different time periods by different producers or when we calculate per capita metrics using population data from a second source.

## Detailed information about the data


## Freshwater withdrawals per 100g protein
Global average freshwater withdrawals per 100 grams of protein across food products. This is measured in liters of freshwater per 100 grams of protein.


### How to cite this data

#### In-line citation
If you have limited space (e.g. in data visualizations), you can use this abbreviated in-line citation:  
Poore, J., & Nemecek, T. (2018). Reducing food’s environmental impacts through producers and consumers. Science. – processed by Our World in Data

#### Full citation
Poore, J., & Nemecek, T. (2018). Reducing food’s environmental impacts through producers and consumers. Science. – processed by Our World in Data. “Freshwater withdrawals per 100g protein” [dataset]. Poore, J., & Nemecek, T. (2018). Reducing food’s environmental impacts through producers and consumers. Science. [original data].
Source: Poore, J., & Nemecek, T. (2018). Reducing food’s environmental impacts through producers and consumers. Science. – processed by Our World In Data

### Additional information about this data
Data is based on the largest meta-analysis of food system impact studies to date, from Poore & Nemecek's 2018 study.

The authors note the following about the scope of the studies included in this meta-analysis:
"We derived data from a comprehensive meta-analysis, identifying 1530 studies for potential inclusion, which were supplemented with additional data received from 139 authors. Studies were assessed against 11 criteria designed to standardize methodology, resulting in 570 suitable studies with a median reference year of 2010. The data set covers ~38,700 commercially viable farms in 119 countries and 40 products representing ~90% of global protein and calorie consumption'.

Environmental impacts are compared across several metrics: land use (m2), greenhouse gas emissions (tonnes of CO2-equivalents), eutrophying emissions (grams of PO4-equivalents), freshwater withdrawals (liters), and scarcity-weighted water (liters) which are freshwater withdrawals weighted for local water scarcity.

All comparisons here are based on the global mean value per food product across all studies.

Comparisons can be made in functional units: here all comparisons are made as impacts per kilogram of product.

Comparisons are also made on the basis of nutritional units in two categories: per 100 grams of protein and per 1000 kilocalories.

Poore & Nemecek (2018) quantified a range of footprints in nutritional units:
(1) protein products, which are compared per 100 grams of protein. Protein products include all meats, seafood, dairy, nuts, tofu and pulses. Grains are also compared here – despite being a low-quality source of protein – since a large share of global protein is derived from cereals.

(2) grains and staples, which are compared per 1000 kilocalories.

Poore & Nemecek (2018) do not provide data per 100g protein for food products which are not protein-rich, or kilocalorie measures for non-stale crops. To provide footprints for all products Our World in Data have filled these gaps by calculating footprints per nutritional unit using food composition factors from the FAO INFOODS International Database and Food Balance Sheets:
http://www.fao.org/3/X9892E/X9892e05.htm#P8217_125315
http://www.fao.org/infoods/infoods/tables-and-databases/international-databases/en/

Footprints expressed per kilogram of food product can be converted to per unit protein or kilocalorie using data on the nutrient density of food products.

Where nutritional footprints are available from Poore & Nemecek (2018), this data has been used. Where there were gaps, this data has been calculated by Our World in Data.


    