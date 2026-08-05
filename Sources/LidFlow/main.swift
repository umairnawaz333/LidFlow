import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    private var statusItem: NSStatusItem?
    
    private var creakMenuItem: NSMenuItem?
    private var thereminMenuItem: NSMenuItem?
    private var showWindowMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start monitoring LidSensor singleton
        let sensor = LidSensor.shared
        sensor.startMonitoring()
        
        // Build contents
        let contentView = LidFlowView()
        
        // Build window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 680, height: 400)
        window.center()
        window.setFrameAutosaveName("LidFlowMainWindow")
        window.title = "LidFlow Hinge Utility"
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        
        // Ensure window is activated on front
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Setup macOS Menu Bar Status Item (Menu Bar Extra)
        setupStatusItem()
        
        // Listen to sensor angle updates to refresh menu bar title and menu states
        sensor.onAngleChange = { [weak self] angle in
            self?.updateMenuBar(angle: angle)
        }
        
        // Set application Dock icon programmatically from main bundle resources
        if let iconURL = Bundle.main.url(forResource: "logo", withExtension: "jpg"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = iconImage
        } else {
            // Fallback to local path check
            let iconPath = "logo.jpg"
            if FileManager.default.fileExists(atPath: iconPath),
               let iconImage = NSImage(contentsOfFile: iconPath) {
                NSApplication.shared.applicationIconImage = iconImage
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Return false so the application keeps running in the menu bar even when window is closed!
        return false
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Just hide the window, don't destroy it!
        window.orderOut(nil)
        showWindowMenuItem?.title = "Show App Window"
        return false
    }

    // MARK: - Menu Bar Setup & Actions
    private func createAngleImage() -> NSImage {
        let size = NSSize(width: 14, height: 14)
        let image = NSImage(size: size)
        image.isTemplate = true
        image.lockFocus()
        
        let path = NSBezierPath()
        path.lineWidth = 1.8
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        
        // Draw the angle: starts from top-right, goes to bottom-left (vertex), then to bottom-right
        path.move(to: NSPoint(x: 12, y: 11))
        path.line(to: NSPoint(x: 2, y: 2))
        path.line(to: NSPoint(x: 12, y: 2))
        
        // Curved indicator arc (radius 5.0, from 0 degrees to 45 degrees)
        path.appendArc(withCenter: NSPoint(x: 2, y: 2), radius: 5.0, startAngle: 0.0, endAngle: 45.0)
        
        path.stroke()
        
        image.unlockFocus()
        return image
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        
        // Set the custom drawn bold angle icon image and align it to the left of the text
        button.image = createAngleImage()
        button.imagePosition = .imageLeft
        
        // Use a semibold monospaced digit system font so values look bold and stable (no horizontal wiggling)
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 13.5, weight: .semibold)
        button.title = "0°"
        
        let menu = NSMenu()
        
        // Sound Mode Header
        let soundHeader = NSMenuItem(title: "Sound Mode", action: nil, keyEquivalent: "")
        soundHeader.isEnabled = false
        menu.addItem(soundHeader)
        
        // Creak option
        let creakItem = NSMenuItem(title: "Creak", action: #selector(toggleCreak), keyEquivalent: "")
        creakItem.state = LidSensor.shared.doorSoundsEnabled ? .on : .off
        menu.addItem(creakItem)
        self.creakMenuItem = creakItem
        
        // Theremin option
        let thereminItem = NSMenuItem(title: "Theremin", action: #selector(toggleTheremin), keyEquivalent: "")
        thereminItem.state = LidSensor.shared.thereminEnabled ? .on : .off
        menu.addItem(thereminItem)
        self.thereminMenuItem = thereminItem
        
        menu.addItem(NSMenuItem.separator())
        
        // Show/Hide App Window
        let showItem = NSMenuItem(title: "Hide App Window", action: #selector(toggleWindow), keyEquivalent: "")
        menu.addItem(showItem)
        self.showWindowMenuItem = showItem
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit option
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleCreak() {
        LidSensor.shared.doorSoundsEnabled.toggle()
        creakMenuItem?.state = LidSensor.shared.doorSoundsEnabled ? .on : .off
    }
    
    @objc private func toggleTheremin() {
        LidSensor.shared.thereminEnabled.toggle()
        thereminMenuItem?.state = LidSensor.shared.thereminEnabled ? .on : .off
    }
    
    @objc private func toggleWindow() {
        if window.isVisible {
            window.orderOut(nil)
            showWindowMenuItem?.title = "Show App Window"
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            showWindowMenuItem?.title = "Hide App Window"
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func updateMenuBar(angle: Double) {
        if let button = statusItem?.button {
            // Rounded to the nearest integer (e.g. 116.7 -> 117)
            button.title = String(format: "%.0f°", round(angle))
        }
        
        // Sync menu item checkmarks with the shared state (in case they were changed in the main UI)
        creakMenuItem?.state = LidSensor.shared.doorSoundsEnabled ? .on : .off
        thereminMenuItem?.state = LidSensor.shared.thereminEnabled ? .on : .off
        showWindowMenuItem?.title = window.isVisible ? "Hide App Window" : "Show App Window"
    }
}

// Start NSApplication runloop
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
