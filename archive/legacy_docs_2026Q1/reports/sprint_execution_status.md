# Sprint Execution Status

Last updated: 2026-02-13

## Sprint 1
Status: Completed
- Android release signing fail-fast config eklendi.
- Firestore `team_members` path standardi rules ile hizalandi.
- Release checklist + prereq scriptleri eklendi.

## Sprint 2
Status: Completed
- PR CI workflow (`Format Check`, `Analyze`, `Test`) eklendi.
- Release candidate workflow eklendi.
- CI runbook ve contributing guncellendi.

## Sprint 3
Status: Completed
- Widget test timer problemi giderildi.
- Lokal smoke test seti eklendi (`test/smoke_local_flow_test.dart`).
- Analyze ve test suite yesil.

## Sprint 4
Status: Completed
- Go/No-Go, rollback/hotfix ve 72 saat monitoring runbook dokumanlari eklendi.

## Sprint 5
Status: Completed
- Journal/page/block kritik write akislarinda oplog producer aktif.
- HLC + deviceId bazli oplog uretimi FirestoreService'e eklendi.
- Pending queue metrik providerlari ve debug ekrani eklendi.

## Sprint 6
Status: Completed
- `syncUp` uploader pipeline implement edildi.
- `pending -> sent -> acked/failed` status gecisleri eklendi.
- Retry/backoff (ust sinirli) eklendi.

## Sprint 7
Status: Completed (baseline)
- Reconcile pipeline implement edildi.
- LWW benzeri deterministic apply (updatedAt karsilastirma) eklendi.
- Reconcile telemetry eventi eklendi.

## Sprint 8
Status: Completed (phase-1 baseline)
- iOS kamera/fotograf permission description alanlari eklendi.
- Security scan workflow (secret + dependency) eklendi.
- Permission denial UX fallback iyilestirildi.

## Sprint 9
Status: In Progress
- Editor icinde persistence/sync yardimci metotlari ayrildi.
- Daha derin dosya bolunmesi (controller/viewmodel extraction) devam ediyor.

## Sprint 10
Status: In Progress
- AppError tipi eklendi.
- Structured logger + telemetry servisleri eklendi.
- `save_duration`, `sync_latency`, `pending_queue`, `reconcile_outcome` eventleri aktif.

## Sprint 11
Status: In Progress
- TR/EN localization altyapisi (ARB + provider + app delegates) eklendi.
- Profile ayarlari ekranina dil secici eklendi.
- A11y/reduce-motion iyilestirmeleri login tarafinda baslatildi.

## Sprint 12
Status: Completed (automation baseline)
- Full regression scripti (`scripts/run_release2_validation.sh`) eklendi.
- Release checklist release-2 validasyon komutlariyla guncellendi.
