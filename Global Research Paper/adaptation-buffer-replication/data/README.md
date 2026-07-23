# Data layout for replication

Place files under this `data/` folder using the paths below (scripts expect these exact relative locations).

## Required for Experiments 1–6

```
data/raw/climate vulnerability/cv/vulnerability/vulnerability.csv
data/raw/climate vulnerability/cv/readiness/readiness.csv
data/raw/fao/FAO_Data/Food_Security_Data_E_All_Data_NOFLAG.csv
data/raw/world_bank_data.csv
data/raw/em_dat/em_dat_data.csv
data/processed/acled_conflict_data.csv
```

## Required for robustness checks

```
data/raw/wri/WorldRiskIndex-2025.xlsx
data/raw/global_data_lab/climate/climate vunerability index.csv
data/raw/climate vulnerability/cv/vulnerability/exposure.csv
data/raw/who/child_stunting_data.csv
```

## Notes

- Raw inputs are not committed to GitHub by default (see `.gitignore`).
- If you already have these files in the parent Research Project `data/` tree, you can copy or symlink them into this folder before running.
- Do not commit API keys or private ACLED credentials.
