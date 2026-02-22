# 1) Yönetici Özeti

## Kapsam
- Uygulama: `journal_app` (Flutter, iOS+Android)
- Versiyon: `1.0.1+2` (`pubspec.yaml:4`)
- İncelenen alanlar: Kod kalitesi, mimari, performans, güvenlik, backend/altyapı, UI/UX, test, release readiness
- Kanıt standardı: Repo tabanlı + varsayım etiketi

## Genel Durum
- Güçlü yönler:
- Offline local DB altyapısı mevcut (Drift, migration stratejisi var) (`lib/core/database/app_database.dart:13`)
- Riverpod + modüler feature klasörlemesi mevcut (`lib/features/*`)
- Temel Firestore rules ve release checklist dokümantasyonu mevcut (`firestore.rules`, `md_files/docs/RELEASE_CHECKLIST.md`)
- Kritik açıklar:
- Sync mimarisi dokümanda hedeflenen seviyede değil; `syncUp`/`reconcile` uygulanmamış (`lib/core/sync/sync_service.dart:65`)
- Android release debug key ile imzalanıyor (`android/app/build.gradle.kts:40`)
- Firestore koleksiyon adı kod/rules tutarsız (`team_members` vs `teamMembers`) (`lib/features/team/team_service.dart:51`, `firestore.rules:57`)
- Widget test paketi kırık (pending timer) (`test/widget_test.dart:11` çalıştırma çıktısı)
- CI workflow repoda yok (`.github/workflows` bulunamadı)

## Üst Seviye Puan (10 üzerinden)
| Alan | Skor | Durum |
|---|---:|---|
| Kod Kalitesi | 6.0 | Orta, büyük sınıf ve tutarsız hata ele alma var |
| Mimari | 5.5 | Hedef mimari var, uygulama kısmi |
| Performans Hazırlığı | 5.0 | Ölçüm hedefleri var, otomatik ölçüm yok |
| Güvenlik | 4.5 | Temel kurallar var, release-hardening ve data-protection eksik |
| Backend/Altyapı | 4.0 | Firebase tabanı var, CI/CD ve SLO/observability yok |
| UI/UX | 6.5 | Görsel kalite iyi, erişilebilirlik/lokalizasyon sistematik değil |
| Test & Release Readiness | 4.0 | Test kapsamı dar, quality gate otomasyonu eksik |

## İşe Etki Açısından İlk 6 Öncelik
1. `CRITICAL` Android release signing/hardening düzeltmesi.
2. `CRITICAL` Sync motorunun (`syncUp/reconcile`) tamamlanması ve conflict policy.
3. `HIGH` Firestore koleksiyon/rules tutarsızlığının giderilmesi.
4. `HIGH` CI kalite kapıları (analyze/test/security scan/build) zorunlu hale getirilmesi.
5. `HIGH` Test mimarisinin onarımı (widget timer, e2e kritik akışlar).
6. `HIGH` Gizli veri/logging ve at-rest koruma katmanı.

---

# 2) Teknik Tarama Sonuçları (Kod/Mimari/Perf/Güvenlik/Backend)

## 2.0 Skor Rubriği
- `1-3`: Kritik risk, release blocker
- `4-5`: Zayıf, önemli refactor gerekiyor
- `6-7`: Orta, hedefe yakın ama eksikler var
- `8-9`: İyi, küçük iyileştirmeler
- `10`: Mükemmel, sürdürülebilir örnek seviye

## 2.1 Kod Kalitesi (10 Kriter)
| Kriter | Skor | Kanıt | Etki | Önerilen Aksiyon |
|---|---:|---|---|---|
| Naming/Okunabilirlik/Tutarlılık | 6 | Genel tutarlı isimlendirme; fakat aynı dosyada “legacy + yeni” yorum karışımı (`lib/core/sync/sync_service.dart:143`) | Öğrenme eğrisi artar | Kod stili rehberi + PR checklist ile isim/yorum standardı |
| SOLID + Clean Code | 5 | `EditorScreen` 1488 satır, UI+data+sync birlikte (`lib/features/editor/editor_screen.dart:27`) | Değişiklik riski yüksek | Editor’ı `state/controller/sync adapter` olarak parçala |
| DRY ihlalleri + duplicate | 5 | Görsel/akış benzer bloklar tekrarlı (örn. upload/sync blokları) (`lib/features/editor/editor_screen.dart:966`, `1002`) | Bug fix maliyeti artar | Ortak `MediaSyncService` ile tekrar azalt |
| Complexity (büyük sınıf/metod) | 4 | Çok büyük ekran sınıfları (`editor_screen.dart`, `friends_screen.dart`) | Test edilebilirlik düşer | max-file-size/max-method-size quality gate |
| Dokümantasyon + yorum kalitesi | 7 | Mimari/test/perf/security dokümanları var (`md_files/docs/*`) | Onboarding kolay | Doküman-kod drift kontrolü için ADR update zorunlu kural |
| Error handling standardı | 4 | Birçok yerde `catch` + ignore/null (`lib/core/database/storage_service.dart:46`, `lib/providers/journal_providers.dart:53`) | Sessiz veri kaybı | Ortak `AppError` + telemetry/log seviyesi standardı |
| Test coverage + kalite | 4 | Sadece 3 test dosyası; widget test fail (`test/widget_test.dart:11`) | Regression riski yüksek | Test piramidi hedefi + kritik akış e2e |
| Dependency yönetimi + riskli paketler | 6 | Paketler pinli; ancak otomatik update/security scan kanıtı yok (`pubspec.yaml`) | Bilinmeyen CVE riski | Dependabot/Renovate + `osv-scanner` |
| Dead code/unused alanlar | 5 | Responsive bileşenler tanımlı ama kullanılmıyor (`lib/core/responsive/responsive_layout.dart`) | Bakım maliyeti | Kullanılmayan kodu temizle veya entegre et |
| Lint/format + CI enforcement | 5 | Lint kuralları güçlü (`analysis_options.yaml`), fakat CI enforcement yok | Kalite dalgalanır | PR’da zorunlu `analyze/test/format-check` |

### Top 10 Kritik Refactor Alanı
1. `lib/features/editor/editor_screen.dart` parçalama (UI-state-sync ayrımı).
2. `lib/core/sync/sync_service.dart` full oplog sync geçişi.
3. `lib/core/database/storage_service.dart` hata modeli + retry queue.
4. `lib/core/navigation/app_router.dart` auth/profile flow sadeleştirme.
5. `lib/features/team/team_service.dart` collection naming ve lifecycle yönetimi.
6. `lib/providers/journal_providers.dart` cloud error swallow azaltımı.
7. `test/widget_test.dart` deterministic timer/animation test düzeltimi.
8. `lib/features/friends/friends_screen.dart` (büyük dosya) modülerleşme.
9. Telemetry abstraction (debugPrint yerine structured log).
10. UI localization katmanı (hardcoded TR stringlerin ayrıştırılması).

### Hızlı Kazanımlar (1-3 gün)
- Android release signing config düzeltme.
- Firestore `team_members/teamMembers` tekilleştirme.
- Widget test timer fix (`pumpAndSettle` + animation kapatma).
- CI’da `flutter analyze` + `flutter test` zorunlu gate.

### Orta Vadeli Refactor (1-4 hafta)
- Sync engine v2 (oplog queue, ack, retry, reconcile).
- Editor domain katmanına command/usecase ayrımı.
- Global error/result model ve telemetry pipeline.
- Accessibility + localization altyapısı.

## 2.2 Mimari Analiz

### Mevcut Mimari (Metin Diyagram)
```text
UI (Flutter Screens)
  -> Riverpod Providers
    -> Drift DAO (Local SQLite)
    -> FirestoreService/StorageService (Remote)

Auth: FirebaseAuth + GoogleSignIn
Sync: login sonrası syncDown (legacy), syncUp/reconcile TODO
```

### Hedef Mimari
```text
Presentation (Screen/ViewModel)
  -> UseCases (CreateJournal, SavePage, SyncNow)
    -> Repositories (Local-first, deterministic)
      -> Local (Drift) + Remote (Firestore/Storage)

Sync Engine:
  Oplog producer -> Queue -> Uploader -> Ack -> Reconciler
  Conflict policy + idempotency + retry/backoff
```

### Gap Analizi
| Alan | Mevcut | Hedef | Gap |
|---|---|---|---|
| Presentation/Domain/Data ayrımı | Kısmi | Net katman | Büyük ekranlar domain iş taşıyor |
| DI yaklaşımı | Riverpod var | Composition root + interface bazlı | Soyutlama seviyesi düşük |
| Sync | `syncDown` legacy | full oplog + reconcile | Kritik eksik |
| Cache/offline invalidation | Local save var | deterministic invalidation | Kısmi |
| Navigation | GoRouter var | auth/profile deterministik flow | Karmaşık redirect |
| Multi-env/flavor | Dokümanda var | CI’da env-parity | Kodda net değil |

### “Yeni Feature Eklemek Kaç Adım?”
- Bugünkü durum: ~9-12 adım (UI + provider + DAO + Firestore + hata + test), çünkü bazı altyapılar standartlaştırılmamış.
- Hedef: 5-7 adım (usecase/repository şablonuyla).

## 2.3 Performans

### Ölçüm Durumu
- Repo içinde hedef metrik dokümante (`md_files/docs/PERFORMANCE.md`) ancak otomatik benchmark/CI perf gate yok.
- Gerçek cihaz/senaryo ölçümü paylaşılmadı (varsayım etiketi).

### Mevcut vs Hedef Metrik Tablosu
| metrik | mevcut | hedef | olcum_yontemi | notlar |
|---|---|---|---|---|
| Cold start | Bilinmiyor | <2s | Flutter DevTools + startup trace | Ölçüm pipeline eksik |
| Warm start | Bilinmiyor | <1s | DevTools timeline | Ölçüm yok |
| Ekran geçişi | Bilinmiyor | <300ms | profile mode frame timeline | Ölçüm yok |
| Jank/frame drop | Bilinmiyor | 60fps sabit | Frame chart | Ink/editor akışları kritik |
| RAM avg/peak | Bilinmiyor | leak yok | Android Profiler/Instruments | Uzun oturum test yok |
| CPU idle | Bilinmiyor | <5% | profiler sample | Ölçüm yok |
| Pil tüketimi | Bilinmiyor | düşük | Battery historian + Instruments | Ölçüm yok |
| APK/IPA boyutu | Bilinmiyor | kategori ortalaması | `flutter build --analyze-size` | Size gate yok |
| API latency avg/P95 | Bilinmiyor | <500ms / <1.5s | Firebase Performance/custom spans | Şu an telemetry sınırlı |
| Crash/ANR | Bilinmiyor | <1% / <0.5% | Crashlytics/Play Console | SDK entegre görünmüyor |

### Bottleneck Adayları
- Editor içinde eşzamanlı UI+sync işleri (`editor_screen.dart:83`, `966`).
- Sync’de sequential network+DB döngüleri (`sync_service.dart:90`, `127`, `164`).
- Ink çizimde incremental path rebuild (`ink_canvas.dart:102`, `160`).

### Optimizasyon Planı
- Quick wins:
- `build --analyze-size` raporu ve paket/asset trimming.
- Editor save sırasında fire-and-forget queue modeline geçiş.
- Deep work:
- Isolate tabanlı medya işleme ve incremental sync batching.
- Render invalidation minimizasyonu + repaint sınırlarının gözden geçirilmesi.

## 2.4 Güvenlik (OWASP MASVS / Mobile Top 10)

### Threat Model (Özet)
- Asset: Journal içeriği, medya dosyaları, kullanıcı kimliği, paylaşım davetleri
- Actor: Kötü niyetli kullanıcı, çalınan cihaz erişimi, yetkisiz backend istemcisi
- Attack Surface: Mobil istemci, Firestore rules, local DB/storage, auth token, paylaşım endpointleri

### Kritik Bulgular
| id | baslik | kategori | severity | etki | kanıt | onerilen_cozum | tahmini_efor | bagimlilik |
|---|---|---|---|---|---|---|---|---|
| SEC-01 | Android release debug key ile imza | Güvenlik/Release | Critical | Store/production güveni ve supply-chain riski | `android/app/build.gradle.kts:40` | Release signing + keystore secret yönetimi | 1-2 gün | CI secret setup |
| SEC-02 | At-rest encryption uygulanmamış | Veri Koruma | High | Cihaz ele geçirilmesinde local veri ifşası | `app_database.dart` plain sqlite; secure storage bağımlılığı yok (`pubspec.yaml`) | SQLCipher/field encryption + key mgmt | 1-2 sprint | Migration plan |
| SEC-03 | iOS kamera/foto usage description eksik | Platform Security/Privacy | High | Kamera/galeri akışında runtime fail/uyumluluk riski | `Info.plist` yalnız mikrofon içeriyor (`ios/Runner/Info.plist:48`), kamera kullanımı var (`image_picker_service.dart:27`) | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` ekle | <1 gün | iOS test |
| SEC-04 | Firestore collection name mismatch | Access Control | High | Rules bypass/işlevsel erişim hatası riski | Kod: `team_members` (`team_service.dart:51`), rules: `teamMembers` (`firestore.rules:57`) | Tek isim standardı + rules ve kod birlikte güncelle | 1-2 gün | Rules deploy |
| SEC-05 | Hata/log standardı hassas bilgi filtrelemiyor | Logging | Medium | Üretimde teknik detay sızması | Çok sayıda `debugPrint` (`rg` çıktısı) | Structured logger + redaction policy | 2-3 gün | Logging abstraction |

### Güvenlik Risk Matrisi
| risk | olasilik | etki | skor | azaltma | yedek_plan |
|---|---:|---:|---:|---|---|
| Debug signing ile release | 4 | 5 | 20 | Release key + CI signing | Release blokaj kuralı |
| Local data theft (unencrypted DB) | 3 | 5 | 15 | At-rest encryption + app lock | Sensitive data minimization |
| Rules-path mismatch | 4 | 4 | 16 | Rules test suite + naming convention | Emergency rule patch |
| Incomplete sync reconciliation | 4 | 4 | 16 | Oplog v2 + conflict tests | Write-protect / fallback sync |
| Test/CI eksikliği | 4 | 4 | 16 | Mandatory quality gates | Manual go/no-go checklist |

### Top 10 Güvenlik Aksiyonu
1. Release signing + artifact integrity.
2. Firestore path/rules tekilleştirme.
3. At-rest encryption rollout.
4. Token lifecycle & session hardening policy.
5. Secret scanning CI (gitleaks/trufflehog).
6. Log redaction standardı.
7. Security regression test seti.
8. Dependency vulnerability scan.
9. Deep link güvenlik validasyonu.
10. KVKK/GDPR data deletion akışının testle doğrulanması.

### Güvenlik Test Planı
- SAST: `flutter analyze` + secret scan + dependency vuln scan.
- DAST-Mobile: rooted/emulator dynamic checks (debuggable, TLS behavior, storage).
- Rules test: Firestore emulator ile allow/deny matrix.

## 2.5 Backend ve Altyapı
- Repo’da backend mostly Firebase managed services üzerinden.
- Sunucu tarafı API, versioning, rate limiting, tracing kurgusu repo içinde görünmüyor (varsayım).
- CI/CD workflow dosyası yok; sadece tasarım dokümanı var (`md_files/ci_cd.md`).

### Backend İyileştirme Backlog’u
1. Firestore rules test otomasyonu.
2. Env-parity (dev/staging/prod) config pipeline.
3. Incident/runbook + SLO dashboard.
4. Sync telemetry event’leri (queue depth, retry, reconcile outcomes).
5. Backup/restore tatbikatı (Firestore exports).

### SLO/SLA Önerisi
- Crash-free sessions: `>=99.5%`
- Sync success rate (24h): `>=99%`
- P95 sync latency: `<1.5s`
- P95 save latency (local): `<150ms`

### Incident/Runbook Önerileri
- Incident sınıfları: Auth, Sync, Data loss risk, Rules misconfig, Release pipeline.
- On-call playbook: triage → rollback/rules patch → user comms → postmortem.

---

# 3) UI/UX Denetim Sonuçları

## Bulgu Özeti
| id | baslik | kategori | severity | etki | kanıt | onerilen_cozum | tahmini_efor | bagimlilik |
|---|---|---|---|---|---|---|---|---|
| UX-01 | Lokalizasyon altyapısı yok | UX/A11y | High | Çok dilli büyümede ölçeklenemezlik | `flutter_localizations`/l10n yok (`pubspec.yaml`) | ARB tabanlı localization kur | 3-5 gün | String extraction |
| UX-02 | A11y semantics sistematik değil | Erişilebilirlik | Medium | Screen reader deneyimi tutarsız | Semantics kullanımı tespit edilmedi | Kritik bileşenlere semantics labels/hints ekle | 3-4 gün | UI audit |
| UX-03 | Editor ekranı aşırı yoğun | Kullanılabilirlik | Medium | Öğrenilebilirlik ve hata riski artar | Tek ekran çok fazla aksiyon (`editor_screen.dart`) | Progressive disclosure + toolbar segmentation | 1 sprint | UX tasarım |
| UX-04 | Placeholder ikon/metinler var | Tutarlılık | Low | Profesyonellik algısı düşer | Google login icon placeholder (`login_screen.dart:202`) | Design-system ikon standardı | 1 gün | UI pack |
| UX-05 | Responsive altyapı kullanılmıyor | UX/Device | Medium | Tablet deneyimi tutarsız kalır | Responsive bileşenler tanımlı ama kullanım yok | `AdaptiveJournalView` gerçek akışa entegre et | 1 sprint | Navigation/layout refactor |

## Tasarım Sistemi Eksik Bileşenler
- Form validation state seti (error/warning/success)
- Skeleton/loading component seti
- Empty/error state pattern library
- Standardized bottom sheet/action sheet templates
- Accessibility token seti (min touch target, contrast tokens)

## Önerilen Component Envanteri
1. `AppButton` (primary/secondary/destructive/loading/disabled)
2. `AppInput` (validation + helper + icon)
3. `StatusCard` (empty/error/offline)
4. `AsyncListState` (loading/error/empty/data)
5. `EditorToolbar` atomik component’ler
6. `A11yText` ve `SemanticIconButton`

## Material/HIG Uyum Notu
- Material tarafında temel uyum iyi (AppBar, ListTile, FAB kullanımı).
- HIG tarafında izin metinleri/izin akışları eksik (kamera/foto usage description).

---

# 4) Önceliklendirilmiş Backlog (RICE + Severity)

## RICE Varsayımı
- Reach: 1-10 (etkilenen kullanıcı oranı)
- Impact: 0.5/1/2/3
- Confidence: 0-1
- Effort: kişi-hafta
- Formül: `(Reach * Impact * Confidence) / Effort`

| id | ozellik/bulgu | reach | impact | confidence | effort | rice_skor | oncelik |
|---|---|---:|---:|---:|---:|---:|---|
| BL-01 | Android release signing + hardening | 10 | 3 | 0.95 | 1 | 28.5 | P0 |
| BL-02 | Sync v2: syncUp + reconcile + oplog processing | 10 | 3 | 0.8 | 6 | 4.0 | P0 |
| BL-03 | Firestore collection/rules naming düzeltmesi | 8 | 3 | 0.9 | 1 | 21.6 | P0 |
| BL-04 | CI quality gates (analyze/test/security/build) | 10 | 2 | 0.9 | 2 | 9.0 | P0 |
| BL-05 | Widget test stabilization + timer leak fix | 8 | 2 | 0.9 | 1 | 14.4 | P1 |
| BL-06 | At-rest encryption rollout | 7 | 3 | 0.7 | 5 | 2.94 | P1 |
| BL-07 | Error model + telemetry standardization | 8 | 2 | 0.85 | 3 | 4.53 | P1 |
| BL-08 | Editor modularization (state/usecase split) | 8 | 2 | 0.8 | 5 | 2.56 | P1 |
| BL-09 | Accessibility baseline + semantics | 7 | 2 | 0.8 | 2 | 5.6 | P2 |
| BL-10 | Localization (TR/EN) altyapısı | 6 | 2 | 0.8 | 2 | 4.8 | P2 |
| BL-11 | Responsive/tablet view entegrasyonu | 5 | 1 | 0.7 | 3 | 1.17 | P3 |
| BL-12 | Dependency/security scan automation | 7 | 1 | 0.9 | 1 | 6.3 | P2 |

## Epic → Story → Task Kırılımı
1. Epic: Sync Reliability
- Story: Oplog producer devreye al
- Task: `insertOplog` çağrılarını command path’lerine bağla
- Story: Remote uploader + ack
- Task: `getPendingOplogs` işleyici yaz
- Story: Reconcile
- Task: deterministic conflict strategy + integration tests

2. Epic: Release & Security Baseline
- Story: Release signing
- Task: keystore secret pipeline
- Story: Rules consistency
- Task: collection rename + firestore rules update

3. Epic: Quality Automation
- Story: PR gates
- Task: GitHub Actions workflow dosyaları
- Story: Test health
- Task: widget timer fail fix + e2e smoke

## Bağımlılık Grafiği (Metin)
- `BL-01` bağımsız, release blocker.
- `BL-03` -> `BL-02` (sync güvenilirliği rules tutarlılığına bağlı).
- `BL-04` -> `BL-05`, `BL-12` (otomasyon çatı bağımlılığı).
- `BL-07` -> `BL-02`, `BL-08` (standardized error/telemetry).
- `BL-06` migration nedeniyle `BL-02` ile koordineli yapılmalı.

---

# 5) 12 Sprint Yol Haritası + Release Planı

## Kapasite Varsayımı
- 6+ dev squad, 2 haftalık sprint, tahmini `80-100 SP/sprint`.

## Sprint Planı
| Sprint | Tema | Hedef | User Story (özet) | Kabul Kriteri | SP | Risk | Bağımlılık |
|---|---|---|---|---|---:|---|---|
| S1 | Stabilizasyon Başlangıcı | Release blocker temizliği | Signing, rules mismatch fix | Release build debug key kullanmaz, rules test pass | 85 | CI gecikmesi | BL-01 BL-03 |
| S2 | CI Foundation | Kalite kapıları | PR analyze/test/build gate | Gate geçmeden merge yok | 90 | Build süreleri | BL-04 |
| S3 | Test Sağlığı | Kırık testlerin onarımı | Widget timer fix + smoke flows | `flutter test` stabil geçer | 80 | flaky tests | BL-05 |
| S4 | Release-1 Hazırlık | Stabil release | Crash smoke, sync temel doğrulama | Go/No-Go kriterleri sağlanır | 70 | prod config | S1-S3 |
| S5 | Sync v2 Phase-1 | Oplog producer | Local aksiyonlardan oplog üretimi | pending queue doluyor | 95 | data migration | BL-02 |
| S6 | Sync v2 Phase-2 | Uploader/Ack | pending → sent/acked akışı | retry/backoff çalışır | 100 | network edge cases | S5 |
| S7 | Sync v2 Phase-3 | Reconcile/Conflict | deterministik merge | A/B device conflict test pass | 95 | conflict policy | S6 |
| S8 | Security Hardening | Veri koruma | At-rest encryption phase-1 | yeni kurulum encrypted | 85 | migration complexity | BL-06 |
| S9 | Editor Refactor-1 | Modüler editor | state/sync ayrımı | Editor file boyutu ve complexity düşer | 90 | regresyon | BL-08 |
| S10 | Editor Refactor-2 + Telemetry | Operasyonel görünürlük | error model + perf events | kritik eventler dashboard’a akar | 90 | schema drift | BL-07 |
| S11 | UX/A11y/L10n | Erişilebilirlik ve dil | semantics + l10n altyapısı | TR/EN, basic a11y checklist pass | 80 | tasarım tutarlılığı | BL-09 BL-10 |
| S12 | Release-2 Final | Major capability release | full regression + store readiness | Release-2 go/no-go pass | 75 | scope creep | Tüm kritikler |

## Release Planı
- Release-1 (Sprint 4 sonu / Ay 2): Stabilizasyon release
- Go: Signing doğru, rules tutarlı, CI gate aktif, temel testler yeşil
- No-Go: Sync kritik hataları, test kırıkları, release key eksik
- Release-2 (Sprint 12 sonu / Ay 6): Sync v2 + güvenlik + kalite major release
- Go: Sync conflict test pass, encryption rollout tamam, regression pass
- No-Go: Data integrity riski, unresolved critical security bug

## Quality Gates (CI)
1. `flutter analyze` temiz (error/warning policy).
2. `flutter test` (unit + widget) zorunlu.
3. Security scan (secret + dependency vuln) zorunlu.
4. Release build (android appbundle, ios archive smoke) zorunlu.

## Definition of Done
- Kod + test + doküman güncel.
- Telemetry eventleri eklendi (gerekli akışlarda).
- Security checklist etkileniyorsa yeniden doğrulandı.
- PR kalite kapılarından geçti.

---

# 6) Test Stratejisi + Quality Gates

## Test Piramidi ve Coverage Hedefi
| Katman | Mevcut | Hedef 6 Ay |
|---|---|---|
| Unit | Düşük-Orta (HLC/Oplog temel) | %70+ core logic |
| Integration | Düşük | %50+ kritik servis akışları |
| UI/Widget | Çok düşük ve kırık test var | Kritik ekranlarda smoke + interaction set |
| E2E | Yok | 8-12 kritik senaryo |
| Perf/Security | Doküman var, otomasyon yok | Release öncesi zorunlu suite |

## Araç Önerileri
- Unit/Widget: `flutter_test`
- Integration/E2E: `integration_test` (+ Firebase emulator testleri)
- Perf: Flutter DevTools timeline + `--profile` scripted runs
- Security: secret scan + dependency scan + Firestore rules emulator tests

## Kritik E2E Senaryolar
1. Login → profile setup → library açılış.
2. Journal create → page edit → save → app restart persistence.
3. Offline edit → online sync → ikinci cihazda görünürlük.
4. Team invite accept/reject akışı.
5. Media ekleme (image/audio/video) + upload fallback.
6. Delete/soft-delete senaryosu ve geri yükleme beklentisi.

## Regression Planı
- Her PR: unit/widget hızlı suite.
- Gece koşusu: integration + rules suite.
- Release adayı: full e2e + perf smoke + security smoke.

---

# 7) Risk Matrisi

| risk | olasilik | etki | skor | azaltma | yedek_plan |
|---|---:|---:|---:|---|---|
| Sync v2 gecikmesi | 4 | 5 | 20 | Sprint 5-7 sadece sync odak | Release kapsam daralt |
| Encryption migration data riski | 3 | 5 | 15 | Aşamalı migration + backup | Rollback migration |
| CI gate adoption direnci | 3 | 4 | 12 | Kademeli gate + flaky quarantine | Manual gate policy |
| Firestore rules hatalı deploy | 3 | 5 | 15 | Emulator test + staged rollout | Emergency rules rollback |
| Büyük refactor regresyonu | 4 | 4 | 16 | Golden tests + feature flag | Canary release |

---

# 8) Teknik Metrikler Dashboard (Mevcut vs Hedef)

| metrik | mevcut | hedef | olcum_yontemi | notlar |
|---|---|---|---|---|
| Crash rate (30g) | Veri yok | <1% | Crashlytics | Metrik entegrasyonu gerekli |
| ANR (30g) | Veri yok | <0.5% | Play Console | Android release sonrası izleme |
| Cold start P95 | Veri yok | <2s | startup trace | cihaz matrisiyle ölç |
| Save latency p95 | Veri yok | <150ms | custom telemetry | local transaction metric |
| Sync success 24h | Veri yok | >=99% | sync events | uploader/reconcile sonrası |
| Test pass rate | Kısmi (widget test fail) | >=98% | CI reports | flaky test azaltımı |
| PR gate pass | Ölçülmüyor | >=95% | CI | gate zorunlu yapılmalı |
| Coverage (core) | Ölçülmüyor | >=70% | coverage reports | otomatik rapor üretimi |

---

# Varsayımlar & İstenen Bilgiler

## Varsayımlar
1. Kapsam yalnız iOS+Android (macOS hariç).
2. İş modeli freemium-growth odaklı.
3. Sprint kapasitesi 80-100 SP civarı (6+ dev squad).
4. Backend managed Firebase ağırlıklı; ayrı API repo erişimi yok.

## İstenen Bilgiler
1. Son 30 gün crash/anr oranları.
2. P95 API latency ve start-up ölçümleri.
3. D1/D7 retention ve conversion funnel.
4. Gerçek takım velocity geçmişi.
5. Staging/prod rule deploy geçmişi ve incident kayıtları.

---

# Ek Kanıt Notları
- `flutter analyze` sonucu: 3 adet info seviyesi issue.
- `flutter test` sonucu: `test/widget_test.dart` pending timer nedeniyle fail.
- `test/hlc_test.dart` ve `test/oplog_test.dart` tekil koşuda geçiyor.
