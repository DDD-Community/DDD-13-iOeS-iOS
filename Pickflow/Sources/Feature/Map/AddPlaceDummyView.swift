import SwiftUI

struct AddPlaceDummyView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Place")
                    .font(.title)
                    .foregroundStyle(.primary)
            }
            .navigationTitle("장소 추가")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AddPlaceDummyView()
}
