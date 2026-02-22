# ANDROID_SIGNING.md

## Local Gelistirme
1. `key.properties.example` dosyasini `key.properties` olarak kopyala.
2. Asagidaki alanlari doldur:
   - `storeFile`
   - `storePassword`
   - `keyAlias`
   - `keyPassword`
3. `flutter build appbundle --release` calistir.

## CI Konfig
- `RELEASE_STORE_FILE`
- `RELEASE_STORE_PASSWORD`
- `RELEASE_KEY_ALIAS`
- `RELEASE_KEY_PASSWORD`

Not:
- Keystore dosyasini CI tarafinda base64 secret olarak tutup runtime'da dosyaya acmak tercih edilir.
- Release task'leri signing bilgisi yoksa fail-fast olacak sekilde konfigure edilmistir.
