# UI Redesign Checklist

## Theme and Tokens
- [x] Brand color tokens added
- [x] Typography updated to Inter + Playfair(H1/H2)
- [x] ThemeData moved to explicit branded light/dark ColorScheme
- [x] Theme extensions added for semantic colors, spacing, radius, elevation

## Library Redesign
- [x] Cover-first card model applied
- [x] Live preview preserved as secondary flow
- [x] Header updated with greeting + profile/notification affordances
- [x] Empty state updated with clear CTA

## Editor Redesign
- [x] Top bar switched to translucent/solid dynamic behavior
- [x] Bottom toolbar moved to floating pill design
- [x] Core tool set exposed directly (text/image/video/audio/drawing/sticker/pen)
- [x] Selection visuals updated (glow + round handles + mint rotate handle)
- [x] Snap grid overlay added for selected block mode

## Hardcoded Color Cleanup
- [x] Theme picker updated
- [x] Cover customization dialog updated
- [x] Sticker picker updated
- [x] Drawing canvas updated
- [x] Image frame widget updated

## Validation
- [x] `dart analyze`
- [x] Affected widget tests
- [ ] Full release build matrix (run per machine/signing constraints)
