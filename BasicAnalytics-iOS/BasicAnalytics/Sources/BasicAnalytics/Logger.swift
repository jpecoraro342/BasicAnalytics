//
//  Logger.swift
//  
//
//  Created by Joseph Pecoraro on 5/11/23.
//

import Foundation
import os

internal extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let analytics = Logger(subsystem: subsystem, category: "BasicAnalytics")
}
