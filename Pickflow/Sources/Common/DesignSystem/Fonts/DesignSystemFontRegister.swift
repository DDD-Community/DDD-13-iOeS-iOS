import UIKit

enum DesignSystemFontRegister {
    private static let fontFileNames = [
        "Pretendard-Regular.otf",
        "Pretendard-Medium.otf",
        "Pretendard-SemiBold.otf",
        "Pretendard-Bold.otf",
    ]

    static func registerAllCustomFonts() {
        fontFileNames.forEach(registerFontIfNeeded(named:))
    }

    private static func registerFontIfNeeded(named fileName: String) {
        let displayName = fileName.replacingOccurrences(of: ".otf", with: "")

        guard let fontURL = Bundle.module.url(forResource: fileName, withExtension: nil) else {
            print("\(displayName) 등록 실패")
            return
        }

        guard let dataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(dataProvider),
              let postScriptName = font.postScriptName as String? else {
            print("\(displayName) 등록 실패")
            return
        }

        if UIFont(name: postScriptName, size: 12) != nil {
            print("\(displayName) 등록 성공")
            return
        }

        let didRegister = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        print("\(displayName) 등록 \(didRegister ? "성공" : "실패")")
    }
}
