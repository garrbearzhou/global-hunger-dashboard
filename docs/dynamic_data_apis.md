# Dynamic data collection: APIs and programmatic access

Your dashboard currently uses **versioned CSV/XLSX snapshots** under `data/raw/`. For **ongoing updates** (what your professor called “dynamic” extraction), these are the main **official programmatic options** that correspond to your sources. None of these replace careful **harmonization** (see `docs/data_source_discrepancies.md`).

---

## 1. World Bank — World Development Indicators (WDI)

- **REST API (JSON/XML):** [World Bank Indicators API](https://datahelpdesk.worldbank.org/knowledgebase/articles/889392-about-the-indicators-api-documentation) — v2, no API key required for typical use.
- **Example:**  
  `https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?format=json&date=2010:2020&per_page=1000`
- **R:** Package **`WDI`** (you already use this pattern in `load_hunger_data()` when building from API) — pulls the same database as the bulk CSV.
- **Notes:** Rate limits apply for heavy use; for **full-country panels** many teams prefer **periodic bulk CSV** (what you have) plus occasional API refresh for new years.

---

## 2. FAO — FAOSTAT (food security, PoU, trade, etc.)

- **Bulk API / downloads:** FAO provides **dataset codes** and **bulk files** (CSV/ZIP). The CRAN package **`FAOSTAT`** (e.g. `get_faostat_bulk_api()`, bulk URL helpers) wraps the **FAOSTAT bulk** workflow.
- **Portal:** [FAOSTAT data](https://www.fao.org/faostat/en/#data) — select domain → download or copy bulk URL.
- **Notes:** “Food security” indicators (e.g. prevalence of undernourishment) are **not** the same as IPC phases or WFP operational metrics — keep definitions separate in your data dictionary.

---

## 3. WHO Global Health Observatory (GHO)

- **API:** [WHO GHO OData API](https://www.who.int/data/gho/info/gho-odata-api) — OData-style endpoints for many indicators (e.g. child stunting).
- **Notes:** Indicator codes and **reference years** vary by country; often requires **merging metadata** (age group, sex, estimate type). Your static extract should be refreshed by **re-querying the same indicator ID** when updating.

---

## 4. Our World in Data (OWID) — charts based on CSV

- OWID does **not** typically offer a single “hunger API” for all charts. Datasets are often **mirrored on GitHub** (CSV) with clear provenance.
- **Approach:** Use **GitHub raw URLs** or **ETL scripts** that pull the same CSV your extract came from, and **pin commit or release** for reproducibility.

---

## 5. UNHCR — population statistics

- **UNHCR data finder / API:** See [UNHCR data portal](https://www.unhcr.org/refugee-statistics) and their documentation for **download packages** and any **API** they expose for operational statistics (offerings change over time).
- **Notes:** Tables are often **by country of asylum** / **origin** — your discrepancy report flags **host vs origin** ambiguity.

---

## 6. HDX (Humanitarian Data Exchange) — IDU and similar

- **API:** [HDX CKAN API](https://data.humdata.org/documentation) — search datasets, get **resource URLs**, download CSV programmatically.
- **Notes:** IDU files are often **per-country** extracts; aggregation to a **global panel** is your responsibility (naming typos like `seirra leone` appear in filenames).

---

## 7. IPC / WFP (food security phases)

- **IPC** analysis products are often distributed as **reports and spreadsheets** via partners (WFP, IPC Global). A **stable public API** for all IPC country panels is **not** always available; many workflows use **scheduled downloads** from the authoritative partner portal when permitted.
- **WFP APIs:** WFP sometimes exposes **VAM / data APIs** for specific products — check [WFP VAM data](https://dataviz.vam.wfp.org/) and terms of use for automation.

---

## 8. EM-DAT (disasters)

- **Access:** [EM-DAT](https://www.emdat.be/) — public access may require **registration**; bulk export is common for research.
- **Notes:** Event-level data → **aggregation to country-year** must match your app’s logic.

---

## 9. ACLED (conflict)

- **API:** [ACLED API](https://acleddata.com/api-documentation/) — typically requires **registration** and compliance with terms of use.
- **Notes:** Event microdata vs **pre-aggregated fatalities by country** (your extract) need explicit alignment.

---

## 10. Climate / ND-GAIN–style indices

- **Notre Dame GAIN:** Check [GAIN](https://gain.nd.edu/) for **download** and citation; API availability varies by product.
- **Replication:** Many projects **download annual country panels** on a schedule rather than live API calls.

---

## Practical architecture (recommended)

1. **Keep snapshots** in `data/raw/YYYYMMDD/` or git-lfs for large files.  
2. **Scripts** (R or Python) per source: `fetch_wb.R`, `fetch_fao_bulk.R`, etc., writing to `data/raw/` then your existing **merge pipeline**.  
3. **Schedule** (cron, GitHub Actions, or a server job) **monthly or quarterly** — not every page load — to respect rate limits and reproducibility.  
4. **Log** API version, download URL, and **run date** in a small `manifest.json` next to the extract.

This gives your professor a clear answer: **yes, dynamic extraction is feasible** for WB, FAO bulk, WHO GHO, HDX, and (with registration) ACLED; **IPC/WFP and some humanitarian products** are often **bulk or partner-mediated** rather than a single REST API for everything.
