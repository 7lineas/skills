# Dev accounts — MCP inventory

Installed MCP servers in this Cursor workspace (check `mcps/` tool schemas before calling).

## Convex (`plugin-convex-convex`)

- `status`, `tables`, `data`, `functionSpec`, `run`, `runOneoffQuery`
- `logs`, `insights`
- `envList`, `envGet`, `envSet`, `envRemove`

## Vercel (`plugin-vercel-vercel`)

- `list_projects`, `get_project`, `list_deployments`, `get_deployment`
- `get_deployment_build_logs`, `get_runtime_logs`
- `deploy_to_vercel`, `list_teams`
- `search_vercel_documentation`, `web_fetch_vercel_url`, `get_access_to_vercel_url`
- Toolbar thread tools (review UI)

## Cloudflare

**Bindings** (`plugin-cloudflare-cloudflare-bindings`): Workers list/get/code, D1, R2, KV, Hyperdrive, docs search

**Builds** (`plugin-cloudflare-cloudflare-builds`): Workers builds, build logs

**Observability** (`plugin-cloudflare-cloudflare-observability`): `query_worker_observability`, keys/values

**Docs** (`plugin-cloudflare-cloudflare-docs`): documentation search

## Notion (`plugin-notion-workspace-notion`)

- `notion-search`, `notion-fetch`
- `notion-create-pages`, `notion-update-page`, `notion-move-pages`, `notion-duplicate-page`
- `notion-create-database`, `notion-update-data-source`
- `notion-create-view`, `notion-update-view`
- Comments, users, teams

## Linear (`user-linear`, `plugin-linear-linear`)

Issues, projects, documents, comments, attachments, cycles, milestones, diffs, labels, statuses

## GitHub (`user-Github`)

Repos, files, branches, commits, issues, PRs, reviews, search (code/issues/users)

## Resend (`plugin-resend-resend`)

Send email, templates, webhooks, topics, segments, logs, received mail, broadcasts

## Clerk (`plugin-clerk-clerk`)

- `list_clerk_sdk_snippets`, `clerk_sdk_snippet` only — **not** a dashboard API

## Stripe (`plugin-stripe-stripe`)

- `mcp_auth` — authenticate plugin for expanded access

## WorkOS

- **No MCP server** — use browser → https://dashboard.workos.com
- WorkOS **skill plugin** available for implementation guidance

## shadcn (`plugin-shadcn-shadcn`)

Component registry search/add — not a hosted account

## Google Cloud Console

- **No MCP server** — use browser → https://console.cloud.google.com
- Typical tasks: project picker, IAM & admin, enabled APIs, Cloud Run / GKE / Cloud Functions, BigQuery, Cloud Storage, Secret Manager, billing, quotas
- Pick the correct Google account and project before reporting; deep links often need `?project=<id>`
- **`gcloud` CLI** when available: `gcloud config list`, `gcloud projects list`, `gcloud run services list`, etc.

## Google Play Console

- **No MCP server** — use browser → https://play.google.com/console
- Typical tasks: production/internal testing tracks, release status, Android vitals, crashes, store listing, policy issues, app signing
- Google account login required; may need to pick the correct developer account and app

## Google Search Console

- **No MCP server** — use browser → https://search.google.com/search-console
- Typical tasks: URL inspection, indexing/coverage, sitemaps, Core Web Vitals, search performance, manual actions
- Pick the correct property (domain vs URL-prefix) before reporting

## Cursor (`cursor-app-control`, `cursor-ide-browser`)

- App control: open files, Glass, automations
- Browser: navigate, snapshot, screenshot, CDP

## Other CLI

- `gh` — GitHub from terminal (PRs, CI, releases)
- `npx convex`, `vercel`, `wrangler` — when MCP or browser is insufficient
