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
        #if DEBUG
        if let index = CommandLine.arguments.firstIndex(of: "--snapshot"), CommandLine.arguments.count > index + 1 {
            Controller.shared.tick()
            let folder = URL(fileURLWithPath: CommandLine.arguments[index + 1])
            snapshot(ContentView().background(Color(nsColor: .windowBackgroundColor)), to: folder.appendingPathComponent("popover.png"))
            snapshot(SettingsView(), to: folder.appendingPathComponent("settings.png"))
            exit(0)
        }
        #endif
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

    #if DEBUG
    private func snapshot<Content: View>(_ view: Content, to url: URL) {
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        let window = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try? bitmap.representation(using: .png, properties: [:])?.write(to: url)
    }
    #endif

    private func updateStatusItem(percent: Int) {
        let defaults = UserDefaults.standard
        let icon = defaults.string(forKey: Key.menuIcon) ?? Key.defaultMenuIcon
        statusBarItem.button?.image = NSImage(systemSymbolName: icon, accessibilityDescription: "Voltly")
            ?? NSImage(systemSymbolName: Key.defaultMenuIcon, accessibilityDescription: "Voltly")
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
