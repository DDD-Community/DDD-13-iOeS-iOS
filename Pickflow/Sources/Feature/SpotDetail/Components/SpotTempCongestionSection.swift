import SwiftUI

struct SpotTempCongestionSection: View {
    let weather: SpotWeather

    var body: some View {
        HStack(spacing: 8) {
            metric(title: "현재 기온", value: "\(weather.temperature)℃")
            metric(title: "혼잡도", value: weather.congestion.rawValue)
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .pretendard(.body(.small(.bold)))
                .foregroundStyle(.gray50)
            Text(value)
                .pretendard(.heading(.large))
                .foregroundStyle(.gray0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
