# Sources for Historical Hunger Outbreak Data

## Current Status

The current dataset includes **18 countries** with documented major hunger crises in the 21st century. This data is manually curated and needs expansion.

## Quick Start: Best Data Sources

**For comprehensive famine data, prioritize these sources (in order):**

1. **FAO Global Report on Food Crises** ⭐ **BEST SOURCE**
   - Most authoritative and comprehensive
   - Specifically tracks food crises and famines
   - Annual reports from 2017-present
   - Download from: https://www.fao.org/emergencies/resources/documents/resources-detail/en/c/1208963/

2. **IPC (Integrated Food Security Phase Classification)**
   - Standardized famine classification (Phase 4 = Emergency, Phase 5 = Famine)
   - Country-specific reports
   - Access at: https://www.ipcinfo.org/

3. **WFP Emergency Reports**
   - Country briefs and situation reports
   - Emergency operations database
   - Access at: https://www.wfp.org/publications

4. **EM-DAT** (Use with caution - no "famine" category)
   - Search "Food shortage" disaster type
   - Also check "Drought" events with high mortality
   - Cross-reference with FAO/WFP to verify
   - Access at: https://www.emdat.be/

**Note:** EM-DAT does NOT have a "famine" category, so use it as supplementary data only.

## Recommended Data Sources

### ⚠️ Important Note on EM-DAT
EM-DAT does **NOT** have a specific "Famine" category. Famine-related events are typically found under:
- **"Food shortage"** (disaster subset that includes famines)
- **"Drought"** (many famines are drought-induced)
- **"Complex Disasters"** (conflict-related famines)
- Sometimes under other categories

**Recommendation:** Use EM-DAT as a supplementary source, but **prioritize FAO and WFP reports** for comprehensive famine data, as they specifically track food crises.

### 1. EM-DAT (Emergency Events Database)
**URL:** https://www.emdat.be/
**Description:** The most comprehensive database of natural and technological disasters. **Note:** EM-DAT does NOT have a specific "Famine" category, but captures famine-related events under other classifications.

**How to Access:**
- Register for free account at emdat.be
- Use the Advanced Search feature
- **Search Strategy:**
  1. **Disaster Type:** Select "Food shortage" (this is the closest category to famine)
  2. **OR** Search by "Drought" events (many famines are drought-related)
  3. **OR** Use keyword search in event names/descriptions for terms like:
     - "famine"
     - "food crisis"
     - "starvation"
     - "hunger emergency"
  4. Filter by date range (2000-present)
  5. Filter by countries of interest
  6. Look for events with high death counts (>1000) or high affected populations (>100,000)
- Export filtered results as CSV

**Important Notes:**
- **"Food shortage"** is the disaster subset that includes famine events in EM-DAT
- Many famines are recorded under **"Drought"** category (especially in Africa)
- Some famine events may be under **"Complex Disasters"** or **"Epidemic"** (if disease was a major factor)
- **Cross-reference with other sources** (FAO, WFP) to identify famine events that might be categorized differently

**Data Fields Available:**
- Event name
- Country/Countries affected
- Start date
- End date
- Total deaths
- Total affected
- Event type classification
- Disaster subtype

**Coverage:** Global, 1900-present (comprehensive from 2000)

**Limitation:** Since there's no dedicated "famine" category, you may need to:
1. Search multiple disaster types (Food shortage, Drought, Complex disasters)
2. Manually review events with high mortality/affected populations
3. Cross-reference with FAO/WFP reports to identify which events were actual famines

---

### 2. FAO Food Crises Reports
**URL:** https://www.fao.org/emergencies/resources/documents/resources-detail/en/c/1208963/
**Description:** FAO's annual reports on food crises globally.

**Key Reports:**
- **Global Report on Food Crises** (annual, 2017-present)
- **Crop Prospects and Food Situation** (quarterly)
- **Food Security Information Network (FSIN) Reports**

**How to Access:**
- Download PDF reports from FAO website
- Extract crisis information manually or use PDF parsing tools
- Focus on countries listed in "Severe Food Insecurity" sections

**Coverage:** Global, comprehensive from 2017, some historical data available

---

### 3. WFP (World Food Programme) Emergency Reports
**URL:** https://www.wfp.org/publications
**Description:** WFP publishes detailed reports on food emergencies and humanitarian crises.

**Key Resources:**
- **Emergency Operations** database
- **Country Briefs** (country-specific crisis information)
- **Situation Reports** (ongoing crises)

**How to Access:**
- Browse WFP publications by country
- Look for "Emergency" or "Crisis" designations
- Extract dates and severity information

**Coverage:** Global, comprehensive from 2000s

---

### 4. FEWS NET (Famine Early Warning Systems Network)
**URL:** https://fews.net/
**Description:** Specialized in food security early warning and crisis monitoring.

**Key Resources:**
- **Food Security Alerts** (by country)
- **Historical Crisis Timeline**
- **IPC (Integrated Food Security Phase Classification) Reports**

**How to Access:**
- Browse country pages for historical alerts
- Download IPC reports (classify food security phases)
- Phase 4 (Emergency) and Phase 5 (Famine) indicate major crises

**Coverage:** Focus on Africa, Middle East, Central America, Haiti (comprehensive from 2000s)

---

### 5. IPC (Integrated Food Security Phase Classification)
**URL:** https://www.ipcinfo.org/
**Description:** Standardized scale for classifying food security crises.

**IPC Classifications:**
- **Phase 1:** Minimal
- **Phase 2:** Stressed
- **Phase 3:** Crisis
- **Phase 4:** Emergency
- **Phase 5:** Famine/Catastrophe

**How to Access:**
- Browse country analyses
- Download IPC reports (PDF/Excel)
- Extract Phase 4 and Phase 5 periods

**Coverage:** Global, comprehensive from 2004

---

### 6. Academic and Research Sources

**Key Databases:**
- **Google Scholar:** Search "famine [country] [year]"
- **JSTOR:** Historical famine research
- **PubMed:** Health impacts of food crises

**Key Publications:**
- "The State of Food Security and Nutrition in the World" (FAO annual)
- "Global Hunger Index" reports (Welthungerhilfe/Concern Worldwide)
- Academic papers on specific famines

---

### 7. News Archives and Media Sources

**Reliable Sources:**
- **BBC News Archives:** Search for "famine" or "food crisis"
- **Reuters:** Crisis reporting
- **Associated Press:** Historical crisis coverage
- **The Guardian:** In-depth crisis reporting

**How to Use:**
- Search archives by country and year
- Look for keywords: "famine", "food crisis", "starvation", "hunger emergency"
- Extract dates and affected regions

---

### 8. Government and UN Reports

**Sources:**
- **UN OCHA (Office for Coordination of Humanitarian Affairs):** Situation reports
- **UNICEF:** Nutrition crisis reports
- **National government reports:** Some countries publish crisis documentation
- **EU ECHO (European Civil Protection and Humanitarian Aid):** Crisis reports

---

## Data Collection Strategy

### Phase 1: Systematic Review (Recommended)

**Recommended Primary Sources (in order of priority):**

1. **Start with FAO Global Report on Food Crises:**
   - Most comprehensive and authoritative source
   - Specifically tracks food crises and famines
   - Annual reports from 2017-present
   - Historical data available in earlier reports
   - Lists countries in "Severe Food Insecurity" (Phase 3+) and "Famine" (Phase 5)

2. **Cross-reference with IPC (Integrated Food Security Phase Classification):**
   - For each country in EM-DAT, check IPC reports
   - Identify Phase 4 and Phase 5 periods
   - Note start/end dates

3. **Supplement with WFP Emergency Reports:**
   - Check WFP country briefs and situation reports
   - Identify countries with emergency operations
   - Note crisis start/end dates and severity

4. **Use EM-DAT as supplementary source:**
   - Search "Food shortage" events (2000-present)
   - Search "Drought" events with high mortality
   - Cross-reference with FAO/WFP to verify famine classification
   - **Note:** EM-DAT may categorize some famines under different disaster types

5. **Fill gaps with FEWS NET:**
   - Check countries not well-covered by other sources
   - Review historical alerts and IPC reports
   - Focus on Africa, Middle East, Central America, Haiti

### Phase 2: Data Formatting

For each crisis, collect:
- **Country name** (standardized)
- **Crisis start year**
- **Crisis end year** (or "ongoing")
- **Severity level** (Famine, Severe Crisis, etc.)
- **Primary cause** (Drought, Conflict, Economic, etc.)
- **Affected population** (if available)
- **Deaths** (if available)

### Phase 3: Integration

Update the `create_comprehensive_data_table.R` script to:
1. Load your new historical crisis CSV
2. Join it to the comprehensive data
3. Update the `hunger_outbreaks` data frame or load from CSV

---

## Example Data Structure

Create a CSV file: `data/raw/historical_hunger_outbreaks.csv`

```csv
country,outbreak_start_year,outbreak_end_year,severity,primary_cause,affected_population,deaths,source
Somalia,2011,2012,Famine,Drought,4000000,260000,EM-DAT
Somalia,2017,2017,Severe Crisis,Drought,6300000,0,FAO
Yemen,2016,2023,Ongoing,Conflict,20000000,377000,UN OCHA
South Sudan,2017,2023,Ongoing,Conflict,7000000,0,IPC
...
```

---

## Current Countries with Major Outbreaks (21st Century)

The following countries are already documented:
1. Somalia
2. Yemen
3. South Sudan
4. Nigeria
5. Ethiopia
6. Afghanistan
7. Haiti
8. Madagascar
9. Democratic Republic of the Congo
10. Central African Republic
11. Chad
12. Mali
13. Burkina Faso
14. Niger
15. Zambia
16. Zimbabwe
17. Venezuela (Bolivarian Republic of)
18. United Republic of Tanzania

## Additional Countries to Research

Based on historical records, also consider:
- **North Korea** (1990s-2000s, some ongoing issues)
- **Sudan** (Darfur crisis, ongoing conflicts)
- **Syria** (2011-present, conflict-related)
- **Myanmar** (Rohingya crisis, ongoing conflicts)
- **Cameroon** (Boko Haram affected regions)
- **Mozambique** (conflict in Cabo Delgado)
- **Lebanon** (2020 economic crisis)
- **Sri Lanka** (2022 economic crisis)
- **Zimbabwe** (2000s hyperinflation crisis)
- **Venezuela** (2016-present economic collapse)

---

## Automation Options

### Option 1: Manual Collection (Most Reliable)
- Systematically review each source
- Create structured CSV with all crises
- Update script to load from CSV

### Option 2: Web Scraping (Advanced)
- Scrape EM-DAT website (if API available)
- Parse FAO/WFP PDF reports
- Extract structured data automatically

### Option 3: API Access (If Available)
- Check if EM-DAT has API access
- Use FAO/WFP APIs if available
- Automate data collection

---

## Next Steps

1. **Start with EM-DAT:** Register and download famine data
2. **Create structured CSV:** Format as shown above
3. **Update the script:** Modify `create_comprehensive_data_table.R` to load from CSV
4. **Verify data:** Cross-check with multiple sources
5. **Re-run script:** Generate updated comprehensive CSV

---

## Notes

- **Definition of "Major Hunger Outbreak":** 
  - Famine (IPC Phase 5) OR
  - Severe crisis affecting >1 million people OR
  - Crisis causing >10,000 deaths OR
  - Crisis requiring major international humanitarian response

- **Data Quality:** Prioritize official sources (UN, FAO, WFP) over media reports
- **Ongoing Crises:** Mark end_year as current year or "Ongoing"
- **Multiple Crises:** Some countries may have multiple entries for different time periods

