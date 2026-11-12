#!/usr/bin/env swift

import AppKit
import QuartzCore

let version = "0.1.1"

let usage = """
usage: skhd-hud [-d seconds] [-c color] [-a app] [--] message...
  -d, --duration  seconds on screen (default 1.2)
  -c, --color     border color: accent, red, orange, yellow, green, blue,
                  purple, pink, gray, white, or hex like #ff8800
  -a, --app       show this app's icon (name like Safari, or a bundle id);
                  the app name is used as the message if none is given
  -v, --version   print version and exit
"""

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write(Data("skhd-hud: \(msg)\n\(usage)\n".utf8))
    exit(2)
}

func parseColor(_ s: String) -> NSColor? {
    let named: [String: NSColor] = [
        "accent": .controlAccentColor,
        "red": .systemRed,
        "orange": .systemOrange,
        "yellow": .systemYellow,
        "green": .systemGreen,
        "blue": .systemBlue,
        "purple": .systemPurple,
        "pink": .systemPink,
        "gray": .systemGray,
        "grey": .systemGray,
        "white": .white,
    ]
    if let color = named[s.lowercased()] { return color }
    var hex = Substring(s)
    if hex.hasPrefix("#") { hex = hex.dropFirst() }
    guard hex.count == 6, let v = UInt32(hex, radix: 16) else { return nil }
    return NSColor(
        srgbRed: CGFloat((v >> 16) & 0xff) / 255,
        green: CGFloat((v >> 8) & 0xff) / 255,
        blue: CGFloat(v & 0xff) / 255,
        alpha: 1
    )
}

// Look up an app icon by running-app name, bundle id, or .app in the usual folders.
func appIcon(_ name: String) -> NSImage? {
    let ws = NSWorkspace.shared
    if let app = ws.runningApplications.first(where: {
        $0.localizedName?.caseInsensitiveCompare(name) == .orderedSame
    }), let icon = app.icon {
        return icon
    }
    if let url = ws.urlForApplication(withBundleIdentifier: name) {
        return ws.icon(forFile: url.path)
    }
    let dirs = [
        "/Applications",
        "/Applications/Utilities",
        "/System/Applications",
        "/System/Applications/Utilities",
        NSHomeDirectory() + "/Applications",
    ]
    for dir in dirs {
        let path = "\(dir)/\(name).app"
        if FileManager.default.fileExists(atPath: path) {
            // Resolve symlinks (e.g. /Applications/Safari.app) so the icon has no alias badge.
            return ws.icon(forFile: URL(fileURLWithPath: path).resolvingSymlinksInPath().path)
        }
    }
    return nil
}

// MARK: - Arguments

var duration = 1.2
var accent = NSColor.controlAccentColor
var appName: String?
var words: [String] = []

let args = Array(CommandLine.arguments.dropFirst())
var i = 0
func value(for flag: String) -> String {
    i += 1
    guard i < args.count else { fail("\(flag) needs a value") }
    return args[i]
}

while i < args.count {
    let arg = args[i]
    switch arg {
    case "-d", "--duration":
        guard let d = Double(value(for: arg)), d > 0 else { fail("invalid duration") }
        duration = d
    case "-c", "--color":
        let v = value(for: arg)
        guard let color = parseColor(v) else { fail("unknown color '\(v)'") }
        accent = color
    case "-a", "--app":
        appName = value(for: arg)
    case "-h", "--help":
        print(usage)
        exit(0)
    case "-v", "--version":
        print("skhd-hud \(version)")
        exit(0)
    case "--":
        words += args[(i + 1)...]
        i = args.count
        continue
    default:
        if arg.count > 1, arg.hasPrefix("-"), Double(arg) == nil {
            fail("unknown option \(arg)")
        }
        words.append(arg)
    }
    i += 1
}

let maxMessageLength = 256
var message = words.joined(separator: " ")
if message.isEmpty { message = appName ?? "" }
guard !message.isEmpty else { exit(0) }
if message.count > maxMessageLength {
    message = String(message.prefix(maxMessageLength - 1)) + "…"
}

let icon = appName.flatMap(appIcon)
if let appName, icon == nil {
    FileHandle.standardError.write(Data("skhd-hud: no icon found for '\(appName)'\n".utf8))
}

// MARK: - Panel

let fadeIn = 0.12
let fadeOut = 0.25
let visibleFor = max(duration, fadeIn + fadeOut)
let paddingX: CGFloat = 36
let paddingY: CGFloat = 20
let cornerRadius: CGFloat = 16
let iconSize: CGFloat = 44
let iconGap: CGFloat = 14
let maxTextWidth: CGFloat = 720

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // No Dock icon; do not become the active app.

func makePanel(for screen: NSScreen) -> NSPanel {
    let label = NSTextField(wrappingLabelWithString: message)
    label.font = .systemFont(ofSize: 28, weight: .semibold)
    label.textColor = .white
    label.alignment = .center
    label.isSelectable = false

    // Wrap long messages instead of growing one very wide line.
    let textLimit = min(maxTextWidth, screen.visibleFrame.width * 0.6)
    let textSize = label.cell!.cellSize(
        forBounds: NSRect(x: 0, y: 0, width: textLimit, height: .greatestFiniteMagnitude)
    )
    let textW = ceil(textSize.width)
    let textH = ceil(textSize.height)

    let iconW = icon == nil ? 0 : iconSize + iconGap
    let contentH = max(textH, icon == nil ? 0 : iconSize)
    let width = paddingX * 2 + iconW + textW
    let height = paddingY * 2 + contentH

    let panel = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: width, height: height),
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )

    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = true
    panel.level = .statusBar
    panel.ignoresMouseEvents = true
    panel.collectionBehavior = [
        .canJoinAllSpaces,
        .fullScreenAuxiliary,
        .transient,
        .ignoresCycle
    ]

    let background = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
    background.wantsLayer = true
    if let layer = background.layer {
        layer.backgroundColor = NSColor(white: 0.08, alpha: 0.92).cgColor
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 2
        layer.borderColor = accent.cgColor
        layer.masksToBounds = true
    }

    if let icon {
        let imageView = NSImageView(frame: NSRect(
            x: paddingX,
            y: paddingY + (contentH - iconSize) / 2,
            width: iconSize,
            height: iconSize
        ))
        imageView.image = icon
        imageView.imageScaling = .scaleProportionallyUpOrDown
        background.addSubview(imageView)
    }

    label.frame = NSRect(
        x: paddingX + iconW,
        y: paddingY + (contentH - textH) / 2,
        width: textW,
        height: textH
    )
    background.addSubview(label)
    panel.contentView = background

    // Horizontally centered, about 1/3 down from the top of this display.
    let frame = screen.visibleFrame
    panel.setFrameOrigin(
        NSPoint(
            x: frame.midX - (width / 2),
            y: frame.maxY - (frame.height / 3) - (height / 2)
        )
    )
    return panel
}

// Scale transform around the view's center (NSView layers anchor at the bottom-left).
func centeredScale(_ s: CGFloat, in bounds: NSRect) -> CATransform3D {
    let cx = bounds.midX, cy = bounds.midY
    var t = CATransform3DMakeTranslation(cx, cy, 0)
    t = CATransform3DScale(t, s, s, 1)
    return CATransform3DTranslate(t, -cx, -cy, 0)
}

// Show on the display containing the mouse cursor (fall back to the main display).
let mouse = NSEvent.mouseLocation
let targetScreen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
    ?? NSScreen.main
let panels = [targetScreen].compactMap { $0 }.map(makePanel)

for panel in panels {
    panel.alphaValue = 0
    panel.orderFrontRegardless()

    if let view = panel.contentView, let layer = view.layer {
        let pop = CABasicAnimation(keyPath: "transform")
        pop.fromValue = centeredScale(0.85, in: view.bounds)
        pop.toValue = CATransform3DIdentity
        pop.duration = fadeIn + 0.08
        pop.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(pop, forKey: "pop")
    }
}

NSAnimationContext.runAnimationGroup { ctx in
    ctx.duration = fadeIn
    panels.forEach { $0.animator().alphaValue = 1 }
}

Timer.scheduledTimer(withTimeInterval: visibleFor - fadeOut, repeats: false) { _ in
    NSAnimationContext.runAnimationGroup({ ctx in
        ctx.duration = fadeOut
        panels.forEach { $0.animator().alphaValue = 0 }
    }, completionHandler: {
        app.terminate(nil)
    })
}

app.run()
