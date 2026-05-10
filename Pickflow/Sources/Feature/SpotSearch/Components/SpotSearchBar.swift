import SwiftUI
import UIKit

struct SpotSearchBar: View {
    @Binding var text: String
    let searchAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("장소의 키워드를 입력해 주세요.")
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray50.color)
                }

                KeyboardStableTextField(text: $text, submitAction: searchAction)
                    .frame(maxWidth: .infinity, minHeight: 24)
            }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    AssetImage(named: "ic_close", renderingMode: .original, size: 24) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .frame(width: 24, height: 24)
                            .foregroundStyle(UIAsset.Colors.gray50.color)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색어 지우기")
            }

            Button(action: searchAction) {
                AssetImage(named: "ic_search", renderingMode: .template, size: 24) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .foregroundStyle(UIAsset.Colors.gray0.color)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("검색")
        }
        .padding(16)
        .frame(height: 56)
        .background(UIAsset.Colors.gray90.color, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct KeyboardStableTextField: UIViewRepresentable {
    @Binding var text: String
    let submitAction: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.tintColor = .systemBlue
        textField.textColor = UIColor(named: "gray0") ?? .white
        textField.font = UIFont(name: PretendardFontName.semiBold, size: 15)
            ?? .systemFont(ofSize: 15, weight: .semibold)
        textField.returnKeyType = .search
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.enablesReturnKeyAutomatically = false
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != text {
            textField.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, submitAction: submitAction)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String
        private let submitAction: () -> Void

        init(text: Binding<String>, submitAction: @escaping () -> Void) {
            _text = text
            self.submitAction = submitAction
        }

        @objc
        func textDidChange(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            submitAction()
            return false
        }
    }
}
