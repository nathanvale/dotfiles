# Format Spec Reference

Complete reference for transforming technical specifications into implementation tasks.

---

## 10 Required Enrichments

**For complete enrichment patterns and templates, see @../SHARED_ENRICHMENTS.md**

Every task MUST include all 10 enrichments:

1. Specific file locations with line numbers
2. Effort estimates in hours
3. Complexity classification
4. Concrete acceptance criteria (3-5 items)
5. Regression risk assessment (5 dimensions)
6. Actionable implementation steps
7. Code examples (current vs proposed)
8. File change scope (Create/Modify/Delete)
9. Required testing table
10. Dependencies and blocking information

---

## Input: Tech Spec Structures

This skill handles three common spec formats:

### Structure 1: Requirements-Based

```markdown
# Feature Specification

## Background/Context

{Problem description}

## Requirements

### Functional Requirements

FR1: System shall...
FR2: User shall be able to...

### Non-Functional Requirements

NFR1: Performance...
NFR2: Security...

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Out of Scope

- Future feature X
```

### Structure 2: User Story Based

```markdown
# Feature: User Authentication

## User Stories

### US-001: As a user, I want to log in

**Acceptance Criteria:**

- [ ] Login form validates input
- [ ] Successful login redirects to dashboard

### US-002: As an admin, I want to manage users

...
```

### Structure 3: Solution Design

```markdown
# OAuth2 Integration Design

## Solution Overview

{Technical approach}

## Components

### Component 1: OAuth Client

{Description}

### Component 2: Token Manager

{Description}

## Implementation Plan

1. Step one
2. Step two
```

---

## Extraction Strategy

### Phase 1: Identify Task Boundaries

**Task boundaries** (each becomes separate task file):

1. **Functional Requirements** (FR#) → One task per requirement
2. **User Stories** (US-###) → One task per user story
3. **Major Components** → One task per component
4. **Implementation Phases** → Tasks per phase if detailed

**Example:**

```markdown
## Requirements

FR1: Implement OAuth2 authentication
FR2: Add token refresh mechanism
FR3: Migrate existing sessions

→ Creates 3 tasks: T0001, T0002, T0003
```

### Phase 2: Extract Core Information

#### Title

**Sources:**

- Requirement ID + description: "FR1: Implement OAuth2 authentication"
- User story summary: "US-001: User can log in with OAuth2"
- Component name: "Implement OAuth Client Component"

**Format:** `{extracted title without prefix}`
**Example:** "Implement OAuth2 authentication" (not "FR1: Implement...")

#### Description

**Sources (priority order):**

1. Requirement description paragraph
2. User story context ("As a user, I want...")
3. Component overview section
4. Background/context if task-specific

**Fallback:** Use title expanded with context from spec overview

#### Acceptance Criteria

**Sources (priority order):**

1. **Explicit AC section** under requirement/user story
2. **NFRs** related to this requirement
3. **"Must have" statements** in description
4. **Generate from requirement** if none found

**Generation rules if missing:**

```markdown
For "Implement OAuth2 authentication":

- [ ] OAuth2 client library integrated
- [ ] Authentication flow completes successfully
- [ ] Tokens stored securely
- [ ] Error handling covers all OAuth2 edge cases
- [ ] Unit tests cover OAuth2 client
```

**Format:** Always checkboxes `- [ ]`, minimum 3, maximum 7

#### Implementation Steps

**Sources (priority order):**

1. "Implementation Plan" section
2. "Technical Approach" steps
3. "How to" instructions
4. **Generate from requirement** if none found

**Generation rules if missing:**

```markdown
For "Implement OAuth2 authentication":

1. Research OAuth2 libraries and select best fit
2. Create OAuth2 client wrapper class
3. Implement authorization code flow
4. Add token storage mechanism
5. Integrate with existing auth middleware
6. Write unit and integration tests
7. Update authentication documentation
```

**Format:** Always numbered list `1.`, minimum 3, maximum 10

### Phase 3: Priority Classification

**Mapping logic:**

| Spec Language                                  | Priority | Rationale               |
| ---------------------------------------------- | -------- | ----------------------- |
| "critical", "must have", "blocker"             | P0       | Essential functionality |
| "security requirement", "data loss prevention" | P0       | Risk mitigation         |
| "high priority", "should have"                 | P1       | Important features      |
| "performance requirement"                      | P1       | User experience         |
| "nice to have", "could have"                   | P2       | Optional improvements   |
| "usability requirement"                        | P2       | Enhancement             |
| "future", "enhancement"                        | P3       | Deferred features       |
| "functional requirement" (default)             | P1       | Standard features       |

**Fallback:** P1 (high) if no priority signals detected

### Phase 4: Effort Estimation

**Estimation heuristics:**

| Requirement Type                | Base Hours | Multipliers |
| ------------------------------- | ---------- | ----------- |
| "fix", "update", "modify"       | 2h         | -           |
| "new feature", "implement"      | 4h         | +2h         |
| "integration", "api", "service" | 4h         | +4h         |
| "migration", "refactor"         | 4h         | +6h         |

**Complexity multipliers:**

- Security/auth: ×1.5
- Database/schema: ×1.3
- UI/frontend: ×1.2
- Testing overhead: ×1.3 (add 30%)

**Examples:**

- "Add login button" → 2h
- "Implement OAuth2 authentication" → 12h
- "Migrate 10K users to new auth system" → 24h

### Phase 5: File Change Inference

**Extraction logic:**

1. **Check for explicit file mentions** in spec:

   ```markdown
   Files affected:

   - src/auth/oauth-client.ts (new)
   - src/middleware/auth.ts (modify)
   - src/auth/legacy-auth.ts (delete)
   ```

2. **Infer from component names:**
   - "OAuth Client" → `src/lib/auth/oauth-client.ts` (create)
   - "Token Manager" → `src/lib/auth/token-manager.ts` (create)
   - "Update auth middleware" → `src/middleware/auth.ts:XX-YY` (modify)

3. **Standard patterns by requirement type:**
   - **API endpoint:** Create `src/routes/{feature}.ts`, `src/controllers/{feature}.ts`
   - **Database model:** Create `src/models/{entity}.ts`, modify `src/models/index.ts`
   - **UI component:** Create `src/components/{Component}.tsx`, `{Component}.module.css`
   - **Tests:** Always create `tests/{type}/{feature}.test.ts`

4. **Fallback if no file info:**

   ```markdown
   ### Files to Create

   - TBD - To be determined during implementation

   ### Files to Modify

   - TBD - To be determined during implementation

   ### Files to Delete

   - None
   ```

### Phase 6: Testing Table Generation

**Generation from acceptance criteria:**

For each AC, infer test type:

- **Unit:** AC mentions "function", "class", "method", "logic"
- **Integration:** AC mentions "API", "service", "database", "flow"
- **E2E:** AC mentions "user", "UI", "workflow", "end-to-end"

**Example output:**

| Test Type   | Validates AC | Description                       | Location                         |
| ----------- | ------------ | --------------------------------- | -------------------------------- |
| Unit        | AC1, AC2     | Verify OAuth client configuration | `tests/unit/auth/oauth.test.ts`  |
| Integration | AC3, AC4     | Verify full authentication flow   | `tests/integration/auth.test.ts` |
| E2E         | AC5          | Verify user can log in via OAuth  | `tests/e2e/login.spec.ts`        |

### Phase 7: Dependency Extraction

**Extraction logic:**

1. **Check for explicit dependencies** in spec:

   ```markdown
   ## Dependencies

   - Requires FR1 (OAuth2 setup) to be completed first
   - Blocks FR5 (user profile migration)
   ```

2. **Infer from requirements order:**
   - FR1 must complete before FR2 if FR2 mentions FR1
   - Sequential phases create dependency chain

3. **Technical dependencies:**
   - "Database migration" blocks everything touching that table
   - "API changes" block frontend features using those APIs

**Format:**

```markdown
**Blocking Dependencies:** T0001 (OAuth2 setup), T0003 (Database schema)
**Blocks:** T0005 (User profile), T0007 (Admin panel)

**Prerequisites:**

- [ ] OAuth2 library selected and approved
- [ ] Database schema changes reviewed
```

### Phase 8: Component Classification

Invoke **component-manager skill** to classify each requirement:

**Example workflow:**

- Requirement relates to: "OAuth2 Authentication"
- Component-manager skill returns: C05 (Authentication & Authorization)
- Use in task: **Component:** C05: Authentication & Authorization

### Phase 9: Task ID Generation

Invoke **id-generator skill** for each task:

**Example workflow:**

- Component: C05 (Authentication)
- Priority: P0
- Sequence: 1
- Generated ID: C05-P0-001

### Phase 10: Create Task Files

Output task files in `tasks/` directory with complete metadata.

---

## Priority Classification Examples

### P0 (Critical)

- Security requirements: "System shall encrypt all PII"
- Data integrity: "Prevent duplicate records"
- Blockers: "Must complete before Phase 2"
- Must-have features: "Core authentication required for launch"

### P1 (High Priority)

- Functional requirements: "User can create account"
- Performance requirements: "Page load under 2 seconds"
- Should-have features: "Email notifications"

### P2 (Medium Priority)

- Nice-to-have features: "Dark mode support"
- Usability improvements: "Autocomplete suggestions"
- Code quality: "Refactor legacy auth module"

### P3 (Low Priority)

- Future enhancements: "Social media integration"
- Optional features: "Export to PDF"
- Stretch goals: "AI-powered recommendations"

---

## Special Cases

### Specs with No Explicit Requirements

If spec has no FR# or US-### markers:

1. Break by major headings (## level)
2. Each major section becomes a task
3. Use heading as task title
4. Generate ACs from section content

### Specs with Only High-Level Goals

If spec is very high-level:

1. Extract goals as task titles
2. Generate implementation steps from context
3. Mark file changes as TBD
4. Flag for human review: `<!-- WARNING: Generated from high-level spec, needs refinement -->`

### Specs with Conflicting Requirements

If requirements conflict:

1. Create tasks for both conflicting requirements
2. Add dependency note: `**Conflict:** Conflicts with T0003, needs clarification`
3. Set priority to P3 until resolved

---

## Integration with Convert Command

The convert command routes spec documents to this skill:

```bash
# User invokes convert
/convert docs/specs/auth-redesign-spec.md

# detect-input-type skill detects "spec" type
# Routes to format-spec skill
# format-spec extracts requirements and creates tasks
# Output: tasks/C05-P0-001.md, tasks/C05-P1-002.md, etc.
```

---

## Quality Checks

Before finalizing tasks:

- [ ] All requirements from spec have corresponding tasks
- [ ] No requirements skipped or merged inappropriately
- [ ] Each task has all 10 enrichments (see SHARED_ENRICHMENTS.md)
- [ ] Priority classification reflects spec language
- [ ] File changes match project structure
- [ ] Testing table covers all ACs
- [ ] Dependencies correctly identified
- [ ] Component classification applied
- [ ] Task IDs generated

---

## Notes

- This skill generates tasks from requirements, not findings
- Priority mapping differs from bug priority (specs use "must have" vs "P0-P3")
- File changes often need TBD markers for specs (unlike code reviews with known files)
- Implementation steps may need generation if spec lacks detail
- User stories map cleanly to tasks (1:1 relationship)
- Component-based specs may need additional task splitting
- Always reference SHARED_ENRICHMENTS.md for complete enrichment patterns
