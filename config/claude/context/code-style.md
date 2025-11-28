# Code Style & Patterns

## Patterns I Love

- **Functional programming** — Pure functions, immutability, composition
- **Factory patterns** — For object creation
- **Dependency injection** — For testability and flexibility
- **Small, focused modules** — Single responsibility
- **Abstraction is good** — Well-structured over "simple but messy"

## Code Style

- TypeScript strict mode always
- **Biome defaults** — Tab indentation, opinionated formatting
- `kebab-case` lowercase for file names
- No abbreviated variable names
- Keep functions simple (refactor complex ones)
- Template literals over string concatenation

## Documentation

Every exported function needs JSDoc (TypeDoc compatible). Document the "why."

```typescript
/**
 * Creates a user repository with dependency injection.
 * @param db - Database client instance
 * @returns User repository with CRUD operations
 */
export function createUserRepository(db: Database): UserRepository {
  // ...
}
```

## Tech Stack

Bun (primary), Node 22+, TypeScript (strict), React (functional), Tailwind, Biome

## Testing

- **TDD for big features** — Write tests first
- **Ask about TDD for small features** — Nathan decides case-by-case
- Coverage goal: 80%
- Prefer integration tests over unit tests for behavior
