# Query Library

**Complete reference for all supported query types**

## Table of Contents
- [Query Type Index](#query-type-index)
- [1. blast-radius](#1-blast-radius)
  - [Input Schema](#input-schema)
  - [Output Schema](#output-schema)
  - [Algorithm](#algorithm)
  - [Performance](#performance)
- [2. find-callers](#2-find-callers)
  - [Input Schema](#input-schema-1)
  - [Output Schema](#output-schema-1)
  - [Algorithm](#algorithm-1)
  - [Performance](#performance-1)
- [3. find-calls](#3-find-calls)
  - [Input Schema](#input-schema-2)
  - [Output Schema](#output-schema-2)
  - [Algorithm](#algorithm-2)
  - [Performance](#performance-2)
- [4. trace-to-error](#4-trace-to-error)
  - [Input Schema](#input-schema-3)
  - [Output Schema](#output-schema-3)
  - [Algorithm](#algorithm-3)
  - [Performance](#performance-3)
- [5. dead-code](#5-dead-code)
  - [Input Schema](#input-schema-4)
  - [Output Schema](#output-schema-4)
  - [Algorithm](#algorithm-4)
  - [Performance](#performance-4)
- [6. cycles](#6-cycles)
  - [Input Schema](#input-schema-5)
  - [Output Schema](#output-schema-5)
  - [Algorithm](#algorithm-5)
  - [Performance](#performance-5)
- [7. hotspots](#7-hotspots)
  - [Input Schema](#input-schema-6)
  - [Output Schema](#output-schema-6)
  - [Algorithm](#algorithm-6)
  - [Performance](#performance-6)
- [8. cross-domain](#8-cross-domain)
  - [Input Schema](#input-schema-7)
  - [Output Schema](#output-schema-7)
  - [Algorithm](#algorithm-7)
  - [Performance](#performance-7)
- [Usage Patterns](#usage-patterns)
  - [Sequential Queries (Agent Workflow)](#sequential-queries-agent-workflow)
  - [Combined Analysis](#combined-analysis)
- [Performance Summary](#performance-summary)
- [Error Handling](#error-handling)

---

## Query Type Index

1. [blast-radius](#1-blast-radius) - Transitive callers (what breaks?)
2. [find-callers](#2-find-callers) - Direct reverse dependencies
3. [find-calls](#3-find-calls) - Direct forward dependencies
4. [trace-to-error](#4-trace-to-error) - Call stack to file:line
5. [dead-code](#5-dead-code) - Functions never called
6. [cycles](#6-cycles) - Circular dependencies
7. [hotspots](#7-hotspots) - Most-connected functions
8. [cross-domain](#8-cross-domain) - External dependencies

---

## 1. blast-radius

**Purpose**: Find all functions affected if target function changes (transitive callers)

**Use Case**: "What breaks if I refactor parseDate?"

### Input Schema
```json
{
  "query": "blast-radius",
  "target": "parseDate",
  "domain": "csv-processing",
  "options": {
    "depth": 5,
    "limit": 100
  }
}
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| query | ✅ | string | "blast-radius" |
| target | ✅ | string | Function name to analyze |
| domain | ✅ | string | Domain name from MANIFEST |
| options.depth | ❌ | number | Max traversal depth (default: unlimited) |
| options.limit | ❌ | number | Max results (default: 100) |

### Output Schema
```json
{
  "status": "success",
  "query": "blast-radius",
  "target": "parseDate",
  "domain": "csv-processing",
  "results": [
    {
      "function": "mapRow",
      "file": "apps/migration-cli/src/lib/csv/parser.ts",
      "line": 272,
      "depth": 1,
      "type": "direct-caller"
    },
    {
      "function": "validateData",
      "file": "apps/migration-cli/src/lib/validation.ts",
      "line": 45,
      "depth": 2,
      "type": "transitive-caller"
    }
  ],
  "summary": {
    "total": 47,
    "max_depth": 3,
    "by_depth": {
      "1": 12,
      "2": 25,
      "3": 10
    }
  }
}
```

### Algorithm
Uses BFS (Breadth-First Search) to find all transitive callers. See @graph-algorithms.md for implementation.

### Performance
- ~300-500ms for typical functions (< 100 callers)
- ~1-2s for hotspots (100+ callers)

---

## 2. find-callers

**Purpose**: Find direct callers of a function (reverse dependencies)

**Use Case**: "Who directly calls showError?"

### Input Schema
```json
{
  "query": "find-callers",
  "target": "showError",
  "domain": "core-cli"
}
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| query | ✅ | string | "find-callers" |
| target | ✅ | string | Function name |
| domain | ✅ | string | Domain name |

### Output Schema
```json
{
  "status": "success",
  "query": "find-callers",
  "target": "showError",
  "domain": "core-cli",
  "results": [
    {
      "function": "executeValidate",
      "file": "src/commands/validate.ts",
      "line": 67
    },
    {
      "function": "executeMigration",
      "file": "src/commands/migrate.ts",
      "line": 123
    }
  ],
  "summary": {
    "total": 3
  }
}
```

### Algorithm
Simple jq query on graph edges:
```bash
jq -r --arg func "$TARGET" '.g[] | select(.[1] == $func) | .[0]' < domain.json
```

### Performance
- ~20-50ms (jq query)

---

## 3. find-calls

**Purpose**: Find what a function directly calls (forward dependencies)

**Use Case**: "What does migrateAttachments call?"

### Input Schema
```json
{
  "query": "find-calls",
  "target": "migrateAttachments",
  "domain": "migration-pipelines"
}
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| query | ✅ | string | "find-calls" |
| target | ✅ | string | Function name |
| domain | ✅ | string | Domain name |

### Output Schema
```json
{
  "status": "success",
  "query": "find-calls",
  "target": "migrateAttachments",
  "domain": "migration-pipelines",
  "results": [
    {
      "function": "getBlobServiceClient",
      "file": "src/lib/services/blob-storage.ts",
      "line": 45,
      "domain": "service-factory"
    },
    {
      "function": "logMigrationStart",
      "file": "src/lib/logging.ts",
      "line": 89,
      "domain": "utilities"
    }
  ],
  "summary": {
    "total": 4,
    "internal": 2,
    "external": 2
  }
}
```

### Algorithm
Simple jq query on graph edges:
```bash
jq -r --arg func "$TARGET" '.g[] | select(.[0] == $func) | .[1]' < domain.json
```

### Performance
- ~20-50ms (jq query)

---

## 4. trace-to-error

**Purpose**: Find call stack leading to a specific file:line (how does execution reach an error?)

**Use Case**: "Error at src/parser.ts:123, how does code execution get there?"

### Input Schema
```json
{
  "query": "trace-to-error",
  "file": "apps/migration-cli/src/lib/csv/parser.ts",
  "line": 123,
  "domain": "csv-processing"
}
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| query | ✅ | string | "trace-to-error" |
| file | ✅ | string | File path (relative to project root) |
| line | ✅ | number | Line number where error occurs |
| domain | ❌ | string | Domain name (auto-detected if omitted) |

### Output Schema
```json
{
  "status": "success",
  "query": "trace-to-error",
  "file": "apps/migration-cli/src/lib/csv/parser.ts",
  "line": 123,
  "function_at_line": "parseDate",
  "call_stacks": [
    {
      "entry_point": "runCli",
      "path": [
        {"function": "runCli", "file": "src/cli.ts", "line": 15},
        {"function": "executeMigration", "file": "src/commands/migrate.ts", "line": 45},
        {"function": "mapRow", "file": "src/lib/csv/parser.ts", "line": 272},
        {"function": "parseDate", "file": "src/lib/csv/parser.ts", "line": 123}
      ],
      "depth": 3
    }
  ],
  "summary": {
    "total_paths": 2,
    "min_depth": 2,
    "max_depth": 4
  }
}
```

### Algorithm
1. Find which function is defined at file:line (from `.f` section)
2. Run reverse BFS to find all paths to that function
3. Return call chains from entry points

See @graph-algorithms.md for implementation.

### Performance
- ~400-600ms (Python reverse BFS)

---

## 5. dead-code

**Purpose**: Find functions that are never called (potential dead code)

**Use Case**: "What can I safely delete from csv-processing domain?"

### Input Schema
```json
{
  "query": "dead-code",
  "domain": "csv-processing",
  "options": {
    "exclude_entry_points": true,
    "exclude_exports": false
  }
}
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| query | ✅ | string | "dead-code" |
| domain | ✅ | string | Domain name |
| options.exclude_entry_points | ❌ | boolean | Exclude main/CLI commands (default: true) |
| options.exclude_exports | ❌ | boolean | Exclude exported functions (default: false) |

### Output Schema
```json
{
  "status": "success",
  "query": "dead-code",
  "domain": "csv-processing",
  "results": [
    {
      "function": "streamCsvChunked",
      "file": "src/lib/csv/parser.ts",
      "line": 257,
      "reason": "never_called",
      "exported": false
    },
    {
      "function": "cleanupTempFiles",
      "file": "src/lib/utilities.ts",
      "line": 89,
      "reason": "never_called",
      "exported": true,
      "warning": "Exported but unused - may be public API"
    }
  ],
  "summary": {
    "total": 5,
    "safe_to_delete": 3,
    "exported_unused": 2
  }
}
```

### Algorithm
1. Extract all defined functions from `.f` section
2. Extract all called functions from `.g` section
3. Set difference: defined - called = dead code
4. Filter entry points (main, CLI commands) if requested

### Performance
- ~200-300ms (jq + set operations)

---

## 6. cycles

**Purpose**: Detect circular dependencies (functions that call each other directly or transitively)

**Use Case**: "Are there any circular dependencies in this domain?"

### Input Schema
```json
{
  "query": "cycles",
  "domain": "csv-processing"
}
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| query | ✅ | string | "cycles" |
| domain | ✅ | string | Domain name |

### Output Schema
```json
{
  "status": "success",
  "query": "cycles",
  "domain": "csv-processing",
  "results": [
    {
      "cycle": ["parseChunkSmart", "validateChunk", "parseChunkSmart"],
      "length": 2,
      "files": [
        "src/lib/csv/chunked-parser.ts",
        "src/lib/csv/validator.ts"
      ]
    }
  ],
  "summary": {
    "total_cycles": 1,
    "min_length": 2,
    "max_length": 2
  }
}
```

### Algorithm
DFS (Depth-First Search) with cycle detection using recursion stack. See @graph-algorithms.md for implementation.

### Performance
- ~500ms-1s (Python DFS)

---

## 7. hotspots

**Purpose**: Find most-connected functions (highest change risk / maintenance burden)

**Use Case**: "What functions have the most callers (highest risk to change)?"

### Input Schema
```json
{
  "query": "hotspots",
  "domain": "csv-processing",
  "options": {
    "limit": 10,
    "min_callers": 5
  }
}
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| query | ✅ | string | "hotspots" |
| domain | ✅ | string | Domain name |
| options.limit | ❌ | number | Max results (default: 10) |
| options.min_callers | ❌ | number | Minimum callers to include (default: 3) |

### Output Schema
```json
{
  "status": "success",
  "query": "hotspots",
  "domain": "csv-processing",
  "results": [
    {
      "function": "isNonEmpty",
      "file": "src/lib/csv/domino-contact-normalizer.ts",
      "line": 22,
      "callers": 9,
      "rank": 1
    },
    {
      "function": "parseDate",
      "file": "src/lib/csv/parser.ts",
      "line": 123,
      "callers": 7,
      "rank": 2
    }
  ],
  "summary": {
    "total": 10,
    "max_callers": 9,
    "avg_callers": 5.3
  }
}
```

### Algorithm
Group by callee, count, sort descending:
```bash
jq '[.g[] | .[1]] | group_by(.) | map({func: .[0], callers: length}) | sort_by(-.callers)' < domain.json
```

### Performance
- ~100-200ms (jq aggregation)

---

## 8. cross-domain

**Purpose**: Find functions called from outside the domain (external dependencies / coupling)

**Use Case**: "What external functions does csv-processing depend on?"

### Input Schema
```json
{
  "query": "cross-domain",
  "domain": "csv-processing"
}
```

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| query | ✅ | string | "cross-domain" |
| domain | ✅ | string | Domain name |

### Output Schema
```json
{
  "status": "success",
  "query": "cross-domain",
  "domain": "csv-processing",
  "results": [
    {
      "function": "getBlobServiceClient",
      "called_by": ["parseCsv", "loadCsvFromBlob"],
      "from_domain": "service-factory",
      "coupling_strength": 2
    },
    {
      "function": "logError",
      "called_by": ["parseRow", "validateData"],
      "from_domain": "utilities",
      "coupling_strength": 2
    }
  ],
  "summary": {
    "total_external_deps": 5,
    "coupled_domains": ["service-factory", "utilities", "dataverse-repositories"],
    "coupling_score": 12
  }
}
```

### Algorithm
1. Extract functions defined in this domain (from `.f`)
2. Extract functions called by this domain (from `.g`)
3. Set difference: called - defined = external deps
4. Group by source domain, count coupling strength

### Performance
- ~150-250ms (jq set operations)

---

## Usage Patterns

### Sequential Queries (Agent Workflow)

**Example: Debug assistant investigating error**
```
1. trace-to-error (file:line) → Get call stack
2. find-calls for each function in stack → Understand data flow
3. blast-radius for suspected bug location → Assess fix impact
```

**Example: Refactor planner**
```
1. blast-radius (target function) → Find affected code
2. hotspots (domain) → Identify high-risk functions to avoid
3. cross-domain (domain) → Check external coupling
```

### Combined Analysis

**Example: Domain health assessment**
```
1. dead-code → Find unused functions
2. cycles → Find circular deps
3. hotspots → Find high-maintenance functions
4. cross-domain → Assess coupling

Combined metrics → Domain health score
```

---

## Performance Summary

See @performance.md for detailed performance characteristics, optimization strategies, and scalability limits.

**Quick Reference**:
- Simple queries (find-callers, hotspots): ~20-200ms
- Complex queries (blast-radius, cycles): ~300-1000ms
- All queries complete in <2 seconds

---

## Error Handling

See @error-handling.md for complete error patterns and recovery strategies.

**Quick Reference**:
- All queries return structured JSON errors with helpful hints
- Common errors: function not found, domain not found, invalid query type
- Recovery guidance provided in `hint` field

---

**Fast • Deterministic • Token-Efficient**
