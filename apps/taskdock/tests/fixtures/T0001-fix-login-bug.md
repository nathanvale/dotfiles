---
id: T0001
title: Fix login authentication bug
status: READY
priority: P0
depends_on: []
assigned_to: ""
estimated_hours: 4
github: https://github.com/example/repo/issues/101
---

# P0: Fix login authentication bug

## Description

Users are unable to log in with email addresses containing special characters (e.g., `user+tag@example.com`). The authentication middleware is rejecting these valid email formats.

## Current Behavior

- Login fails with error: "Invalid email format"
- Affected emails: those with `+`, `-`, or `.` characters before `@`
- Works for simple emails like `user@example.com`

## Expected Behavior

- All RFC-compliant email addresses should be accepted
- Login should succeed for emails with special characters
- Error messages should be more specific

## Acceptance Criteria

- [ ] Login accepts email addresses with `+` character
- [ ] Login accepts email addresses with `-` character
- [ ] Login accepts email addresses with `.` character
- [ ] All existing tests pass
- [ ] New tests added for special character emails
- [ ] Error messages updated to be more descriptive

## Technical Notes

**Location:** `src/auth/middleware/validateEmail.ts`

**Root Cause:** The regex pattern is too restrictive:
```typescript
const emailRegex = /^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}$/;
```

**Proposed Fix:**
```typescript
const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
```

**Test Cases:**
- `user+tag@example.com` ✅
- `first.last@company.co.uk` ✅
- `user-name@domain.com` ✅

## Dependencies

None

## Related Tasks

- T0002 (Improve error handling)
- T0005 (Update authentication docs)

## Files to Modify

- `src/auth/middleware/validateEmail.ts` - Fix regex pattern
- `src/auth/middleware/validateEmail.test.ts` - Add test cases
- `docs/authentication.md` - Update supported formats

## Estimated Time

4 hours
