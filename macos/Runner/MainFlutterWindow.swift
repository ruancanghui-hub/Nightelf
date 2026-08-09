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

/// Always-on-top circular panels that open an external URL on click.
enum FloatingBubblePlugin {
  private static var panels: [String: NSPanel] = [:]
  private static var channel: FlutterMethodChannel?

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
          hideBubble(id: id)
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
    if let existing = panels[id] {
      existing.title = title
      if let button = existing.contentView as? NSButton {
        button.title = shortLabel(title)
        button.toolTip = "\(title)\n\(url)"
        button.target = BubbleClickTarget.shared
        BubbleClickTarget.shared.urls[id] = url
        button.identifier = NSUserInterfaceItemIdentifier(id)
      }
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
    panel.hasShadow = true
    panel.hidesOnDeactivate = false
    panel.ignoresMouseEvents = false

    let button = NSButton(frame: NSRect(x: 0, y: 0, width: size, height: size))
    button.title = shortLabel(title)
    button.toolTip = "\(title)\n\(url)\n右键关闭"
    button.bezelStyle = .circular
    button.isBordered = false
    button.wantsLayer = true
    button.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
    button.layer?.cornerRadius = size / 2
    button.contentTintColor = .white
    button.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
    button.target = BubbleClickTarget.shared
    button.action = #selector(BubbleClickTarget.openUrl(_:))
    button.identifier = NSUserInterfaceItemIdentifier(id)
    BubbleClickTarget.shared.urls[id] = url
    BubbleClickTarget.shared.onClose = { bubbleId in
      hideBubble(id: bubbleId)
    }

    let menu = NSMenu()
    let closeItem = NSMenuItem(
      title: "关闭悬浮球",
      action: #selector(BubbleClickTarget.closeBubble(_:)),
      keyEquivalent: ""
    )
    closeItem.target = BubbleClickTarget.shared
    closeItem.representedObject = id
    menu.addItem(closeItem)
    button.menu = menu

    panel.contentView = button
    panel.orderFrontRegardless()
    panels[id] = panel
  }

  private static func hideBubble(id: String) {
    panels[id]?.orderOut(nil)
    panels.removeValue(forKey: id)
    BubbleClickTarget.shared.urls.removeValue(forKey: id)
  }

  private static func hideAllBubbles() {
    for id in Array(panels.keys) {
      hideBubble(id: id)
    }
  }

  private static func shortLabel(_ title: String) -> String {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return "🔗"
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
  var onClose: ((String) -> Void)?

  @objc func openUrl(_ sender: NSButton) {
    let id = sender.identifier?.rawValue ?? ""
    guard let urlString = urls[id], let url = URL(string: urlString) else {
      return
    }
    NSWorkspace.shared.open(url)
  }

  @objc func closeBubble(_ sender: NSMenuItem) {
    guard let id = sender.representedObject as? String else {
      return
    }
    onClose?(id)
  }
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
