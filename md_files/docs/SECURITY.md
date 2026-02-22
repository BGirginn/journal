# SECURITY.md — Threat Model + Kontroller

## 1) Tehdit Modeli (Kısa)
- Cihaz kaybı/çalınması
- Omuz sörfü / screenshot
- Hesap ele geçirilmesi
- Cloud verisi sızıntısı
- Sync conflict ile veri kaybı

## 2) Kontroller
### 2.1 App Lock (v1.1)
- PIN/Biometric
- iOS: secure screen, Android: FLAG_SECURE (screenshot engeli)

### 2.2 Encryption-at-rest (v1.2+)
- DB: SQLCipher
- Asset: AES-GCM (opsiyon)
- Key: Keychain/Keystore
- Faz-1 notu: iOS permission compliance + CI security scanning aktif.

### 2.3 Firebase Security Rules
- userId scope:
  - /users/{uid}/... sadece uid erişir
- Group future: roles-based
- team uyumu:
  - `team_members` collection standardi

### 2.4 Sync Safety
- tombstone rule
- applied watermark
- retry/backoff

## 3) Incident Response
- kullanıcı “hesabım çalındı”: token revoke (Firebase)
- cihaz kaybı: remote sign-out önerisi

## 4) CI Security Gates
- Workflow: `.github/workflows/security_scan.yml`
- Secret scan: Gitleaks
- Dependency scan: Trivy (HIGH/CRITICAL bulguda fail)

## 5) iOS Permission Compliance
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- `NSMicrophoneUsageDescription`
