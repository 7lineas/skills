# Exhaustive SEO Audit Checklist

Use with [SKILL.md](SKILL.md) Workflow A. Mark each item **✓** **✗** **—** (N/A).

---

## A. Discovery & scope

- [ ] Identify all public routes (marketing, help, legal, blog)
- [ ] Identify all private routes (auth, workspace, user content, API)
- [ ] Confirm production domain and deployment platform
- [ ] Confirm primary locale (single-language vs i18n)
- [ ] List competitors/reference sites for SERP expectations (optional)

---

## B. Environment & configuration

- [ ] `NEXT_PUBLIC_APP_URL` / `NEXT_PUBLIC_SITE_URL` set in production
- [ ] Same variable available at **build time** on host (Vercel env)
- [ ] Staging/preview: decide noindex strategy for preview URLs (Vercel defaults often noindex — verify)
- [ ] No secrets in public env vars
- [ ] `metadataBase` uses production URL helper, not hardcoded string

---

## C. Global metadata (root layout)

- [ ] `applicationName`
- [ ] `authors`, `creator`, `publisher`
- [ ] Default title and description (home)
- [ ] Favicon (`icon`, `shortcut`)
- [ ] Apple touch icon
- [ ] `manifest.webmanifest` linked via `app/manifest.ts`
- [ ] `category` if relevant
- [ ] Site-wide JSON-LD in layout body

---

## D. Per-route metadata matrix

Create a table for every route:

| Path | Title unique? | Description unique? | Canonical | noIndex | OG image |

Routes to always include:

- [ ] `/`
- [ ] `/help`
- [ ] Each `/help/[slug]`
- [ ] `/privacy`
- [ ] `/terms`
- [ ] `/sign-in` → **noIndex**
- [ ] `/sign-up` → **noIndex**
- [ ] Workspace shell → **noIndex**
- [ ] Dynamic user pages → **noIndex** or blocked

Checks:

- [ ] No two public pages share identical title
- [ ] No two public pages share identical description
- [ ] Descriptions match visible page intent (not lorem)
- [ ] Title length roughly 30–60 chars visible portion
- [ ] Description length roughly 120–160 chars (flexible)

---

## E. robots.txt

- [ ] Returns 200 at `/robots.txt`
- [ ] Valid syntax
- [ ] `User-agent: *` rule present
- [ ] Disallow paths cover:
  - [ ] `/api/`
  - [ ] Authenticated app areas
  - [ ] Internal auth provider paths
  - [ ] Search/filter query explosion paths (if any)
- [ ] Sitemap URL is absolute HTTPS
- [ ] No obsolete directives (`Host`, crawl-delay unless needed)
- [ ] Not blocking `/`, `/help`, or CSS/JS needed for render (Next handles this)

---

## F. sitemap.xml

- [ ] Returns 200 at `/sitemap.xml`
- [ ] Valid XML, correct namespace
- [ ] All URLs HTTPS and match production domain
- [ ] No trailing-slash duplicates (pick one style)
- [ ] Includes all intended public pages
- [ ] Excludes:
  - [ ] Sign-in / sign-up
  - [ ] Workspace / dashboard
  - [ ] User-generated private URLs
  - [ ] API routes
  - [ ] Redirect-only URLs
- [ ] Help articles synced with content catalog
- [ ] `lastModified` present (optional but recommended)
- [ ] Under 50,000 URLs (single file limit)

---

## G. JSON-LD / structured data

### Site-level

- [ ] Organization — name, url
- [ ] WebSite — name, url, description
- [ ] SoftwareApplication (if applicable) — no fake offers/pricing/reviews
- [ ] All URLs absolute
- [ ] `@context` is `https://schema.org`

### Page-level

- [ ] WebPage on content pages
- [ ] BreadcrumbList on nested pages (help articles)
- [ ] FAQPage only where FAQ is visible on page
- [ ] Question/Answer text matches DOM content
- [ ] No conflicting types on same page (e.g. duplicate FAQPage)

### Validation

- [ ] Rich Results Test passes for sample URLs
- [ ] No parser errors in JSON (valid JSON.stringify)
- [ ] Scripts in initial HTML (SSR), not client-only injection

---

## H. Open Graph & Twitter

- [ ] Every public page has og:title, og:description, og:url
- [ ] og:site_name set
- [ ] og:locale appropriate
- [ ] og:type = website (or article for blog)
- [ ] og:image 1200×630 minimum
- [ ] og:image alt text
- [ ] twitter:card = summary_large_image
- [ ] Image URL resolves (200, image/png or jpeg)
- [ ] LinkedIn/Facebook debugger shows correct preview (manual spot check)
- [ ] No separate twitter-image required if OG image works

---

## I. Content & on-page SEO

### Landing page

- [ ] Single clear H1
- [ ] Supporting H2/H3 structure
- [ ] Above-the-fold text describes product (not "Loading...")
- [ ] Feature sections with descriptive copy
- [ ] Internal links to help, pricing (if any), legal
- [ ] CTA to sign-up (OK for UX; sign-up itself stays noindex)
- [ ] Images have alt text where meaningful
- [ ] No hidden text / keyword stuffing

### Help / docs

- [ ] Index page lists articles with summaries
- [ ] Each article ≥ 300 words substantive content (guideline)
- [ ] Code examples don't replace explanatory prose
- [ ] Cross-links between related articles
- [ ] Last updated visible (optional, builds trust)

### Legal

- [ ] Privacy and terms indexable (trust signals)
- [ ] Contact information reachable

---

## J. Performance & crawlability (light touch)

- [ ] Home LCP acceptable (not blocking SEO launch alone)
- [ ] No `Disallow: /_next/` in robots (don't block assets)
- [ ] No accidental `X-Robots-Tag: noindex` header on public pages
- [ ] HTTPS enforced
- [ ] www vs non-www — one canonical (redirect other)
- [ ] 404 page exists, not in sitemap

---

## K. Auth & middleware

- [ ] Crawlers can fetch `/`, `/help/*`, `/robots.txt`, `/sitemap.xml` without session
- [ ] Sign-in/up reachable but noindex
- [ ] Authenticated redirect does not apply to bots on marketing URLs
- [ ] Clerk/auth public route list includes SEO assets

---

## L. Internationalization (if applicable)

- [ ] `hreflang` alternates for each locale
- [ ] Canonical per locale or x-default strategy documented
- [ ] `inLanguage` in JSON-LD matches page language
- [ ] og:locale / og:locale:alternate set

---

## M. Automated tests

- [ ] seo.test.ts (or equivalent) exists
- [ ] Tests run in CI
- [ ] Tests cover sitemap exclusions
- [ ] Tests cover robots disallow
- [ ] Tests cover metadata invariants
- [ ] Tests cover JSON-LD shape

---

## N. Production & Search Console

- [ ] Deploy succeeded after SEO changes
- [ ] curl verification passed
- [ ] GSC property verified
- [ ] Sitemap submitted
- [ ] No critical coverage errors (monitor weekly)
- [ ] Brand search returns correct title/description

---

## O. Post-audit deliverables

Agent should produce:

1. Scorecard (Pass/Fail per section)
2. Prioritized fix list (Critical → Nice-to-have)
3. PR or commits with fixes (if user asked to implement)
4. Updated tests for any new routes added to sitemap
