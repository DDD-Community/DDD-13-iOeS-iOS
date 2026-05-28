import SwiftUI

struct PickflowWorkMarkLogo: View {
    var width: CGFloat = 140
    var height: CGFloat = 32

    var body: some View {
        Image("pickflow_wordmark")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height, alignment: .leading)
            .accessibilityLabel("PICKFLOW")
    }
}

#Preview {
    PickflowWorkMarkLogo()
        .padding()
}
