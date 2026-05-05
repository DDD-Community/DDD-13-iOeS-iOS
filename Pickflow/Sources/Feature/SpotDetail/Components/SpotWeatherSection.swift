import SwiftUI

struct SpotWeatherSection: View {
    let weather: SpotWeather

    var body: some View {
        HStack(spacing: 8) {
            metric(title: "오늘 날씨", value: weather.condition.rawValue)
            metric(title: "강수 확률", value: "\(weather.precipitationProbability)%")
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
