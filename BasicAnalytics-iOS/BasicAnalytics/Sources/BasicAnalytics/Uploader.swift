//
//  Uploader.swift
//  
//
//  Created by Joseph Pecoraro on 5/9/23.
//

import Foundation
import os

internal class Uploader : NSObject {
    private var events : [Event] = []
    
    var systemFields : SystemFields = SystemFields.current()
    var configuration : Configuration {
        didSet {
            initializeFromConfig()
        }
    }
    
    var timer : Timer?
    var notificationObservers : [NSObjectProtocol] = []
    
    public init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
        
        initializeFromConfig()
    }
    
    func logEvent(_ event: Event) {
        events.append(event)
        
        Logger.analytics.debug("Event: \(event.eventName ?? "")")
        
        if events.count >= configuration.eventUploadThreshold {
            uploadPendingEvents("Threshold Count: \(events.count)")
        }
    }
    
    private func uploadPendingEvents(_ trigger: String) {
        Logger.analytics.debug("Uploading events from trigger: \(trigger, privacy: .public)")
        Task {
            await uploadPendingEvents(trigger)
        }
    }
    
    private func uploadPendingEvents(_ trigger: String) async {
        let events = self.events
        self.events = []
        
        let count = events.count
        Logger.analytics.debug("Attempting to upload \(count) events")
        
        guard count != 0 else {
            Logger.analytics.debug("No events to upload")
            return
        }
        
        do {
            guard let url = configuration.url.with(queryItems: [URLQueryItem(name: "low-data", value: "true")]) else {
                Logger.analytics.warning("Error appending low-data response to query item")
                return
            }
            
            var request = URLRequest(url: url, timeoutInterval: configuration.uploadTimeout)
            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
            for (key, value) in configuration.httpHeaderFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .iso8601
            let body = try encoder.encode(EventsBody(events: events, system: systemFields, trigger: trigger))
            
            let response = try await URLSession.shared.upload(for: request, from: body)
            logResponse(response)
        } catch {
            Logger.analytics.error("Error while attempting to upload events \(error.localizedDescription, privacy: .public)")
            // TODO: Re-add events?
        }
    }
    
    private func initializeFromConfig() {
        updateNotificationRegistration()
        updateAutoUploadTimer()
    }
    
    private func updateAutoUploadTimer() {
        timer?.invalidate()
        timer = nil
        
        if (configuration.uploadTimerSeconds != 0) {
            let timerSeconds = TimeInterval(configuration.uploadTimerSeconds)
            timer = Timer.scheduledTimer(
                withTimeInterval: timerSeconds,
                repeats: true) { [weak self] timer in
                    self?.uploadPendingEvents("\(timer.debugDescription) \(timer.timeInterval)s")
                }
            
            Logger.analytics.debug("Added upload trigger for timer every \(timerSeconds) seconds")
        }
    }
    
    private func updateNotificationRegistration() {
        // Clear notifications
        notificationObservers.forEach({ observer in
            NotificationCenter.default.removeObserver(observer)
            Logger.analytics.debug("Removed observer \(observer.debugDescription ?? "??", privacy: .public)")
        })
        notificationObservers = []
        
        if configuration.uploadOnBackground {
            addObserverForNotification(Self.willResignActiveNotification)
        }
        
        if configuration.uploadOnForeground {
            addObserverForNotification(Self.didBecomeActiveNotification)
        }
    }
    
    private func addObserverForNotification(_ notification: Notification.Name) {
        notificationObservers.append(
            NotificationCenter.default.addObserver(
                forName: notification,
                object: nil,
                queue: nil,
                using: { self.uploadPendingEvents($0.name.rawValue) })
        )
        
        Logger.analytics.debug("Added upload trigger for notification \(notification.rawValue)")
    }
    
    private func logResponse(_ response: (Data, URLResponse)) {
        let body = String(decoding: response.0, as: UTF8.self)
        var status = "??"
        
        if let httpResponse = response.1 as? HTTPURLResponse {
            status = "\(httpResponse.statusCode)"
        }
        
        Logger.analytics.debug("recieved response: \(status), body: \(body)")
    }
}

#if canImport(UIKit)
import UIKit

extension Uploader {
    static var willResignActiveNotification : NSNotification.Name {
        return UIApplication.willResignActiveNotification
    }
    
    static var didBecomeActiveNotification : NSNotification.Name {
        return UIApplication.didBecomeActiveNotification
    }
    
    static var willTerminateNotification : NSNotification.Name {
        return UIApplication.willTerminateNotification
    }
}

#elseif canImport(AppKit)
import AppKit

extension Uploader {
    static var willResignActiveNotification : NSNotification.Name {
        return NSApplication.willResignActiveNotification
    }
    
    static var didBecomeActiveNotification : NSNotification.Name {
        return NSApplication.didBecomeActiveNotification
    }
    
    static var willTerminateNotification : NSNotification.Name {
        return NSApplication.willTerminateNotification
    }
}

#endif

extension URL {
    /// Returns a new URL by adding the query items, or nil if the URL doesn't support it.
    /// URL must conform to RFC 3986.
    func with(queryItems: [URLQueryItem]) -> URL? {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            // URL is not conforming to RFC 3986 (maybe it is only conforming to RFC 1808, RFC 1738, and RFC 2732)
            return nil
        }
        // append the query items to the existing ones
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems

        // return the url from new url components
        return urlComponents.url
    }
}
