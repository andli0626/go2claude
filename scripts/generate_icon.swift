#!/usr/bin/env swift
// 生成 Go2Claude 应用图标
// 使用 Claude 主题色：紫色渐变

import Foundation
import CoreGraphics
import ImageIO
import CoreText
import UniformTypeIdentifiers

// 图标尺寸配置
let iconSizes: [(size: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

// 创建 CGColor 的辅助函数
func makeColor(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> CGColor {
    return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [r, g, b, a])!
}

// Claude 主题色 (sRGB)
let claudePurple = makeColor(r: 0.42, g: 0.16, b: 0.90, a: 1.0)  // #6B2DE6
let claudePurpleLight = makeColor(r: 0.62, g: 0.35, b: 1.0, a: 1.0)
let claudePurpleDark = makeColor(r: 0.25, g: 0.08, b: 0.65, a: 1.0)
let white = makeColor(r: 1.0, g: 1.0, b: 1.0, a: 1.0)

func generateIcon(size: Int, scale: Int) -> CGImage? {
    let pixelSize = size * scale
    let context = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )

    guard let ctx = context else { return nil }

    let rect = CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize)

    // 绘制圆角矩形背景（macOS 图标风格）
    let cornerRadius = CGFloat(pixelSize) * 0.22
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // 渐变背景
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()

    let gradientColors = [claudePurpleDark, claudePurple, claudePurpleLight] as CFArray
    let gradientLocations: [CGFloat] = [0.0, 0.5, 1.0]
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: gradientLocations) else {
        return nil
    }

    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: pixelSize), end: CGPoint(x: pixelSize, y: 0), options: [])
    ctx.restoreGState()

    // 绘制内部圆形装饰
    ctx.saveGState()
    let circlePath = CGPath(ellipseIn: CGRect(
        x: Double(pixelSize) * 0.15,
        y: Double(pixelSize) * 0.15,
        width: Double(pixelSize) * 0.7,
        height: Double(pixelSize) * 0.7
    ), transform: nil)
    ctx.addPath(circlePath)
    let semiWhite = makeColor(r: 1.0, g: 1.0, b: 1.0, a: 0.3)
    ctx.setStrokeColor(semiWhite)
    ctx.setLineWidth(Double(pixelSize) * 0.03)
    ctx.strokePath()
    ctx.restoreGState()

    // 绘制 "C" 字母（代表 Claude）
    let fontSize = Double(pixelSize) * 0.55
    let text = "C" as CFString

    // 创建字体
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)

    let attributes: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: white
    ]

    let attributedString = CFAttributedStringCreate(kCFAllocatorDefault, text, attributes as CFDictionary)
    let line = CTLineCreateWithAttributedString(attributedString!)

    // 计算文字位置（居中）
    let textBounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
    let textX = (Double(pixelSize) - Double(textBounds.width)) / 2 - Double(textBounds.origin.x)
    let textY = (Double(pixelSize) - Double(textBounds.height)) / 2 - Double(textBounds.origin.y)

    ctx.saveGState()
    ctx.translateBy(x: 0, y: CGFloat(Double(pixelSize)))
    ctx.scaleBy(x: 1, y: -1)
    ctx.textPosition = CGPoint(x: CGFloat(textX), y: CGFloat(textY))
    CTLineDraw(line, ctx)
    ctx.restoreGState()

    // 添加小箭头装饰（表示"前往"）
    ctx.saveGState()
    let arrowSize = Double(pixelSize) * 0.12
    let arrowX = Double(pixelSize) * 0.72
    let arrowY = Double(pixelSize) * 0.28

    let arrowPath = CGMutablePath()
    arrowPath.move(to: CGPoint(x: CGFloat(arrowX), y: CGFloat(arrowY)))
    arrowPath.addLine(to: CGPoint(x: CGFloat(arrowX + arrowSize), y: CGFloat(arrowY)))
    arrowPath.addLine(to: CGPoint(x: CGFloat(arrowX + arrowSize * 0.6), y: CGFloat(arrowY + arrowSize * 0.4)))
    arrowPath.move(to: CGPoint(x: CGFloat(arrowX + arrowSize), y: CGFloat(arrowY)))
    arrowPath.addLine(to: CGPoint(x: CGFloat(arrowX + arrowSize * 0.6), y: CGFloat(arrowY - arrowSize * 0.4)))

    ctx.addPath(arrowPath)
    let arrowWhite = makeColor(r: 1.0, g: 1.0, b: 1.0, a: 0.9)
    ctx.setStrokeColor(arrowWhite)
    ctx.setLineWidth(Double(pixelSize) * 0.025)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    return ctx.makeImage()
}

func saveImage(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    let utType = UTType.png.identifier as CFString
    guard let destination = CGImageDestinationCreateWithURL(url, utType, 1, nil) else {
        print("Failed to create image destination for \(path)")
        return
    }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
}

// 主程序
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/AppIcon.appiconset"
let fm = FileManager.default

// 确保输出目录存在
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// 生成 Contents.json
var images: [[String: Any]] = []

for (size, scale) in iconSizes {
    guard let image = generateIcon(size: size, scale: scale) else {
        print("Failed to generate icon \(size)x\(size)@\(scale)x")
        continue
    }

    let filename = "icon_\(size)x\(size)\(scale > 1 ? "@\(scale)x" : "").png"
    let filepath = "\(outputDir)/\(filename)"
    saveImage(image, to: filepath)
    print("Generated: \(filename)")

    images.append([
        "filename": filename,
        "idiom": "mac",
        "scale": "\(scale)x",
        "size": "\(size)x\(size)"
    ])
}

// 同时生成 1024x1024 版本
if let image1024 = generateIcon(size: 1024, scale: 1) {
    let filename = "icon_1024x1024.png"
    let filepath = "\(outputDir)/\(filename)"
    saveImage(image1024, to: filepath)
    print("Generated: \(filename)")
}

// 写入 Contents.json
let contents: [String: Any] = [
    "images": images,
    "info": [
        "author": "xcode",
        "version": 1
    ]
]

let contentsData = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
let contentsPath = "\(outputDir)/Contents.json"
try! contentsData.write(to: URL(fileURLWithPath: contentsPath))
print("Generated: Contents.json")

print("\nDone! Icons generated in \(outputDir)")
