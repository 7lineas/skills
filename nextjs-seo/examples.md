# SEO Examples — Before & After

Concrete patterns agents should recognize and apply.

---

## Example 1: Auth page indexing

### Before (bad)

```typescript
// sitemap includes sign-in
export const PUBLIC_SEO_SITEMAP_ENTRIES = [
  { path: "/", ... },
  { path: "/sign-in", changeFrequency: "monthly", priority: 0.8 },
];

// sign-in/page.tsx
export const metadata = createPageMetadata({ title: "Sign in", path: "/sign-in" });
```

### After (good)

```typescript
// public-routes.ts — no sign-in in sitemap
export const PUBLIC_SEO_SITEMAP_ENTRIES = [
  { path: "/", ... },
  // sign-in deliberately omitted
];

// sign-in/page.tsx
export const metadata = createPageMetadata({
  title: "Sign in",
  path: "/sign-in",
  noIndex: true,
});
```

---

## Example 2: Client-only landing

### Before (bad)

```tsx
"use client";
export default function Home() {
  const { isLoaded, userId } = useAuth();
  if (!isLoaded) return <Spinner />;
  if (userId) redirect("/p");
  return <LandingContent />;
}
```

Crawler sees: spinner or empty shell.

### After (good)

```tsx
// app/page.tsx — Server Component
import { LandingMarketing } from "@/components/landing/landing-marketing";

export const metadata = createPageMetadata({ path: "/" });

export default function Home() {
  return (
    <>
      <LandingMarketing />
      <LandingAuthRedirect />
    </>
  );
}
```

`LandingMarketing` = server HTML with H1, features, FAQ. `LandingAuthRedirect` = small client piece.

---

## Example 3: Fake SoftwareApplication offers

### Before (bad)

```typescript
return {
  "@type": "SoftwareApplication",
  name: "MyApp",
  offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
  aggregateRating: { ratingValue: "4.9", reviewCount: "1000" },
};
```

### After (good)

```typescript
return {
  "@type": "SoftwareApplication",
  name: "MyApp",
  applicationCategory: "BusinessApplication",
  operatingSystem: "Web",
  url: siteUrl,
  description: SITE_DESCRIPTION,
  publisher: publisherOrganizationNode(),
};
```

Add offers only when public pricing page with real prices exists.

---

## Example 4: FAQ schema drift

### Before (bad)

```tsx
// JSON-LD
faqPageSchema([{ question: "Is it free?", answer: "Yes, forever!" }])

// Visible page — different text or no FAQ section
<p>Contact sales for pricing.</p>
```

### After (good)

```typescript
// faq.ts
export const PAGE_FAQ = [
  { question: "How do I share a page?", answer: "Open Share in the top right..." },
] as const;
```

```tsx
// page.tsx
{PAGE_FAQ.map(({ question, answer }) => (
  <div key={question}>
    <h3>{question}</h3>
    <p>{answer}</p>
  </div>
))}
<HelpPageJsonLd faq={PAGE_FAQ} ... />
```

---

## Example 5: Adding a new help article (end-to-end)

1. Add to catalog:

```typescript
// lib/help-catalog.ts
{
  slug: "databases",
  title: "Databases",
  description: "Create linked databases, views, and filters in Scriptor.",
  changeFrequency: "monthly",
  priority: 0.5,
}
```

2. Create page:

```tsx
// app/help/databases/page.tsx
export const metadata = createPageMetadata({
  title: "Databases",
  description: "Create linked databases...",
  path: "/help/databases",
});

export default function Page() {
  return (
    <>
      <HelpPageJsonLd
        path="/help/databases"
        title="Databases"
        description="..."
        breadcrumbs={[...]}
      />
      <article>...</article>
    </>
  );
}
```

3. Sitemap auto-includes via catalog spread — no sitemap.ts edit.

4. Add test expectation if slug list is asserted.

5. Deploy → verify URL in sitemap.xml.

---

## Example 6: Audit report snippet

```markdown
# SEO Audit — Acme App — 2026-06-12

## Summary
Metadata and sitemap are solid. Critical fix: `/sign-up` missing noindex. Help center strong; add smoke tests.

## Scorecard
| Area | Status | Notes |
|------|--------|-------|
| Metadata | Fail | sign-up indexable |
| Crawl rules | Pass | robots disallow /p/ |
| Sitemap | Pass | 8 URLs, no auth |
| JSON-LD | Pass | no fake offers |
| Content | Pass | server-rendered landing |
| Tests | Fail | no seo.test.ts |

## Critical fixes
1. Add `noIndex: true` to sign-up metadata
2. Add `__tests__/unit/seo.test.ts` from reference template
```

---

## Example 7: Smoke test addition for new route

When adding `/pricing` to sitemap:

```typescript
it("includes pricing in sitemap", () => {
  const paths = PUBLIC_SEO_SITEMAP_ENTRIES.map((e) => e.path);
  expect(paths).toContain("/pricing");
});

it("indexes pricing page", () => {
  const md = createPageMetadata({ title: "Pricing", path: "/pricing" });
  expect(md.robots).toEqual(expect.objectContaining({ index: true }));
});
```

Only add `/pricing` to sitemap if page is public and indexable — not if checkout is auth-gated.
