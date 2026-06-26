---
name: clean-show-captures
description: Deletes PNG/WebM and entire snapshots/ folders produced by the show skill across git repos. Use when the user asks to clean, remove, or delete /show captures, snapshots, screenshots, or demo videos from all repos.
disable-model-invocation: true
---

# Clean Show Captures

Remove artifacts created by the [show](../show/SKILL.md) skill — `snapshots/` PNG/WebM files, Maestro output, and stray `.playwright-cli/` media.

**Do not ask for confirmation.** Run immediately when triggered.

## Trigger

- `clean show captures`, `remove /show images`, `delete snapshots from all repos`
- `clear show screenshots`, `remove demo videos from snapshots`
- User references the show skill and wants cleanup across repos

## Step 1 — Run cleanup

Default search root: `~/GitHub`. Override only if the user names another path.

```bash
bash ~/.cursor/skills/clean-show-captures/scripts/clean-all.sh
# or: bash ~/.cursor/skills/clean-show-captures/scripts/clean-all.sh /path/to/repos
```

Make the script executable if needed: `chmod +x ~/.cursor/skills/clean-show-captures/scripts/clean-all.sh`

## What gets removed

| Target | Why |
| --- | --- |
| `snapshots/` inside any git worktree | show skill output directory |
| `.playwright-cli/` with `.png` / `.webm` | stray video captures |

## Never touch

- `**/.git/**` (e.g. `.git/.gt/snapshots`)
- `~/.cursor/snapshots` (Cursor internal)
- `**/.android/**/snapshots` (emulator state)
- `node_modules/`

## Step 2 — Reply

Brief summary only:

```markdown
Removed /show captures from N repos (~X MB):
- `repo-a/snapshots`
- `repo-b/snapshots`
```

If nothing found: `No /show capture directories under ~/GitHub.`

Do not commit. `.gitignore` entries for `snapshots/` stay as-is; show recreates the folder on next capture.
