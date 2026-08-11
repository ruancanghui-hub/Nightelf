# Nightelf README Promotion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a bilingual, product-led GitHub README for Nightelf with a polished screenshot derived from the real macOS application UI.

**Architecture:** Keep the deliverable documentation-only: `README.md` owns the product story and onboarding, while one checked-in PNG under `docs/images/` supplies the hero visual. Capture the running Flutter app first, then apply only presentational framing so every visible feature remains truthful to the current implementation.

**Tech Stack:** Markdown, Flutter macOS, macOS screenshot tools, bundled image-processing runtime, Git.

## Global Constraints

- Modify only README material and its directly referenced image; do not change application behavior, versions, packaging, or licensing.
- Use a real current Nightelf UI as the screenshot source; do not invent controls, content capabilities, metrics, or availability.
- Present Chinese first with concise English summaries on the same page.
- Describe Releases as “Coming soon”; do not claim that a DMG or downloadable Release exists.
- State that Nightelf currently targets macOS and requires Flutter for source installation.
- If no license file exists, say that the license has not yet been published.

---

### Task 1: Capture and polish the real workbench visual

**Files:**
- Create: `docs/images/nightelf-workbench.png`
- Inspect: `assets/nightelf-logo.png`
- Inspect: `lib/app/ai_workbench_app.dart`
- Inspect: `lib/features/overview/presentation/emerald_overview_dashboard.dart`
- Inspect: `lib/features/shell/presentation/workbench_shell.dart`

**Interfaces:**
- Consumes: the current Flutter macOS application and a representative local Vault.
- Produces: `docs/images/nightelf-workbench.png`, a GitHub-ready PNG referenced by Task 2.

- [ ] **Step 1: Establish a clean baseline**

Run:

```bash
git status --short
flutter --version
flutter pub get
```

Expected: only intentional pre-existing changes are present; Flutter resolves project dependencies successfully.

- [ ] **Step 2: Launch the current macOS application**

Run:

```bash
flutter run -d macos
```

Expected: Nightelf opens as a macOS desktop application without a build error.

- [ ] **Step 3: Prepare the representative real UI state**

Open or create a local Vault through the app, then select the Overview or another workspace state that visibly includes the resource navigation and central workbench. Use only resources already present in the Vault or files created through the product's normal UI.

Expected: the window visibly communicates the Nightelf brand and multi-resource workbench without exposing private paths or personal data.

- [ ] **Step 4: Capture the Nightelf window**

Use the macOS window screenshot shortcut (`Shift+Command+4`, then Space) or equivalent UI automation and save the source screenshot outside the repository.

Expected: the capture contains the full application window at native resolution, with no other application windows, menus, notifications, or cursor overlays.

- [ ] **Step 5: Produce the hero image**

Create `docs/images/nightelf-workbench.png` from the source capture. Preserve the actual UI pixels; limit treatment to cropping, dark forest-green background, balanced margins, rounded presentation, subtle shadow, and global contrast/sharpness corrections. Export at a width between 1600 and 2400 pixels and keep text legible.

Expected: the resulting PNG is visually polished but still an accurate representation of the application.

- [ ] **Step 6: Inspect the finished asset**

Run:

```bash
file docs/images/nightelf-workbench.png
sips -g pixelWidth -g pixelHeight docs/images/nightelf-workbench.png
```

Open the image at full size and verify that no text is clipped, no private data is visible, the Nightelf interface is readable, and no unsupported functionality appears.

- [ ] **Step 7: Commit the visual**

```bash
git add docs/images/nightelf-workbench.png
git commit -m "docs: add Nightelf workbench showcase"
```

### Task 2: Rewrite the repository README

**Files:**
- Modify: `README.md`
- Read: `pubspec.yaml`
- Read: `script/build_and_run.sh`
- Read: `openspec/changes/flutter-mac-ai-vault/proposal.md`
- Read: `openspec/changes/flutter-mac-ai-vault/design.md`
- Read: `docs/superpowers/specs/2026-08-10-nightelf-readme-promotion-design.md`

**Interfaces:**
- Consumes: `docs/images/nightelf-workbench.png` from Task 1 and verified repository commands/features.
- Produces: the public repository landing page in `README.md`.

- [ ] **Step 1: Verify every public claim against the repository**

Run:

```bash
rg -n "Vault|Prompt|SKILL|MCP|Workflow|bookmark|bubble|悬浮|search|搜索" lib test openspec
test -f LICENSE || test -f LICENSE.md || test -f COPYING
```

Expected: each feature selected for the README has code, tests, or specification evidence; the license check records whether a license file exists.

- [ ] **Step 2: Replace the opening with the product hero**

Write a centered opening containing the existing Nightelf logo, `Nightelf 工作台`, the Chinese positioning line, a concise English positioning line, factual macOS/Flutter/local-first badges, a relative link to `docs/images/nightelf-workbench.png`, and a restrained request to Star the repository.

Expected copy includes these exact factual ideas: “本地优先”, “文件即真相”, “macOS”, and “Prompt · Skill · MCP · Link · Workflow”.

- [ ] **Step 3: Add product value and capability sections**

Explain the scattered-AI-assets problem in Chinese followed by a short English summary. Add concise feature entries for Vault, Prompt, Skill, MCP, website links, Workflow, overview/search/metadata, and macOS integrations, including only behavior verified in Step 1.

Expected: a visitor can understand the product in under one minute and no entry suggests that Nightelf executes MCP servers or includes an LLM chat client.

- [ ] **Step 4: Add onboarding and on-disk model**

Include the exact source setup commands:

```bash
flutter pub get
flutter run -d macos
```

Also document `./script/build_and_run.sh`, first-launch Vault creation/opening, and the repository-backed Vault folders `.ai-vault.json`, `prompts/`, `skills/`, `mcp/`, `links/`, `workflows/`, and `meta/`.

Expected: the instructions do not imply that Flutter is bundled or that non-macOS platforms are supported.

- [ ] **Step 5: Add project status, contribution, and support sections**

Mark packaged Releases/DMG downloads as “Coming soon”. Invite Issues and Pull Requests, provide the existing development commands `flutter test` and `flutter build macos --debug`, and state that the project license has not yet been published if Step 1 found no license file. End with a brief, non-coercive Star invitation.

Expected: the README contains no fabricated download link, usage statistic, social proof, or license claim.

- [ ] **Step 6: Commit the README**

```bash
git add README.md
git commit -m "docs: publish bilingual Nightelf README"
```

### Task 3: Verify the GitHub-facing documentation

**Files:**
- Verify: `README.md`
- Verify: `docs/images/nightelf-workbench.png`

**Interfaces:**
- Consumes: the completed Task 1 and Task 2 deliverables.
- Produces: evidence that README paths, commands, presentation, and project tests are valid.

- [ ] **Step 1: Check Markdown asset targets and whitespace**

Run:

```bash
test -f assets/nightelf-logo.png
test -f docs/images/nightelf-workbench.png
git diff --check HEAD~2..HEAD
rg -n "TBD|TODO|example\.com|YOUR_|LICENSE.*详见|下载 DMG" README.md
```

Expected: both image targets exist, `git diff --check` prints nothing, and the placeholder scan prints nothing except any deliberately quoted “Coming soon” wording outside the listed patterns.

- [ ] **Step 2: Validate documented shell commands**

Run:

```bash
flutter pub get
flutter build macos --debug
```

Expected: dependency resolution and the documented debug build both succeed.

- [ ] **Step 3: Run the repository test suite**

Run:

```bash
flutter test
```

Expected: all Flutter tests pass.

- [ ] **Step 4: Review the rendered README**

Open the repository README in a Markdown/GitHub preview. Verify heading hierarchy, badge rendering, image sharpness, code block wrapping, bilingual readability, relative links, and the visibility of the Star CTA without excessive repetition.

Expected: the page reads as a coherent product introduction at desktop and narrow content widths.

- [ ] **Step 5: Record final repository state**

Run:

```bash
git status --short
git log -3 --oneline
```

Expected: no unintended files are modified or untracked; the implementation commits are visible after the design and plan history.
