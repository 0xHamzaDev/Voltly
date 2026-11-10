//
//  ContentView.swift
//  Voltly
//
//  Created by David Wernhart on 09.02.20.
//  Copyright © 2020 David Wernhart. All rights reserved.
//

import ServiceManagement
import SwiftUI

struct ContentView: View {
    @ObservedObject private var controller = Controller.shared
    @State private var draftLimit = 80.0

    @AppStorage(Key.limit) private var limit = 80
    @AppStorage(Key.showStatus) private var showStatus = true
    @AppStorage(Key.showActions) private var showActions = true
    @AppStorage(Key.showToggles) private var showToggles = true
    @AppStorage(Key.sailing) private var sailing = false
    @AppStorage(Key.heatProtection) private var heatProtection = false
    @AppStorage(Key.autoDischarge) private var autoDischarge = false

    private var calibrating: Bool {
        if case .calibration = controller.state.mode { return true }
        return false
    }

    private func mode(_ mode: Mode, active: Bool) -> Binding<Bool> {
        Binding(get: { active }, set: { controller.setMode($0 ? mode : .normal) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Voltly").font(.headline)
                Spacer()
                Text("\(controller.percent)%").font(.headline).monospacedDigit()
            }
            if showStatus {
                Text(controller.status).font(.caption).foregroundColor(.secondary)
            }

            HStack {
                Slider(value: $draftLimit, in: 20...100, step: 1) { editing in
                    if !editing { controller.setLimit(Int(draftLimit)) }
                }
                .accessibilityLabel("Charge limit")
                Text("\(Int(draftLimit))%").monospacedDigit().frame(width: 44, alignment: .trailing)
            }

            if showActions {
                HStack {
                    Toggle("Top Up", isOn: mode(.topUp, active: controller.state.mode == .topUp))
                    Toggle("Discharge", isOn: mode(.discharge, active: controller.state.mode == .discharge))
                    Toggle("Calibrate", isOn: mode(.calibration(0), active: calibrating))
                }
                .toggleStyle(.button)
            }

            if showToggles {
                Toggle("Sailing Mode", isOn: $sailing)
                Toggle("Heat Protection", isOn: $heatProtection)
                Toggle("Automatic Discharge", isOn: $autoDischarge)
            }

            Divider()
            HStack {
                Button("Settings…") { (NSApp.delegate as? AppDelegate)?.openSettings() }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear { draftLimit = Double(limit) }
        .onChange(of: limit) { draftLimit = Double($0) }
    }
}

struct SettingsView: View {
    @AppStorage(Key.sailing) private var sailing = false
    @AppStorage(Key.sailRange) private var sailRange = 5
    @AppStorage(Key.heatProtection) private var heatProtection = false
    @AppStorage(Key.maxTemperature) private var maxTemperature = 35
    @AppStorage(Key.stopChargingOnSleep) private var stopChargingOnSleep = false
    @AppStorage(Key.preventSleep) private var preventSleep = true
    @AppStorage(Key.autoDischarge) private var autoDischarge = false
    @AppStorage(Key.clamshellDischarge) private var clamshellDischarge = false
    @AppStorage(Key.ledMode) private var ledMode = 0
    @AppStorage(Key.lowPowerMode) private var lowPowerMode = 0
    @AppStorage(Key.schedule) private var schedule = Data()
    @AppStorage(Key.menuIcon) private var menuIcon = "voltly"
    @AppStorage(Key.menuPercent) private var menuPercent = false
    @AppStorage(Key.showStatus) private var showStatus = true
    @AppStorage(Key.showActions) private var showActions = true
    @AppStorage(Key.showToggles) private var showToggles = true
    @AppStorage(Key.classicKey) private var classicKey = false
    @AppStorage(Key.limit) private var limit = 80
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private var capabilities: [String: Bool] { Helper.instance.capabilities }

    private var tasks: Binding<[ScheduledTask]> {
        Binding(
            get: { (try? JSONDecoder().decode([ScheduledTask].self, from: schedule)) ?? [] },
            set: { schedule = (try? JSONEncoder().encode($0)) ?? Data() }
        )
    }

    var body: some View {
        Form {
            Section("Charging") {
                Toggle("Sailing Mode", isOn: $sailing)
                Stepper("Resume charging \(sailRange)% below the limit", value: $sailRange, in: 2...20)
                Toggle("Heat Protection", isOn: $heatProtection)
                Stepper("Pause charging at \(maxTemperature)°C", value: $maxTemperature, in: 30...45)
                Toggle("Stop Charging when Sleeping", isOn: $stopChargingOnSleep)
                Toggle("Sleep Control: stay awake until the limit is reached", isOn: $preventSleep)
                    .disabled(capabilities["charging"] != true)
            }

            Section("Discharge") {
                Toggle("Automatic Discharge", isOn: $autoDischarge)
                Toggle("Discharge in Clamshell Mode", isOn: $clamshellDischarge)
            }

            Section("Hardware") {
                Picker("MagSafe LED", selection: $ledMode) {
                    Text("System").tag(0)
                    Text("Show charge status").tag(1)
                    Text("Off").tag(2)
                }
                .disabled(capabilities["led"] != true)
                Picker("Low Power Mode", selection: $lowPowerMode) {
                    Text("Do not change").tag(0)
                    Text("Always on").tag(1)
                    Text("On battery only").tag(2)
                    Text("Always off").tag(3)
                }
            }

            Section("Schedule") {
                ForEach(tasks) { $task in
                    HStack {
                        Toggle("Enabled", isOn: $task.enabled).labelsHidden()
                        Picker("Day", selection: $task.weekday) {
                            Text("Every day").tag(0)
                            ForEach(1...7, id: \.self) { Text(Calendar.current.weekdaySymbols[$0 - 1]).tag($0) }
                        }
                        DatePicker("Time", selection: Binding(
                            get: { Calendar.current.startOfDay(for: Date()).addingTimeInterval(Double(task.minutes) * 60) },
                            set: {
                                let parts = Calendar.current.dateComponents([.hour, .minute], from: $0)
                                task.minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
                            }
                        ), displayedComponents: .hourAndMinute)
                        Picker("Action", selection: $task.action) {
                            Text("Top Up").tag("topUp")
                            Text("Discharge").tag("discharge")
                            Text("Calibrate").tag("calibrate")
                            Text("Set limit").tag("limit")
                        }
                        if task.action == "limit" {
                            Stepper("\(task.value)%", value: $task.value, in: 20...100, step: 5)
                        }
                        Button(role: .destructive) {
                            tasks.wrappedValue.removeAll { $0.id == task.id }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Delete task")
                    }
                    .labelsHidden()
                }
                Button("Add Task") { tasks.wrappedValue.append(ScheduledTask()) }
            }

            Section("Menu Bar Icon") {
                Picker("Icon", selection: $menuIcon) {
                    Text("Voltly").tag("voltly")
                    Label("Bolt", systemImage: "bolt.fill").tag("bolt.fill")
                    Label("Battery", systemImage: "battery.75percent").tag("battery.75percent")
                    Label("Leaf", systemImage: "leaf.fill").tag("leaf.fill")
                }
                Toggle("Show battery percentage", isOn: $menuPercent)
            }

            Section("Popover") {
                Toggle("Show status", isOn: $showStatus)
                Toggle("Show Top Up, Discharge and Calibrate", isOn: $showActions)
                Toggle("Show quick toggles", isOn: $showToggles)
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in
                        if enabled { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                #if arch(x86_64)
                Toggle("Use Classic SMC Key (Intel)", isOn: $classicKey)
                    .onChange(of: classicKey) { enabled in
                        Helper.instance.proxy?.setBCLM(UInt8(enabled ? limit : 100))
                    }
                #endif
                Button("Reinstall Helper") { Helper.instance.installHelper() }
                let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                Text("Voltly \(version ?? ""). Based on AlDente by AppHouseKitchen.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 640)
    }
}
