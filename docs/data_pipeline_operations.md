# Data pipeline operations

| Artifact | Purpose |
|----------|---------|
| `data/metadata/data_dictionary.csv` | Variable ↔ source ↔ unit ↔ role in score |
| `data/metadata/crosswalk_country_iso3.csv` | Canonical country name ↔ `iso3c` (from WB panel); run `Rscript scripts/build_crosswalk_iso3.R` to refresh |
| `data/raw/incoming/YYYYMMDD/` | Staging for fetches; each folder may contain `manifest.json` |
| `data/raw/archive/YYYYMMDD/` | Optional archives before promotion (`scripts/data/promote_incoming.R`) |
| `data/metadata/last_refresh.txt` | Stamp written by `scripts/run_data_refresh_pipeline.sh` |
| `data/metadata/validation_baseline.csv` | Created by first `validate_raw_snapshot.R` run for row-count regression tests |

## Commands

```bash
# Rebuild ISO3 crosswalk from current world_bank_data.csv
Rscript scripts/build_crosswalk_iso3.R

# Validate current raw files
Rscript scripts/validate_raw_snapshot.R

# Full pipeline (placeholder fetch + validate + discrepancy + regressions + last_refresh.txt)
./scripts/run_data_refresh_pipeline.sh

# With live World Bank WDI download (needs network + WDI package)
FETCH_WB=1 ./scripts/run_data_refresh_pipeline.sh
```

## Harmonization fields in `latest_summary` (app)

- `undernourishment_interval_censored` — `TRUE` when FAO bulk raw value was `<2.5` (metadata; score uses numeric floor as before).
- `coverage_wfp_grfc` / `coverage_ipc_historical` — logical flags for GRFC vs IPC historical year availability.
- `unhcr_metric_scope` — short text explaining UNHCR totals are **asylum/host country** when displacement data exist.

GitHub Actions: `.github/workflows/data-pipeline.yml` runs validation + discrepancy profile on a schedule (not full Shiny-sourced regressions by default).
