import SwiftUI

struct TermsAndPolicyListView: View {
    @Environment(\.dismiss) private var dismiss

    let documents: [TermsPolicyDocument]
    @State private var selectedDocument: TermsPolicyDocument?

    init(documents: [TermsPolicyDocument] = TermsPolicyDocument.all) {
        self.documents = documents
    }

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            VStack(spacing: 0) {
                customHeader

                VStack(spacing: 0) {
                    ForEach(documents) { document in
                        documentRow(document)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedDocument) { document in
            TermsAndPolicyView(title: document.title, url: document.url)
        }
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        ZStack {
            Text("약관 및 정책")
                .pretendard(.heading(.small))
                .foregroundStyle(.gray0)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.gray0)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Row

    private func documentRow(_ document: TermsPolicyDocument) -> some View {
        Button {
            selectedDocument = document
        } label: {
            HStack {
                Text(document.title)
                    .pretendard(.body(.large()))
                    .foregroundStyle(.gray0)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.gray50)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
