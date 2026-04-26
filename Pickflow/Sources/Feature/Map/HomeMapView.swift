import SwiftUI

// 무드 필터 (노을/윤슬).
enum MoodFilter: String, CaseIterable {
    case sunset = "노을"
    case ripple = "윤슬"

    var imageName: String {
        switch self {
        case .sunset:
            "sunset"
        case .ripple:
            "sparklingRipple"
        }

    }
}

struct HomeMapView: View {
    @State private var selectedMood: MoodFilter? = nil
    @State private var mapListMode: MapListMode = .map
    @State private var isAddPlacePresented = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                NaverMapView()
                    .ignoresSafeArea()

                // MARK: - Top overlay
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, Padding.containerHorizontal)
                        .padding(.top, Padding.containerTop)
                    Spacer()
                }

                // MARK: - Bottom trailing overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        trailingControls
                            .padding(.trailing, Padding.containerHorizontal)
                            .padding(.bottom, Padding.containerBottom)
                    }
                }

                // MARK: - Bottom overlay
                VStack {
                    Spacer()
                    MapListToggle(selectedMode: $mapListMode)
                        .padding(.bottom, Padding.containerBottom)
                }
            }
            .navigationDestination(isPresented: $isAddPlacePresented) {
                AddPlaceDummyView()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("PICKFLOW")
                    .font(.custom("Rambla-Bold", size: 28))
                    .tracking(-0.056)
                    .lineSpacing(1.11)
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    ForEach(MoodFilter.allCases, id: \.self) { mood in
                        moodCapsuleButton(mood)
                    }
                }
            }

            Spacer()
        }

    }

    private func moodCapsuleButton(_ mood: MoodFilter) -> some View {
        Button {
            selectedMood = selectedMood == mood ? nil : mood
        } label: {
            HStack(spacing: 4) {

                Image(mood.imageName)

                Text(mood.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 6)
                    .foregroundStyle(selectedMood == mood ? .white : .primary)
            }
            .padding(.horizontal, 14)
            .background(.gray95)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(selectedMood == mood ? Color.orangeBorder : .clear, lineWidth: 1)
            )

        }
    }

    // MARK: - Trailing Controls

    private var trailingControls: some View {
        VStack(spacing: 12) {
            // Add place button
            Button {
                isAddPlacePresented = true
            } label: {
                Image(.addLocation)
                    .frame(width: Size.iconWidth, height: Size.iconHeight)
                    .background(.gray95)
                    .clipShape(Circle())
                    .addTappableArea(.horizontal, 20)
            }

            // Current position button
            Button {
                // TODO: 현재 위치로 이동
            } label: {
                Image(.myLocation)
                    .frame(width: Size.iconWidth, height: Size.iconHeight)
                    .background(.gray95)
                    .clipShape(Circle())
                    .addTappableArea(.horizontal, 20)
            }
        }
        .padding(.horizontal, -20)
    }

}

// MARK: - Colors

extension Color {
    fileprivate static let orangeBorder: Color = Color(
        red: 250 / 255, green: 97 / 255, blue: 51 / 255)
}

extension HomeMapView {
    fileprivate enum Size {
        static let iconWidth: CGFloat = 56
        static let iconHeight: CGFloat = 56
    }

    fileprivate enum Padding {
        static let containerTop: CGFloat = 16
        static let containerHorizontal: CGFloat = 16
        static let containerBottom: CGFloat = 24
    }
}

extension View {
    func addTappableArea(
        _ edges: Edge.Set = .all, _ length: CGFloat, shape: some Shape = Rectangle()
    ) -> some View {
        self
            .padding(edges, length)
            .contentShape(shape)
    }
}
#Preview {
    HomeMapView()
}
