## Purpose

Lets users bookmark website links with title, URL, notes, and tags, and open them in the system browser.

## ADDED Requirements

### Requirement: Add a website link
The system SHALL allow creating a link resource with a title and URL stored in the vault.

#### Scenario: Create link with URL
- **WHEN** the user adds a link with a valid URL and title
- **THEN** the link appears in the link library

### Requirement: Validate URL format
The system SHALL reject saving a link when the URL is empty or not a plausible http(s) URL, and show an actionable error.

#### Scenario: Reject empty URL
- **WHEN** the user tries to save a link with an empty URL
- **THEN** the system blocks the save and explains that a URL is required

### Requirement: Open link in browser
The system SHALL open the link URL in the default system browser.

#### Scenario: Open selected link
- **WHEN** the user chooses Open for a link
- **THEN** the system browser opens that URL

### Requirement: Link notes and tags
The system SHALL support optional notes and tags on each link.

#### Scenario: Edit link notes
- **WHEN** the user adds notes to a link and saves
- **THEN** the notes persist and are shown when the link is reopened

### Requirement: Delete link
The system SHALL allow deleting a link after confirmation.

#### Scenario: Confirm delete link
- **WHEN** the user confirms deletion of a link
- **THEN** the link is removed from the library
