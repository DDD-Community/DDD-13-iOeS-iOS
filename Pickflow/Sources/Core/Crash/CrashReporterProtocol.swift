import Foundation

protocol CrashReporterProtocol: Sendable {
    func record(error: Error)
    func setUserID(_ userID: String?)
}

@MainActor
func getCrashReporter() -> CrashReporterProtocol {
    guard let reporter = DIContainerHolder.shared?.resolve(CrashReporterProtocol.self) else {
        fatalError("CrashReporterProtocol is not registered in DIContainer")
    }
    return reporter
}
