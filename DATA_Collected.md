# Data Collected

This document lists **all data sources** under `data/raw` that are integrated or available in the project, with **country coverage** and **holes** (countries missing from each source).

**Backbone:** The reference country list is **World Bank** (so *holes* = WB countries that do not appear in that source). Sources that use different naming (e.g. ISO3) may show more holes unless names are standardized.

Generated: 
2026-03-11 21:31

---

## Summary

| Data source | Path | Countries with data | Holes (count) |
|-------------|------|---------------------|----------------|
| World Bank | `world_bank_data.csv` | 265 | 0 |
| FAO (fao_data) | `fao/fao_data.csv` | 263 | 1 |
| FAO Food Security (Food_Security_Data_E_All_Data) | `fao/FAO_Data/Food_Security_Data_E_All_Data.csv` | 248 | 65 |
| FAO FPMA | `fao/FAO_Data/fao fpma data.csv` | 0 | 234 |
| WFP GRFC (xlsx) | `wfp/grfc2016-2024_data.xlsx` | 25 | 234 |
| IPC general | `ipc/ipc data general data.csv` | 31 | 208 |
| IPC historical (2017-2025) | `ipc/ipc all data 2017-2025.csv` | 52 | 234 |
| Historical hunger outbreaks | `historical_hunger_outbreaks.csv` | 18 | 221 |
| WHO stunting | `who/child_stunting_data.csv` | 206 | 94 |
| OWID poverty | `our_world_in_data/poverty data.csv` | 194 | 85 |
| Climate vulnerability (cv/vulnerability) | `climate vulnerability/cv/vulnerability/vulnerability.csv` | 192 | 69 |
| Climate cv exposure | `climate vulnerability/cv/vulnerability/exposure.csv` | 192 | 69 |
| Climate cv sensitivity | `climate vulnerability/cv/vulnerability/sensitivity.csv` | 192 | 69 |
| Climate cv capacity | `climate vulnerability/cv/vulnerability/capacity.csv` | 192 | 69 |
| Climate cv food | `climate vulnerability/cv/vulnerability/food.csv` | 192 | 69 |
| Climate cv water | `climate vulnerability/cv/vulnerability/water.csv` | 192 | 69 |
| Climate cv health | `climate vulnerability/cv/vulnerability/health.csv` | 192 | 69 |
| Climate (Global Data Lab) | `global_data_lab/climate/climate vunerability index.csv` | 43 | 199 |
| Health vulnerability (Global Data Lab) | `global_data_lab/health/health vunerability data.csv` | 39 | 203 |
| UNHCR displaced | `un/unhcr/displaced people data/persons_of_concern.csv` | 186 | 76 |
| IDU (HDX) | `hdx/idu` | 76 | 169 |
| EM-DAT disasters | `em_dat/em_dat_data.csv` | 263 | 1 |
| Food trade dependency | `food trade dependency/data overview.csv` | 66 | 178 |
| Food supply (OWID) | `our_world_in_data/food supply data.csv` | 240 | 71 |
| Water per capita (OWID) | `our_world_in_data/freshwater resources per capita/renewable-water-resources-per-capita.csv` | 195 | 77 |
| Agriculture water withdrawals (OWID) | `our_world_in_data/agriculture water withdrawals/agricultural-water-withdrawals.csv` | 179 | 80 |
| USDA agricultural | `usda/agricultural_production_1.csv` | 89 | 234 |
| GHI (Global Hunger Index) | `global hunger index/2025 csv.xlsx` | 1 | 234 |
| ACLED conflict | `acled - conflict data/fatalities per country.xlsx` | 45 | 199 |
| WPR malnutrition | `wpr/malnutrition-rate-by-country-2025.csv` | 169 | 87 |

---

## Detail by source

### World Bank

- **Path:** `world_bank_data.csv`

- **Countries with data:** 265

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 0


### FAO (fao_data)

- **Path:** `fao/fao_data.csv`

- **Countries with data:** 263

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 1

  - 
Barb994.64806074889



### FAO Food Security (Food_Security_Data_E_All_Data)

- **Path:** `fao/FAO_Data/Food_Security_Data_E_All_Data.csv`

- **Countries with data:** 248

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 65

  - 
Aruba, Bahamas, The, Barb994.64806074889, Bolivia, British Virgin Islands, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Cote d'Ivoire, Curacao, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, Gambia, The, Gibraltar, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Liechtenstein, Low income, Lower middle income, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, Monaco, Netherlands, Northern Mariana Islands, Puerto Rico (US), San Marino, Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Tanzania, Turkiye, Turks and Caicos Islands, United Kingdom, United States, Upper middle income, Venezuela, RB, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### FAO FPMA

- **Path:** `fao/FAO_Data/fao fpma data.csv`

- **Countries with data:** 0

  - 



- **Holes (countries in backbone but missing from this source):** 234

  - *(first 100)* 
Afghanistan, Albania, Algeria, American Samoa, Andorra, Angola, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, The, Bahrain, Bangladesh, Barb994.64806074889, Barbados, Belarus, Belgium, Belize, Benin, Bermuda, Bhutan, Bolivia, Bosnia and Herzegovina, Botswana, Brazil, British Virgin Islands, Brunei Darussalam, Bulgaria, Burkina Faso, Burundi, Cabo Verde, Cambodia, Cameroon, Canada, Cayman Islands, Central African Republic, Chad, Chile, China, Colombia, Comoros, Congo, Dem. Rep., Congo, Rep., Costa Rica, Cote d'Ivoire, Croatia, Cuba, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Ecuador, Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Eswatini, Ethiopia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gabon, Gambia, The, Georgia, Germany, Ghana, Gibraltar, Greece, Greenland, Grenada, Guam, Guatemala, Guinea, Guinea-Bissau, Guyana, Haiti, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia
 ...



### WFP GRFC (xlsx)

- **Path:** `wfp/grfc2016-2024_data.xlsx`

- **Countries with data:** 25

  - 
Analysis period, Availability of AFI info (Y/N), GRFC publication, Major food  crisis (Y/N), Population  in Phase 1 %, Population  in Phase 2 %, Population  in Phase 3 %, Population analysed, Population in Phase 1 #, Population in Phase 2 #, Population in Phase 3 #, Population in Phase 3 or above #, Population in Phase 3 or above %, Population in Phase 4 #, Population in Phase 4 %, Population Phase 5 #, Population Phase 5 %, Primary driver, Region, Selection criteria, Selection in the GRFC (Y/N), Share of population analysed of total country population (%), Source, Total country population, Year of reference


- **Holes (countries in backbone but missing from this source):** 234

  - *(first 100)* 
Afghanistan, Albania, Algeria, American Samoa, Andorra, Angola, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, The, Bahrain, Bangladesh, Barb994.64806074889, Barbados, Belarus, Belgium, Belize, Benin, Bermuda, Bhutan, Bolivia, Bosnia and Herzegovina, Botswana, Brazil, British Virgin Islands, Brunei Darussalam, Bulgaria, Burkina Faso, Burundi, Cabo Verde, Cambodia, Cameroon, Canada, Cayman Islands, Central African Republic, Chad, Chile, China, Colombia, Comoros, Congo, Dem. Rep., Congo, Rep., Costa Rica, Cote d'Ivoire, Croatia, Cuba, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Ecuador, Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Eswatini, Ethiopia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gabon, Gambia, The, Georgia, Germany, Ghana, Gibraltar, Greece, Greenland, Grenada, Guam, Guatemala, Guinea, Guinea-Bissau, Guyana, Haiti, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia
 ...



### IPC general

- **Path:** `ipc/ipc data general data.csv`

- **Countries with data:** 31

  - 
Afghanistan, Benin, Burundi, Cabo Verde, Cameroon, Central African Republic, Chad, Côte d'Ivoire, Democratic Republic of the Congo, Djibouti, Eswatini, Gaza Strip, Ghana, Guatemala, Guinea, Haiti, Lesotho, Malawi, Mali, Mauritania, Namibia, Niger, Nigeria, Senegal, Sierra Leone, Somalia, South Sudan, Sudan, Togo, Yemen, Zambia


- **Holes (countries in backbone but missing from this source):** 208

  - *(first 100)* 
Albania, Algeria, American Samoa, Andorra, Angola, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, The, Bahrain, Bangladesh, Barb994.64806074889, Barbados, Belarus, Belgium, Belize, Bermuda, Bhutan, Bolivia, Bosnia and Herzegovina, Botswana, Brazil, British Virgin Islands, Brunei Darussalam, Bulgaria, Burkina Faso, Cambodia, Canada, Cayman Islands, Chile, China, Colombia, Comoros, Congo, Dem. Rep., Congo, Rep., Costa Rica, Cote d'Ivoire, Croatia, Cuba, Curacao, Cyprus, Czechia, Denmark, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Ecuador, Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Ethiopia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gabon, Gambia, The, Georgia, Germany, Gibraltar, Greece, Greenland, Grenada, Guam, Guinea-Bissau, Guyana, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia, Iran, Islamic Rep., Iraq, Ireland, Isle of Man, Israel, Italy, Jamaica, Japan, Jordan, Kazakhstan, Kenya, Kiribati, Korea, Dem. People's Rep.
 ...



### IPC historical (2017-2025)

- **Path:** `ipc/ipc all data 2017-2025.csv`

- **Countries with data:** 52

  - 
AFG, AGO, BDI, BEN, BFA, BGD, CAF, CIV, CMR, COD, CPV, DJI, DOM, ECU, ETH, GHA, GIN, GMB, GNB, GTM, HND, HTI, KEN, LBN, LBR, LSO, MDG, MLI, MOZ, MRT, MWI, NAM, NER, NGA, PAK, PSE, SDN, SEN, SLE, SLV, SOM, SSD, SWZ, TCD, TGO, TLS, TZA, UGA, YEM, ZAF, ZMB, ZWE


- **Holes (countries in backbone but missing from this source):** 234

  - *(first 100)* 
Afghanistan, Albania, Algeria, American Samoa, Andorra, Angola, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, The, Bahrain, Bangladesh, Barb994.64806074889, Barbados, Belarus, Belgium, Belize, Benin, Bermuda, Bhutan, Bolivia, Bosnia and Herzegovina, Botswana, Brazil, British Virgin Islands, Brunei Darussalam, Bulgaria, Burkina Faso, Burundi, Cabo Verde, Cambodia, Cameroon, Canada, Cayman Islands, Central African Republic, Chad, Chile, China, Colombia, Comoros, Congo, Dem. Rep., Congo, Rep., Costa Rica, Cote d'Ivoire, Croatia, Cuba, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Ecuador, Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Eswatini, Ethiopia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gabon, Gambia, The, Georgia, Germany, Ghana, Gibraltar, Greece, Greenland, Grenada, Guam, Guatemala, Guinea, Guinea-Bissau, Guyana, Haiti, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia
 ...



### Historical hunger outbreaks

- **Path:** `historical_hunger_outbreaks.csv`

- **Countries with data:** 18

  - 
Afghanistan, Burkina Faso, Central African Republic, Chad, Democratic Republic of the Congo, Ethiopia, Haiti, Madagascar, Mali, Niger, Nigeria, Somalia, South Sudan, United Republic of Tanzania, Venezuela (Bolivarian Republic of), Yemen, Zambia, Zimbabwe


- **Holes (countries in backbone but missing from this source):** 221

  - *(first 100)* 
Albania, Algeria, American Samoa, Andorra, Angola, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, The, Bahrain, Bangladesh, Barb994.64806074889, Barbados, Belarus, Belgium, Belize, Benin, Bermuda, Bhutan, Bolivia, Bosnia and Herzegovina, Botswana, Brazil, British Virgin Islands, Brunei Darussalam, Bulgaria, Burundi, Cabo Verde, Cambodia, Cameroon, Canada, Cayman Islands, Chile, China, Colombia, Comoros, Congo, Dem. Rep., Congo, Rep., Costa Rica, Cote d'Ivoire, Croatia, Cuba, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Ecuador, Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Eswatini, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gabon, Gambia, The, Georgia, Germany, Ghana, Gibraltar, Greece, Greenland, Grenada, Guam, Guatemala, Guinea, Guinea-Bissau, Guyana, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia, Iran, Islamic Rep., Iraq, Ireland, Isle of Man, Israel, Italy
 ...



### WHO stunting

- **Path:** `who/child_stunting_data.csv`

- **Countries with data:** 206

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 94

  - 
American Samoa, Andorra, Antigua and Barbuda, Aruba, Austria, Bahamas, The, Barb994.64806074889, Bermuda, Bolivia, British Virgin Islands, Canada, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Cote d'Ivoire, Croatia, Curacao, Cyprus, Denmark, Dominica, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, France, French Polynesia, Gambia, The, Gibraltar, Greenland, Grenada, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Israel, Italy, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Liechtenstein, Low income, Lower middle income, Luxembourg, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, Monaco, Netherlands, New Caledonia, New Zealand, Nicaragua, Northern Mariana Islands, Norway, Palau, Puerto Rico (US), Russian Federation, San Marino, Sint Maarten (Dutch part), Slovak Republic, Slovenia, Somalia, Fed. Rep., Spain, St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Sweden, Switzerland, Tanzania, Turkiye, United Arab Emirates, United Kingdom, United States, Upper middle income, Venezuela, RB, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### OWID poverty

- **Path:** `our_world_in_data/poverty data.csv`

- **Countries with data:** 194

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 85

  - 
Afghanistan, American Samoa, Andorra, Antigua and Barbuda, Argentina, Aruba, Bahamas, The, Bahrain, Barb994.64806074889, Bermuda, British Virgin Islands, Brunei Darussalam, Cabo Verde, Cambodia, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Cuba, Curacao, Dominica, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Eritrea, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kuwait, Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Libya, Liechtenstein, Low income, Lower middle income, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Monaco, New Caledonia, New Zealand, Northern Mariana Islands, Oman, Palau, Puerto Rico (US), Russian Federation, San Marino, Saudi Arabia, Singapore, Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Syrian Arab Republic, Timor-Leste, Turkiye, Turks and Caicos Islands, Upper middle income, Venezuela, RB, Viet Nam, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### Climate vulnerability (cv/vulnerability)

- **Path:** `climate vulnerability/cv/vulnerability/vulnerability.csv`

- **Countries with data:** 192

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 69

  - 
American Samoa, Aruba, Bahamas, The, Barb994.64806074889, Bermuda, Bolivia, British Virgin Islands, Cabo Verde, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Curacao, Czechia, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Eswatini, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Libya, Low income, Lower middle income, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, New Caledonia, North Macedonia, Northern Mariana Islands, Puerto Rico (US), Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., South Sudan, St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Tanzania, Turkiye, Turks and Caicos Islands, Upper middle income, Venezuela, RB, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### Climate cv exposure

- **Path:** `climate vulnerability/cv/vulnerability/exposure.csv`

- **Countries with data:** 192

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 69

  - 
American Samoa, Aruba, Bahamas, The, Barb994.64806074889, Bermuda, Bolivia, British Virgin Islands, Cabo Verde, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Curacao, Czechia, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Eswatini, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Libya, Low income, Lower middle income, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, New Caledonia, North Macedonia, Northern Mariana Islands, Puerto Rico (US), Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., South Sudan, St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Tanzania, Turkiye, Turks and Caicos Islands, Upper middle income, Venezuela, RB, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### Climate cv sensitivity

- **Path:** `climate vulnerability/cv/vulnerability/sensitivity.csv`

- **Countries with data:** 192

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 69

  - 
American Samoa, Aruba, Bahamas, The, Barb994.64806074889, Bermuda, Bolivia, British Virgin Islands, Cabo Verde, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Curacao, Czechia, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Eswatini, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Libya, Low income, Lower middle income, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, New Caledonia, North Macedonia, Northern Mariana Islands, Puerto Rico (US), Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., South Sudan, St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Tanzania, Turkiye, Turks and Caicos Islands, Upper middle income, Venezuela, RB, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### Climate cv capacity

- **Path:** `climate vulnerability/cv/vulnerability/capacity.csv`

- **Countries with data:** 192

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 69

  - 
American Samoa, Aruba, Bahamas, The, Barb994.64806074889, Bermuda, Bolivia, British Virgin Islands, Cabo Verde, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Curacao, Czechia, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Eswatini, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Libya, Low income, Lower middle income, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, New Caledonia, North Macedonia, Northern Mariana Islands, Puerto Rico (US), Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., South Sudan, St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Tanzania, Turkiye, Turks and Caicos Islands, Upper middle income, Venezuela, RB, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### Climate cv food

- **Path:** `climate vulnerability/cv/vulnerability/food.csv`

- **Countries with data:** 192

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 69

  - 
American Samoa, Aruba, Bahamas, The, Barb994.64806074889, Bermuda, Bolivia, British Virgin Islands, Cabo Verde, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Curacao, Czechia, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Eswatini, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Libya, Low income, Lower middle income, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, New Caledonia, North Macedonia, Northern Mariana Islands, Puerto Rico (US), Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., South Sudan, St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Tanzania, Turkiye, Turks and Caicos Islands, Upper middle income, Venezuela, RB, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### Climate cv water

- **Path:** `climate vulnerability/cv/vulnerability/water.csv`

- **Countries with data:** 192

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 69

  - 
American Samoa, Aruba, Bahamas, The, Barb994.64806074889, Bermuda, Bolivia, British Virgin Islands, Cabo Verde, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Curacao, Czechia, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Eswatini, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Libya, Low income, Lower middle income, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, New Caledonia, North Macedonia, Northern Mariana Islands, Puerto Rico (US), Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., South Sudan, St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Tanzania, Turkiye, Turks and Caicos Islands, Upper middle income, Venezuela, RB, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### Climate cv health

- **Path:** `climate vulnerability/cv/vulnerability/health.csv`

- **Countries with data:** 192

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 69

  - 
American Samoa, Aruba, Bahamas, The, Barb994.64806074889, Bermuda, Bolivia, British Virgin Islands, Cabo Verde, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Curacao, Czechia, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Eswatini, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Libya, Low income, Lower middle income, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, New Caledonia, North Macedonia, Northern Mariana Islands, Puerto Rico (US), Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., South Sudan, St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Tanzania, Turkiye, Turks and Caicos Islands, Upper middle income, Venezuela, RB, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### Climate (Global Data Lab)

- **Path:** `global_data_lab/climate/climate vunerability index.csv`

- **Countries with data:** 43

  - 
Afghanistan, Algeria, Angola, Argentina urban, Bangladesh, Barbados, Belize, Benin, Bhutan, Bolivia, Botswana, Brazil, Burkina Faso, Burundi, Cambodia, Cameroon, Cape Verde, Central African Republic CAR, Chad, Chili, China, Colombia, Comoros, Congo Brazzaville, Congo Democratic Republic, Costa Rica, Cote d'Ivoire, Cuba, Djibouti, Dominican Republic, Ecuador, Egypt, El Salvador, Equatorial Guinea, Eritrea, Eswatini, Ethiopia, Fiji, Gabon, Gambia, Ghana, Guatemala, Guinea


- **Holes (countries in backbone but missing from this source):** 199

  - *(first 100)* 
Albania, American Samoa, Andorra, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, The, Bahrain, Barb994.64806074889, Belarus, Belgium, Bermuda, Bosnia and Herzegovina, British Virgin Islands, Brunei Darussalam, Bulgaria, Cabo Verde, Canada, Cayman Islands, Central African Republic, Chile, Congo, Dem. Rep., Congo, Rep., Croatia, Curacao, Cyprus, Czechia, Denmark, Dominica, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Estonia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Finland, Fragile and conflict affected situations, France, French Polynesia, Gambia, The, Georgia, Germany, Gibraltar, Greece, Greenland, Grenada, Guam, Guinea-Bissau, Guyana, Haiti, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia, Iran, Islamic Rep., Iraq, Ireland, Isle of Man, Israel, Italy, Jamaica, Japan, Jordan, Kazakhstan, Kenya, Kiribati, Korea, Dem. People's Rep., Korea, Rep., Kuwait, Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Latvia, Least developed countries: UN classification, Lebanon, Lesotho, Liberia, Libya, Liechtenstein, Lithuania, Low income, Lower middle income, Luxembourg, Macao SAR, China, Madagascar, Malawi, Malaysia
 ...



### Health vulnerability (Global Data Lab)

- **Path:** `global_data_lab/health/health vunerability data.csv`

- **Countries with data:** 39

  - 
Argentina urban, Azerbaijan, Bangladesh, Benin, Burkina Faso, Cambodia, Comoros, Cote d'Ivoire, Cuba, Eswatini, Fiji, Gabon, Gambia, Ghana, Jordan, Kenya, Kosovo, Lesotho, Liberia, Madagascar, Malawi, Mauritania, Mozambique, Nepal, Nigeria, Palestine, Philippines, Rwanda, Samoa, Senegal, Tanzania, Thailand, Tonga, Trinidad & Tobago, Turks & Caicos Islands, Tuvalu, Vanuatu, Vietnam, Yemen


- **Holes (countries in backbone but missing from this source):** 203

  - *(first 100)* 
Afghanistan, Albania, Algeria, American Samoa, Andorra, Angola, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Bahamas, The, Bahrain, Barb994.64806074889, Barbados, Belarus, Belgium, Belize, Bermuda, Bhutan, Bolivia, Bosnia and Herzegovina, Botswana, Brazil, British Virgin Islands, Brunei Darussalam, Bulgaria, Burundi, Cabo Verde, Cameroon, Canada, Cayman Islands, Central African Republic, Chad, Chile, China, Colombia, Congo, Dem. Rep., Congo, Rep., Costa Rica, Croatia, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Ecuador, Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Ethiopia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Finland, Fragile and conflict affected situations, France, French Polynesia, Gambia, The, Georgia, Germany, Gibraltar, Greece, Greenland, Grenada, Guam, Guatemala, Guinea, Guinea-Bissau, Guyana, Haiti, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia, Iran, Islamic Rep., Iraq, Ireland, Isle of Man, Israel, Italy, Jamaica, Japan, Kazakhstan, Kiribati, Korea, Dem. People's Rep., Korea, Rep.
 ...



### UNHCR displaced

- **Path:** `un/unhcr/displaced people data/persons_of_concern.csv`

- **Countries with data:** 186

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 76

  - 
American Samoa, Andorra, Bahamas, The, Barb994.64806074889, Bermuda, Bhutan, Bolivia, Central African Republic, Congo, Dem. Rep., Congo, Rep., Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Kiribati, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Low income, Lower middle income, Macao SAR, China, Maldives, Marshall Islands, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, Netherlands, New Caledonia, Northern Mariana Islands, Puerto Rico (US), Samoa, San Marino, Sao Tome and Principe, Serbia, Seychelles, Slovak Republic, Somalia, Fed. Rep., St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Syrian Arab Republic, Tanzania, Timor-Leste, Tonga, Turkiye, Tuvalu, United Kingdom, United States, Upper middle income, Venezuela, RB, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### IDU (HDX)

- **Path:** `hdx/idu`

- **Countries with data:** 76

  - 
Afghanistan, Albania, Algeria, Angola, Argentina, Bangladesh, Belize, Bhutan, Bolivia, Brazil, Burkina Faso, Burundi, Cambodia, Cameroon, Central African Republic, Chad, China, Colombia, Congo, Costa Rica, Cuba, Dem. Rep. Congo, Dominican Republic, Ecuador, Egypt, Eswatini, Ethiopia, Gabon, Gambia, Georgia, Guatemala, Guernsey, Haiti, India, Indonesia, Iran, Jamaica, Kenya, Madagascar, Malawi, Malaysia, Maldives, Mali, Mauritania, Mexico, Morocco, Mozambique, Myanmar, Nepal, Nicaragua, Niger, Nigeria, North Macedonia, Pakistan, Palestine, Papua New Guinea, Paraguay, Peru, Philippines, Russia, Senegal, Sierra Leone, Somalia, South Africa, South Sudan, Sri Lanka, Sudan, Syria, Tanzania, Thailand, Uganda, Ukraine, Viet Nam, Yemen, Zambia, Zimbabwe


- **Holes (countries in backbone but missing from this source):** 169

  - *(first 100)* 
American Samoa, Andorra, Antigua and Barbuda, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, The, Bahrain, Barb994.64806074889, Barbados, Belarus, Belgium, Benin, Bermuda, Bosnia and Herzegovina, Botswana, British Virgin Islands, Brunei Darussalam, Bulgaria, Cabo Verde, Canada, Cayman Islands, Chile, Comoros, Congo, Dem. Rep., Congo, Rep., Cote d'Ivoire, Croatia, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gambia, The, Germany, Ghana, Gibraltar, Greece, Greenland, Grenada, Guam, Guinea, Guinea-Bissau, Guyana, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Iraq, Ireland, Isle of Man, Israel, Italy, Japan, Jordan, Kazakhstan, Kiribati, Korea, Dem. People's Rep., Korea, Rep., Kuwait, Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Latvia, Least developed countries: UN classification, Lebanon, Lesotho, Liberia, Libya, Liechtenstein, Lithuania, Low income, Lower middle income, Luxembourg, Macao SAR, China
 ...



### EM-DAT disasters

- **Path:** `em_dat/em_dat_data.csv`

- **Countries with data:** 263

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 1

  - 
Barb994.64806074889



### Food trade dependency

- **Path:** `food trade dependency/data overview.csv`

- **Countries with data:** 66

  - 
Argentina, Australia, Bahrain, Bangladesh, Belarus, Belize, Bolivia (Plurinational State of), Bosnia and Herzegovina, Botswana, Brazil, Brunei Darussalam, Canada, Chile, China, China, Macao SAR, Colombia, Costa Rica, Côte d'Ivoire, Ecuador, Egypt, El Salvador, Ethiopia, EU 27, Georgia, Ghana, Guatemala, Honduras, India, Indonesia, Japan, Jordan, Kazakhstan, Kenya, Madagascar, Malaysia, Mauritius, Mexico, Montenegro, Morocco, Myanmar, Namibia, New Zealand, Norway, Panama, Paraguay, Peru, Philippines, Qatar, Republic of Korea, Russian Federation, Saudi Arabia, Senegal, Serbia, Singapore, South Africa, Sri Lanka, Switzerland, Taiwan, Thailand, The former Yugoslav Republic of Macedonia, Turkey, Ukraine, United Kingdom, United States of America, Uruguay, Zambia


- **Holes (countries in backbone but missing from this source):** 178

  - *(first 100)* 
Afghanistan, Albania, Algeria, American Samoa, Andorra, Angola, Antigua and Barbuda, Armenia, Aruba, Austria, Azerbaijan, Bahamas, The, Barb994.64806074889, Barbados, Belgium, Benin, Bermuda, Bhutan, Bolivia, British Virgin Islands, Bulgaria, Burkina Faso, Burundi, Cabo Verde, Cambodia, Cameroon, Cayman Islands, Central African Republic, Chad, Comoros, Congo, Dem. Rep., Congo, Rep., Cote d'Ivoire, Croatia, Cuba, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Equatorial Guinea, Eritrea, Estonia, Eswatini, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gabon, Gambia, The, Germany, Gibraltar, Greece, Greenland, Grenada, Guam, Guinea, Guinea-Bissau, Guyana, Haiti, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Iraq, Ireland, Isle of Man, Israel, Italy, Jamaica, Kiribati, Korea, Dem. People's Rep., Korea, Rep., Kuwait, Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Latvia, Least developed countries: UN classification, Lebanon, Lesotho, Liberia, Libya, Liechtenstein, Lithuania
 ...



### Food supply (OWID)

- **Path:** `our_world_in_data/food supply data.csv`

- **Countries with data:** 240

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 71

  - 
American Samoa, Andorra, Aruba, Bahamas, The, Barb994.64806074889, British Virgin Islands, Brunei Darussalam, Cabo Verde, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Curacao, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Equatorial Guinea, Eritrea, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Liechtenstein, Low income, Lower middle income, Macao SAR, China, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Monaco, Northern Mariana Islands, Palau, Puerto Rico (US), Russian Federation, San Marino, Singapore, Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Syrian Arab Republic, Timor-Leste, Turkiye, Turks and Caicos Islands, Upper middle income, Venezuela, RB, Viet Nam, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### Water per capita (OWID)

- **Path:** `our_world_in_data/freshwater resources per capita/renewable-water-resources-per-capita.csv`

- **Countries with data:** 195

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 77

  - 
American Samoa, Aruba, Bahamas, The, Barb994.64806074889, Bermuda, British Virgin Islands, Brunei Darussalam, Cabo Verde, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Curacao, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Kiribati, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Liechtenstein, Low income, Lower middle income, Macao SAR, China, Marshall Islands, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Monaco, Montenegro, New Caledonia, Northern Mariana Islands, Palau, Puerto Rico (US), Russian Federation, Samoa, San Marino, Seychelles, Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Syrian Arab Republic, Timor-Leste, Tonga, Turkiye, Turks and Caicos Islands, Tuvalu, Upper middle income, Venezuela, RB, Viet Nam, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### Agriculture water withdrawals (OWID)

- **Path:** `our_world_in_data/agriculture water withdrawals/agricultural-water-withdrawals.csv`

- **Countries with data:** 179

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 80

  - 
American Samoa, Andorra, Aruba, Bahamas, The, Barb994.64806074889, Bermuda, Bosnia and Herzegovina, British Virgin Islands, Brunei Darussalam, Cabo Verde, Cayman Islands, Congo, Dem. Rep., Congo, Rep., Curacao, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, French Polynesia, Gambia, The, Gibraltar, Greenland, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Kiribati, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Liechtenstein, Low income, Lower middle income, Macao SAR, China, Marshall Islands, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Nauru, New Caledonia, Northern Mariana Islands, Palau, Puerto Rico (US), Russian Federation, Samoa, San Marino, Sao Tome and Principe, Sint Maarten (Dutch part), Slovak Republic, Solomon Islands, Somalia, Fed. Rep., St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Syrian Arab Republic, Timor-Leste, Tonga, Turkiye, Turks and Caicos Islands, Tuvalu, Upper middle income, Vanuatu, Venezuela, RB, Viet Nam, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



### USDA agricultural

- **Path:** `usda/agricultural_production_1.csv`

- **Countries with data:** 89

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 234

  - *(first 100)* 
Afghanistan, Albania, Algeria, American Samoa, Andorra, Angola, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, The, Bahrain, Bangladesh, Barb994.64806074889, Barbados, Belarus, Belgium, Belize, Benin, Bermuda, Bhutan, Bolivia, Bosnia and Herzegovina, Botswana, Brazil, British Virgin Islands, Brunei Darussalam, Bulgaria, Burkina Faso, Burundi, Cabo Verde, Cambodia, Cameroon, Canada, Cayman Islands, Central African Republic, Chad, Chile, China, Colombia, Comoros, Congo, Dem. Rep., Congo, Rep., Costa Rica, Cote d'Ivoire, Croatia, Cuba, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Ecuador, Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Eswatini, Ethiopia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gabon, Gambia, The, Georgia, Germany, Ghana, Gibraltar, Greece, Greenland, Grenada, Guam, Guatemala, Guinea, Guinea-Bissau, Guyana, Haiti, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia
 ...



### GHI (Global Hunger Index)

- **Path:** `global hunger index/2025 csv.xlsx`

- **Countries with data:** 1

  - 
Rank1


- **Holes (countries in backbone but missing from this source):** 234

  - *(first 100)* 
Afghanistan, Albania, Algeria, American Samoa, Andorra, Angola, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, The, Bahrain, Bangladesh, Barb994.64806074889, Barbados, Belarus, Belgium, Belize, Benin, Bermuda, Bhutan, Bolivia, Bosnia and Herzegovina, Botswana, Brazil, British Virgin Islands, Brunei Darussalam, Bulgaria, Burkina Faso, Burundi, Cabo Verde, Cambodia, Cameroon, Canada, Cayman Islands, Central African Republic, Chad, Chile, China, Colombia, Comoros, Congo, Dem. Rep., Congo, Rep., Costa Rica, Cote d'Ivoire, Croatia, Cuba, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Ecuador, Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Eswatini, Ethiopia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gabon, Gambia, The, Georgia, Germany, Ghana, Gibraltar, Greece, Greenland, Grenada, Guam, Guatemala, Guinea, Guinea-Bissau, Guyana, Haiti, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia
 ...



### ACLED conflict

- **Path:** `acled - conflict data/fatalities per country.xlsx`

- **Countries with data:** 45

  - 
Afghanistan, Akrotiri and Dhekelia, Albania, Algeria, American Samoa, Andorra, Angola, Anguilla, Antarctica, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, Bahrain, Bailiwick of Guernsey, Bailiwick of Jersey, Bangladesh, Barbados, Belarus, Belgium, Belize, Benin, Bermuda, Bhutan, Bolivia, Bosnia and Herzegovina, Botswana, Brazil, British Indian Ocean Territory, British Virgin Islands, Brunei, Bulgaria, Burkina Faso, Burundi, Cambodia, Cameroon, Canada, Cape Verde, Caribbean Netherlands, Cayman Islands, Central African Republic


- **Holes (countries in backbone but missing from this source):** 199

  - *(first 100)* 
Bahamas, The, Barb994.64806074889, Brunei Darussalam, Cabo Verde, Chad, Chile, China, Colombia, Comoros, Congo, Dem. Rep., Congo, Rep., Costa Rica, Cote d'Ivoire, Croatia, Cuba, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Ecuador, Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Eswatini, Ethiopia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gabon, Gambia, The, Georgia, Germany, Ghana, Gibraltar, Greece, Greenland, Grenada, Guam, Guatemala, Guinea, Guinea-Bissau, Guyana, Haiti, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia, Iran, Islamic Rep., Iraq, Ireland, Isle of Man, Israel, Italy, Jamaica, Japan, Jordan, Kazakhstan, Kenya, Kiribati, Korea, Dem. People's Rep., Korea, Rep., Kuwait, Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Latvia, Least developed countries: UN classification, Lebanon, Lesotho, Liberia, Libya, Liechtenstein, Lithuania, Low income, Lower middle income, Luxembourg, Macao SAR, China, Madagascar, Malawi, Malaysia
 ...



### WPR malnutrition

- **Path:** `wpr/malnutrition-rate-by-country-2025.csv`

- **Countries with data:** 169

  - *(too many to list; see backbone below)*


- **Holes (countries in backbone but missing from this source):** 87

  - 
American Samoa, Andorra, Antigua and Barbuda, Aruba, Bahamas, The, Bahrain, Barb994.64806074889, Bermuda, Bhutan, British Virgin Islands, Brunei Darussalam, Burundi, Cabo Verde, Cayman Islands, Comoros, Congo, Dem. Rep., Congo, Rep., Cote d'Ivoire, Curacao, Czechia, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Egypt, Arab Rep., Equatorial Guinea, Eritrea, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fragile and conflict affected situations, Gambia, The, Gibraltar, Greenland, Grenada, Guam, Heavily indebted poor countries (HIPC), Hong Kong SAR, China, IDA & IBRD total, IDA blend, Iran, Islamic Rep., Isle of Man, Korea, Dem. People's Rep., Korea, Rep., Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Least developed countries: UN classification, Lesotho, Liechtenstein, Low income, Lower middle income, Macao SAR, China, Maldives, Marshall Islands, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Monaco, Nauru, Northern Mariana Islands, Palau, Puerto Rico (US), Qatar, Russian Federation, San Marino, Singapore, Sint Maarten (Dutch part), Slovak Republic, Somalia, Fed. Rep., South Sudan, St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Syrian Arab Republic, Tonga, Turkiye, Turks and Caicos Islands, Tuvalu, Upper middle income, Venezuela, RB, Viet Nam, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep.



---

## Backbone (World Bank countries used as reference)

Total: 234 countries.


Afghanistan, Albania, Algeria, American Samoa, Andorra, Angola, Antigua and Barbuda, Argentina, Armenia, Aruba, Australia, Austria, Azerbaijan, Bahamas, The, Bahrain, Bangladesh, Barb994.64806074889, Barbados, Belarus, Belgium, Belize, Benin, Bermuda, Bhutan, Bolivia, Bosnia and Herzegovina, Botswana, Brazil, British Virgin Islands, Brunei Darussalam, Bulgaria, Burkina Faso, Burundi, Cabo Verde, Cambodia, Cameroon, Canada, Cayman Islands, Central African Republic, Chad, Chile, China, Colombia, Comoros, Congo, Dem. Rep., Congo, Rep., Costa Rica, Cote d'Ivoire, Croatia, Cuba, Curacao, Cyprus, Czechia, Denmark, Djibouti, Dominica, Dominican Republic, Early-demographic dividend, East Asia & Pacific (excluding high income), East Asia & Pacific (IDA & IBRD countries), Ecuador, Egypt, Arab Rep., El Salvador, Equatorial Guinea, Eritrea, Estonia, Eswatini, Ethiopia, Europe & Central Asia (excluding high income), Europe & Central Asia (IDA & IBRD countries), Faroe Islands, Fiji, Finland, Fragile and conflict affected situations, France, French Polynesia, Gabon, Gambia, The, Georgia, Germany, Ghana, Gibraltar, Greece, Greenland, Grenada, Guam, Guatemala, Guinea, Guinea-Bissau, Guyana, Haiti, Heavily indebted poor countries (HIPC), Honduras, Hong Kong SAR, China, Hungary, Iceland, IDA & IBRD total, IDA blend, India, Indonesia, Iran, Islamic Rep., Iraq, Ireland, Isle of Man, Israel, Italy, Jamaica, Japan, Jordan, Kazakhstan, Kenya, Kiribati, Korea, Dem. People's Rep., Korea, Rep., Kuwait, Kyrgyz Republic, Lao PDR, Late-demographic dividend, Latin America & Caribbean (excluding high income), Latin America & the Caribbean (IDA & IBRD countries), Latvia, Least developed countries: UN classification, Lebanon, Lesotho, Liberia, Libya, Liechtenstein, Lithuania, Low income, Lower middle income, Luxembourg, Macao SAR, China, Madagascar, Malawi, Malaysia, Maldives, Mali, Malta, Marshall Islands, Mauritania, Mauritius, Mexico, Micronesia, Fed. Sts., Middle East, North Africa, Afghanistan & Pakistan, Moldova, Monaco, Mongolia, Montenegro, Morocco, Mozambique, Myanmar, Namibia, Nauru, Nepal, Netherlands, New Caledonia, New Zealand, Nicaragua, Niger, Nigeria, North Macedonia, Northern Mariana Islands, Norway, Oman, Pakistan, Palau, Panama, Papua New Guinea, Paraguay, Peru, Philippines, Poland, Portugal, Puerto Rico (US), Qatar, Romania, Russian Federation, Rwanda, Samoa, San Marino, Sao Tome and Principe, Saudi Arabia, Senegal, Serbia, Seychelles, Sierra Leone, Singapore, Sint Maarten (Dutch part), Slovak Republic, Slovenia, Solomon Islands, Somalia, Fed. Rep., South Africa, South Sudan, Spain, Sri Lanka, St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Sub-Saharan Africa (excluding high income), Sub-Saharan Africa (IDA & IBRD countries), Sudan, Suriname, Sweden, Switzerland, Syrian Arab Republic, Tajikistan, Tanzania, Thailand, Timor-Leste, Togo, Tonga, Trinidad and Tobago, Tunisia, Turkiye, Turkmenistan, Turks and Caicos Islands, Tuvalu, Uganda, Ukraine, United Arab Emirates, United Kingdom, United States, Upper middle income, Uruguay, Uzbekistan, Vanuatu, Venezuela, RB, Viet Nam, Virgin Islands (U.S.), West Bank and Gaza, Yemen, Rep., Zambia, Zimbabwe

