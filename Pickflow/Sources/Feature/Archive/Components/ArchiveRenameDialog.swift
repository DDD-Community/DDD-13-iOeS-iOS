import SwiftUI

struct ArchiveRenameDialog: View {
    @Binding var isPresented: Bool
    let initialName: String
    let onSave: (String) -> Void

    @State private var name: String = ""
    private let maxLength = 15

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
                    Text("\(name.count)/\(maxLength)")
                        .pretendard(.body(.small()))
                        .foregroundStyle(.gray50)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(UIAsset.Colors.gray80.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 8) {
                    Button("취소") { isPresented = false }
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray10.swiftUIColor)
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
                    .foregroundStyle(UIAsset.Colors.gray10.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(UIAsset.Colors.gray70.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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
