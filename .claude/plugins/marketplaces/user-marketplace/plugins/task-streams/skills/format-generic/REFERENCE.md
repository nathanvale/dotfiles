## When Used

Automatically invoked when:

- detect-input-type returns 'generic' (low confidence)
- Document is ADR (ADRs route here intentionally)
- User provides custom documentation format
- Mixed content from multiple types
- Novel documentation structure

## Extraction Strategy

### Phase 1: Structural Analysis

Analyze document structure to find task boundaries:

#### 1.1: Identify Sections

```typescript
interface DocumentStructure {
  headings: Array<{
    level: number // H1, H2, H3, etc.
    text: string
    lineNumber: number
  }>
  lists: Array<{
    type: "checkbox" | "numbered" | "bulleted"
    items: string[]
    lineNumber: number
  }>
  codeBlocks: Array<{
    language?: string
    code: string
    lineNumber: number
  }>
  tables: Array<{
    headers: string[]
    rows: string[][]
    lineNumber: number
  }>
}
```

#### 1.2: Find Task Boundaries

**Heuristics** for where one task ends and another begins:

1. **Top-level headings** (H2, H3) often represent separate tasks
2. **Numbered items** in implementation sections
3. **Checkbox items** that are detailed (>20 words)
4. **Major sections** with substantial content (>100 words)

**Example:**

```markdown
## Improve Authentication Flow

{description}

### Acceptance Criteria

- [ ] Item 1
- [ ] Item 2

## Add User Profile Page

{description}

→ Two tasks identified (H2 boundaries)
```

### Phase 2: Extract Core Information

For each identified task boundary:

#### 2.1: Title

**Sources (in priority order):**

1. **Heading text** (remove markdown #)
2. **First sentence** of section if no heading
3. **Checkbox item text** if task is a single checkbox
4. **Numbered list first item** if task is from list

**Sanitization:**

```typescript
function extractTitle(sectionContent: string): string {
  // Get first H2/H3 heading or first sentence
  let title =
    extractHeading(sectionContent) || extractFirstSentence(sectionContent)

  // Sanitize
  title = title
    .replace(/^#+\s*/, "") // Remove markdown #
    .replace(/\*\*/g, "") // Remove bold
    .replace(/\[|\]/g, "") // Remove checkboxes
    .trim()

  // Limit length
  if (title.length > 80) {
    title = title.substring(0, 77) + "..."
  }

  return title || "Untitled Task"
}
```

#### 2.2: Description

**Extraction rules:**

1. **First paragraph** after heading
2. **Multiple paragraphs** until next section/list
3. **"Description:" or "Overview:"** labeled section
4. **Fallback:** Use title expanded as description

**Example:**

```markdown
## Implement User Profile

Users need a dedicated profile page to view and edit their information.

This includes basic details (name, email, photo) and account settings.

→ Description: "Users need a dedicated profile page... account settings."
```

#### 2.3: Acceptance Criteria

**Extraction strategies:**

1. **Explicit AC section**: Look for "Acceptance Criteria" heading

   ```markdown
   ## Acceptance Criteria

   - [ ] Criterion 1
   - [ ] Criterion 2
   ```

2. **"Requirements" section with checkboxes**

   ```markdown
   ## Requirements

   - [ ] Must support...
   - [ ] Must handle...
   ```

3. **"Goals" or "Objectives"** with checkboxes

4. **Generate from title** if none found

   ```markdown
   For "Implement User Profile":

   - [ ] User profile page created
   - [ ] User can view profile information
   - [ ] User can edit profile details
   ```

**Format enforcement:**

```typescript
function ensureCheckboxFormat(items: string[]): string[] {
  return items.map((item) => {
    // Remove existing checkbox if present
    item = item.replace(/^[-*]\s*\[[ x]\]\s*/, "")
    // Ensure checkbox format
    return `- [ ] ${item}`
  })
}
```

**Minimum 3, maximum 7 criteria**

#### 2.4: Implementation Steps

**Extraction strategies:**

1. **Explicit "Implementation" or "Steps" section**

   ```markdown
   ## Implementation Steps

   1. Create component
   2. Add routing
   3. Write tests
   ```

2. **Numbered lists** anywhere in section

   ```markdown
   To implement:

   1. First step
   2. Second step
   ```

3. **"How to" sections**

4. **Generate from title** if none found

   ```markdown
   For "Implement User Profile":

   1. Create profile page component
   2. Add routing for /profile
   3. Implement data fetching
   4. Add edit functionality
   5. Write unit and E2E tests
   ```

**Format enforcement:**

```typescript
function ensureNumberedFormat(items: string[]): string[] {
  return items.map((item, index) => {
    // Remove existing numbering/bullets
    item = item.replace(/^(\d+\.|-|\*)\s*/, "")
    // Apply numbered format
    return `${index + 1}. ${item}`
  })
}
```

**Minimum 3, maximum 10 steps**

#### 2.5: Priority

**Inference heuristics:**

```typescript
function inferPriority(content: string): string {
  const keywords = {
    P0: ["critical", "urgent", "blocker", "must fix", "security", "data loss"],
    P1: ["important", "high priority", "should", "needed soon"],
    P2: ["medium", "nice to have", "could", "enhancement"],
    P3: ["low", "minor", "future", "someday", "optional"],
  }

  for (const [priority, words] of Object.entries(keywords)) {
    if (words.some((word) => content.toLowerCase().includes(word))) {
      return priority
    }
  }

  // Default for unknown documents
  return "P2" // Medium - safe default for generic content
}
```

#### 2.6: Effort Estimate

**Inference from content signals:**

```typescript
function inferEffort(content: string, stepsCount: number): string {
  let baseHours = 4 // Default

  // Adjust based on content length
  const wordCount = content.split(/\s+/).length
  if (wordCount < 100) baseHours = 2
  if (wordCount > 500) baseHours = 8

  // Adjust based on implementation steps
  if (stepsCount >= 10) baseHours += 8
  else if (stepsCount >= 7) baseHours += 4
  else if (stepsCount >= 5) baseHours += 2

  // Complexity keywords
  if (/integration|migration|refactor|architecture/.test(content)) {
    baseHours *= 1.5
  }

  // Round to reasonable values
  const reasonable = [2, 4, 8, 12, 16, 24, 40]
  return `${reasonable.find((h) => h >= baseHours) || 40}h`
}
```

#### 2.7: Files to Change

**Extraction:**

1. **Look for explicit file mentions**

   ```markdown
   Files:

   - src/components/Profile.tsx
   - src/routes/profile.ts
   ```

2. **Code blocks with file comments**

   ```typescript
   // src/components/Profile.tsx
   export function Profile() { ... }
   ```

3. **Fallback: Mark as TBD**

   ```markdown
   ### Files to Create

   - TBD - To be determined during implementation

   ### Files to Modify

   - TBD - To be determined during implementation

   ### Files to Delete

   - None identified
   ```

#### 2.8: Testing Requirements

**Generate from acceptance criteria:**

```typescript
function generateTestingTable(acceptanceCriteria: string[]): string {
  const rows = acceptanceCriteria.map((ac, i) => {
    const acNum = `AC${i + 1}`
    // Infer test type from content
    const testType = inferTestType(ac)
    return `| ${testType} | ${acNum} | Verify ${ac} | TBD |`
  })

  return `
| Test Type | Validates AC | Description | Location |
|-----------|--------------|-------------|----------|
${rows.join("\n")}
  `.trim()
}

function inferTestType(ac: string): string {
  if (/\b(unit|function|method|class)\b/i.test(ac)) return "Unit"
  if (/\b(user|UI|interface|page)\b/i.test(ac)) return "E2E"
  return "Integration"
}
```

#### 2.9: Dependencies

**Extraction:**

1. **Look for "Depends on" or "Prerequisites" sections**
2. **Look for "Blocks" mentions**
3. **Fallback:**

   ```markdown
   **Blocking:** None identified
   **Blocked By:** None identified

   ## Prerequisites

   - [ ] TBD - Define prerequisites during planning
   ```

#### 2.10: Component Classification

**Use component-manager skill for classification:**

When extracting a task from generic content, invoke the **component-manager skill** to find or create the appropriate component code. The component-manager skill will:

1. Search existing components for a match based on task content
2. Create a new component if no match found
3. Return the component code for use in task metadata

**Inference from content:**

- Extract key terms from title and description (e.g., "API", "database", "authentication", "frontend")
- Use those terms to query component-manager skill for best match
- If no clear match, component-manager returns C00 (General / Cross-Cutting) as default

**Example workflow:**

- Task title: "Add user authentication to API endpoints"
- Key terms: "authentication", "API"
- Component-manager skill returns: C05 (Authentication & Authorization) as primary match
- Fallback to C00 if unable to determine specific component

The component-manager skill manages the component registry and ensures consistent component codes across all tasks.

### Phase 3: Handle Special Cases

#### Case 1: ADR Format

ADRs route to format-generic intentionally. Extract implementation tasks from "Decision" section:

```markdown
# ADR-005: Adopt OAuth2

## Status

Accepted

## Context

{Background}

## Decision

We will adopt OAuth2 authentication using Azure AD B2C.

## Consequences

### Positive

- Better security
- SSO support

### Negative

- Migration complexity

→ Extract task: "Implement OAuth2 authentication (ADR-005)"
```

**Extraction:**

- Title: "Implement {decision} (ADR-###)"
- Description: Context + Decision
- Acceptance Criteria: Generated from Consequences
- Priority: P1 (ADRs are architectural - usually important)

#### Case 2: Simple Todo List

```markdown
# Tasks

- [ ] Fix login bug
- [ ] Add user profile page
- [ ] Update documentation
- [ ] Write tests

→ 4 simple tasks, minimal enrichment
```

**Handling:**

- Each checkbox → separate task
- Description: TBD (user should add details)
- Steps: TBD
- Mark with note: "⚠️ Minimal context - review and enrich"

#### Case 3: Mixed Content

Document has some review findings, some tech debt, some spec requirements.

**Strategy:**

- Process all as generic tasks
- Note ambiguous classification in task description
- User can manually reclassify if needed

#### Case 4: Empty or Minimal Content

```markdown
# TODO

- Fix stuff
```

**Handling:**

- Create task but mark everything as TBD
- Note: "⚠️ Incomplete specification - define details before implementation"

### Phase 4: Quality Checks

Before generating task files:

```typescript
interface QualityCheck {
  hasTitle: boolean // Every task needs title
  hasDescription: boolean // At least basic description
  hasMinimumAC: boolean // At least 1 AC (prefer 3+)
  hasMinimumSteps: boolean // At least 1 step (prefer 3+)
  hasValidPriority: boolean // P0-P3
  hasComponent: boolean // C## code
}

function validateTask(task: Task): QualityCheck {
  return {
    hasTitle: task.title.length > 0,
    hasDescription: task.description.length > 20,
    hasMinimumAC: task.acceptanceCriteria.length >= 1,
    hasMinimumSteps: task.implementationSteps.length >= 1,
    hasValidPriority: /^P[0-3]$/.test(task.priority),
    hasComponent: /^C\d{2}$/.test(task.component),
  }
}
```

**Action on failures:**

- Missing title → Use "Task from {filename}"
- Missing description → Use title as description + TBD note
- No AC → Generate "- [ ] TBD - Define acceptance criteria"
- No steps → Generate "1. TBD - Define implementation steps"
- Invalid priority → Default to P2
- Invalid component → Default to C00

## Output: Generic Task File

```markdown
---
id: T0001
title: Implement user profile page
priority: P2
component: C08
status: READY
created: 2025-11-05T14:30:22Z
source: docs/planning/features.md
---

# T0001: Implement user profile page

**Component:** C08: Frontend (inferred from content)
**Priority:** P2 (Medium - default for generic content)
**Status:** READY
**Estimated Effort:** 8h (inferred from content length and steps)
**Complexity:** MEDIUM

## Description

{Extracted from document section}

Users need a dedicated profile page to view and edit their personal information, including name, email, and avatar.

⚠️ **Note:** This task was extracted from generic documentation. Review and enrich details before implementation.

## Acceptance Criteria

{Extracted from document or generated}

- [ ] User profile page accessible at /profile
- [ ] User can view current profile information
- [ ] User can edit name and email
- [ ] User can upload profile photo
- [ ] Changes saved successfully to database

## Implementation Steps

{Extracted from document or generated}

1. Create Profile page component
2. Add routing for /profile route
3. Implement profile data fetching from API
4. Add form for editing profile fields
5. Implement photo upload functionality
6. Add save functionality with API integration
7. Write unit tests for Profile component
8. Write E2E tests for profile workflow

## Files to Change

{Extracted or marked as TBD}

### Files to Create

- TBD - To be determined during implementation (likely: src/pages/Profile.tsx, tests, API route)

### Files to Modify

- TBD - To be determined during implementation

### Files to Delete

- None identified

## Testing Requirements

{Generated from acceptance criteria}

| Test Type   | Validates AC | Description                         | Location |
| ----------- | ------------ | ----------------------------------- | -------- |
| Unit        | AC1, AC2     | Verify profile data rendering       | TBD      |
| Integration | AC3, AC4     | Verify edit and save functionality  | TBD      |
| E2E         | AC5          | Verify full profile update workflow | TBD      |

## Dependencies

{Extracted or defaulted}

**Blocking:** None identified
**Blocked By:** None identified

## Prerequisites

{Extracted or defaulted}

- [ ] TBD - Define prerequisites during planning
- [ ] Profile API endpoint available
- [ ] User authentication working

## Regression Risk

{Inferred from content}

**Impact:** MEDIUM - User-facing feature
**Blast Radius:** LOW - Isolated to profile page
**Dependencies:** User API, authentication
**Testing Gaps:** Need comprehensive test coverage
**Rollback Risk:** LOW - New feature, easy to disable

## Code Examples

{Not available in generic documents}

**Note:** Code examples not available in source document. Define implementation approach during development.

## Notes

⚠️ **Extracted from generic documentation** - This task was created from unstructured content using best-effort extraction. Please review and enrich the following before implementation:

- [ ] Verify acceptance criteria are complete and testable
- [ ] Define specific implementation steps
- [ ] Identify files to change
- [ ] Specify test locations
- [ ] Clarify prerequisites and dependencies
- [ ] Add code examples if available

**Source:** docs/planning/features.md (section: "User Profile")
```

## Integration with Convert Command

```typescript
// Convert command routes generic documents here
const sections = analyzeDocumentStructure(content)
const taskBoundaries = identifyTaskBoundaries(sections)

const tasks = taskBoundaries.map((boundary) => {
  const title = extractTitle(boundary)
  const description = extractDescription(boundary)
  const acceptanceCriteria = extractOrGenerateAC(boundary)
  const implementationSteps = extractOrGenerateSteps(boundary)
  const priority = inferPriority(boundary)
  const effort = inferEffort(boundary, implementationSteps.length)
  const component = inferComponent(boundary.content, title)

  return createGenericTask({
    title,
    description,
    acceptanceCriteria,
    implementationSteps,
    priority,
    effort,
    component,
  })
})

// Flag tasks that need review
tasks.forEach((task) => {
  if (task.needsReview) {
    task.notes +=
      "\n\n⚠️ This task needs review and enrichment before implementation."
  }
})
```

## Quality Indicators

Tasks are flagged with indicators showing extraction confidence:

```markdown
## Extraction Quality

✅ **High Confidence:**

- Title: Extracted from H2 heading
- Description: Extracted from section content
- Acceptance Criteria: Explicit AC section found

⚠️ **Medium Confidence:**

- Implementation Steps: Generated from section content
- Priority: Inferred from keywords (default: P2)
- Effort: Estimated from content length

❌ **Low Confidence:**

- Files to Change: TBD (not specified in source)
- Testing Locations: TBD (not specified in source)
- Dependencies: Not specified in source
```

## Notes

- **Graceful degradation**: Creates best-possible tasks from any input
- **TBD marking**: Clearly marks uncertain/missing information
- **User refinement**: Expects user to validate and enrich via /validate
- **Safe defaults**: Uses P2/C00 when classification unclear
- **Extraction notes**: Documents what was extracted vs generated
- **Quality flags**: Indicates confidence level for each field
- **Fallback of last resort**: Better to create incomplete task than fail completely
