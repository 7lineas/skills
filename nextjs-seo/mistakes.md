# SEO Mistakes & Anti-Patterns

Learned from production SaaS (Scriptor) and common Next.js pitfalls. Agents should scan for these during every audit.

---

## Critical (fix before considering SEO "done")

### 1. Auth pages in sitemap or indexable

**Symptom:** `/sign-in` appears in Google; sitemap lists auth routes.

**Fix:** Remove from `PUBLIC_SEO_SITEMAP_ENTRIES`; add `noIndex: true` on sign-in/sign-up metadata.

**Why both:** robots disallow alone does not remove URLs already discovered; noindex is the definitive signal.

---

### 2. Landing page is a loading shell for crawlers

**Symptom:** View-source on `/` shows spinner or empty div; marketing copy only after client JS + auth check.

**Fix:** Server-render `LandingMarketing` as Server Component; isolate client auth redirect to a small child.

**Test:** `curl -s https://domain/ | grep -i "your product headline"` should match visible H1 text.

---

### 3. Missing production URL env var

**Symptom:** Sitemap shows `localhost`, vercel preview URL, or wrong domain; OG tags broken on social.

**Fix:** Set `NEXT_PUBLIC_APP_URL` in production; use in `getSiteUrl()` / `metadataBase`.

---

### 4. Fake structured data

**Symptom:** `SoftwareApplication` with `offers`, price `0`, or fabricated `aggregateRating`.

**Fix:** Remove offers unless real checkout/pricing page exists. Google penalizes rich-result spam.

---

### 5. FAQ JSON-LD doesn't match page

**Symptom:** Rich Results Test warning; FAQ schema questions not visible on page.

**Fix:** Single source of truth array — render FAQ UI and JSON-LD from same data.

---

## High impact

### 6. `keywords` meta tag

**Symptom:** `<meta name="keywords" ...>` in layout.

**Fix:** Remove. No SEO benefit; signals outdated SEO practice.

---

### 7. Duplicate titles/descriptions

**Symptom:** Every help page says "Help | Product"; all descriptions identical.

**Fix:** Per-page `createPageMetadata({ title, description, path })` from catalog.

---

### 8. Workspace/app routes indexable

**Symptom:** User pages `/p/[id]` in Google; workspace layout missing noindex.

**Fix:** `noIndex` on workspace layout; `disallow: /p/` in robots.

---

### 9. robots.txt blocks too much or too little

**Too much:** `Disallow: /` — site won't rank.

**Too little:** API and private app crawlable — wastes crawl budget, leaks URLs.

**Fix:** Disallow-only list for known private prefixes; don't add redundant Allow rules.

---

### 10. Non-standard robots directives

**Symptom:** `Host:` directive (Yandex-specific, ignored/misleading elsewhere).

**Fix:** Remove; use canonical tags and Search Console preferred domain.

---

## Medium impact

### 11. Relative vs absolute canonical confusion

**Symptom:** Canonical shows wrong path or double domain.

**Fix:** Relative path in metadata + `metadataBase` in root layout. Use `absoluteUrl()` only for sitemap/JSON-LD.

---

### 12. OG image 404 or wrong dimensions

**Symptom:** Social shares show no image; image not 1200×630.

**Fix:** `app/opengraph-image.tsx`; verify `curl -sI .../opengraph-image`.

---

### 13. Twitter-specific image when unnecessary

**Symptom:** Maintaining duplicate `twitter-image.tsx`.

**Fix:** `summary_large_image` + same OG URL is sufficient for most brands. Add twitter-image only if different crop needed.

---

### 14. Twitter `@site` handle assumed required

**Symptom:** Placeholder `@yourcompany` in metadata.

**Fix:** Omit `twitter:site` unless real active account.

---

### 15. Client-only metadata

**Symptom:** `useEffect` setting document.title on marketing pages.

**Fix:** Use Next.js `export const metadata` or `generateMetadata` — metadata in server HTML.

---

### 16. Help articles not in sitemap catalog

**Symptom:** New help page shipped but not discoverable; manual sitemap edit forgotten.

**Fix:** `HELP_ARTICLES` catalog drives sitemap + index page.

---

### 17. Sign-in in sitemap "for discoverability"

**Symptom:** Product manager asked to list sign-in in sitemap.

**Fix:** Never. Users find sign-in via CTAs and nav; Google should not index login forms.

---

## Low impact / polish

### 18. Stale `lastModified` everywhere identical

**Acceptable** for small sites using build time. Improve later with git or CMS timestamps per article.

---

### 19. Missing manifest / apple icons

**Impact:** PWA install + mobile bookmark polish, minor trust signal.

---

### 20. Legal pages without JSON-LD

**OK.** WebPage schema optional for privacy/terms.

---

### 21. Over-engineering hreflang on single-language site

**Fix:** Don't add hreflang until multiple locales ship.

---

## Process mistakes

### 22. SEO review only in dev

**Fix:** Always curl **production** after deploy. Preview URLs may differ.

---

### 23. No automated smoke tests

**Fix:** `seo.test.ts` locks invariants; run in CI.

---

### 24. Submitting sitemap before deploy completes

**Symptom:** GSC "Couldn't fetch" briefly.

**Fix:** Deploy first, verify 200, then submit. Recheck in 24h.

---

### 25. Requesting indexing for every page manually

**Fix:** Sitemap + internal links sufficient for small sites. Use URL Inspection sparingly for home after major relaunch.

---

## Quick scan command bundle

```bash
# Auth in sitemap?
curl -s "https://DOMAIN/sitemap.xml" | grep -E 'sign-in|sign-up' && echo "FAIL" || echo "OK"

# noindex on sign-in?
curl -s "https://DOMAIN/sign-in" | grep -i noindex | head -1

# keywords meta?
curl -s "https://DOMAIN/" | grep -i 'name="keywords"' && echo "FAIL" || echo "OK"

# landing has content?
curl -s "https://DOMAIN/" | grep -o '<h1[^>]*>[^<]*' | head -1
```
