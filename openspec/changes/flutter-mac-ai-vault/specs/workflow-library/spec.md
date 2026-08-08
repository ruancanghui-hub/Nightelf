## Purpose

Organizes workflow files in the vault so users can import, edit, and group automation or agent workflow definitions.

## ADDED Requirements

### Requirement: Create workflow file
The system SHALL allow creating a new workflow document with a title and body in the vault.

#### Scenario: Create workflow
- **WHEN** the user creates a new workflow and provides a title
- **THEN** a workflow file is saved in the vault and opened for editing

### Requirement: Edit workflow content
The system SHALL provide an editor for workflow file content and persist changes to disk.

#### Scenario: Save workflow edits
- **WHEN** the user edits a workflow and saves
- **THEN** the updated content is written to the workflow file on disk

### Requirement: Import workflow file
The system SHALL allow importing an existing workflow file from disk into the vault.

#### Scenario: Import workflow
- **WHEN** the user selects a workflow file to import
- **THEN** the file is added to the workflow library

### Requirement: Workflow metadata
The system SHALL support tags and an optional description for each workflow.

#### Scenario: Tag a workflow
- **WHEN** the user adds tags to a workflow
- **THEN** the workflow is discoverable via those tags in search

### Requirement: Delete workflow
The system SHALL allow deleting a workflow after confirmation.

#### Scenario: Confirm delete workflow
- **WHEN** the user confirms deletion of a workflow
- **THEN** the workflow file is removed from the vault library
