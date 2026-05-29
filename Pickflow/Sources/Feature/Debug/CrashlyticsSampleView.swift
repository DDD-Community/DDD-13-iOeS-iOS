#if DEBUG
import SwiftUI
import FirebaseCrashlytics

struct CrashlyticsSampleView: View {
    private let reporter: CrashReporterProtocol
    @State private var lastRecorded: String?
    @State private var showCrashConfirm = false

    init(reporter: CrashReporterProtocol = getCrashReporter()) {
        self.reporter = reporter
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Crashlytics 테스트")
                .font(.title2.bold())

            Button("Non-fatal 에러 기록") {
                let error = NSError(
                    domain: "com.pickflow.debug",
                    code: 9999,
                    userInfo: [NSLocalizedDescriptionKey: "테스트용 non-fatal 에러"]
                )
                reporter.record(error: error)
                lastRecorded = "non-fatal 에러 전송 완료"
            }
            .buttonStyle(.borderedProminent)

            Button("강제 크래시 발생") {
                showCrashConfirm = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            if let lastRecorded {
                Text(lastRecorded)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text("크래시 발생 후 앱을 재실행해야 Firebase Console에 리포트가 올라갑니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .confirmationDialog("정말 크래시를 발생시킬까요?", isPresented: $showCrashConfirm, titleVisibility: .visible) {
            Button("크래시 발생", role: .destructive) {
                Crashlytics.crashlytics().crash()
            }
            Button("취소", role: .cancel) {}
        }
    }
}
#endif
