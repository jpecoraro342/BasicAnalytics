//
//  Uploader.swift
//  
//
//  Created by Joseph Pecoraro on 5/9/23.
//

import Foundation

class Uploader : NSObject {
    
    var systemFields : SystemFields = SystemFields.current()
    
    public override init() {
        super.init()
        self.registerForNotifications()
    }
    
    private func uploadPendingEvents() {
        
    }
    
    private func didEnterBackground() {
        print("Did enter background")
    }
    
    private func willEnterForeground() {
        print("will enter foreground")
    }
    
    @objc private func willResignActive() {
        print("will resign active")
    }
    
    @objc private func didBecomeActive() {
        print("did become active")
    }
    
    @objc private func willTerminate() {
        print("will terminate")
    }
}

#if canImport(UIKit)
import UIKit

extension Uploader {
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate), name: UIApplication.willTerminate, object: nil)
    }
}

#elseif canImport(AppKit)
import AppKit

extension Uploader {
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: NSApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate), name: NSApplication.willTerminateNotification, object: nil)
    }
}

#endif
