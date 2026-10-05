import AppKit

// Original gksdud character badge. Copyright 2026 CodingNoye (MIT).
enum DudIcon {
    static func drawFace(in context: CGContext, korean: Bool = false) {
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(18)
        for centerX: CGFloat in [157.6, 354.4] {
            let eye = CGMutablePath()
            if korean {
                // Two horizontal strokes and a circle form each ㅎ eye.
                eye.move(to: CGPoint(x: centerX - 14, y: 190))
                eye.addLine(to: CGPoint(x: centerX + 14, y: 190))
                eye.move(to: CGPoint(x: centerX - 42, y: 218))
                eye.addLine(to: CGPoint(x: centerX + 42, y: 218))
                eye.addEllipse(in: CGRect(x: centerX - 38, y: 244.2, width: 76, height: 76))
            } else {
                eye.move(to: CGPoint(x: centerX + 48, y: 185.8))
                eye.addLine(to: CGPoint(x: centerX + 48, y: 272.2))
                eye.addArc(center: CGPoint(x: centerX, y: 272.2), radius: 48,
                    startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            }
            context.addPath(eye)
            context.strokePath()
        }
        let mouth = CGMutablePath()
        mouth.move(to: CGPoint(x: 232, y: 285.4))
        mouth.addLine(to: CGPoint(x: 232, y: 302.2))
        mouth.addArc(center: CGPoint(x: 256, y: 302.2), radius: 24,
            startAngle: .pi, endAngle: 0, clockwise: true)
        mouth.addLine(to: CGPoint(x: 280, y: 285.4))
        context.setLineWidth(16)
        context.addPath(mouth)
        context.strokePath()
    }

    static func badge(korean: Bool) -> NSImage {
        let filled = korean
        let image = NSImage(size: NSSize(width: 22, height: 20), flipped: false) { rect in
            let shape = NSBezierPath(roundedRect: rect.insetBy(dx: 0.75, dy: 1.25), xRadius: 3, yRadius: 3)
            NSColor.black.set()
            if filled { shape.fill() } else { shape.lineWidth = 0.8; shape.stroke() }
            let face = NSImage(size: rect.size, flipped: false) { bounds in
                guard let context = NSGraphicsContext.current?.cgContext else { return false }
                context.saveGState()
                context.translateBy(x: bounds.midX, y: bounds.midY)
                let scale: CGFloat = 16.5 / 310.8
                context.scaleBy(x: scale, y: -scale)
                context.translateBy(x: -256, y: -255.5)
                context.setStrokeColor(NSColor.black.cgColor)
                drawFace(in: context, korean: korean)
                context.restoreGState()
                return true
            }
            // Transparent cutout lets macOS tint the complete template in light/dark menus.
            face.draw(in: rect, from: .zero, operation: filled ? .destinationOut : .sourceOver, fraction: 1)
            return true
        }
        image.isTemplate = true
        return image
    }
}
