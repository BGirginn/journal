# TEST_PLAN.md

## 1) Unit Tests
- Payload parse/serialize
- Transform math (move/resize/rotate)
- Hit-test correctness
- Command history: undo/redo + coalesce
- HLC ordering

## 2) Integration Tests
- Offline: create journal/page/blocks -> restart -> persist
- Sync: device A offline edits -> online -> device B receives
- Asset: upload/download + placeholder -> render
- Smoke set (CI):
  - `test/widget_test.dart` (login shell render smoke)
  - `test/smoke_local_flow_test.dart` (journal create, save/reload, block delete)

## 3) Performance Tests
- 1 page: 30 blocks (10 text, 10 image, 10 ink)
- Ink: 2000 points incremental draw
- Drag/resize: frame time <16ms

## 4) Manual QA Checklist
- orientation changes
- airplane mode scenarios
- force close during save
- storage full edge case
- clock skew (device time change)
