// Renders the app icon: two slim interlocking links, gold over cream, hanging top to bottom on pine.
// Usage: swift scripts/make_icon.swift <out.png> [light|dark|tinted]
// Dark and tinted variants leave the background clear; the system draws its own behind them.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let variant = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "light"
let size: CGFloat = 1024

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

// Top-to-bottom gradients for each link.
let (upper, lower): ((UInt32, UInt32), (UInt32, UInt32)) = switch variant {
case "tinted": ((0xA6A6A6, 0x8C8C8C), (0xFFFFFF, 0xE8E8E8))
default: ((0xF2C25A, 0xD69A2B), (0xFFFDF8, 0xE6DDC9))
}

// The App Store icon can't have an alpha channel; the dark and tinted variants need one.
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: (variant == "light" ? CGImageAlphaInfo.noneSkipLast : .premultipliedLast).rawValue)!

func gradient(_ colors: (UInt32, UInt32)) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [rgb(colors.0), rgb(colors.1)] as CFArray, locations: [0, 1])!
}

if variant == "light" {
    ctx.drawLinearGradient(gradient((0x3B8060, 0x1F4C37)), start: CGPoint(x: 0, y: size), end: .zero, options: [])
}

// Each link is a stadium: `length` long, `width` across, measured on the stroke's centerline.
let length: CGFloat = 490, width: CGFloat = 214, stroke: CGFloat = 54

/// Points along a vertical link's centerline, clockwise from the top of its right side.
func link(center c: CGPoint) -> [CGPoint] {
    let r = width / 2, half = length / 2 - r, n = 1600
    let perimeter = 4 * half + 2 * .pi * r
    return (0..<n).map { k in
        var s = CGFloat(k) / CGFloat(n) * perimeter
        if s < 2 * half { return CGPoint(x: c.x + r, y: c.y + half - s) }
        s -= 2 * half
        if s < .pi * r { let a = -s / r; return CGPoint(x: c.x + r * cos(a), y: c.y - half + r * sin(a)) }
        s -= .pi * r
        if s < 2 * half { return CGPoint(x: c.x - r, y: c.y - half + s) }
        s -= 2 * half
        let a = .pi - s / r
        return CGPoint(x: c.x + r * cos(a), y: c.y + half + r * sin(a))
    }
}

func path(_ points: [CGPoint]) -> CGPath {
    let p = CGMutablePath()
    p.addLines(between: points)
    p.closeSubpath()
    return p
}

/// Fills the stroke of `p` with a top-to-bottom gradient.
func draw(_ p: CGPath, _ colors: (UInt32, UInt32)) {
    ctx.saveGState()
    ctx.addPath(p)
    ctx.setLineWidth(stroke)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    ctx.drawLinearGradient(gradient(colors), start: CGPoint(x: 0, y: size), end: .zero, options: [])
    ctx.restoreGState()
}

func clip(toStrokeOf p: CGPath) {
    ctx.addPath(p)
    ctx.setLineWidth(stroke)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
}

// The upper link sits a little left, the lower a little right, overlapping by about a link's width.
let top = link(center: CGPoint(x: size / 2 - 46, y: size / 2 + 128))
let bottom = link(center: CGPoint(x: size / 2 + 46, y: size / 2 - 128))
let topPath = path(top), bottomPath = path(bottom)

// On the light icon, a soft shadow lifts both links off the background.
if variant == "light" {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 36, color: rgb(0x0B2418, 0.35))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
}
draw(topPath, upper)
draw(bottomPath, lower)
if variant == "light" {
    ctx.endTransparencyLayer()
    ctx.restoreGState()
}

// The links cross twice. The lower link stays on top at one crossing; the upper goes over at the other.
var crossings: [CGPoint] = []
for p in top where bottom.contains(where: { hypot($0.x - p.x, $0.y - p.y) < 2.5 }) {
    if !crossings.contains(where: { hypot($0.x - p.x, $0.y - p.y) < 60 }) { crossings.append(p) }
}
guard crossings.count == 2 else { fatalError("expected two crossings, found \(crossings.count)") }
let over = crossings.max { $0.y < $1.y }!
let zone = CGRect(x: over.x - stroke * 1.4, y: over.y - stroke * 1.4, width: stroke * 2.8, height: stroke * 2.8)

ctx.saveGState()
ctx.addEllipse(in: zone)
ctx.clip()
// Shadow from the strand on top, falling only on the strand beneath it.
ctx.saveGState()
clip(toStrokeOf: bottomPath)
ctx.setShadow(offset: CGSize(width: 0, height: -stroke * 0.12), blur: stroke * 0.45, color: rgb(0x000000, 0.45))
ctx.addPath(topPath)
ctx.setLineWidth(stroke)
ctx.setStrokeColor(rgb(upper.1))
ctx.strokePath()
ctx.restoreGState()
draw(topPath, upper)
ctx.restoreGState()

let other = crossings.min { $0.y < $1.y }!
let underZone = CGRect(x: other.x - stroke * 1.4, y: other.y - stroke * 1.4, width: stroke * 2.8, height: stroke * 2.8)
ctx.saveGState()
ctx.addEllipse(in: underZone)
ctx.clip()
ctx.saveGState()
clip(toStrokeOf: topPath)
ctx.setShadow(offset: CGSize(width: 0, height: -stroke * 0.12), blur: stroke * 0.45, color: rgb(0x000000, 0.45))
ctx.addPath(bottomPath)
ctx.setLineWidth(stroke)
ctx.setStrokeColor(rgb(lower.1))
ctx.strokePath()
ctx.restoreGState()
draw(bottomPath, lower)
ctx.restoreGState()

let url = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("couldn't write \(url)") }
