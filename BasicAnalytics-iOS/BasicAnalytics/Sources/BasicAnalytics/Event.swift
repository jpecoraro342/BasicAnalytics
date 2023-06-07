//
//  Event.swift
//  
//
//  Created by Joseph Pecoraro on 5/8/23.
//

import Foundation

public struct Event {
    var userIdentifier: String? = nil
    var eventName: String? = nil
    var eventLocation: String? = nil
    // TODO: Change this to String : AnyCodable
    var extras: [String: String] = [:]
    var eventTime: Date = Date()
    var experiments: [String] = []
    
    public init(userIdentifier: String? = nil, eventName: String? = nil, eventLocation: String? = nil, extras: [String : String] = [:], eventTime: Date = Date(), experiments: [String] = []) {
        self.userIdentifier = userIdentifier
        self.eventName = eventName
        self.eventLocation = eventLocation
        self.extras = extras
        self.eventTime = eventTime
        self.experiments = experiments
    }
}

extension Event : Codable {}

struct SystemFields {
    var deviceIdentifier: String?
    var appName: String? = Bundle.main.appName
    var appVersion: String? = Bundle.main.appVersionLong
    var appBuildNumber: String? = Bundle.main.appBuild
    var deviceType: String?
    var os: String?
    var osVersion: String?
}

extension SystemFields : Codable {}

struct EventsBody : Codable {
    let events : [Event]
    let system : SystemFields
    let trigger : String
}

#if canImport(UIKit)

import UIKit

extension SystemFields {
    static func current() -> SystemFields {
        return SystemFields(
            deviceIdentifier: UIDevice.current.identifierForVendor?.uuidString,
            deviceType: UIDevice.current.modelName(),
            os: UIDevice.current.systemName,
            osVersion: UIDevice.current.systemVersion)
    }
}

private extension UIDevice {
    func modelName() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
}

#else

extension SystemFields {
    static func current() -> SystemFields {
        return SystemFields(
            deviceIdentifier: hardwareUUID(),
            deviceType: nil,
            os: "MacOs",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString)
    }
}

private func hardwareUUID() -> String? {
    let matchingDict = IOServiceMatching("IOPlatformExpertDevice")
    let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict)
    defer{ IOObjectRelease(platformExpert) }

    guard platformExpert != 0 else { return nil }
    return IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String
}

#endif

private extension Bundle {
    var appName: String           { getInfo("CFBundleName")  }
    var appBuild: String          { getInfo("CFBundleVersion") }
    var appVersionLong: String    { getInfo("CFBundleShortVersionString") }
    
    private func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}
