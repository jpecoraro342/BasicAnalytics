//
//  Event.swift
//  
//
//  Created by Joseph Pecoraro on 5/8/23.
//

import Foundation

public protocol Event {
    var userIdentifier: String? { get }
    var eventName: String? { get }
    var eventLocation: String? { get }
    var extras: [String: Any] { get }
    var eventTime: Date { get }
    var experiments: [String] { get }
}

extension Event {
    var userIdentifier: String? { return nil }
    var eventName: String? { return nil }
    var eventLocation: String? { return nil }
    var extras: [String: Any] { return [:] }
    var eventTime: Date { return Date() }
    var experiments: [String] { return [] }
}

struct SystemFields {
    let deviceIdentifier: String?
    let appName: String? = Bundle.main.appName
    let appVersion: String? = Bundle.main.appVersionLong
    let appBuildNumber: String? = Bundle.main.appBuild
    let deviceType: String?
    let os: String?
    let osVersion: String?
}

#if canImport(UIKit)

import UIKit

extension SystemFields {
    static func current() -> SystemFields {
        return SystemFields(
            deviceIdentifier: UIDevice.current.identifierForVender?.uuidString,
            deviceType: UIDevice.current.modelName,
            os: UIDevice.current.systemName,
            osVersion: UIDevice.current.systemVersion)
    }
}

private extension UIDevice {
    let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }()
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
