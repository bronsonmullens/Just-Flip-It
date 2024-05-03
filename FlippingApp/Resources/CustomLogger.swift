//
//  CustomLogger.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import Foundation
import OSLog

public let log = Logger(subsystem: "com.bronsonmullens.Just-Flip-It", category: "Main")

extension Logger {
    func info(_ message: String) {
        self.log(level: .info, "🟦 \(message)")
    }

    func debug(_ message: String) {
        self.log(level: .debug, "🟩 \(message)")
    }

    func error(_ message: String) {
        self.log(level: .error, "🟥 \(message)")
    }
}
