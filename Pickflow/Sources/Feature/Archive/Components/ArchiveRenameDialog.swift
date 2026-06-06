import SwiftUI

struct ArchiveRenameDialog: View {
    @Binding var isPresented: Bool
    let initialName: String
    let onSave: (String) -> Void

    @State private var name: String = ""
    private let maxLength = 15

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    // 변경 사항이 있고(=초기 이름과 다르고) 비어있지 않을 때만 저장 활성화
    private var isSaveEnabled: Bool {
        !trimmedName.isEmpty && trimmedName != initialName.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 16) {
                Text("보관함 이름 변경")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray0)

                HStack {
                    TextField("보관함 이름", text: $name)
                        .pretendard(.body(.medium()))
                        .foregroundStyle(.gray0)
                        .onChange(of: name) { _, new in
                            if new.count > maxLength { name = String(new.prefix(maxLength)) }
                        }
                    Spacer(minLength: 8)
                    (Text("\(name.count)")
                        .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                        + Text("/\(maxLength)")
                        .foregroundStyle(UIAsset.Colors.gray50.swiftUIColor))
                        .pretendard(.body(.small()))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(UIAsset.Colors.gray80.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 8) {
                    Button("취소") { isPresented = false }
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray80.swiftUIColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .buttonStyle(.plain)

                    Button("저장") {
                        onSave(name)
                        isPresented = false
                    }
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(isSaveEnabled
                        ? UIAsset.Colors.gray0.swiftUIColor
                        : UIAsset.Colors.gray40.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isSaveEnabled
                        ? UIAsset.Colors.sunsetOrange.swiftUIColor
                        : UIAsset.Colors.gray70.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .buttonStyle(.plain)
                    .disabled(!isSaveEnabled)
                }
            }
            .padding(20)
            .background(UIAsset.Colors.gray90.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
        }
        .onAppear { name = initialName }
    }
}
