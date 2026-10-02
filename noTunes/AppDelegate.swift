//
//  AppDelegate.swift
//  noTunes
//
//  Created by Tom Taylor on 04/01/2017.
//  Copyright © 2017 Twisted Digital Ltd. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let defaults = UserDefaults.standard

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var launchAtLoginMenuItem: NSMenuItem!

    @IBAction func hideIconClicked(_ sender: NSMenuItem) {
        defaults.set(true, forKey: "hideIcon")
        NSStatusBar.system.removeStatusItem(statusItem)
        self.appIsLaunched()
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }

    @IBAction func launchAtLoginClicked(_ sender: NSMenuItem) {
        guard #available(macOS 13.0, *) else { return }

        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Couldn’t update Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }

        refreshLaunchAtLoginMenuItem()

        if SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == NSEvent.EventType.rightMouseUp ||
           (event.type == NSEvent.EventType.leftMouseUp && event.modifierFlags.contains(NSEvent.ModifierFlags.control)) {
            refreshLaunchAtLoginMenuItem()
            statusItem.menu = statusMenu
            if let menu = statusItem.menu {
                menu.popUp(positioning: menu.items.first, at: NSEvent.mouseLocation, in: nil)
            }
            statusItem.menu = nil
        } else {
            if statusItem.button?.image == NSImage(named: "StatusBarButtonImage") {
                self.appIsLaunched()
                statusItem.button?.image = NSImage(named: "StatusBarButtonImageActive")
            } else {
                statusItem.button?.image = NSImage(named: "StatusBarButtonImage")
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.button?.image = NSImage(named: "StatusBarButtonImageActive")

        if let button = statusItem.button {
            button.action = #selector(self.statusBarButtonClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        if defaults.bool(forKey: "hideIcon") {
            NSStatusBar.system.removeStatusItem(statusItem)
        }

        self.appIsLaunched()
        self.createListener()
        refreshLaunchAtLoginMenuItem()
    }

    func refreshLaunchAtLoginMenuItem() {
        if #available(macOS 13.0, *) {
            launchAtLoginMenuItem.isHidden = false
            launchAtLoginMenuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        } else {
            launchAtLoginMenuItem.isHidden = true
        }
    }

    func createListener() {
        let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter
        workspaceNotificationCenter.addObserver(self, selector: #selector(self.appWillLaunch(note:)), name: NSWorkspace.willLaunchApplicationNotification, object: nil)
    }

    func appIsLaunched() {
        let apps = NSWorkspace.shared.runningApplications
        for currentApp in apps.enumerated() {
            let runningApp = apps[currentApp.offset]

            if(runningApp.activationPolicy == .regular) {
                if(runningApp.bundleIdentifier == "com.apple.iTunes") {
                    runningApp.forceTerminate()
                }
                if(runningApp.bundleIdentifier == "com.apple.Music") {
                    runningApp.forceTerminate()
                }
            }
        }
    }

    @objc func appWillLaunch(note:Notification) {
        if statusItem.button?.image == NSImage(named: "StatusBarButtonImageActive") || defaults.bool(forKey: "hideIcon") {
            if let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if app.bundleIdentifier == "com.apple.Music" {
                    app.forceTerminate()
                    self.launchReplacement()
                }
                else if app.bundleIdentifier == "com.apple.iTunes" {
                    app.forceTerminate()
                    self.launchReplacement()
                }
            }
        }
    }

    func launchReplacement() {
        guard let replacement = defaults.string(forKey: "replacement"), !replacement.isEmpty else {
            return
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [replacement]
        try? task.run()
    }

}
