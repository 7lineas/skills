# SEO Reference — Code Templates & Technical Detail

## Environment variables

| Variable | Purpose |
|----------|---------|
| `NEXT_PUBLIC_APP_URL` or `NEXT_PUBLIC_SITE_URL` | Canonical production origin, no trailing slash issues — use `new URL(path, base)` |
| `NEXT_PUBLIC_SEO_LOCALE` | Optional; default `en_US` for Open Graph |
| Publisher name/URL | Organization JSON-LD; can be env-backed |

**Critical:** Without production URL in env, sitemap/JSON-LD may emit wrong host. Always verify in deployed build.

---

## `createPageMetadata()` template

```typescript
import type { Metadata } from "next";

export function createPageMetadata({
  title,
  description = SITE_DESCRIPTION,
  path = "/",
  noIndex = false,
}: {
  title?: string;
  description?: string;
  path?: string;
  noIndex?: boolean;
} = {}): Metadata {
  const pageTitle = title ? `${title} | ${SITE_NAME}` : SITE_TITLE;
  const ogImagePath = "/opengraph-image";

  return {
    title: pageTitle,
    description,
    alternates: { canonical: path },
    openGraph: {
      title: pageTitle,
      description,
      url: path,
      siteName: SITE_NAME,
      locale: SEO_LOCALE,
      type: "website",
      images: [
        { url: ogImagePath, width: 1200, height: 630, alt: `${SITE_NAME} — ${description}` },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: pageTitle,
      description,
      images: [ogImagePath],
    },
    robots: noIndex
      ? { index: false, follow: false, googleBot: { index: false, follow: false } }
      : {
          index: true,
          follow: true,
          googleBot: {
            index: true,
            follow: true,
            "max-image-preview": "large",
            "max-snippet": -1,
            "max-video-preview": -1,
          },
        },
  };
}
```

**Do not add:** `keywords`, duplicate `metadataBase` per page, full absolute URLs in `canonical` when using `metadataBase`.

---

## Root layout metadata

```typescript
export function generateMetadata(): Metadata {
  return {
    metadataBase: getSiteUrl(), // new URL(process.env.NEXT_PUBLIC_APP_URL)
    applicationName: SITE_NAME,
    authors: [{ name: PUBLISHER_NAME, url: PUBLISHER_URL }],
    creator: PUBLISHER_NAME,
    publisher: PUBLISHER_NAME,
    ...createPageMetadata({ description: SITE_DESCRIPTION }),
    icons: { icon: "/favicon.ico", apple: "/apple-icon.png" },
  };
}
```

Per-route pages override with `export const metadata = createPageMetadata({ ... })`.

Auth pages:

```typescript
export const metadata = createPageMetadata({
  title: "Sign in",
  path: "/sign-in",
  noIndex: true,
});
```

Workspace layout:

```typescript
export const metadata = createPageMetadata({ noIndex: true });
```

---

## `public-routes.ts` template

```typescript
export const PUBLIC_SEO_SITEMAP_ENTRIES = [
  { path: "/", changeFrequency: "weekly" as const, priority: 1 },
  { path: "/help", changeFrequency: "monthly" as const, priority: 0.6 },
  // ... help articles from catalog
  { path: "/privacy", changeFrequency: "yearly" as const, priority: 0.4 },
  { path: "/terms", changeFrequency: "yearly" as const, priority: 0.4 },
] as const;

export const PUBLIC_AUTH_ROUTE_PATTERNS = [
  "/",
  "/sign-in(.*)",
  "/sign-up(.*)",
  "/help(.*)",
  "/privacy(.*)",
  "/terms(.*)",
  "/robots.txt",
  "/sitemap.xml",
  "/manifest.webmanifest",
  "/opengraph-image",
  "/opengraph-image(.*)",
] as const;

export const ROBOTS_DISALLOW_PATHS = [
  "/api/",
  "/p/",           // user pages — adjust to your app
  "/library/",     // authenticated library
  "/__clerk/",
] as const;
```

**Sitemap rule:** If a route is in `ROBOTS_DISALLOW_PATHS` or has `noIndex`, it must **not** appear in `PUBLIC_SEO_SITEMAP_ENTRIES`.

---

## `robots.ts`

```typescript
import type { MetadataRoute } from "next";
import { ROBOTS_DISALLOW_PATHS } from "@/lib/public-routes";
import { absoluteUrl } from "@/lib/seo";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", disallow: [...ROBOTS_DISALLOW_PATHS] },
    sitemap: absoluteUrl("/sitemap.xml"),
  };
}
```

---

## `sitemap.ts`

```typescript
import type { MetadataRoute } from "next";
import { PUBLIC_SEO_SITEMAP_ENTRIES } from "@/lib/public-routes";
import { absoluteUrl } from "@/lib/seo";

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date();
  return PUBLIC_SEO_SITEMAP_ENTRIES.map((route) => ({
    url: absoluteUrl(route.path),
    lastModified,
    changeFrequency: route.changeFrequency,
    priority: route.priority,
  }));
}
```

For large sites: split sitemaps or paginate. For small SaaS (<100 URLs), single sitemap is fine.

---

## JSON-LD schemas

### Site-wide (root layout)

| Schema | When |
|--------|------|
| `Organization` | Always — real publisher |
| `WebSite` | Always — site name + url |
| `SoftwareApplication` | SaaS/product sites only |

```typescript
export function softwareApplicationSchema() {
  return {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: SITE_NAME,
    applicationCategory: "BusinessApplication",
    applicationSubCategory: "ProductivityApplication",
    operatingSystem: "Web",
    url: siteUrl,
    inLanguage: "en",
    description: SITE_DESCRIPTION,
    publisher: { "@type": "Organization", name: PUBLISHER_NAME, url: PUBLISHER_URL },
    // NO offers unless real pricing page exists
  };
}
```

### Per help/doc page

```typescript
export function webPageSchema({ path, title, description }) { /* ... */ }
export function breadcrumbListSchema(items: { name: string; path: string }[]) { /* ... */ }
export function faqPageSchema(items: { question: string; answer: string }[]) { /* ... */ }
```

### Rendering component

```tsx
export function JsonLd({ schema }: { schema: Record<string, unknown> }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  );
}

// Multiple schemas: one script tag per @type OR array — both valid; separate tags easier to debug
```

### FAQ data source

Keep FAQ in one file (e.g. `faq.ts`); use same array for visible `<dl>` and `faqPageSchema()`.

---

## Open Graph image

`app/opengraph-image.tsx`:

```tsx
import { ImageResponse } from "next/og";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpenGraphImage() {
  return new ImageResponse(
    (<div style={{ /* flex layout, brand colors, title, tagline */ }}>...</div>),
    { ...size },
  );
}
```

- Use inline styles only (no Tailwind in OG JSX).
- Avoid special characters that break JSX parsing in taglines.
- Twitter card `summary_large_image` reuses this URL — no separate file required.

---

## Landing page pattern (auth-aware SaaS)

**Problem:** Client-only `useAuth()` landing shows loading spinner → Google indexes empty page.

**Solution:**

```tsx
// app/page.tsx — Server Component
export const metadata = createPageMetadata({ path: "/" });

export default async function RootPage({ searchParams }) {
  // Optional: redirect authenticated users server-side
  return <LandingMarketing authSuffix={...} />;
}
```

- `LandingMarketing` = Server Component with static marketing sections (hero, features, FAQ).
- Auth redirect / One Tap = small Client Component child, not wrapping entire page content.
- Crawlers receive full HTML without executing auth.

---

## Help center catalog

```typescript
// lib/help-catalog.ts
export const HELP_ARTICLES = [
  {
    slug: "getting-started",
    title: "Getting started",
    description: "...",
    changeFrequency: "monthly" as const,
    priority: 0.5,
  },
  // ...
] as const;
```

- Help index reads catalog for links.
- Sitemap spreads catalog into entries.
- Each article page exports metadata + `HelpPageJsonLd`.

---

## Smoke tests

File: `__tests__/unit/seo.test.ts`

**Invariants to lock:**

1. `createPageMetadata` — title format, canonical, OG image dimensions, twitter card, robots index true
2. `createPageMetadata({ noIndex: true })` — index false
3. No `keywords` property on metadata
4. Sitemap paths contain `/`, `/help`, legal, all help slugs
5. Sitemap paths exclude `/sign-in`, `/sign-up`
6. `ROBOTS_DISALLOW_PATHS` includes api, app, clerk paths
7. `PUBLIC_AUTH_ROUTE_PATTERNS` includes SEO + auth entry routes
8. `siteJsonLdSchemas()` types = Organization, WebSite, SoftwareApplication
9. `softwareApplicationSchema()` has no `offers`
10. `breadcrumbListSchema` / `faqPageSchema` structure

---

## Priority & changeFrequency guidelines

| Route type | priority | changeFrequency |
|------------|----------|-----------------|
| Home | 1.0 | weekly |
| Help index | 0.6 | monthly |
| Help articles | 0.5 | monthly |
| Legal | 0.4 | yearly |
| Blog posts | 0.7 | weekly/monthly |

Google largely ignores `priority`; keep it sane for human maintenance.

---

## Google Search Console ops

1. Add property → domain or URL prefix
2. Verify via DNS TXT (preferred) or HTML file
3. Sitemaps → submit `https://domain/sitemap.xml`
4. Monitor: Coverage, Page indexing, Core Web Vitals
5. "Couldn't fetch" + live 200 → wait 24–48h or resubmit

Optional: URL Inspection → "Request indexing" for home after major relaunch (not required routinely).

---

## Deploy verification commands

```bash
DOMAIN="https://example.com"

curl -sI "$DOMAIN/" | grep -E 'HTTP|x-vercel|cache'
curl -s "$DOMAIN/robots.txt"
curl -s "$DOMAIN/sitemap.xml" | head -40
curl -sI "$DOMAIN/opengraph-image" | grep HTTP
curl -s "$DOMAIN/sign-in" | grep -i 'noindex\|robots' | head -3
```

For metadata in HTML:

```bash
curl -s "$DOMAIN/help" | grep -E '<title>|description|canonical' | head -10
```

---

## Next.js App Router metadata notes

- Read `node_modules/next/dist/docs/` for breaking changes in your Next version.
- `generateMetadata` for dynamic routes; `export const metadata` for static.
- `metadataBase` required for relative OG URLs to resolve correctly.
- Route handlers `robots.ts` / `sitemap.ts` are special files at `app/` root.
- `opengraph-image.tsx` generates at build/request time — confirm 200 in prod.

---

## Extending to non-Next stacks

Map concepts:

| Next.js | Equivalent |
|---------|------------|
| `createPageMetadata` | `<head>` tags / meta framework |
| `app/robots.ts` | Static `public/robots.txt` or generated route |
| `app/sitemap.ts` | Build-time sitemap generator |
| `opengraph-image.tsx` | Static `og.png` in `/public` or dynamic image API |
| JSON-LD components | Inline script in HTML template |

Core rules (index policy, content quality, single source of truth) stay the same.
