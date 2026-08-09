## 1. Project scaffold

- [ ] 1.1 Create Flutter macOS desktop project in the repo and verify `flutter run -d macos` launches an empty window
- [ ] 1.2 Add state management, path/file picker, URL launcher, and Markdown/YAML helpers as needed
- [ ] 1.3 Create feature module folders: `shell`, `vault`, `prompts`, `skills`, `mcp`, `links`, `workflows`, plus shared `vault_fs` service
- [ ] 1.4 Define vault on-disk schema constants (marker file, folder names, meta paths) matching `design.md`

## 2. Desktop shell

- [ ] 2.1 Build Obsidian-like layout: left sidebar + main content pane (+ optional inspector slot)
- [ ] 2.2 Add sidebar navigation entries for Favorites, Collections, All, and each resource type
- [ ] 2.3 Wire keyboard focus so Return opens the selected list item in the main pane
- [ ] 2.4 Add empty/welcome state when no vault is open (Create / Open actions)

## 3. Vault workspace

- [ ] 3.1 Implement create vault (pick folder, write `.ai-vault.json` + standard directories)
- [ ] 3.2 Implement open vault with validation of vault marker; show clear error for invalid folders
- [ ] 3.3 Persist and restore last-opened vault path on launch
- [ ] 3.4 Implement folder tree browsing with lazy expand of children
- [ ] 3.5 Implement favorites read/write via `meta/favorites.json` and Favorites sidebar section
- [ ] 3.6 Implement collections CRUD via `meta/collections.json` (create, rename, add/remove members)
- [ ] 3.7 Implement search over titles/tags/content and type filter chips

## 4. Shared text editor & metadata

- [ ] 4.1 Build shared text document editor with debounced autosave and Cmd+S
- [ ] 4.2 Implement front-matter / metadata helpers for title, tags, description
- [ ] 4.3 Add delete-with-confirmation dialog reusable across resource types
- [ ] 4.4 Detect external file mtime changes on window focus and reload or notify

## 5. Prompt library

- [ ] 5.1 Create / list / open prompts under `prompts/`
- [ ] 5.2 Edit body + tags/description and persist
- [ ] 5.3 Duplicate prompt to a new path/title
- [ ] 5.4 Delete prompt after confirmation

## 6. Skill library

- [ ] 6.1 Import SKILL folder by copying into `skills/<name>/` with progress UI
- [ ] 6.2 Browse skill contents and open text files in the shared editor
- [ ] 6.3 Reveal skill folder in Finder
- [ ] 6.4 Store skill display metadata (name/tags/notes) without rewriting skill internals
- [ ] 6.5 Remove skill from library after confirmation

## 7. MCP library

- [ ] 7.1 Create / list / open MCP configs under `mcp/`
- [ ] 7.2 Edit config text with JSON syntax validation feedback
- [ ] 7.3 Import existing MCP config file into the library
- [ ] 7.4 Delete MCP config after confirmation

## 8. Link library

- [ ] 8.1 Create / list / open link records under `links/`
- [ ] 8.2 Validate http(s) URL on save; block empty/invalid URLs with clear errors
- [ ] 8.3 Open link in the default system browser
- [ ] 8.4 Edit notes/tags and delete after confirmation

## 9. Workflow library

- [ ] 9.1 Create / list / open workflows under `workflows/`
- [ ] 9.2 Edit content + tags/description and persist
- [ ] 9.3 Import existing workflow file (preserve extension when possible)
- [ ] 9.4 Delete workflow after confirmation

## 10. Polish & verification

- [ ] 10.1 End-to-end manual check: create vault → add one of each resource type → favorite → collection → search → reopen app
- [ ] 10.2 Add README covering vault folder layout and how to run on macOS
- [ ] 10.3 Fix P0 UX gaps (empty states, error toasts, destructive confirmations) found in the E2E pass
