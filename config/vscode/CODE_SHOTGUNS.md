# Code Shotguns: Tools vs Anti-Patterns

## Overview

"Shotgun" concepts in software development have two opposite meanings:
1. **Shotgun CLI** - A tool that prevents chaos in AI-driven development
2. **Shotgun Surgery** - An anti-pattern that represents chaos in code

Understanding both helps keep your codebase healthy when using VS Code with AI agents.

---

## 🎯 Shotgun CLI: Spec-Driven Development Tool

### What It Is

[Shotgun CLI](https://github.com/shotgun-sh/shotgun) is a **codebase-aware spec engine** that generates technical specifications for AI coding agents (Claude Code, Cursor, Windsurf, Lovable).

**Core Problem It Solves:** AI agents often derail during implementation because they lack full context about your architecture, existing patterns, and dependencies.

### The 5-Phase Workflow

```
Research → Specify → Plan → Tasks → Export
   ↓         ↓         ↓       ↓       ↓
Explore   Define    Create  Break   Format
Patterns  Specs     Plan    Down    for AI
```

#### Phase 1: 🔬 Research
- **What It Does**: Explores your entire codebase + web research
- **Example**: "How do we handle authentication in this codebase?"
- **Output**: `research.md` with identified patterns and dependencies

#### Phase 2: 📝 Specify
- **What It Does**: Creates technical specifications aware of architecture
- **Example**: "Add OAuth2 with refresh token support"
- **Output**: `specification.md` with complete requirements

#### Phase 3: 📋 Plan
- **What It Does**: Generates implementation roadmap respecting existing patterns
- **Example**: "Create implementation plan for payment system"
- **Output**: `plan.md` with step-by-step roadmap

#### Phase 4: ✅ Tasks
- **What It Does**: Breaks down plans into actionable items
- **Example**: "Break down dashboard plan into tasks"
- **Output**: `tasks.md` with discrete, testable items

#### Phase 5: 📤 Export
- **What It Does**: Formats everything for AI agents
- **Output**: `AGENTS.md` ready for Cursor/Claude Code/Windsurf

### Key Features

| Feature | Why It Matters |
|---------|----------------|
| **Codebase Indexing** | Reads entire repository with tree-sitter parser. Finds existing patterns, dependencies, architecture—no manual context needed |
| **Dedicated Agents Per Mode** | Each phase uses a specialized AI agent with tailored prompts. 100% user-controllable via mode switching |
| **Research-First Approach** | Discovers what you already have AND external solutions before writing code. Prevents duplicate/suboptimal solutions |
| **Structured Workflow** | Clear 5-phase journey with checkpoints. No "prompt and hope" chaos |
| **Export Formats** | Creates `AGENTS.md` files compatible with your favorite AI coding tool |

### Real-World Impact

**Case Study:** Payment system implementation
- ❌ Without Shotgun: Claude Code suggested building custom payment proxy (3-4 weeks)
- ✅ With Shotgun: Research discovered LiteLLM Proxy instead (30 min research, 5 days deployment)
- **Result:** 80% less dev time, near-zero technical debt

### Installation & Usage

```bash
# Try it out (ephemeral)
uvx shotgun-sh@latest

# Install permanently
uv tool install shotgun-sh

# Run in your project
shotgun
```

**Keyboard Shortcuts:**
- `Shift+Tab` - Switch modes
- `Ctrl+P` - Command palette
- `Ctrl+C` - Cancel
- `Escape` - Stop agent
- `Ctrl+U` - View usage stats

### Best Practices with Shotgun

✅ **Do This**
- Research how we handle authentication
- Ask Shotgun questions first
- Follow Research → Specify → Plan → Tasks
- Export to AGENTS.md for AI agents

❌ **Don't Do This**
- Skip directly to building
- Assume Shotgun knows your needs
- Jump between phases randomly
- Use raw specs without research phase

---

## 🚨 Shotgun Surgery: The Anti-Pattern to Avoid

### What It Is

**Shotgun Surgery** is a software anti-pattern where a single feature change requires modifications scattered across **many places** in your codebase, often with duplicated/similar code.

### Causes of Shotgun Surgery

1. **Copy-Paste Programming** - Code duplicated across multiple locations
2. **Lack of Abstraction** - No central place to make cross-cutting changes
3. **Time Pressure** - No time to refactor; just copy-paste instead
4. **Tight Coupling** - Components overly dependent on each other
5. **No Single Source of Truth** - Logic replicated in multiple implementations

### Classic Example: Logging

**Before (scattered functions):**
```javascript
function processOrder() {
  // ... logic
}

function processPayment() {
  // ... logic
}

function sendNotification() {
  // ... logic
}
```

**After adding logging (scattered modifications):**
```javascript
function processOrder() {
  console.log("Entering processOrder");
  // ... logic
  console.log("Exiting processOrder");
}

function processPayment() {
  console.log("Entering processPayment");
  // ... logic
  console.log("Exiting processPayment");
}

function sendNotification() {
  console.log("Entering sendNotification");
  // ... logic
  console.log("Exiting sendNotification");
}
```

**Problem:** Any change to logging format requires updates in many places. This is shotgun surgery.

### Consequences of Shotgun Surgery

| Consequence | Impact |
|-------------|--------|
| **Increased Dev Effort** | Changes take longer because you must update many places |
| **Higher Defect Rate** | Bugs in duplicated code multiply across the codebase |
| **Psychological Neglect** | Developers give up on maintaining "messy" code (broken windows) |
| **Software Rot** | Exponential degradation can make entire codebase unmaintainable |
| **Rewrite Costs** | Only solution is often complete rewrite at massive cost |

### Mitigation Strategies

#### 1. Aspect-Oriented Programming (AOP)
Apply cross-cutting concerns (logging, auth, caching) in a single place that "weaves" across all functions.

**Example with Node.js decorators:**
```javascript
@WithLogging
function processOrder(orderId) {
  // Logging automatically applied
  // ... logic
}
```

#### 2. Higher-Order Functions / Middleware
Wrap behavior once, apply everywhere.

```javascript
const withLogging = (fn) => {
  return function(...args) {
    console.log(`Entering ${fn.name}`);
    const result = fn(...args);
    console.log(`Exiting ${fn.name}`);
    return result;
  };
};

const processOrder = withLogging(function(orderId) {
  // ... logic
});
```

#### 3. Domain-Specific Languages (DSLs)
Use code generation to eliminate duplication.

```javascript
// Write once
@Log("entering", "exiting")
function processOrder() { }

// Compiler generates the logging code
```

#### 4. Single Source of Truth
Centralize shared logic instead of copying.

```javascript
// ✅ GOOD: Single place to change
const operations = {
  processOrder: createOperation(orderLogic),
  processPayment: createOperation(paymentLogic),
  sendNotification: createOperation(notificationLogic)
};

function createOperation(logic) {
  return async function(...args) {
    console.log(`Entering ${logic.name}`);
    try {
      return await logic(...args);
    } finally {
      console.log(`Exiting ${logic.name}`);
    }
  };
}
```

---

## 🔗 How Shotgun CLI Prevents Shotgun Surgery

### The Connection

**Shotgun Surgery happens when:**
- Developers don't understand the codebase architecture
- They duplicate code because they don't know where common logic lives
- They make scattered changes without considering impact

**Shotgun CLI prevents this by:**
1. **Research Phase** - Maps existing patterns so developers don't duplicate
2. **Specification Phase** - Documents exactly what needs to change and where
3. **Planning Phase** - Creates roadmap that respects architecture
4. **Task Phase** - Breaks changes into focused, non-scattered work
5. **Export Phase** - AI agents follow the spec precisely, no random scattered changes

### Workflow Integration with VS Code

```
User Need
    ↓
[Run Shotgun in Terminal]
    ↓
Research → Specify → Plan → Tasks → Export to AGENTS.md
    ↓
[Copy AGENTS.md into VS Code Chat]
    ↓
Claude Code/Copilot reads clear spec
    ↓
AI makes surgical, focused changes (not scattered)
    ↓
Fewer regressions, less technical debt
```

---

## 📊 Decision Matrix: When to Use What

| Scenario | Use Shotgun CLI? | Key Reason |
|----------|------------------|-----------|
| Adding new feature to unfamiliar codebase | ✅ YES | Prevents shotgun surgery from ignorance |
| Refactoring to eliminate duplication | ✅ YES | Planning prevents scattered changes |
| Fixing a simple bug | ❌ NO | Overkill; too small |
| Onboarding new developer | ✅ YES | Research generates architecture docs |
| Migrating old code | ✅ YES | Plan prevents scattered migration |
| Adding cross-cutting concern (logging, auth) | ✅ YES | Specs can recommend AOP patterns |
| Quick hotfix in production | ❌ NO | Time-critical; use judgment |

---

## 🛠️ Integration with Your VS Code Workflow

### Setup

1. Install Shotgun CLI globally:
   ```bash
   uv tool install shotgun-sh
   ```

2. In VS Code terminal (your project directory):
   ```bash
   shotgun
   ```

3. Go through Research → Specify → Plan → Tasks phases

4. Export to AGENTS.md (Phase 5)

5. Copy AGENTS.md content into VS Code Chat

6. Paste context and ask Claude Code to implement

### Best Practices

✅ **Do**
- Run Shotgun before starting ANY non-trivial feature
- Research thoroughly—it catches duplicated solutions
- Review the spec before giving to AI agent
- Keep AGENTS.md as living documentation
- Reference spec in commit messages

❌ **Don't**
- Skip research phase to save time
- Write specs manually if Shotgun can do it
- Let AI agent deviate from the spec
- Delete AGENTS.md after implementation
- Use Shotgun for trivial 5-minute fixes

---

## References

### Shotgun CLI
- **Official Site**: https://shotgun.sh/
- **GitHub**: https://github.com/shotgun-sh/shotgun
- **Case Study**: Real-world payment system implementation
- **YouTube Demo**: Complete walkthrough of 5-phase workflow

### Shotgun Surgery (Anti-Pattern)
- **Wikipedia**: https://en.wikipedia.org/wiki/Shotgun_surgery
- **Key Paper**: "An Investigation of Bad Smells in Object-Oriented Design" (2006)
- **Related Concepts**:
  - Copy-paste programming
  - Technical debt
  - Software rot
  - Broken windows theory
  - Abstraction principle (Once and Only Once rule)

### Mitigation Techniques
- **Aspect-Oriented Programming (AOP)**: Decorators, interceptors, middleware
- **Higher-Order Functions**: Function composition, decorators
- **Domain-Specific Languages**: Code generation approaches
- **Design Patterns**: Strategy, Template Method, Decorator patterns

---

## Summary

| Concept | Type | Solution | Impact |
|---------|------|----------|--------|
| **Shotgun CLI** | Tool | Specs for AI agents | Prevents chaos from AI agents |
| **Shotgun Surgery** | Anti-Pattern | Refactoring, AOP, DRY | Prevents chaos from scattered changes |

**Together:** Shotgun CLI + architectural discipline = AI-powered development that stays clean and maintainable.

The key insight: **Specifications prevent the scattered changes that lead to shotgun surgery.** When AI agents have a clear spec, they make surgical changes. When developers have clear specs, they refactor to prevent duplication.
