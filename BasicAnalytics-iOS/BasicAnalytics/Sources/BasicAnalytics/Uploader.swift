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
            // TODO: Maybe only send system fields up with one event instead of all of them
            var request = URLRequest(url: configuration.url, timeoutInterval: configuration.uploadTimeout)
            request.httpMethod = "POST"
            request.httpBody = try JSONEncoder().encode(EventsBody(events: events, system: systemFields, trigger: trigger))
            
            let response = try await URLSession.shared.data(for: request)
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
