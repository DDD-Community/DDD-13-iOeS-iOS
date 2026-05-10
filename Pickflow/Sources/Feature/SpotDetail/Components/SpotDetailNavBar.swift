import SwiftUI

struct SpotDetailNavBar: View {
    let onShare: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 4) {
                Button(action: onShare) {
                    AssetImage(named: "icShare", size: 32) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(.gray0)
                    }
                    .frame(width: 48, height: 48)
                }
                Button(action: onClose) {
                    AssetImage(named: "icClose", size: 32) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(.gray0)
                    }
                    .frame(width: 48, height: 48)
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 48)
        .background(.gray95)
    }
}
