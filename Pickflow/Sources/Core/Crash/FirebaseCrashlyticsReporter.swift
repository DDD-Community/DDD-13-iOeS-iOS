import Foundation
import FirebaseCrashlytics

final class FirebaseCrashlyticsReporter: CrashReporterProtocol, @unchecked Sendable {
    func record(error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }

    func setUserID(_ userID: String?) {
        Crashlytics.crashlytics().setUserID(userID ?? "")
    }
}
