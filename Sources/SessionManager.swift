import AppKit

/// Manages Sindri window sessions, tracking the current active session
/// and routing newly opened documents to the active session.
class SessionManager: NSObject {
    static let shared = SessionManager()
    
    // The current active session window
    private(set) weak var currentSessionWindow: NSWindow?
    
    // The host window that a newly opened tab should be merged into
    weak var pendingHostWindow: NSWindow?
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowDidBecomeMain(_:)),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }
    
    @objc private func handleWindowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, isDocumentWindow(window) else { return }
        updateCurrentSession(window)
    }
    
    @objc private func handleWindowDidBecomeMain(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, isDocumentWindow(window) else { return }
        updateCurrentSession(window)
    }
    
    @objc private func handleWindowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, isDocumentWindow(window) else { return }
        if pendingHostWindow == window {
            pendingHostWindow = nil
        }
        if currentSessionWindow == window {
            let next = eligibleDocumentWindows.first(where: { $0 != window })
            currentSessionWindow = next
            DLog("SessionManager: window closed, new current session: '\(next?.title ?? "none")'")
        }
    }
    
    func updateCurrentSession(_ window: NSWindow) {
        guard isDocumentWindow(window) else { return }
        currentSessionWindow = window
        DLog("SessionManager: current session updated to '\(window.title)' (ID: \(window.windowNumber))")
    }
    
    func consumePendingHostWindow() -> NSWindow? {
        let win = pendingHostWindow
        pendingHostWindow = nil
        if let win = win, isDocumentWindow(win) {
            return win
        }
        return nil
    }
    
    func clearPendingHostWindow() {
        pendingHostWindow = nil
    }
    
    var activeSessionWindow: NSWindow? {
        if let key = NSApp.keyWindow, isDocumentWindow(key) {
            currentSessionWindow = key
            return key
        }
        if let main = NSApp.mainWindow, isDocumentWindow(main) {
            currentSessionWindow = main
            return main
        }
        if let current = currentSessionWindow, isDocumentWindow(current) {
            return current
        }
        let fallback = eligibleDocumentWindows.first
        currentSessionWindow = fallback
        return fallback
    }
    
    var eligibleDocumentWindows: [NSWindow] {
        return NSApp.windows.filter { isDocumentWindow($0) }
    }
    
    func isDocumentWindow(_ window: NSWindow) -> Bool {
        return window.canBecomeKey &&
               !window.className.contains("Panel") &&
               !window.className.contains("NSColorPanel") &&
               !window.className.contains("NSFontPanel") &&
               !window.className.contains("NSOpenPanel")
    }
    
    /// Merges all open split windows/sessions back into a single window tab group
    func mergeAllWindows() {
        let windows = eligibleDocumentWindows
        guard windows.count > 1 else { return }
        let targetWindow = activeSessionWindow ?? windows.first
        guard let target = targetWindow else { return }
        
        DLog("SessionManager.mergeAllWindows: merging \(windows.count) windows into target '\(target.title)'")
        target.mergeAllWindows(nil)
        target.makeKeyAndOrderFront(nil)
        updateCurrentSession(target)
    }
}
