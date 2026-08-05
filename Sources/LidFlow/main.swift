import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Build contents
        let contentView = LidFlowView()
        
        // Build window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 660),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("LidFlowMainWindow")
        window.title = "LidFlow Hinge Utility"
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        
        // Ensure window is activated on front
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Start NSApplication runloop
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
