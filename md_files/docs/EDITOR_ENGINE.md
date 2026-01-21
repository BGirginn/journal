# EDITOR_ENGINE.md — Hit-test, Transform, Render, Gesture

## 1) Modlar
- View Mode: sayfa çevirme açık (JournalView)
- Edit Mode: sayfa çevirme kapalı; block etkileşimi açık
- Pen Mode: ink çizimi açık; block selection kapalı veya long-press ile

## 2) Hit-test
Sıra:
1) z_index DESC
2) AABB (axis-aligned bbox) hızlı test
3) OBB (rotated rect) kesin test
4) tolerance: 8–12px

Seçim:
- İlk eşleşen block seçilir.
- Boş alana dokunma: selection clear.

## 3) Transform Matematiği
### Move
- Drag delta viewport → page px → normalize
- clamp: x,y ∈ [0..1], w,h korunur (block page dışına taşabilir mi? MVP: kısmen izin; min %10 içeride kalsın)

### Resize
- Handles: NW/NE/SW/SE
- min size: minW=0.06, minH=0.06
- rotation varsa: delta local coords’ta uygulanır
- anchor: karşı köşe sabit

### Rotate
- center C
- angleDeg = atan2(p - C)*180/pi
- rotationDeg = angleDeg - initialOffset
- snap: v1.1+ (15°)

## 4) Gesture Arbitration
Öncelik:
1) Resize handle
2) Rotate handle
3) Block drag
4) (Edit mode dışı) Page swipe
5) Pen mode: ink draw

Kural:
- Selected block varken sayfa swipe devre dışı veya threshold yüksek.

## 5) Z-Index
- CreateBlock → maxZ+1
- BringToFront → maxZ+1
- SendToBack → minZ-1, sonra normalize (zIndex rebalance) (v1.1+)

## 6) Undo/Redo
- Command pattern
- Coalescing: drag/resize/rotate gesture end’de tek komut

Komutlar:
- AddBlock, DeleteBlock
- MoveBlock, ResizeBlock, RotateBlock
- UpdatePayload (text, caption)
- ReorderZ

## 7) Autosave
- Dirty flag
- Debounce 1500ms
- Gesture end → immediate flush opsiyon
- UI: Kaydediliyor… / Kaydedildi

## 8) Render Pipeline
### Baseline
- ZIndex’e göre çiz
- Image: decode cache
- Text: paragraph cache
- Ink: bitmap cache

### Gesture sırasında
- Selected block: outline preview (low quality)
- Gesture end: full render

## 9) Ink (Handwriting)
- Ink block = “drawing surface” block
- Veri: ink.bin (binary)
- Çizim: incremental append + raster cache
- Eraser: MVP “clear ink block”; v1.1 stroke delete

## 10) Page Thumbnail
- Page değişince thumbnail invalidate
- Background job: thumbnail render → assets(kind=thumb)
