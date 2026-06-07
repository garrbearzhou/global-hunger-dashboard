# Summary: dynamic data extraction & dataset discrepancies — implementation roadmap

This document **summarizes** the two threads discussed with your professor and lists **logical next steps** to implement them properly in this project.

---

## Part A — Dynamic data extraction (what we concluded)

**Current state:** Indicators are loaded from **static snapshots** under `data/raw/` (CSV/XLSX), built when you (or a script) download from each provider.

**Message:** Many sources **do** support programmatic refresh, but **there is no single API** for everything. A sustainable pattern is:

| Source type | Typical approach |
|-------------|------------------|
| **World Bank WDI** | Official **Indicators API** (JSON/XML, no key for normal use) or **`WDI` R package** — same database as your CSV. |
| **FAO / FAOSTAT** | **Bulk downloads** or CRAN **`FAOSTAT`** helpers (`get_faostat_bulk_api`, etc.). |
| **WHO GHO** | **OData API** — refresh by **indicator ID**; metadata (year, age group) must stay aligned. |
| **OWID** | Often **GitHub-hosted CSVs** — pin **commit or release**, not a generic “OWID API.” |
| **UNHCR, HDX** | Portal + **CKAN-style API** on HDX to resolve **resource URLs**; terms vary. |
| **IPC / WFP** | Frequently **bulk files or partner portals**, not one stable public API for all country panels. |
| **ACLED, EM-DAT** | **Registration** and API or bulk export; respect terms of use. |
| **Climate / ND-GAIN** | Usually **scheduled downloads** of published panels. |

**Harmonization is still required:** APIs reduce manual copying; they **do not** fix different definitions (PoU vs IPC vs stunting). See Part B.

**Reference:** `docs/dynamic_data_apis.md`

---

## Part B — Dataset discrepancies (what we concluded)

**Structural issues:**

- **Geography:** Mix of **full country names**, **ISO3 codes** (sometimes in a column still named `Country`), and special cases — joins rely on `country_name_mapping.csv` + `standardize_country_names()`; **gaps remain** for edge cases.
- **UNHCR:** Often **country of asylum** (host), not origin — semantics differ from “hunger in country X.”
- **Event data (EM-DAT, IDU):** **Event-level** rows must be **aggregated** consistently to country-year before merging.

**Semantic issues (same word ≠ same indicator):**

- **Undernourishment** (FAO PoU) vs **IPC phase** (often subnational / partial coverage) vs **stunting** (children under five) — different populations and scales.
- **Poverty:** WB lines vs OWID — **different definitions**.
- **Climate indices:** **Composite scores** — not comparable in levels to prevalence rates without care.
- **Conflict / displacement:** Different **definitions** (fatalities vs intensity; refugees vs IDPs; host vs origin).

**Coding / statistical:**

- FAO **censored** values (`"<2.5"`) — statistically **interval-censored**, not exact zeros.
- **Mixed-type columns** in CSVs → `readr` parse warnings.
- **`latest_summary`** combines indicators from **different reference years** — a **synthetic** cross-section, not one survey wave.

**Artifacts:** `docs/data_source_discrepancies.md`, `docs/data_discrepancy_profile.csv` (regenerate with `Rscript scripts/analyze_data_discrepancies.R`).

---

## Part C — Logical next steps (implementation order)

### Phase 1 — Documentation & contracts (low code, high value)

1. **Data dictionary (single source of truth)**  
   - One table (CSV or sheet): **variable id**, **source**, **raw column name**, **unit**, **reference population**, **year / vintage**, **role in vulnerability formula**, **known limitations**.  
   - Link each row to a **citation** (already partly on Data Sources tab).

2. **Internal geography standard**  
   - Treat **ISO3** as the primary join key in **new** ETL; keep `country` as display name.  
   - Extend `country_name_mapping.csv` with a reviewed **ISO3 column** for ambiguous names.

3. **Manifest for each raw refresh**  
   - Small **`manifest.json`** next to each download: `source`, `url` or API call id, **`downloaded_at`**, **`file_hash`** or size, **`script_version`**.

### Phase 2 — Repeatable fetch pipeline (dynamic extraction, safely)

4. **One R (or Python) script per provider** (no monolith):  
   - `scripts/fetch_wb_wdi.R`  
   - `scripts/fetch_faostat_pou.R`  
   - `scripts/fetch_owid_*.R` (GitHub raw URL + pinned ref)  
   - etc.  
   - Each writes to **`data/raw/incoming/YYYYMMDD/`** then a **promotion step** copies to `data/raw/` when validated.

5. **Orchestration**  
   - **Quarterly** (or monthly) **cron** / GitHub Actions / local Task Scheduler: run fetch scripts → run **`analyze_data_discrepancies.R`** → diff row counts vs manifest → fail loudly on large drops.

6. **Rate limits & etiquette**  
   - Throttle API calls; prefer **bulk** where FAO/WB offer it; cache responses in `incoming/`.

### Phase 3 — Harmonization hardening (discrepancy remediation)

7. **Explicit join layer**  
   - Function **`join_to_backbone(iso3, indicator_tbl)`** used by all sources — no ad hoc `filter(country == ...)` scattered in `app.R` beyond what you already centralize.

8. **Censored FAO values**  
   - Store **both** raw string and **numeric lower bound** (or Tobit / survival-style model later); document in data dictionary.

9. **UNHCR / displacement**  
   - Separate columns: **`displaced_host_country`** vs **origin** if you ever add origin — until then, **label clearly** in UI (“asylum country”).

10. **IPC / GRFC**  
    - Keep **coverage flags** (e.g. `has_grfc_ipc`) in `latest_summary` so maps and tables **grey out** “not in GRFC sample” instead of implying national coverage.

### Phase 4 — Quality gates before the app reads new data

11. **Validation script** (`scripts/validate_raw_snapshot.R`):  
    - Min/max country count vs last manifest;  
    - Required columns present;  
    - No explosion of NA in key indicators;  
    - Optional: **checksum** match to previous week for non-versioned sources.

12. **Regenerate derived artifacts**  
    - After successful validation: run **`scripts/analyze_data_discrepancies.R`**, **`scripts/vulnerability_undernourishment_regressions.R`** (or fold into a single `make data-check`).

### Phase 5 — Optional product improvements

13. **Dashboard “Data vintage” strip** — show **last refresh date** and **year of latest observation** per major block (WB, FAO, etc.).

14. **Versioned backups** — `data/raw/archive/YYYY-MM-DD/` before overwriting production CSVs.

---

## Quick reference: files already in the repo

| File | Role |
|------|------|
| `docs/dynamic_data_apis.md` | API / bulk options by source |
| `docs/data_source_discrepancies.md` | Structural + semantic discrepancy narrative |
| `docs/data_discrepancy_profile.csv` | Automated scan of raw files |
| `scripts/analyze_data_discrepancies.R` | Regenerates discrepancy md + csv |
| `scripts/vulnerability_undernourishment_regressions.R` | Regression evidence vs undernourishment |

---

*This plan does not remove any variables from the vulnerability formula; it makes updates and interpretation **safer and reproducible**.*

---

## Implementation status (in this repo)

- **Data dictionary:** `data/metadata/data_dictionary.csv`
- **ISO3 crosswalk:** `data/metadata/crosswalk_country_iso3.csv` (rebuild: `Rscript scripts/build_crosswalk_iso3.R`)
- **Fetch / manifest / promote:** `scripts/data/` — see **`docs/data_pipeline_operations.md`**
- **Pipeline shell:** `scripts/run_data_refresh_pipeline.sh`
- **Validation:** `scripts/validate_raw_snapshot.R`
- **Harmonization columns** in `latest_summary`: `undernourishment_interval_censored`, `coverage_wfp_grfc`, `coverage_ipc_historical`, `unhcr_metric_scope`
- **Introduction UI:** collapsible “Data pipeline” box when `data/metadata/last_refresh.txt` exists
- **GitHub Actions:** `.github/workflows/data-pipeline.yml`
