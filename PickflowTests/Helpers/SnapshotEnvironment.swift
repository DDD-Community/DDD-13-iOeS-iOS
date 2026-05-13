import SwiftUI

extension View {
    /// Phase C 가이드의 고정값(언어/지역/DynamicType/ColorScheme)을 한 번에 적용하는 헬퍼.
    /// 디바이스/사이즈는 assertSnapshot의 layout 인자로 별도 지정.
    func snapshotEnvironment(
        colorScheme: ColorScheme,
        dynamicType: DynamicTypeSize = .large,
        locale: Locale = Locale(identifier: "ko_KR")
    ) -> some View {
        self
            .environment(\.colorScheme, colorScheme)
            .environment(\.locale, locale)
            .dynamicTypeSize(dynamicType)
    }
}
