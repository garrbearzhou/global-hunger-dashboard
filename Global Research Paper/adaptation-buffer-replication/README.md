# Adaptation Buffer — Analysis Code

Replication code for the manuscript:

**Climate Vulnerability Does Not Equal Hunger: Measuring the Global Adaptation Buffer**

Authors: Garrett Zhou; Hannah Jacobs

This repository contains the Python scripts used for Experiments 1–6 and robustness checks (ordinary least squares regression and Monte Carlo simulation).

## Contents

```
scripts/
  global_models_1_to_4.py      # OLS Experiments 1, 2, 4 (+ shared data loaders)
  compute_buffer_rankings.py   # Experiment 3 buffer rankings
  global_monte_carlo.py        # Experiments 5–6 (uncertainty + collapse)
  global_robustness_checks.py  # Robustness R1–R5
output/                        # Example CSV outputs from a completed run
data/                          # Place downloaded raw/processed inputs here (not bundled)
requirements.txt
```

## Requirements

- Python 3.10+ recommended
- Packages listed in `requirements.txt`

```bash
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

## Data setup

Public data sources are **not** redistributed here (size / licensing). Download them and place files so paths match `data/README.md`.

Main sources (also cited in the manuscript):

- ND-GAIN Country Index: https://gain.nd.edu/our-work/country-index/download-data/
- FAOSTAT Suite of Food Security Indicators (Item 210041): https://www.fao.org/faostat/en/#data/FS
- World Bank World Development Indicators: https://databank.worldbank.org
- EM-DAT: https://www.emdat.be
- ACLED: https://acleddata.com
- World Risk Index / Global Data Lab / WHO stunting (for robustness): see `data/README.md`

## How to run

From the **repository root**:

```bash
python3 scripts/global_models_1_to_4.py
python3 scripts/compute_buffer_rankings.py
python3 scripts/global_monte_carlo.py
python3 scripts/global_robustness_checks.py
```

Outputs are written to `output/`.

Monte Carlo uses `random seed = 42` and `20,000` iterations (as reported in the manuscript).

## Citation

If you use this code, please cite the manuscript and this repository URL.
