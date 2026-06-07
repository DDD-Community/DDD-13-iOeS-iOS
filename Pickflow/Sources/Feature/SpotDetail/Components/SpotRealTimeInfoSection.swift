import SwiftUI

struct SpotRealTimeInfoSection: View {
    let spot: SpotDetail
    @State private var isCongestionInfoPresented = false
    // 풀스크린 커버 기본 슬라이드업 대신 fade in/out 으로 보이도록
    // 커버 표시 애니메이션은 끄고 내부 콘텐츠 opacity 로 페이드를 제어한다.
    @State private var showCongestionCover = false
    @State private var congestionContentVisible = false

    private var isMine: Bool { spot.isMySpot }

    private func presentCongestionCover() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { showCongestionCover = true }
    }

    private func dismissCongestionCover() {
        guard showCongestionCover else { return }
        withAnimation(.easeInOut(duration: 0.2)) { congestionContentVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { showCongestionCover = false }
        }
    }

    private var realtimeDescriptionText: AttributedString {
        var str = AttributedString("공공 API를 활용한 실시간 정보를 확인해 보세요")
        if let range = str.range(of: "실시간 정보") {
            str[range].foregroundColor = UIAsset.Colors.sunsetOrange.swiftUIColor
        }
        return str
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(realtimeDescriptionText)
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray0)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("\(spot.sunsetTime.map { DateFormatter.pickflowDisplayTime(from: $0) } ?? "-") 기준 정보입니다.")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(alignment: .leading, spacing: 36) {
                    infoRow(
                        iconName: "icSunny",
                        label: "현재 날씨",
                        value: spot.weatherDisplayName ?? "-",
                        sub: spot.precipitationProbability.map { "강수확률 \($0)%" } ?? "강수확률 -"
                    )
                    infoRow(
                        iconName: "icTwilight",
                        label: "일몰 시간",
                        value: spot.sunsetTime.map { DateFormatter.pickflowDisplayTime(from: $0) } ?? "-",
                        sub: "오차 시간"
                    )
                    infoRow(
                        iconName: "icLocalParking",
                        label: "주차 관련",
                        value: isMine ? "-" : (spot.parkingInfo ?? "-"),
                        sub: nil,
                        multiline: true
                    )
                    congestionRow
                }
            }
            .padding(16)
            .background(.gray90)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .onChange(of: isCongestionInfoPresented) { _, presented in
            if presented { presentCongestionCover() } else { dismissCongestionCover() }
        }
        .fullScreenCover(isPresented: $showCongestionCover, onDismiss: { congestionContentVisible = false }) {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { isCongestionInfoPresented = false }
                CongestionInfoPopup { isCongestionInfoPresented = false }
                    .padding(.horizontal, 24)
            }
            .opacity(congestionContentVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.2)) { congestionContentVisible = true }
            }
            .presentationBackground(.clear)
        }
    }

    private static let whiteIconNames: Set<String> = ["icSunny", "icTwilight"]

    private func infoRow(iconName: String, label: String, value: String, sub: String?, multiline: Bool = false) -> some View {
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
                        .lineLimit(multiline ? 2 : 1)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: multiline ? .infinity : nil, alignment: .leading)
                    if let sub {
                        Text(sub)
                            .pretendard(.body(.medium(.bold)))
                            .foregroundStyle(.gray50)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 54)
    }

    private var congestionRow: some View {
        HStack(spacing: 12) {
            iconContainer(named: "icPeople")
            VStack(alignment: .leading, spacing: 2) {
                Text("혼잡도")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
                HStack(spacing: 6) {
                    Text(isMine ? "-" : (spot.congestionLevel?.displayName ?? "-"))
                        .pretendard(.heading(.large))
                        .foregroundStyle(.gray0)
                    Button {
                        isCongestionInfoPresented = true
                    } label: {
                        AssetImage(named: "icHelpOutline", size: 20) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(.gray50)
                        }
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
