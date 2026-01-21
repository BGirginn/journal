# DECISIONS.md — ADR (Kilit Kararlar)

## ADR-001 Platform
- Decision: Flutter
- Reason: cross-platform + gesture/canvas geliştirme hızı

## ADR-002 Local DB
- Decision: SQLite via Drift
- Reason: migration + query + ölçek

## ADR-003 Sync Model
- Decision: Oplog + deterministic apply
- Reason: multi-device conflict kontrolü

## ADR-004 Coordinates
- Decision: normalize [0..1]
- Reason: cross-device layout stabilitesi

## ADR-005 Rotation
- Decision: degree storage
- Reason: kullanıcı algısı ve okunabilirlik

## ADR-006 Ink
- Decision: binary ink.bin
- Reason: performans + boyut
