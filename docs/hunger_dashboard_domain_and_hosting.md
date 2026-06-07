# Hunger dashboard: domain and hosting (from local to public)

Your app is only on your machine right now. To use **your own domain** (e.g. `yourproject.org`), you need **(1)** a public deployment and **(2)** DNS records that point your domain to that deployment.

---

## Recommended path (simple, reliable)

1. **Deploy the app** to a host that supports your stack (R Shiny or similar).
2. **Buy a domain** from a registrar.
3. **Point DNS** at your host (usually CNAME + apex/ALIAS records).
4. **Enable HTTPS** (most hosts issue certificates automatically once DNS is correct).

**Order of operations:** deploy first, then attach the domain. You cannot meaningfully “point” a domain at `localhost`.

---

## Hosting options that fit a research dashboard

### Option A — Container platform (good default)

**Railway** or **Render** (and similar) work well when you package the app with a **Dockerfile**.

- **Pros:** predictable deployments, custom domains, HTTPS, scales if traffic grows.
- **Typical flow:** push code → build image → get a public URL → add custom domain in the dashboard → paste DNS records from the host into your registrar.

### Option B — Shiny-specific host (fastest demo)

**shinyapps.io** can be the quickest way to get a public URL for an R Shiny app.

- **Pros:** very fast to publish Shiny apps.
- **Cons:** less flexibility than full container hosting; pricing/limits vary by tier.

### Option C — University / lab infrastructure (if available)

Some schools provide VMs or web hosting for student research. Ask your advisor/IT — sometimes free and stable for academic use.

---

## Buying a domain

Common registrars:

- **Cloudflare Registrar** (often at-cost pricing)
- **Namecheap**
- **Google Domains** (now often migrated; verify current options)

**Tips:**

- Prefer a **short, memorable** name.
- **`.org`** reads well for public-good / research tools.
- Register **2–3 years** if you plan to cite the URL on posters or papers.

**Rough cost:** about **$10–20/year** for many common TLDs (varies).

---

## Connecting the domain (typical DNS pattern)

Exact clicks differ by host, but the pattern is:

1. In the hosting dashboard, choose **Custom domain**.
2. Add:
   - **`www.yourproject.org`** → usually a **CNAME** to the platform hostname.
   - **Apex** `yourproject.org` (no `www`) → often an **A record** or **ALIAS/ANAME** (depends on provider).
3. Wait for DNS propagation (often minutes, sometimes up to 24–48 hours).
4. Confirm **HTTPS** certificate status in the host dashboard.

**Note:** Some platforms want you to verify domain ownership via a temporary TXT record.

---

## Cost expectations (rough)

| Item | Typical range |
|------|----------------|
| Domain | ~$10–20/year |
| Hosting | Free tiers exist for demos; **$5–20/month** is common for reliable small apps |
| Email (optional) | Not required for the dashboard; extra if you want `contact@` |

---

## Security and operations basics (worth doing early)

- **HTTPS only** for anything public.
- **Secrets:** API keys, DB passwords in environment variables — not in Git.
- **Updates:** plan occasional dependency updates (R packages, system libs).
- **Backups:** if you add a database later, back it up; static dashboards are simpler.

---

## What you need from your project before deployment

- A reproducible way to run the app (e.g. `Rscript` entrypoint or Shiny run command).
- Ideally a **`Dockerfile`** if using Railway/Render-style hosting.
- A clear list of **data paths** (read-only bundled data vs. downloaded at runtime).

---

## Suggested next step in this repo

1. Confirm the app’s **run command** (how you start it locally).
2. Add deployment packaging (**Dockerfile** if targeting Railway/Render).
3. Deploy → get temporary URL → buy domain → attach custom domain → verify HTTPS.

If you want a tailored checklist, add which stack you deploy (**Shiny**, **static site**, **Plumber API**, etc.) and where you prefer to host (**Railway/Render/shinyapps.io**).
