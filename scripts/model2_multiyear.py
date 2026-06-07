"""
Model 2: Multi-Year Simulation
═══════════════════════════════
$8B/year for 5 years (BNP first term) → measure impact over 20 years.

Two policy types:
  CAPITAL:      One-time investment, benefits persist with decay after funding stops.
                Diminishing returns on CUMULATIVE spend across all years.
  OPERATIONAL:  Must be funded each year. Benefits only while funded.
                Diminishing returns on ANNUAL spend.
"""

UNDERNOURISHED = 18_050_486
BNP_QUOTA = 0.35
MIN_INVEST = 200
INCREMENT = 1
BDP2100_DISCOUNT = 0.60

INVEST_YEARS = 5
MEASURE_YEARS = 20
ANNUAL_BUDGET = 8000  # $M

# capital: one-time build, impact persists with decay
# operational: must fund each year, impact only while funded
POLICIES = {
    "Tree planting":          {"base": 412,   "mx": 900,  "b": 0.50, "bnp": True,  "bdp": False, "ptype": "infra",   "funding": "capital",     "decay": 0.02},
    "River/canal excavation": {"base": 364,   "mx": 800,  "b": 0.60, "bnp": True,  "bdp": False, "ptype": "infra",   "funding": "capital",     "decay": 0.05},
    "Renewable irrigation":   {"base": 2944,  "mx": 1200, "b": 0.75, "bnp": True,  "bdp": False, "ptype": "infra",   "funding": "capital",     "decay": 0.03},
    "Farmer insurance":       {"base": 2500,  "mx": 1000, "b": 0.50, "bnp": True,  "bdp": False, "ptype": "protect", "funding": "operational", "decay": 1.00},
    "Cyclone early warning":  {"base": 80,    "mx": 500,  "b": 0.85, "bnp": True,  "bdp": False, "ptype": "protect", "funding": "capital",     "decay": 0.03},
    "Flood forecasting":      {"base": 21,    "mx": 700,  "b": 0.85, "bnp": True,  "bdp": True,  "ptype": "protect", "funding": "capital",     "decay": 0.05},
    "Crop diversification":   {"base": 2748,  "mx": 1000, "b": 0.65, "bnp": False, "bdp": False, "ptype": "prod",    "funding": "capital",     "decay": 0.08},
    "Post-harvest storage":   {"base": 9698,  "mx": 1200, "b": 0.70, "bnp": False, "bdp": False, "ptype": "prod",    "funding": "capital",     "decay": 0.03},
    "Aquaculture":            {"base": 180,   "mx": 600,  "b": 0.75, "bnp": False, "bdp": False, "ptype": "prod",    "funding": "capital",     "decay": 0.05},
    "Fortified feeding":      {"base": 22831, "mx": 1800, "b": 0.80, "bnp": False, "bdp": False, "ptype": "direct",  "funding": "operational", "decay": 1.00},
    "Flood-tolerant rice":    {"base": 7419,  "mx": 1800, "b": 0.70, "bnp": False, "bdp": True,  "ptype": "prod",    "funding": "capital",     "decay": 0.05},
    "AWD irrigation":         {"base": 15079, "mx": 1000, "b": 0.70, "bnp": True,  "bdp": True,  "ptype": "prod",    "funding": "capital",     "decay": 0.05},
    "Saline-tolerant rice":   {"base": 9892,  "mx": 1500, "b": 0.80, "bnp": False, "bdp": True,  "ptype": "prod",    "funding": "capital",     "decay": 0.05},
}

TIME_MULT = {"direct": 1.00, "prod": 1.15, "protect": 1.40, "infra": 1.50}

SYNERGIES = [
    ("Cyclone early warning", "Flood forecasting",      0.35),
    ("Flood-tolerant rice",   "AWD irrigation",          0.20),
    ("Post-harvest storage",  "Crop diversification",    0.25),
    ("Saline-tolerant rice",  "AWD irrigation",          0.20),
    ("Farmer insurance",      "Flood-tolerant rice",     0.15),
    ("Tree planting",         "River/canal excavation",  0.10),
    ("Aquaculture",           "Crop diversification",    0.15),
]


def cum_impact(name, spend):
    """People-equivalent from spending $spend M on policy (annualized)."""
    p = POLICIES[name]
    if spend <= 0:
        return 0.0
    x = min(spend, p["mx"])
    raw = (p["base"] / p["b"]) * (x ** p["b"])
    raw *= TIME_MULT[p["ptype"]]
    if p["bdp"]:
        raw *= BDP2100_DISCOUNT
    return raw


def marginal(name, spend):
    p = POLICIES[name]
    if spend >= p["mx"]:
        return 0.0
    x = max(spend, 0.5)
    raw = p["base"] * (x ** (p["b"] - 1))
    raw *= TIME_MULT[p["ptype"]]
    if p["bdp"]:
        raw *= BDP2100_DISCOUNT
    return max(raw, 0)


def synergy_bonus(active_levels):
    """Synergy based on current active impact levels."""
    s = 0.0
    for (a, b, alpha) in SYNERGIES:
        la = active_levels.get(a, 0)
        lb = active_levels.get(b, 0)
        if la <= 0 or lb <= 0:
            continue
        max_a = cum_impact(a, POLICIES[a]["mx"])
        max_b = cum_impact(b, POLICIES[b]["mx"])
        if max_a <= 0 or max_b <= 0:
            continue
        frac_a = la / max_a
        frac_b = lb / max_b
        joint = (frac_a * frac_b) ** 0.5
        s += alpha * joint * (la + lb)
    return s


def optimize_year(budget, cum_capital, operational_budget_only=False):
    """
    Allocate one year's budget.
    cum_capital: dict of cumulative capital investment so far (from prior years).
    Returns: year_alloc (what was allocated this year), new cum_capital
    """
    year_alloc = {k: 0.0 for k in POLICIES}
    sel = set()
    spent = 0.0
    bnp_target = budget * BNP_QUOTA

    def bnp_spent():
        return sum(year_alloc[k] for k in POLICIES if POLICIES[k]["bnp"])

    def effective_spend(k):
        """Current effective spend level for marginal calculation."""
        p = POLICIES[k]
        if p["funding"] == "capital":
            return cum_capital.get(k, 0) + year_alloc[k]
        else:
            return year_alloc[k]

    def remaining_capacity(k):
        p = POLICIES[k]
        if p["funding"] == "capital":
            return max(p["mx"] - cum_capital.get(k, 0) - year_alloc[k], 0)
        else:
            return max(p["mx"] - year_alloc[k], 0)

    def pick_best(cands):
        best_k, best_m = None, -1
        for k in cands:
            if remaining_capacity(k) <= 0:
                continue
            m = marginal(k, effective_spend(k))
            if m > best_m:
                best_m = m
                best_k = k
        return best_k, best_m

    # Phase 1: BNP quota
    while bnp_spent() < bnp_target - 1 and spent < budget - 1:
        cands = [k for k in POLICIES
                 if POLICIES[k]["bnp"] and remaining_capacity(k) > 0]
        if not cands:
            break
        best_k, best_m = pick_best(cands)
        if best_k is None or best_m <= 0:
            break
        if best_k not in sel:
            add = min(MIN_INVEST, remaining_capacity(best_k), budget - spent)
        else:
            add = min(INCREMENT, remaining_capacity(best_k), budget - spent)
        if add <= 0:
            break
        year_alloc[best_k] += add
        spent += add
        sel.add(best_k)

    # Phase 2: optimize rest
    while spent < budget - 1:
        cands = [k for k in POLICIES if remaining_capacity(k) > 0]
        if not cands:
            break
        best_k, best_m = pick_best(cands)
        if best_k is None or best_m <= 0:
            break
        if best_k not in sel:
            add = min(MIN_INVEST, remaining_capacity(best_k), budget - spent)
        else:
            add = min(INCREMENT, remaining_capacity(best_k), budget - spent)
        if add <= 0:
            break
        year_alloc[best_k] += add
        spent += add
        sel.add(best_k)

    new_cum = dict(cum_capital)
    for k in POLICIES:
        if POLICIES[k]["funding"] == "capital":
            new_cum[k] = new_cum.get(k, 0) + year_alloc[k]

    return year_alloc, spent, new_cum


# ══════════════════════════════════════════════════════
# RUN SIMULATION
# ══════════════════════════════════════════════════════
print("=" * 75)
print("  MODEL 2: MULTI-YEAR SIMULATION")
print(f"  Investment: ${ANNUAL_BUDGET/1000:.0f}B/year × {INVEST_YEARS} years = ${ANNUAL_BUDGET * INVEST_YEARS / 1000:.0f}B total")
print(f"  Measurement: {MEASURE_YEARS} years")
print("=" * 75)

cum_capital = {k: 0.0 for k in POLICIES}
yearly_operational = {}
yearly_alloc = {}
yearly_spent = {}

# Phase A: Investment years (1-5)
print(f"\n{'─'*75}")
print("INVESTMENT PHASE (Years 1–{})".format(INVEST_YEARS))
print(f"{'─'*75}")

for yr in range(1, INVEST_YEARS + 1):
    alloc, spent, cum_capital = optimize_year(ANNUAL_BUDGET, cum_capital)
    yearly_alloc[yr] = alloc
    yearly_spent[yr] = spent
    yearly_operational[yr] = {k: v for k, v in alloc.items()
                              if POLICIES[k]["funding"] == "operational" and v > 0}

    print(f"\n  Year {yr} allocation (${spent:,.0f}M spent):")
    for k in sorted(alloc.keys(), key=lambda k: alloc[k], reverse=True):
        if alloc[k] <= 0:
            continue
        p = POLICIES[k]
        tag = f"[{p['funding'][:3].upper()}]"
        cum_str = ""
        if p["funding"] == "capital":
            cum_str = f" (cumulative: ${cum_capital[k]:,.0f}M)"
        print(f"    {k:<28} ${alloc[k]:>7,.0f}M {tag}{cum_str}")

# Summary of cumulative capital investment
print(f"\n{'─'*75}")
print("CUMULATIVE CAPITAL INVESTMENT AFTER 5 YEARS")
print(f"{'─'*75}")
total_capital = 0
for k in sorted(cum_capital.keys(), key=lambda k: cum_capital.get(k, 0), reverse=True):
    v = cum_capital.get(k, 0)
    if v <= 0:
        continue
    p = POLICIES[k]
    pct = v / p["mx"] * 100
    total_capital += v
    print(f"  {k:<28} ${v:>8,.0f}M  ({pct:>5.1f}% of max ${p['mx']:,}M)")
total_operational = sum(yearly_spent[yr] for yr in range(1, INVEST_YEARS + 1)) - total_capital
print(f"\n  Total capital invested:      ${total_capital:,.0f}M")
print(f"  Total operational spent:     ${total_operational:,.0f}M")
print(f"  Grand total (5 years):       ${total_capital + total_operational:,.0f}M")

# Phase B: Calculate impact for all 20 years
print(f"\n{'─'*75}")
print("20-YEAR IMPACT SIMULATION")
print(f"{'─'*75}")

print(f"\n  {'Year':>4} {'Capital':>12} {'Operational':>12} {'Synergy':>10} {'Total':>12} {'Capped':>12} {'Deficit%':>9}")
print(f"  {'─'*75}")

total_person_years = 0
total_capped_person_years = 0
yearly_impact = {}

for yr in range(1, MEASURE_YEARS + 1):
    active_levels = {}
    cap_total = 0
    op_total = 0

    for k, p in POLICIES.items():
        if p["funding"] == "capital":
            invested = cum_capital.get(k, 0)
            if yr <= INVEST_YEARS:
                # during investment: use cumulative up to this year
                inv_so_far = sum(yearly_alloc[y].get(k, 0) for y in range(1, yr + 1))
                base_imp = cum_impact(k, inv_so_far)
            else:
                # after investment: full cumulative, but decaying
                years_since = yr - INVEST_YEARS
                base_imp = cum_impact(k, invested) * ((1 - p["decay"]) ** years_since)
            active_levels[k] = base_imp
            cap_total += base_imp

        else:  # operational
            if yr <= INVEST_YEARS:
                op_spend = yearly_alloc[yr].get(k, 0)
                base_imp = cum_impact(k, op_spend)
                active_levels[k] = base_imp
                op_total += base_imp
            else:
                active_levels[k] = 0

    syn = synergy_bonus(active_levels)
    total = cap_total + op_total + syn
    capped = min(total, UNDERNOURISHED)

    yearly_impact[yr] = {
        "capital": cap_total, "operational": op_total, "synergy": syn,
        "total": total, "capped": capped
    }
    total_person_years += total
    total_capped_person_years += capped

    deficit_pct = min(total / UNDERNOURISHED * 100, 100)
    marker = " ◄ funding stops" if yr == INVEST_YEARS else ""
    print(f"  {yr:>4} {cap_total:>12,.0f} {op_total:>12,.0f} {syn:>10,.0f} {total:>12,.0f} {capped:>12,.0f} {deficit_pct:>8.1f}%{marker}")

# Summary
print(f"\n{'═'*75}")
print("  20-YEAR SUMMARY")
print(f"{'═'*75}")

avg_annual = total_person_years / MEASURE_YEARS
total_invested = sum(yearly_spent[yr] for yr in range(1, INVEST_YEARS + 1))

# years where deficit is fully closed
full_closure_years = sum(1 for yr in range(1, MEASURE_YEARS + 1)
                         if yearly_impact[yr]["total"] >= UNDERNOURISHED)

# year when impact drops below UNDERNOURISHED after investment stops
drop_below_year = None
for yr in range(INVEST_YEARS + 1, MEASURE_YEARS + 1):
    if yearly_impact[yr]["total"] < UNDERNOURISHED:
        drop_below_year = yr
        break

# impact in year 20
yr20 = yearly_impact[MEASURE_YEARS]
yr20_pct = min(yr20["total"] / UNDERNOURISHED * 100, 100)

# total person-years during investment vs after
invest_py = sum(yearly_impact[yr]["capped"] for yr in range(1, INVEST_YEARS + 1))
post_py = sum(yearly_impact[yr]["capped"] for yr in range(INVEST_YEARS + 1, MEASURE_YEARS + 1))

print(f"\n  Total invested (5 years):           ${total_invested:,.0f}M")
print(f"  Total person-years of food security: {total_person_years:,.0f}")
print(f"  Capped person-years (max 18.05M/yr): {total_capped_person_years:,.0f}")
print(f"  Average annual impact:               {avg_annual:,.0f} people")
print(f"  Full deficit closure years:          {full_closure_years} of {MEASURE_YEARS}")
if drop_below_year:
    print(f"  Impact drops below deficit in year:  {drop_below_year} (year {drop_below_year - INVEST_YEARS} after funding stops)")
else:
    print(f"  Impact stays above deficit:           All 20 years")
print(f"  Year 20 impact:                      {yr20['total']:,.0f} ({yr20_pct:.1f}% of deficit)")
print(f"  Year 20 breakdown:                   capital={yr20['capital']:,.0f}, synergy={yr20['synergy']:,.0f}")
print(f"\n  Person-years during investment (1–5):  {invest_py:,.0f}")
print(f"  Person-years after investment (6–20):  {post_py:,.0f}")
print(f"  Ratio (post/during):                   {post_py/invest_py:.1f}x")
print(f"  Cost per person-year (total):          ${total_invested * 1e6 / total_capped_person_years:.2f}")

# What the model recommends vs single-year
print(f"\n{'─'*75}")
print("  CAPITAL vs OPERATIONAL — 20-YEAR VALUE COMPARISON")
print(f"{'─'*75}")
total_cap_py = sum(yearly_impact[yr]["capital"] for yr in range(1, MEASURE_YEARS + 1))
total_op_py = sum(yearly_impact[yr]["operational"] for yr in range(1, MEASURE_YEARS + 1))
total_syn_py = sum(yearly_impact[yr]["synergy"] for yr in range(1, MEASURE_YEARS + 1))
total_cap_invested = total_capital
total_op_invested = total_operational

print(f"\n  {'':>30} {'Capital':>15} {'Operational':>15}")
print(f"  {'─'*62}")
print(f"  {'Total invested':>30} ${total_cap_invested:>13,.0f}M ${total_op_invested:>13,.0f}M")
print(f"  {'Total person-years':>30} {total_cap_py:>15,.0f} {total_op_py:>15,.0f}")
print(f"  {'Person-years per $M':>30} {total_cap_py/max(total_cap_invested,1):>15,.0f} {total_op_py/max(total_op_invested,1):>15,.0f}")
print(f"  {'Synergy person-years':>30} {total_syn_py:>15,.0f}")
print(f"  {'% of total impact':>30} {total_cap_py/total_person_years*100:>14.1f}% {total_op_py/total_person_years*100:>14.1f}%")

# Per-policy 20-year value
print(f"\n{'─'*75}")
print("  PER-POLICY 20-YEAR IMPACT")
print(f"{'─'*75}")
print(f"\n  {'Policy':<28} {'Invested':>10} {'20yr People':>14} {'Per $M':>10} {'Type':>5}")
print(f"  {'─'*70}")
policy_20yr = {}
for k in POLICIES:
    total_imp = 0
    for yr in range(1, MEASURE_YEARS + 1):
        p = POLICIES[k]
        if p["funding"] == "capital":
            invested = cum_capital.get(k, 0)
            if yr <= INVEST_YEARS:
                inv_so_far = sum(yearly_alloc[y].get(k, 0) for y in range(1, yr + 1))
                total_imp += cum_impact(k, inv_so_far)
            else:
                years_since = yr - INVEST_YEARS
                total_imp += cum_impact(k, invested) * ((1 - p["decay"]) ** years_since)
        else:
            if yr <= INVEST_YEARS:
                total_imp += cum_impact(k, yearly_alloc[yr].get(k, 0))
    policy_20yr[k] = total_imp

for k in sorted(policy_20yr.keys(), key=lambda k: policy_20yr[k], reverse=True):
    v = policy_20yr[k]
    if v <= 0:
        continue
    p = POLICIES[k]
    if p["funding"] == "capital":
        inv = cum_capital.get(k, 0)
    else:
        inv = sum(yearly_alloc[yr].get(k, 0) for yr in range(1, INVEST_YEARS + 1))
    per_m = v / inv if inv > 0 else 0
    tag = "CAP" if p["funding"] == "capital" else "OPS"
    print(f"  {k:<28} ${inv:>8,.0f}M {v:>14,.0f} {per_m:>10,.0f} {tag:>5}")
