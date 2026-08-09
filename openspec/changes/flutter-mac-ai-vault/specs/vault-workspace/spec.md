## Purpose

Manages the local-first Vault: open and create vault roots, browse folders, favorites/collections, search, and type filters.

## ADDED Requirements

### Requirement: Create a new vault
The system SHALL allow the user to create a new vault by choosing an empty or new folder on disk and initializing the vault folder structure.

#### Scenario: Create vault in chosen folder
- **WHEN** the user chooses Create Vault and selects a destination folder
- **THEN** the system initializes the vault structure in that folder and opens it

### Requirement: Open an existing vault
The system SHALL allow the user to open an existing vault by selecting a vault root folder on disk.

#### Scenario: Open valid vault
- **WHEN** the user selects a folder that contains a valid vault marker
- **THEN** the system opens that vault and shows its contents

#### Scenario: Reject non-vault folder
- **WHEN** the user selects a folder that is not a valid vault
- **THEN** the system refuses to open it as a vault and explains why

### Requirement: Persist last-opened vault
The system SHALL remember the last successfully opened vault and offer to reopen it on next launch.

#### Scenario: Reopen last vault
- **WHEN** the app starts and a last-opened vault path is still valid
- **THEN** the system can reopen that vault without requiring the user to browse again

### Requirement: Folder tree browsing
The system SHALL display the vault directory tree and allow expanding folders and selecting files or folders that represent resources.

#### Scenario: Expand folder in tree
- **WHEN** the user expands a folder in the vault tree
- **THEN** its immediate children are listed

### Requirement: Favorites
The system SHALL allow the user to mark any supported resource as a favorite and list favorites in a dedicated navigation section.

#### Scenario: Star a resource
- **WHEN** the user favorites a resource
- **THEN** that resource appears in the Favorites section and remains favorited after app restart

#### Scenario: Unfavorite a resource
- **WHEN** the user removes a favorite
- **THEN** the resource no longer appears in Favorites

### Requirement: Collections
The system SHALL allow the user to create named collections and assign resources of any supported type to a collection.

#### Scenario: Add resource to collection
- **WHEN** the user adds a resource to a collection
- **THEN** opening that collection lists the resource

### Requirement: Search across vault
The system SHALL provide search over resource titles and, where applicable, text content and tags within the open vault.

#### Scenario: Search by title
- **WHEN** the user enters a query matching a resource title
- **THEN** that resource appears in search results

### Requirement: Filter by resource type
The system SHALL allow filtering the library view to a single resource type (prompt, skill, mcp, link, workflow) or showing all types.

#### Scenario: Filter to links only
- **WHEN** the user applies the link type filter
- **THEN** only link resources are listed in the filtered view

### Requirement: Local-first storage
The system SHALL store vault data as files and folders on the local filesystem so the vault remains usable outside the app (e.g. Finder, Git).

#### Scenario: Files visible on disk
- **WHEN** the user creates a resource in the app
- **THEN** a corresponding file or folder exists under the vault root on disk
