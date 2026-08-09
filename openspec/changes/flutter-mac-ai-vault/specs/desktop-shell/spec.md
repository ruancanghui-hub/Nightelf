## Purpose

Provides the Flutter macOS desktop application chrome and Obsidian-like navigation layout users interact with daily.

## ADDED Requirements

### Requirement: Native macOS desktop window
The system SHALL launch as a native macOS desktop application with a resizable primary window.

#### Scenario: App launches on macOS
- **WHEN** the user opens the application on macOS
- **THEN** a primary desktop window appears and is ready for vault interaction

### Requirement: Obsidian-like three-pane layout
The system SHALL present a layout with a left sidebar for navigation, a main content pane for the active item, and optional secondary pane or inspector for metadata when an item is selected.

#### Scenario: Default layout on vault open
- **WHEN** a vault is open
- **THEN** the user sees a left navigation area and a main content area within the same window

### Requirement: Resource type navigation
The system SHALL allow the user to switch between resource views for prompts, skills, MCP configs, links, and workflows from the sidebar or equivalent navigation.

#### Scenario: Switch to prompts view
- **WHEN** the user selects the prompts navigation entry
- **THEN** the main pane shows the prompt library view

### Requirement: Keyboard-friendly focus
The system SHALL keep keyboard focus usable for navigating the sidebar and opening the selected item with standard activation keys (Enter / Return).

#### Scenario: Open selected sidebar item with keyboard
- **WHEN** the user highlights a resource in the list and presses Return
- **THEN** that resource opens in the main content pane
