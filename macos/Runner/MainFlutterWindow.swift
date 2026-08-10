import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FloatingBubblePlugin.register(with: flutterViewController.engine.binaryMessenger)
    DirectoryPickerPlugin.register(with: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}

/// Always-on-top flat circular panels that open an external URL on click.
enum FloatingBubblePlugin {
  private static var panels: [String: NSPanel] = [:]
  private static var channel: FlutterMethodChannel?

  /// Nightelf emerald flat fill.
  private static let bubbleFill = NSColor(
    calibratedRed: 18.0 / 255.0,
    green: 122.0 / 255.0,
    blue: 82.0 / 255.0,
    alpha: 1.0
  )

  static func register(with messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(
      name: "ai_workbench/floating_bubble",
      binaryMessenger: messenger
    )
    channel = methodChannel
    methodChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "show":
        guard
          let args = call.arguments as? [String: Any],
          let id = args["id"] as? String,
          let title = args["title"] as? String,
          let url = args["url"] as? String
        else {
          result(FlutterError(code: "bad_args", message: "id/title/url required", details: nil))
          return
        }
        DispatchQueue.main.async {
          showBubble(id: id, title: title, url: url)
          result(nil)
        }
      case "hide":
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String else {
          result(FlutterError(code: "bad_args", message: "id required", details: nil))
          return
        }
        DispatchQueue.main.async {
          hideBubble(id: id, notifyDart: false)
          result(nil)
        }
      case "hideAll":
        DispatchQueue.main.async {
          hideAllBubbles()
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func showBubble(id: String, title: String, url: String) {
    if let existing = panels[id], let bubble = existing.contentView as? FloatingBubbleView {
      bubble.configure(id: id, title: title, url: url)
      existing.orderFrontRegardless()
      return
    }

    let size: CGFloat = 64
    let panel = NSPanel(
      contentRect: NSRect(x: 40 + CGFloat(panels.count) * 76, y: 80, width: size, height: size),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.isFloatingPanel = true
    panel.level = .floating
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.ignoresMouseEvents = false
    panel.isMovableByWindowBackground = true

    let bubble = FloatingBubbleView(frame: NSRect(x: 0, y: 0, width: size, height: size))
    bubble.fillColor = bubbleFill
    bubble.configure(id: id, title: title, url: url)
    bubble.onOpen = { bubbleId in
      guard let urlString = BubbleClickTarget.shared.urls[bubbleId],
            let url = URL(string: urlString)
      else {
        return
      }
      NSWorkspace.shared.open(url)
    }
    bubble.onClose = { bubbleId in
      hideBubble(id: bubbleId, notifyDart: true)
    }
    BubbleClickTarget.shared.urls[id] = url

    panel.contentView = bubble
    panel.orderFrontRegardless()
    panels[id] = panel
  }

  private static func hideBubble(id: String, notifyDart: Bool) {
    panels[id]?.orderOut(nil)
    panels.removeValue(forKey: id)
    BubbleClickTarget.shared.urls.removeValue(forKey: id)
    if notifyDart {
      channel?.invokeMethod("dismissed", arguments: ["id": id])
    }
  }

  private static func hideAllBubbles() {
    for id in Array(panels.keys) {
      hideBubble(id: id, notifyDart: false)
    }
  }
}

/// Flat circular bubble: drag to move, click to open, right-click to close.
final class FloatingBubbleView: NSView {
  var fillColor: NSColor = .systemGreen
  var onOpen: ((String) -> Void)?
  var onClose: ((String) -> Void)?

  private var bubbleId = ""
  private var label = ""
  private var toolTipText = ""
  private var mouseDownLocation: NSPoint?
  private var didDrag = false

  override var isFlipped: Bool { false }

  func configure(id: String, title: String, url: String) {
    bubbleId = id
    label = Self.shortLabel(title)
    toolTipText = "\(title)\n\(url)\n拖动移动 · 点击打开 · 右键关闭"
    toolTip = toolTipText
    needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    let bounds = self.bounds
    let path = NSBezierPath(ovalIn: bounds.insetBy(dx: 0.5, dy: 0.5))
    fillColor.setFill()
    path.fill()

    let attrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: NSColor.white,
      .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
    ]
    let text = NSString(string: label)
    let size = text.size(withAttributes: attrs)
    let origin = NSPoint(
      x: (bounds.width - size.width) / 2,
      y: (bounds.height - size.height) / 2
    )
    text.draw(at: origin, withAttributes: attrs)
  }

  override func mouseDown(with event: NSEvent) {
    mouseDownLocation = event.locationInWindow
    didDrag = false
  }

  override func mouseDragged(with event: NSEvent) {
    guard let window, let start = mouseDownLocation else { return }
    let current = event.locationInWindow
    let dx = abs(current.x - start.x)
    let dy = abs(current.y - start.y)
    if dx > 2 || dy > 2 {
      didDrag = true
    }
    let newOrigin = NSPoint(
      x: window.frame.origin.x + event.deltaX,
      y: window.frame.origin.y - event.deltaY
    )
    window.setFrameOrigin(newOrigin)
  }

  override func mouseUp(with event: NSEvent) {
    defer {
      mouseDownLocation = nil
      didDrag = false
    }
    if didDrag {
      return
    }
    onOpen?(bubbleId)
  }

  override func rightMouseUp(with event: NSEvent) {
    let menu = NSMenu()
    let closeItem = NSMenuItem(
      title: "关闭悬浮球",
      action: #selector(closeFromMenu(_:)),
      keyEquivalent: ""
    )
    closeItem.target = self
    menu.addItem(closeItem)
    NSMenu.popUpContextMenu(menu, with: event, for: self)
  }

  @objc private func closeFromMenu(_ sender: Any?) {
    onClose?(bubbleId)
  }

  private static func shortLabel(_ title: String) -> String {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return "N"
    }
    if trimmed.count <= 2 {
      return trimmed
    }
    return String(trimmed.prefix(2))
  }
}

final class BubbleClickTarget: NSObject {
  static let shared = BubbleClickTarget()
  var urls: [String: String] = [:]
}

/// Application-modal directory picker that stays responsive with macos_ui.
enum DirectoryPickerPlugin {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "ai_workbench/directory_picker",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "pickDirectory" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let args = call.arguments as? [String: Any]
      DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = (args?["allowCreate"] as? Bool) ?? true
        panel.prompt = "选择"
        panel.message = (args?["dialogTitle"] as? String) ?? "选择文件夹"
        if let initial = args?["initialDirectory"] as? String, !initial.isEmpty {
          panel.directoryURL = URL(fileURLWithPath: initial, isDirectory: true)
        }
        // runModal keeps keyboard/mouse focus reliable; sheet modal fights macos_ui.
        NSApp.activate(ignoringOtherApps: true)
        let response = panel.runModal()
        if response == .OK, let url = panel.url {
          result(url.path)
        } else {
          result(nil)
        }
      }
    }
  }
}
