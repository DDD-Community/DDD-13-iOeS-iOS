import os

enum Log {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pickflow.app", category: "Pickflow")

    static func debug(_ message: String) {
        logger.debug("\(message)")
    }

    static func info(_ message: String) {
        logger.info("\(message)")
    }

    static func error(_ message: String) {
        logger.error("\(message)")
    }
}
