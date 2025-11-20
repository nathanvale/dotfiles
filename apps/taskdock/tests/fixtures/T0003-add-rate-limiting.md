---
id: T0003
title: Add rate limiting to authentication endpoints
status: BLOCKED
priority: P1
depends_on: [T0002]
assigned_to: ""
estimated_hours: 8
github: https://github.com/example/repo/issues/103
---

# P1: Add rate limiting to authentication endpoints

## Description

Authentication endpoints are vulnerable to brute force attacks. Need to implement rate limiting to
protect user accounts.

## Blocking Issue

This task is blocked by T0002 (error handling improvements) because we need proper error codes to
communicate rate limit violations to clients.

## Requirements

- Limit login attempts per IP address
- Limit login attempts per email address
- Implement exponential backoff
- Store rate limit data in Redis
- Return appropriate HTTP status codes (429)

## Acceptance Criteria

- [ ] Rate limiting middleware implemented
- [ ] Redis integration for counter storage
- [ ] Configurable limits via environment variables
- [ ] Proper HTTP headers (X-RateLimit-\*)
- [ ] Tests for rate limiting scenarios
- [ ] Documentation updated

## Technical Approach

Use `express-rate-limit` package with Redis store.

**Configuration:**

- Max 5 attempts per email per 15 minutes
- Max 20 attempts per IP per hour
- Exponential backoff after first block

## Dependencies

**Blocks:**

- Must wait for T0002 to be completed

**Requires:**

- Redis instance (already available in staging/prod)
- express-rate-limit npm package
