import SwiftUI
import UIKit

struct AssetImage<Fallback: View>: View {
    let named: String
    var renderingMode: Image.TemplateRenderingMode = .original
    let size: CGFloat
    @ViewBuilder let fallback: () -> Fallback

    var body: some View {
        if UIImage(named: named) != nil {
            Image(named)
                .renderingMode(renderingMode)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            fallback()
        }
    }
}
