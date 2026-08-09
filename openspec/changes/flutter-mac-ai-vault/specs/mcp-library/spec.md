## Purpose

Stores and edits MCP configuration documents in the vault so users can collect, review, and reuse MCP setups.

## ADDED Requirements

### Requirement: Create MCP config
The system SHALL allow creating a new MCP configuration document with a title and body stored in the vault.

#### Scenario: Create MCP config entry
- **WHEN** the user creates a new MCP config and enters a title
- **THEN** a new config document is saved and opened for editing

### Requirement: Edit MCP config content
The system SHALL provide an editor suitable for configuration text (e.g. JSON) and persist edits to disk.

#### Scenario: Save MCP config edits
- **WHEN** the user edits an MCP config and saves
- **THEN** the updated content is written to the config file on disk

### Requirement: Basic JSON validation feedback
When the MCP config is treated as JSON, the system SHALL indicate whether the document is syntactically valid JSON after edit or on save.

#### Scenario: Invalid JSON shown
- **WHEN** the user saves or validates content that is not valid JSON
- **THEN** the system shows a clear validation error without deleting the user’s content

#### Scenario: Valid JSON accepted
- **WHEN** the user saves valid JSON content
- **THEN** the system reports no syntax error for that document

### Requirement: Import MCP config file
The system SHALL allow importing an existing MCP config file from disk into the vault library.

#### Scenario: Import config file
- **WHEN** the user selects an MCP config file to import
- **THEN** the file is added to the MCP library and available for editing

### Requirement: Delete MCP config
The system SHALL allow deleting an MCP config after confirmation.

#### Scenario: Confirm delete MCP config
- **WHEN** the user confirms deletion of an MCP config
- **THEN** the config file is removed from the vault library
