#!/usr/bin/env bash
# Full refresh: fetch (optional) -> validate -> discrepancy report -> regression report -> vintage stamp.
# Usage: ./scripts/run_data_refresh_pipeline.sh
#   FETCH_WB=1 to run WDI fetch (requires R WDI package and network).

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DATE_TAG="${DATE_TAG:-$(date +%Y%m%d)}"
export DATE_TAG

echo "== Data refresh pipeline =="
echo "ROOT=$ROOT DATE_TAG=$DATE_TAG"

mkdir -p "data/raw/incoming/$DATE_TAG" data/metadata

if [[ "${FETCH_WB:-0}" == "1" ]]; then
  echo "-> Fetching World Bank WDI..."
  Rscript scripts/data/fetch_world_bank_wdi.R "$DATE_TAG"
else
  echo "-> Skipping WDI fetch (set FETCH_WB=1 to enable)."
  Rscript scripts/data/fetch_placeholder.R "$DATE_TAG"
fi

echo "-> Validating raw snapshot..."
Rscript scripts/validate_raw_snapshot.R || { echo "Validation failed"; exit 1; }

echo "-> Data discrepancy profile..."
Rscript scripts/analyze_data_discrepancies.R

echo "-> Undernourishment regressions (long run; sources app.R)..."
Rscript scripts/vulnerability_undernourishment_regressions.R

STAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
{
  echo "refreshed_at_utc=$STAMP"
  echo "incoming_folder=data/raw/incoming/$DATE_TAG"
  echo "note=Regenerate app data by replacing files under data/raw/ after promote_incoming.R"
} > data/metadata/last_refresh.txt

echo "-> Wrote data/metadata/last_refresh.txt"
echo "Done."
