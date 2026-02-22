# RELEASE_GO_NO_GO.md

## Release-1 Go/No-Go Checklist

### Go Kriterleri
- [ ] Release signing guvenli ve dogrulandi
- [ ] Firestore rules path mismatch kapatildi (`team_members`)
- [ ] PR quality gate'ler yesil (`Format Check`, `Analyze`, `Test`)
- [ ] `flutter test` kritik smoke senaryolari geciyor
- [ ] Release candidate build artifact olustu

### No-Go Kriterleri
- [ ] P0 guvenlik acigi acik
- [ ] Sync tarafinda data integrity riski var
- [ ] Kritik test suite kirik
- [ ] Rollback/hotfix akisi dogrulanmadi

## Karar Toplantisi Ciktisi
- Tarih:
- Karar:
- Katilimcilar:
- Acik riskler:
- Aksiyonlar:

## Release Retrospective Template
1. Neler iyi gitti?
2. Neler release'i yavaslatti?
3. Tespit edilen riskler nasil erken yakalanabilirdi?
4. Sonraki release icin en az 2 aksiyon:
