//
//  OSLogProvider.swift
//  Coach
//
//  Created by Allen Liang on 3/4/25.
//

import Foundation
import os.log


struct OSLogProvider: LoggerProvider {
    private let logger: Logger
    
    init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.allenliang.Coach", category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.debug("[\(file.split(separator: "/").last ?? ""):\(line)] \(message)")
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.info("[\(file.split(separator: "/").last ?? ""):\(line)] \(message)")
    }
    
    func notice(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.notice("[\(file.split(separator: "/").last ?? ""):\(line)] \(message)")
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.warning("[\(file.split(separator: "/").last ?? ""):\(line)] \(message)")
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.error("[\(file.split(separator: "/").last ?? ""):\(line)] \(message)")
    }
    
    
}
