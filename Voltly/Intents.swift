import AppIntents

struct SetChargeLimitIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Charge Limit"

    @Parameter(title: "Limit", inclusiveRange: (20, 100))
    var limit: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        Controller.shared.setLimit(limit)
        return .result()
    }
}

struct TopUpIntent: AppIntent {
    static var title: LocalizedStringResource = "Top Up Battery"

    @MainActor
    func perform() async throws -> some IntentResult {
        Controller.shared.setMode(.topUp)
        return .result()
    }
}

struct DischargeIntent: AppIntent {
    static var title: LocalizedStringResource = "Discharge Battery to Limit"

    @MainActor
    func perform() async throws -> some IntentResult {
        Controller.shared.setMode(.discharge)
        return .result()
    }
}

struct CalibrateIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Battery Calibration"

    @MainActor
    func perform() async throws -> some IntentResult {
        Controller.shared.setMode(.calibration(0))
        return .result()
    }
}

struct ResumeLimitIntent: AppIntent {
    static var title: LocalizedStringResource = "Return to Charge Limit"

    @MainActor
    func perform() async throws -> some IntentResult {
        Controller.shared.setMode(.normal)
        return .result()
    }
}
