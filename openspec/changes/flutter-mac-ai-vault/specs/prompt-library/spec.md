## Purpose

Lets users create, edit, tag, and organize AI prompt documents inside the vault as first-class library resources.

## ADDED Requirements

### Requirement: Create a prompt
The system SHALL allow the user to create a new prompt with a title and body stored as a text document in the vault.

#### Scenario: Create empty prompt
- **WHEN** the user creates a new prompt and provides a title
- **THEN** a new prompt document is saved in the vault and opened for editing

### Requirement: Edit prompt body
The system SHALL provide an editor for the prompt body and persist changes to disk.

#### Scenario: Save edited prompt
- **WHEN** the user edits the prompt body and saves (explicitly or via autosave)
- **THEN** the updated content is written to the prompt file on disk

### Requirement: Prompt metadata
The system SHALL support tags and an optional short description on each prompt.

#### Scenario: Add tags to prompt
- **WHEN** the user adds one or more tags to a prompt
- **THEN** those tags are persisted and usable for search and filtering

### Requirement: Duplicate prompt
The system SHALL allow duplicating an existing prompt into a new prompt document.

#### Scenario: Duplicate selected prompt
- **WHEN** the user duplicates a prompt
- **THEN** a new prompt is created with the same body and a distinct title/path

### Requirement: Delete prompt
The system SHALL allow deleting a prompt after confirmation, removing its file from the vault.

#### Scenario: Confirm delete
- **WHEN** the user confirms deletion of a prompt
- **THEN** the prompt file is removed from the vault and no longer appears in the library
