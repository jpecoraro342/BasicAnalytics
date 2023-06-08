import Foundation
import os

public class Analytics {
    
    var uploader : Uploader?
    
    public static let shared = Analytics()
    
    private init() {}
    
    public func initialize(_ configuration: Configuration) {
        uploader = Uploader(configuration: configuration)
    }
    
    public func initialize(_ url: URL) {
        uploader = Uploader(configuration: Configuration(url: url))
    }
    
    public func logEvent(_ event: Event) {
        guard let uploader = uploader else {
            Logger.analytics.error("Failed to log event: \(event.eventName ?? ""). Please initialize the analytics library with Analytics.shared.initialize() to log events")
            return
        }
        
        uploader.logEvent(event)
    }
    
    public func logEvent(_ eventName: String) {
        logEvent(Event(eventName: eventName))
    }
}

public struct Configuration {
    var url: URL
    var httpHeaderFields : [String : String?] = [:]
    var uploadOnBackground = true
    var uploadOnForeground = true
    var eventUploadThreshold = 40
    var uploadTimeout = 10.0
    var tempFileName: String? = nil
    /// 0 to disable upload on a timer
    var uploadTimerSeconds = 120
    var enableSystemFields = true
    
    public init(url: URL, httpHeaderFields: [String : String?] = [:], uploadOnBackground: Bool = true, uploadOnForeground: Bool = true, eventUploadThreshold: Int = 40, uploadTimeout: Double = 10.0, tempFileName: String? = nil, uploadTimerSeconds: Int = 120, enableSystemFields: Bool = true) {
        self.url = url
        self.httpHeaderFields = httpHeaderFields
        self.uploadOnBackground = uploadOnBackground
        self.uploadOnForeground = uploadOnForeground
        self.eventUploadThreshold = eventUploadThreshold
        self.uploadTimeout = uploadTimeout
        self.tempFileName = tempFileName
        self.uploadTimerSeconds = uploadTimerSeconds
        self.enableSystemFields = enableSystemFields
    }
}
