import AppKit
import ServiceManagement

// MARK: - Settings

enum Defaults {
    static let store = UserDefaults.standard

    static var showSeconds: Bool {
        get { store.object(forKey: "showSecondsV2") as? Bool ?? false }
        set { store.set(newValue, forKey: "showSecondsV2") }
    }
    static var use24Hour: Bool {
        get { store.object(forKey: "use24Hour") as? Bool ?? false }
        set { store.set(newValue, forKey: "use24Hour") }
    }
    static var showDate: Bool {
        get { store.object(forKey: "showDate") as? Bool ?? false }
        set { store.set(newValue, forKey: "showDate") }
    }
    static var fontSize: Double {
        get {
            let stored = store.object(forKey: "fontSize") as? Double ?? 36
            // Map sizes from the earlier, smaller presets onto the new ones.
            return [18: 24, 28: 36, 42: 52, 64: 72][stored] ?? stored
        }
        set { store.set(newValue, forKey: "fontSize") }
    }
    static var fontChoice: String {
        get { store.string(forKey: "fontChoice") ?? "condensed" }
        set { store.set(newValue, forKey: "fontChoice") }
    }
    static var customFontName: String {
        get { store.string(forKey: "customFontName") ?? "" }
        set { store.set(newValue, forKey: "customFontName") }
    }
    static var minuteChimes: Bool {
        get { store.object(forKey: "minuteChimes") as? Bool ?? true }
        set { store.set(newValue, forKey: "minuteChimes") }
    }
    static var cycleColors: Bool {
        get { store.object(forKey: "cycleColors") as? Bool ?? true }
        set { store.set(newValue, forKey: "cycleColors") }
    }
    static var opacity: Double {
        get { store.object(forKey: "opacity") as? Double ?? 0.85 }
        set { store.set(newValue, forKey: "opacity") }
    }
    static var showBackground: Bool {
        get { store.object(forKey: "showBackground") as? Bool ?? true }
        set { store.set(newValue, forKey: "showBackground") }
    }
    static var showBorder: Bool {
        get { store.object(forKey: "showBorder") as? Bool ?? true }
        set { store.set(newValue, forKey: "showBorder") }
    }
    static var alwaysOnTop: Bool {
        get { store.object(forKey: "alwaysOnTop") as? Bool ?? true }
        set { store.set(newValue, forKey: "alwaysOnTop") }
    }
    static var locked: Bool {
        get { store.bool(forKey: "locked") }
        set { store.set(newValue, forKey: "locked") }
    }
    static var origin: NSPoint? {
        get {
            guard let s = store.string(forKey: "origin") else { return nil }
            return NSPointFromString(s)
        }
        set {
            if let p = newValue { store.set(NSStringFromPoint(p), forKey: "origin") }
        }
    }
}

// MARK: - Clock view

final class ClockView: NSView {
    private let timeLabel = NSTextField(labelWithString: "")
    private let dateLabel = NSTextField(labelWithString: "")
    private let stack = NSStackView()
    private let row = NSStackView()
    private let timerButton = NSButton()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.65).cgColor
        layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        layer?.borderWidth = 1

        for label in [timeLabel, dateLabel] {
            label.textColor = .white
            label.alignment = .center
            label.isSelectable = false
        }
        dateLabel.textColor = NSColor.white.withAlphaComponent(0.7)

        stack.orientation = .vertical
        stack.spacing = 0
        stack.alignment = .centerX
        stack.addArrangedSubview(timeLabel)
        stack.addArrangedSubview(dateLabel)
        timerButton.isBordered = false
        timerButton.imagePosition = .imageOnly
        timerButton.contentTintColor = NSColor.white.withAlphaComponent(0.75)
        timerButton.target = self
        timerButton.action = #selector(timerButtonPressed)
        timerButton.toolTip = "Set a timer"

        row.orientation = .horizontal
        row.alignment = .centerY
        row.addArrangedSubview(stack)
        row.addArrangedSubview(timerButton)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: centerXAnchor),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        applyStyle()
    }

    /// Opens the timer menu when no timer is set; otherwise pauses, resumes or dismisses.
    @objc func timerButtonPressed() {
        guard let delegate = NSApp.delegate as? AppDelegate else { return }
        switch delegate.countdown {
        case .idle:
            let menu = delegate.quickTimerMenu()
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: timerButton.bounds.height + 4), in: timerButton)
        case .running, .paused:
            delegate.togglePause()
        case .finished:
            delegate.stopTimer()
        }
    }

    private var buttonSymbol = ""

    private func setButtonSymbol(_ name: String, tip: String) {
        guard name != buttonSymbol else { return }
        buttonSymbol = name
        let config = NSImage.SymbolConfiguration(pointSize: CGFloat(Defaults.fontSize) * 0.85, weight: .semibold)
        timerButton.image = NSImage(systemSymbolName: name, accessibilityDescription: tip)?.withSymbolConfiguration(config)
        timerButton.toolTip = tip
    }

    required init?(coder: NSCoder) { fatalError() }

    func applyStyle() {
        let size = CGFloat(Defaults.fontSize)
        let pointSize = size * 1.35
        let base: NSFont
        switch Defaults.fontChoice {
        case "monospaced":
            base = NSFont.monospacedSystemFont(ofSize: pointSize, weight: .semibold)
        case "rounded":
            let descriptor = NSFont.systemFont(ofSize: pointSize, weight: .semibold)
                .fontDescriptor.withDesign(.rounded)
            base = descriptor.flatMap { NSFont(descriptor: $0, size: pointSize) }
                ?? NSFont.systemFont(ofSize: pointSize, weight: .semibold)
        case "custom":
            base = NSFont(name: Defaults.customFontName, size: pointSize)
                ?? NSFont.systemFont(ofSize: pointSize, weight: .semibold, width: .condensed)
        default:
            base = NSFont.systemFont(ofSize: pointSize, weight: .semibold, width: .condensed)
        }
        let tabular = base.fontDescriptor.addingAttributes([.featureSettings: [[
            NSFontDescriptor.FeatureKey.typeIdentifier: kNumberSpacingType,
            NSFontDescriptor.FeatureKey.selectorIdentifier: kMonospacedNumbersSelector
        ]]])
        timeLabel.font = NSFont(descriptor: tabular, size: pointSize) ?? base
        dateLabel.font = .systemFont(ofSize: max(10, size * 0.4), weight: .medium)
        dateLabel.isHidden = !Defaults.showDate
        row.spacing = size * 0.35
        buttonSymbol = "" // size may have changed; redraw the icon on the next update
    }

    enum Mode { case clock, running, paused, finished(flashOn: Bool) }

    /// Bright colors that read well on the dark background. Red is left out since it means "time's up".
    static let palette: [NSColor] = [
        NSColor(srgbRed: 0.00, green: 0.90, blue: 1.00, alpha: 1), // cyan
        NSColor(srgbRed: 0.65, green: 1.00, blue: 0.00, alpha: 1), // lime
        NSColor(srgbRed: 1.00, green: 0.31, blue: 0.85, alpha: 1), // pink
        NSColor(srgbRed: 1.00, green: 0.90, blue: 0.00, alpha: 1), // yellow
        NSColor(srgbRed: 0.70, green: 0.53, blue: 1.00, alpha: 1), // violet
        NSColor(srgbRed: 0.24, green: 1.00, blue: 0.69, alpha: 1), // mint
    ]
    private var lastColorIndex = -1

    /// Same color for 22 seconds, then the next one; the first color when cycling is off.
    private func accentColor(_ now: Date) -> NSColor {
        guard Defaults.cycleColors else { return Self.palette[0] }
        let index = Int(now.timeIntervalSince1970 / 22) % Self.palette.count
        if index != lastColorIndex {
            if lastColorIndex != -1 && Defaults.showBorder { pulseBorder() }
            lastColorIndex = index
        }
        return Self.palette[index]
    }

    /// A quick thick-border flash on each color change, to catch the eye.
    private func pulseBorder() {
        let pulse = CABasicAnimation(keyPath: "borderWidth")
        pulse.fromValue = 4
        pulse.toValue = 1.5
        pulse.duration = 0.6
        layer?.add(pulse, forKey: "pulse")
    }

    /// Shows the clock, or a countdown with the clock underneath when `countdown` is set.
    /// `note` is prefixed to the small clock line (e.g. "Paused", "Time's up!").
    func update(_ now: Date, countdown: String? = nil, note: String? = nil, mode: Mode = .clock) {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        let hours = Defaults.use24Hour ? "HH" : "h"
        let secs = Defaults.showSeconds ? ":ss" : ""
        let ampm = Defaults.use24Hour ? "" : " a"
        f.dateFormat = "\(hours):mm\(secs)\(ampm)"
        let clock = f.string(from: now)

        var background = NSColor.black.withAlphaComponent(0.65)
        let accent = accentColor(now)
        var textColor = Defaults.cycleColors ? accent : NSColor.white
        var border = accent.withAlphaComponent(0.6)
        if let countdown {
            timeLabel.stringValue = countdown
            dateLabel.isHidden = false
            dateLabel.stringValue = note.map { "\($0) · \(clock)" } ?? clock
            switch mode {
            case .paused:
                textColor = NSColor.white.withAlphaComponent(0.5)
                border = NSColor.white.withAlphaComponent(0.15)
            case .finished(let flashOn):
                textColor = .white
                border = .white
                background = flashOn ? NSColor.systemRed.withAlphaComponent(0.9)
                                     : NSColor.black.withAlphaComponent(0.65)
            default:
                textColor = accent
            }
        } else {
            timeLabel.stringValue = clock
            dateLabel.isHidden = !Defaults.showDate
            if Defaults.showDate {
                f.dateFormat = "EEE, d MMM"
                dateLabel.stringValue = f.string(from: now)
            }
        }
        switch mode {
        case .clock:    setButtonSymbol("timer", tip: "Set a timer")
        case .running:  setButtonSymbol("pause.fill", tip: "Pause timer")
        case .paused:   setButtonSymbol("play.fill", tip: "Resume timer")
        case .finished: setButtonSymbol("stop.fill", tip: "Dismiss timer")
        }
        timeLabel.textColor = textColor
        timerButton.contentTintColor = textColor.withAlphaComponent(0.85)
        layer?.backgroundColor = Defaults.showBackground ? background.cgColor : NSColor.clear.cgColor
        layer?.borderColor = Defaults.showBorder ? border.cgColor : NSColor.clear.cgColor
        layer?.borderWidth = Defaults.showBorder ? 1.5 : 0
        if !Defaults.showBorder { layer?.removeAnimation(forKey: "pulse") }
    }

    /// Size the window needs to fit the current text.
    func fittingContentSize() -> NSSize {
        let s = row.fittingSize
        let padH = CGFloat(Defaults.fontSize) * 0.5
        let padV = CGFloat(Defaults.fontSize) * 0.4
        return NSSize(width: ceil(s.width + padH * 2), height: ceil(s.height + padV * 2))
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        (NSApp.delegate as? AppDelegate)?.buildMenu()
    }

    override func mouseDown(with event: NSEvent) {
        if (NSApp.delegate as? AppDelegate)?.handleClick(count: event.clickCount) != true {
            super.mouseDown(with: event)
        }
    }
}

// MARK: - Minute chimes

/// Synthesized bell chimes for the timer: a short three-note phrase, different for every minute,
/// all at the same clear volume (the built-in macOS sounds vary too much in loudness).
final class Chimes {
    /// Three octaves of a major pentatonic scale from A4, so any combination sounds pleasant.
    private static let scale: [Double] = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26, 28, 31, 33]
        .map { 440 * pow(2, $0 / 12) }
    /// Melody shapes, as scale steps from the starting note. Each has a distinct up/down pattern.
    private static let shapes: [[Int]] = [[0, 2, 4], [4, 2, 0], [0, 4, 2], [2, 0, 4], [0, 0, 4], [0, 3, 5]]
    private static let sampleRate = 44_100.0

    /// Kept so the sound isn't released while it's still playing.
    private var current: NSSound?

    /// Minute n starts on one of 10 notes and uses one of 6 shapes, giving 60 different chimes.
    static func notes(minute: Int) -> [Double] {
        let i = max(0, minute - 1)
        let start = i % 10, shape = shapes[(i / 10) % shapes.count]
        return shape.map { scale[start + $0] }
    }

    static func samples(minute: Int) -> [Float] {
        let freqs = notes(minute: minute)
        let gap = 0.16, ring = 0.7
        var out = [Float](repeating: 0, count: Int(sampleRate * (gap * Double(freqs.count - 1) + ring)))
        for (k, f) in freqs.enumerated() {
            let first = Int(sampleRate * gap * Double(k))
            for n in first..<out.count {
                let t = Double(n - first) / sampleRate
                // Bell-like: a few harmonics, a fast attack and an exponential fade.
                let envelope = min(1, t / 0.005) * exp(-t * 6)
                let tone = sin(2 * .pi * f * t) + 0.3 * sin(4 * .pi * f * t) + 0.1 * sin(6 * .pi * f * t)
                out[n] += Float(0.22 * envelope * tone)
            }
        }
        return out
    }

    /// 16-bit mono WAV file bytes, so the chime can be played with a plain NSSound.
    static func wav(_ samples: [Float]) -> Data {
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        let rate = UInt32(sampleRate), bytes = UInt32(samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(36 + bytes)
        data.append(contentsOf: Array("WAVEfmt ".utf8)); append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(rate); append(rate * 2); append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: Array("data".utf8)); append(bytes)
        for x in samples { append(Int16(max(-1, min(1, x)) * Float(Int16.max))) }
        return data
    }

    func play(minute: Int) {
        current?.stop()
        current = NSSound(data: Self.wav(Self.samples(minute: minute)))
        current?.play()
    }
}

// MARK: - Floating panel

final class ClockPanel: NSPanel {
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 160, height: 50),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = Defaults.showBackground || Defaults.showBorder
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        // High level so it sits above full-screen apps and slideshows.
        level = Defaults.alwaysOnTop ? .screenSaver : .normal
        // Follow every Space (three-finger swipe) and appear over full-screen apps.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let panel = ClockPanel()
    let clockView = ClockView(frame: .zero)
    var statusItem: NSStatusItem!
    var timer: Timer?

    enum CountdownState {
        case idle
        case running(end: Date)
        case paused(remaining: TimeInterval)
        case finished(at: Date)
    }
    var countdown: CountdownState = .idle
    var countdownTotal: TimeInterval = 0
    var lastChimeSecond = -1
    var minutesChimed = 0
    let chimes = Chimes()

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel.contentView = clockView
        panel.delegate = self
        panel.alphaValue = Defaults.opacity
        panel.isMovableByWindowBackground = !Defaults.locked

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "SpaceClock")
        statusItem.menu = buildMenu()

        refresh()
        positionInitially()
        panel.orderFrontRegardless()

        // Tick several times a second so both the clock and a countdown change right on time.
        timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)

        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged),
                                               name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func tick() {
        let now = Date()
        if case .running(let end) = countdown, now >= end {
            countdown = .finished(at: end)
            lastChimeSecond = -1
            statusItem.menu = buildMenu()
        }
        render(now)
        // Re-assert being on top in case another app raised itself.
        if !panel.isVisible { panel.orderFrontRegardless() }
    }

    func render(_ now: Date) {
        switch countdown {
        case .idle:
            clockView.update(now)
        case .running(let end):
            let remaining = end.timeIntervalSince(now)
            chimeIfMinutePassed(remaining: remaining)
            clockView.update(now, countdown: format(remaining), mode: .running)
        case .paused(let remaining):
            clockView.update(now, countdown: format(remaining), note: "Paused", mode: .paused)
        case .finished(let at):
            let elapsed = Int(now.timeIntervalSince(at))
            // Chime every 2 seconds for the first 10 seconds, then just keep flashing.
            if elapsed != lastChimeSecond && elapsed % 2 == 0 && elapsed < 10 {
                lastChimeSecond = elapsed
                NSSound(named: "Glass")?.play()
            }
            // Count up how long it's been since time ran out.
            clockView.update(now, countdown: "+" + format(Double(elapsed)), note: "Time's up!",
                             mode: .finished(flashOn: elapsed % 2 == 0))
        }
        resizeToFit()
    }

    /// Plays a different sound each time another full minute of the timer has gone by.
    /// Skipped at the very end, where the "time's up" chime takes over.
    func chimeIfMinutePassed(remaining: TimeInterval) {
        let passed = Int((countdownTotal - remaining) / 60)
        guard passed > minutesChimed else { return }
        minutesChimed = passed
        guard Defaults.minuteChimes, remaining > 1 else { return }
        chimes.play(minute: passed)
    }

    /// Countdown text: rounds up so it reads 0:01 until the very end, never 0:00 early.
    func format(_ interval: TimeInterval) -> String {
        let total = max(0, Int(ceil(interval)))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    /// Single click dismisses a finished timer; double-click pauses/resumes a timer,
    /// or toggles seconds when no timer is set. Returns true if the click was used.
    func handleClick(count: Int) -> Bool {
        if case .finished = countdown {
            stopTimer()
            return true
        }
        guard count == 2 else { return false }
        switch countdown {
        case .running, .paused: togglePause()
        default: toggleSeconds()
        }
        return true
    }

    // MARK: Timer

    func startTimer(_ seconds: TimeInterval) {
        countdownTotal = seconds
        minutesChimed = 0
        countdown = .running(end: Date().addingTimeInterval(seconds))
        refresh()
    }

    @objc func startPreset(_ sender: NSMenuItem) {
        if let minutes = sender.representedObject as? Double { startTimer(minutes * 60) }
    }

    @objc func togglePause() {
        switch countdown {
        case .running(let end): countdown = .paused(remaining: end.timeIntervalSinceNow)
        case .paused(let remaining): countdown = .running(end: Date().addingTimeInterval(remaining))
        default: return
        }
        refresh()
    }

    @objc func restartTimer() { startTimer(countdownTotal) }

    @objc func stopTimer() {
        countdown = .idle
        refresh()
    }

    @objc func customTimer() {
        let alert = NSAlert()
        alert.messageText = "Set a Timer"
        alert.informativeText = "Enter minutes (7), minutes:seconds (2:30), or units (1h 15m, 90s)."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        field.placeholderString = "e.g. 5"
        alert.accessoryView = field
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        if let seconds = parseDuration(field.stringValue) {
            startTimer(seconds)
        } else {
            NSSound.beep()
        }
    }

    func parseDuration(_ input: String) -> TimeInterval? {
        let text = input.trimmingCharacters(in: .whitespaces).lowercased()
        if text.isEmpty { return nil }

        if text.contains(":") {
            // m:ss or h:mm:ss
            let parts = text.split(separator: ":").map { Double($0.trimmingCharacters(in: .whitespaces)) }
            guard parts.count <= 3, parts.allSatisfy({ $0 != nil }) else { return nil }
            let seconds = parts.compactMap { $0 }.reduce(0) { $0 * 60 + $1 }
            return seconds > 0 ? seconds : nil
        }
        if let minutes = Double(text) {
            return minutes > 0 ? minutes * 60 : nil
        }

        let regex = try! NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)\s*(h|hr|hrs|hours?|m|min|mins|minutes?|s|sec|secs|seconds?)\b"#)
        let range = NSRange(text.startIndex..., in: text)
        var seconds = 0.0
        for match in regex.matches(in: text, range: range) {
            guard let value = Double(text[Range(match.range(at: 1), in: text)!]) else { continue }
            switch text[Range(match.range(at: 2), in: text)!].first {
            case "h": seconds += value * 3600
            case "m": seconds += value * 60
            default: seconds += value
            }
        }
        return seconds > 0 ? seconds : nil
    }

    func refresh() {
        clockView.applyStyle()
        render(Date())
        resizeToFit()
        panel.alphaValue = Defaults.opacity
        panel.isMovableByWindowBackground = !Defaults.locked
        panel.level = Defaults.alwaysOnTop ? .screenSaver : .normal
        panel.hasShadow = Defaults.showBackground || Defaults.showBorder
        statusItem?.menu = buildMenu()
    }

    func resizeToFit() {
        let size = clockView.fittingContentSize()
        var frame = panel.frame
        guard frame.size != size else { return }
        // Keep the top-right corner anchored so it doesn't drift when text width changes.
        frame.origin.x += frame.width - size.width
        frame.origin.y += frame.height - size.height
        frame.size = size
        panel.setFrame(frame, display: true)
        clockView.layer?.cornerRadius = min(14, size.height / 3)
    }

    func positionInitially() {
        if let o = Defaults.origin, NSScreen.screens.contains(where: { $0.frame.contains(o) }) {
            panel.setFrameOrigin(o)
        } else {
            moveToTopRight()
        }
    }

    func moveToTopRight() {
        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: vf.maxX - size.width - 20, y: vf.maxY - size.height - 20))
        Defaults.origin = panel.frame.origin
    }

    @objc func screensChanged() {
        if !NSScreen.screens.contains(where: { $0.frame.intersects(panel.frame) }) { moveToTopRight() }
    }

    func windowDidMove(_ notification: Notification) {
        Defaults.origin = panel.frame.origin
    }

    // MARK: Menu

    /// Compact menu for the ⏱ button: timer controls (if one is set), then the presets.
    func quickTimerMenu() -> NSMenu {
        let full = buildMenu()
        let menu = NSMenu()
        for item in full.items {
            if let presets = item.submenu, item.title == "Start Timer" {
                if !menu.items.isEmpty { menu.addItem(.separator()) }
                let header = NSMenuItem(title: "Start a Timer", action: nil, keyEquivalent: "")
                header.isEnabled = false
                menu.addItem(header)
                for preset in presets.items {
                    presets.removeItem(preset)
                    menu.addItem(preset)
                }
                break
            }
            full.removeItem(item)
            menu.addItem(item)
        }
        return menu
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()

        func action(_ title: String, _ selector: Selector, in target: NSMenu = menu) {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
            item.target = self
            target.addItem(item)
        }

        // Timer controls first, since that's the most common thing to reach for.
        switch countdown {
        case .running:
            action("Pause Timer", #selector(togglePause))
            action("Restart Timer", #selector(restartTimer))
            action("Stop Timer", #selector(stopTimer))
        case .paused:
            action("Resume Timer", #selector(togglePause))
            action("Restart Timer", #selector(restartTimer))
            action("Stop Timer", #selector(stopTimer))
        case .finished:
            action("Dismiss Timer", #selector(stopTimer))
            action("Restart Timer", #selector(restartTimer))
        case .idle:
            break
        }

        let timerMenu = NSMenu()
        for minutes in [1.0, 3, 7, 13, 19, 23, 29, 37, 43, 59] {
            let item = NSMenuItem(title: "\(Int(minutes)) min", action: #selector(startPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = minutes
            timerMenu.addItem(item)
        }
        timerMenu.addItem(.separator())
        action("Custom…", #selector(customTimer), in: timerMenu)
        let timerItem = NSMenuItem(title: "Start Timer", action: nil, keyEquivalent: "")
        timerItem.submenu = timerMenu
        menu.addItem(timerItem)
        menu.addItem(.separator())

        func toggle(_ title: String, _ on: Bool, _ action: Selector) {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            item.state = on ? .on : .off
            menu.addItem(item)
        }

        toggle("Show Seconds", Defaults.showSeconds, #selector(toggleSeconds))
        toggle("24-Hour Time", Defaults.use24Hour, #selector(toggle24h))
        toggle("Show Date", Defaults.showDate, #selector(toggleDate))
        toggle("Lock Position", Defaults.locked, #selector(toggleLock))
        toggle("Always on Top", Defaults.alwaysOnTop, #selector(toggleAlwaysOnTop))
        toggle("Show Background", Defaults.showBackground, #selector(toggleBackground))
        toggle("Show Border", Defaults.showBorder, #selector(toggleBorder))
        toggle("Minute Chimes (Timer)", Defaults.minuteChimes, #selector(toggleMinuteChimes))
        toggle("Change Color Every 22s", Defaults.cycleColors, #selector(toggleCycleColors))
        menu.addItem(.separator())

        let sizeMenu = NSMenu()
        for (name, value) in [("Small", 24.0), ("Medium", 36.0), ("Large", 52.0), ("Huge", 72.0), ("Giant", 100.0), ("Massive", 140.0)] {
            let item = NSMenuItem(title: name, action: #selector(setSize(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            item.state = Defaults.fontSize == value ? .on : .off
            sizeMenu.addItem(item)
        }
        sizeMenu.addItem(.separator())
        action("Custom Size…", #selector(customSize), in: sizeMenu)
        let sizeItem = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        let fontMenu = NSMenu()
        for (title, key) in [("System Condensed", "condensed"),
                             ("System Monospaced", "monospaced"),
                             ("System Rounded", "rounded")] {
            let item = NSMenuItem(title: title, action: #selector(setFont(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = key
            item.state = Defaults.fontChoice == key ? .on : .off
            fontMenu.addItem(item)
        }
        fontMenu.addItem(.separator())
        let customFont = NSMenuItem(title: "Custom Font…", action: #selector(chooseCustomFont), keyEquivalent: "")
        customFont.target = self
        customFont.state = Defaults.fontChoice == "custom" ? .on : .off
        fontMenu.addItem(customFont)
        let fontItem = NSMenuItem(title: "Font", action: nil, keyEquivalent: "")
        fontItem.submenu = fontMenu
        menu.addItem(fontItem)

        let opacityMenu = NSMenu()
        for percent in stride(from: 100, through: 10, by: -10) {
            let value = Double(percent) / 100.0
            let item = NSMenuItem(title: "\(Int(value * 100))%", action: #selector(setOpacity(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            item.state = abs(Defaults.opacity - value) < 0.01 ? .on : .off
            opacityMenu.addItem(item)
        }
        let opacityItem = NSMenuItem(title: "Opacity", action: nil, keyEquivalent: "")
        opacityItem.submenu = opacityMenu
        menu.addItem(opacityItem)

        let reset = NSMenuItem(title: "Move to Top Right", action: #selector(resetPosition), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)

        menu.addItem(.separator())
        toggle("Launch at Login", SMAppService.mainApp.status == .enabled, #selector(toggleLogin))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit SpaceClock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    @objc func toggleSeconds() { Defaults.showSeconds.toggle(); refresh() }
    @objc func toggle24h() { Defaults.use24Hour.toggle(); refresh() }
    @objc func toggleDate() { Defaults.showDate.toggle(); refresh() }
    @objc func toggleLock() { Defaults.locked.toggle(); refresh() }
    @objc func toggleAlwaysOnTop() { Defaults.alwaysOnTop.toggle(); refresh() }
    @objc func toggleBackground() { Defaults.showBackground.toggle(); refresh() }
    @objc func toggleBorder() { Defaults.showBorder.toggle(); refresh() }
    @objc func toggleMinuteChimes() { Defaults.minuteChimes.toggle(); refresh() }
    @objc func toggleCycleColors() { Defaults.cycleColors.toggle(); refresh() }
    @objc func resetPosition() { moveToTopRight() }

    @objc func setSize(_ sender: NSMenuItem) {
        if let v = sender.representedObject as? Double { Defaults.fontSize = v; refresh() }
    }

    @objc func customSize() {
        let alert = NSAlert()
        alert.messageText = "Custom Clock Size"
        alert.informativeText = "Enter the base font size in points (12–300)."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 180, height: 24))
        field.stringValue = String(format: "%g", Defaults.fontSize)
        alert.accessoryView = field
        alert.addButton(withTitle: "Apply")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        guard let value = Double(field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)),
              value.isFinite, (12...300).contains(value) else {
            NSSound.beep()
            return
        }
        Defaults.fontSize = value
        refresh()
    }

    @objc func setFont(_ sender: NSMenuItem) {
        guard let choice = sender.representedObject as? String else { return }
        Defaults.fontChoice = choice
        refresh()
    }

    @objc func chooseCustomFont() {
        let manager = NSFontManager.shared
        let current = NSFont(name: Defaults.customFontName, size: CGFloat(Defaults.fontSize) * 1.35)
            ?? NSFont.systemFont(ofSize: CGFloat(Defaults.fontSize) * 1.35)
        manager.setSelectedFont(current, isMultiple: false)
        manager.target = self
        manager.action = #selector(changeFont(_:))
        manager.orderFrontFontPanel(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func changeFont(_ sender: NSFontManager) {
        let current = NSFont(name: Defaults.customFontName, size: CGFloat(Defaults.fontSize) * 1.35)
            ?? NSFont.systemFont(ofSize: CGFloat(Defaults.fontSize) * 1.35)
        let selected = sender.convert(current)
        Defaults.customFontName = selected.fontName
        Defaults.fontChoice = "custom"
        refresh()
    }

    @objc func setOpacity(_ sender: NSMenuItem) {
        if let v = sender.representedObject as? Double { Defaults.opacity = v; refresh() }
    }

    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't change Launch at Login"
            alert.informativeText = "\(error.localizedDescription)\n\nYou can add SpaceClock manually in System Settings → General → Login Items."
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
        refresh()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Accessory = no Dock icon; also required for the window to show over other apps' full-screen Spaces.
app.setActivationPolicy(.accessory)
app.run()
