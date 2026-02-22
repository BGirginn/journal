# PERFORMANCE.md — Hedefler ve Profiling

## 1) Hedefler
- Editor gesture: <16ms/frame
- Ink draw: <16ms/frame
- Page open: <500ms
- Autosave: p95 <150ms DB transaction (asset hariç)

## 2) Profiling
- Flutter DevTools (frame chart)
- Android Studio profiler
- iOS Instruments

## 3) Optimizasyon Basamakları
1) RepaintBoundary doğru yerde mi?
2) Image decode cache (resize decode)
3) Text layout cache
4) Ink raster cache + incremental paint
5) Gesture sırasında outline preview
6) Z-index normalize (çok büyürse)

## 4) Büyük veri stratejisi
- Page thumbnail cache
- Journal list: sadece metadata query
- Lazy load blocks per page

## 5) Telemetry Event Seti
- `save_duration`:
  - `duration_ms`
  - `block_count`
  - `stroke_count`
- `sync_latency`:
  - `duration_ms`
  - `pending_before`
  - `acked`
  - `failed`
  - `pending_after`
- `pending_queue`:
  - `count`
- `reconcile_outcome`:
  - `applied_count`
