# Data source discrepancies and harmonization notes

**Generated:** 2026-04-10 21:39

This report summarizes **structural** differences across raw files (geography key, time coverage, sampling) and **semantic** differences between indicators that sound similar but are **not** interchangeable.

---

## 1. Automated file profile

| Source | Exists | n_rows (sample) | n_cols | geo_column | geo_kind | year_min | year_max | censor-like strings | notes |
|---|---:|---:|---:|---|---|---:|---:|---|---|
| World Bank (WDI CSV) | TRUE | 6971 | 28 | country | country_name | 2000 | 2023 | FALSE | — |
| FAO fao_data.csv | TRUE | 5320 | 6 | country | country_name | 2020 | 2023 | FALSE | — |
| FAO Food Security bulk | TRUE | 8000 | 152 | Area | country_name | 1960 | 2100 | FALSE | sampled first 8000 rows |
| FAO FPMA | TRUE | 83 | 7 | — | — | — | — | FALSE | — |
| IPC general | TRUE | 34 | 11 | Country | country_name | — | — | FALSE | — |
| IPC historical 2017-2025 | TRUE | 8000 | 50 | Country | country_name | — | — | FALSE | sampled first 8000 rows |
| Historical outbreaks | TRUE | 30 | 8 | country | country_name | — | — | FALSE | — |
| WHO stunting | TRUE | 8000 | 15 | GEO_NAME_SHORT | country_name | — | — | FALSE | sampled first 8000 rows |
| OWID poverty | TRUE | 2874 | 3 | Country | country_name | 1963 | 2025 | FALSE | — |
| ND-GAIN climate vulnerability | TRUE | 192 | 31 | Name | country_name | — | — | FALSE | — |
| GDL health vulnerability | TRUE | 572 | 23 | Country | country_name | 2023 | 2023 | FALSE | — |
| UNHCR PoC | TRUE | 8000 | 12 | Country of Asylum | country_name | 2019 | 2020 | FALSE | sampled first 8000 rows |
| EM-DAT | TRUE | 7448 | 6 | country | country_name | 2020 | 2023 | FALSE | — |
| Food trade dependency | TRUE | 8000 | 14 | importer_country_name | country_name | — | — | FALSE | sampled first 8000 rows |
| OWID food supply | TRUE | 8000 | 3 | Entity | country_name | 1961 | 2022 | FALSE | sampled first 8000 rows |
| OWID water per cap | TRUE | 8000 | 4 | Entity | country_name | 1961 | 2021 | FALSE | sampled first 8000 rows |
| USDA ag | TRUE | 8000 | 10 | ISO3 | ISO3_code | 1961 | 2022 | FALSE | sampled first 8000 rows |
| WPR malnutrition | TRUE | 169 | 3 | country | country_name | — | — | FALSE | — |
| IDU global (HDX) | TRUE | 1 | 22 | country | country_name | 2022 | 2022 | FALSE | — |

---

## 2. Geographic identifier mismatches

- **Country names vs ISO3:** IPC files often store **ISO3 codes** in a column named `Country`, while FAO/WB/OWID tables use **full area names**. The profile table may still say `geo_kind = country_name` when the **column name** is `Country` — inspect **values** (three-letter codes vs full names). The app uses `country_name_mapping.csv` and `standardize_country_names()`; **residual join failures** remain for contested territories and variants.
- **UNHCR:** `Country of Asylum` is the unit of aggregation (host state), not always the hunger-affected population's origin — interpret displacement metrics accordingly.
- **EM-DAT / IDU:** Event- or crisis-level rows may duplicate country-year appearances when aggregated.

## 3. Conceptual / definitional discrepancies (same word, different meaning)

| Topic | Sources in this project | Discrepancy |
|--------|-------------------------|-------------|
| **Undernourishment / hunger** | FAO PoU (%); WFP GRFC IPC phase; WHO stunting | **PoU** = national calorie inadequacy prevalence; **IPC** = phase classification in analysed areas (not always national); **stunting** = chronic malnutrition in children under five — different populations and scales. |
| **Poverty** | World Bank `SI.POV.DDAY`; OWID poverty series | WB uses **international poverty lines** (e.g. $2.15 2017 PPP); OWID may use **multiple definitions** — compare variable notes before merging. |
| **Climate vulnerability** | ND-GAIN-style CSVs (0–1 index); sub-indices | Indices are **ordinal composites** — not comparable in levels to PoU or IPC without harmonization. |
| **Conflict** | ACLED fatalities | Fatality counts **≠** conflict risk index; annual sums mask seasonality. |
| **Displacement** | UNHCR PoC; IDU | Different **definitions** (refugees vs IDPs); **host** vs **origin** in UNHCR tables. |
| **Food trade** | Trade dependency extract | Units depend on source — not always comparable to FAO balances. |

## 4. Statistical / coding issues visible in raw extracts

- **Censored FAO values:** Prevalence often reported as `"<2.5"` — parsed in code as a numeric floor where needed; statistically this is **interval-censored**.
- **Mixed types:** Some CSVs mix text and numbers — causes `readr` **parse warnings** during app load.
- **Year alignment:** Merged "latest" profiles combine indicators from **different reference years** — not a single survey wave.

## 5. Suggested next steps

1. Maintain a **data dictionary** (one row per variable): source, unit, reference period, intended use in the score.
2. Prefer **ISO3** as internal join key with a reviewed crosswalk.
3. For updates, use **APIs or scheduled bulk downloads** — see `docs/dynamic_data_apis.md` — and version snapshots (e.g. `data/raw/YYYYMMDD/`).

Machine-readable: `docs/data_discrepancy_profile.csv`

