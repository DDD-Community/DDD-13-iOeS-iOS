import SwiftUI

#if DEBUG
struct MyProfileDebugView: View {
    var body: some View {
        ContentView(initialTab: .my)
    }
}
#endif
