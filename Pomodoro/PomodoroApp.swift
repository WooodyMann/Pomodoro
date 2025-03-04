import SwiftUI
import Combine

@main
struct PomodoroMenuBarApp: App {
    // Instantiate the AppDelegate to manage the status bar item
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty WindowGroup since the app runs in the menu bar
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: AnyCancellable?
    var remainingTime: TimeInterval = 0
    let durations: [TimeInterval] = [600, 1200, 2700, 3600] // 10m, 20m, 45m, 60m
    var selectedDuration: TimeInterval = 600

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = formatTime(remainingTime)
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }

        // Initialize the timer label
        updateTimerLabel()
    }

    @objc func statusBarButtonClicked(_ sender: Any?) {
        // Create the menu
        let menu = NSMenu()

        // Add timer duration options
        for duration in durations {
            let minutes = Int(duration) / 60
            let title = "\(minutes) Minute\(minutes > 1 ? "s" : "")"
            let menuItem = NSMenuItem(title: title, action: #selector(setTimerDuration(_:)), keyEquivalent: "")
            menuItem.representedObject = duration
            menu.addItem(menuItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Add Start and Stop options
        let startItem = NSMenuItem(title: "Start Timer", action: #selector(startTimer), keyEquivalent: "S")
        startItem.target = self
        menu.addItem(startItem)

        let stopItem = NSMenuItem(title: "Stop Timer", action: #selector(stopTimer), keyEquivalent: "X")
        stopItem.target = self
        menu.addItem(stopItem)

        // Add Quit option
        let quitItem = NSMenuItem(title: "Quit Pomodoro", action: #selector(quitApp), keyEquivalent: "Q")
        quitItem.target = self
        menu.addItem(quitItem)

        // Attach the menu to the status item
        statusItem.menu = menu
        statusItem.button?.performClick(nil) // Show the menu
        statusItem.menu = nil // Detach to allow button clicks to toggle menu
    }

    @objc func setTimerDuration(_ sender: NSMenuItem) {
        if let duration = sender.representedObject as? TimeInterval {
            selectedDuration = duration
            remainingTime = duration
            updateTimerLabel()
        }
    }

    @objc func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    @objc func stopTimer() {
        timer?.cancel()
        remainingTime = selectedDuration
        updateTimerLabel()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }

    func tick() {
        if remainingTime > 0 {
            remainingTime -= 1
            updateTimerLabel()
        } else {
            timer?.cancel()
            // Optionally, add a notification or sound here
            // For simplicity, we'll reset the timer
            remainingTime = selectedDuration
            updateTimerLabel()
        }
    }

    func updateTimerLabel() {
        if let button = statusItem.button {
            button.title = formatTime(remainingTime)
        }
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02dm %02ds", minutes, seconds)
    }
}
