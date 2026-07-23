#!/usr/bin/env python3
"""
Compute the global adaptation buffer for every country in the Model 1
cross-section and write a ranked table.

buffer_i = (Model 1 predicted PoU from vulnerability) - actual PoU
Positive buffer => country beats the climate-only benchmark.

Output: output/global_buffer_rankings.csv
"""

import sys
from pathlib import Path

import pandas as pd
import statsmodels.api as sm
from statsmodels.regression.linear_model import OLS

PAPER = Path(__file__).resolve().parents[1]  # repo root
PROJECT = PAPER
sys.path.insert(0, str(PAPER / "scripts"))

from global_models_1_to_4 import (  # noqa: E402
    CV_VULN,
    cross_section_2022,
    load_world_bank_backbone,
)


def main() -> int:
    wb, backbone = load_world_bank_backbone()
    cs = cross_section_2022(wb, backbone)

    names = pd.read_csv(CV_VULN, low_memory=False)[["ISO3", "Name"]].rename(
        columns={"ISO3": "iso3", "Name": "country"}
    )
    cs = cs.merge(names, on="iso3", how="left")

    d = cs.dropna(subset=["undernourishment", "vulnerability"]).copy()
    X = sm.add_constant(d["vulnerability"])
    fit = OLS(d["undernourishment"], X).fit(cov_type="HC1")

    d["predicted"] = fit.predict(X)
    d["buffer"] = d["predicted"] - d["undernourishment"]
    d = d.sort_values("buffer", ascending=False).reset_index(drop=True)
    d["rank"] = d.index + 1

    out = d[
        ["rank", "country", "iso3", "vulnerability", "readiness",
         "undernourishment", "predicted", "buffer"]
    ].round(3)
    out_path = PAPER / "output" / "global_buffer_rankings.csv"
    out.to_csv(out_path, index=False)

    print(f"N = {len(out)}; written to {out_path}\n")
    print("=== TOP 15 OVERPERFORMERS (largest positive buffer) ===")
    print(out.head(15).to_string(index=False))
    print("\n=== BOTTOM 15 UNDERPERFORMERS (most negative buffer) ===")
    print(out.tail(15).to_string(index=False))
    print("\n=== SELECTED COUNTRIES ===")
    sel = out[out["iso3"].isin(["BGD", "VNM", "ETH", "IND", "NER", "TCD", "YEM", "HTI", "AFG", "PRK", "MDG", "COD"])]
    print(sel.to_string(index=False))
    print("\nSummary stats:")
    print(out["buffer"].describe().round(2).to_string())
    return 0


if __name__ == "__main__":
    sys.exit(main())
