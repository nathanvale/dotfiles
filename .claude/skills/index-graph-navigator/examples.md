# Usage Examples

Complete examples showing how to use index-graph-navigator for common queries.

## Example 1: Find Hotspots

**User request**: "What are the hotspots in the codebase?"

**Command**:
```bash
python3 ~/.claude/skills/index-graph-navigator/scripts/query-dispatcher.py "find hotspots"
```

**Response**:
```json
{
  "status": "success",
  "results": [
    {"function": "showError", "callers": 47, "file": "src/utils.ts", "line": 23},
    {"function": "parseDate", "callers": 35, "file": "src/parser.ts", "line": 102}
  ]
}
```

**Present to user**: "Top hotspots: `showError` (47 callers) at src/utils.ts:23, `parseDate` (35 callers) at src/parser.ts:102"

---

## Example 2: Find Who Calls a Function

**User request**: "Who calls the parseDate function?"

**Command**:
```bash
python3 ~/.claude/skills/index-graph-navigator/scripts/query-dispatcher.py "who calls parseDate"
```

**Response**:
```json
{
  "status": "success",
  "results": [
    {"caller": "validateData", "file": "src/validator.ts", "line": 45},
    {"caller": "mapRow", "file": "src/mapper.ts", "line": 78}
  ]
}
```

**Present to user**: "`parseDate` is called by: `validateData` (src/validator.ts:45), `mapRow` (src/mapper.ts:78)"

---

## Example 3: Find Dead Code

**User request**: "Are there any unused functions?"

**Command**:
```bash
python3 ~/.claude/skills/index-graph-navigator/scripts/query-dispatcher.py "find dead code"
```

**Response**:
```json
{
  "status": "success",
  "results": [
    {"function": "oldParser", "file": "src/legacy.ts", "line": 12},
    {"function": "unusedHelper", "file": "src/utils.ts", "line": 234}
  ]
}
```

**Present to user**: "Found 2 unused functions: `oldParser` (src/legacy.ts:12), `unusedHelper` (src/utils.ts:234). These can be safely removed."

---

## Example 4: Blast Radius Analysis

**User request**: "What breaks if I change sanitizeEmail?"

**Command**:
```bash
python3 ~/.claude/skills/index-graph-navigator/scripts/query-dispatcher.py "blast radius of sanitizeEmail"
```

**Response**:
```json
{
  "status": "success",
  "results": [
    {"function": "validateEmail", "file": "src/validator.ts", "line": 23, "depth": 1},
    {"function": "processUser", "file": "src/processor.ts", "line": 45, "depth": 2},
    {"function": "migrateUsers", "file": "src/migration.ts", "line": 89, "depth": 3}
  ],
  "summary": {"total": 47, "max_depth": 5}
}
```

**Present to user**: "Changing `sanitizeEmail` affects 47 functions across 5 levels. Direct impact: `validateEmail` (src/validator.ts:23). High-level impact includes `migrateUsers` (src/migration.ts:89)."

---

## Example 5: Circular Dependencies

**User request**: "Are there any circular dependencies?"

**Command**:
```bash
python3 ~/.claude/skills/index-graph-navigator/scripts/query-dispatcher.py "find circular dependencies"
```

**Response**:
```json
{
  "status": "success",
  "results": [
    {
      "cycle": ["parseData", "validateData", "sanitizeData", "parseData"],
      "files": ["src/parser.ts", "src/validator.ts", "src/sanitizer.ts"]
    }
  ]
}
```

**Present to user**: "Found 1 circular dependency: parseData → validateData → sanitizeData → parseData across 3 files. Consider refactoring to break the cycle."

---

## Example 6: Natural Language Limits

**User request**: "Show me the top 20 hotspots"

**Command**:
```bash
python3 ~/.claude/skills/index-graph-navigator/scripts/query-dispatcher.py "top 20 hotspots"
```

The dispatcher automatically extracts `limit=20` from natural language.

---

## Example 7: Multiple Function Name Formats

All these work:

```bash
# Backtick-wrapped
"who calls `parseDate`"

# "function X" syntax
"who calls function parseDate"

# Direct camelCase/PascalCase
"who calls parseDate"
```

The dispatcher recognizes all formats automatically.

---

## Example 8: Error Handling

**User request**: "Who calls parsDate?" (typo)

**Response**:
```json
{
  "status": "error",
  "error": "Function 'parsDate' not found",
  "suggestions": ["parseDate", "parseData", "parseDateTime"],
  "hint": "Did you mean one of these functions?"
}
```

**Present to user**: "Function 'parsDate' not found. Did you mean: `parseDate`, `parseData`, or `parseDateTime`?"

---

## Direct Script Usage (Advanced)

When you know the exact query type:

```bash
# More efficient - no dispatcher overhead
bash ~/.claude/skills/index-graph-navigator/scripts/find-callers.sh "parseDate" --json
bash ~/.claude/skills/index-graph-navigator/scripts/hotspots.sh --limit 20 --json
bash ~/.claude/skills/index-graph-navigator/scripts/dead-code.sh --json
python3 ~/.claude/skills/index-graph-navigator/scripts/blast-radius.py "sanitizeEmail"
python3 ~/.claude/skills/index-graph-navigator/scripts/cycles.py
```

Use direct scripts when:
- You know exact query type
- Faster execution needed
- Debugging query logic
