//
//  Log.swift
//  riidaa
//

import Foundation
import os

extension Logger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "dev.repierre.riidaa"

    static let database = Logger(subsystem: subsystem, category: "database")
    static let dictionary = Logger(subsystem: subsystem, category: "dictionary")
    static let library = Logger(subsystem: subsystem, category: "library")
    static let reader = Logger(subsystem: subsystem, category: "reader")
    static let anki = Logger(subsystem: subsystem, category: "anki")

}
