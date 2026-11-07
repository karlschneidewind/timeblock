#!/usr/bin/env swift

import Foundation
import AppKit

let outputDir = "/Users/karlschneidewind/Downloads/Timeblock App/Timeblock/Assets.xcassets/AppIcon.appiconset"

func renderIcon(pixelSize: Int) -> Data? {
    let size = CGFloat(pixelSize)

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    ) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    let ctx = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext

    // Rounded background
    let cornerRadius = size * 0.225
    let bgRect = CGRect(x: 0, y: 0, width: size, height: size)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // White → very light gray gradient (top to bottom)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors: CFArray = [
        CGColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1),
        CGColor(red: 0.91, green: 0.92, blue: 0.94, alpha: 1)
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!

    cg.saveGState()
    cg.addPath(bgPath)
    cg.clip()
    cg.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: 0, y: 0),
        options: []
    )
    cg.restoreGState()

    // Timer glyph: matches SF Symbol "timer" — circle, top stem with cap, single hand
    let blue = NSColor(red: 0.20, green: 0.50, blue: 0.95, alpha: 1).cgColor
    cg.setStrokeColor(blue)
    cg.setFillColor(blue)
    cg.setLineCap(.round)
    cg.setLineJoin(.round)

    let lineWidth = max(1.5, size * 0.045)
    cg.setLineWidth(lineWidth)

    let cx = size / 2
    let cy = size * 0.46                // dial slightly below center to leave room for stem
    let dialRadius = size * 0.27

    // Outer dial
    cg.strokeEllipse(in: CGRect(
        x: cx - dialRadius, y: cy - dialRadius,
        width: dialRadius * 2, height: dialRadius * 2
    ))

    // Stem (vertical line from dial top to cap)
    let stemBottom = cy + dialRadius
    let stemTop = stemBottom + size * 0.085
    cg.move(to: CGPoint(x: cx, y: stemBottom))
    cg.addLine(to: CGPoint(x: cx, y: stemTop))
    cg.strokePath()

    // Cap (small horizontal line above stem)
    let capWidth = size * 0.11
    cg.move(to: CGPoint(x: cx - capWidth / 2, y: stemTop))
    cg.addLine(to: CGPoint(x: cx + capWidth / 2, y: stemTop))
    cg.strokePath()

    // Single clock hand pointing up-right (~2 o'clock)
    let handLength = dialRadius * 0.62
    let angle: CGFloat = .pi / 4  // 45° from horizontal
    cg.move(to: CGPoint(x: cx, y: cy))
    cg.addLine(to: CGPoint(
        x: cx + handLength * cos(angle),
        y: cy + handLength * sin(angle)
    ))
    cg.strokePath()

    return bitmap.representation(using: .png, properties: [:])
}

let icons: [(pixelSize: Int, filename: String)] = [
    (16,   "icon_16.png"),
    (32,   "icon_16@2x.png"),
    (32,   "icon_32.png"),
    (64,   "icon_32@2x.png"),
    (128,  "icon_128.png"),
    (256,  "icon_128@2x.png"),
    (256,  "icon_256.png"),
    (512,  "icon_256@2x.png"),
    (512,  "icon_512.png"),
    (1024, "icon_512@2x.png"),
]

for icon in icons {
    guard let data = renderIcon(pixelSize: icon.pixelSize) else {
        print("Failed to render \(icon.filename)")
        continue
    }
    let path = "\(outputDir)/\(icon.filename)"
    do {
        try data.write(to: URL(fileURLWithPath: path))
        print("Wrote \(icon.filename) (\(icon.pixelSize)×\(icon.pixelSize))")
    } catch {
        print("Failed to write \(icon.filename): \(error)")
    }
}

// Update Contents.json
let contentsPath = "\(outputDir)/Contents.json"
let contents = """
{
  "images" : [
    { "idiom" : "mac", "scale" : "1x", "size" : "16x16",   "filename" : "icon_16.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "16x16",   "filename" : "icon_16@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "32x32",   "filename" : "icon_32.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "32x32",   "filename" : "icon_32@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "128x128", "filename" : "icon_128.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "128x128", "filename" : "icon_128@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "256x256", "filename" : "icon_256.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "256x256", "filename" : "icon_256@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "512x512", "filename" : "icon_512.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "512x512", "filename" : "icon_512@2x.png" }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

"""
do {
    try contents.write(toFile: contentsPath, atomically: true, encoding: .utf8)
    print("Updated Contents.json")
} catch {
    print("Failed to write Contents.json: \(error)")
}
