//
//  HelperTool.swift
//  com.hamz4.Voltly.Helper
//
//  Created by David Wernhart on 13.02.20.
//  Copyright © 2020 David Wernhart. All rights reserved.
//

import Foundation
import notify

private enum PowerUI {
    private typealias ErrorPointer = AutoreleasingUnsafeMutablePointer<NSError?>

    private static let client: NSObject? = {
        guard dlopen("/System/Library/PrivateFrameworks/PowerUI.framework/Versions/A/PowerUI", RTLD_NOW) != nil,
              let cls = NSClassFromString("PowerUISmartChargeClient") as? NSObject.Type,
              let allocated = cls.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue() as? NSObject,
              allocated.responds(to: NSSelectorFromString("initWithClientName:")),
              let instance = allocated.perform(NSSelectorFromString("initWithClientName:"), with: "Voltly")?.takeUnretainedValue() as? NSObject
        else { return nil }
        let required = ["isMCLSupported", "getMCLLimitWithError:", "setMCLLimit:error:", "isMCLCurrentlyEnabled:", "disableMCL:"]
        return required.allSatisfy { instance.responds(to: NSSelectorFromString($0)) } ? instance : nil
    }()

    private static let domain = "com.apple.smartcharging.topoffprotection" as CFString

    static var supported: Bool {
        guard let client else { return false }
        let selector = NSSelectorFromString("isMCLSupported")
        typealias Function = @convention(c) (NSObject, Selector) -> Bool
        return unsafeBitCast(client.method(for: selector), to: Function.self)(client, selector)
    }

    private static var acceptsExactTargets: Bool {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27
            && client?.responds(to: NSSelectorFromString("enableMCL:")) == true
    }

    private static func run(_ name: String) -> Bool {
        guard let client else { return false }
        let selector = NSSelectorFromString(name)
        typealias Function = @convention(c) (NSObject, Selector, ErrorPointer) -> Bool
        var error: NSError?
        return unsafeBitCast(client.method(for: selector), to: Function.self)(client, selector, &error) && error == nil
    }

    static var limit: Int? {
        guard let client else { return nil }
        var error: NSError?
        let enabledSelector = NSSelectorFromString("isMCLCurrentlyEnabled:")
        typealias EnabledFunction = @convention(c) (NSObject, Selector, ErrorPointer) -> UInt64
        let enabled = unsafeBitCast(client.method(for: enabledSelector), to: EnabledFunction.self)(client, enabledSelector, &error)
        guard error == nil else { return nil }
        guard enabled != 0 else { return 100 }
        let limitSelector = NSSelectorFromString("getMCLLimitWithError:")
        typealias LimitFunction = @convention(c) (NSObject, Selector, ErrorPointer) -> UInt8
        let value = unsafeBitCast(client.method(for: limitSelector), to: LimitFunction.self)(client, limitSelector, &error)
        return error == nil ? Int(value) : nil
    }

    static func setLimit(_ limit: Int) {
        guard let client, supported else { return }
        guard limit < 100 else {
            _ = run("disableMCL:")
            return
        }
        guard acceptsExactTargets else {
            let selector = NSSelectorFromString("setMCLLimit:error:")
            typealias Function = @convention(c) (NSObject, Selector, UInt8, ErrorPointer) -> Bool
            var error: NSError?
            _ = unsafeBitCast(client.method(for: selector), to: Function.self)(client, selector, UInt8(limit), &error)
            return
        }
        if self.limit == 100 {
            _ = run("enableMCL:")
        }
        CFPreferencesSetValue("MCLFeatureState" as CFString, 1 as CFNumber, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesSetValue("mclLimitValue" as CFString, limit as CFNumber, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        notify_post("com.apple.smartcharging.defaultschanged")
    }
}

final class HelperTool: NSObject, HelperToolProtocol {

    static let instance = HelperTool()

    private let smcOpened = (try? SMCKit.open()) != nil
    private var originalNativeLimit: Int?
    private var originalBCLM: UInt8?

    private lazy var hasDirectCharging = writable("CHTE") || (writable("CH0B") && writable("CH0C"))
    private lazy var adapterKey = ["CH0I", "CH0J", "CHIE"].first(where: writable)

    private func key(_ name: String) -> SMCKey? {
        guard smcOpened, name.utf8.count == 4 else { return nil }
        let code = FourCharCode(fromString: name)
        guard let info = try? SMCKit.keyInformation(code), info.size > 0 else { return nil }
        return SMCKey(code: code, info: info)
    }

    private func read(_ name: String) -> [UInt8]? {
        guard let key = key(name), let data = try? SMCKit.readData(key) else { return nil }
        return withUnsafeBytes(of: data) { Array($0.prefix(Int(key.info.size))) }
    }

    @discardableResult
    private func write(_ name: String, _ values: [UInt8]) -> Bool {
        guard let key = key(name) else { return false }
        var data = SMCParamStruct().bytes
        withUnsafeMutableBytes(of: &data) { $0.copyBytes(from: values.prefix($0.count)) }
        return (try? SMCKit.writeData(key, data: data)) != nil
    }

    private func writable(_ name: String) -> Bool {
        guard let current = read(name) else { return false }
        return write(name, current)
    }

    func getVersion(withReply reply: (String) -> Void) {
//        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString" as String) as? String ?? "(unknown version)"
//        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "(unknown build)"
//        reply("v\(version) (\(build))")
        reply(helperVersion)

    }

    func capabilities(withReply reply: @escaping ([String: Bool]) -> Void) {
        reply([
            "charging": hasDirectCharging,
            "native": !hasDirectCharging && PowerUI.supported,
            "adapter": adapterKey != nil,
            "led": writable("ACLC"),
        ])
    }

    func setCharging(_ enabled: Bool) {
        if read("CHTE") != nil {
            write("CHTE", [enabled ? 0 : 1, 0, 0, 0])
        } else {
            write("CH0B", [enabled ? 0 : 2])
            write("CH0C", [enabled ? 0 : 2])
        }
    }

    func setNativeLimit(_ limit: Int) {
        guard !hasDirectCharging else { return }
        if originalNativeLimit == nil {
            originalNativeLimit = PowerUI.limit
        }
        guard originalNativeLimit != nil else { return }
        PowerUI.setLimit(min(max(limit, 10), 100))
    }

    func setAdapter(_ enabled: Bool) {
        guard let adapterKey else { return }
        write(adapterKey, [enabled ? 0 : (adapterKey == "CHIE" ? 8 : 1)])
    }

    func setLED(_ value: UInt8) {
        guard [0, 1, 3, 4].contains(value) else { return }
        write("ACLC", [value])
    }

    func setLowPowerMode(_ enabled: Bool) {
        let pmset = Process()
        pmset.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        pmset.arguments = ["-a", "lowpowermode", enabled ? "1" : "0"]
        try? pmset.run()
    }

    func batteryTemperature(withReply reply: @escaping (Double) -> Void) {
        guard let bytes = read("TB0T"), bytes.count >= 2 else { return reply(0) }
        if bytes.count == 4 {
            let bits = UInt32(bytes[0]) | UInt32(bytes[1]) << 8 | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
            reply(Double(Float(bitPattern: bits)))
        } else {
            reply(Double(Int8(bitPattern: bytes[0])) + Double(bytes[1]) / 256)
        }
    }

    func setBCLM(_ value: UInt8) {
        if originalBCLM == nil {
            originalBCLM = read("BCLM")?.first
        }
        write("BCLM", [min(max(value, 20), 100)])
    }

    func reset(){
        if hasDirectCharging {
            setCharging(true)
        }
        setAdapter(true)
        setLED(0)
        if let originalNativeLimit {
            PowerUI.setLimit(originalNativeLimit)
        }
        if let originalBCLM {
            write("BCLM", [originalBCLM])
        }
        originalNativeLimit = nil
        originalBCLM = nil
    }
}
