//
//  AppDelegate.swift
//  Voltly
//
//  Created by David Wernhart on 09.02.20.
//  Copyright © 2020 David Wernhart. All rights reserved.
//

import AppKit
import Combine
import SwiftUI

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {

    //var window: NSWindow!
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private var observers: [AnyCancellable] = []

    func applicationWillTerminate(_ aNotification: Notification) {
        Helper.instance.proxy?.reset()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if CommandLine.arguments.contains("--self-check") {
            selfCheck()
            print("self-check passed")
            exit(0)
        }

        let hosting = NSHostingController(rootView: ContentView())
        hosting.sizingOptions = .preferredContentSize

        // Create the popover
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = hosting
        self.popover = popover

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.action = #selector(togglePopover(_:))
        statusBarItem.button?.imagePosition = .imageLeading

        Controller.shared.start()
        Controller.shared.$percent.removeDuplicates().sink { [weak self] in self?.updateStatusItem(percent: $0) }.store(in: &observers)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification).receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatusItem(percent: Controller.shared.percent) }.store(in: &observers)

        Helper.instance.checkHelperVersion{(foundHelper) in
            if(foundHelper){
                print("helper found!")
                Controller.shared.tick()
            }
            else{
                DispatchQueue.main.async { Helper.instance.installHelper() }
            }
        }
    }

    private func updateStatusItem(percent: Int) {
        let defaults = UserDefaults.standard
        let icon = defaults.string(forKey: Key.menuIcon) ?? "voltly"
        statusBarItem.button?.image = icon == "voltly"
            ? NSImage(named: "menubaricon")
            : NSImage(systemSymbolName: icon, accessibilityDescription: "Voltly")
        statusBarItem.button?.title = defaults.bool(forKey: Key.menuPercent) ? " \(percent)%" : ""
    }

    func openSettings() {
        popover.performClose(nil)
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            window.title = "Voltly Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        popover.contentViewController?.view.window?.becomeKey()

        Controller.shared.tick()
        if let button = self.statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

}
