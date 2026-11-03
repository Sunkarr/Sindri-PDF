import SwiftUI
import AppKit
import PDFKit
import UniformTypeIdentifiers

// Define the focused value key for global Cmd+F search routing
struct SearchActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct CloseActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct OpenTabActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct OpenWindowActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct JumpToPageActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct PresentationActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var searchAction: SearchActionKey.Value? {
        get { self[SearchActionKey.self] }
        set { self[SearchActionKey.self] = newValue }
    }
    
    var closeAction: CloseActionKey.Value? {
        get { self[CloseActionKey.self] }
        set { self[CloseActionKey.self] = newValue }
    }
    
    var openTabAction: OpenTabActionKey.Value? {
        get { self[OpenTabActionKey.self] }
        set { self[OpenTabActionKey.self] = newValue }
    }
    
    var openWindowAction: OpenWindowActionKey.Value? {
        get { self[OpenWindowActionKey.self] }
        set { self[OpenWindowActionKey.self] = newValue }
    }
    
    var jumpToPageAction: JumpToPageActionKey.Value? {
        get { self[JumpToPageActionKey.self] }
        set { self[JumpToPageActionKey.self] = newValue }
    }
    
    var presentationAction: PresentationActionKey.Value? {
        get { self[PresentationActionKey.self] }
        set { self[PresentationActionKey.self] = newValue }
    }
}

// Commands definition for global search menu item
struct SearchCommands: Commands {
    @FocusedValue(\.searchAction) var searchAction
    @AppStorage("shortcut_findText") private var findTextData: Data?
    
    var findTextShortcut: ShortcutConfig {
        ShortcutManager.getShortcut(forKey: "shortcut_findText", defaultShortcut: ShortcutManager.defaultFindText)
    }
    
    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Button("Find...") {
                searchAction?()
            }
            .keyboardShortcut(findTextShortcut.swiftUIKeyEquivalent, modifiers: findTextShortcut.swiftUIModifiers)
            .disabled(searchAction == nil)
        }
    }
}

// Commands for File menu: Cmd+O (open as tab) and Cmd+N (open in new window)
struct FileOpenCommands: Commands {
    @FocusedValue(\.openTabAction) var openTabAction
    @FocusedValue(\.openWindowAction) var openWindowAction
    @AppStorage("shortcut_openTab") private var openTabShortcutData: Data?
    @AppStorage("shortcut_openWindow") private var openWindowShortcutData: Data?
    
    var openTabShortcut: ShortcutConfig {
        ShortcutManager.getShortcut(forKey: "shortcut_openTab", defaultShortcut: ShortcutManager.defaultOpenTab)
    }
    
    var openWindowShortcut: ShortcutConfig {
        ShortcutManager.getShortcut(forKey: "shortcut_openWindow", defaultShortcut: ShortcutManager.defaultOpenWindow)
    }
    
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open in New Tab...") {
                openTabAction?()
            }
            .keyboardShortcut(openTabShortcut.swiftUIKeyEquivalent, modifiers: openTabShortcut.swiftUIModifiers)
            
            Button("Open in New Window...") {
                openWindowAction?()
            }
            .keyboardShortcut(openWindowShortcut.swiftUIKeyEquivalent, modifiers: openWindowShortcut.swiftUIModifiers)
        }
    }
}

// Commands definition for Close (Cmd+W) routing
struct CloseCommands: Commands {
    @FocusedValue(\.closeAction) var closeAction
    @AppStorage("shortcut_closeDoc") private var closeDocData: Data?
    
    var closeDocShortcut: ShortcutConfig {
        ShortcutManager.getShortcut(forKey: "shortcut_closeDoc", defaultShortcut: ShortcutManager.defaultCloseDoc)
    }
    
    var body: some Commands {
        CommandGroup(replacing: .saveItem) {
            Button("Close Document") {
                if let action = closeAction {
                    action()
                } else {
                    NSApp.keyWindow?.performClose(nil)
                }
            }
            .keyboardShortcut(closeDocShortcut.swiftUIKeyEquivalent, modifiers: closeDocShortcut.swiftUIModifiers)
        }
    }
}

// Commands definition for Go to Page (Cmd+P) replacing Print menu item
struct FileJumpCommands: Commands {
    @FocusedValue(\.jumpToPageAction) var jumpToPageAction
    @AppStorage("shortcut_goToPage") private var goToPageData: Data?
    
    var goToPageShortcut: ShortcutConfig {
        ShortcutManager.getShortcut(forKey: "shortcut_goToPage", defaultShortcut: ShortcutManager.defaultGoToPage)
    }
    
    var body: some Commands {
        CommandGroup(replacing: .printItem) {
            Button("Go to Page...") {
                jumpToPageAction?()
            }
            .keyboardShortcut(goToPageShortcut.swiftUIKeyEquivalent, modifiers: goToPageShortcut.swiftUIModifiers)
            .disabled(jumpToPageAction == nil)
        }
    }
}

// Commands definition for Presentation Mode (Cmd+Option+P by default)
struct ViewCommands: Commands {
    @FocusedValue(\.presentationAction) var presentationAction
    @AppStorage("shortcut_presentation") private var presentationData: Data?
    
    var presentationShortcut: ShortcutConfig {
        ShortcutManager.getShortcut(forKey: "shortcut_presentation", defaultShortcut: ShortcutManager.defaultPresentation)
    }
    
    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Button("Presentation Mode") {
                presentationAction?()
            }
            .keyboardShortcut(presentationShortcut.swiftUIKeyEquivalent, modifiers: presentationShortcut.swiftUIModifiers)
            .disabled(presentationAction == nil)
        }
    }
}

// Save the paths of all open PDF documents to restore later
func saveOpenDocuments() {
    let urls = OpenDocumentsRegistry.shared.openPaths()
    UserDefaults.standard.set(urls, forKey: "OpenPDFPaths")
}

// Focus window displaying a specific PDF file and return true, or return false if not found
func focusWindow(showing url: URL, excluding currentWindow: NSWindow? = nil) -> Bool {
    let normalized = url.resolvingSymlinksInPath().standardized
    if let window = OpenDocumentsRegistry.shared.window(showing: normalized), window != currentWindow {
        window.makeKeyAndOrderFront(nil)
        return true
    }
    return false
}

// Restore previously open PDF documents (posts notifications handled by ContentView)
func restoreOpenDocuments() {
    guard let paths = UserDefaults.standard.stringArray(forKey: "OpenPDFPaths"), !paths.isEmpty else { return }
    for path in paths {
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: url.path) {
            NotificationCenter.default.post(name: Notification.Name("OpenPDFAsTab"), object: url)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var isTerminating = false
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }
    
    func application(_ app: NSApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return false
    }
    
    func application(_ app: NSApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return false
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        DLog("AppDelegate.application(open urls): count=\(urls.count) urls=\(urls.map { $0.lastPathComponent })")
        OpenQueue.shared.add(urls: urls)
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        AppDelegate.isTerminating = true
        return .terminateNow
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            return false
        }
        let pending = AppleEventsHandler.shared.consumePendingURLs()
        if !pending.isEmpty {
            OpenQueue.shared.add(urls: pending)
        }
        return true
    }
}

@main
struct SindriPDFApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var initialURL: URL? = nil
    
    init() {
        let currentApp = NSRunningApplication.current
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.jonas.SindriPDF")
            .filter { $0 != currentApp }
        
        if !runningApps.isEmpty {
            // Activate the existing running instance
            runningApps.first?.activate()
            
            // Forward command line PDF arguments to the running instance
            let fileArgs = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("-") }
            let urls = fileArgs.map { URL(fileURLWithPath: $0) }.filter { FileManager.default.fileExists(atPath: $0.path) }
            if !urls.isEmpty {
                NSWorkspace.shared.open(urls, withApplicationAt: runningApps.first!.bundleURL!, configuration: NSWorkspace.OpenConfiguration())
            }
            exit(0)
        }
        
        // Parse initial URL from argument if available
        let fileArgs = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("-") }
        let urls = fileArgs.map { URL(fileURLWithPath: $0) }.filter { FileManager.default.fileExists(atPath: $0.path) }
        if let firstURL = urls.first {
            self._initialURL = State(initialValue: firstURL)
            let remainingURLs = Array(urls.dropFirst())
            if !remainingURLs.isEmpty {
                AppleEventsHandler.shared.appendPendingURLs(remainingURLs)
            }
        }
        
        // Register Apple Event handler early for subsequent document opens
        if !AppleEventsHandler.hasRegistered {
            AppleEventsHandler.hasRegistered = true
            NSAppleEventManager.shared().setEventHandler(
                AppleEventsHandler.shared,
                andSelector: #selector(AppleEventsHandler.handleOpenDocsEvent(_:withReplyEvent:)),
                forEventClass: AEEventClass(kCoreEventClass),
                andEventID: AEEventID(kAEOpenDocuments)
            )
        }
    }
    
    var body: some Scene {
        // Main window (shows landing page by default, or initial URL)
        Window("Sindri PDF", id: "main") {
            ContentView(fileURL: initialURL)
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            SidebarCommands()
            FileOpenCommands()
            SearchCommands()
            CloseCommands()
            FileJumpCommands()
            ViewCommands()
        }
        
        // Window group for opening subsequent files as tabs
        WindowGroup(for: URL.self) { $url in
            ContentView(fileURL: url)
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            SidebarCommands()
            FileOpenCommands()
            SearchCommands()
            CloseCommands()
            FileJumpCommands()
            ViewCommands()
        }
        
        Settings {
            SettingsView()
        }
    }
}

// Map the native macOS tab bar plus (+) button action to a custom file picker
extension NSWindow {
    @objc open override func newWindowForTab(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.pdf]
        
        if panel.runModal() == .OK, !panel.urls.isEmpty {
            OpenQueue.shared.add(urls: panel.urls)
        }
    }
}

class OpenDocumentsRegistry {
    static let shared = OpenDocumentsRegistry()
    
    private var openDocuments: [String: NSWindow] = [:]
    private var separateWindowURLs: Set<String> = []
    private let lock = NSLock()
    
    func registerSeparateWindow(for url: URL) {
        lock.lock()
        defer { lock.unlock() }
        let path = url.resolvingSymlinksInPath().standardized.path.lowercased()
        separateWindowURLs.insert(path)
    }
    
    func consumeSeparateWindow(for url: URL) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let path = url.resolvingSymlinksInPath().standardized.path.lowercased()
        return separateWindowURLs.remove(path) != nil
    }
    
    func register(window: NSWindow, for url: URL) {
        lock.lock()
        defer { lock.unlock() }
        let path = url.resolvingSymlinksInPath().standardized.path
        openDocuments[path] = window
    }
    
    func unregister(window: NSWindow) {
        lock.lock()
        defer { lock.unlock() }
        openDocuments = openDocuments.filter { $0.value != window }
    }
    
    func unregister(url: URL) {
        lock.lock()
        defer { lock.unlock() }
        let path = url.resolvingSymlinksInPath().standardized.path
        openDocuments.removeValue(forKey: path)
        
        // Fallback case-insensitive unregister to be safe
        let lowercasePath = path.lowercased()
        if let key = openDocuments.keys.first(where: { $0.lowercased() == lowercasePath }) {
            openDocuments.removeValue(forKey: key)
        }
    }
    
    func window(showing url: URL) -> NSWindow? {
        lock.lock()
        defer { lock.unlock() }
        let path = url.resolvingSymlinksInPath().standardized.path
        if let window = openDocuments[path], window.isVisible {
            return window
        }
        
        // Fallback case-insensitive search
        let lowercasePath = path.lowercased()
        for (openPath, window) in openDocuments {
            if openPath.lowercased() == lowercasePath && window.isVisible {
                return window
            }
        }
        return nil
    }
    
    func url(for window: NSWindow) -> URL? {
        lock.lock()
        defer { lock.unlock() }
        for (path, w) in openDocuments {
            if w == window {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
    
    func openPaths() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return openDocuments.compactMap { path, window in
            return window.isVisible ? path : nil
        }
    }
}

class OpenQueue {
    static let shared = OpenQueue()
    private var urls: [URL] = []
    private var currentURL: URL? = nil
    private let lock = NSLock()
    private var isProcessing = false
    private var isReady = false
    private var timeoutTimer: Timer? = nil
    
    func markReady() {
        lock.lock()
        let wasReady = isReady
        isReady = true
        let shouldStart = !isProcessing && !urls.isEmpty
        if shouldStart {
            isProcessing = true
        }
        DLog("OpenQueue.markReady: wasReady=\(wasReady), shouldStart=\(shouldStart), queuedCount=\(urls.count)")
        lock.unlock()
        
        if !wasReady && shouldStart {
            DispatchQueue.main.async { [weak self] in
                self?.processNext()
            }
        }
    }
    
    func add(urls: [URL]) {
        lock.lock()
        // Filter out duplicates that are already in the queue or currently being loaded
        let uniqueNew = urls.filter { newURL in
            let path = newURL.resolvingSymlinksInPath().standardized.path
            let isCurrent = currentURL?.resolvingSymlinksInPath().standardized.path == path
            let isQueued = self.urls.contains(where: { $0.resolvingSymlinksInPath().standardized.path == path })
            return !isCurrent && !isQueued
        }
        self.urls.append(contentsOf: uniqueNew)
        DLog("OpenQueue.add: added=\(uniqueNew.map { $0.lastPathComponent }), totalQueued=\(self.urls.map { $0.lastPathComponent }), isReady=\(isReady), isProcessing=\(isProcessing)")
        let shouldStart = isReady && !isProcessing
        if shouldStart {
            isProcessing = true
        }
        lock.unlock()
        
        if shouldStart {
            DispatchQueue.main.async { [weak self] in
                self?.processNext()
            }
        }
    }
    
    func processNext() {
        lock.lock()
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        
        guard !urls.isEmpty else {
            DLog("OpenQueue.processNext: queue is empty, stopping.")
            isProcessing = false
            currentURL = nil
            lock.unlock()
            return
        }
        let nextURL = urls.removeFirst()
        currentURL = nextURL
        DLog("OpenQueue.processNext: dispatching \(nextURL.lastPathComponent)")
        lock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            // Start a 3.0s timeout to prevent getting stuck if a window fails to open
            self?.timeoutTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                DLog("OpenQueue: Timeout waiting for window to open, moving to next.")
                self?.processNext()
            }
            
            NotificationCenter.default.post(name: Notification.Name("OpenSinglePDF"), object: nextURL)
        }
    }
}

class AppleEventsHandler: NSObject {
    static let shared = AppleEventsHandler()
    static var hasRegistered = false
    
    private var pendingURLs: [URL] = []
    private let lock = NSLock()
    
    func appendPendingURLs(_ urls: [URL]) {
        lock.lock()
        defer { lock.unlock() }
        pendingURLs.append(contentsOf: urls)
    }
    
    func consumePendingURLs() -> [URL] {
        lock.lock()
        defer { lock.unlock() }
        let urls = pendingURLs
        pendingURLs.removeAll()
        return urls
    }
    
    @objc func handleOpenDocsEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let filesList = event.paramDescriptor(forKeyword: keyDirectObject) else { return }
        
        var urls: [URL] = []
        for i in 1...filesList.numberOfItems {
            if let descriptor = filesList.atIndex(i) {
                if let url = descriptor.fileURLValue {
                    urls.append(url)
                } else if let str = descriptor.stringValue, !str.isEmpty {
                    urls.append(URL(fileURLWithPath: str))
                }
            }
        }
        
        guard !urls.isEmpty else { return }
        DLog("DEBUG handleOpenDocsEvent: received \(urls.count) URLs: \(urls.map { $0.lastPathComponent })")
        
        DispatchQueue.main.async {
            // Activate the running app so it comes to the foreground
            NSApp.activate(ignoringOtherApps: true)
            
            // Filter out URLs that are already open and just focus them
            let urlsToOpen = urls.filter { url in
                if focusWindow(showing: url) {
                    return false
                }
                return true
            }
            
            guard !urlsToOpen.isEmpty else { return }
            
            // Bring frontmost window to key if available
            let visibleCandidateWindows = NSApp.windows.filter {
                $0.isVisible && $0.canBecomeKey && !$0.className.contains("Panel")
            }
            if let frontWin = visibleCandidateWindows.first {
                frontWin.makeKeyAndOrderFront(nil)
            }
            
            if visibleCandidateWindows.isEmpty {
                self.appendPendingURLs(urlsToOpen)
                _ = NSApp.delegate?.applicationShouldHandleReopen?(NSApp, hasVisibleWindows: false)
            } else {
                OpenQueue.shared.add(urls: urlsToOpen)
            }
        }
    }
}
