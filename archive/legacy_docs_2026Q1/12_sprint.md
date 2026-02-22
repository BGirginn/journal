# Journal V2 - 12 Sprint Detaylı Yol Haritası

## 1) Plan Çerçevesi

### Dönem
- Toplam süre: 6 ay
- Sprint sayısı: 12
- Sprint süresi: 2 hafta
- Başlangıç varsayımı: 2026 Q1

### Ekip ve Kapasite Varsayımı
- 6+ dev squad (mobile ağırlıklı, backend/devops destekli)
- 1 QA (veya QA sorumluluğu dağıtılmış)
- 1 Product/Design temsilcisi
- Ortalama sprint kapasitesi: 80-100 SP

### Stratejik Öncelik Sırası
1. Release-blocker güvenlik ve teslimat risklerini kapatmak
2. Sync güvenilirliğini (oplog + reconcile) üretim seviyesine taşımak
3. Kalite kapılarını otomatik hale getirmek
4. Editor mimarisini sürdürülebilir hale getirmek
5. UX/A11y/L10n iyileştirmeleriyle ölçeklenebilir ürün deneyimi oluşturmak

### Release Pencereleri
- Release-1: Sprint 4 sonu (Stabilizasyon Release)
- Release-2: Sprint 12 sonu (Major Capability Release)

### Done Tanımı (Global)
- Kod merge kriterleri: analyze + test + security gate geçer
- Kritik akışlar için test güncellemesi yapılır
- Dokümantasyon/ADR etkisi varsa güncellenir
- Telemetry etkisi olan işlerde event şeması eklenir

---

## 2) Epic Yapısı

### EPIC-A: Release & Security Baseline
- Android release signing/hardening
- Firestore rules/path tutarlılığı
- Temel güvenlik kalite kapıları

### EPIC-B: Quality Automation
- CI workflowları
- Test sağlığı ve flaky azaltımı
- Güvenlik taramaları

### EPIC-C: Sync Reliability V2
- Oplog producer
- Uploader/ack/retry
- Reconcile ve conflict resolution

### EPIC-D: Editor Refactor
- Büyük ekran parçalama
- State/sync ayrıştırma
- Test edilebilirlik artırımı

### EPIC-E: UX/A11y/L10n
- Accessibility baseline
- Localization altyapısı
- Responsive/tablet entegrasyon

### EPIC-F: Observability & Operations
- Structured logging
- Operational telemetry
- SLO dashboard ve release health görünürlüğü

---

## 3) Sprint Bazlı Detay Plan

## Sprint 1 - Release Blocker Cleanup

### Tema
- Production release güvenlik ve konfigürasyon blokajlarını kaldırma

### Sprint Hedefleri
1. Android release build debug key ile imzalanmamalı
2. Firestore collection naming tutarlılığı için teknik karar kesinleşmeli
3. Hızlı güvenlik riskleri için önleyici checklist aktif edilmeli

### User Story / Task Breakdown
- US-1: "Release build güvenli imzalama ile üretilsin"
- Task: `android/app/build.gradle.kts` release signing yapılandırması
- Task: `key.properties`/CI secret dokümantasyonu
- Task: local debug fallback yerine release fail-fast

- US-2: "Firestore team collection adları tutarlı olsun"
- Task: kod tarafında tek isim standardı belirleme (`team_members` vs `teamMembers`)
- Task: rules ile kod path eşleştirme planı
- Task: migration etki analizi (mevcut veriler)

- US-3: "Release öncesi minimal security checklist zorunlu olsun"
- Task: release checklist’e signing/rules doğrulama adımı ekleme
- Task: smoke doğrulama komut seti

### Kabul Kriterleri
1. Release build artık debug signing kullanmıyor
2. Rules-path mismatch için net teknik karar ve uygulanabilir değişiklik listesi hazır
3. Sprint demo’da release adayı güvenlik checklist’i çalıştırılabilir

### Story Point Planı
- Signing hardening: 24 SP
- Rules/path alignment design + prep: 20 SP
- Checklist + smoke automation basics: 16 SP
- Buffer/bugfix: 20 SP
- Toplam: 80 SP

### Riskler
- Keystore yönetimi ve secret erişim gecikmesi
- Rules değişiminin mevcut datayı etkilemesi

### Bağımlılıklar
- DevOps/CI secret yönetimi
- Firebase rules deploy yetkisi

### Sprint Çıkış Metrikleri
- Release signing doğrulaması: %100
- P0 açık sayısı: Sprint sonu < 3

---

## Sprint 2 - CI Quality Gate Foundation

### Tema
- PR ve merge süreçlerinde kalite kapılarını zorunlu hale getirme

### Sprint Hedefleri
1. PR pipeline: `flutter analyze`, `flutter test`, format check
2. Release candidate pipeline: build + artifact doğrulama
3. Fail-fast kalite kapıları (merge block)

### User Story / Task Breakdown
- US-4: "PR açıldığında otomatik kalite kontrolleri çalışsın"
- Task: `.github/workflows/pr_ci.yml` oluşturma
- Task: analyze/test/format adımları
- Task: branch protection entegrasyonu

- US-5: "Release candidate build otomatik doğrulansın"
- Task: release build workflow
- Task: artifact upload + metadata
- Task: workflow status badge/dokümantasyon

- US-6: "CI fail nedenleri okunabilir olsun"
- Task: standart log çıktıları
- Task: hata sınıflandırma (lint/test/build)

### Kabul Kriterleri
1. PR merge için en az 3 zorunlu check aktif
2. Release workflow manuel veya tag ile tetiklenebilir
3. CI hata çıktısı ekip içinde tekrarlanabilir (runbook)

### Story Point Planı
- PR CI pipeline: 34 SP
- Release pipeline skeleton: 28 SP
- Branch protection + docs: 14 SP
- Stabilizasyon: 14 SP
- Toplam: 90 SP

### Riskler
- CI sürelerinin uzun olması
- Flaky testlerin merge hızını düşürmesi

### Bağımlılıklar
- GitHub repo admin izinleri
- Secret değişkenlerinin hazır olması

### Sprint Çıkış Metrikleri
- PR gate coverage: %100
- Ortalama CI süresi: < 15 dk hedef

---

## Sprint 3 - Test Health and Stability

### Tema
- Test kırıklarını giderme ve temel güvence setini sağlamlaştırma

### Sprint Hedefleri
1. `flutter test` suite yeşile dönsün
2. Widget testlerde timer/animation kaynaklı flaky davranışlar giderilsin
3. Kritik akış smoke testleri eklensin

### User Story / Task Breakdown
- US-7: "Widget test deterministic çalışsın"
- Task: `test/widget_test.dart` timer pending fix
- Task: animation disable/mock stratejisi
- Task: test harness standardization

- US-8: "Kritik akış smoke testleri olsun"
- Task: login shell render smoke
- Task: journal create smoke
- Task: save/reload smoke

- US-9: "Test raporları CI’da görünür olsun"
- Task: junit/summary çıktısı
- Task: failed test artifact attachment

### Kabul Kriterleri
1. `flutter test` default suite fail etmez
2. En az 3 kritik smoke scenario CI’da koşar
3. Flaky oranı <%5

### Story Point Planı
- Widget test stabilization: 30 SP
- Smoke test ekleme: 28 SP
- CI raporlama: 12 SP
- Bugfix ve stabilization: 10 SP
- Toplam: 80 SP

### Riskler
- Üçüncü parti paket animasyon davranışları
- Mock altyapısında aşırı bakım maliyeti

### Bağımlılıklar
- Sprint 2 CI altyapısı

### Sprint Çıkış Metrikleri
- Test pass oranı: >= 95%
- Flaky retry ihtiyacı: <= %5

---

## Sprint 4 - Release-1 Stabilizasyon ve Go/No-Go

### Tema
- İlk release penceresi için sistemin stabilize edilmesi

### Sprint Hedefleri
1. Release-1 kapsamına giren P0/P1 açıklar kapanmalı
2. Security + test + build kalite kapıları release dalında koşmalı
3. Go/No-Go kararı ölçülebilir kriterlerle alınmalı

### User Story / Task Breakdown
- US-10: "Release candidate checklist eksiksiz çalışsın"
- Task: crash-free smoke checklist
- Task: offline/save/restart senaryo doğrulama
- Task: rules deploy doğrulama

- US-11: "Release kararı objektif olsun"
- Task: go/no-go tablosu
- Task: release retrospective template

- US-12: "Post-release izleme hazır olsun"
- Task: ilk 72 saat monitoring planı
- Task: rollback prosedürü

### Kabul Kriterleri
1. Release-1 go/no-go checklist %100 tamam
2. P0 açık kalmaz
3. Rollback ve hotfix akışı prova edilmiş

### Story Point Planı
- Release hardening: 32 SP
- Validation + QA cycle: 22 SP
- Monitoring + runbook: 16 SP
- Buffer: 10 SP
- Toplam: 80 SP

### Riskler
- Prod konfigürasyon farklılıkları
- Release son dakika scope artışı

### Bağımlılıklar
- Sprint 1-3 çıktılarını tamamlama

### Release-1 Go/No-Go Kriteri
- Go:
- Release signing güvenli
- Rules mismatch çözülmüş
- CI gates yeşil
- Kritik testler geçiyor
- No-Go:
- P0 güvenlik açığı
- Sync veri bütünlüğü riski
- Test suite kırık

---

## Sprint 5 - Sync V2 Phase 1 (Oplog Producer)

### Tema
- Tüm kritik yazma akışlarında oplog üretiminin devreye alınması

### Sprint Hedefleri
1. Local mutasyonlardan oplog üretimi yapılması
2. Oplog kimliği/HLC/deviceId standardı
3. Sync state observability başlangıcı

### User Story / Task Breakdown
- US-13: "Write operations oplog’a düşsün"
- Task: journal/page/block create/update/delete üzerinde oplog üretimi
- Task: `OplogDao.insertOplog` entegrasyonu
- Task: transaction integrity

- US-14: "Oplog modeli tutarlı olsun"
- Task: payload schema standardı
- Task: idempotency anahtarı
- Task: status lifecycle başlangıç değerleri

- US-15: "Queue görünürlüğü olsun"
- Task: pending oplog count metriği
- Task: basic debug ekranı/log

### Kabul Kriterleri
1. Kritik write akışlarının %100’ü oplog üretir
2. Oplog satırları schema-valid
3. Pending queue metriği izlenebilir

### Story Point Planı
- Producer integration: 48 SP
- Schema/idempotency: 24 SP
- Queue observability basic: 18 SP
- Toplam: 90 SP

### Riskler
- Data schema drift
- HLC sıralama edge case’leri

### Bağımlılıklar
- Sprint 3 test altyapısı

### Sprint Çıkış Metrikleri
- Oplog üretim kapsaması: >= %95
- Oplog schema hata oranı: < %1

---

## Sprint 6 - Sync V2 Phase 2 (Uploader/Ack/Retry)

### Tema
- Oplog’ların güvenli şekilde remote’a taşınması

### Sprint Hedefleri
1. Pending oplog uploader
2. Ack ve status transition
3. Retry/backoff politikası

### User Story / Task Breakdown
- US-16: "Pending oploglar remote’a gönderilsin"
- Task: background uploader loop
- Task: batch upload stratejisi
- Task: partial failure handling

- US-17: "Status lifecycle doğru işlesin"
- Task: pending -> sent -> acked/apply state transition
- Task: duplicate submit guard

- US-18: "Network hatalarında dayanıklılık"
- Task: exponential backoff
- Task: retry upper bound
- Task: failover logging

### Kabul Kriterleri
1. Offline->online geçişte pending queue azalarak sıfıra iner
2. Duplicate write oranı kabul edilebilir eşik altında
3. Retry mekanizması testlerle doğrulanmış

### Story Point Planı
- Uploader pipeline: 44 SP
- Ack/status machine: 26 SP
- Retry/backoff + tests: 24 SP
- Stabilizasyon: 6 SP
- Toplam: 100 SP

### Riskler
- Firebase rate-limit
- Büyük batch’lerde timeout

### Bağımlılıklar
- Sprint 5 producer tamamlanması

### Sprint Çıkış Metrikleri
- Sync success (happy path): >= %98
- Ortalama retry sayısı: < 2

---

## Sprint 7 - Sync V2 Phase 3 (Reconcile/Conflict)

### Tema
- Çok cihazlı çakışmaları deterministik çözme

### Sprint Hedefleri
1. Reconcile motoru
2. Conflict policy (field-level / last-writer / domain-specific)
3. A/B cihaz entegrasyon test seti

### User Story / Task Breakdown
- US-19: "Çakışma durumları öngörülebilir çözülsün"
- Task: conflict matrix (text, media, delete vs update)
- Task: deterministic apply rule implementation

- US-20: "Reconcile izlenebilir olsun"
- Task: reconcile outcome telemetry
- Task: failed reconcile fallback

- US-21: "Çok cihaz testleri otomatize olsun"
- Task: device A/B senaryoları
- Task: clock skew senaryoları

### Kabul Kriterleri
1. En az 10 conflict senaryosu deterministic sonuç verir
2. Reconcile failure kritik veri kaybına yol açmaz
3. Multi-device integration suite CI’da koşar (nightly olabilir)

### Story Point Planı
- Conflict engine: 46 SP
- Reconcile telemetry: 16 SP
- Multi-device tests: 28 SP
- Stabilizasyon: 5 SP
- Toplam: 95 SP

### Riskler
- Domain kuralı belirsizliği
- Non-deterministic edge case’ler

### Bağımlılıklar
- Sprint 6 uploader/ack hazır olmalı

### Sprint Çıkış Metrikleri
- Conflict test pass: >= %95
- Reconcile failure rate: < %1

---

## Sprint 8 - Security Hardening and Data Protection

### Tema
- Veri koruma ve güvenlik temelini kurumsal seviyeye çıkarma

### Sprint Hedefleri
1. At-rest encryption rollout phase-1
2. iOS permission description eksiklerinin tamamlanması
3. Secret/dependency scan’in CI’ya entegrasyonu

### User Story / Task Breakdown
- US-22: "Local veriler şifreli tutulmalı"
- Task: encryption strategy implementation
- Task: key material secure storage
- Task: migration compatibility

- US-23: "Platform permission compliance"
- Task: iOS camera/photo usage descriptions
- Task: permission denial UX fallback

- US-24: "Security scan automation"
- Task: secret scan job
- Task: dependency vulnerability scan

### Kabul Kriterleri
1. Yeni kurulumlarda local sensitive data encrypted
2. iOS media izin akışı policy-compliant
3. CI security scan yüksek riskte build’i fail eder

### Story Point Planı
- Encryption + migration: 48 SP
- iOS compliance: 10 SP
- Security scans: 16 SP
- Regression + docs: 11 SP
- Toplam: 85 SP

### Riskler
- Encryption migrationde data corruption riski
- Performans etkisi

### Bağımlılıklar
- Sync v2 stabilitesi (Sprint 7)

### Sprint Çıkış Metrikleri
- Security high finding açık sayısı: %50 azalma
- Encryption migration başarı oranı: >= %99

---

## Sprint 9 - Editor Refactor Phase 1

### Tema
- Editor kod tabanının bölünmesi ve sorumlulukların ayrılması

### Sprint Hedefleri
1. `EditorScreen` dosyasını modülerleştirme
2. UI ve sync/data işlemlerini ayrıştırma
3. Test edilebilirliği artırma

### User Story / Task Breakdown
- US-25: "Editor business logic widget dışında yönetilsin"
- Task: editor controller/viewmodel katmanı
- Task: command handling abstraction

- US-26: "Media sync editor’dan ayrışsın"
- Task: `MediaSyncService` extraction
- Task: upload/sync reusable API

- US-27: "Refactor sonrası regression güvence"
- Task: editor interaction tests
- Task: save/sync integration test

### Kabul Kriterleri
1. `editor_screen.dart` boyut/karmaşıklık belirgin düşer
2. Yeni katmanlarla test yazımı kolaylaşır
3. Editor ana akışları regresyonsuz çalışır

### Story Point Planı
- Controller split: 34 SP
- Media sync extraction: 28 SP
- Tests + stabilization: 20 SP
- Cleanup: 8 SP
- Toplam: 90 SP

### Riskler
- Refactor kaynaklı regressions
- Async state race condition

### Bağımlılıklar
- Sprint 7/8 stabil sync ve security tabanı

### Sprint Çıkış Metrikleri
- Editor file complexity düşüşü: >= %30
- Editor akış test pass: >= %95

---

## Sprint 10 - Editor Refactor Phase 2 + Observability

### Tema
- Refactor’ı tamamlayıp operasyonel gözlemlenebilirliği ekleme

### Sprint Hedefleri
1. Error model standardizasyonu
2. Structured log + telemetry event şeması
3. Sync/save performans metriği toplama

### User Story / Task Breakdown
- US-28: "Hatalar tek modelle yönetilsin"
- Task: `AppError` hiyerarşisi
- Task: catch+ignore pattern temizliği

- US-29: "Operasyonel metrikler dashboard’a akabilsin"
- Task: save_duration, sync_latency, pending_queue metrik eventleri
- Task: event naming ve versioning

- US-30: "DebugPrint yerine kontrollü loglama"
- Task: logging adapter
- Task: PII redaction

### Kabul Kriterleri
1. Kritik servislerde typed error kullanımı
2. Minimum telemetry event seti canlı
3. Debug loglar redaction policy’ye uygun

### Story Point Planı
- Error model rollout: 30 SP
- Telemetry events: 28 SP
- Logging adapter + migration: 22 SP
- Stabilizasyon: 10 SP
- Toplam: 90 SP

### Riskler
- Event schema değişiklikleri
- Performans overhead

### Bağımlılıklar
- Sprint 9 refactor altyapısı

### Sprint Çıkış Metrikleri
- Silent fail pattern azalımı: >= %70
- Telemetry event completeness: >= %90

---

## Sprint 11 - UX, Accessibility, Localization

### Tema
- Ölçeklenebilir ve erişilebilir ürün deneyimi

### Sprint Hedefleri
1. A11y baseline (semantics, touch target, contrast)
2. TR/EN localization altyapısı
3. Kritik ekranlarda UX tutarlılığı

### User Story / Task Breakdown
- US-31: "Erişilebilirlik minimum standardı sağlansın"
- Task: semantics labels/hints
- Task: touch target audit
- Task: reduce motion uyumu

- US-32: "Lokalizasyon altyapısı devrede olsun"
- Task: `flutter_localizations` kurulumu
- Task: ARB extraction (kritik ekranlar)
- Task: language switch doğrulaması

- US-33: "Kritik akışlarda UX polish"
- Task: login/library/editor empty/loading/error state standardizasyonu
- Task: ikon/metin tutarlılık temizliği

### Kabul Kriterleri
1. A11y checklist’in kritik maddeleri pass
2. TR/EN dillerinde ana akışlar çalışır
3. UX state’ler tutarlı component seti ile sunulur

### Story Point Planı
- Accessibility improvements: 30 SP
- Localization infra + extraction: 28 SP
- UX polish: 16 SP
- QA + fixes: 6 SP
- Toplam: 80 SP

### Riskler
- Çok sayıda hardcoded string
- Design consistency kararlarının gecikmesi

### Bağımlılıklar
- Sprint 9/10 component ve logging refactor çıktıları

### Sprint Çıkış Metrikleri
- A11y kritik bulgu sayısı: >= %60 azalma
- Lokalizasyon kapsaması (kritik ekran): >= %80

---

## Sprint 12 - Release-2 Finalization

### Tema
- Major capability release için tam regression, kalite ve operasyon hazırlığı

### Sprint Hedefleri
1. Sync v2 + security + UX geliştirmelerinin release-ready hale gelmesi
2. Full regression + performance/security smoke
3. Go/No-Go ile Release-2 kararı

### User Story / Task Breakdown
- US-34: "Release-2 tam doğrulama"
- Task: full regression suite
- Task: perf smoke (cold/warm, jank, save/sync latency)
- Task: security smoke (rules, secret scan, signing)

- US-35: "Operasyon hazırlığı"
- Task: incident/runbook güncelleme
- Task: release notes + known issues
- Task: rollback planı prova

- US-36: "Post-release gözlem"
- Task: 7 gün izleme planı
- Task: alert threshold ve sorumluluk ataması

### Kabul Kriterleri
1. Release-2 go/no-go checklist tamam
2. P0/P1 kritik bug kapalı
3. Regression suite hedef pass oranı >= %98

### Story Point Planı
- Full validation: 34 SP
- Perf/security smoke: 20 SP
- Release ops + runbook: 12 SP
- Bugfix window: 14 SP
- Toplam: 80 SP

### Riskler
- Son hafta kritik bug yoğunluğu
- Scope creep

### Bağımlılıklar
- Sprint 5-11 çıktılarının stabilize edilmiş olması

### Release-2 Go/No-Go Kriteri
- Go:
- Sync conflict suite başarılı
- Encryption migration güvenli
- CI quality gates %100
- Kritik UX/A11y bulguları kapatılmış
- No-Go:
- Data integrity riski
- Critical security açık
- Regression fail trendi

---

## 4) Kapasite ve SP Dağılım Özeti

| Sprint | Planlanan SP |
|---|---:|
| S1 | 80 |
| S2 | 90 |
| S3 | 80 |
| S4 | 80 |
| S5 | 90 |
| S6 | 100 |
| S7 | 95 |
| S8 | 85 |
| S9 | 90 |
| S10 | 90 |
| S11 | 80 |
| S12 | 80 |
| Toplam | 1060 |

Not: SP değerleri takım velocity’sine göre sprint başında yeniden kalibre edilir.

---

## 5) Cross-Sprint Risk Azaltma Planı

1. Her sprint sonunda teknik risk review (30 dk)
2. Her 2 sprintte bir architecture checkpoint
3. Flaky test quarantine politikası (max 1 sprint)
4. Security bulguları için ayrı P0 triage hattı
5. Release öncesi freeze window (en az 3 iş günü)

---

## 6) Minimum Dashboard KPI Seti

1. CI pass rate
2. Test pass/flaky oranı
3. Sync success ve pending queue trendi
4. Crash-free sessions
5. Save/sync p95 latency
6. P0/P1 açık sayısı

---

## 7) Çalışma Şekli (Önerilen Ritüeller)

1. Sprint Planning: backlog + risk + dependency görünürlüğü
2. Mid-sprint demo: teknik doğrulama checkpoint
3. Sprint Review: ürün etkisi + kalite metrikleri
4. Retro: delivery iyileştirme aksiyonları (en az 2 aksiyon/sprint)

---

## 8) Bu Planın Başarı Koşulu

- İlk 4 sprintte release ve kalite tabanı oturursa, 5-12 sprintte yapılan sync/refactor yatırımları gerçek değer üretir.
- Aksi durumda sync/refactor işleri sürekli operasyonel acil işlerle kesilir.

