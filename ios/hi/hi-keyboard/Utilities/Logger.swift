import os
import Sentry

enum LogLevel: String {
    case debug, info, warning, error, fatal
    
    var sentryLevel: SentryLevel {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .fatal: return .fatal
        }
    }
}

enum LogCategory: String {
    case general, app, keyboard
}

enum HiLogger {
    private static let subsystem = "ai.havingfunwith.hi"
    
    // MARK: - Initialization (call once at app launch)
    
    static func configure() {
        // #if !DEBUG
        SentrySDK.start { options in
            options.dsn = "https://14be289d0d7ecafc27ee7e0dc2d92c77@o4510544121757696.ingest.de.sentry.io/4510544154918992"
            options.environment = "production"
            options.enableAutoSessionTracking = true
            options.attachStacktrace = true
            options.sendDefaultPii = true
            // Sample 100% of errors, 20% of transactions, 20% profiling
            options.sampleRate = 1.0
            options.tracesSampleRate = 0.2
            options.configureProfiling = {
                $0.sessionSampleRate = 0.2
                $0.lifecycle = .trace
            }
            options.experimental.enableLogs = true
        }
        // #endif
    }
    
    // MARK: - Logging Methods
    
    static func debug(_ message: String, category: LogCategory = .general) {
        log(message, level: .debug, category: category)
    }
    
    static func info(_ message: String, category: LogCategory = .general) {
        log(message, level: .info, category: category)
    }
    
    static func warning(_ message: String, category: LogCategory = .general) {
        log(message, level: .warning, category: category)
    }
    
    static func error(_ message: String, error: Error? = nil, category: LogCategory = .general) {
        log(message, error: error, level: .error, category: category)
        
        // #if !DEBUG
        if let error = error {
            SentrySDK.capture(error: error)
        }
        // #endif
    }
    
    static func fatal(_ message: String, error: Error? = nil, category: LogCategory = .general) {
        log(message, error: error, level: .fatal, category: category)
        
        // #if !DEBUG
        if let error = error {
            SentrySDK.capture(error: error)
        }
        // #endif
    }
    
    // MARK: - Performance Tracking
    
    static func startTransaction(name: String, operation: String) -> Span? {
        // #if !DEBUG
        return SentrySDK.startTransaction(name: name, operation: operation)
        // #else
        return nil
        // #endif
    }
    
    // MARK: - Private
    
    private static func log(_ message: String, error: Error? = nil, level: LogLevel, category: LogCategory) {
        // Always log to console (visible in Xcode)
        let osLog = Logger(subsystem: subsystem, category: category.rawValue)
        switch level {
        case .debug: osLog.debug("\(message)")
        case .info: osLog.info("\(message)")
        case .warning: osLog.warning("\(message)")
        case .error: osLog.error("\(message): \(error?.localizedDescription ?? "")")
        case .fatal: osLog.fault("\(message): \(error?.localizedDescription ?? "")")
        }
        
        // #if !DEBUG
        let breadcrumb = Breadcrumb(level: level.sentryLevel, category: category.rawValue)
        breadcrumb.message = message
        SentrySDK.addBreadcrumb(breadcrumb)
        // #endif
    }
}
