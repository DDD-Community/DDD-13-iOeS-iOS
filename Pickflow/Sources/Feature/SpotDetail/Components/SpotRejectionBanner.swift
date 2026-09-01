import SwiftUI

/// 반려된 내 스팟 상세 최상단에 붙는 사유 배너.
struct SpotRejectionBanner: View {
    let rejection: SpotRejectionInfo
    let onWithdraw: () -> Void
    let onResubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if let rejectedAt = formattedRejectedAt {
                        Text(rejectedAt)
                    }
                    Text("반려됨")
                }
                .pretendard(.body(.small()))
                .foregroundStyle(UIAsset.Colors.gray30.swiftUIColor)

                Text(message)
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                Button(action: onWithdraw) {
                    Text("스팟 오픈 철회")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray80.swiftUIColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(UIAsset.Colors.gray0.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: onResubmit) {
                    Text("수정 후 재신청")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(UIAsset.Colors.sunsetOrange.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(UIAsset.Colors.gray90.swiftUIColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.spotRejectionOverlay.opacity(0.12))
                }
        }
    }

    /// 서버가 안내 문구를 내려주면 그대로 쓰고, 없으면 사유 라벨로 대체한다.
    private var message: String {
        rejection.guideMessage ?? rejection.reasonLabel ?? "오픈 신청이 반려되었어요."
    }

    private var formattedRejectedAt: String? {
        guard let raw = rejection.rejectedAt else { return nil }
        return SpotRejectionDate.display(raw)
    }
}

/// 반려 시각 표기. "2026-07-21T10:00:00Z" → "26.07.21"
/// 파싱에 실패하면 원문을 그대로 보여준다(빈 줄보다는 낫다).
enum SpotRejectionDate {
    private nonisolated(unsafe) static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .korean
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yy.MM.dd"
        return formatter
    }()

    private nonisolated(unsafe) static let parsers: [ISO8601DateFormatter] = {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return [plain, withFraction]
    }()

    static func display(_ iso8601: String) -> String {
        for parser in parsers {
            if let date = parser.date(from: iso8601) {
                return display.string(from: date)
            }
        }
        return iso8601
    }
}
