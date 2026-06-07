# Industrial water withdrawal - Data package

This data package contains the data that powers the chart ["Industrial water withdrawal"](https://ourworldindata.org/grapher/industrial-water-withdrawal?v=1&csvType=full&useColumnShortNames=false) on the Our World in Data website. It was downloaded on November 28, 2025.

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


## Industrial water withdrawal
Unit: billion m³ per year  
Unit conversion factor: 1000000000  


### How to cite this data

#### In-line citation
If you have limited space (e.g. in data visualizations), you can use this abbreviated in-line citation:  
Water withdrawals and consumption - Aquastat – processed by Our World in Data

#### Full citation
Water withdrawals and consumption - Aquastat – processed by Our World in Data. “Industrial water withdrawal” [dataset]. Water withdrawals and consumption - Aquastat [original data].
Source: Water withdrawals and consumption - Aquastat – processed by Our World In Data

### Additional information about this data
Data definitions for each variable included in the AQUASTAT Database is as follows:

Agricultural water withdrawal: "Annual quantity of self-supplied water withdrawn for irrigation, livestock and aquaculture purposes. It can include water from primary renewable and secondary freshwater resources, as well as water from over-abstraction of renewable groundwater or withdrawal from fossil groundwater, direct use of agricultural drainage water, direct use of (treated) wastewater, and desalinated water. Water for the dairy and meat industries and industrial processing of harvested agricultural products is included under industrial water withdrawal."

Industrial water withdrawal: "Annual quantity of self-supplied water withdrawn for industrial uses. It can include water from primary renewable and secondary freshwater resources, as well as water from over-abstraction of renewable groundwater or withdrawal from fossil groundwater, direct use of agricultural drainage water, direct use of (treated) wastewater, and desalinated water. This sector refers to self-supplied industries not connected to the public distribution network. The ratio between net consumption and withdrawal is estimated at less than 5%. It includes water for the cooling of thermoelectric and nuclear power plants, but it does not include hydropower. Water withdrawn by industries that are connected to the public supply network is generally included in municipal water withdrawal."

Municipal water withdrawal: "Annual quantity of water withdrawn primarily for the direct use by the population. It can include water from primary renewable and secondary freshwater resources, as well as water from over-abstraction of renewable groundwater or withdrawal from fossil groundwater, direct use of agricultural drainage water, direct use of (treated) wastewater, and desalinated water. It is usually computed as the total water withdrawn by the public distribution network. It can include that part of the industries and urban agriculture, which is connected to the municipal network. The ratio between the net consumption and the water withdrawn can vary from 5 to 15% in urban areas and from 10 to 50% in rural areas."

Irrigation water requirement: "The quantity of water exclusive of precipitation and soil moisture (i.e. quantity of irrigation water) required for normal crop production. It consists of water to ensure that the crop receives its full crop water requirement (i.e. irrigation consumptive water use, as well as extra water for flooding of paddy fields to facilitate land preparation and protect the plant and for leaching salt when necessary to allow for plant growth). It is usually expressed in water depth (millimetres) or water volume (m3) and may be stated in monthly, seasonal or annual terms, or for a crop period. It corresponds to net irrigation water requirement."

Irrigation water withdrawal: "Annual quantity of water withdrawn for irrigation purposes. In the AQUASTAT database water withdrawal for irrigation is part of agricultural water withdrawal, together with water withdrawal for livestock (watering and cleaning) and water withdrawal for aquaculture. It can include water from primary renewable and secondary freshwater resources, as well as water from over-abstraction of renewable groundwater or withdrawal from fossil groundwater, direct use of agricultural drainage water, direct use of (treated) wastewater, and desalinated water. The amount of water withdrawn for irrigation by far exceeds the consumptive use of irrigation because of water lost in its distribution from its source to the crops. The term "water requirement ratio" (sometimes also called "irrigation efficiency") is used to indicate the ratio between the net irrigation water requirements or crop water requirements, which is the volume of water needed to compensate for the deficit between potential evapotranspiration and effective precipitation over the growing period of the crop, and the amount of water withdrawn for irrigation including the losses. In the specific case of paddy rice irrigation, additional water is needed for flooding to facilitate land preparation and for plant protection. In that case, irrigation water requirements are the sum of rainfall deficit and the water needed to flood paddy fields. At scheme level, water requirement ratio values can vary from less than 20 percent to more than 80 percent."

Total water withdrawal: "Annual quantity of water withdrawn for agricultural, industrial and municipal purposes. It can include water from primary renewable and secondary freshwater resources, as well as water from over-abstraction of renewable groundwater or withdrawal from fossil groundwater, direct use of agricultural drainage water, direct use of (treated) wastewater, and desalinated water. It does not include in-stream uses, which are characterized by a very low net consumption rate, such as recreation, navigation, hydropower, inland capture fisheries, etc."


    