import AppKit
import SwiftUI

/// Point Guard: a windowed app for checking on Barry's active sessions.
///
/// Deliberately not a menu bar app, for the reason BarryIdentities/BarryActions
/// give: point-guard is a status-check tool you open occasionally to see if
/// any session needs attention, not something requiring constant menu-bar
/// presence -- the menu bar already has BarrySessions, and a second icon
/// there is a cost with no return for an occasional-glance tool.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let state = PointGuardState()
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.mainMenu = Self.makeMenu()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Point Guard"
        window.contentViewController = NSHostingController(rootView: ContentView(state: state))
        window.setContentSize(NSSize(width: 480, height: 640))
        window.contentMinSize = NSSize(width: 360, height: 420)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("PointGuardWindow")
        window.center()
        window.delegate = self
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    /// Quit when the window closes -- the same call BarryActions makes, for
    /// the same reason: keeping a process resident for an occasional glance
    /// is a cost with no return.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    /// A minimal menu, but a real one: Quit, and Copy/Select All for the
    /// history and reply text.
    private static func makeMenu() -> NSMenu {
        let main = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "Quit Point Guard",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appItem.submenu = appMenu
        main.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(
            withTitle: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        editItem.submenu = editMenu
        main.addItem(editItem)

        return main
    }
}

// Strong global reference (NSApp.delegate is weak)
var appDelegateRef: AppDelegate!

MainActor.assumeIsolated {
    let app = NSApplication.shared
    appDelegateRef = AppDelegate()
    app.delegate = appDelegateRef
    app.run()
}
