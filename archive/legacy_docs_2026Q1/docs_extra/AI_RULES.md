# AI_RULES.md — LLM ile Çalışma Kuralları (Repo Anayasası)

## Amaç
LLM çıktısı “taslak”tır. Repoya giren her şey test edilebilir ve ölçülebilir olmalıdır.

## Kurallar
1) Editor Engine değişiklikleri:
   - Hit-test, transform, render cache değişiyorsa mutlaka:
     - unit test + perf notu
2) Sync değişiklikleri:
   - Oplog formatı değişiyorsa:
     - version bump + migration planı
3) DB değişiklikleri:
   - Drift migration script yazılmadan merge yok
4) Güvenlik/gizlilik:
   - Telemetry’ye içerik eklemek yasak
5) “Güzel görünsün” diye performans feda etmek yasak:
   - animasyon eklenirse frame time ölçümü zorunlu
6) Kod kopyala-yapıştır:
   - Her yeni modül için “neden bu şekilde” açıklaması docs’a eklenir
7) MVP kapsamı:
   - MVP dışı feature eklemek yasak (Backlog’a yazılır)

## Çıktı Formatı
LLM’den istenen her şey:
- Dosya adı
- Patch/diff veya tam içerik
- Test planı
- Edge-case listesi
