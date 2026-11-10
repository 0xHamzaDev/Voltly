//
//  Helper.swift
//  Voltly
//
//  Created by David Wernhart on 14.02.20.
//  Copyright © 2020 David Wernhart. All rights reserved.
//

import Foundation
import ServiceManagement

final class Helper {

    static let instance = Helper()

    public var isInitialized:Bool = false
    public var capabilities: [String: Bool] = [:]

    lazy var helperToolConnection: NSXPCConnection = {
        let connection = NSXPCConnection(machServiceName: "com.hamz4.Voltly.Helper.mach", options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperToolProtocol.self)

        connection.resume()
        return connection
    }()

    var proxy: HelperToolProtocol? {
        helperToolConnection.remoteObjectProxyWithErrorHandler {
            let e = $0 as NSError
            print("Remote proxy error \(e.code): \(e.localizedDescription) \(e.localizedRecoverySuggestion ?? "---")")
        } as? HelperToolProtocol
    }

    @objc func installHelper() {
        print("trying to install helper!")
        var status = noErr
        let helperID = "com.hamz4.Voltly.Helper" as CFString // Prefs.helperID as CFString

        var authItem = kSMRightBlessPrivilegedHelper.withCString {
            AuthorizationItem(name: $0, valueLength: 0, value: nil, flags: 0)
        }
        var authRights = withUnsafeMutablePointer(to: &authItem) {
            AuthorizationRights(count: 1, items: $0)
        }
        let authFlags: AuthorizationFlags = [.interactionAllowed, .preAuthorize, .extendRights]
        var authRef: AuthorizationRef?
        status = AuthorizationCreate(&authRights, nil, authFlags, &authRef)
        if status != errAuthorizationSuccess {
            print(SecCopyErrorMessageString(status, nil) ?? "")
            print("Error: \(status)")
        }

        var error: Unmanaged<CFError>?
        SMJobBless(kSMDomainSystemLaunchd, helperID, authRef, &error)
        if let e = error?.takeRetainedValue() {
            print("Domain: ", CFErrorGetDomain(e) ?? "")
            print("Code: ", CFErrorGetCode(e))
            print("UserInfo: ", CFErrorCopyUserInfo(e) ?? "")
            print("Description: ", CFErrorCopyDescription(e) ?? "")
            print("Reason: ", CFErrorCopyFailureReason(e) ?? "")
            print("Suggestion: ", CFErrorCopyRecoverySuggestion(e) ?? "")
        }
        
        if(error == nil){
            print("helper installed successfully!")
            restart()
        }
    }
    
    func restart(){
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        exit(0)
    }
    
    @objc func checkHelperVersion(withReply reply: @escaping (Bool) -> Void) {
        print("checking helper version")
        let helper = helperToolConnection.remoteObjectProxyWithErrorHandler {
            let e = $0 as NSError
            print("Remote proxy error \(e.code): \(e.localizedDescription) \(e.localizedRecoverySuggestion ?? "---")")
            reply(false)
            return()

        } as? HelperToolProtocol

        helper?.getVersion { version in
            print("helperVersion:", helperVersion, " version from helper:", version)
            if !helperVersion.elementsEqual(version) {
                reply(false)
                return()
            }
            else{
                helper?.capabilities { capabilities in
                    DispatchQueue.main.async {
                        self.capabilities = capabilities
                        self.isInitialized = true
                        reply(true)
                    }
                }
            }
        }
    }
}
