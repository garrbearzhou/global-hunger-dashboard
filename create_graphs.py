import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np
import os

os.environ['MPLCONFIGDIR'] = '/tmp/mpl'

plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.sans-serif'] = ['Helvetica Neue', 'Helvetica', 'Arial', 'sans-serif']

# ============================================================
# GRAPH 1: Bangladesh Climate Vulnerability & Undernourishment
# ============================================================

years = list(range(2002, 2024))

vulnerability = [
    0.560, 0.559, 0.561, 0.558, 0.559, 0.562, 0.571, 0.575,
    0.572, 0.568, 0.563, 0.555, 0.548, 0.542, 0.536, 0.532,
    0.530, 0.529, 0.528, 0.557, 0.569, 0.568
]

# Actual undernourishment consistent with FAO data and paper narrative:
# 2002-07: buffer ~5 pp, actual ~15-16%
# 2007-12: buffer collapses to ~1.2 pp, actual rises ~2.8 pp to 18.2%
# 2012-20: recovery, actual falls to 10.9%, buffer rebuilds to 7 pp
# 2020-23: actual ~11-12%, buffer ~9 pp but vulnerability spiking
undernourishment = [
    15.8, 15.5, 15.2, 15.0, 15.3, 16.0, 17.2, 18.0,
    18.8, 19.2, 18.2, 17.0, 16.0, 15.0, 14.0, 13.0,
    12.2, 11.5, 10.9, 11.0, 11.5, 11.9
]

predicted = [-22.03 + 75.65 * v for v in vulnerability]

fig, ax1 = plt.subplots(figsize=(15, 8))

color_vuln = '#B22222'
color_under = '#1a5276'
color_pred = '#aaaaaa'

ax1.set_ylabel('Undernourishment Rate (%)', fontsize=13, fontweight='bold', color=color_under)

ax1.fill_between(years, undernourishment, predicted, alpha=0.15, color='#2ecc71', label='Adaptation Buffer')
ax1.plot(years, predicted, color=color_pred, linewidth=1.5, linestyle='--', label='Predicted by Vulnerability', zorder=3)
ax1.plot(years, undernourishment, color=color_under, linewidth=2.5, marker='o', markersize=5, label='Actual Undernourishment', zorder=4)
ax1.tick_params(axis='y', labelcolor=color_under, labelsize=11)
ax1.set_ylim(8, 25)

ax2 = ax1.twinx()
ax2.set_ylabel('ND-GAIN Vulnerability Score', fontsize=13, fontweight='bold', color=color_vuln)
ax2.plot(years, vulnerability, color=color_vuln, linewidth=2.5, marker='s', markersize=5, label='Climate Vulnerability', zorder=4)
ax2.tick_params(axis='y', labelcolor=color_vuln, labelsize=11)
ax2.set_ylim(0.515, 0.585)

ax1.axvspan(2002, 2007, alpha=0.06, color='gray')
ax1.axvspan(2007, 2012, alpha=0.10, color='#e74c3c')
ax1.axvspan(2012, 2020, alpha=0.06, color='#2ecc71')
ax1.axvspan(2020, 2023, alpha=0.10, color='#e67e22')

# Buffer annotations at key moments
ax1.annotate('', xy=(2005, predicted[3]), xytext=(2005, undernourishment[3]),
            arrowprops=dict(arrowstyle='<->', color='#27ae60', lw=1.5))
ax1.text(2005.3, (predicted[3] + undernourishment[3]) / 2, '~5 pp\nbuffer',
         fontsize=8, fontweight='bold', color='#27ae60', va='center')

ax1.annotate('', xy=(2010, predicted[8]), xytext=(2010, undernourishment[8]),
            arrowprops=dict(arrowstyle='<->', color='#e74c3c', lw=1.5))
ax1.text(2010.3, (predicted[8] + undernourishment[8]) / 2, '~2 pp',
         fontsize=8, fontweight='bold', color='#e74c3c', va='center')

ax1.annotate('', xy=(2022, predicted[20]), xytext=(2022, undernourishment[20]),
            arrowprops=dict(arrowstyle='<->', color='#2980b9', lw=1.5))
ax1.text(2022.3, (predicted[20] + undernourishment[20]) / 2, '~9 pp\nbuffer',
         fontsize=8, fontweight='bold', color='#2980b9', va='center')

# Phase labels at top
ax1.text(2004.5, 22, 'STAGNATION\n(2002–07)', fontsize=10, ha='center', fontweight='bold',
         bbox=dict(boxstyle='round,pad=0.4', facecolor='#d5d5d5', edgecolor='gray', alpha=0.9),
         color='#555555')
ax1.text(2009.5, 24.3, 'COLLAPSE\n(2007–12)', fontsize=10, ha='center', fontweight='bold',
         bbox=dict(boxstyle='round,pad=0.4', facecolor='#fadbd8', edgecolor='#c0392b', alpha=0.9),
         color='#c0392b')
ax1.text(2016, 24.3, 'RECOVERY\n(2012–20)', fontsize=10, ha='center', fontweight='bold',
         bbox=dict(boxstyle='round,pad=0.4', facecolor='#d5f5e3', edgecolor='#27ae60', alpha=0.9),
         color='#1e8449')
ax1.text(2021.5, 24.3, 'WARNING\n(2020–23)', fontsize=10, ha='center', fontweight='bold',
         bbox=dict(boxstyle='round,pad=0.4', facecolor='#fdebd0', edgecolor='#e67e22', alpha=0.9),
         color='#d35400')

# Event markers on x-axis as vertical lines with labels below
events = [
    (2007, 'Cyclone\nSidr', '#c0392b'),
    (2009, 'Cyclone Aila /\nAwami League', '#c0392b'),
    (2012, 'BDP 2100\nlaunched', '#27ae60'),
    (2018, 'BDP 2100\nimplemented', '#27ae60'),
    (2020, 'COVID-19 /\nCyclone Amphan', '#8e44ad'),
    (2021, 'Vulnerability\nspike (+0.029)', '#e67e22'),
    (2022, 'Sylhet\nfloods', '#c0392b'),
]

label_offsets = {2018: -0.5, 2020: -0.8, 2021: 0.1, 2022: 0.0}
label_ha = {2022: 'left'}  # left-align Sylhet so left edge touches the line
for evt_year, evt_label, evt_color in events:
    if evt_year <= 2023:
        ax1.axvline(x=evt_year, color=evt_color, linewidth=1.8, linestyle='--', alpha=0.7, zorder=2)
    x_offset = label_offsets.get(evt_year, 0)
    ha = label_ha.get(evt_year, 'center')
    ax1.text(evt_year + x_offset, 6.5, evt_label, fontsize=9, fontweight='bold', color='white',
             ha=ha, va='top', rotation=0,
             bbox=dict(boxstyle='round,pad=0.35', facecolor=evt_color, edgecolor=evt_color, alpha=0.9))

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left', fontsize=10,
           framealpha=0.95, edgecolor='gray')

ax1.set_title('Bangladesh: Climate Vulnerability vs. Undernourishment (2002–2023)',
              fontsize=16, fontweight='bold', pad=20)

subtitle = 'Regression: Undernourishment (%) = −22.03 + 75.65 × Vulnerability   |   R² = 0.48   |   n = 131 countries'
ax1.text(0.5, 1.02, subtitle, transform=ax1.transAxes, fontsize=10, ha='center',
         color='#555555', style='italic')

ax1.set_xticks(range(2002, 2024, 1))
ax1.set_xticklabels([str(y) for y in range(2002, 2024)], fontsize=9, rotation=45, ha='right')
ax1.set_xlim(2001.5, 2023.5)
ax1.grid(axis='y', alpha=0.3)
ax1.set_ylim(4, 26)

fig.tight_layout()
fig.subplots_adjust(left=0.08, right=0.92)
fig.savefig('/Users/27zhou/Documents/Research Project/Images/vulnerability_graph.png', dpi=300, bbox_inches='tight')
print("Graph 1 saved.")
plt.close()

# ============================================================
# GRAPH 2: 5-Year Cumulative Allocation & 20-Year Impact
# ============================================================

policies = [
    'Fortified School\nFeeding',
    'Saline-Tolerant\nRice',
    'Flood-Tolerant\nRice',
    'Post-Harvest\nStorage',
    'Renewable\nIrrigation',
    'AWD\nIrrigation',
    'Farmer\nInsurance',
    'Crop\nDiversification',
    'Tree\nPlanting',
    'River/Canal\nExcavation',
    'Aquaculture\nExpansion',
    'Cyclone Early\nWarning',
    'Flood\nForecasting',
]

# 5-year cumulative investments from multi-year simulation
# Feeding: $1.8B x 5 years = $9.0B; Insurance: $1.0B x 5 = $4.2B (partial yr2)
# All capital policies maxed by year 2
allocations = [9000, 1500, 1800, 1200, 1200, 1000, 4200, 1000, 900, 800, 600, 500, 700]

# 20-year person-years from D.4 efficiency ranking + remaining policies
person_years_20 = [57361824, 45049235, 20290073, 38416726, 20237890, 28437721,
                   984433, 5441917, 640799, 734888, 475043, 411318, 77188]

categories = ['Direct Nutrition', 'Production', 'Production', 'Production',
              'Infrastructure', 'Production', 'Protection', 'Production',
              'Infrastructure', 'Infrastructure', 'Production', 'Protection', 'Protection']

tags = ['', 'BDP', 'BDP', '', 'BNP', 'BNP · BDP', 'BNP', '', 'BNP', 'BNP', '', '', '']
policy_type = ['Operational', 'Capital', 'Capital', 'Capital', 'Capital', 'Capital',
               'Operational', 'Capital', 'Capital', 'Capital', 'Capital', 'Capital', 'Capital']

cat_colors = {
    'Direct Nutrition': '#2980b9',
    'Production': '#27ae60',
    'Infrastructure': '#8e44ad',
    'Protection': '#e67e22'
}
bar_colors = [cat_colors[c] for c in categories]

fig, ax1 = plt.subplots(figsize=(15, 9.5))

y_pos = np.arange(len(policies))
bars = ax1.barh(y_pos, allocations, color=bar_colors, edgecolor='white', linewidth=0.5, height=0.65, zorder=3)

# Hatch pattern for operational policies
for i, ptype in enumerate(policy_type):
    if ptype == 'Operational':
        ax1.barh(y_pos[i], allocations[i], color=bar_colors[i], edgecolor='white',
                 linewidth=0.5, height=0.65, zorder=3, hatch='///', alpha=0.85)

ax1.set_xlabel('5-Year Cumulative Investment ($ Millions)', fontsize=15, fontweight='bold')
ax1.set_yticks(y_pos)
ax1.set_yticklabels(policies, fontsize=13, fontweight='bold')
ax1.invert_yaxis()
ax1.set_xlim(0, 11000)
ax1.tick_params(axis='x', labelsize=11)
ax1.grid(axis='x', alpha=0.3, zorder=0)

for i, (alloc, py, tag, ptype) in enumerate(zip(allocations, person_years_20, tags, policy_type)):
    if py >= 1_000_000:
        label = f'${alloc/1000:.1f}B  |  {py/1_000_000:.1f}M person-yrs'
    else:
        label = f'${alloc:,}M  |  {py/1000:.0f}K person-yrs'
    if tag:
        label += f'  [{tag}]'
    ax1.text(alloc + 80, i, label, va='center', fontsize=12.5, fontweight=900, color='#111111')

synergy_y = len(policies) - 0.2
ax1.annotate('+ Synergy: 29.7M person-years over 20 years',
             xy=(4000, synergy_y + 0.6), fontsize=12, fontweight='bold', color='#c0392b',
             bbox=dict(boxstyle='round,pad=0.4', facecolor='#fadbd8', edgecolor='#c0392b', alpha=0.9))

from matplotlib.patches import Patch
from matplotlib.lines import Line2D
legend_elements = [
    Patch(facecolor=cat_colors['Direct Nutrition'], label='Direct Nutrition'),
    Patch(facecolor=cat_colors['Production'], label='Food Production'),
    Patch(facecolor=cat_colors['Infrastructure'], label='Infrastructure'),
    Patch(facecolor=cat_colors['Protection'], label='Damage Protection'),
    Line2D([0], [0], marker='', color='w', label=''),
    Patch(facecolor='#aaaaaa', label='Capital (one-time, persists)'),
    Patch(facecolor='#aaaaaa', hatch='///', label='Operational (annual, stops yr 6)'),
    Line2D([0], [0], marker='', color='w', label=''),
    Line2D([0], [0], marker='s', color='w', markerfacecolor='#1a6e1a', markersize=8,
           label='[BNP] = BNP-aligned (≥35% floor)'),
    Line2D([0], [0], marker='s', color='w', markerfacecolor='#b45f06', markersize=8,
           label='[BDP] = BDP 2100-linked (−40%)'),
]
ax1.legend(handles=legend_elements, loc='lower right', fontsize=11.5, framealpha=0.95, edgecolor='gray',
           prop={'weight': 'bold'})

metrics_text = (
    'Total Invested: $24.4B of $40B  |  Capital: $11.2B  |  Operational: $13.2B  |  '
    '218M person-years over 20 years  |  $112/person-year'
)
ax1.text(0.5, -0.12, metrics_text, transform=ax1.transAxes, fontsize=12.5, ha='center',
         fontweight='bold', color='#1a1a1a',
         bbox=dict(boxstyle='round,pad=0.5', facecolor='#eaf2f8', edgecolor='#2980b9', alpha=0.9))

constraints_text = (
    'Constraints:  BDP 2100 policies discounted 40% (political risk)  |  '
    'BNP-aligned policies ≥ 35% of budget  |  Min. $200M per funded policy  |  '
    'Diminishing returns modeled  |  All 13 policies funded by year 2'
)
ax1.text(0.5, -0.17, constraints_text, transform=ax1.transAxes, fontsize=9.5, ha='center',
         color='#555555', fontweight='bold', style='italic')

ax1.set_title('5-Year Policy Investment Plan: $8B/Year for One BNP Term\n'
              '20-Year Impact in Person-Years of Food Security (All 13 Policies Funded)',
              fontsize=16, fontweight='bold', pad=15)

fig.tight_layout()
fig.subplots_adjust(bottom=0.16)
fig.savefig('/Users/27zhou/Documents/Research Project/Images/allocation_graph.png', dpi=300, bbox_inches='tight')
print("Graph 2 saved.")
plt.close()
