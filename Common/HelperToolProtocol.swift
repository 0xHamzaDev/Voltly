//
//  HelperToolProtocol.swift
//  Voltly
//
//  Created by David Wernhart on 13.02.20.
//  Copyright © 2020 David Wernhart. All rights reserved.
//

import Foundation

let helperVersion: String = "11" //for some reason the integrated version check does not work, so I use this one

@objc(HelperToolProtocol) protocol HelperToolProtocol {
//protocol HelperToolProtocol {
    func getVersion(withReply reply: @escaping (String) -> Void)
    func capabilities(withReply reply: @escaping ([String: Bool]) -> Void)

    func setCharging(_ enabled: Bool)
    func setNativeLimit(_ limit: Int)
    func setAdapter(_ enabled: Bool)
    func setLED(_ value: UInt8)
    func setLowPowerMode(_ enabled: Bool)
    func batteryTemperature(withReply reply: @escaping (Double) -> Void)

    func setBCLM(_ value: UInt8)
    func reset()
}
