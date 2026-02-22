# ROLLBACK_HOTFIX.md

## Hedef
Release sonrasi kritik problemde uygulamayi hizli ve kontrollu sekilde geri almak.

## Rollback Tetikleyicileri
- P0 crash spike
- Data corruption sinyali
- Security incident
- Kritik login/sync akisinin calismamasi

## Rollback Akisi
1. Incident owner atanir.
2. Etkilenen surum tespit edilir.
3. Store rollout durdurulur.
4. Son stabil surume rollback karari alinip yayinlanir.
5. Kullanici etkisi ve status guncellemesi paylasilir.

## Hotfix Akisi
1. `hotfix/*` branch ac.
2. Minimum degisiklik ile fix uygula.
3. `flutter analyze` + `flutter test` + release candidate build al.
4. GO onayi ile tag'le ve dagit.
5. Postmortem ve kalici iyilestirme backlog'a ekle.

## Prova (Release oncesi zorunlu)
- [ ] Rollback dry-run tamamlandi
- [ ] Hotfix dry-run tamamlandi
- [ ] Sorumlular ve iletisim kanali net
