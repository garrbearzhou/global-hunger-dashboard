#!/usr/bin/env python3
"""
Model 7 — Regularized out-of-sample prediction of the adaptation buffer.

Outcome: buffer_c = Model-1 fitted PoU - actual PoU (as in Model 4).
Predictors (vulnerability and its components EXCLUDED, as in Model 4):
  ND-GAIN readiness + components (economic, governance, social);
  World Bank 2022 structure (ln GDPpc, rural/urban shares, agri land,
  arable land, crop production index, life expectancy, infant mortality,
  population growth, inflation); EM-DAT disasters; ACLED conflict.

Pipeline: median imputation -> standardization -> {OLS, RidgeCV, LassoCV,
ElasticNetCV}; 80/20 train/test split (seed 42); penalties via 5-fold CV
on the training set; report test RMSE/MAE and Lasso-surviving predictors.

Outputs: output/global_model7_results.csv, output/global_model7_coefs.csv
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm
from sklearn.impute import SimpleImputer
from sklearn.linear_model import ElasticNetCV, LassoCV, LinearRegression, RidgeCV
from sklearn.metrics import mean_absolute_error, mean_squared_error
from sklearn.model_selection import KFold, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from statsmodels.regression.linear_model import OLS

PAPER = Path(__file__).resolve().parents[1]
PROJECT = PAPER.parent
sys.path.insert(0, str(PAPER / "scripts"))

from global_models_1_to_4 import (  # noqa: E402
    CV_READ,
    CV_VULN,
    cross_section_2022,
    load_world_bank_backbone,
    wb_latest,
)

SEED = 42
READ_DIR = CV_READ.parent

WB_VARS = {
    "pop_RUR.TOTL.ZS": "rural_pct_wb",
    "pop_URB.TOTL.IN.ZS": "urban_pct",
    "agriculture_LND.AGRI.ZS": "agri_land_pct",
    "agriculture_LND.ARBL.ZS": "arable_land_pct",
    "agriculture_PRD.CROP.XD": "crop_prod_index",
    "pop_DYN.LE00.IN": "life_expectancy",
    "pop_DYN.IMRT.IN": "infant_mortality",
    "pop_POP.GROW": "pop_growth",
    "inflation_CPI.TOTL.ZG": "inflation",
}


def load_readiness_component(fname: str, col: str) -> pd.DataFrame:
    df = pd.read_csv(READ_DIR / fname, low_memory=False)
    out = df[["ISO3", "2022"]].rename(columns={"ISO3": "iso3", "2022": col})
    out[col] = pd.to_numeric(out[col], errors="coerce")
    return out


def main() -> int:
    wb, backbone = load_world_bank_backbone()
    cs = cross_section_2022(wb, backbone)
    names = pd.read_csv(CV_VULN, low_memory=False)[["ISO3", "Name"]].rename(
        columns={"ISO3": "iso3", "Name": "country"})
    cs = cs.merge(names, on="iso3", how="left")

    # Buffer from Model 1
    d = cs.dropna(subset=["undernourishment", "vulnerability"]).copy()
    f1 = OLS(d["undernourishment"], sm.add_constant(d["vulnerability"])).fit(cov_type="HC1")
    d["buffer"] = f1.fittedvalues - d["undernourishment"]

    # Readiness components
    for fname, col in [("economic.csv", "read_economic"),
                       ("governance.csv", "read_governance"),
                       ("social.csv", "read_social")]:
        d = d.merge(load_readiness_component(fname, col), on="iso3", how="left")

    # World Bank extras: latest available value <= 2022 per country
    wb22 = wb_latest(wb, WB_VARS)
    d = d.merge(wb22, on="iso3", how="left")
    # Backfill ln GDP / rural where strict-2022 merge was missing
    fill = wb_latest(wb, {"gdp_GDP.PCAP.CD": "gdp_fill", "pop_RUR.TOTL.ZS": "rural_fill"})
    d = d.merge(fill, on="iso3", how="left")
    d["ln_gdp_pcap"] = d["ln_gdp_pcap"].fillna(np.log(d["gdp_fill"].clip(lower=1)))
    d["rural_pct"] = d["rural_pct"].fillna(d["rural_fill"])

    features = (["readiness", "read_economic", "read_governance", "read_social",
                 "ln_gdp_pcap", "rural_pct", "disaster_count", "ln1_fatalities"]
                + [c for c in WB_VARS.values() if c != "rural_pct_wb"])
    # drop features with >25% missing
    keep = [f for f in features if d[f].isna().mean() <= 0.25]
    dropped = sorted(set(features) - set(keep))
    if dropped:
        print(f"Dropped (>25% missing): {dropped}")

    d = d.dropna(subset=["buffer"]).reset_index(drop=True)
    X, y = d[keep], d["buffer"]
    print(f"N = {len(d)}; p = {len(keep)} predictors: {keep}\n")

    X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=SEED)
    cv = KFold(n_splits=5, shuffle=True, random_state=SEED)
    alphas = np.logspace(-3, 3, 100)

    models = {
        "OLS": LinearRegression(),
        "Ridge": RidgeCV(alphas=alphas, cv=cv),
        "Lasso": LassoCV(alphas=alphas, cv=cv, random_state=SEED, max_iter=50_000),
        "ElasticNet": ElasticNetCV(alphas=alphas, l1_ratio=[0.1, 0.5, 0.7, 0.9],
                                   cv=cv, random_state=SEED, max_iter=50_000),
    }

    rows, coef_rows = [], []
    for name, est in models.items():
        pipe = Pipeline([("impute", SimpleImputer(strategy="median")),
                         ("scale", StandardScaler()),
                         ("model", est)])
        pipe.fit(X_tr, y_tr)
        pred_te = pipe.predict(X_te)
        pred_tr = pipe.predict(X_tr)
        m = pipe.named_steps["model"]
        alpha = getattr(m, "alpha_", np.nan)
        rows.append({
            "model": name,
            "alpha": alpha,
            "l1_ratio": getattr(m, "l1_ratio_", np.nan),
            "train_rmse": np.sqrt(mean_squared_error(y_tr, pred_tr)),
            "test_rmse": np.sqrt(mean_squared_error(y_te, pred_te)),
            "test_mae": mean_absolute_error(y_te, pred_te),
            "nonzero_coefs": int((np.abs(m.coef_) > 1e-8).sum()),
        })
        for f, c in zip(keep, m.coef_):
            coef_rows.append({"model": name, "feature": f, "coef_std": c})

    res = pd.DataFrame(rows)
    base_rmse = float(np.sqrt(mean_squared_error(y_te, np.full(len(y_te), y_tr.mean()))))
    print(f"Naive baseline (predict train mean): test RMSE = {base_rmse:.3f}\n")
    print("=== MODEL COMPARISON ===")
    print(res.round(3).to_string(index=False))

    coefs = pd.DataFrame(coef_rows)
    lasso = coefs[coefs.model == "Lasso"].copy()
    lasso = lasso[lasso.coef_std.abs() > 1e-8].sort_values("coef_std", key=abs, ascending=False)
    print("\n=== LASSO SURVIVORS (standardized coefficients) ===")
    print(lasso[["feature", "coef_std"]].round(3).to_string(index=False))

    enet = coefs[coefs.model == "ElasticNet"].copy()
    enet = enet.sort_values("coef_std", key=abs, ascending=False).head(8)
    print("\n=== ELASTIC NET TOP COEFFICIENTS (standardized) ===")
    print(enet[["feature", "coef_std"]].round(3).to_string(index=False))

    # Repeated CV so the conclusion does not hinge on one split
    from sklearn.model_selection import RepeatedKFold, cross_val_score
    rkf = RepeatedKFold(n_splits=5, n_repeats=20, random_state=SEED)
    print("\n=== REPEATED 5-FOLD CV (20 repeats), RMSE mean +/- sd ===")
    cv_rows = []
    for name, est in [("OLS", LinearRegression()),
                      ("Ridge", RidgeCV(alphas=alphas)),
                      ("ElasticNet", ElasticNetCV(alphas=alphas, l1_ratio=[0.1, 0.5, 0.9],
                                                  random_state=SEED, max_iter=50_000))]:
        pipe = Pipeline([("impute", SimpleImputer(strategy="median")),
                         ("scale", StandardScaler()),
                         ("model", est)])
        sc = -cross_val_score(pipe, X, y, cv=rkf, scoring="neg_root_mean_squared_error")
        print(f"{name:12s}: {sc.mean():.3f} +/- {sc.std():.3f}")
        cv_rows.append({"model": name, "cv_rmse_mean": sc.mean(), "cv_rmse_sd": sc.std()})
    from sklearn.dummy import DummyRegressor
    pipe0 = Pipeline([("impute", SimpleImputer(strategy="median")),
                      ("model", DummyRegressor(strategy="mean"))])
    sc0 = -cross_val_score(pipe0, X, y, cv=rkf, scoring="neg_root_mean_squared_error")
    print(f"{'Mean only':12s}: {sc0.mean():.3f} +/- {sc0.std():.3f}")
    cv_rows.append({"model": "MeanBaseline", "cv_rmse_mean": sc0.mean(), "cv_rmse_sd": sc0.std()})
    pd.DataFrame(cv_rows).round(4).to_csv(PAPER / "output" / "global_model7_repeated_cv.csv", index=False)

    res.round(4).to_csv(PAPER / "output" / "global_model7_results.csv", index=False)
    coefs.round(4).to_csv(PAPER / "output" / "global_model7_coefs.csv", index=False)
    print("\nWritten: output/global_model7_results.csv, global_model7_coefs.csv")
    return 0


if __name__ == "__main__":
    sys.exit(main())
