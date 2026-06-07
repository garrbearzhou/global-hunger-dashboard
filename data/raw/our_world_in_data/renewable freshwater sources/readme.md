# Internal renewable freshwater resources by region - Data package

This data package contains the data that powers the chart ["Internal renewable freshwater resources by region"](https://ourworldindata.org/grapher/internal-renewable-freshwater-resources-by-region?v=1&csvType=full&useColumnShortNames=false) on the Our World in Data website. It was downloaded on November 28, 2025.

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


## Renewable internal freshwater resources, total (billion cubic meters)
Last updated: September 8, 2025  
Next update: September 2026  
Date range: 1961–2021  
Unit: billion cubic meters  


### How to cite this data

#### In-line citation
If you have limited space (e.g. in data visualizations), you can use this abbreviated in-line citation:  
Food and Agriculture Organization of the United Nations, OECD, and World Bank (2025) – processed by Our World in Data

#### Full citation
Food and Agriculture Organization of the United Nations, OECD, and World Bank (2025) – processed by Our World in Data. “Renewable internal freshwater resources, total (billion cubic meters)” [dataset]. Food and Agriculture Organization of the United Nations, OECD, and World Bank, “World Development Indicators 122” [original data].
Source: Food and Agriculture Organization of the United Nations, OECD, and World Bank (2025) – processed by Our World In Data

### How is this data described by its producer - Food and Agriculture Organization of the United Nations, OECD, and World Bank (2025)?
Renewable internal freshwater resources flows refer to internal renewable resources (internal river flows and groundwater from rainfall) in the country.

### Limitations and exceptions:
A common perception is that most of the available freshwater resources are visible (on the surfaces of lakes, reservoirs and rivers). However, this visible water represents only a tiny fraction of global freshwater resources, as most of it is stored in aquifers, with the largest stocks stored in solid form in the Antarctic and in Greenland's ice cap.

The data on freshwater resources are based on estimates of runoff into rivers and recharge of groundwater. These estimates are based on different sources and refer to different years, so cross-country comparisons should be made with caution. Because the data are collected intermittently, they may hide significant variations in total renewable water resources from year to year. The data also fail to distinguish between seasonal and geographic variations in water availability within countries. Data for small countries and countries in arid and semiarid zones are less reliable than those for larger countries and countries with greater rainfall.

Caution should also be used in comparing data on annual freshwater withdrawals, which are subject to variations in collection and estimation methods. In addition, inflows and outflows are estimated at different times and at different levels of quality and precision, requiring caution in interpreting the data, particularly for water-short countries, notably in the Middle East and North Africa.

The data are based on surveys and estimates provided by governments to the Joint Monitoring Programme of the World Health Organization (WHO) and the United Nations Children's Fund (UNICEF). The coverage rates are based on information from service users on actual household use rather than on information from service providers, which may include nonfunctioning systems.

### Statistical concept and methodology:
The data on freshwater resources are based on estimates of runoff into rivers and recharge of groundwater. Renewable water resources (internal and external) include average annual flow of rivers and recharge of aquifers generated from endogenous precipitation, and those water resources that are not generated in the country, such as inflows from upstream countries (groundwater and surface water), and part of the water of border lakes and/or rivers. Non-renewable water includes groundwater bodies (deep aquifers) that have a negligible rate of recharge on the human time-scale. While renewable water resources are expressed in flows, non-renewable water resources have to be expressed in quantity (stock). Runoff from glaciers where the mass balance is negative is considered non-renewable.

Total actual renewable water resources correspond to the maximum theoretical yearly amount of water actually available for a country at a given moment. The unit of calculation is km3/year or 109 m3/year. Calculation Criteria is [Water resources: total renewable (actual)] = [Surface water: total renewable (actual)] + [Groundwater: total renewable (actual)] - [Overlap between surface water and groundwater].*

Fresh water is naturally occurring water on the Earth's surface. It is a renewable but limited natural resource. Fresh water can only be renewed through the process of the water cycle, where water from seas, lakes, forests, land, rivers, and dams evaporates, forms clouds, and returns as precipitation. However, if more fresh water is consumed through human activities than is restored by nature, the result is that the quantity of fresh water available in lakes, rivers, dams and underground waters can be reduced which can cause serious damage to the surrounding environment.

* http://www.fao.org/nr/water/aquastat/data/glossary/search.html?termId=4188&submitBtn=s&cls=yes

### Source

#### Food and Agriculture Organization of the United Nations, OECD, and World Bank – World Development Indicators
Retrieved on: 2025-09-08  
Retrieved from: https://data.worldbank.org/indicator/ER.H2O.INTR.K3  


    