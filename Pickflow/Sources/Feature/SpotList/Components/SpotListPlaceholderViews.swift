import SwiftUI

struct SpotListLoadingView: View {
    var body: some View {
        // 스켈레톤 6개 placeholder. FIXME(Figma): 실제 스켈레톤 디자인 확정 시 교체.
        HStack(alignment: .top, spacing: 12) {
            column(aspects: [1.2, 0.9, 1.1])
            column(aspects: [0.9, 1.2, 0.9])
        }
        .padding(.horizontal, 16)
    }

    private func column(aspects: [CGFloat]) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(aspects.enumerated()), id: \.offset) { _, aspect in
                RoundedRectangle(cornerRadius: 12)
                    .fill(UIAsset.Colors.gray90.swiftUIColor)
                    .aspectRatio(1.0 / aspect, contentMode: .fit)
            }
        }
    }
}

struct SpotListEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            // FIXME(Figma): 전용 일러스트 확정 전 SF Symbol 임시 사용
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.gray40)
            Text("조건에 맞는 스팟이 없어요")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.gray0)
                .multilineTextAlignment(.center)
            Text("필터를 조정해 보세요.")
                .pretendard(.body(.small()))
                .foregroundStyle(.gray50)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SpotListFailedView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(.icErrorOutline)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(.gray40)
            Text("스팟을 불러오지 못했어요")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.gray0)
            Text(message)
                .pretendard(.body(.small()))
                .foregroundStyle(.gray50)
                .multilineTextAlignment(.center)
            Button("다시 시도", action: onRetry)
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(UIAsset.Colors.sunsetOrange.swiftUIColor)
                .clipShape(Capsule())
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SpotListUnauthorizedLocationView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(.icLocationOn)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(.gray40)
            Text("위치 권한이 필요해요")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.gray0)
                .multilineTextAlignment(.center)
            Text("가까운 스팟을 보여드리려면\n위치 권한 허용이 필요합니다.")
                .pretendard(.body(.small()))
                .foregroundStyle(.gray50)
                .multilineTextAlignment(.center)
            Button("설정으로 이동", action: onOpenSettings)
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(UIAsset.Colors.sunsetOrange.swiftUIColor)
                .clipShape(Capsule())
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
