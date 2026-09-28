// Renders the app icon: two interlocking chain links on cabin cream.
// Usage: swift scripts/make_icon.swift <out.png> [light|dark|tinted]
// Dark and tinted variants leave the background clear; the system draws its own behind them.
import AppKit

let variant = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "light"

let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let (backColor, frontColor): (CGColor, CGColor) = switch variant {
case "dark": (rgb(0xF2EDE2), rgb(0x4C9670))
case "tinted": (rgb(0xFFFFFF), rgb(0x9A9A9A))
default: (rgb(0x1F2421), rgb(0x2F6B4F))
}

if variant == "light" {
    ctx.setFillColor(rgb(0xF7F3EA))
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
}

ctx.translateBy(x: 512, y: 512)
ctx.rotate(by: 20 * .pi / 180)

let w: CGFloat = 470, h: CGFloat = 270, line: CGFloat = 78
func link(_ dx: CGFloat, _ dy: CGFloat) -> CGPath {
    let r = CGRect(x: dx - w / 2, y: dy - h / 2, width: w, height: h)
    return CGPath(roundedRect: r, cornerWidth: h / 2, cornerHeight: h / 2, transform: nil)
}
let left = link(-145, 55)
let right = link(145, -55)

ctx.setLineWidth(line)
ctx.setStrokeColor(backColor); ctx.addPath(left); ctx.strokePath()
ctx.setStrokeColor(frontColor); ctx.addPath(right); ctx.strokePath()
// Re-draw the left link over the right on its lower crossing so they interlock.
ctx.saveGState()
ctx.rotate(by: -20 * .pi / 180)
ctx.translateBy(x: -512, y: -512)
ctx.clip(to: CGRect(x: 470, y: 540, width: 190, height: 160)) // upper crossing, in image space
ctx.translateBy(x: 512, y: 512)
ctx.rotate(by: 20 * .pi / 180)
ctx.setStrokeColor(backColor); ctx.addPath(left); ctx.strokePath()
ctx.restoreGState()

NSGraphicsContext.current = nil
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
