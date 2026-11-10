//
//  ContentView.swift
//  Voltly
//
//  Created by David Wernhart on 09.02.20.
//  Copyright © 2020 David Wernhart. All rights reserved.
//

import ServiceManagement
import SwiftUI

private struct BatteryBar: View {
    let percent: Int
    let limit: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(percent <= 20 ? Color.red : Color.green)
                    .frame(width: max(geometry.size.width * CGFloat(percent) / 100, 8))
                Rectangle()
                    .fill(.primary)
                    .frame(width: 2, height: 14)
                    .offset(x: geometry.size.width * CGFloat(limit) / 100 - 1)
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityLabel("Battery")
        .accessibilityValue("\(percent) percent, limit \(limit) percent")
    }
}

private struct ModeButton: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 15, weight: .medium))
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .toggleStyle(.button)
    }
}

private struct SwitchRow: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Toggle(title, isOn: $isOn).labelsHidden()
        }
    }
}

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

    private var canDischarge: Bool {
        let capabilities = Helper.instance.capabilities
        return capabilities["adapter"] == true || capabilities["native"] == true
    }

    private func mode(_ mode: Mode, active: Bool) -> Binding<Bool> {
        Binding(get: { active }, set: { controller.setMode($0 ? mode : .normal) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(controller.percent)%")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Spacer()
                    Text("Voltly").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                }
                BatteryBar(percent: controller.percent, limit: Int(draftLimit.rounded()))
                if showStatus {
                    Text(controller.status).font(.callout).foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Charge limit")
                    Spacer()
                    Text("\(Int(draftLimit.rounded()))%").monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $draftLimit, in: 20...100) { editing in
                    if !editing { controller.setLimit(Int(draftLimit.rounded())) }
                }
                .accessibilityLabel("Charge limit")
            }

            if showActions {
                HStack(spacing: 8) {
                    ModeButton(title: "Top Up", symbol: "bolt.fill", isOn: mode(.topUp, active: controller.state.mode == .topUp))
                    ModeButton(title: "Discharge", symbol: "arrow.down.to.line", isOn: mode(.discharge, active: controller.state.mode == .discharge))
                        .disabled(!canDischarge)
                    ModeButton(title: "Calibrate", symbol: "gauge.with.needle", isOn: mode(.calibration(0), active: calibrating))
                        .disabled(!canDischarge)
                }
            }

            if showToggles {
                Divider()
                VStack(spacing: 10) {
                    SwitchRow(title: "Sailing Mode", symbol: "sailboat", isOn: $sailing)
                    SwitchRow(title: "Heat Protection", symbol: "thermometer.medium", isOn: $heatProtection)
                    SwitchRow(title: "Automatic Discharge", symbol: "arrow.down.circle", isOn: $autoDischarge)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }

            Divider()
            HStack {
                Button { (NSApp.delegate as? AppDelegate)?.openSettings() } label: {
                    Label("Settings…", systemImage: "gearshape")
                }
                Spacer()
                Button("Quit Voltly") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
        .frame(width: 300)
        .onAppear { draftLimit = Double(limit) }
        .onChange(of: limit) { draftLimit = Double($0) }
    }
}

private struct Described: View {
    let title: String
    let detail: String

    var body: some View {
        Text(title)
        Text(detail)
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
    @AppStorage(Key.menuIcon) private var menuIcon = Key.defaultMenuIcon
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
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            charging.tabItem { Label("Charging", systemImage: "bolt.fill") }
            discharge.tabItem { Label("Discharge", systemImage: "arrow.down.to.line") }
            scheduleTab.tabItem { Label("Schedule", systemImage: "calendar") }
            appearance.tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 430)
    }

    private var general: some View {
        Form {
            Section {
                Toggle(isOn: $launchAtLogin) {
                    Described(title: "Launch at login", detail: "The charge limit only holds while Voltly is running.")
                }
                .onChange(of: launchAtLogin) { enabled in
                    if enabled { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }
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
            Section {
                #if arch(x86_64)
                Toggle("Use Classic SMC Key (Intel)", isOn: $classicKey)
                    .onChange(of: classicKey) { enabled in
                        Helper.instance.proxy?.setBCLM(UInt8(enabled ? limit : 100))
                    }
                #endif
                LabeledContent("Helper") {
                    Button("Reinstall") { Helper.instance.installHelper() }
                }
                let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                LabeledContent("Voltly \(version ?? "")") {
                    Text("Based on AlDente by AppHouseKitchen")
                }
            }
        }
    }

    private var charging: some View {
        Form {
            Section {
                Toggle(isOn: $sailing) {
                    Described(title: "Sailing Mode", detail: "After reaching the limit, wait for the battery to drop before charging again.")
                }
                Stepper("Resume charging \(sailRange)% below the limit", value: $sailRange, in: 2...20)
                    .disabled(!sailing)
            }
            Section {
                Toggle(isOn: $heatProtection) {
                    Described(title: "Heat Protection", detail: "Pause charging while the battery is hot.")
                }
                Stepper("Pause charging at \(maxTemperature)°C", value: $maxTemperature, in: 30...45)
                    .disabled(!heatProtection)
            }
            Section("Sleep") {
                Toggle(isOn: $stopChargingOnSleep) {
                    Described(title: "Stop Charging when Sleeping", detail: "Pause charging as the Mac goes to sleep.")
                }
                Toggle(isOn: $preventSleep) {
                    Described(
                        title: "Sleep Control",
                        detail: capabilities["charging"] == true
                            ? "Keep the Mac awake until the limit is reached."
                            : "Not needed on this Mac. macOS holds the limit during sleep."
                    )
                }
                .disabled(capabilities["charging"] != true)
            }
        }
    }

    private var discharge: some View {
        Form {
            Toggle(isOn: $autoDischarge) {
                Described(title: "Automatic Discharge", detail: "Run on battery while plugged in whenever the charge is above the limit.")
            }
            Toggle(isOn: $clamshellDischarge) {
                Described(title: "Discharge in Clamshell Mode", detail: "Allow discharging with the lid closed. A closed Mac without wall power can go to sleep.")
            }
        }
    }

    private var scheduleTab: some View {
        Form {
            Section {
                if tasks.wrappedValue.isEmpty {
                    Text("No scheduled tasks. A task is skipped if the Mac is asleep at its time.")
                        .foregroundStyle(.secondary)
                }
                ForEach(tasks) { $task in
                    HStack {
                        Toggle("Enabled", isOn: $task.enabled)
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
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Delete task")
                    }
                    .labelsHidden()
                }
                Button { tasks.wrappedValue.append(ScheduledTask()) } label: {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
    }

    private var appearance: some View {
        Form {
            Section("Menu Bar") {
                Picker("Icon", selection: $menuIcon) {
                    ForEach(["bolt.batteryblock.fill", "bolt.fill", "battery.75percent", "leaf.fill"], id: \.self) {
                        Image(systemName: $0).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                Toggle("Show battery percentage", isOn: $menuPercent)
            }
            Section("Popover") {
                Toggle("Status line", isOn: $showStatus)
                Toggle("Top Up, Discharge and Calibrate", isOn: $showActions)
                Toggle("Quick toggles", isOn: $showToggles)
            }
        }
    }
}
