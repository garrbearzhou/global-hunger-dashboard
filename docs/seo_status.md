# SEO & indexing tracker — globalhungerdashboard.com

Last updated: 2026-07-11

## Search Console — URL status

| URL | Status | Notes |
|-----|--------|-------|
| `https://globalhungerdashboard.com/` | **Indexed** | Confirmed in URL Inspection (green check) |
| `?tab=map` | Indexing requested | |
| `?tab=country_details` | Indexing requested | |
| `?tab=bangladesh_research` | **Request after deploy** | New in sitemap Jul 11 |
| `?tab=about` | **Request after deploy** | New in sitemap Jul 11 |
| `?tab=overview` | Indexing requested | |
| `?tab=scenario_lab` | **Request after deploy** | New in sitemap Jul 11 |
| `?tab=timeseries` | Indexing requested | |
| `?tab=analysis` | Indexing requested | |
| `?tab=grfc_trends` | **Request after deploy** | New in sitemap Jul 11 |
| `?tab=ghi_comparison` | **Request after deploy** | New in sitemap Jul 11 |
| `?tab=explorer` | **Request after deploy** | New in sitemap Jul 11 |
| `?tab=data_coverage` | Indexing requested | |
| `?tab=citations` | Indexing requested | |

Full URLs: `https://globalhungerdashboard.com/?tab=<name>`

## Sitemap & robots (done)

- Sitemap submitted: `assets/sitemap.xml` — **Success**, **9** pages discovered (Jul 9, 2026) → **15** URLs after Jul 11 update (re-submit after deploy)
- Static SEO landing page: `https://globalhungerdashboard.com/assets/landing.html`
- Live sitemap: `https://globalhungerdashboard.com/assets/sitemap.xml`
- Root redirects (Cloudflare): `/sitemap.xml` → `/assets/sitemap.xml`, `/robots.txt` → `/assets/robots.txt`
- `robots.txt` points to assets sitemap URL

### After deploy — Search Console checklist

1. Open [Google Search Console](https://search.google.com/search-console) → **Sitemaps**
2. Re-submit: `https://globalhungerdashboard.com/assets/sitemap.xml` (or click existing sitemap → **Resubmit**)
3. **URL Inspection** → paste each new URL below → **Request indexing**:
   - `https://globalhungerdashboard.com/?tab=bangladesh_research`
   - `https://globalhungerdashboard.com/?tab=about`
   - `https://globalhungerdashboard.com/?tab=scenario_lab`
   - `https://globalhungerdashboard.com/?tab=grfc_trends`
   - `https://globalhungerdashboard.com/?tab=ghi_comparison`
   - `https://globalhungerdashboard.com/?tab=explorer`

## Next checks (weekly)

- [ ] Re-inspect tab URLs in Search Console — update table when status changes to **Indexed**
- [ ] Review **Performance** (clicks, impressions) after ~1–2 weeks
- [ ] Review **Pages** report for indexed vs not indexed
- [ ] Confirm sitemap shows **15** discovered pages after resubmit

## Backlinks

| Source | Status |
|--------|--------|
| GitHub README | Updated locally — **push to publish** |
| GitHub repo Website field | Manual — see `docs/backlinks_playbook.md` |
| Blog (A Grain of Change) | Copy ready in playbook |
| School/lab / mentor page | Email template in playbook |
| Poster / paper | Add footer line in playbook |

Full instructions: **`docs/backlinks_playbook.md`**

## On-site SEO (Jul 11)

- [x] Sitemap expanded to 15 URLs (6 new tabs)
- [x] `SEO_BY_TAB` covers all public menu tabs
- [x] Per-tab canonical URLs update in browser

## Optional next SEO work

- [x] Static landing page with crawlable intro copy
- [x] Open Graph / Twitter meta tags
- [ ] Backlinks — in progress (see playbook)
- [ ] `seo-intro-block` on Bangladesh and About tabs
- [ ] Refresh `landing.html` with new tab links
