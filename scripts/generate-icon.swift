import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: generate-icon <output.png>\n", stderr)
    exit(2)
}

let pixels = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixels,
    pixelsHigh: pixels,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Could not create icon bitmap.\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()

let backgroundRect = NSRect(x: 64, y: 64, width: 896, height: 896)
let background = NSBezierPath(roundedRect: backgroundRect, xRadius: 210, yRadius: 210)
let gradient = NSGradient(
    starting: NSColor(red: 0.10, green: 0.07, blue: 0.28, alpha: 1),
    ending: NSColor(red: 0.04, green: 0.38, blue: 0.48, alpha: 1)
)!
gradient.draw(in: background, angle: -45)

// Split traffic lanes: the center gap suggests traffic manipulation/bypass.
let laneColor = NSColor(red: 0.25, green: 0.92, blue: 0.82, alpha: 0.82)
laneColor.setStroke()
for y in [310.0, 512.0, 714.0] {
    let left = NSBezierPath()
    left.lineWidth = 34
    left.lineCapStyle = .round
    left.move(to: NSPoint(x: 170, y: y))
    left.line(to: NSPoint(x: 365, y: y))
    left.stroke()

    let right = NSBezierPath()
    right.lineWidth = 34
    right.lineCapStyle = .round
    right.move(to: NSPoint(x: 659, y: y))
    right.line(to: NSPoint(x: 854, y: y))
    right.stroke()
}

// A bold Z gives the utility its own recognizable mark at small sizes.
let mark = NSBezierPath()
mark.move(to: NSPoint(x: 306, y: 770))
mark.line(to: NSPoint(x: 734, y: 770))
mark.line(to: NSPoint(x: 734, y: 660))
mark.line(to: NSPoint(x: 440, y: 354))
mark.line(to: NSPoint(x: 734, y: 354))
mark.line(to: NSPoint(x: 734, y: 244))
mark.line(to: NSPoint(x: 290, y: 244))
mark.line(to: NSPoint(x: 290, y: 354))
mark.line(to: NSPoint(x: 584, y: 660))
mark.line(to: NSPoint(x: 306, y: 660))
mark.close()
NSColor.white.setFill()
mark.fill()

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not encode icon PNG.\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
