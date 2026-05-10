import SwiftUI

struct SpotRealTimeInfoSection: View {
    let weather: SpotWeather
    let isMine: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("공공 API를 활용한 실시간 정보를 확인해 보세요")
                .pretendard(.body(.medium()))
                .foregroundStyle(.sunsetOrange)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(DateFormatter.pickflowDisplayTime(from: weather.sunsetTime)) 기준 정보입니다.")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 8)

                infoRow(
                    iconName: "icSunny",
                    label: "현재 날씨",
                    value: weather.condition.rawValue,
                    sub: "강수확률 \(weather.precipitationProbability)%"
                )
                infoRow(
                    iconName: "icTwilight",
                    label: "일몰 시간",
                    value: DateFormatter.pickflowDisplayTime(from: weather.sunsetTime),
                    sub: "오차 시간"
                )
                infoRow(
                    iconName: "icLocalParking",
                    label: "주차 관련",
                    value: isMine ? "-" : (weather.parking ?? "-"),
                    sub: nil
                )
                congestionRow
            }
            .padding(16)
            .background(.gray90)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private static let whiteIconNames: Set<String> = ["icSunny", "icTwilight"]

    private func infoRow(iconName: String, label: String, value: String, sub: String?) -> some View {
        HStack(spacing: 12) {
            iconContainer(named: iconName, white: Self.whiteIconNames.contains(iconName))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
                HStack(spacing: 6) {
                    Text(value)
                        .pretendard(.heading(.large))
                        .foregroundStyle(.gray0)
                    if let sub {
                        Text(sub)
                            .pretendard(.body(.medium()))
                            .foregroundStyle(.gray50)
                    }
                }
            }
            Spacer()
        }
        .frame(height: 54)
    }

    private var congestionRow: some View {
        HStack(spacing: 12) {
            iconContainer(named: "icPeople")
            VStack(alignment: .leading, spacing: 2) {
                Text("혼잡도")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
                HStack(spacing: 6) {
                    Text(isMine ? "-" : weather.congestion.rawValue)
                        .pretendard(.heading(.large))
                        .foregroundStyle(.gray0)
                    AssetImage(named: "icHelpOutline", size: 20) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(.gray50)
                    }
                }
            }
            Spacer()
        }
        .frame(height: 54)
    }

    private func iconContainer(named: String, white: Bool = false) -> some View {
        AssetImage(named: named, renderingMode: white ? .template : .original, size: 36) {
            Rectangle()
                .fill(.gray90)
                .frame(width: 36, height: 36)
        }
        .foregroundStyle(.gray0)
        .frame(width: 54, height: 54)
    }
}
