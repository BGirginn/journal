# Android Editor Smoke Test

## Build Artifact
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Install:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Scope
- Image block selection/deselection
- Image drag/move interaction
- Frame styles (especially `polaroid` and `tape`)
- Page pinch zoom in/out and reset behavior

## Preconditions
1. App installed from latest APK.
2. Existing journal with at least one page.
3. Editor can add image blocks from gallery/camera.

## Test Cases
1. Open any page in Editor.
Expected: Canvas and toolbar load without lag or freeze.

2. Add a new image block.
Expected: Image appears once; block is selectable.

3. Tap image once.
Expected: Block becomes selected (outline/handles visible).

4. Tap same selected image once again.
Expected: Selection clears immediately (normal mode returns in one tap).

5. Select image and drag it across page.
Expected: Block follows finger smoothly; position updates correctly.

6. While image selected, pinch on empty page area.
Expected: Image selection is cleared and page zoom starts.

7. Pinch zoom in/out on page (no block selected).
Expected: Zoom responds consistently; no need for repeated taps to recover control.

8. Double tap empty area.
Expected: Page zoom resets to 1x.

9. Select image -> open frame picker -> choose `Polaroid`.
Expected: Polaroid frame appears immediately on canvas.

10. Select image -> choose `Tape`.
Expected: Tape frame appears immediately on canvas.

11. Save page, exit editor, reopen same page.
Expected: Selected frame style persists (Polaroid/Tape still visible).

12. Optional regression: draw/erase quick stroke and save.
Expected: No regression in draw/erase/save flow.

## Pass Criteria
- All expected results succeed on physical Android device.
- No crashes, no stuck gesture state, no visual frame loss after reopen.

