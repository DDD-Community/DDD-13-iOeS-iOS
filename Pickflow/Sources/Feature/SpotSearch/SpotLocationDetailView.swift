import SwiftUI

struct SpotLocationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SpotLocationDetailViewModel
    @State private var markerCoordinate: Coordinate

    init(
        viewModel: SpotLocationDetailViewModel,
        onConfirm: @escaping (Address) -> Void
    ) {
        viewModel.onConfirm = onConfirm
        _viewModel = StateObject(wrappedValue: viewModel)
        _markerCoordinate = State(initialValue: viewModel.currentCoordinate)
    }

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                VStack(alignment: .leading, spacing: 16) {
                    mapCard

                    Text("핀을 움직여 정확한 위치로 이동해 주세요")
                    .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray30.color)
                        .frame(maxWidth: .infinity, alignment: .center)

                    confirmButton

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.refreshUserLocation()
        }
        .alert("위치 권한이 필요합니다", isPresented: $viewModel.showLocationPermissionAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("설정에서 위치 권한을 허용해 주세요.")
        }
    }

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                AssetImage(named: "icon_back_arrow", renderingMode: .template, size: 28) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 28, weight: .regular))
                        .frame(width: 28, height: 28)
                }
                .foregroundStyle(UIAsset.Colors.gray0.color)
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로가기")

            Spacer()

            Text("장소 상세 정보")
                .pretendard(.heading(.medium))
                .foregroundStyle(UIAsset.Colors.gray0.color)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
        .background(UIAsset.Colors.gray95.color)
    }

    private var mapCard: some View {
        ZStack {
            SpotLocationDetailMapView(
                initialCoordinate: viewModel.currentCoordinate,
                userLocation: viewModel.userLocation,
                cameraMoveRequest: viewModel.cameraMoveRequest,
                onCenterCoordinateChange: { coordinate in
                    markerCoordinate = coordinate
                }
            )

            Image("ic_search_pin")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 44)
                .offset(y: -22)
                .allowsHitTesting(false)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    currentPositionButton
                        .padding(12)
                }
            }
        }
        .frame(height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var currentPositionButton: some View {
        Button {
            Task { await viewModel.moveToCurrentLocation() }
        } label: {
            Image(.myLocation)
                .frame(width: 44, height: 44)
                .background(UIAsset.Colors.gray95.color)
                .clipShape(Circle())
                .overlay(Circle().stroke(UIAsset.Colors.gray80.swiftUIColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("현재 위치")
    }

    private var confirmButton: some View {
        Button {
            Task {
                await viewModel.confirm(markerCoordinate: markerCoordinate)
            }
        } label: {
            ZStack {
                if viewModel.isConfirming {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("이 장소가 맞아요")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.gray0)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.spotOrange, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isConfirming)
        .accessibilityLabel("이 장소가 맞아요")
    }
}
