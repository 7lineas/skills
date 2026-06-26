---
name: dev-accounts
description: Guides agents on accessing the user's dev service accounts via Cursor MCP plugins and logged-in browser dashboards (Convex, Vercel, Clerk, Cloudflare, Notion, WorkOS, Stripe, Linear, GitHub, Resend, Google Cloud Console, Google Play Console, Google Search Console). Use when checking deployments, env vars, auth settings, logs, billing, GCP projects/APIs, app store releases, SEO/indexing, or any vendor console — or when the user mentions a dev dashboard or "my account on X".
---

# Dev accounts (MCP + browser)

The user’s dev accounts are reachable in Cursor through **MCP plugins** (preferred) and the **browser** (dashboard UI, visual checks, gaps MCP does not cover). Assume sessions may already be logged in; if a login wall appears, stop and ask the user to sign in in the browser tab — do not guess credentials.

## Decision order

1. **MCP** — deployments, logs, data, env vars, issues, docs search, Notion CRUD.
2. **Browser** — UI-only settings, visual verification, WorkOS/Clerk dashboard tasks MCP cannot do, multi-step console flows.
3. **`@show`** — snapshot or record a console view for the user ([show skill](../show/SKILL.md)).

## Rules

- **Notion:** broad permission to search, read, create, edit without asking first (user preference).
- Never paste secrets, API keys, or tokens into chat, commits, or repo files.
- Prefer read/inspect before destructive console changes; confirm with the user for billing, deletes, or production toggles.
- GitHub CLI (`gh`) is also available for PRs, issues, checks.

## Quick console URLs

| Service | Dashboard |
| --- | --- |
| Convex | https://dashboard.convex.dev |
| Vercel | https://vercel.com/dashboard |
| Clerk | https://dashboard.clerk.com |
| Cloudflare | https://dash.cloudflare.com |
| Notion | https://www.notion.so |
| WorkOS | https://dashboard.workos.com |
| Stripe | https://dashboard.stripe.com |
| Linear | https://linear.app |
| GitHub | https://github.com |
| Resend | https://resend.com |
| Google Cloud Console | https://console.cloud.google.com |
| Google Play Console | https://play.google.com/console |
| Google Search Console | https://search.google.com/search-console |

## MCP vs browser (summary)

| Service | MCP | Browser when |
| --- | --- | --- |
| **Convex** | Strong — status, tables, data, logs, env, run functions | Visual data browser, settings MCP lacks |
| **Vercel** | Strong — projects, deployments, build/runtime logs, deploy | Team/billing UI, design toolbar flows |
| **Cloudflare** | Strong — Workers, D1, R2, KV, Hyperdrive, observability, builds | Account DNS, Pages UI, billing |
| **Notion** | Strong — search, fetch, pages, databases | Layout preview, permissions UI |
| **Linear** | Strong — issues, projects, docs, comments | Board views, settings |
| **GitHub** | Strong — repos, PRs, issues, code search | Actions UI, org settings, merge UI |
| **Clerk** | Weak — SDK snippets only | Users, orgs, JWT templates, webhooks, instances |
| **WorkOS** | None installed | AuthKit, SSO, Directory Sync, orgs — browser primary |
| **Stripe** | Auth-gated MCP plugin | Connect, products, invoices when MCP unavailable |
| **Resend** | Strong — send, templates, webhooks, logs | Domain DNS verification UI |
| **Google Cloud Console** | None installed | Projects, IAM, APIs, Cloud Run, GKE, BigQuery, billing, secrets — browser primary; `gcloud` CLI when faster |
| **Google Play Console** | None installed | Releases, store listing, crashes, ratings, policy — browser primary |
| **Google Search Console** | None installed | Indexing, sitemaps, coverage, performance, URL inspection — browser primary |

Full tool inventory: [reference.md](reference.md)

## Browser workflow

```text
1. browser_navigate → console URL (or deep link if known)
2. browser_snapshot → read page state
3. interact (click, fill) only when needed
4. @show for PNG/WebM proof if user wants a capture
```

For long console demos, use the **show** skill’s `run-code` screencast pattern (1920×1080, persistent cursor).

## Examples

- “What env vars are on Convex dev?” → Convex MCP `envList`, not browser.
- “Is labs deployed on Vercel?” → Vercel MCP `list_deployments` / `get_deployment`.
- “Add a redirect in Cloudflare” → browser to dash.cloudflare.com if no MCP tool fits.
- “Show me Clerk users for this app” → browser (MCP is snippets-only).
- “WorkOS SSO connection status” → browser → dashboard.workos.com.
- “Screenshot my Vercel deployment” → `@show` on deployment URL or Vercel preview.
- “Which GCP project is billing on?” → browser → console.cloud.google.com → Billing, or `gcloud config get-value project`.
- “Enable Cloud Run API” → browser → APIs & Services, or `gcloud services enable run.googleapis.com`.
- “Check Play Console crash rate” → browser → play.google.com/console → select app.
- “Is labs.7lineas.com indexed?” → browser → Search Console → URL inspection or Pages report.

## Do not

- Assume MCP is unavailable without checking tool descriptors first
- Store or commit dashboard exports with secrets
- Click destructive actions (delete project, rotate prod keys) without explicit user approval
