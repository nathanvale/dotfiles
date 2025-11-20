---
description:
  Plugin discovery API - returns task format schema and integration points for other plugins to
  consume
---

# Capabilities Command

Discovery API that returns the task-streams format specification, allowing other plugins to generate
conformant task files without knowing implementation details.

## Usage

```bash
/task-streams:capabilities [--format=json|yaml|markdown] [--section=<name>]
```

**Parameters:**

- `--format`: Output format (default: `markdown`)
  - `json`: Machine-readable JSON schema
  - `yaml`: Human-readable YAML
  - `markdown`: Formatted documentation
- `--section`: Return specific section only
  - `schema`: Task file structure
  - `frontmatter`: Frontmatter fields
  - `enrichments`: 10 required enrichments
  - `validation`: Validation rules
  - `examples`: Example task files
  - `all`: Complete specification (default)

**Examples:**

```bash
# Get full capabilities (markdown format)
/task-streams:capabilities

# Get JSON schema for programmatic integration
/task-streams:capabilities --format=json

# Get only frontmatter specification
/task-streams:capabilities --section=frontmatter --format=yaml

# Get validation rules
/task-streams:capabilities --section=validation
```

---

## Phase 1: Query Processing

### Step 1.1: Parse Parameters

```typescript
interface CapabilitiesQuery {
  format: "json" | "yaml" | "markdown";
  section: "schema" | "frontmatter" | "enrichments" | "validation" | "examples" | "all";
}
```

### Step 1.2: Report Query

```
🔍 Task-Streams Capabilities

📋 Format: {format}
📦 Section: {section}

Generating specification...
```

---

## Phase 2: Generate Capabilities Response

### Section: Schema (Task File Structure)

**JSON Format:**

```json
{
  "conventions": {
    "componentCodeFormat": "C##",
    "filenameFormat": "{taskId}-{slug}.md",
    "priorityValues": ["P0", "P1", "P2", "P3"],
    "statusValues": ["READY", "IN_PROGRESS", "BLOCKED", "DONE"],
    "taskDirectory": "docs/tasks/",
    "taskIdFormat": "T####"
  },
  "taskFormat": {
    "frontmatter": {
      "optional": ["tags", "assignee", "dueDate", "effort"],
      "required": ["id", "title", "priority", "component", "status", "created", "source"]
    },
    "sections": {
      "optional": ["References", "Alternatives Considered"],
      "required": [
        "Description",
        "Acceptance Criteria",
        "Implementation Steps",
        "Files to Change",
        "Testing Requirements",
        "Dependencies",
        "Prerequisites",
        "Regression Risk",
        "Code Examples",
        "Notes"
      ]
    }
  },
  "version": "1.0.0"
}
```

**Markdown Format:**

```markdown
# Task File Schema

## File Structure
```

docs/tasks/{taskId}-{slug}.md

```

## Required Components

1. **YAML Frontmatter**
   - id: T#### (4-digit number)
   - title: Human-readable task name
   - priority: P0 | P1 | P2 | P3
   - component: C## (2-digit code)
   - status: READY | IN_PROGRESS | BLOCKED | DONE
   - created: ISO 8601 timestamp
   - source: Origin document path

2. **10 Required Sections**
   - Description
   - Acceptance Criteria (checkbox format)
   - Implementation Steps (numbered list)
   - Files to Change (3 subsections)
   - Testing Requirements (table)
   - Dependencies
   - Prerequisites (checkbox format)
   - Regression Risk
   - Code Examples
   - Notes

## Conventions

- **Task IDs**: T0001, T0002, T0003... (sequential, never reused)
- **Component Codes**: C00-C99 (registry-based)
- **Priorities**: P0 (critical), P1 (high), P2 (medium), P3 (low)
- **Statuses**: READY (can start), IN_PROGRESS (active), BLOCKED (waiting), DONE (complete)
```

### Section: Frontmatter (Field Definitions)

**JSON Format:**

```json
{
  "frontmatter": {
    "component": {
      "description": "Component code from registry",
      "example": "C05",
      "format": "C##",
      "required": true,
      "type": "string"
    },
    "created": {
      "description": "ISO 8601 creation timestamp",
      "example": "2025-11-05T14:30:22Z",
      "format": "date-time",
      "required": true,
      "type": "string"
    },
    "id": {
      "description": "Unique task identifier",
      "example": "T0001",
      "format": "T####",
      "required": true,
      "type": "string"
    },
    "priority": {
      "description": "Task priority (P0=critical, P3=low)",
      "enum": ["P0", "P1", "P2", "P3"],
      "example": "P0",
      "required": true,
      "type": "string"
    },
    "source": {
      "description": "Origin document or description",
      "example": "docs/specs/auth-redesign-spec.md",
      "required": true,
      "type": "string"
    },
    "status": {
      "description": "Current task status",
      "enum": ["READY", "IN_PROGRESS", "BLOCKED", "DONE"],
      "example": "READY",
      "required": true,
      "type": "string"
    },
    "title": {
      "description": "Human-readable task name",
      "example": "Implement OAuth2 authentication flow",
      "required": true,
      "type": "string"
    }
  }
}
```

### Section: Enrichments (10 Required Enrichments)

**JSON Format:**

````json
{
  "enrichments": [
    {
      "description": "Files to Create/Modify/Delete with line ranges",
      "example": "### Files to Modify\n- `src/auth.ts:45-89` - Add OAuth flow",
      "format": "Three subsections (Create, Modify, Delete)",
      "name": "File Locations",
      "section": "Files to Change"
    },
    {
      "description": "Realistic time estimates",
      "example": "8h",
      "format": "Hours with 'h' suffix",
      "name": "Effort Estimates",
      "section": "Description (Estimated Effort field)"
    },
    {
      "description": "Technical complexity classification",
      "example": "CRITICAL",
      "format": "CRITICAL | HIGH | MEDIUM | LOW",
      "name": "Complexity",
      "section": "Description (Complexity field)"
    },
    {
      "description": "3-5 testable checkbox items",
      "example": "- [ ] OAuth tokens validated correctly",
      "format": "Markdown checkboxes (- [ ])",
      "name": "Acceptance Criteria",
      "section": "Acceptance Criteria"
    },
    {
      "description": "Impact, Blast Radius, Testing Gaps, Rollback Risk",
      "example": "**Impact:** High - Core authentication",
      "format": "Structured fields",
      "name": "Regression Risk",
      "section": "Regression Risk"
    },
    {
      "description": "Numbered list of concrete actions",
      "example": "1. Create OAuth client wrapper",
      "format": "Numbered list (1., 2., 3.)",
      "name": "Implementation Steps",
      "section": "Implementation Steps"
    },
    {
      "description": "Current and proposed code",
      "example": "**Current:**\n```typescript\n// legacy code\n```",
      "format": "Two code blocks (Current, Proposed)",
      "name": "Code Examples",
      "section": "Code Examples"
    },
    {
      "description": "Maps test types to acceptance criteria",
      "example": "| Unit | AC1, AC2 | Token tests | path |",
      "format": "Markdown table with 4 columns",
      "name": "Testing Table",
      "section": "Testing Requirements"
    },
    {
      "description": "Blocking tasks and prerequisites",
      "example": "**Blocking:** T0001, T0003",
      "format": "Blocking/Blocked By with task IDs",
      "name": "Dependencies",
      "section": "Dependencies"
    },
    {
      "description": "Component code from registry",
      "example": "**Component:** C05: Authentication",
      "format": "C## code with name",
      "name": "Component Classification",
      "section": "Description (Component field)"
    }
  ]
}
````

### Section: Validation (Validation Rules)

**JSON Format:**

```json
{
  "validation": {
    "rules": [
      {
        "autoFix": true,
        "code": "MISSING_FRONTMATTER",
        "description": "Task file must have YAML frontmatter",
        "severity": "ERROR"
      },
      {
        "autoFix": true,
        "code": "INVALID_TASK_ID",
        "description": "Task ID must match T#### format",
        "severity": "ERROR"
      },
      {
        "autoFix": true,
        "code": "MISSING_SECTION",
        "description": "Required section not found",
        "severity": "ERROR"
      },
      {
        "autoFix": false,
        "code": "AC_TOO_FEW",
        "description": "Should have 3-5 acceptance criteria",
        "severity": "WARNING"
      }
    ],
    "validateCommand": "/task-streams:validate"
  }
}
```

### Section: Examples (Complete Task File)

**Markdown Format:**

`````markdown
# Example Task File

## Filename

```
docs/tasks/T0001-implement-oauth-flow.md
```

## Contents

````markdown
---
id: T0001
title: Implement OAuth2 authentication flow
priority: P0
component: C05
status: READY
created: 2025-11-05T14:30:22Z
source: docs/specs/auth-redesign-spec.md
---

# T0001: Implement OAuth2 authentication flow

**Component:** C05: Authentication & Authorization **Priority:** P0 (Critical) **Status:** READY
**Estimated Effort:** 12h **Complexity:** CRITICAL

## Description

Replace legacy authentication with OAuth2 flow using Azure AD B2C. Enables single sign-on and
improves security posture.

## Acceptance Criteria

- [ ] OAuth2 client successfully authenticates users
- [ ] Tokens stored securely in encrypted storage
- [ ] Token refresh works automatically
- [ ] Legacy authentication fully removed
- [ ] All existing auth tests pass with OAuth2

## Implementation Steps

1. Install and configure OAuth2 client library
2. Create OAuth client wrapper with token management
3. Integrate with Azure AD B2C tenant
4. Update authentication middleware to use OAuth2
5. Migrate user sessions to new auth system
6. Remove legacy authentication code
7. Update documentation with new auth flow

## Files to Change

### Files to Create

- `src/lib/auth/oauth-client.ts` (~200 lines) - OAuth2 client implementation
- `src/lib/auth/token-manager.ts` (~150 lines) - Secure token storage
- `tests/unit/auth/oauth.test.ts` (~100 lines) - OAuth client tests

### Files to Modify

- `src/lib/services/auth-service.ts:45-89` - Replace legacy auth with OAuth2
- `src/middleware/auth.ts:12-45` - Update middleware to validate OAuth tokens
- `src/config/auth-config.ts:5-20` - Add OAuth2 configuration

### Files to Delete

- `src/lib/auth/legacy-auth.ts` - Superseded by OAuth2
- `src/lib/auth/password-hash.ts` - No longer needed

## Testing Requirements

| Test Type   | Validates AC | Description                       | Location                              |
| ----------- | ------------ | --------------------------------- | ------------------------------------- |
| Unit        | AC1, AC2     | OAuth client token validation     | `tests/unit/auth/oauth.test.ts`       |
| Integration | AC3, AC4     | Full authentication flow          | `tests/integration/auth-flow.test.ts` |
| E2E         | AC5          | End-to-end login with OAuth2      | `tests/e2e/login.spec.ts`             |
| Migration   | AC4, AC5     | Legacy to OAuth session migration | `tests/migration/auth-migration.ts`   |

## Dependencies

**Blocking:** None **Blocked By:** None

## Prerequisites

- [ ] Azure AD B2C tenant configured
- [ ] OAuth client credentials obtained
- [ ] Redirect URLs registered in Azure portal
- [ ] Development and production configs ready

## Regression Risk

**Impact:** High - Core authentication mechanism affects all users **Blast Radius:** Entire
application (all authenticated features) **Dependencies:** Session management, API authorization,
user profiles **Testing Gaps:** No existing OAuth2 tests, need migration path validation **Rollback
Risk:** Medium - Can revert to legacy auth if needed, sessions persist

## Code Examples

**Current (Legacy):**

```typescript
// src/lib/auth/legacy-auth.ts
export async function authenticate(username: string, password: string) {
  const hash = await hashPassword(password);
  const user = await db.users.findOne({ username, passwordHash: hash });
  if (!user) throw new Error("Invalid credentials");
  return createSession(user.id);
}
```
````
`````

**Proposed (OAuth2):**

```typescript
// src/lib/auth/oauth-client.ts
export async function authenticate(authorizationCode: string) {
  const tokenResponse = await oauthClient.exchangeCodeForTokens(authorizationCode);
  await tokenManager.store(tokenResponse.accessToken, tokenResponse.refreshToken);
  const userInfo = await oauthClient.getUserInfo(tokenResponse.accessToken);
  return createSession(userInfo.sub);
}
```

## Notes

- OAuth2 authorization code flow with PKCE for security
- Token refresh handled automatically by token manager
- Legacy sessions migrated gradually (coexistence during transition)
- Consider MFA as follow-up task (out of scope here)
- Monitor authentication latency after rollout

```

```

````

---

## Phase 3: Generate Output

### Step 3.1: Format Response

Based on requested format, serialize the capabilities data:

```typescript
const response = {
  json: () => JSON.stringify(capabilities, null, 2),
  yaml: () => YAML.stringify(capabilities),
  markdown: () => formatMarkdown(capabilities),
}[format]()
```

### Step 3.2: Display Response

```
📋 Task-Streams Capabilities v1.0.0

{formatted output based on --format and --section}

---

💡 Integration Examples:

# Generate conformant task from your plugin
1. Query schema: /task-streams:capabilities --format=json --section=schema
2. Generate task file following schema
3. Validate: /task-streams:validate <your-output-file>

# Example: ADR Generator Plugin
/adr-generator:create-adr my-decision
  → Generates ADR document
  → Uses /task-streams:convert to create implementation tasks
  → Tasks automatically conform to schema

# Example: Documentation Plugin
/doc-generator:from-code src/
  → Analyzes code
  → Uses /task-streams:capabilities to learn task format
  → Generates conformant task files for documentation gaps
```

---

## Phase 4: Machine-Readable Schema (JSON Output)

Complete JSON schema when `--format=json --section=all`:

```json
{
  "plugin": {
    "name": "task-streams",
    "version": "1.0.0",
    "description": "Generic document-to-tasks converter with standardized task format"
  },
  "commands": {
    "convert": {
      "description": "Convert document to task files",
      "usage": "/task-streams:convert <document-path>"
    },
    "validate": {
      "description": "Validate task files for conformance",
      "usage": "/task-streams:validate [path] [--fix] [--strict]"
    },
    "capabilities": {
      "description": "Query plugin capabilities and task format",
      "usage": "/task-streams:capabilities [--format=json|yaml|markdown]"
    },
    "status": {
      "description": "Inspect state files and task registry",
      "usage": "/task-streams:status"
    }
  },
  "taskFormat": {
    "version": "1.0.0",
    "frontmatter": {
      "required": [
        "id",
        "title",
        "priority",
        "component",
        "status",
        "created",
        "source"
      ],
      "optional": ["tags", "assignee", "dueDate"],
      "fields": {
        "id": {
          "type": "string",
          "format": "T####",
          "pattern": "^T[0-9]{4}$",
          "description": "Unique task identifier"
        },
        "priority": {
          "type": "string",
          "enum": ["P0", "P1", "P2", "P3"]
        },
        "component": {
          "type": "string",
          "format": "C##",
          "pattern": "^C[0-9]{2}$"
        },
        "status": {
          "type": "string",
          "enum": ["READY", "IN_PROGRESS", "BLOCKED", "DONE"]
        }
      }
    },
    "sections": {
      "required": [
        "Description",
        "Acceptance Criteria",
        "Implementation Steps",
        "Files to Change",
        "Testing Requirements",
        "Dependencies",
        "Prerequisites",
        "Regression Risk",
        "Code Examples",
        "Notes"
      ],
      "formats": {
        "Acceptance Criteria": "Markdown checkboxes (- [ ])",
        "Implementation Steps": "Numbered list (1., 2., 3.)",
        "Files to Change": "Three subsections (Create, Modify, Delete)",
        "Testing Requirements": "Markdown table with columns: Test Type, Validates AC, Description, Location"
      }
    },
    "enrichments": [
      "File Locations",
      "Effort Estimates",
      "Complexity",
      "Acceptance Criteria",
      "Regression Risk",
      "Implementation Steps",
      "Code Examples",
      "Testing Table",
      "Dependencies",
      "Component Classification"
    ]
  },
  "conventions": {
    "taskIdFormat": "T####",
    "componentCodeFormat": "C##",
    "filenameFormat": "{taskId}-{slug}.md",
    "taskDirectory": "docs/tasks/",
    "indexFile": "TASKS.md",
    "stateDirectory": ".claude/state/task-streams/"
  },
  "validation": {
    "command": "/task-streams:validate",
    "rules": [
      {
        "code": "MISSING_FRONTMATTER",
        "severity": "ERROR",
        "autoFix": true
      },
      {
        "code": "INVALID_TASK_ID",
        "severity": "ERROR",
        "autoFix": true
      }
    ]
  },
  "integrationPoints": {
    "queryCapabilities": "/task-streams:capabilities --format=json",
    "validateOutput": "/task-streams:validate <your-output-dir>",
    "convertDocument": "/task-streams:convert <your-document>"
  }
}
```

---

## Integration Patterns

### Pattern 1: Direct Task Generation

Plugin generates task files directly following the schema:

```typescript
// Your plugin code
const capabilities = await queryCapabilities()

// Invoke id-generator skill to get task ID with metadata
const taskId = await invokeSkill('id-generator', {
  operation: 'task',
  source: 'my-plugin-output',
  sourceType: 'generic',
  notes: 'My task'
})

// Invoke component-manager skill to find/create component code
const componentCode = await invokeSkill('component-manager', {
  operation: 'find',
  name: 'My Component'
})

const task = {
  frontmatter: {
    id: taskId, // Returns: T0001
    title: "My task",
    priority: "P1",
    component: componentCode, // Returns: C05 (or creates new)
    status: "READY",
    created: new Date().toISOString(),
    source: "my-plugin-output",
  },
  sections: {
    // Follow capabilities.taskFormat.sections
  },
}

await writeTaskFile(`docs/tasks/${task.frontmatter.id}-slug.md`, task)
await validate(`docs/tasks/${task.frontmatter.id}-slug.md`)
```

### Pattern 2: Convert-Based Integration

Plugin generates intermediate document, then uses convert:

```typescript
// Your plugin code
await generateIntermediateDoc("my-output.md")
await convert("my-output.md") // task-streams converts to tasks
```

### Pattern 3: Validation-Only Integration

Plugin generates tasks, then validates conformance:

```typescript
// Your plugin code
await generateTasks() // Your custom format
await validate("my-tasks/") // Validate against schema
// Fix any violations
```

---

## Success Criteria

Capabilities query is successful when:

- ✅ Returns complete task format specification
- ✅ Output format matches requested format (JSON/YAML/Markdown)
- ✅ Section filter works correctly
- ✅ Machine-readable schema is valid and parseable
- ✅ Integration patterns documented clearly
- ✅ Examples demonstrate real-world usage
- ✅ Other plugins can consume and integrate

---

## Notes

- **Versioned schema**: Includes version for compatibility tracking
- **Self-documenting**: Complete specification in one command
- **Integration-focused**: Designed for plugin-to-plugin communication
- **Format agnostic**: JSON for machines, Markdown for humans
- **Extensible**: Easy to add new sections as format evolves
- **Discoverable**: Other plugins can query without reading source code
````
