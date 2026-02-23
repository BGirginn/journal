# Design System V2

## Brand Direction
Modern Editorial + subtle analog texture.

## Color Tokens
- Primary 900: `#1F2240`
- Primary 800: `#2C2F63`
- Primary 700: `#3A3ECF`
- Primary 600: `#4C4FF6`
- Primary 500: `#6366FF`
- Warm Accent: `#FFB84D`
- Soft Mint: `#5CC8A1`
- Muted Rose: `#E38CA7`

## Surface Tokens
### Light
- Background: `#F7F8FC`
- Card: `#FFFFFF`
- Elevated: `#FFFFFF`
- Divider: `#E8EAF2`

### Dark
- Background: `#0F1117`
- Card: `#1A1D26`
- Elevated: `#222534`
- Divider: `#2A2E3D`

## Typography
- Base font: Inter
- Editorial accent: Playfair Display (H1/H2 only)
- Type scale:
  - H1: 28 / 600
  - H2: 22 / 600
  - H3: 18 / 600
  - Body Large: 16 / 500
  - Body: 14 / 400
  - Caption: 12 / 400

## Spacing and Radius
- Spacing scale: 4, 8, 12, 16, 24, 32, 48, 64
- Radius scale: 8, 16, 24, 32

## Elevation
- Card: `0 8 30 rgba(0,0,0,0.06)`
- Floating tool: `0 12 40 rgba(0,0,0,0.12)`

## Theme Extensions
- `JournalSemanticColors`
- `JournalSpacingScale`
- `JournalRadiusScale`
- `JournalElevationScale`

## UI Rules
- Only light/dark modes are supported.
- CTA uses Primary 600, hover/focus uses Primary 700.
- New UI colors must come from token/theme extensions.
