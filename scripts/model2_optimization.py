"""
Model 2: Diminishing Returns + Synergy Policy Optimization
──────────────────────────────────────────────────────────
13 policies · concave power functions · 7 synergy pairs
BDP2100 discount · BNP-priority floor · min investment
10-year timeline multipliers · FDI sensitivity
"""

# ── Constants ──
UNDERNOURISHED = 18_050_486
DAILY_DEFICIT_KCAL = 700
FOOD_COST = 285  # $/person/year — WFP Bangladesh Market Monitor (BDT 2,844/month, Apr 2024)

BNP_QUOTA = 0.35
MIN_INVEST = 200   # $M minimum if policy is funded
INCREMENT = 1      # $M allocation granularity
BDP2100_DISCOUNT = 0.60

# ── 10-Year Timeline Multipliers ──
# A 1-year snapshot under-counts preventive/infrastructure policies
# whose benefits accumulate over time. These multipliers adjust
# annualized impact to reflect a 10-year evaluation horizon.
#   direct:  immediate nutrition → no adjustment (1.00)
#   prod:    agricultural production ramps up over 2-3 years (1.15)
#   protect: prevents cumulative losses across ~3 shock cycles (1.40)
#   infra:   takes years to mature but compounds over a decade (1.50)
TIME_MULT = {"direct": 1.00, "prod": 1.15, "protect": 1.40, "infra": 1.50}

# ── 13 Policies ──
# base = people-equivalent fed per $1M at first unit of spending (year-1 rate)
# mx   = maximum deployable budget ($M)
# b    = diminishing returns exponent (0 < b < 1; lower = steeper drop-off)
# bnp  = BNP-manifesto-linked
# bdp  = BDP2100-linked (gets 40% impact discount)
# ptype = direct / prod / protect / infra (determines time multiplier)
POLICIES = {
    "Tree planting":           {"base": 412,   "mx": 900,  "b": 0.50, "bnp": True,  "bdp": False, "ptype": "infra"},
    "River/canal excavation":  {"base": 364,   "mx": 800,  "b": 0.60, "bnp": True,  "bdp": False, "ptype": "infra"},
    "Renewable irrigation":    {"base": 2944,  "mx": 1200, "b": 0.75, "bnp": True,  "bdp": False, "ptype": "infra"},
    "Farmer insurance":        {"base": 2500,  "mx": 1000, "b": 0.50, "bnp": True,  "bdp": False, "ptype": "protect"},
    "Cyclone early warning":   {"base": 80,    "mx": 500,  "b": 0.85, "bnp": True,  "bdp": False, "ptype": "protect"},
    "Flood forecasting":       {"base": 21,    "mx": 700,  "b": 0.85, "bnp": True,  "bdp": True,  "ptype": "protect"},
    "Crop diversification":    {"base": 2748,  "mx": 1000, "b": 0.65, "bnp": False, "bdp": False, "ptype": "prod"},
    "Post-harvest storage":    {"base": 9698,  "mx": 1200, "b": 0.70, "bnp": False, "bdp": False, "ptype": "prod"},
    "Aquaculture":             {"base": 180,   "mx": 600,  "b": 0.75, "bnp": False, "bdp": False, "ptype": "prod"},
    "Fortified feeding":       {"base": 22831, "mx": 1800, "b": 0.80, "bnp": False, "bdp": False, "ptype": "direct"},
    "Flood-tolerant rice":     {"base": 7419,  "mx": 1800, "b": 0.70, "bnp": False, "bdp": True,  "ptype": "prod"},
    "AWD irrigation":          {"base": 15079, "mx": 1000, "b": 0.70, "bnp": True,  "bdp": True,  "ptype": "prod"},
    "Saline-tolerant rice":    {"base": 9892,  "mx": 1500, "b": 0.80, "bnp": False, "bdp": True,  "ptype": "prod"},
}

# ── 7 Synergy pairs ──
SYNERGIES = [
    ("Cyclone early warning", "Flood forecasting",      0.35),
    ("Flood-tolerant rice",   "AWD irrigation",          0.20),
    ("Post-harvest storage",  "Crop diversification",    0.25),
    ("Saline-tolerant rice",  "AWD irrigation",          0.20),
    ("Farmer insurance",      "Flood-tolerant rice",     0.15),
    ("Tree planting",         "River/canal excavation",  0.10),
    ("Aquaculture",           "Crop diversification",    0.15),
]

SCENARIOS = {
    "Current FDI ($8.0B)": 8000,
    "BNP Target FDI ($8.6B)": 8600,
}


# ── Impact functions ──
# Correct concave power function:
#   I(x) = (base / b) * x^b
# so that: dI/dx at x=1 = base  (marginal impact at first $1M = base)
# and marginal declines as x^(b-1) with increasing spend.

def cum_impact(name, spend):
    """Total people-equivalent from spending $spend M (10-year adjusted)."""
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
    """Marginal people per additional $1M at current spend (10-year adjusted)."""
    p = POLICIES[name]
    if spend >= p["mx"]:
        return 0.0
    x = max(spend, 0.5)
    raw = p["base"] * (x ** (p["b"] - 1))
    raw *= TIME_MULT[p["ptype"]]
    if p["bdp"]:
        raw *= BDP2100_DISCOUNT
    return max(raw, 0)


def synergy_bonus(alloc):
    """Total synergy bonus across all pairs."""
    s = 0.0
    for (a, b, alpha) in SYNERGIES:
        sa, sb = alloc.get(a, 0), alloc.get(b, 0)
        if sa <= 0 or sb <= 0:
            continue
        frac_a = sa / POLICIES[a]["mx"]
        frac_b = sb / POLICIES[b]["mx"]
        joint = (frac_a * frac_b) ** 0.5
        s += alpha * joint * (cum_impact(a, sa) + cum_impact(b, sb))
    return s


def people_total(alloc):
    base = sum(cum_impact(k, v) for k, v in alloc.items() if v > 0)
    return base + synergy_bonus(alloc)


# ── Optimizer: greedy marginal equalization ──
def optimize(budget):
    alloc = {k: 0.0 for k in POLICIES}
    sel = set()
    spent = 0.0
    bnp_target = budget * BNP_QUOTA

    def bnp_spent():
        return sum(alloc[k] for k in POLICIES if POLICIES[k]["bnp"])

    def pick_best(cands):
        best_k, best_m = None, -1
        for k in cands:
            m = marginal(k, alloc[k])
            if m > best_m:
                best_m = m
                best_k = k
        return best_k, best_m

    # Phase 1: satisfy BNP quota
    while bnp_spent() < bnp_target - 1 and spent < budget - 1:
        cands = [k for k in POLICIES
                 if POLICIES[k]["bnp"] and alloc[k] < POLICIES[k]["mx"]]
        if not cands:
            break
        best_k, best_m = pick_best(cands)
        if best_k is None or best_m <= 0:
            break
        if best_k not in sel:
            add = min(MIN_INVEST, POLICIES[best_k]["mx"] - alloc[best_k],
                      budget - spent)
        else:
            add = min(INCREMENT, POLICIES[best_k]["mx"] - alloc[best_k],
                      budget - spent)
        if add <= 0:
            break
        alloc[best_k] += add
        spent += add
        sel.add(best_k)

    # Phase 2: optimize remaining budget
    while spent < budget - 1:
        cands = [k for k in POLICIES if alloc[k] < POLICIES[k]["mx"]]
        if not cands:
            break
        best_k, best_m = pick_best(cands)
        if best_k is None or best_m <= 0:
            break
        if best_k not in sel:
            add = min(MIN_INVEST, POLICIES[best_k]["mx"] - alloc[best_k],
                      budget - spent)
        else:
            add = min(INCREMENT, POLICIES[best_k]["mx"] - alloc[best_k],
                      budget - spent)
        if add <= 0:
            break
        alloc[best_k] += add
        spent += add
        sel.add(best_k)

    return alloc, spent


# ── Reporting ──
def report(label, budget, alloc, spent):
    base = sum(cum_impact(k, v) for k, v in alloc.items() if v > 0)
    syn = synergy_bonus(alloc)
    total = base + syn
    bnp_s = sum(alloc[k] for k in POLICIES if POLICIES[k]["bnp"])
    funded = [k for k, v in alloc.items() if v > 0]
    capped = min(total, UNDERNOURISHED)
    surplus = max(total - UNDERNOURISHED, 0)
    deficit_pct = min(total / UNDERNOURISHED * 100, 100)
    buf_pct = surplus / UNDERNOURISHED * 100 if surplus > 0 else 0

    print(f"\n{'='*72}")
    print(f"  {label}")
    print(f"{'='*72}")

    # allocation table
    print(f"\n  {'Policy':<28} {'$M':>7} {'People-Equiv':>14} {'Marginal@Max':>13}  Tags")
    print(f"  {'-'*75}")
    for k in sorted(funded, key=lambda k: alloc[k], reverse=True):
        v = alloc[k]
        imp = cum_impact(k, v)
        m_end = marginal(k, v)
        tags = ""
        if POLICIES[k]["bnp"]: tags += " [BNP]"
        if POLICIES[k]["bdp"]: tags += " [BDP]"
        print(f"  {k:<28} {v:>7,.0f} {imp:>14,.0f} {m_end:>13,.0f} {tags}")

    print(f"  {'-'*75}")
    print(f"  {'Base subtotal':<28} {spent:>7,.0f} {base:>14,.0f}")
    print(f"  {'Synergy bonus':<28} {'':>7} {syn:>14,.0f}")
    print(f"  {'TOTAL':<28} {spent:>7,.0f} {total:>14,.0f}")

    # synergy detail
    print(f"\n  Synergy breakdown:")
    for (a, b, alpha) in SYNERGIES:
        sa, sb = alloc.get(a, 0), alloc.get(b, 0)
        if sa > 0 and sb > 0:
            frac_a = sa / POLICIES[a]["mx"]
            frac_b = sb / POLICIES[b]["mx"]
            joint = (frac_a * frac_b) ** 0.5
            bonus = alpha * joint * (cum_impact(a, sa) + cum_impact(b, sb))
            print(f"    {a} x {b}: a={alpha}, +{bonus:,.0f} people")
        else:
            status = "neither funded" if alloc.get(a,0)==0 and alloc.get(b,0)==0 else "one unfunded"
            print(f"    {a} x {b}: NOT TRIGGERED ({status})")

    # summary
    print(f"\n  Summary:")
    print(f"    Budget:                  ${budget:,}M")
    print(f"    Spent:                   ${spent:,.0f}M")
    print(f"    BNP share:               {bnp_s/spent*100:.1f}% (floor: {BNP_QUOTA*100:.0f}%)")
    print(f"    Policies funded:         {len(funded)} of 13")
    print(f"    Raw people-equiv:        {total:,.0f}")
    print(f"    Undernourished target:   {UNDERNOURISHED:,}")
    print(f"    Deficit closed:          {deficit_pct:.1f}%")
    if surplus > 0:
        print(f"    Resilience buffer:       {surplus:,.0f} ({buf_pct:.0f}%)")
    print(f"    Dollar value ($285/yr):  ${capped * FOOD_COST / 1e6:,.0f}M")

    return {"label": label, "budget": budget, "spent": spent,
            "base": base, "syn": syn, "total": total,
            "funded": len(funded), "bnp_pct": bnp_s/spent*100,
            "deficit_pct": deficit_pct, "surplus": surplus,
            "capped": capped, "alloc": {k:v for k,v in alloc.items() if v>0}}


# ── Main ──
print("MODEL 2: DIMINISHING RETURNS + SYNERGY OPTIMIZATION")
print("=" * 72)
print(f"  Undernourished target:  {UNDERNOURISHED:,}")
print(f"  Daily kcal deficit:     {DAILY_DEFICIT_KCAL}")
print(f"  BNP funding floor:      {BNP_QUOTA*100:.0f}%")
print(f"  Min investment:         ${MIN_INVEST}M")
print(f"  BDP2100 discount:       {(1-BDP2100_DISCOUNT)*100:.0f}%")
print(f"  Timeline multipliers:   direct={TIME_MULT['direct']}, prod={TIME_MULT['prod']}, protect={TIME_MULT['protect']}, infra={TIME_MULT['infra']}")
print(f"  Synergy pairs:          {len(SYNERGIES)}")
print(f"  Allocation granularity: ${INCREMENT}M")

# verify individual policy max impacts
print(f"\n  Max impact at full scale (no synergy, with time multiplier):")
print(f"  {'Policy':<28} {'Max $M':>7} {'Max People':>12} {'b':>5} {'Type':>8} {'TM':>5}")
print(f"  {'-'*70}")
for k in sorted(POLICIES.keys(), key=lambda k: cum_impact(k, POLICIES[k]["mx"]), reverse=True):
    p = POLICIES[k]
    imp = cum_impact(k, p["mx"])
    tm = TIME_MULT[p["ptype"]]
    print(f"  {k:<28} {p['mx']:>7,} {imp:>12,.0f} {p['b']:>5.2f} {p['ptype']:>8} {tm:>5.2f}")

results = {}
for label, budget in SCENARIOS.items():
    alloc, spent = optimize(budget)
    results[label] = report(label, budget, alloc, spent)

# comparison
print(f"\n{'='*72}")
print("  SCENARIO COMPARISON")
print(f"{'='*72}")
labels = list(SCENARIOS.keys())
r1, r2 = results[labels[0]], results[labels[1]]
print(f"  {'Metric':<30} {labels[0]:>18} {labels[1]:>18}")
print(f"  {'-'*68}")
for m in ["budget", "spent", "funded", "base", "syn", "total",
          "deficit_pct", "surplus", "capped"]:
    v1, v2 = r1[m], r2[m]
    if m == "deficit_pct":
        print(f"  {m:<30} {v1:>17.1f}% {v2:>17.1f}%")
    elif m == "bnp_pct":
        print(f"  {m:<30} {v1:>17.1f}% {v2:>17.1f}%")
    else:
        print(f"  {m:<30} {v1:>18,.0f} {v2:>18,.0f}")

# delta
delta_people = r2["total"] - r1["total"]
delta_budget = r2["budget"] - r1["budget"]
print(f"\n  FDI uplift effect:")
print(f"    Additional budget:       +${delta_budget:,}M")
print(f"    Additional people-equiv: +{delta_people:,.0f}")
print(f"    Marginal efficiency:     {delta_people/delta_budget:,.0f} people/$M")
