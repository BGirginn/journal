# Journal Master Plan

Version: 1.1
Owner: Bora
Scope: iOS + Android cross-platform, offline-first journaling with realtime sync

---

## 1) Product Vision
Build a tactile, notebook-like journaling app with a block-based editor that works fully offline and syncs reliably across devices, without data loss.

## 2) Core Goals (Non-Negotiable)
- Cross-platform single codebase (Flutter)
- Offline-first: full functionality without network
- Realtime or near-realtime sync across devices for the same account
- Editor quality: move/resize/rotate/z-index, undo/redo, autosave, crash recovery
- Data integrity: no silent loss, migration-safe
- Migration-ready data model and payload versioning

## 3) Out of Scope (Early Phases)
- Public sharing, feeds, or discovery
- Gamification (streaks, badges)
- AI or OCR content generation
- Video blocks
- Early-phase payments or paywalls

---

## 4) Technology Stack
- Client: Flutter (Dart), Riverpod state management
- Rendering: CustomPainter + composited layers, RepaintBoundary
- Local DB: Drift (SQLite)
- Backend: Firebase Auth, Firestore (metadata + oplog), Cloud Storage (assets)
- Monetization: RevenueCat + platform billing

---

## 5) Architecture (Client)
Layers:
- Presentation: screens, widgets, gesture handlers
- Editor Engine: hit-test, transform math, command history, render caching, autosave
- Data: local DB, assets, migrations
- Sync: oplog producer/consumer, conflict resolution, reconciliation

Principle:
- Ephemeral UI state stays in memory during gesture
- Commit to DB and oplog on gesture end

---

## 6) Data Model (High-Level)
Entities:
- Journal, Page, Block, Asset, Oplog

Shared fields:
- id, schema_version, created_at, updated_at, deleted_at (soft delete)

Coordinate standard:
- x, y, w, h normalized to [0..1], rotation in degrees

Key indexes:
- blocks(page_id, deleted_at, z_index)
- pages(journal_id, deleted_at, page_index)
- journals(owner_user_id, updated_at desc)
- oplog(user_id, status, created_at)

---

## 7) Editor Engine Plan
- Modes: view, edit, pen
- Hit-test: z-index desc, AABB then OBB
- Transform rules: move/resize/rotate with clamp and min size
- Undo/redo: command pattern with gesture coalescing
- Autosave: 1500ms debounce + immediate flush on gesture end
- Ink: binary blob storage, incremental draw + raster cache
- Render pipeline: cache text/image/ink, outline preview during gestures

---

## 8) Sync and Backend Plan
Sync model:
- Local DB is the source of truth
- Remote oplog is the shared change log
- Deterministic reconciliation on each device

Backend collections:
- users, journals, pages, blocks, assets, oplog

Asset flow:
- Local save -> asset store
- Upload/download via Storage with checksum

---

## 9) Privacy and Security
- No content telemetry (text/image/audio/ink)
- Telemetry limited to performance and crash metrics
- Firestore and Storage rules enforced by role/ownership
- Account deletion triggers remote purge + local cleanup

---

## 10) Performance Targets
- Gesture frame time: <16ms
- Ink draw frame time: <16ms
- Page open: <500ms
- Autosave DB tx: p95 <150ms (assets excluded)

---

## 11) Testing Strategy
Unit tests:
- Payload parse/serialize
- Transform math, hit-test, command history
- HLC ordering

Integration tests:
- Offline create/edit/restart persistence
- Multi-device sync (A offline, B online)
- Asset upload/download with placeholder render

Performance tests:
- 30 blocks per page, 2000 ink points

Manual QA:
- Airplane mode scenarios
- Force close during save
- Storage full edge cases
- Clock skew

---

## 12) CI/CD and Release
Pipeline goals:
- Lint, unit tests, build, and release gates on each push
- Firebase rules and config validation
- Store submission readiness checks

Release checklist:
- Crash-free smoke test (Android + iOS)
- Offline workflows verified
- Sync on two devices verified
- Asset upload/download verified
- Migration upgrade test

---

## 13) Roadmap by Phase

Sequencing guidance:
- Phase 4 (auth + sync) is the highest risk area; execute immediately after Phase 1 to de-risk multi-device behavior early.
- Phase 2 and Phase 3 follow once core data model and sync are stable.
- Phase 5 depends on Phase 4 (auth + sync foundation).
- Phase 6 depends on Phase 2 (theme assets) and Phase 4 (account entitlements).
- Chapter 7 runs after all phases for system-level verification.

### Phase 1: MVP (Offline Single-User Core)
Owner: Bora  
Target Dates (planned): 2026-01-13 to 2026-02-28  
Dependencies: None (foundation)

Goals:
- Journals, pages, blocks (text/image/handwriting)
- Page flip and editor basics
- Local persistence with crash-safe autosave

Deliverables:
- Local DB schema + migrations, asset store, oplog table (local)
- Editor engine core (move/resize/rotate/z-index, undo/redo, autosave)
- Basic library, journal view, and editor UI

### Phase 4: Cloud and Sync (Auth + Multi-Device)
Owner: Bora  
Target Dates (planned): 2026-03-03 to 2026-04-25  
Dependencies: Phase 1 (stable local schema + oplog table), Firebase project configured

Goals:
- Auth and multi-device sync
- Deterministic oplog-based reconciliation
- Media upload/download with integrity checks

Deliverables (Protocol-Driven):
- Identity model: userId (Firebase UID), deviceId (install UUID), actorId (userId/deviceId)
- HLC generator and comparator: `hlc = ms:counter:deviceId` with deterministic ordering
- Oplog event schema and status: opId, journalId, pageId?, blockId?, opType, hlc, deviceId, userId, payload_json, status (pending/sent/acked/applied/failed)
- Local commit pipeline: DB transaction -> oplog enqueue (pending) -> autosave state update
- Uploader: idempotent Firestore write (upsert by opId), status transition to acked/applied
- Listener + apply queue: Firestore stream -> local apply queue with dedupe (opId or hlc/deviceId watermark)
- Conflict rules (v1):
  - Transform: LWW by HLC for x,y,w,h,rotation,z (apply only if op.hlc > last_transform_hlc)
  - Payload: text edit lease (30s + keepalive); image caption LWW; ink append segments merged by HLC order
  - Delete: tombstone overrides newer updates; updates ignored while tombstone present
- Asset sync:
  - Create: local write + checksum
  - Upload: Storage put -> remote_url update
  - Download: remote_url fetch -> local_path update
  - Missing asset: placeholder + retry queue
- Failure handling: exponential backoff, status=failed with manual retry option
- Reconciliation/compaction (v1.2+): per-block snapshot, archive old ops

Data Flows:
- Local edit -> DB commit -> oplog enqueue -> uploader -> Firestore -> listener -> apply -> local DB
- Remote edit -> listener -> apply queue -> conflict rules -> local DB update -> UI refresh
- Asset create -> local file + checksum -> upload -> remote_url set -> other device downloads -> local_path set

Validation Criteria:
- Offline edit on device A, then online sync to device B with no data loss
- Idempotent apply: re-receiving same opId does not reapply
- HLC ordering stable under clock skew and rapid edits
- Transform LWW works and does not override newer state
- Text edit lease blocks concurrent updates and recovers on lease expiry
- Ink append segments merge deterministically across devices
- Tombstone blocks subsequent updates until undelete flow (if any) is explicit
- Missing assets show placeholder and recover after retry/download
- Failed ops retry successfully after backoff

### Phase 2: Experience and Themes
Owner: Bora  
Target Dates (planned): 2026-04-28 to 2026-05-16  
Dependencies: Phase 1 (core editor), Phase 4 (sync stability for shared assets)

Goals:
- Theme system (JSON-based)
- Visual polish, page textures, covers
- Polaroid image style and stickers

Deliverables:
- Theme manager + journal theme binding
- Theme JSON + asset pipeline (covers, backgrounds, stickers)
- Page open/close effects and page hints

### Phase 3: Power Features
Owner: Bora  
Target Dates (planned): 2026-05-19 to 2026-06-20  
Dependencies: Phase 1 (core editor), Phase 2 (theme assets baseline)

Goals:
- Audio blocks
- PDF export
- Local backup and restore

Deliverables:
- Audio recording/playback service and audio block UI
- PDF export pipeline (separate render layer)
- Local backup and restore flow (DB + assets)

### Phase 5: Collaboration
Owner: Bora  
Target Dates (planned): 2026-06-23 to 2026-08-01  
Dependencies: Phase 4 (auth + sync), Phase 2 (theme assets ready for sharing)

Goals:
- Group journals with roles (owner/editor/viewer)
- Invite and membership management
- Asynchronous collaboration (no live cursors)

Deliverables:
- Role-based access control in Firestore rules
- Journal membership model + invite flow
- Sync extensions for shared journals and role enforcement

### Phase 6: Monetization and Platform
Owner: Bora  
Target Dates (planned): 2026-08-04 to 2026-08-29  
Dependencies: Phase 2 (themes/stickers), Phase 4 (accounts/entitlements)

Goals:
- Free vs Premium separation
- Subscription via RevenueCat
- Asset store for themes/stickers/covers

Deliverables:
- Entitlement model + gating rules
- Purchase flow, restore, and receipts validation
- Premium UX and asset store UI

### Chapter 7: System Verification and Cleanup
Owner: Bora  
Target Dates (planned): 2026-09-01 to 2026-09-26  
Dependencies: All phases complete

Goals:
- Regression testing across all phases
- Performance and stress testing
- Security review and asset cleanup

Deliverables:
- Full QA suite + regression matrix
- Release readiness sign-off
- Tech debt and asset cleanup

---

## 14) Definition of Done (Project-Level)
- Offline-first flows verified end-to-end
- Two-device sync verified with no data loss
- Editor performance targets met
- Migration plan and tests executed
- Privacy and security rules validated
- Release checklist completed
