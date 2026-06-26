---
name: nextjs-seo
description: Audits, implements, and maintains production SEO for Next.js App Router sites (SaaS landing pages, help centers, marketing sites). Covers metadata, canonical URLs, Open Graph/Twitter cards, JSON-LD structured data, robots.txt, sitemap.xml, crawl/index rules, server-rendered indexable content, smoke tests, and Google Search Console ops. Use when reviewing SEO, shipping a new site, fixing indexing, improving social previews, adding help/docs SEO, or when the user mentions metadata, sitemap, robots, JSON-LD, Open Graph, canonical, noindex, Search Console, or structured data.
---

# Next.js SEO — Review, Implement, Maintain

Agents use this skill to **audit existing SEO**, **fix gaps**, and **keep SEO from regressing**. Default stack: **Next.js App Router** (16+). Adapt patterns to other frameworks when needed.

## When to apply

| Trigger | Action |
|---------|--------|
| New marketing site / landing / help center | Full implementation workflow |
| "Review our SEO" / pre-launch checklist | Audit workflow |
| Indexing issues (auth pages indexed, app routes in Google) | Fix crawl/index rules |
| Poor social previews | OG image + metadata |
| After major route/content changes | Re-audit sitemap + metadata + tests |

## Core principles

1. **One source of truth** — Centralize site name, description, URL, and metadata helpers (`lib/seo.ts`, `lib/public-routes.ts`).
2. **Index intentionally** — Public marketing/help = index. Auth, workspace, API, user content = noindex + robots disallow.
3. **Crawlers see content without JS auth gates** — Landing/help must be server-rendered HTML with real copy, not a loading shell.
4. **Don't lie to Google** — No fake pricing/offers in JSON-LD unless real. No `keywords` meta (ignored since ~2009).
5. **Test invariants** — Smoke tests lock sitemap exclusions, robots rules, metadata shape, JSON-LD types.
6. **Verify production** — curl live URLs after deploy; submit sitemap in Search Console once.

---

## Workflow A — Full SEO audit

Copy this checklist and work top to bottom. Report each section as **Pass / Fail / N/A** with file paths and fixes.

```
Audit progress:
- [ ] 1. Environment & URL config
- [ ] 2. Metadata (every public route)
- [ ] 3. Crawl rules (robots + noindex)
- [ ] 4. Sitemap
- [ ] 5. Structured data (JSON-LD)
- [ ] 6. Social previews (OG + Twitter)
- [ ] 7. Indexable content quality
- [ ] 8. Technical files (manifest, icons)
- [ ] 9. Auth/middleware alignment
- [ ] 10. Automated tests
- [ ] 11. Production verification
- [ ] 12. Search Console (ops)
```

### 1. Environment & URL config

- [ ] Production URL env var set (`NEXT_PUBLIC_APP_URL` or `NEXT_PUBLIC_SITE_URL`) — **required** for absolute URLs in sitemap, JSON-LD, OG.
- [ ] Root layout sets `metadataBase` from that URL.
- [ ] Canonical paths are **relative** in metadata (`/help`) — Next.js resolves via `metadataBase`.
- [ ] No hardcoded `localhost` in production metadata or JSON-LD.

### 2. Metadata audit

For **each public route**, verify:

- [ ] Unique `title` (`Page Title | Site Name` or dedicated home title)
- [ ] Unique `description` (50–160 chars, human-written, matches page content)
- [ ] `alternates.canonical` matches the route path
- [ ] `openGraph`: title, description, url, siteName, locale, type, images
- [ ] `twitter`: `summary_large_image`, title, description, images
- [ ] `robots`: index/follow true for public; **noindex/nofollow** for auth + private app shells
- [ ] **No** `keywords` meta tag
- [ ] Home page metadata does not duplicate root layout defaults unintentionally

Use centralized `createPageMetadata({ title, description, path, noIndex })` — see [reference.md](reference.md).

### 3. Crawl rules

**robots.txt** (`app/robots.ts`):

- [ ] `disallow` for private surfaces: `/api/`, app workspace paths (`/p/`, `/library/`, etc.), auth internals (`/__clerk/`)
- [ ] **Do not** use redundant `allow: /` lists (disallow-only is fine)
- [ ] **Do not** set non-standard `Host:` directive
- [ ] `sitemap` points to absolute production URL

**noindex metadata** (in addition to robots):

- [ ] `/sign-in`, `/sign-up` — `noIndex: true`
- [ ] Authenticated workspace layout — `noIndex: true` on `(workspace)` layout
- [ ] User-generated / private pages — noindex or not in sitemap

**Rule:** Auth routes may be **publicly reachable** (Clerk) but must **not** be indexed. Disallow alone is insufficient — use `noindex` meta too.

### 4. Sitemap

**Single catalog** (`PUBLIC_SEO_SITEMAP_ENTRIES` or equivalent):

- [ ] Includes: `/`, marketing pages, help/docs articles, legal (`/privacy`, `/terms`)
- [ ] **Excludes:** `/sign-in`, `/sign-up`, workspace, API, dynamic user content
- [ ] Each entry has sensible `changeFrequency` and `priority`
- [ ] URLs are absolute via `absoluteUrl(path)`
- [ ] `lastModified` is acceptable (build time OK for small sites)
- [ ] New help articles auto-added via catalog array — not hand-edited in sitemap.ts

Verify: `curl -s https://DOMAIN/sitemap.xml | grep sign-in` → **empty**

### 5. Structured data (JSON-LD)

**Site-wide** (root layout): Organization, WebSite, SoftwareApplication (if SaaS).

- [ ] Valid `@context`, `@type`, absolute URLs
- [ ] `inLanguage` matches site locale
- [ ] SoftwareApplication: **no** `offers`/pricing unless real product with verified price
- [ ] Publisher Organization matches real company

**Per-page** where applicable:

- [ ] Help/docs: `WebPage` + `BreadcrumbList`
- [ ] FAQ sections: `FAQPage` with Question/Answer pairs matching visible content
- [ ] Legal pages: optional `WebPage` (nice-to-have)

Render via `<script type="application/ld+json">` — see [reference.md](reference.md).

Validate with [Google Rich Results Test](https://search.google.com/test/rich-results) on production URLs.

### 6. Social previews

- [ ] `app/opengraph-image.tsx` — 1200×630 PNG via `ImageResponse`
- [ ] Metadata references `/opengraph-image` (Twitter uses same image — separate `twitter-image` optional, not required)
- [ ] OG image returns HTTP 200 in production
- [ ] No `@` Twitter site handle required unless brand has one

### 7. Indexable content quality

**Landing `/`:**

- [ ] Server Component renders marketing copy (headings, features, use cases) **before** client auth redirect
- [ ] No blank page or spinner as only HTML for crawlers
- [ ] H1 present; logical heading hierarchy (H1 → H2 → H3)
- [ ] Internal links to `/help`, legal, sign-up

**Help center:**

- [ ] Index page lists all articles with descriptions
- [ ] Each article: unique title, description, substantial content, internal links
- [ ] FAQ content in page body matches FAQ JSON-LD

### 8. Technical files

- [ ] `app/manifest.ts` — PWA name, icons, theme
- [ ] Favicon + apple-touch-icon in layout metadata
- [ ] `robots.txt` and `sitemap.xml` routes work without auth

### 9. Auth/middleware alignment

Public route allowlist (Clerk/proxy) must include SEO routes without login:

- `/`, `/help(.*)`, `/privacy`, `/terms`, `/robots.txt`, `/sitemap.xml`, `/opengraph-image`, `/sign-in`, `/sign-up`

Private routes must not leak into sitemap or return indexable metadata.

### 10. Automated tests

Add/maintain smoke tests — see [reference.md](reference.md#smoke-tests):

- Metadata shape, no keywords, noindex on auth
- Sitemap includes/excludes expected paths
- Robots disallow list
- JSON-LD types, no offers on SoftwareApplication
- FAQ/breadcrumb schema builders

Run: `pnpm exec vitest run __tests__/unit/seo.test.ts`

### 11. Production verification

After deploy, run:

```bash
curl -sI "https://DOMAIN/" | head -5
curl -sI "https://DOMAIN/robots.txt" | head -5
curl -sI "https://DOMAIN/sitemap.xml" | head -5
curl -sI "https://DOMAIN/opengraph-image" | head -5
curl -s "https://DOMAIN/sign-in" | grep -i robots
```

Expect: 200 on all; sign-in HTML or headers contain `noindex`.

### 12. Search Console (ops)

- [ ] Property verified (DNS or HTML)
- [ ] Sitemap submitted: `https://DOMAIN/sitemap.xml`
- [ ] "Couldn't fetch" may appear briefly after submit — recheck HTTP 200 within 24h
- [ ] No manual indexing request needed if sitemap + internal links are healthy

---

## Workflow B — Implement SEO from scratch

1. Create `lib/site.ts` or extend `lib/seo.ts` — site name, title, description, URL helper.
2. Add `createPageMetadata()` and JSON-LD helpers.
3. Add `lib/public-routes.ts` — sitemap entries, robots disallow, auth public patterns.
4. Add `app/robots.ts`, `app/sitemap.ts`, `app/opengraph-image.tsx`, `app/manifest.ts`.
5. Wire root `layout.tsx`: `metadataBase`, `generateMetadata`, `<SiteJsonLd />`.
6. Add per-route `export const metadata` on every public page.
7. Set `noIndex` on auth + workspace layouts.
8. Ensure landing/help are server-rendered with real content.
9. Add smoke tests.
10. Deploy, verify curls, submit sitemap.

Full code templates: [reference.md](reference.md).

---

## Workflow C — Fix common regressions

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Sign-in page in Google | In sitemap or missing noindex | Remove from sitemap; `noIndex: true` |
| Empty landing in Search Console | Client-only render / auth loading shell | Server-render marketing; defer auth redirect |
| Wrong URL in OG/sitemap | Missing `NEXT_PUBLIC_*_URL` in prod | Set env var; redeploy |
| Duplicate titles | Layout + page both set full title | Use `Page \| Site` pattern in helper only |
| Rich results error on FAQ | JSON-LD doesn't match visible FAQ | Sync FAQ data source |
| Social preview broken | OG image 404 or wrong path | Fix `opengraph-image.tsx`; check metadata paths |

More mistakes: [mistakes.md](mistakes.md).

---

## Audit report format

When reporting to the user:

```markdown
# SEO Audit — [Site Name] — [date]

## Summary
[1–2 sentences: overall health + top priority fixes]

## Scorecard
| Area | Status | Notes |
|------|--------|-------|
| Metadata | Pass/Fail | ... |
| Crawl rules | Pass/Fail | ... |
| Sitemap | Pass/Fail | ... |
| JSON-LD | Pass/Fail | ... |
| Content | Pass/Fail | ... |
| Tests | Pass/Fail | ... |

## Critical fixes (do first)
1. ...

## Recommended improvements
1. ...

## Verified production
- [ ] sitemap.xml 200
- [ ] robots.txt 200
- [ ] / noindex absent
- [ ] /sign-in noindex present
```

---

## File layout (recommended)

```
lib/
  seo.ts              # createPageMetadata, JSON-LD helpers, absoluteUrl
  public-routes.ts    # sitemap entries, robots disallow, auth patterns
  help-catalog.ts     # help articles → sitemap + index (optional)
app/
  layout.tsx          # metadataBase, SiteJsonLd
  robots.ts
  sitemap.ts
  opengraph-image.tsx
  manifest.ts
components/seo/
  site-json-ld.tsx
  help-page-json-ld.tsx   # WebPage + Breadcrumb + optional FAQ
__tests__/unit/
  seo.test.ts
```

---

## Additional resources

- [reference.md](reference.md) — Code templates, JSON-LD types, smoke test spec, env vars
- [audit-checklist.md](audit-checklist.md) — Exhaustive line-by-line review list
- [mistakes.md](mistakes.md) — Anti-patterns learned from production
- [examples.md](examples.md) — Before/after fixes

Reference implementation repos: `seo-guide` (minimal guide site), Scriptor `apps/web` (full SaaS pattern).
