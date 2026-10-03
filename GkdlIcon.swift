import AppKit

// Native vector/text artwork; rendered at each icon size, no bitmap dependency.
enum GkdlIcon {
    static func drawAppIcon(in context: CGContext) {
        context.saveGState()
        context.setFillColor(NSColor(srgbRed: 0.14, green: 0.32, blue: 0.88, alpha: 1).cgColor)
        context.addPath(CGPath(roundedRect: CGRect(x: 32, y: 32, width: 448, height: 448),
            cornerWidth: 100, cornerHeight: 100, transform: nil))
        context.fillPath()
        let title = NSAttributedString(string: "하이", attributes: [
            .font: NSFont.systemFont(ofSize: 174, weight: .bold), .foregroundColor: NSColor.white,
            .kern: -9
        ])
        let size = title.size()
        title.draw(at: NSPoint(x: (512 - size.width) / 2, y: (512 - size.height) / 2 + 8))
        context.restoreGState()
    }

    static func badge(korean: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 22, height: 20), flipped: false) { rect in
            let shape = NSBezierPath(roundedRect: rect.insetBy(dx: 0.75, dy: 1.25), xRadius: 3, yRadius: 3)
            NSColor.black.set()
            if korean { shape.fill() } else { shape.lineWidth = 0.8; shape.stroke() }
            let label = NSImage(size: rect.size, flipped: false) { bounds in
                let text = NSAttributedString(string: korean ? "하" : "hi", attributes: [
                    .font: NSFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: NSColor.black
                ])
                let size = text.size()
                text.draw(at: NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2))
                return true
            }
            label.draw(in: rect, from: .zero, operation: korean ? .destinationOut : .sourceOver, fraction: 1)
            return true
        }
        image.isTemplate = true
        return image
    }
}

// The build compiles this entry point only for the iconset generator.
#if ICON_GENERATOR
@main
struct IconGenerator {
    static func main() throws {
        let destination = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        for points in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let pixels = points * scale
                let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
                let context = NSGraphicsContext.current!.cgContext
                context.scaleBy(x: CGFloat(pixels) / 512, y: CGFloat(pixels) / 512)
                GkdlIcon.drawAppIcon(in: context)
                NSGraphicsContext.restoreGraphicsState()
                let suffix = scale == 2 ? "@2x" : ""
                try bitmap.representation(using: .png, properties: [:])!.write(to:
                    destination.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
            }
        }
    }
}
#endif
