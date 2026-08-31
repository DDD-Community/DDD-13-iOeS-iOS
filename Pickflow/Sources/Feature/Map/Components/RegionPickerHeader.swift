import SwiftUI

/// PICKFLOW 워드마크 옆에 현재 선택된 지역명을 붙여 노출하는 헤더. 탭하면 지역 선택 바텀시트가 뜬다.
struct RegionPickerHeader: View {
    let regionName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                PickflowWorkMarkLogo()
                if !regionName.isEmpty {
                    Text(regionName)
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RegionPickerHeader(regionName: "대전") {}
        .padding()
        .background(Color.black)
}
