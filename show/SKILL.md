---
name: show
description: Capture PNG or WebM into repo snapshots/ — desktop web via Playwright; iOS/Android/native apps via Maestro only (never browser for mobile). Use for "/show me", snapshot, screenshot, record, demo, or mobile app screen captures.
---

# Show (Snapshot or video)

Save a **PNG** or **WebM** under `snapshots/` and return a clickable path. Do not promise inline chat media; browser MCP "Captured screenshot" chips are unreliable.

Works in **any** git repo.

## Trigger

- `/show me <target>`
- `show me <target>`, `snapshot`, `screenshot`, `record`, `demo`, `walkthrough`

`<target>`: desktop **URL** / `localhost` (Playwright), **native app** or **simulator** screen (Maestro only), local file path, or flow description.

## Step 1 — Repo setup (always)

1. Find git repo root (walk up for `.git`; else use workspace cwd).
2. Create `snapshots/` if missing.
3. Append `snapshots/` to `.gitignore` if not already there.

## Step 2 — Image or video? (agent decides)

**Mobile / iOS / Android / app / simulator → Maestro only.** Never Playwright, browser MCP, or Chromium for these. No `--device` emulation.

| Intent | Tool | Output |
| --- | --- | --- |
| Native app (Expo, RN, etc.) | Maestro `takeScreenshot` | PNG |
| Specific app screen | Maestro flow (tap/scroll → screenshot) | PNG |
| App motion / walkthrough | Maestro `record` — optional | ask user |

**Desktop web** (URL, no mobile/simulator intent) → Playwright below.

**Prefer PNG** when a single frame is enough:

- hero, card, modal open, layout, dark mode, "what does X look like"

**Not** for mobile app screens — use Maestro (below).

**Prefer WebM video** when motion or sequence matters:

- click flow, navigation, form submit, animation, scroll behavior, before→after interaction
- "how it works", "walk me through", "demo the flow", "record", "video"
- verifying a bug reproduction with steps
- multi-step UI (open menu → filter → open detail)

User asked only for a static look → PNG. User asked for a flow or you need motion to explain → video.

Can return **both** if the user asked for a demo **and** a reference still (save two files; reply with two markdown links, one per line).

## Step 3 — Capture

No fixed script. Pick tools by job.

### PNG — Playwright (desktop web only)

For **URLs and localhost** on desktop. **Do not** use for mobile, iOS, Android, or native apps.

```bash
npx playwright screenshot "<url>" "snapshots/<slug>-<timestamp>.png"
npx playwright screenshot --full-page "<url>" "snapshots/<slug>-<timestamp>.png"
npx playwright screenshot --color-scheme dark "<url>" "snapshots/<slug>-dark-<timestamp>.png"
```

### PNG — Maestro (mobile / native only)

**All iOS Simulator, Android emulator, and native app captures.** Never route these through a browser automation tool.

**Prerequisites:** `maestro` CLI installed ([install](https://docs.maestro.dev/getting-started/installing-maestro)); iOS Simulator or Android emulator running (`maestro start-device --platform=ios` / `android` if needed).

**App ID:** from `app.json` / `app.config.*` — `ios.bundleIdentifier`, `android.package`. Expo: `npx expo config --type public` if unsure.

**Simple capture** (launch → screenshot):

```bash
TS=$(date -u +%Y-%m-%dT%H-%M-%S)
OUT="snapshots/maestro-${TS}"
mkdir -p "$OUT"
maestro test ~/.cursor/skills/show/scripts/maestro-screenshot.flow.yaml \
  -e APP_ID=com.example.app \
  -e SHOT_NAME=show-capture \
  --test-output-dir "$OUT"
mv "$OUT/show-capture.png" "snapshots/<slug>-ios-${TS}.png"
```

**Specific screen** (navigate first): write a one-off flow under `snapshots/_show.flow.yaml` (gitignored with `snapshots/`), or reuse project `.maestro/` flows:

```yaml
appId: com.example.app
---
- launchApp
- tapOn: Settings
- takeScreenshot:
    path: settings-screen
    cropOn:
      id: SettingsList   # optional element crop
```

```bash
maestro test snapshots/_show.flow.yaml --test-output-dir snapshots/maestro-out
```

Then move the PNG to `snapshots/<slug>-<platform>-<timestamp>.png`.

**Prefer existing flows:** if the repo has `.maestro/*.yaml`, run or extend those instead of inventing selectors.

**Maestro not installed:** one line — install link; do **not** fall back to Playwright or browser MCP for native/mobile.

### WebM — session recording

**Quick flows:** Playwright CLI (`video-start` / click / `video-stop`).

**Polished flows (preferred for demos):** `page.screencast` via `npx playwright-cli run-code --filename script.js`. Template: `~/.cursor/skills/show/scripts/screencast-template.js`.

#### Quality

- **1920×1080** for HQ demos — match viewport + `screencast.start({ size })`.
- **1280×800** for smaller files.
- Never use default `video-start` without `--size` (~800×800, blurry on wide sites).

#### Slow / frozen start (CLI)

CLI order `open` → `video-start` → long `sleep` → `snapshot` leaves dead air at the top. Fix:

- Use **`run-code`**: `screencast.start` → `goto` → move cursor within ~500ms.
- Skip chapter cards with long `--duration` unless the user wants them.
- No multi-second sleeps before the first visible action.

#### Pointer always visible

`video-show-actions --cursor pointer` only animates the cursor **between clicks**. For a cursor **on screen the whole time**:

1. `addInitScript` injects a fixed SVG pointer + `cursor: none` on the page (survives navigations).
2. Use `page.mouse.move(x, y, { steps: 30 })` before each action and sync overlay position in `evaluate`.
3. Do **not** download OS/Microsoft cursor assets.

See `~/.cursor/skills/show/scripts/screencast-template.js` or `record-labs-demo.js` (copy/adapt per flow).

#### CLI fallback (simple flows)

```bash
PLAYWRIGHT_MCP_VIEWPORT_SIZE=1920x1080 npx playwright-cli open "<url>"
npx playwright-cli resize 1920 1080
npx playwright-cli video-start "snapshots/<slug>.webm" --size=1920x1080
npx playwright-cli click e5
npx playwright-cli video-stop
```

If the file lands under `.playwright-cli/`, move it into `snapshots/`.

### Browser MCP

Desktop web PNG only when Playwright CLI is awkward. **Never** for native/mobile app captures — use Maestro.

For **video**, prefer `playwright-cli` (desktop web flows only).

### Local files

- Images: copy to `snapshots/`.
- HTML/PDF/SVG: open via `file://` — PNG or video per intent.

## Step 4 — Naming

- PNG: `{slug}-{variant}-{timestamp}.png`
- WebM: `{slug}-{flow}-{timestamp}.webm`

## Step 5 — Reply (minimal by default)

**Default:** one markdown link per artifact — clickable in chat:

```markdown
[snapshots/checkout-flow-2026-06-13T16-40-00.webm](snapshots/checkout-flow-2026-06-13T16-40-00.webm)
```

Two artifacts → two lines, links only.

No labels, summaries, or "open locally" reminders unless a row in the table below applies.

| Situation | OK to add |
| --- | --- |
| Capture failed or fallback used | Brief error |
| Login wall, 404, blank page | One line |
| User asked a question or invited discussion | Answer that part |
| Low-confidence guess on image vs video | One line |

## Cloud vs local (know the gap)

[Cursor Cloud Agents](https://cursor.com/docs/cloud-agent) run in a remote VM with computer use; they attach **polished walkthrough videos**, screenshots, and logs to PRs ([blog](https://cursor.com/blog/agent-computer-use)). That packaging is platform infrastructure.

**Locally**, the same *intent* is achievable: record the flow with `playwright-cli` → WebM in `snapshots/`. No Cursor logo outro, no PR attachment UI — just a file path in chat. Use **Cloud** when you want autonomous VM runs with built-in artifact UX; use **`/show`** for fast local captures in whatever repo you're in.

## Examples

**User:** `/show me the labs hero`  
→ PNG → `[snapshots/labs-hero-viewport-2026-06-13T16-24-56.png](snapshots/labs-hero-viewport-2026-06-13T16-24-56.png)`

**User:** `/show me how category pills work on labs`  
→ WebM (hover/click/filter if applicable) → `[snapshots/labs-category-pills-2026-06-13T16-40-00.webm](snapshots/labs-category-pills-2026-06-13T16-40-00.webm)`

**User:** `show me the checkout flow on localhost:3000`  
→ WebM with chapters → one link line

**User:** `/show me the Expo home screen on iOS`  
→ Maestro → `[snapshots/myapp-home-ios-….png](snapshots/myapp-home-ios-….png)`

**User:** `/show me settings on Android`  
→ Maestro → one PNG link

## Do not

- Use Playwright, browser MCP, or `--device` for mobile, iOS, Android, or native apps — **Maestro only**
- Default every URL to full-page PNG or always record video
- Replace PNG with video when a still is enough
- Claim chat will inline the PNG or WebM
- Commit under `snapshots/`
- Add narration when the user only asked for `/show`

## Dependencies

- PNG (desktop web): `npx playwright` + Chromium
- PNG (mobile / native): [Maestro CLI](https://docs.maestro.dev/getting-started/installing-maestro) + iOS Simulator or Android emulator
- Video (desktop web): `npx @playwright/cli`
