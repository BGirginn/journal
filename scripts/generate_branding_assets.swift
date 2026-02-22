import AppKit
import Foundation

enum BadgeStyle {
  case appIcon
  case symbol
}

func gradient(_ colors: [NSColor], rect: NSRect, angle: CGFloat) {
  let g = NSGradient(colors: colors)!
  g.draw(in: rect, angle: angle)
}

func drawFlourish(in rect: NSRect, color: NSColor, width: CGFloat) {
  color.setStroke()
  let path = NSBezierPath()
  path.lineWidth = width

  let midY = rect.midY
  let left = rect.minX + rect.width * 0.16
  let right = rect.maxX - rect.width * 0.16

  path.move(to: NSPoint(x: left, y: midY + rect.height * 0.22))
  path.curve(
    to: NSPoint(x: right, y: midY + rect.height * 0.22),
    controlPoint1: NSPoint(x: rect.midX - rect.width * 0.2, y: rect.maxY),
    controlPoint2: NSPoint(x: rect.midX + rect.width * 0.2, y: rect.minY)
  )
  path.stroke()
}

func drawMonogram(in rect: NSRect, dark: Bool) {
  let border = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.19, yRadius: rect.width * 0.19)
  border.lineWidth = rect.width * 0.04
  NSColor(calibratedRed: 0.93, green: 0.78, blue: 0.42, alpha: 1).setStroke()
  border.stroke()

  let letter = "J"
  let font = NSFont(name: "Didot-Bold", size: rect.width * 0.58) ?? NSFont.boldSystemFont(ofSize: rect.width * 0.58)
  let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: dark
      ? NSColor(calibratedRed: 0.99, green: 0.93, blue: 0.84, alpha: 1)
      : NSColor(calibratedRed: 0.32, green: 0.20, blue: 0.08, alpha: 1)
  ]
  let size = letter.size(withAttributes: attrs)
  let origin = NSPoint(
    x: rect.midX - size.width / 2,
    y: rect.midY - size.height / 2 - rect.height * 0.03
  )
  letter.draw(at: origin, withAttributes: attrs)

  drawFlourish(
    in: rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.04),
    color: NSColor(calibratedRed: 0.93, green: 0.78, blue: 0.42, alpha: 0.9),
    width: rect.width * 0.015
  )
}

func makeImage(size: CGFloat, dark: Bool, style: BadgeStyle) -> NSImage {
  let image = NSImage(size: NSSize(width: size, height: size))
  image.lockFocus()
  defer { image.unlockFocus() }

  let canvas = NSRect(x: 0, y: 0, width: size, height: size)

  switch style {
  case .appIcon:
    gradient(
      dark
        ? [
            NSColor(calibratedRed: 0.22, green: 0.16, blue: 0.12, alpha: 1),
            NSColor(calibratedRed: 0.36, green: 0.22, blue: 0.12, alpha: 1),
          ]
        : [
            NSColor(calibratedRed: 1.0, green: 0.94, blue: 0.84, alpha: 1),
            NSColor(calibratedRed: 0.93, green: 0.70, blue: 0.43, alpha: 1),
          ],
      rect: canvas,
      angle: -28
    )

  case .symbol:
    NSColor.clear.setFill()
    canvas.fill()
  }

  let monogramRect = canvas.insetBy(dx: size * 0.14, dy: size * 0.14)

  if style == .appIcon {
    let fillPath = NSBezierPath(roundedRect: monogramRect, xRadius: monogramRect.width * 0.19, yRadius: monogramRect.width * 0.19)
    let fillColor = dark
      ? NSColor(calibratedRed: 0.18, green: 0.14, blue: 0.11, alpha: 0.95)
      : NSColor(calibratedRed: 0.20, green: 0.14, blue: 0.09, alpha: 0.88)
    fillColor.setFill()
    fillPath.fill()
  }

  drawMonogram(in: monogramRect, dark: dark)
  return image
}

func writePNG(_ image: NSImage, to path: String) throws {
  guard
    let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let data = rep.representation(using: .png, properties: [:])
  else {
    throw NSError(domain: "Branding", code: 1)
  }
  try data.write(to: URL(fileURLWithPath: path), options: .atomic)
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outDir = root.appendingPathComponent("assets/branding", isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let outputs: [(String, CGFloat, Bool, BadgeStyle)] = [
  ("icon_vintage_gold.png", 1024, false, .appIcon),
  ("icon_foreground.png", 1024, false, .symbol),
  ("splash_logo.png", 1024, false, .symbol),
  ("splash_logo_dark.png", 1024, true, .symbol),
  ("splash_android12.png", 960, false, .symbol),
  ("splash_android12_dark.png", 960, true, .symbol),
]

for (name, size, dark, style) in outputs {
  let path = outDir.appendingPathComponent(name).path
  try writePNG(makeImage(size: size, dark: dark, style: style), to: path)
  print("wrote \(name)")
}
