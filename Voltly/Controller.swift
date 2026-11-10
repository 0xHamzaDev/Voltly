import AppKit
import Combine
import IOKit.ps
import IOKit.pwr_mgt

enum Key {
    static let limit = "chargeVal"
    static let classicKey = "oldKey"
    static let sailing = "sailing"
    static let sailRange = "sailRange"
    static let heatProtection = "heatProtection"
    static let maxTemperature = "maxTemperature"
    static let autoDischarge = "autoDischarge"
    static let clamshellDischarge = "clamshellDischarge"
    static let stopChargingOnSleep = "stopChargingOnSleep"
    static let preventSleep = "preventSleep"
    static let ledMode = "ledMode"
    static let lowPowerMode = "lowPowerMode"
    static let schedule = "schedule"
    static let menuIcon = "menuIcon"
    static let menuPercent = "menuPercent"
    static let showStatus = "showStatus"
    static let showActions = "showActions"
    static let showToggles = "showToggles"

    static let defaults: [String: Any] = [
        limit: 80, sailRange: 5, maxTemperature: 35, preventSleep: true,
        menuIcon: "voltly", showStatus: true, showActions: true, showToggles: true,
    ]
}

struct Config {
    var limit = 80
    var sailing = false
    var sailRange = 5
    var heatProtection = false
    var maxTemperature = 35.0
    var autoDischarge = false
    var clamshellDischarge = false
    var stopChargingOnSleep = false
}

enum Mode: Equatable {
    case normal, topUp, discharge, calibration(Int)
}

struct ControlState {
    var mode = Mode.normal
    var sailing = false
    var hot = false
    var holdUntil: Date?
}

struct Decision: Equatable {
    var chargeTo: Int
    var dischargeTo: Int?
}

func decide(_ config: Config, percent: Int, temperature: Double, lidClosed: Bool, sleeping: Bool, now: Date, state: inout ControlState) -> Decision {
    var chargeTo = config.limit
    var dischargeTo: Int?

    switch state.mode {
    case .normal:
        break
    case .topUp:
        if percent >= 100 { state.mode = .normal } else { chargeTo = 100 }
    case .discharge:
        if percent <= config.limit { state.mode = .normal } else { dischargeTo = config.limit }
    case .calibration(0):
        chargeTo = 100
        if percent >= 100 { state.mode = .calibration(1) }
    case .calibration(1):
        chargeTo = 15
        if percent <= 15 { state.mode = .calibration(2) } else { dischargeTo = 15 }
    case .calibration(2):
        chargeTo = 100
        if percent >= 100 {
            state.mode = .calibration(3)
            state.holdUntil = now.addingTimeInterval(3600)
        }
    case .calibration(3):
        chargeTo = 100
        if let holdUntil = state.holdUntil, now >= holdUntil { state.mode = .calibration(4) }
    case .calibration:
        if percent <= config.limit { state.mode = .normal } else { dischargeTo = config.limit }
    }

    if state.mode == .normal {
        if config.autoDischarge && percent > config.limit { dischargeTo = config.limit }
        if percent >= config.limit {
            state.sailing = config.sailing
        } else if percent <= config.limit - config.sailRange {
            state.sailing = false
        }
        if state.sailing && config.sailing { chargeTo = 0 }
    } else {
        state.sailing = false
    }

    state.hot = config.heatProtection
        && (temperature >= config.maxTemperature || (state.hot && temperature > config.maxTemperature - 2))
    if state.hot || (sleeping && config.stopChargingOnSleep) { chargeTo = 0 }
    if sleeping || (lidClosed && !config.clamshellDischarge) { dischargeTo = nil }

    return Decision(chargeTo: chargeTo, dischargeTo: dischargeTo)
}

struct ScheduledTask: Codable, Identifiable, Equatable {
    var id = UUID()
    var enabled = true
    var weekday = 0
    var minutes = 8 * 60
    var action = "topUp"
    var value = 80
    var lastFired = 0.0
}

func dueTasks(_ tasks: [ScheduledTask], now: Date, calendar: Calendar = .current) -> [Int] {
    let parts = calendar.dateComponents([.weekday, .hour, .minute], from: now)
    let minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    let today = calendar.startOfDay(for: now).timeIntervalSince1970
    return tasks.indices.filter {
        let task = tasks[$0]
        return task.enabled
            && (task.weekday == 0 || task.weekday == parts.weekday)
            && (0..<2).contains(minutes - task.minutes)
            && task.lastFired != today
    }
}

func selfCheck() {
    var config = Config()
    var state = ControlState()
    let now = Date(timeIntervalSince1970: 0)
    func run(_ percent: Int, temperature: Double = 25, lidClosed: Bool = false, sleeping: Bool = false, at time: Date = now) -> Decision {
        decide(config, percent: percent, temperature: temperature, lidClosed: lidClosed, sleeping: sleeping, now: time, state: &state)
    }

    precondition(run(50) == Decision(chargeTo: 80))
    precondition(run(90) == Decision(chargeTo: 80))

    config.sailing = true
    precondition(run(80).chargeTo == 0)
    precondition(run(76).chargeTo == 0)
    precondition(run(75).chargeTo == 80)
    precondition(run(79).chargeTo == 80)
    config.sailing = false

    config.heatProtection = true
    precondition(run(50, temperature: 36).chargeTo == 0)
    precondition(run(50, temperature: 34).chargeTo == 0)
    precondition(run(50, temperature: 32.9).chargeTo == 80)
    config.heatProtection = false

    config.autoDischarge = true
    precondition(run(90).dischargeTo == 80)
    precondition(run(90, lidClosed: true).dischargeTo == nil)
    config.clamshellDischarge = true
    precondition(run(90, lidClosed: true).dischargeTo == 80)
    precondition(run(90, sleeping: true).dischargeTo == nil)
    config.autoDischarge = false

    config.stopChargingOnSleep = true
    precondition(run(50, sleeping: true).chargeTo == 0)
    config.stopChargingOnSleep = false

    state.mode = .topUp
    precondition(run(90).chargeTo == 100)
    precondition(run(100).chargeTo == 80 && state.mode == .normal)

    state.mode = .discharge
    precondition(run(90).dischargeTo == 80)
    precondition(run(80).dischargeTo == nil && state.mode == .normal)

    state.mode = .calibration(0)
    precondition(run(90).chargeTo == 100)
    _ = run(100)
    precondition(run(100) == Decision(chargeTo: 15, dischargeTo: 15))
    _ = run(15)
    precondition(run(15).chargeTo == 100 && state.mode == .calibration(2))
    _ = run(100)
    precondition(run(100).chargeTo == 100 && state.mode == .calibration(3))
    _ = run(100, at: now.addingTimeInterval(3600))
    precondition(run(100, at: now.addingTimeInterval(3601)).dischargeTo == 80)
    precondition(run(80) == Decision(chargeTo: 80) && state.mode == .normal)

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let thursdayEight = Date(timeIntervalSince1970: 7 * 86400 + 8 * 3600)
    var tasks = [ScheduledTask(), ScheduledTask(weekday: 2), ScheduledTask(weekday: 5), ScheduledTask(enabled: false)]
    precondition(dueTasks(tasks, now: thursdayEight, calendar: calendar) == [0, 2])
    precondition(dueTasks(tasks, now: thursdayEight.addingTimeInterval(120), calendar: calendar).isEmpty)
    tasks[0].lastFired = calendar.startOfDay(for: thursdayEight).timeIntervalSince1970
    precondition(dueTasks(tasks, now: thursdayEight, calendar: calendar) == [2])
}

final class Controller: ObservableObject {
    static let shared = Controller()

    @Published var percent = 0
    @Published var status = "Waiting for helper…"
    @Published var state = ControlState()

    private var temperature = 0.0
    private var sleeping = false
    private var sentNativeLimit: Int?
    private var sentLED: UInt8?
    private var sleepAssertion: IOPMAssertionID?
    private let defaults = UserDefaults.standard

    func start() {
        defaults.register(defaults: Key.defaults)
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in self.tick() }
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { _ in
            self.sleeping = true
            self.tick()
        }
        workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
            self.sleeping = false
            self.sentNativeLimit = nil
            self.sentLED = nil
            self.tick()
        }
        tick()
    }

    func setLimit(_ limit: Int) {
        let limit = min(max(limit, 20), 100)
        defaults.set(limit, forKey: Key.limit)
        if defaults.bool(forKey: Key.classicKey) {
            Helper.instance.proxy?.setBCLM(UInt8(limit))
        }
        tick()
    }

    func setMode(_ mode: Mode) {
        let capabilities = Helper.instance.capabilities
        let canDischarge = capabilities["adapter"] == true || capabilities["native"] == true
        guard canDischarge || mode == .normal || mode == .topUp else { return }
        state.mode = mode
        tick()
    }

    func perform(_ action: String, value: Int) {
        switch action {
        case "topUp": setMode(.topUp)
        case "discharge": setMode(.discharge)
        case "calibrate": setMode(.calibration(0))
        default: setLimit(value)
        }
    }

    private func runSchedule() {
        guard let data = defaults.data(forKey: Key.schedule),
              var tasks = try? JSONDecoder().decode([ScheduledTask].self, from: data) else { return }
        let now = Date()
        let due = dueTasks(tasks, now: now)
        guard !due.isEmpty else { return }
        for index in due {
            tasks[index].lastFired = Calendar.current.startOfDay(for: now).timeIntervalSince1970
        }
        defaults.set(try? JSONEncoder().encode(tasks), forKey: Key.schedule)
        for index in due {
            perform(tasks[index].action, value: tasks[index].value)
        }
    }

    func tick() {
        guard let power = powerSource() else {
            status = "No battery found"
            return
        }
        percent = power.percent
        guard Helper.instance.isInitialized, let helper = Helper.instance.proxy else { return }
        runSchedule()

        let config = Config(
            limit: defaults.integer(forKey: Key.limit),
            sailing: defaults.bool(forKey: Key.sailing),
            sailRange: defaults.integer(forKey: Key.sailRange),
            heatProtection: defaults.bool(forKey: Key.heatProtection),
            maxTemperature: defaults.double(forKey: Key.maxTemperature),
            autoDischarge: defaults.bool(forKey: Key.autoDischarge),
            clamshellDischarge: defaults.bool(forKey: Key.clamshellDischarge),
            stopChargingOnSleep: defaults.bool(forKey: Key.stopChargingOnSleep)
        )
        if config.heatProtection {
            helper.batteryTemperature { temperature in
                DispatchQueue.main.async { if temperature > 0 { self.temperature = temperature } }
            }
        }

        let classicKey = defaults.bool(forKey: Key.classicKey)
        var next = state
        let decision = classicKey
            ? Decision(chargeTo: 100)
            : decide(config, percent: percent, temperature: temperature, lidClosed: lidClosed(), sleeping: sleeping, now: Date(), state: &next)
        state = next

        let capabilities = Helper.instance.capabilities
        let charging = percent < decision.chargeTo
        let discharging = decision.dischargeTo != nil
        let plugged = power.onAC || discharging

        if capabilities["charging"] == true {
            helper.setCharging(charging)
        } else if capabilities["native"] == true {
            let target = min(max(decision.dischargeTo ?? max(decision.chargeTo, percent), 10), 100)
            if target != sentNativeLimit {
                helper.setNativeLimit(target)
                sentNativeLimit = target
            }
        }
        if capabilities["adapter"] == true {
            helper.setAdapter(!discharging)
        }

        if capabilities["led"] == true {
            let led: UInt8 = [0: 0, 2: 1][defaults.integer(forKey: Key.ledMode)] ?? (discharging ? 1 : charging && plugged ? 4 : 3)
            if led != sentLED {
                helper.setLED(led)
                sentLED = led
            }
        }

        let lowPower: Bool? = [1: true, 2: !plugged, 3: false][defaults.integer(forKey: Key.lowPowerMode)]
        if let lowPower, lowPower != ProcessInfo.processInfo.isLowPowerModeEnabled {
            helper.setLowPowerMode(lowPower)
        }

        let stayAwake = defaults.bool(forKey: Key.preventSleep) && capabilities["charging"] == true && charging && power.onAC
        if stayAwake, sleepAssertion == nil {
            var assertion = IOPMAssertionID(0)
            if IOPMAssertionCreateWithName(kIOPMAssertionTypePreventSystemSleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), "Voltly is charging to the limit" as CFString, &assertion) == kIOReturnSuccess {
                sleepAssertion = assertion
            }
        } else if !stayAwake, let assertion = sleepAssertion {
            IOPMAssertionRelease(assertion)
            sleepAssertion = nil
        }

        status = classicKey
            ? "Classic SMC key mode. Final charge can differ by up to 5%"
            : statusText(decision, charging: charging, plugged: plugged, capabilities: capabilities)
    }

    private func statusText(_ decision: Decision, charging: Bool, plugged: Bool, capabilities: [String: Bool]) -> String {
        if capabilities["charging"] != true && capabilities["native"] != true {
            return "Charge control is not available on this Mac"
        }
        if state.hot {
            return String(format: "Heat Protection: charging paused at %.1f°C", temperature)
        }
        let activity: String
        if let target = decision.dischargeTo {
            activity = "Discharging to \(target)%"
        } else if !plugged {
            activity = "On battery"
        } else if charging {
            activity = "Charging to \(decision.chargeTo)%"
        } else {
            activity = state.sailing ? "Sailing" : "Holding at \(percent)%"
        }
        switch state.mode {
        case .normal: return activity
        case .topUp: return "Top Up · \(activity)"
        case .discharge: return activity
        case .calibration(let stage): return "Calibration step \(stage + 1) of 5 · \(activity)"
        }
    }

    private func powerSource() -> (percent: Int, onAC: Bool)? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        guard let source = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
              let percent = info[kIOPSCurrentCapacityKey] as? Int else { return nil }
        return (percent, info[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue)
    }

    private func lidClosed() -> Bool {
        let root = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        defer { IOObjectRelease(root) }
        return IORegistryEntryCreateCFProperty(root, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool ?? false
    }
}
