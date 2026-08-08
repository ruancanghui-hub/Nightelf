## Purpose

Manages SKILL folders as vault resources: import, browse, open in Finder, and maintain metadata for discovery.

## ADDED Requirements

### Requirement: Import a SKILL folder
The system SHALL allow the user to import an existing SKILL folder into the vault, preserving its folder structure.

#### Scenario: Import skill directory
- **WHEN** the user selects a SKILL folder to import
- **THEN** the folder is copied or linked into the vault skill library and appears as a skill resource

### Requirement: Browse skill contents
The system SHALL allow browsing the files inside an imported SKILL folder from within the app.

#### Scenario: Open skill and list files
- **WHEN** the user opens a skill resource
- **THEN** the app lists the skill folder contents and can open text files for viewing or editing

### Requirement: Reveal skill in Finder
The system SHALL allow revealing the skill folder in Finder.

#### Scenario: Reveal in Finder
- **WHEN** the user chooses Reveal in Finder for a skill
- **THEN** Finder opens showing that skill folder

### Requirement: Skill metadata
The system SHALL support a display name, tags, and optional notes for each skill resource without requiring changes to the skill’s own files when metadata is stored separately.

#### Scenario: Tag a skill
- **WHEN** the user adds tags to a skill
- **THEN** the skill can be found via tag search while its original skill files remain intact

### Requirement: Remove skill from library
The system SHALL allow removing a skill from the vault library after confirmation.

#### Scenario: Confirm remove skill
- **WHEN** the user confirms removal of a skill from the library
- **THEN** the skill no longer appears in the skill library
