// Renders the app icon: two slim links, ink over pine, hanging top to bottom on cabin cream.
// Usage: swift scripts/make_icon.swift <out.png> [light|dark|tinted]
// Dark and tinted variants leave the background clear; the system draws its own behind them.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let variant = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "light"
let size: CGFloat = 1024

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let (upper, lower): (CGColor, CGColor) = switch variant {
case "dark": (rgb(0xF2EDE2), rgb(0x4C9670))
case "tinted": (rgb(0xFFFFFF), rgb(0x9A9A9A))
default: (rgb(0x1F2421), rgb(0x2F6B4F))
}

// The App Store icon can't have an alpha channel; the dark and tinted variants need one.
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: (variant == "light" ? CGImageAlphaInfo.noneSkipLast : .premultipliedLast).rawValue)!
if variant == "light" {
    ctx.setFillColor(rgb(0xF7F3EA))
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
}

// Each link is a stadium: `length` tall, `width` across, measured on the stroke's centerline.
let length: CGFloat = 456, width: CGFloat = 184, stroke: CGFloat = 44
let topCenter = CGPoint(x: size / 2 - 43, y: size / 2 + 118)
let bottomCenter = CGPoint(x: size / 2 + 43, y: size / 2 - 118)

func link(_ c: CGPoint) -> CGPath {
    let rect = CGRect(x: c.x - width / 2, y: c.y - length / 2, width: width, height: length)
    return CGPath(roundedRect: rect, cornerWidth: width / 2, cornerHeight: width / 2, transform: nil)
}

/// Points along a link's centerline, for finding where the two links cross.
func samples(_ c: CGPoint) -> [CGPoint] {
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

func draw(_ p: CGPath, _ color: CGColor, width w: CGFloat = stroke) {
    ctx.addPath(p)
    ctx.setLineWidth(w)
    ctx.setStrokeColor(color)
    ctx.strokePath()
}

let top = link(topCenter), bottom = link(bottomCenter)
draw(top, upper)
draw(bottom, lower)

// The links cross twice. At each crossing the strand on top gets a thin gap on either side,
// like a knot diagram: the upper link passes over at the top crossing, the lower one at the bottom.
let a = samples(topCenter), b = samples(bottomCenter)
var crossings: [CGPoint] = []
for p in a where b.contains(where: { hypot($0.x - p.x, $0.y - p.y) < 2.5 }) {
    if !crossings.contains(where: { hypot($0.x - p.x, $0.y - p.y) < 60 }) { crossings.append(p) }
}
guard crossings.count == 2 else { fatalError("expected two crossings, found \(crossings.count)") }

/// The stretch of a link's centerline within `reach` of a crossing, as an open path.
func piece(of points: [CGPoint], at p: CGPoint, reach: CGFloat) -> CGPath {
    let n = points.count
    let mid = points.indices.min { hypot(points[$0].x - p.x, points[$0].y - p.y) < hypot(points[$1].x - p.x, points[$1].y - p.y) }!
    var start = mid, end = mid, back: CGFloat = 0, ahead: CGFloat = 0
    while back < reach { let j = (start - 1 + n) % n; back += hypot(points[j].x - points[start].x, points[j].y - points[start].y); start = j }
    while ahead < reach { let j = (end + 1) % n; ahead += hypot(points[j].x - points[end].x, points[j].y - points[end].y); end = j }
    var run: [CGPoint] = [], k = start
    while true { run.append(points[k]); if k == end { break }; k = (k + 1) % n }
    let path = CGMutablePath()
    path.addLines(between: run)
    return path
}

/// Clears a thin band on each side of a strand, leaving the strand itself untouched.
func cutGap(beside strand: CGPath) {
    let band = CGMutablePath()
    band.addPath(strand.copy(strokingWithWidth: stroke * 1.8, lineCap: .butt, lineJoin: .round, miterLimit: 10))
    band.addPath(strand.copy(strokingWithWidth: stroke, lineCap: .butt, lineJoin: .round, miterLimit: 10))
    ctx.saveGState()
    if variant == "light" { ctx.setFillColor(rgb(0xF7F3EA)) } else { ctx.setBlendMode(.clear) }
    ctx.addPath(band)
    ctx.fillPath(using: .evenOdd)
    ctx.restoreGState()
}

// The lower link was drawn last, so it's already on top at the lower crossing; it only needs its gap.
cutGap(beside: piece(of: b, at: crossings.min { $0.y < $1.y }!, reach: stroke * 1.6))
// At the upper crossing the upper link goes over: cut its gap, then lay that stretch back on top.
// The stretch ends on plain link, so redrawing it leaves no seam.
let over = piece(of: a, at: crossings.max { $0.y < $1.y }!, reach: stroke * 1.6)
cutGap(beside: over)
ctx.addPath(over)
ctx.setLineWidth(stroke)
ctx.setLineCap(.butt)
ctx.setStrokeColor(upper)
ctx.strokePath()

let url = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("couldn't write \(url)") }
