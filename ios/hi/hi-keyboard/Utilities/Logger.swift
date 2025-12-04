import os

/// Unified logger for the keyboard extension
enum HiLogger {
    private static let subsystem = "ai.havingfunwith.hi.keyboard"
    
    static let general = Logger(subsystem: subsystem, category: "general")
    static let api = Logger(subsystem: subsystem, category: "api")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}

