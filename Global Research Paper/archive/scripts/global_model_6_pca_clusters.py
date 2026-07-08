#!/usr/bin/env python3
"""
Model 6 — Resilience typologies via PCA + k-means clustering.

Feature matrix X (standardized): vulnerability, readiness, adaptation buffer,
ln GDP per capita, rural share, log(1+disasters), log(1+conflict fatalities).

Steps:
  1. Build cross-section, compute buffer from Model 1 fit (as in Model 4).
  2. Standardize features; eigendecompose the covariance (PCA).
  3. k-means on retained component scores; k chosen by silhouette over 2..6.
  4. Report variance explained, loadings, cluster profiles, members.

Outputs:
  output/global_model6_pca_loadings.csv
  output/global_model6_clusters.csv
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.metrics import silhouette_score
from sklearn.preprocessing import StandardScaler
from statsmodels.regression.linear_model import OLS

PAPER = Path(__file__).resolve().parents[1]
PROJECT = PAPER.parent
sys.path.insert(0, str(PAPER / "scripts"))

from global_models_1_to_4 import (  # noqa: E402
    CV_VULN,
    cross_section_2022,
    load_world_bank_backbone,
    wb_latest,
)

FEATURES = ["vulnerability", "readiness", "buffer", "ln_gdp_pcap",
            "rural_pct", "ln1_disasters", "ln1_fatalities"]
SEED = 42


def main() -> int:
    wb, backbone = load_world_bank_backbone()
    cs = cross_section_2022(wb, backbone)
    names = pd.read_csv(CV_VULN, low_memory=False)[["ISO3", "Name"]].rename(
        columns={"ISO3": "iso3", "Name": "country"})
    cs = cs.merge(names, on="iso3", how="left")

    # Backfill GDP / rural share with latest available year (<=2022) where the
    # strict-2022 extract is missing (ragged WB rows, e.g. Bangladesh).
    fill = wb_latest(wb, {"gdp_GDP.PCAP.CD": "gdp_fill", "pop_RUR.TOTL.ZS": "rural_fill"})
    cs = cs.merge(fill, on="iso3", how="left")
    cs["ln_gdp_pcap"] = cs["ln_gdp_pcap"].fillna(np.log(cs["gdp_fill"].clip(lower=1)))
    cs["rural_pct"] = cs["rural_pct"].fillna(cs["rural_fill"])

    d1 = cs.dropna(subset=["undernourishment", "vulnerability"]).copy()
    f1 = OLS(d1["undernourishment"], sm.add_constant(d1["vulnerability"])).fit(cov_type="HC1")
    d1["buffer"] = f1.fittedvalues - d1["undernourishment"]
    d1["ln1_disasters"] = np.log1p(d1["disaster_count"])

    d = d1.dropna(subset=FEATURES).copy()
    print(f"N = {len(d)} countries with complete features\n")

    X = StandardScaler().fit_transform(d[FEATURES])
    pca = PCA()
    scores = pca.fit_transform(X)
    evr = pca.explained_variance_ratio_

    print("=== PCA VARIANCE EXPLAINED ===")
    for i, v in enumerate(evr[:5], 1):
        print(f"PC{i}: {v:.3f}  (cum {evr[:i].sum():.3f})")
    n_keep = int(np.searchsorted(np.cumsum(evr), 0.80) + 1)
    print(f"Components retained (>=80% cumulative variance): {n_keep}\n")

    load = pd.DataFrame(pca.components_[:n_keep].T,
                        index=FEATURES, columns=[f"PC{i+1}" for i in range(n_keep)])
    print("=== LOADINGS (retained components) ===")
    print(load.round(3).to_string())
    load.round(4).to_csv(PAPER / "output" / "global_model6_pca_loadings.csv")

    Z = scores[:, :n_keep]
    print("\n=== K SELECTION (silhouette on retained scores) ===")
    best_k, best_s = None, -1
    for k in range(2, 7):
        km = KMeans(n_clusters=k, n_init=50, random_state=SEED).fit(Z)
        s = silhouette_score(Z, km.labels_)
        print(f"k={k}: silhouette={s:.3f}")
        if s > best_s:
            best_k, best_s, best_km = k, s, km
    print(f"Chosen k = {best_k}\n")

    def report(labels: np.ndarray, tag: str) -> None:
        dd = d.copy()
        dd["cluster"] = labels
        prof = dd.groupby("cluster")[FEATURES].mean().round(2)
        prof["n"] = dd.groupby("cluster").size()
        print(f"=== CLUSTER PROFILES ({tag}) ===")
        print(prof.to_string())
        print(f"\n=== CLUSTER MEMBERS ({tag}) ===")
        for c in sorted(dd["cluster"].unique()):
            members = dd[dd["cluster"] == c].sort_values("buffer", ascending=False)
            lst = ", ".join(members["country"].head(12))
            more = "" if len(members) <= 12 else f" (+{len(members)-12} more)"
            print(f"Cluster {c} (n={len(members)}, mean buffer "
                  f"{members['buffer'].mean():+.1f}): {lst}{more}")
        print()

    d["cluster"] = best_km.labels_
    report(best_km.labels_, f"k={best_k}, silhouette-optimal")

    km4 = KMeans(n_clusters=4, n_init=50, random_state=SEED).fit(Z)
    d["cluster_k4"] = km4.labels_
    report(km4.labels_, "k=4, typology refinement")

    out = d[["country", "iso3", "cluster", "cluster_k4"] + FEATURES].round(3)
    out.to_csv(PAPER / "output" / "global_model6_clusters.csv", index=False)
    print(f"\nWritten: output/global_model6_clusters.csv, global_model6_pca_loadings.csv")
    return 0


if __name__ == "__main__":
    sys.exit(main())
