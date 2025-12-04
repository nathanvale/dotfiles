# Code Style & Patterns

## Patterns

- Functional → pure functions, immutability, composition
- Factory patterns → for object creation
- Dependency injection → for testability
- Small modules → single responsibility
- Abstraction → well-structured over "simple but messy"

## Style

- TypeScript strict mode always
- Biome defaults → tab indentation, opinionated formatting
- Import order → `node:*` → external → local
- File names → `kebab-case` lowercase
- No abbreviated variable names
- Template literals over concatenation

## JSDoc (Required for exports)

```typescript
/**
 * Creates a user repository with dependency injection.
 * @param db - Database client instance
 * @returns User repository with CRUD operations
 */
export function createUserRepository(db: Database): UserRepository {}
```

## Tech Stack

Bun | Node 22+ | TypeScript (strict) | React (functional) | Tailwind | Biome

## Testing

- TDD for big features → write tests first
- Small features → ask Nathan
- Coverage goal → 80%
- Prefer integration over unit tests
- Colocated → `*.test.ts` alongside source
- Arrow notation in test descriptions
