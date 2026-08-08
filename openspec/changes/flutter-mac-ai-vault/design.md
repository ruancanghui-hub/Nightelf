## Context

Greenfield Flutter macOS app. See `proposal.md` for motivation and scope. Specs define observable behavior for shell, vault, and five resource libraries. Design below chooses the technical approach for a local-first, Obsidian-like vault.

## Goals / Non-Goals

**Goals:**
- Local vault as source of truth (files on disk)
- Shared library UX across resource types with type-specific editors
- Stable folder conventions so Git / Finder / other tools can coexist
- Ship a usable macOS MVP with create/open vault, favorites, collections, search, and CRUD for all five resource types

**Non-Goals:**
- Cloud sync, multi-device conflict resolution
- In-app LLM chat or running MCP servers inside the app
- Plugin marketplace or third-party extension API (v1)
- Windows / Linux / iOS / Android targets in this change
- Full Obsidian plugin/graph/canvas parity

## Decisions

### 1. Flutter macOS desktop (not Electron / SwiftUI-only)
- **Choice:** Flutter with macOS desktop target.
- **Rationale:** Matches product request; one codebase if platforms expand later; good enough for file-centric UI.
- **Alternatives:** Electron (heavier, web stack), pure SwiftUI (best native feel, Mac-only forever).

### 2. Vault layout on disk
- **Choice:** Vault root contains:
  - `.ai-vault.json` — vault marker + version
  - `prompts/` — prompt documents (Markdown with YAML front matter for tags/description)
  - `skills/` — imported SKILL folders (one folder per skill)
  - `mcp/` — MCP config files (`.json`)
  - `links/` — link records (Markdown or YAML front matter with `url`)
  - `workflows/` — workflow documents (original extension preserved when imported; default `.md` or `.yml` for new)
  - `meta/favorites.json` — favorites list (paths relative to vault)
  - `meta/collections.json` — named collections → resource path lists
- **Rationale:** Clear type boundaries; metadata for favorites/collections does not rewrite foreign skill trees.
- **Alternatives:** Single SQLite DB (harder external edit), everything as freeform notes with typed front matter only (weaker type folders).

### 3. Skill import = copy into vault (default)
- **Choice:** Default import copies the SKILL folder into `skills/<name>/`. Optional later: “link / alias” to external path.
- **Rationale:** Vault remains portable and self-contained for v1.
- **Alternatives:** Symlink-only (fragile when moved), reference-by-path without copy (breaks offline portability).

### 4. Editors
- **Choice:** Shared text editor widget for prompts, MCP JSON, workflows, and skill text files; form fields for link URL/title/notes; JSON syntax check for MCP.
- **Rationale:** One editing primitive covers most types; links need URL validation UX.
- **Alternatives:** Full CodeMirror-class IDE embedding (overkill for MVP), separate rich WYSIWYG for prompts only (defer).

### 5. State & architecture
- **Choice:** Feature-first Flutter modules (`shell`, `vault`, `prompts`, `skills`, `mcp`, `links`, `workflows`) with a thin vault filesystem service; reactive UI state (e.g. Riverpod or equivalent already chosen at scaffold time).
- **Rationale:** Maps 1:1 to OpenSpec capabilities; keeps filesystem I/O testable behind interfaces.
- **Alternatives:** Single global BLoC, pure `setState` (doesn’t scale).

### 6. Autosave
- **Choice:** Debounced autosave for text documents + explicit Save shortcut (Cmd+S).
- **Rationale:** Feels Obsidian-like; reduces data loss.
- **Alternatives:** Manual save only (safer but friction), save-on-blur only.

## Risks / Trade-offs

- **[Risk] Large skill folders slow import / tree UI** → Cap import size warning; lazy-load tree children; progress indicator on import.
- **[Risk] External edits while app has file open** → On focus regain, detect mtime change and reload or prompt; v1 can be last-write-wins with a toast.
- **[Risk] Ambiguous workflow file formats** → Treat as opaque text + extension; do not execute workflows in-app.
- **[Risk] MCP JSON schema variance across tools** → Validate syntax only in v1; do not claim schema-complete MCP compliance.
- **[Trade-off] Copy vs link for skills** → Copy wins portability; costs disk and update drift from upstream skill repos.

## Migration Plan

- New app / new vaults only; no legacy data.
- Vault marker includes `version`; future layout changes bump version and run additive migrations.
- Rollback: delete app; vault folders remain on disk untouched.

## Open Questions

- Default language / UI locale (zh-CN first vs system locale).
- Whether “collections” should also be represented as folders on disk for power users (currently JSON meta).
- Exact default extension and front-matter schema for prompts vs workflows (finalize at scaffold).
