import AppKit
import Foundation

func generateIcon() throws {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    image.lockFocus()
    NSColor(calibratedRed: 0.66, green: 0.16, blue: 0.12, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

    let cream = NSColor(calibratedRed: 0.96, green: 0.90, blue: 0.75, alpha: 1)
    cream.withAlphaComponent(0.20).setStroke()
    for inset in [70.0, 98.0] {
        let ring = NSBezierPath(ovalIn: NSRect(x: inset, y: inset, width: 1024 - inset * 2, height: 1024 - inset * 2))
        ring.lineWidth = inset == 70 ? 8 : 2
        ring.stroke()
    }

    cream.setFill()
    for (x, y, radius) in [(195.0, 770.0, 11.0), (822.0, 742.0, 8.0), (780.0, 225.0, 12.0), (224.0, 248.0, 7.0)] {
        NSBezierPath(ovalIn: NSRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)).fill()
    }

    let text = "紫微" as NSString
    let font = NSFont(name: "PingFangSC-Semibold", size: 280) ?? NSFont.systemFont(ofSize: 280, weight: .semibold)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: cream,
        .paragraphStyle: paragraph,
        .kern: 18
    ]
    let textSize = text.size(withAttributes: attributes)
    text.draw(in: NSRect(x: 62, y: (1024 - textSize.height) / 2 - 8, width: 900, height: textSize.height), withAttributes: attributes)

    let subtitle = "ZI WEI DAILY" as NSString
    let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 38, weight: .medium),
        .foregroundColor: cream.withAlphaComponent(0.85),
        .paragraphStyle: paragraph,
        .kern: 8
    ]
    subtitle.draw(in: NSRect(x: 112, y: 230, width: 800, height: 60), withAttributes: subtitleAttributes)
    image.unlockFocus()

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: 1024,
        pixelsHigh: 1024,
        bitsPerSample: 8,
        samplesPerPixel: 3,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "IconGeneration", code: 1)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
        throw NSError(domain: "IconGeneration", code: 2)
    }
    let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
    try png.write(to: URL(fileURLWithPath: output))
}

try generateIcon()
