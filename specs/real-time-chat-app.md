# Plan: Real-Time Chat Application

## Task Description
Build a multi-user real-time chat application for a Monash University Senior Full Stack Developer coding challenge. The app features a lobby for creating/joining rooms, real-time messaging via Socket.IO, SQLite persistence, and deployment to Fly.io. Built with Bun, React 19, Vite, SCSS Modules, and TypeScript.

**Critical constraint:** Other candidates failed by over-engineering with AI. Every architectural decision must be explainable. Nathan must own every choice.

## Objective
Deliver a deployed, polished real-time chat application at `~/code/real-time-chat` with:
- Lobby page (create/join rooms)
- Chat page (real-time messaging, typing indicators, user presence)
- SQLite persistence (messages survive refresh)
- Session reconnection
- Responsive design (320px to desktop)
- CSS-only animations
- Deployed to Fly.io (Sydney region)
- Unit tests for core logic
- CI/CD pipeline

## Problem Statement
Nathan needs a coding challenge submission that demonstrates measured architecture, clean code, and clear reasoning -- not over-engineering. The app must be a real-time chat with lobby, rooms, and live messaging, deployable within one week.

## Solution Approach
Single Bun server serving both the built React SPA and Socket.IO WebSocket connections. SQLite via `bun:sqlite` for zero-dependency persistence. Socket.IO with `@socket.io/bun-engine` for native Bun performance. React 19 + Vite frontend with SCSS Modules. Deploy as a single Fly.io instance with persistent volume.

## Relevant Files
Reference plan: `~/.claude/plans/ancient-toasting-peach.md` -- contains all architectural decisions, type definitions, schema, event contracts, and interview talking points.

### New Files
All files are new (greenfield project at `~/code/real-time-chat/`):

- `package.json` -- Root with workspaces
- `tsconfig.json` -- Root with project references
- `biome.json` -- Single root config
- `shared/types.ts` -- All TypeScript interfaces and Socket.IO event types
- `server/package.json`, `server/tsconfig.json`
- `server/src/index.ts` -- Entry point with `@socket.io/bun-engine`
- `server/src/db.ts` -- SQLite schema + queries
- `server/src/room-manager.ts` -- Room CRUD, code generation
- `server/src/socket-handlers.ts` -- All socket event handlers
- `server/src/static.ts` -- Production static file serving
- `client/package.json`, `client/tsconfig.json`
- `client/index.html`, `client/vite.config.ts`
- `client/src/main.tsx`, `client/src/App.tsx`
- `client/src/pages/LobbyPage.tsx`, `client/src/pages/ChatPage.tsx`
- `client/src/components/` -- LobbyForm, ChatHeader, MessageList, MessageInput, TypingIndicator (each with .tsx + .module.scss)
- `client/src/hooks/useSocket.ts`, `useChat.ts`, `useSession.ts`
- `client/src/contexts/SocketContext.tsx`, `ChatContext.tsx`
- `client/src/styles/variables.scss`, `reset.scss`
- `Dockerfile`, `fly.toml`
- `.github/workflows/deploy.yml`
- `INTERVIEW_NOTES.md` (gitignored)

## Implementation Phases

### Phase 1: Foundation (Tasks 1-3)
Project scaffolding, shared types, and database layer. These have no dependencies and the types/db work can run in parallel after scaffolding.

### Phase 2: Server (Tasks 4-6)
Socket.IO server setup, event handlers, and static file serving. Sequential -- each builds on the previous.

### Phase 3: Frontend Core (Tasks 7-10)
Styles, hooks/contexts, lobby page, chat page. Styles and hooks can be parallel. Pages are sequential (lobby first, chat second).

### Phase 4: Integration & Features (Tasks 11-14)
Reconnection, typing indicators, message grouping, animations. Some can run in parallel.

### Phase 5: Deploy & Polish (Tasks 15-18)
Deployment config, CI/CD, tests, final polish. Deploy config and CI can be parallel. Tests after core is stable.

## Team Orchestration

- You operate as the team lead and orchestrate the team to execute the plan.
- IMPORTANT: You NEVER operate directly on the codebase. Use Task and Task* tools only.
- Take note of the session id (agentId) of each team member for resume operations.

### Model Selection Guide

| Role | Model | Rationale |
|------|-------|-----------|
| All builders | sonnet | Executes well-specified tasks reliably |
| All validators | haiku | Mechanical checks: read files, run commands, report PASS/FAIL |

### Team Members

- Builder
  - Name: builder-scaffold
  - Role: Project initialization, package.json, tsconfig, biome setup
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Builder
  - Name: builder-shared
  - Role: Shared TypeScript types and Socket.IO event contracts
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Builder
  - Name: builder-server-db
  - Role: SQLite database layer and room manager
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Builder
  - Name: builder-server-socket
  - Role: Socket.IO server, event handlers, static serving
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Builder
  - Name: builder-client-foundation
  - Role: Vite config, styles, hooks, contexts
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Builder
  - Name: builder-client-lobby
  - Role: Lobby page and form components
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Builder
  - Name: builder-client-chat
  - Role: Chat page and all chat components
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Builder
  - Name: builder-features
  - Role: Reconnection, typing indicators, message grouping, animations
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Builder
  - Name: builder-deploy
  - Role: Dockerfile, fly.toml, CI/CD, static serving
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Builder
  - Name: builder-tests
  - Role: Unit tests for reducer, room manager, DB queries
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Builder
  - Name: builder-polish
  - Role: Loading states, error states, README, interview notes
  - Agent Type: general-purpose
  - Model: sonnet
  - Resume: true

- Validator
  - Name: validator-phase
  - Role: Validates each phase completion -- runs typecheck, lint, tests, verifies file structure
  - Agent Type: general-purpose
  - Model: haiku
  - Resume: true

## Step by Step Tasks

- Execute every step in order, top to bottom.
- Before starting, run TaskCreate for each task so all team members can see the full plan.

### 1. Project Scaffolding
- **Task ID**: scaffold-project
- **Depends On**: none
- **Assigned To**: builder-scaffold
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: false
- Run `bun init` in `~/code/real-time-chat`
- Create directory structure: `client/src/`, `server/src/`, `shared/`
- Create root `package.json` with workspaces: `["client", "server"]`
- Create root `tsconfig.json` with project references to client and server
- Create `biome.json` at root (single config, no nested configs)
- Create `server/package.json` and `server/tsconfig.json` (Bun types)
- Create `client/package.json` and `client/tsconfig.json` (DOM + ES2022)
- Install dependencies:
  - Root: `@biomejs/biome`, `typescript` (dev)
  - Server: `socket.io`, `@socket.io/bun-engine`
  - Client: `react`, `react-dom`, `react-router-dom@6`, `socket.io-client`, `@vitejs/plugin-react`, `sass-embedded`, `vite` (dev)
- Create `client/vite.config.ts` with React plugin and SCSS support
- Create `client/index.html` with root div
- Create `client/src/main.tsx` (minimal React entry)
- Add root scripts: `"dev"`, `"lint"`, `"typecheck"`, `"test"`
- Add `.gitignore` (node_modules, dist, *.db, INTERVIEW_NOTES.md)
- Initialize git repo
- Verify `bun run lint` and `bun run typecheck` pass (may need stub files)

### 2. Shared Types
- **Task ID**: shared-types
- **Depends On**: scaffold-project
- **Assigned To**: builder-shared
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: true (can run parallel with task 3 after scaffold)
- Create `shared/types.ts` with all interfaces from the plan:
  - `User` (id, displayName, roomCode, connectedAt)
  - `Message` (id, userId, displayName, text, type: 'user' | 'system', timestamp, roomCode)
  - `Room` (code, users, messages, createdAt)
- Define typed Socket.IO event maps:
  - `ClientToServerEvents` (room:create, room:join, room:leave, message:send, typing:start, typing:stop)
  - `ServerToClientEvents` (room:created, room:joined, room:user-joined, room:user-left, room:error, message:received, message:history, typing:started, typing:stopped)
- Export all types
- Ensure both client and server tsconfigs can import from shared/

### 3. Database Layer
- **Task ID**: database-layer
- **Depends On**: scaffold-project
- **Assigned To**: builder-server-db
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: true (can run parallel with task 2 after scaffold)
- Create `server/src/db.ts`:
  - Use `bun:sqlite` (zero dependencies)
  - Read DATABASE_PATH from env, default to `./app.db`
  - Create tables with `IF NOT EXISTS` (idempotent)
  - `rooms` table: code (PK), created_at
  - `messages` table: id (PK), room_code (FK), user_id, display_name, text, type (default 'user'), timestamp
  - Index on messages(room_code, timestamp)
  - Export query helpers: `createRoom`, `getRoom`, `addMessage`, `getMessagesByRoom`
- Create `server/src/room-manager.ts`:
  - In-memory Map for connected users per room
  - Room code generation: `crypto.randomUUID().substring(0, 6).toUpperCase()` with uniqueness check + retry
  - Methods: createRoom, joinRoom, leaveRoom, getRoom, getRoomUsers
  - Persist rooms and messages to SQLite, users in-memory only

### 4. Validate Foundation
- **Task ID**: validate-foundation
- **Depends On**: shared-types, database-layer
- **Assigned To**: validator-phase
- **Agent Type**: general-purpose
- **Model**: haiku
- **Parallel**: false
- Verify directory structure matches plan
- Run `bun run typecheck` -- no errors
- Run `bun run lint` -- no errors
- Verify shared/types.ts exports all required interfaces
- Verify db.ts creates tables correctly
- Report PASS/FAIL with details

### 5. Socket.IO Server
- **Task ID**: socket-server
- **Depends On**: validate-foundation
- **Assigned To**: builder-server-socket
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: false
- Create `server/src/index.ts`:
  - Use `@socket.io/bun-engine` for native Bun HTTP (NOT Node.js polyfill)
  - Configure CORS for dev (localhost:5173)
  - Set idleTimeout: 30 (must exceed pingInterval default 25s)
  - Export default Bun server config
- Create `server/src/socket-handlers.ts`:
  - `room:create` -- generate code, persist to SQLite, join socket to room, emit room:created
  - `room:join` -- validate room exists, add user, load message history, emit room:joined + room:user-joined, persist system message
  - `room:leave` -- remove user, notify room, persist system message
  - `message:send` -- validate (max 2000 chars), persist to SQLite, broadcast to room
  - `disconnect` -- same as room:leave
  - `typing:start/stop` -- relay to room (no persistence)
  - Server-side validation: display name 2-20 chars, message max 2000 chars, room code format
- Create `server/src/static.ts`:
  - In production (NODE_ENV=production), serve `client/dist/` files
  - SPA fallback: return index.html for unmatched routes
  - In dev, this module is a no-op (Vite handles it)

### 6. Validate Server
- **Task ID**: validate-server
- **Depends On**: socket-server
- **Assigned To**: validator-phase
- **Agent Type**: general-purpose
- **Model**: haiku
- **Parallel**: false
- Run `bun run typecheck` -- no errors
- Run `bun run lint` -- no errors
- Verify server/src/index.ts uses `@socket.io/bun-engine` (not polyfill)
- Verify all socket events from the contract are handled
- Verify input validation exists (name length, message length, room code format)
- Report PASS/FAIL

### 7. Client Foundation - Styles
- **Task ID**: client-styles
- **Depends On**: validate-server
- **Assigned To**: builder-client-foundation
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: true (can run parallel with task 8)
- Create `client/src/styles/variables.scss`:
  - CSS custom properties for colors (light theme, accent color)
  - Spacing scale, typography scale, border radius, shadows
  - Breakpoint variables (320px, 768px, 1024px)
- Create `client/src/styles/reset.scss`:
  - Minimal CSS reset (box-sizing, margin, font inheritance)
- Import reset in main.tsx

### 8. Client Foundation - Hooks & Contexts
- **Task ID**: client-hooks
- **Depends On**: validate-server
- **Assigned To**: builder-client-foundation
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: true (can run parallel with task 7)
- Create `client/src/hooks/useSocket.ts`:
  - Manages Socket.IO connection lifecycle
  - Returns `{ socket, isConnected }`
  - Uses `useRef` for stable socket instance
  - Every `socket.on()` has matching `socket.off()` in cleanup (React 19 StrictMode)
- Create `client/src/hooks/useChat.ts`:
  - `useReducer` with actions: SET_ROOM, ADD_MESSAGE, SET_MESSAGES, USER_JOINED, USER_LEFT, TYPING_STARTED, TYPING_STOPPED, CLEAR
  - State: room, messages, users, typingUsers
  - Export reducer separately for unit testing
- Create `client/src/hooks/useSession.ts`:
  - Read/write sessionStorage for `{ displayName, roomCode }`
  - Tab-scoped (clears on tab close)
- Create `client/src/contexts/SocketContext.tsx`:
  - Creates single socket instance at app root
  - Provides socket + isConnected to children
- Create `client/src/contexts/ChatContext.tsx`:
  - Wraps useChat reducer
  - Wires socket events to dispatch calls
  - Route cleanup: emit `room:leave` on unmount

### 9. Validate Client Foundation
- **Task ID**: validate-client-foundation
- **Depends On**: client-styles, client-hooks
- **Assigned To**: validator-phase
- **Agent Type**: general-purpose
- **Model**: haiku
- **Parallel**: false
- Run `bun run typecheck` -- no errors
- Run `bun run lint` -- no errors
- Verify all hooks export correct return types
- Verify contexts use proper Provider pattern
- Verify socket cleanup (socket.off) exists in every useEffect that adds listeners
- Report PASS/FAIL

### 10. Lobby Page
- **Task ID**: lobby-page
- **Depends On**: validate-client-foundation
- **Assigned To**: builder-client-lobby
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: false
- Create `client/src/pages/LobbyPage.tsx`:
  - Form with display name input + create/join actions
  - Join mode: additional room code input
  - Form validation: name 2-20 chars, room code required + uppercase
  - On success: navigate to `/room/:code`
- Create `client/src/components/LobbyForm/LobbyForm.tsx` + `LobbyForm.module.scss`:
  - Styled form component with inputs and buttons
  - Error message display
  - Responsive: max-width 480px centered card
  - Animation: fade-in on mount
- Update `client/src/App.tsx`:
  - React Router v6 setup
  - Routes: `/` (LobbyPage), `/room/:code` (ChatPage placeholder)
  - Wrap with SocketProvider and ChatProvider

### 11. Chat Page
- **Task ID**: chat-page
- **Depends On**: lobby-page
- **Assigned To**: builder-client-chat
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: false
- Create `client/src/pages/ChatPage.tsx`:
  - Orchestrates all chat components
  - Reads room code from URL params
  - Joins room on mount, leaves on unmount
- Create `client/src/components/ChatHeader/ChatHeader.tsx` + `.module.scss`:
  - Room code display (click to copy)
  - Connected user list (collapsible on small screens)
- Create `client/src/components/MessageList/MessageList.tsx` + `.module.scss`:
  - Renders messages with auto-scroll to bottom
  - Differentiates user vs system messages
  - Own messages styled differently (right-aligned or different color)
- Create `client/src/components/MessageInput/MessageInput.tsx` + `.module.scss`:
  - Text input + send button
  - Enter to send, Shift+Enter for newline
  - Sticky bottom on mobile
- Create `client/src/components/TypingIndicator/TypingIndicator.tsx` + `.module.scss`:
  - "User is typing..." display
  - Placeholder -- wired up in features phase
- Wire socket events to ChatContext dispatch
- System messages for join/leave
- Responsive: flex column layout, test at 320px/768px/1024px

### 12. Validate Core App
- **Task ID**: validate-core-app
- **Depends On**: chat-page
- **Assigned To**: validator-phase
- **Agent Type**: general-purpose
- **Model**: haiku
- **Parallel**: false
- Run `bun run typecheck` -- no errors
- Run `bun run lint` -- no errors
- Verify all components have matching .module.scss files
- Verify Router setup with correct routes
- Verify ChatPage joins room on mount and leaves on unmount
- Verify MessageList auto-scrolls
- Report PASS/FAIL

### 13. Reconnection
- **Task ID**: reconnection
- **Depends On**: validate-core-app
- **Assigned To**: builder-features
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: true (can run parallel with task 14)
- Implement session persistence in useSession:
  - Save displayName + roomCode on successful join
  - On page load: if session exists + URL has room code, auto-rejoin
  - If session expired but URL has room code, redirect to lobby with room code pre-filled
- Load message history from SQLite on rejoin
- Handle room-not-found gracefully (redirect to lobby with error message)
- Route cleanup: emit `room:leave` when ChatPage unmounts

### 14. Typing Indicators & Message Grouping
- **Task ID**: typing-and-grouping
- **Depends On**: validate-core-app
- **Assigned To**: builder-features
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: true (can run parallel with task 13)
- Typing indicator:
  - Debounced 300ms emission
  - Auto-clear after 3s inactivity
  - Wire to TypingIndicator component
  - Pulse animation on dots (CSS)
- Message grouping:
  - Group consecutive messages from same user within 5-min window
  - Pure rendering logic in MessageList
  - Only show avatar/name on first message in group

### 15. CSS Animations
- **Task ID**: css-animations
- **Depends On**: reconnection, typing-and-grouping
- **Assigned To**: builder-features
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: false
- Time-boxed implementation (all CSS-only, no JS animation libraries):
  - Message bubble entrance (slide up + fade in with stagger)
  - Typing indicator pulse on dots
  - Room join/leave toast slide-in/out
  - Lobby-to-chat page transition (opacity + transform)
  - Smooth auto-scroll with `scroll-behavior: smooth`
  - Subtle hover states on interactive elements

### 16. Validate Features
- **Task ID**: validate-features
- **Depends On**: css-animations
- **Assigned To**: validator-phase
- **Agent Type**: general-purpose
- **Model**: haiku
- **Parallel**: false
- Run `bun run typecheck` -- no errors
- Run `bun run lint` -- no errors
- Verify reconnection logic in useSession
- Verify typing indicator debounce and auto-clear
- Verify message grouping logic
- Verify CSS animations are keyframe-based (no JS animation libs)
- Report PASS/FAIL

### 17. Deployment Configuration
- **Task ID**: deploy-config
- **Depends On**: validate-features
- **Assigned To**: builder-deploy
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: true (can run parallel with task 18)
- Create `Dockerfile` (multi-stage build from plan)
- Create `fly.toml` (syd region, persistent volume, single instance, auto_stop=false)
- Create `.github/workflows/deploy.yml` (lint + typecheck + test + deploy)
- Verify static.ts serves client/dist/ correctly in production mode
- Add deployment instructions to README

### 18. Unit Tests
- **Task ID**: unit-tests
- **Depends On**: validate-features
- **Assigned To**: builder-tests
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: true (can run parallel with task 17)
- Create `client/src/hooks/__tests__/useChat.test.ts`:
  - Test chatReducer pure function
  - All action types: SET_ROOM, ADD_MESSAGE, SET_MESSAGES, USER_JOINED, USER_LEFT, TYPING_STARTED, TYPING_STOPPED, CLEAR
- Create `server/src/__tests__/room-manager.test.ts`:
  - createRoom, joinRoom, leaveRoom
  - Room code uniqueness
  - User tracking
- Create `server/src/__tests__/db.test.ts`:
  - Message persistence and retrieval
  - Room creation
  - Idempotent schema creation
- Run `bun test` -- all pass

### 19. Validate Tests & Deploy
- **Task ID**: validate-tests-deploy
- **Depends On**: deploy-config, unit-tests
- **Assigned To**: validator-phase
- **Agent Type**: general-purpose
- **Model**: haiku
- **Parallel**: false
- Run `bun test` -- all pass
- Run `bun run typecheck` -- no errors
- Run `bun run lint` -- no errors
- Verify Dockerfile builds successfully (`docker build .`)
- Verify fly.toml has correct settings (single instance, syd region, volume mount)
- Verify CI workflow has all required steps
- Report PASS/FAIL

### 20. Polish & Interview Prep
- **Task ID**: polish-and-prep
- **Depends On**: validate-tests-deploy
- **Assigned To**: builder-polish
- **Agent Type**: general-purpose
- **Model**: sonnet
- **Parallel**: false
- Add loading states (connecting spinner, joining room skeleton)
- Add error states (room not found, connection lost with retry)
- Create README.md with:
  - Project description
  - Tech stack rationale
  - Setup instructions (dev + production)
  - Live demo URL placeholder
- Create INTERVIEW_NOTES.md (gitignored) with all talking points from the plan
- Final responsive check: ensure all components work at 320px/768px/1024px

### 21. Final Validation
- **Task ID**: validate-all
- **Depends On**: polish-and-prep
- **Assigned To**: validator-phase
- **Agent Type**: general-purpose
- **Model**: haiku
- **Parallel**: false
- Run all validation commands:
  - `bun test` -- all pass
  - `bun run typecheck` -- no errors
  - `bun run lint` -- no errors
- Verify complete file structure matches plan
- Verify .gitignore includes INTERVIEW_NOTES.md, *.db, node_modules, dist
- Verify all acceptance criteria met
- Final report: PASS/FAIL with summary

## Acceptance Criteria
- Project runs with `bun run dev` (Vite on 5173, server on 3001)
- Two tabs can create/join a room and exchange messages in real time
- Messages persist in SQLite and survive page refresh
- Reconnection works (session restored from sessionStorage)
- Typing indicators show/hide correctly with debounce
- Messages are grouped by sender within 5-min windows
- Responsive layout works at 320px, 768px, 1024px
- CSS-only animations (no JS animation libraries)
- `bun test` passes all unit tests
- `bun run typecheck` has no errors
- `bun run lint` has no errors
- Dockerfile builds successfully
- fly.toml configured for Sydney region, single instance, persistent volume
- CI/CD pipeline runs lint + typecheck + test + deploy
- INTERVIEW_NOTES.md exists (gitignored) with all talking points
- README.md has setup instructions

## Validation Commands
- `bun test` -- run all tests
- `bunx tsc --noEmit` -- verify no type errors
- `bunx biome ci .` -- lint and format check

## Dependency Graph

```
scaffold-project
├── shared-types ──────────────────┐
└── database-layer ────────────────┤
                                   ▼
                          validate-foundation
                                   │
                              socket-server
                                   │
                             validate-server
                             ┌─────┴─────┐
                       client-styles  client-hooks
                             └─────┬─────┘
                       validate-client-foundation
                                   │
                              lobby-page
                                   │
                              chat-page
                                   │
                          validate-core-app
                          ┌────────┴────────┐
                    reconnection    typing-and-grouping
                          └────────┬────────┘
                            css-animations
                                   │
                          validate-features
                          ┌────────┴────────┐
                     deploy-config      unit-tests
                          └────────┬────────┘
                      validate-tests-deploy
                                   │
                          polish-and-prep
                                   │
                            validate-all
```

## Parallel Execution Opportunities

| After this completes... | These can run in parallel |
|------------------------|--------------------------|
| scaffold-project | shared-types + database-layer |
| validate-server | client-styles + client-hooks |
| validate-core-app | reconnection + typing-and-grouping |
| validate-features | deploy-config + unit-tests |

## Notes
- All agents use `general-purpose` subagent type (no team agent definitions exist)
- The plan file at `~/.claude/plans/ancient-toasting-peach.md` is the source of truth for all architectural decisions, type definitions, schemas, and interview talking points
- Builders MUST read the plan file before starting their task to get exact code patterns and type definitions
- No Bun workspaces `bun.lockb` -- use single root install with workspaces in package.json
- Biome config is root-only (NEVER create nested biome.json)
- React Router v6 specifically (NOT v7)
- `sass-embedded` (NOT `sass` or `node-sass`)
- Every builder prompt should include: "Read ~/.claude/plans/ancient-toasting-peach.md for architectural context and exact code patterns"
