# Search Tool Selection

**Use the right tool to minimize tokens and maximize accuracy.**

## Kit Plugin Tools (Primary)

| Tool | Use For | Speed |
|------|---------|-------|
| `kit_grep` | Text patterns, regex, literal matches | ~30ms |
| `kit_semantic` | Natural language queries ("find auth logic") | ~500ms |
| `kit_symbols` | Function/class/variable definitions | ~200ms |
| `kit_usages` | Find where symbols are used | ~300ms |
| `kit_ast_search` | Structural code patterns (tree-sitter) | ~400ms |
| `kit_file_tree` | Repository structure overview | ~50ms |
| `kit_file_content` | Multi-file content retrieval | ~100ms |

## Decision Tree

| Need | Tool |
|------|------|
| Literal text, regex, TODO comments | `kit_grep` |
| "Find where we handle errors" | `kit_semantic` |
| List all functions in a file | `kit_symbols` |
| Where is `createUser` called? | `kit_usages` |
| All async functions, classes with X shape | `kit_ast_search` |
| Understand repo layout | `kit_file_tree` |

## AST Search Modes (`kit_ast_search`)

**Simple mode** (natural language):
- `"async function"` → async function declarations
- `"class"` → class definitions
- `"arrow function"` → arrow functions

**Pattern mode** (JSON criteria):
```json
{"type": "function_declaration", "async": true}
{"type": "class_declaration", "name": "MyClass"}
```

Supported: TypeScript, JavaScript, Python

## Built-in Grep (ripgrep)

Use when Kit unavailable. Full ripgrep features: context lines, multiline, type filters.

## Quick Reference

| Task | Tool |
|------|------|
| TODO comments | `kit_grep` |
| Import statements | `kit_grep` |
| Error message strings | `kit_grep` |
| All async functions | `kit_ast_search` |
| Private methods | `kit_ast_search` |
| Classes with specific structure | `kit_ast_search` |
| "Find validation logic" | `kit_semantic` |
| Function definitions | `kit_symbols` |
| Where is X used? | `kit_usages` |
