# Prompt Engineering Test Automation - Technical Specification

**Version**: 1.0.0
**Status**: Approved
**Last Updated**: 2025-01-06

---

## Executive Summary

This specification defines an automated testing system for prompt engineering in the task-streams plugin. The system enables confident modification of SKILL.md prompts and supporting documentation by providing immediate feedback on structural validity, output quality, and consistency.

**Key Innovation**: Separate slow LLM invocation from fast validation via response caching, enabling deterministic, fast, free testing of non-deterministic LLM outputs.

---

## 1. Architecture Overview

### 1.1 Three-Layer Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Test Orchestrator                  │
│  (Coordinates test suites, generates reports)       │
└──────────────────┬──────────────────────────────────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
       ▼           ▼           ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│Structure │ │ Quality  │ │Consistency│
│  Tests   │ │  Tests   │ │  Tests   │
│  (Fast)  │ │ (Medium) │ │  (Slow)  │
└────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │
     └────────────┼────────────┘
                  │
       ┌──────────┴──────────┐
       │                     │
       ▼                     ▼
┌──────────────┐      ┌──────────────┐
│ Skill        │      │ Output       │
│ Invoker      │─────▶│ Validator    │
│              │      │              │
│ (API/Cache)  │      │ (Existing)   │
└──────────────┘      └──────────────┘
       │
       ▼
┌──────────────┐
│ Response     │
│ Cache        │
│              │
│ (SHA256-key) │
└──────────────┘
```

### 1.2 Component Responsibilities

**Skill Invoker** (`tests/helpers/skill-invoker.ts`)

- Loads SKILL.md and supporting files
- Constructs full prompt with input document
- Checks response cache first (SHA256 key)
- Calls Claude API if cache miss
- Saves response to cache

**Response Cache** (`test-cache/`)

- SHA256-keyed storage (includes all prompt files in hash)
- Git-committed cache files (all developers benefit)
- Invalidates automatically on prompt changes
- Manifest tracks cache metadata

**Output Validator** (Existing: `validators/validate-*.ts`)

- Checks structural validity (all 10 enrichments present)
- Used as automation layer by tests
- No changes needed - reuse existing validators

**Quality Assessor** (`tests/helpers/quality-assessor.ts`)

- Substantiveness: Detects vague content ("Fix the bug", "TBD")
- Adherence: Checks guideline compliance (5 risk dimensions, line ranges)
- Consistency: Multi-run comparison for stable decisions

**Test Orchestrator** (`tests/integration/prompt-engineering.test.ts`)

- Coordinates three test suites
- Generates combined test reports
- Manages cache usage (cached vs fresh modes)

---

## 2. Response Caching System

### 2.1 Cache Directory Structure

```
test-cache/
├── skill-responses/
│   ├── format-bug-findings/
│   │   ├── review-001-batch-failures.json
│   │   ├── review-002-null-checks.json
│   │   └── [sha256-hash].json
│   ├── format-spec/
│   │   ├── spec-oauth-implementation.json
│   │   └── [sha256-hash].json
│   ├── format-tech-debt/
│   ├── format-security/
│   └── format-generic/
├── cache-manifest.json
└── README.md  # Explains cache purpose and workflow
```

### 2.2 Cache Manifest Format

```json
{
  "version": "1.0.0",
  "lastUpdated": "2025-01-06T10:30:00Z",
  "entries": [
    {
      "key": "sha256-abc123def456...",
      "skill": "format-bug-findings",
      "inputFile": "review-001-batch-failures.md",
      "outputFile": "skill-responses/format-bug-findings/review-001-batch-failures.json",
      "createdAt": "2025-01-05T09:00:00Z",
      "promptVersion": "1.2.0",
      "apiModel": "claude-sonnet-4",
      "tokenCount": 8450
    }
  ]
}
```

### 2.3 Cache Key Generation

```typescript
// tests/helpers/cache-manager.ts

export function generateCacheKey(
  skillName: string,
  inputDocument: string
): string {
  // Load ALL files that influence prompt behavior
  const skillMd = readFileSync(
    `.claude-plugins/task-streams/skills/${skillName}/SKILL.md`
  )
  const workflow = readFileSync(
    `.claude-plugins/task-streams/skills/${skillName}/WORKFLOW.md`
  )
  const examples = readFileSync(
    `.claude-plugins/task-streams/skills/${skillName}/EXAMPLES.md`
  )
  const troubleshooting = readFileSync(
    `.claude-plugins/task-streams/skills/${skillName}/TROUBLESHOOTING.md`
  )
  const validation = readFileSync(
    `.claude-plugins/task-streams/skills/${skillName}/VALIDATION_CHECKLIST.md`
  )
  const sharedEnrichments = readFileSync(
    `.claude-plugins/task-streams/skills/SHARED_ENRICHMENTS.md`
  )

  // Combine everything that affects output
  const combined = [
    `skill:${skillName}`,
    `input:${inputDocument}`,
    `skill-md:${skillMd}`,
    `workflow:${workflow}`,
    `examples:${examples}`,
    `troubleshooting:${troubleshooting}`,
    `validation:${validation}`,
    `shared:${sharedEnrichments}`,
  ].join("|||")

  return crypto.createHash("sha256").update(combined).digest("hex")
}
```

### 2.4 Cache Invalidation

**Automatic invalidation** occurs when:

- Any SKILL.md file modified
- Any supporting file modified (WORKFLOW.md, EXAMPLES.md, etc.)
- SHARED_ENRICHMENTS.md modified
- Input fixture modified

**Manual invalidation** via CLI:

```bash
# Refresh all cached responses
pnpm test:prompt:refresh

# Refresh specific skill
pnpm test:prompt:refresh --skill=format-bug-findings

# Clear entire cache
pnpm test:prompt:clear-cache
```

---

## 3. Quality Assessment System

### 3.1 Substantiveness Assessment

**Purpose**: Detect vague, non-actionable content

```typescript
// tests/helpers/quality-assessor.ts

interface SubstantivenessReport {
  vacuousACs: Array<{ line: number; text: string }> // "Fix the bug"
  genericDescriptions: Array<{ section: string; text: string }> // "This is a problem"
  tbdMarkers: Array<{ location: string; context: string }> // "TBD", "[file]"
  missingDetails: Array<{ enrichment: string; reason: string }> // No line ranges
  score: number // 0-100
}

export async function assessSubstantiveness(
  output: string
): Promise<SubstantivenessReport> {
  const report: SubstantivenessReport = {
    vacuousACs: [],
    genericDescriptions: [],
    tbdMarkers: [],
    missingDetails: [],
    score: 100,
  }

  // Check acceptance criteria for vague language
  const acSection = extractSection(output, "Acceptance Criteria")
  const acLines = acSection
    .split("\n")
    .filter((l) => l.trim().startsWith("- [ ]"))

  const vacuousPatterns = [
    /fix the bug/i,
    /improve (performance|quality|code)/i,
    /add tests/i,
    /make it better/i,
  ]

  for (const [lineNum, line] of acLines.entries()) {
    for (const pattern of vacuousPatterns) {
      if (pattern.test(line)) {
        report.vacuousACs.push({ line: lineNum, text: line })
        report.score -= 10
      }
    }
  }

  // Check file locations have line ranges
  const fileLocations = extractFileLocations(output)
  for (const loc of fileLocations) {
    if (!loc.match(/\.\w+:\d+-\d+/)) {
      // file.ts:100-150
      report.missingDetails.push({
        enrichment: "File Locations",
        reason: `Missing line range: ${loc}`,
      })
      report.score -= 5
    }
  }

  // Check for TBD markers
  const tbdMatches = output.match(/\bTBD\b/gi) || []
  if (tbdMatches.length > 2) {
    // Allow 2, flag if more
    report.tbdMarkers.push({
      location: "Multiple sections",
      context: `Found ${tbdMatches.length} TBD markers`,
    })
    report.score -= 15
  }

  return report
}
```

### 3.2 Adherence Assessment

**Purpose**: Check compliance with style guidelines

```typescript
interface AdherenceReport {
  guidelineViolations: Array<{
    guideline: string
    severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW"
    location: string
    example: string
  }>
  score: number // 0-100
}

export async function assessAdherence(
  output: string,
  formatType: string
): Promise<AdherenceReport> {
  const violations = []
  let score = 100

  // CRITICAL: All 5 risk dimensions present
  const riskSection = extractSection(output, "Regression Risk Details")
  const requiredDimensions = [
    "Impact:",
    "Blast Radius:",
    "Dependencies:",
    "Testing Gaps:",
    "Rollback Risk:",
  ]

  const missingDimensions = requiredDimensions.filter(
    (d) => !riskSection.includes(d)
  )
  if (missingDimensions.length > 0) {
    violations.push({
      guideline: "All 5 risk dimensions required",
      severity: "CRITICAL",
      location: "Regression Risk Details",
      example: `Missing: ${missingDimensions.join(", ")}`,
    })
    score -= 20
  }

  // HIGH: File locations use backticks and line ranges
  const fileLocations = extractFileLocations(output)
  for (const loc of fileLocations) {
    if (!loc.startsWith("`") || !loc.endsWith("`")) {
      violations.push({
        guideline: "File locations must use backticks",
        severity: "HIGH",
        location: loc,
        example: "Should be: `file.ts:100-150`",
      })
      score -= 10
    }
  }

  // MEDIUM: Acceptance criteria use checkbox format
  const acSection = extractSection(output, "Acceptance Criteria")
  if (!acSection.includes("- [ ]")) {
    violations.push({
      guideline: "Acceptance criteria must use - [ ] format",
      severity: "MEDIUM",
      location: "Acceptance Criteria",
      example: "Should be: - [ ] Specific criterion",
    })
    score -= 5
  }

  // MEDIUM: Implementation steps numbered
  const implSection = extractSection(output, "Implementation Steps")
  if (!implSection.match(/^\d+\./m)) {
    violations.push({
      guideline: "Implementation steps must be numbered",
      severity: "MEDIUM",
      location: "Implementation Steps",
      example: "Should be: 1. First step",
    })
    score -= 5
  }

  return {
    guidelineViolations: violations,
    score: Math.max(0, score),
  }
}
```

### 3.3 Consistency Assessment

**Purpose**: Check if skill makes stable structural decisions

```typescript
interface ConsistencyReport {
  stableFields: string[] // Fields that matched across runs
  unstableFields: string[] // Fields that varied
  runs: number // Number of comparison runs
  threshold: number // Acceptable variance (0-1)
  score: number // 0-100
}

export async function assessConsistency(
  skillName: string,
  inputDocument: string,
  runs: number = 3
): Promise<ConsistencyReport> {
  const outputs: string[] = []

  // Generate multiple outputs (SLOW - cache is bypassed)
  for (let i = 0; i < runs; i++) {
    const output = await invokeSkillFresh(skillName, inputDocument)
    outputs.push(output)
  }

  // Compare structural elements
  const components = outputs.map((o) => extractComponent(o))
  const priorities = outputs.map((o) => extractPriority(o))
  const complexities = outputs.map((o) => extractComplexity(o))
  const regressionRisks = outputs.map((o) => extractRegressionRisk(o))

  const stableFields: string[] = []
  const unstableFields: string[] = []

  // Check component consistency
  if (allSame(components)) {
    stableFields.push("component")
  } else {
    unstableFields.push("component")
  }

  // Check priority consistency
  if (allSame(priorities)) {
    stableFields.push("priority")
  } else {
    unstableFields.push("priority")
  }

  // Check complexity consistency
  if (allSame(complexities)) {
    stableFields.push("complexity")
  } else {
    unstableFields.push("complexity")
  }

  // Check regression risk consistency
  if (allSame(regressionRisks)) {
    stableFields.push("regressionRisk")
  } else {
    unstableFields.push("regressionRisk")
  }

  const stabilityRate =
    stableFields.length / (stableFields.length + unstableFields.length)

  return {
    stableFields,
    unstableFields,
    runs,
    threshold: 0.8, // 80% of fields should be stable
    score: stabilityRate * 100,
  }
}
```

---

## 4. Test Suites

### 4.1 Structure Test Suite (Fast, Deterministic)

**Purpose**: Validate all 10 enrichments present and properly formatted

```typescript
// tests/integration/prompt-engineering.test.ts

describe("Prompt Engineering - Structure Tests", () => {
  const fixtures = [
    { input: "review-001-batch-failures.md", skill: "format-bug-findings" },
    { input: "spec-oauth-implementation.md", skill: "format-spec" },
    { input: "tech-debt-q4-2025.md", skill: "format-tech-debt" },
    { input: "security-pentest-findings.md", skill: "format-security" },
    { input: "generic-api-improvements.md", skill: "format-generic" },
  ]

  fixtures.forEach(({ input, skill }) => {
    describe(`${skill} with ${input}`, () => {
      let output: string

      beforeAll(async () => {
        const inputDoc = await readFixture(input)
        output = await invokeSkill(skill, inputDoc) // Uses cache by default
      })

      it("should produce valid structure", async () => {
        const validator = getValidatorForSkill(skill)
        const result = validator.validate(output)

        expect(result.passed).toBe(true)
        expect(result.results.filter((r) => r.passed)).toHaveLength(12)
      })

      it("should include all 10 enrichments", () => {
        const validation = validateTemplateHasAllEnrichments(output)
        expect(validation.passed).toBe(true)
        expect(validation.missing).toHaveLength(0)
      })

      it("should include all 5 risk dimensions", () => {
        const riskDimensions = [
          "**Impact:**",
          "**Blast Radius:**",
          "**Dependencies:**",
          "**Testing Gaps:**",
          "**Rollback Risk:**",
        ]
        riskDimensions.forEach((dimension) => {
          expect(output).toContain(dimension)
        })
      })
    })
  })
})
```

**Execution time**: < 10 seconds (cached)
**Cost**: Free (uses cache)
**Run frequency**: Every commit

### 4.2 Quality Test Suite (Medium, Non-Deterministic)

**Purpose**: Assess content quality (substantiveness, adherence)

```typescript
describe("Prompt Engineering - Quality Tests", () => {
  const fixtures = [
    { input: "review-001-batch-failures.md", skill: "format-bug-findings" },
    // ... same 5 fixtures
  ]

  fixtures.forEach(({ input, skill }) => {
    describe(`${skill} quality`, () => {
      let output: string

      beforeAll(async () => {
        const inputDoc = await readFixture(input)
        output = await invokeSkill(skill, inputDoc)
      })

      it("should produce substantive content", async () => {
        const quality = await assessSubstantiveness(output)

        // No vague acceptance criteria
        expect(quality.vacuousACs).toHaveLength(0)

        // Minimal generic descriptions
        expect(quality.genericDescriptions.length).toBeLessThan(2)

        // Minimal TBD markers
        expect(quality.tbdMarkers.length).toBeLessThan(3)

        // High overall score
        expect(quality.score).toBeGreaterThan(70)
      })

      it("should adhere to guidelines", async () => {
        const adherence = await assessAdherence(output, skill)

        // No critical violations
        const criticalViolations = adherence.guidelineViolations.filter(
          (v) => v.severity === "CRITICAL"
        )
        expect(criticalViolations).toHaveLength(0)

        // High adherence score
        expect(adherence.score).toBeGreaterThan(85)
      })

      it("should include line ranges in file locations", () => {
        const fileLocations = extractFileLocations(output)
        const withLineRanges = fileLocations.filter((loc) =>
          loc.match(/\.\w+:\d+-\d+/)
        )

        // At least 80% should have line ranges
        expect(withLineRanges.length / fileLocations.length).toBeGreaterThan(
          0.8
        )
      })
    })
  })
})
```

**Execution time**: < 15 seconds (cached)
**Cost**: Free (uses cache)
**Run frequency**: Every commit

### 4.3 Consistency Test Suite (Slow, Multi-Run)

**Purpose**: Verify stable structural decisions across multiple runs

```typescript
describe("Prompt Engineering - Consistency Tests", () => {
  // Only test 2 fixtures (slow test suite)
  const fixtures = [
    { input: "review-001-batch-failures.md", skill: "format-bug-findings" },
    { input: "spec-oauth-implementation.md", skill: "format-spec" },
  ]

  fixtures.forEach(({ input, skill }) => {
    it(
      `${skill} should produce consistent structural decisions`,
      async () => {
        const inputDoc = await readFixture(input)
        const report = await assessConsistency(skill, inputDoc, 3)

        // Component classification should be stable
        expect(report.stableFields).toContain("component")

        // Priority assessment should be stable
        expect(report.stableFields).toContain("priority")

        // Overall stability threshold
        expect(report.score).toBeGreaterThan(80)

        // At least 80% of fields stable
        const stabilityRate =
          report.stableFields.length /
          (report.stableFields.length + report.unstableFields.length)
        expect(stabilityRate).toBeGreaterThan(0.8)
      },
      { timeout: 120000 }
    ) // 2 minute timeout per test
  })
})
```

**Execution time**: ~10 minutes (3 runs × 2 fixtures × ~1.5 min/run)
**Cost**: ~$0.30 per run (assuming $0.05 per API call)
**Run frequency**: Weekly or on-demand

---

## 5. Skill Invoker Implementation

### 5.1 Core Invoker

```typescript
// tests/helpers/skill-invoker.ts

import { Anthropic } from "@anthropic-ai/sdk"
import { readFileSync } from "fs"
import { generateCacheKey, loadFromCache, saveToCache } from "./cache-manager"

interface InvokeOptions {
  useCache?: boolean // Default: true
  cacheOnly?: boolean // Default: false (fail if cache miss)
  refreshCache?: boolean // Default: false (force API call)
}

export async function invokeSkill(
  skillName: string,
  inputDocument: string,
  options: InvokeOptions = {}
): Promise<string> {
  const { useCache = true, cacheOnly = false, refreshCache = false } = options

  // Generate cache key
  const cacheKey = generateCacheKey(skillName, inputDocument)

  // Check cache first (unless refreshing)
  if (useCache && !refreshCache) {
    const cachedResponse = await loadFromCache(skillName, cacheKey)
    if (cachedResponse) {
      console.log(`✓ Cache hit: ${skillName}`)
      return cachedResponse
    }

    if (cacheOnly) {
      throw new Error(`Cache miss: ${skillName} (cacheOnly mode)`)
    }
  }

  // Load skill prompt
  const skillMd = readFileSync(
    `.claude-plugins/task-streams/skills/${skillName}/SKILL.md`,
    "utf-8"
  )

  // Construct full prompt
  const fullPrompt = `${skillMd}\n\n---\n\n${inputDocument}`

  // Call Claude API
  console.log(`⟳ API call: ${skillName}`)
  const client = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY,
  })

  const message = await client.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 16000,
    messages: [{ role: "user", content: fullPrompt }],
  })

  const response =
    message.content[0].type === "text" ? message.content[0].text : ""

  // Save to cache
  if (useCache) {
    await saveToCache(skillName, cacheKey, response, {
      inputFile: inputDocument.substring(0, 100), // Truncate for manifest
      promptVersion: extractPromptVersion(skillMd),
      apiModel: "claude-sonnet-4",
      tokenCount: message.usage.input_tokens + message.usage.output_tokens,
    })
  }

  return response
}

// Convenience wrappers
export async function invokeSkillCached(
  skillName: string,
  inputDocument: string
): Promise<string> {
  return invokeSkill(skillName, inputDocument, { cacheOnly: true })
}

export async function invokeSkillFresh(
  skillName: string,
  inputDocument: string
): Promise<string> {
  return invokeSkill(skillName, inputDocument, { refreshCache: true })
}
```

### 5.2 Cache Manager

```typescript
// tests/helpers/cache-manager.ts

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "fs"
import { join } from "path"
import crypto from "crypto"

interface CacheEntry {
  key: string
  skill: string
  inputFile: string
  outputFile: string
  createdAt: string
  promptVersion: string
  apiModel: string
  tokenCount: number
}

interface CacheManifest {
  version: string
  lastUpdated: string
  entries: CacheEntry[]
}

const CACHE_DIR = join(__dirname, "../../test-cache")
const MANIFEST_PATH = join(CACHE_DIR, "cache-manifest.json")

export function generateCacheKey(
  skillName: string,
  inputDocument: string
): string {
  const skillDir = `.claude-plugins/task-streams/skills/${skillName}`

  // Load all files that influence output
  const files = [
    readFileSync(`${skillDir}/SKILL.md`, "utf-8"),
    readFileSync(`${skillDir}/WORKFLOW.md`, "utf-8"),
    readFileSync(`${skillDir}/EXAMPLES.md`, "utf-0"),
    readFileSync(`${skillDir}/TROUBLESHOOTING.md`, "utf-8"),
    readFileSync(`${skillDir}/VALIDATION_CHECKLIST.md`, "utf-8"),
    readFileSync(
      ".claude-plugins/task-streams/skills/SHARED_ENRICHMENTS.md",
      "utf-8"
    ),
  ]

  const combined = `${skillName}|||${inputDocument}|||${files.join("|||")}`
  return crypto.createHash("sha256").update(combined).digest("hex")
}

export async function loadFromCache(
  skillName: string,
  cacheKey: string
): Promise<string | null> {
  const manifest = loadManifest()
  const entry = manifest.entries.find((e) => e.key === cacheKey)

  if (!entry) return null

  const cachePath = join(CACHE_DIR, entry.outputFile)
  if (!existsSync(cachePath)) return null

  return readFileSync(cachePath, "utf-8")
}

export async function saveToCache(
  skillName: string,
  cacheKey: string,
  response: string,
  metadata: Partial<CacheEntry>
): Promise<void> {
  // Create skill directory
  const skillCacheDir = join(CACHE_DIR, "skill-responses", skillName)
  if (!existsSync(skillCacheDir)) {
    mkdirSync(skillCacheDir, { recursive: true })
  }

  // Save response
  const outputFile = `skill-responses/${skillName}/${cacheKey}.json`
  const cachePath = join(CACHE_DIR, outputFile)
  writeFileSync(cachePath, JSON.stringify({ response }, null, 2))

  // Update manifest
  const manifest = loadManifest()
  manifest.entries.push({
    key: cacheKey,
    skill: skillName,
    outputFile,
    createdAt: new Date().toISOString(),
    ...metadata,
  } as CacheEntry)

  manifest.lastUpdated = new Date().toISOString()
  saveManifest(manifest)
}

function loadManifest(): CacheManifest {
  if (!existsSync(MANIFEST_PATH)) {
    return {
      version: "1.0.0",
      lastUpdated: new Date().toISOString(),
      entries: [],
    }
  }
  return JSON.parse(readFileSync(MANIFEST_PATH, "utf-8"))
}

function saveManifest(manifest: CacheManifest): void {
  writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2))
}
```

---

## 6. CLI Commands

### 6.1 Test Execution Commands

```bash
# Use cached responses (default, fast, free)
pnpm test:prompt

# Run only structure tests
pnpm test:prompt:structure

# Run only quality tests
pnpm test:prompt:quality

# Run only consistency tests (slow)
pnpm test:prompt:consistency

# Run all tests with fresh API calls (slow, costs money)
pnpm test:prompt:refresh

# Refresh specific skill
pnpm test:prompt:refresh --skill=format-bug-findings
```

### 6.2 Cache Management Commands

```bash
# Show cache statistics
pnpm test:prompt:cache-stats

# Validate cache integrity
pnpm test:prompt:cache-validate

# Clear entire cache
pnpm test:prompt:cache-clear

# Clear cache for specific skill
pnpm test:prompt:cache-clear --skill=format-spec

# Export cache manifest
pnpm test:prompt:cache-export > cache-report.json
```

### 6.3 Package.json Scripts

```json
{
  "scripts": {
    "test:prompt": "vitest run tests/integration/prompt-engineering.test.ts",
    "test:prompt:structure": "vitest run tests/integration/prompt-engineering.test.ts -t 'Structure Tests'",
    "test:prompt:quality": "vitest run tests/integration/prompt-engineering.test.ts -t 'Quality Tests'",
    "test:prompt:consistency": "vitest run tests/integration/prompt-engineering.test.ts -t 'Consistency Tests'",
    "test:prompt:refresh": "REFRESH_CACHE=true vitest run tests/integration/prompt-engineering.test.ts",
    "test:prompt:cache-stats": "tsx tests/helpers/cache-stats.ts",
    "test:prompt:cache-validate": "tsx tests/helpers/cache-validate.ts",
    "test:prompt:cache-clear": "tsx tests/helpers/cache-clear.ts"
  }
}
```

---

## 7. Implementation Phases

### Phase 1: Core Infrastructure (Week 1)

**Deliverables:**

- `tests/helpers/skill-invoker.ts` - Basic skill invocation with cache
- `tests/helpers/cache-manager.ts` - Cache key generation and storage
- `test-cache/` directory structure
- Initial cache with 5 fixture responses (1 per format skill)
- CLI wrapper for Claude API calls

**Success Criteria:**

- Can invoke skill and get cached response
- Cache hit rate > 95% on second run
- Cache invalidates when prompts change

**Implementation Steps:**

1. Create `tests/helpers/skill-invoker.ts` with `invokeSkill()` function
2. Create `tests/helpers/cache-manager.ts` with SHA256 keying
3. Create `test-cache/` directory structure
4. Generate initial cache by calling API for 5 fixtures
5. Test cache hit/miss behavior
6. Commit cache files to git

### Phase 2: Quality Assessment (Week 2)

**Deliverables:**

- `tests/helpers/quality-assessor.ts` with 3 assessment functions
- Substantiveness checks (vague AC detection, TBD markers)
- Adherence checks (5 risk dimensions, line ranges, formatting)
- Consistency checks (multi-run comparison)
- Quality report generation

**Success Criteria:**

- Can assess quality of cached outputs
- Detects vague acceptance criteria
- Detects missing risk dimensions
- Consistency assessment completes in < 10 minutes

**Implementation Steps:**

1. Create `assessSubstantiveness()` function
2. Add vacuous AC detection patterns
3. Add TBD marker detection
4. Create `assessAdherence()` function
5. Add guideline compliance checks
6. Create `assessConsistency()` function
7. Add multi-run comparison logic
8. Test quality assessment on cached outputs

### Phase 3: Test Suites (Week 2-3)

**Deliverables:**

- `tests/integration/prompt-engineering.test.ts`
- Structure test suite (5 tests, one per format)
- Quality test suite (15 tests, 3 per format)
- Consistency test suite (2 tests, slow)
- Integration with Vitest

**Success Criteria:**

- All structure tests pass with cached responses (< 10 seconds)
- All quality tests pass with cached responses (< 15 seconds)
- Consistency tests complete successfully (< 10 minutes)

**Implementation Steps:**

1. Create `tests/integration/prompt-engineering.test.ts`
2. Implement structure test suite (use existing validators)
3. Implement quality test suite (use quality assessor)
4. Implement consistency test suite (multi-run)
5. Add timeout configuration for slow tests
6. Test all suites with cached responses
7. Document test execution workflow

### Phase 4: Cache Management (Week 3)

**Deliverables:**

- `scripts/manage-test-cache.ts` - Cache management CLI
- Cache validation script
- Cache statistics report
- Cache clear functionality
- Documentation on cache workflow

**Success Criteria:**

- Developers can refresh cache when needed
- Cache validation detects corruption
- Cache statistics show hit rates

**Implementation Steps:**

1. Create `scripts/manage-test-cache.ts`
2. Implement `cache-stats` command
3. Implement `cache-validate` command
4. Implement `cache-clear` command
5. Add cache export functionality
6. Write cache workflow documentation
7. Test cache management commands

### Phase 5: CI/CD Integration (Week 4)

**Deliverables:**

- GitHub Actions workflow for prompt tests
- Separate jobs: structure (fast), quality (medium), consistency (optional)
- Cache validation in pre-commit hooks
- Performance monitoring and reporting

**Success Criteria:**

- Tests run automatically on PRs
- Structure + quality tests complete in < 2 minutes
- Consistency tests run weekly
- Cache corruption detected before merge

**Implementation Steps:**

1. Create `.github/workflows/prompt-tests.yml`
2. Configure structure test job (required)
3. Configure quality test job (required)
4. Configure consistency test job (optional, weekly)
5. Add cache validation to pre-commit hooks
6. Set up performance monitoring
7. Test CI workflow on PR

### Phase 6: Golden Master Testing (Week 4)

**Deliverables:**

- Snapshot testing for output structure
- Diff reporting when outputs change
- Review workflow for prompt changes
- Documentation on golden master approach

**Success Criteria:**

- Prompt changes are reviewable via diffs
- Structural regressions detected automatically
- Developers understand when to update snapshots

**Implementation Steps:**

1. Add Vitest snapshot support
2. Create golden master snapshots for 5 fixtures
3. Configure snapshot update workflow
4. Add diff reporting to test output
5. Document snapshot review process
6. Test snapshot update workflow

---

## 8. Success Metrics

### 8.1 Development Metrics

- **Cache hit rate**: > 95% (most test runs use cache)
- **Test execution time**: < 10 seconds (with cache)
- **Test execution time**: < 5 minutes (full refresh for 5 fixtures)
- **Zero false positives**: Structure validation never fails on valid output

### 8.2 Quality Metrics

- **Structural validity**: 100% of outputs pass validation
- **Adherence score**: > 85% across all skills
- **Vague ACs**: < 5% of acceptance criteria flagged as vague
- **Component consistency**: > 90% stability across 3 runs
- **Priority consistency**: > 90% stability across 3 runs

### 8.3 Operational Metrics

- **CI pipeline duration**: < 2 minutes (cached mode)
- **Cache refresh cost**: < $5 per month
- **Manual prompt testing**: Zero (fully automated)
- **Developer confidence**: "I can confidently change prompts"

### 8.4 Monitoring Dashboard

```typescript
interface TestReport {
  timestamp: string
  mode: "cached" | "fresh"
  duration: number
  results: {
    structure: { passed: number; failed: number }
    quality: {
      substantiveness: number // 0-100 score
      adherence: number // 0-100 score
    }
    consistency: {
      stableFields: string[]
      unstableFields: string[]
      score: number // 0-100
    }
  }
  cacheStats: {
    hits: number
    misses: number
    hitRate: number
  }
}
```

Reports stored in `test-reports/` for trend analysis.

---

## 9. Developer Workflows

### 9.1 Daily Development (Fast, Cached)

```bash
# Make changes to SKILL.md or supporting files
vim .claude-plugins/task-streams/skills/format-bug-findings/WORKFLOW.md

# Run structure tests (< 10 seconds)
pnpm test:prompt:structure

# If tests pass, commit
git add .
git commit -m "refactor: improve workflow guidance"
```

### 9.2 Major Prompt Changes (Refresh Cache)

```bash
# Make significant changes to prompts
vim .claude-plugins/task-streams/skills/format-bug-findings/SKILL.md

# Refresh cache for this skill (API calls)
pnpm test:prompt:refresh --skill=format-bug-findings

# Review quality assessment
pnpm test:prompt:quality

# If quality improved, commit cache + changes
git add test-cache/ .claude-plugins/
git commit -m "feat: enhance bug finding enrichment prompts"
```

### 9.3 Weekly Quality Check (Full Suite)

```bash
# Run all tests including consistency (slow)
pnpm test:prompt:refresh
pnpm test:prompt:consistency

# Review quality reports
cat test-reports/prompt-quality-$(date +%Y%m%d).json

# Address any quality degradation
```

### 9.4 CI/CD Pipeline

**On every PR:**

- Structure tests run (cached, fast)
- Quality tests run (cached, fast)
- Cache validation runs

**Weekly (scheduled):**

- Consistency tests run (fresh API calls)
- Full cache refresh
- Quality trend report generated

---

## 10. Integration with Existing Tests

### 10.1 Test Pyramid Alignment

```
┌────────────────────────────────────┐
│         E2E Tests (Full)           │  ← Full pipeline (detect + format + validate)
│    tests/e2e/full-pipeline.test.ts │
└────────────────────────────────────┘
┌────────────────────────────────────┐
│    Integration Tests (Prompt)      │  ← Prompt engineering tests (THIS SPEC)
│ tests/integration/prompt-eng.test  │
└────────────────────────────────────┘
┌────────────────────────────────────┐
│      Unit Tests (Validators)       │  ← Existing validators (reused above)
│   validators/validate-*.test.ts    │
└────────────────────────────────────┘
```

### 10.2 Shared Fixtures

Prompt engineering tests use same fixtures as E2E tests:

- `test-fixtures/inputs/review-001-batch-failures.md`
- `test-fixtures/inputs/spec-oauth-implementation.md`
- `test-fixtures/inputs/tech-debt-q4-2025.md`
- `test-fixtures/inputs/security-pentest-findings.md`
- `test-fixtures/inputs/generic-api-improvements.md`

### 10.3 Shared Validators

Prompt engineering tests leverage existing validators:

- `validators/validate-finding.ts` → Used by structure tests
- `validators/validate-spec.ts` → Used by structure tests
- `validators/validate-tech-debt.ts` → Used by structure tests
- `validators/validate-security.ts` → Used by structure tests
- `validators/validate-generic.ts` → Used by structure tests

No duplication - prompt tests are an automation layer above validators.

---

## 11. File Structure

```
.claude-plugins/task-streams/
├── skills/
│   ├── format-bug-findings/
│   │   ├── SKILL.md              # Prompt content
│   │   ├── WORKFLOW.md           # Included in cache key
│   │   ├── EXAMPLES.md           # Included in cache key
│   │   ├── TROUBLESHOOTING.md    # Included in cache key
│   │   └── VALIDATION_CHECKLIST.md  # Included in cache key
│   └── SHARED_ENRICHMENTS.md     # Included in ALL cache keys
├── tests/
│   ├── helpers/
│   │   ├── skill-invoker.ts      # NEW - API invocation with cache
│   │   ├── cache-manager.ts      # NEW - Cache CRUD operations
│   │   └── quality-assessor.ts   # NEW - Quality assessment
│   └── integration/
│       └── prompt-engineering.test.ts  # NEW - Main test file
├── test-cache/                   # NEW - Git-committed cache
│   ├── skill-responses/
│   │   ├── format-bug-findings/
│   │   │   └── [hash].json
│   │   └── ...
│   ├── cache-manifest.json
│   └── README.md
├── test-reports/                 # NEW - Quality trend reports
│   └── prompt-quality-YYYYMMDD.json
├── scripts/
│   └── manage-test-cache.ts      # NEW - Cache management CLI
└── SPEC-PROMPT-ENGINEERING-TEST-AUTOMATION.md  # THIS FILE
```

---

## 12. Open Questions and Future Enhancements

### 12.1 Open Questions

1. **API Rate Limits**: How to handle Anthropic rate limits during cache refresh?
   - Proposed: Add backoff/retry logic with exponential backoff

2. **Cache Size**: What happens when cache grows to 100+ files?
   - Proposed: Add cache pruning for old entries (> 6 months)

3. **Cost Tracking**: How to track cumulative API costs?
   - Proposed: Add cost reporting to cache manifest

### 12.2 Future Enhancements

1. **Differential Testing**: Compare outputs before/after prompt changes
2. **A/B Testing**: Run two prompt versions in parallel, compare quality
3. **Quality Trends**: Track quality metrics over time, alert on degradation
4. **Prompt Optimization**: Automatically suggest prompt improvements based on quality issues
5. **Multi-Model Testing**: Test prompts across different Claude models (Sonnet, Opus)

---

## 13. Appendix: Example Cache Entry

```json
{
  "key": "sha256-a3f2b1c8d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1",
  "skill": "format-bug-findings",
  "inputFile": "review-001-batch-failures.md (truncated: Batch operation fails without rollback\n\nThe `migrateBatch()` func...)",
  "outputFile": "skill-responses/format-bug-findings/review-001-batch-failures.json",
  "createdAt": "2025-01-05T09:15:32Z",
  "promptVersion": "1.2.0",
  "apiModel": "claude-sonnet-4",
  "tokenCount": 8450
}
```

Corresponding output file:

```json
{
  "response": "### P0: Batch operation fails silently without rollback\n\n**Component:** C03: Migration & Batch Processing\n**Location:** `src/lib/migration/referral.ts:233-267`\n..."
}
```

---

## 14. Conclusion

This prompt engineering test automation system enables confident, rapid iteration on skill prompts while maintaining quality standards. By separating slow LLM invocation from fast validation via intelligent caching, we achieve:

- **Speed**: < 10 second test runs (cached)
- **Cost**: Free for most development (cache hit rate > 95%)
- **Quality**: Automated detection of vague content and guideline violations
- **Confidence**: Developers can refactor prompts without fear of breaking outputs

The system integrates seamlessly with existing validators and test infrastructure, providing a complete quality assurance pipeline from prompt to production.

**Next Steps**: Begin Phase 1 implementation (Core Infrastructure).
