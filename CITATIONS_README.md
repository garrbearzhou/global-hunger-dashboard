# Citations and References Guide

This document explains how to add citations to the Global Hunger Research Dashboard.

## Overview

The dashboard includes a "References and Citations" section on the Introduction page that displays all data sources and references in APA citation format.

## How to Add Citations

### Method 1: Using the Helper Script (Recommended)

1. Open `add_citation.R`
2. Uncomment the `generate_citation()` line at the bottom
3. Paste your URL:
   ```r
   generate_citation(url = "https://your-url-here.com")
   ```
4. Optionally add more information:
   ```r
   generate_citation(
     url = "https://your-url-here.com",
     organization = "Organization Name",
     title = "Title of the Resource",
     year = "2024",
     description = "Brief description of what this source provides"
   )
   ```
5. Run the script - it will generate:
   - R code to copy into `app.R`
   - A preview of how the citation will appear
   - The formatted citation text

6. Copy the generated code and add it to the `citations_data` list in `app.R` (around line 1450)

### Method 2: Manual Addition

Add entries directly to the `citations_data` list in `app.R`:

```r
list(
  organization = "Organization Name",
  title = "Title of the Resource",
  url = "https://your-url-here.com",
  year = "2024",
  accessed_date = format(Sys.Date(), "%B %d, %Y"),
  description = "Brief description of what this source provides"
)
```

## Current Citations

The following sources are currently included:

1. **World Bank** - World Development Indicators
2. **FAO** - FAOSTAT Food Security Indicators
3. **WFP** - Global Report on Food Crises 2025
4. **WHO** - Global Health Observatory Data
5. **Global Data Lab** - Subnational Human Development Index
6. **Our World in Data** - Global Development Data
7. **UNHCR** - Refugee Statistics

## Citation Format

Citations are automatically formatted in APA style:
- Organization. (Year). Title. Retrieved from URL (accessed Date).
- Followed by a brief description in italics

## Example

If you paste this URL:
```
https://data.worldbank.org/indicator/SI.POV.DDAY
```

The helper script will generate:
```r
list(
  organization = "World Bank",
  title = "World Development Indicators - Poverty",
  url = "https://data.worldbank.org/indicator/SI.POV.DDAY",
  year = "2024",
  accessed_date = format(Sys.Date(), "%B %d, %Y"),
  description = "Data from World Bank"
)
```

Which will display as:
> World Bank. (2024). World Development Indicators - Poverty. Retrieved from https://data.worldbank.org/indicator/SI.POV.DDAY (accessed [current date]).
> 
> *(Data from World Bank)*

## Tips

- The helper script tries to automatically identify organizations from common domains
- You can always override the auto-detected values by providing them explicitly
- For academic papers, include author names in the organization field
- For books, include publisher information
- Always verify the year of publication/update

## Questions?

If you need help formatting a specific citation, just paste the URL and any additional information you have, and the citation can be properly formatted.



