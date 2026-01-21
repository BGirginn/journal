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

### 2.3 Firebase Security Rules
- userId scope:
  - /users/{uid}/... sadece uid erişir
- Group future: roles-based

### 2.4 Sync Safety
- tombstone rule
- applied watermark
- retry/backoff

## 3) Incident Response
- kullanıcı “hesabım çalındı”: token revoke (Firebase)
- cihaz kaybı: remote sign-out önerisi
