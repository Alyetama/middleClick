import AppKit

// Renders a 1024x1024 app icon: gradient squircle + white cursor-click glyph.
let size = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let rect = NSRect(x: 0, y: 0, width: size, height: size)

// Rounded squircle background with a diagonal gradient.
let bg = NSBezierPath(roundedRect: rect, xRadius: 224, yRadius: 224)
bg.addClip()
let grad = NSGradient(colors: [
    NSColor(calibratedRed: 0.42, green: 0.58, blue: 0.98, alpha: 1),
    NSColor(calibratedRed: 0.30, green: 0.30, blue: 0.86, alpha: 1),
])!
grad.draw(in: rect, angle: -60)

// White cursor-click glyph, centered.
let cfg = NSImage.SymbolConfiguration(pointSize: 560, weight: .semibold)
if let base = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: nil)?
    .withSymbolConfiguration(cfg) {
    let glyph = base.copy() as! NSImage
    glyph.lockFocus()
    NSColor.white.set()
    NSRect(origin: .zero, size: glyph.size).fill(using: .sourceAtop)
    glyph.unlockFocus()

    let gs = glyph.size
    let origin = NSPoint(x: (CGFloat(size) - gs.width) / 2,
                         y: (CGFloat(size) - gs.height) / 2)
    glyph.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
}

NSGraphicsContext.restoreGraphicsState()

let out = URL(fileURLWithPath: "icon_1024.png")
try! rep.representation(using: .png, properties: [:])!.write(to: out)
print("wrote \(out.path)")
