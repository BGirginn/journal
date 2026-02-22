# FIRESTORE_PATH_DECISION.md

## Karar
- Firestore team member collection standardi `team_members` olarak sabitlendi.
- Kod tabani ve rules bu standarda gore hizalandi.

## Gerekce
- Uygulama kodunda mevcut sorgular `team_members` kullaniyor.
- Rules tarafinda `teamMembers` kalmasi runtime authorization hatasi riski yaratiyor.
- Snake_case adlandirma mevcut veritabani tablo adlariyla da daha tutarli (`team_members`).

## Etki Analizi
- Kod tarafi: mevcut `TeamService` sorgulari degisiklik gerektirmiyor.
- Rules tarafi: `match /teamMembers/{memberId}` -> `match /team_members/{memberId}`.
- Veri tarafi: daha once `teamMembers` altina yazilmis dokumanlar varsa tek seferlik migration gerekir.

## Migration Plani
1. Rules deploy oncesi mevcut iki collection'i say:
   - `team_members`
   - `teamMembers`
2. `teamMembers` kayitlarini `team_members` altina tasiyip id'leri koru.
3. Rules deploy et.
4. Smoke:
   - takim olusturma
   - uye ekleme
   - uye listesi cekme

## Rollback
- Migration sirasinda hata olursa yazma islemlerini durdur, rules'i gecici olarak eski haline al ve kopyalama scriptini tekrar calistir.
