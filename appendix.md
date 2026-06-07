Appendix — Policy Optimization Model: Full Data and Methodology


A. Model 1: Global Regression

Equation: Undernourishment (%) = −22.03 + 75.65 × Climate Vulnerability

Data: 131 countries with complete data for all 8 variables (2022 or latest available year).

Sources: ND-GAIN Country Index (University of Notre Dame); FAOSTAT Suite of Food Security Indicators (FAO); World Bank World Development Indicators; EM-DAT International Disaster Database; Our World in Data.

Key result: R² = 0.48. Climate vulnerability alone explains 48% of the variation in undernourishment rates across 131 countries. Bangladesh's predicted undernourishment is 21%, but actual is 11.9% — an adaptation buffer of 9.1 percentage points.


B. Model 2: Policy Optimization — 13 Policies Tested

B.1 Policy List with Cost-Effectiveness Data

| # | Policy | Category | Cost Basis | Impact Basis | Max Budget ($M) | b (dim. returns) | Sources |
|---|--------|----------|-----------|-------------|-----------------|-------------------|---------|
| 1 | Fortified rice & school feeding | Direct nutrition | $0.12/child/day | Anemia reduced; enrollment +4.2%, dropout −7.5% | 1,800 | 0.80 | WFP Bangladesh school feeding evaluation (2020–2024); PLOS One fortified rice study |
| 2 | Saline-tolerant rice | Production | ~$5,000/farm | +2 tons/ha in saline zones; 11.75% production increase | 1,500 | 0.80 | CGIAR salt-tolerant varieties; PLOS One BRRI dhan97/99 |
| 3 | Post-harvest storage | Production | Recovered in 1 harvest | Reduces losses from 11.38% to 0.92% (98% reduction) | 1,200 | 0.70 | ASABE hermetic bag study; BAU/ADM Institute pilot |
| 4 | AWD irrigation | Production | $67–97/ha | +500 kg/ha yield; 27% water savings | 1,000 | 0.70 | IRRI Rice Knowledge Bank; MDPI Water participatory evaluation |
| 5 | Flood-tolerant rice (Sub1) | Production | ~$5,000/farm | +1–3 tons/ha post-flood; 55% higher profit | 1,800 | 0.70 | CGIAR/IRRI flood-tolerant rice study; BRRI Sub1 field trials |
| 6 | Renewable energy for irrigation | Infrastructure | ADB $400M+ | Eliminates volatile fuel costs for pumps | 1,200 | 0.75 | ADB $400M climate priorities; ADB $400M resilient development |
| 7 | Crop diversification | Production | ~$120M/Five Year Plan | Reduces rice monoculture; 59% grow only one crop | 1,000 | 0.65 | Frontiers in Sustainable Food Systems (2024); MDPI Sustainability |
| 8 | Farmer insurance | Protection | Farmers pay 25% premium | Prevents land abandonment; 10,000 BDT payout/event | 1,000 | 0.50 | World Bank Agricultural Insurance Appraisal; Reuters; ADB pilot |
| 9 | River/canal excavation | Infrastructure | ~$1.7M/km | 20% reduction in flood duration | 800 | 0.60 | USQ cost-benefit analysis (BCR 4.35); LSU flood risk study |
| 10 | Tree planting | Infrastructure | $1.50–$10/tree | Erosion control, flood buffering, 350,000+ jobs | 900 | 0.50 | BNP manifesto (250M trees); The Daily Star |
| 11 | Aquaculture expansion | Production | ~$12,700/ha gross | Production increased 6x over 25 years; 65% adoption | 600 | 0.75 | BanglaJOL cost-benefit analysis; ScienceDirect |
| 12 | Cyclone early warning | Protection | Low — FFWC upgrade | Avoids $73–85M per major flood event | 500 | 0.85 | Springer 2024 early warning valuation |
| 13 | Flood forecasting | Protection | $270M (B-STRONG) | BCR 79–213; $2,525/household per flood | 700 | 0.85 | World Bank B-STRONG project; Springer 2024 |

B.2 Conversion to Common Unit (People Fed per $1M)

All policies were converted to a common metric:

Production policies: People fed = (tons produced × 3,600,000 kcal/ton) ÷ (2,393 kcal/day × 365 days/year)
   Example: 1 ton of rice = 3,600,000 kcal → 3,600,000 ÷ 873,445 = 4.12 people per ton per year
Direct nutrition policies: People fed = program headcount × coverage factor
Protection policies: Marginal people fed = base production × P(shock/year) × P(loss prevented) ÷ annual kcal per person

B.3 Caloric Deficit Calculation

Undernourished population: 18,050,486 (FAO, 2022)
Bangladesh extreme poverty caloric threshold: 1,805 kcal/day (BBS)
National average caloric intake: 2,393 kcal/day (BBS HIES 2022)
Estimated daily deficit per undernourished person: ~700 kcal
Total annual deficit: 18,050,486 × 700 × 365 = 4.612 trillion kcal

B.4 Diminishing Returns Model

Each policy's impact is modeled as a concave power function:

impact(x) = (a / b) × x^b

where:
   x = spending in $M
   a = marginal impact at first unit of spending (people fed per $M)
   b = diminishing returns exponent (0 < b < 1)

| b range | Policy type | Rationale |
|---------|------------|-----------|
| 0.80–0.85 | Standardized delivery (feeding, forecasting, early warning) | Milder drop-off at scale |
| 0.70–0.75 | Agricultural production (rice, AWD, storage, aquaculture, solar) | Terrain, access, behavioral constraints for later adopters |
| 0.60–0.65 | Behavioral change (crop diversification, canal excavation) | Requires cultural shift |
| 0.50 | Highest resistance (tree planting, farmer insurance) | Steepest diminishing returns |

B.5 Synergy Terms

Seven policy pairs received synergy bonuses based on documented evidence of complementarity:

Synergy formula: S(i,j) = α × √(f_i × f_j) × (Impact_i + Impact_j)

where f = deployment fraction (spend / max budget), α = synergy coefficient.

| Pair | α | Evidence |
|------|---|---------|
| Cyclone early warning × Flood forecasting | 0.35 | FFWC + Cyclone Preparedness Programme integration |
| Post-harvest storage × Crop diversification | 0.25 | FAO value chain studies — diversified crops need storage to reach markets |
| Flood-tolerant rice × AWD irrigation | 0.20 | IRRI compound adoption trials — same paddy system |
| Saline-tolerant rice × AWD irrigation | 0.20 | BRRI coastal zone trials — complementary water management |
| Farmer insurance × Flood-tolerant rice | 0.15 | World Bank — insurance removes financial adoption barrier |
| Aquaculture × Crop diversification | 0.15 | Bangladesh Dept. of Fisheries — integrated rice-fish farming |
| Tree planting × River/canal excavation | 0.10 | BDP2100 — riparian cover prevents re-siltation |

B.6 Timeline Multipliers

Single-year snapshots undervalue infrastructure. These multipliers convert year-1 impact to a 10-year-equivalent:

| Policy type | Multiplier | Rationale |
|------------|-----------|-----------|
| Direct nutrition | 1.00 | Immediate impact, only while funded |
| Production | 1.15 | Ramps up over 2–3 years, then persists |
| Protection | 1.40 | Prevents cumulative losses across ~3 shock cycles/decade |
| Infrastructure | 1.50 | Years to mature but compounds over a full decade |

B.7 Political and Budget Constraints

| Constraint | Value | Source |
|-----------|-------|--------|
| BDP 2100 annual allocation | 2.5% of GDP (~$11.9B) | The Daily Ittefaq; BDP2100 Knowledge Portal |
| BDP 2100 political risk discount | 40% reduction (→ $7.1B effective) | BNP–Awami League rivalry assessment |
| International aid (guaranteed) | ~$900M–$1.5B/year | World Bank ($858M 2023, $270M 2025); ADB ($800M); GCF |
| BNP policy floor | 35% of budget to BNP-aligned policies | Political feasibility constraint |
| Minimum investment per policy | $200M if funded | Prevents token allocations |
| Implementation efficiency discount | 20% | World Bank/IMF developing country standard |
| Working annual budget | ~$8.0B | |

B.8 Food Cost Valuation

People lifted from undernourishment are valued at $285 per person per year in direct food cost savings, based on the WFP Bangladesh Market Monitor's national food basket cost of BDT 2,844 per person per month (April 2024). The full recommended diet costs ~$340/year per FAO Cost of Recommended Diet estimates.

B.9 Himalayan Glacial Melt and Model Implications

The Ganges and Brahmaputra rivers that form Bangladesh's delta originate in Hindu Kush Himalayan glaciers. Between 1990 and 2020, these glaciers lost 12% of their total area and 9% of their ice reserves, with the rate of loss doubling since 2000 (ICIMOD, "HKH Glacier Outlook," 2026). The Ganges basin lost 21% of glacier area and the Brahmaputra lost 16% over 30 years. Currently, 65% of the Brahmaputra's and 70% of the Ganges' dry-season water supply comes from glacial melt ("Rapid Himalayan Ice Melt").

This trend affects the model in two ways:

1. Near-term flood intensification: Accelerated melt increases peak monsoon river flows. Flood levels in the Brahmaputra could surge 80% by 2075. This strengthens the case for flood-tolerant rice (Sub1), flood forecasting, and river/canal excavation. The 10-year timeline multipliers for protection and infrastructure policies (1.40 and 1.50) may be conservative given this acceleration.

2. Long-term dry-season water scarcity: As glaciers shrink past critical thresholds, dry-season irrigation water will decline. This makes AWD irrigation — which saves 27% of water — and renewable-powered irrigation pumps even more valuable over the 20-year measurement period. The model's current efficiency rankings already place AWD irrigation 3rd in 20-year per-dollar impact (28,438 person-years per $M); glacial melt trends suggest this ranking will hold or improve over time.

No policy parameters were changed as a result of this analysis. The glacier melt trend reinforces existing allocations rather than requiring new policies. However, it provides additional justification for the model's central finding: capital infrastructure investments that persist for decades are more valuable than operational programs, because the climate threats they protect against are intensifying over time.


C. Single-Year Model Results ($8.0B Budget)

C.1 Optimal Allocation

| Policy | Allocation | People-Equiv | Tags |
|--------|-----------|-------------|------|
| Fortified feeding | $1,800M | 11,472,365 | — |
| Saline-tolerant rice | $1,500M | 2,964,259 | BDP |
| Renewable irrigation | $1,200M | 1,200,477 | BNP |
| Post-harvest storage | $1,200M | 2,278,814 | — |
| AWD irrigation | $1,000M | 1,871,215 | BNP, BDP |
| Flood-tolerant rice | $499M | 565,935 | BDP |
| Crop diversification | $200M | 152,220 | — |
| Farmer insurance | $200M | 98,995 | BNP |
| River/canal excavation | $200M | 21,860 | BNP |
| Tree planting | $200M | 17,480 | BNP |
| Base subtotal | $7,999M | 20,643,620 | |
| Synergy bonus | | +1,519,946 | |
| GRAND TOTAL | $7,999M | 22,163,566 | |

Policies NOT funded: Cyclone early warning, flood forecasting, aquaculture (marginal impact too low to compete at $8B scale).

C.2 Key Metrics

Deficit closed: 100% (22.2M people-equiv vs 18.05M target)
Resilience buffer: 23% (4.1M surplus capacity)
BNP share of spending: 35.0% (meets floor exactly)
Policies funded: 10 of 13
Synergy contribution: 7.4% of base impact
Dollar value of gains: $5.14B/year (at $285/person food cost)


D. Multi-Year Simulation: 5-Year Investment, 20-Year Impact

D.1 Setup

Investment period: 5 years at $8B/year = $40B available
Measurement period: 20 years
Capital policies (11 total): one-time investment, benefits persist with 2–8% annual decay
Operational policies (2: fortified feeding, farmer insurance): require annual funding; zero impact when unfunded

D.2 Investment Phase

| Year | Spent | Key Allocation |
|------|-------|---------------|
| 1 | $8.0B | Full mix: feeding $1.8B, saline rice $1.5B, storage $1.2B, solar $1.2B, AWD $1.0B, flood rice $0.5B, plus 4 more |
| 2 | $8.0B | Maxes remaining capital: flood rice to $1.8B, diversification to $1.0B, trees $0.9B, canals $0.8B, forecasting, warning, aquaculture. Plus feeding $1.8B, insurance $1.0B |
| 3–5 | $2.8B/yr | All capital complete. Only feeding ($1.8B) + insurance ($1.0B) |

Total capital invested: $11.2B. Total operational: $13.2B. Grand total: $24.4B of $40B available.

D.3 20-Year Impact Trajectory

| Year | Capital | Operational | Synergy | Total | % of Deficit |
|------|---------|------------|---------|-------|-------------|
| 1 | 9,072,260 | 11,571,360 | 1,682,768 | 22,326,387 | 100% |
| 2 | 10,289,472 | 11,693,724 | 2,628,528 | 24,611,724 | 100% |
| 3–5 | 10,289,486 | 11,693,724 | 2,628,546 | 24,611,755 | 100% |
| 6 | 9,833,229 | 0 | 2,156,163 | 11,989,392 | 66.4% |
| 7 | 9,398,700 | 0 | 1,948,052 | 11,346,751 | 62.9% |
| 10 | 8,214,713 | 0 | 1,438,207 | 9,652,919 | 53.5% |
| 15 | 6,583,707 | 0 | 870,223 | 7,453,930 | 41.3% |
| 20 | 5,296,290 | 0 | 528,536 | 5,824,826 | 32.3% |

During years 1–5, the deficit is fully closed (100%). When funding stops in year 6, operational impact vanishes. Capital investments continue but decay slowly. By year 20, capital still covers 32.3% of the deficit — 5.8 million people remain food-secure from investments made 15+ years earlier.

D.4 20-Year Efficiency Ranking

| Policy | Invested | 20-Year Person-Years | Per $M (20yr) |
|--------|---------|---------------------|--------------|
| Post-harvest storage | $1,200M | 38,416,726 | 32,014 |
| Saline-tolerant rice | $1,500M | 45,049,235 | 30,033 |
| AWD irrigation | $1,000M | 28,437,721 | 28,438 |
| Renewable irrigation | $1,200M | 20,237,890 | 16,865 |
| Flood-tolerant rice | $1,800M | 20,290,073 | 11,272 |
| Fortified feeding | $9,000M | 57,361,824 | 6,374 |
| Crop diversification | $1,000M | 5,441,917 | 5,442 |

D.5 Capital vs Operational — 20-Year Comparison

| | Capital | Operational |
|---|---------|------------|
| Total invested | $11,200M (45.9%) | $13,200M (54.1%) |
| Total person-years | 160,212,798 (64.5%) | 58,346,257 (23.5%) |
| Person-years per $M | 14,305 | 4,420 |
| Synergy person-years | 29,719,576 (12.0%) | — |

Capital investments produce 3.2x more person-years per dollar than operational programs over 20 years.

D.6 Key Findings

1. All 11 capital policies reach full deployment by year 2.
2. Only $24.4B of $40B is productively deployable — surplus should fund education, healthcare, or climate resilience reserves.
3. Capital investments deliver 127.5M person-years AFTER funding stops vs 90.3M DURING the 5-year period.
4. When operational funding stops in year 6, impact drops 51% overnight (the "vulnerability cliff").
5. Cost per person-year across 20 years: $112, well below the $285 food cost benchmark.
6. At year 20, capital alone still covers 32.3% of the deficit — 5.8 million people remain food-secure from investments made 15+ years earlier.
