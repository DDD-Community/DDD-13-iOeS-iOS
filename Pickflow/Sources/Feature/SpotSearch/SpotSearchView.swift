import CoreLocation
import SwiftUI
import UIKit

struct SpotSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SpotSearchViewModel
    @State private var pushedAddress: Address?
    private let onSelectAddress: (Address) -> Void

    init(
        viewModel: SpotSearchViewModel,
        onSelectAddress: @escaping (Address) -> Void
    ) {
        self.onSelectAddress = onSelectAddress
        viewModel.onSelectAddress = onSelectAddress
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private func dismissKeyboard() {
        UIApplication.shared.endEditing()
    }

    var body: some View {
        // root 를 ScrollView 로 둔다: 키보드를 뷰 전체 offset 이 아닌 content inset 으로 처리해
        // 키보드 등장 시 헤더/검색바가 status bar 뒤로 밀려 올라가는 문제를 방지한다.
        ScrollView {
            contentView
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollDismissesKeyboard(.immediately)
        // 빈 영역을 탭하면 키보드를 내린다. (검색 결과 셀은 Button 이라 탭 우선순위가 유지됨)
        .contentShape(Rectangle())
        .onTapGesture { dismissKeyboard() }
        // 헤더 + 검색바는 상단 safe area 에 고정 → 스크롤/키보드와 무관하게 항상 상단에 노출
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 8) {
                headerView

                SpotSearchBar(text: $viewModel.searchQuery) {
                    Task {
                        await viewModel.search()
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
            .background(UIAsset.Colors.gray95.color)
        }
        .background(UIAsset.Colors.gray95.color.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $pushedAddress) { address in
            SpotLocationDetailView(
                viewModel: SpotLocationDetailViewModel(
                    originalAddress: address,
                    addressService: getAddressService(),
                    locationService: getLocationService()
                ),
                onConfirm: { confirmed in
                    onSelectAddress(confirmed)
                }
            )
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

            Text("장소 검색")
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

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            SpotSearchEmptyPlaceholder(message: "당신이 발견한 일상 속 반짝임,\n어디인가요?")
        case .loading:
            ProgressView()
                .tint(UIAsset.Colors.gray0.color)
                .frame(maxWidth: .infinity)
                .padding(.top, 120)
        case let .loaded(addresses):
            // root ScrollView 가 스크롤을 담당하므로 중첩 ScrollView 없이 LazyVStack 만 둔다.
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(addresses.enumerated()), id: \.element.id) { index, address in
                    SpotSearchResultItem(
                        address: address,
                        distanceText: viewModel.distanceText(for: address)
                    ) {
                        pushedAddress = address
                    }
                    .padding(.vertical, 24)

                    if index < addresses.count - 1 {
                        Divider()
                            .background(UIAsset.Colors.gray80.color)
                    }
                }
            }
        case .empty:
            SpotSearchEmptyPlaceholder(message: "검색 결과가 없어요.\n다른 장소를 검색해 보세요.")
        case .failed:
            EmptyView()
        }
    }
}

private extension UIApplication {
    func endEditing() {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .endEditing(true)
    }
}

#Preview {
    SpotSearchView(
        viewModel: SpotSearchViewModel(
            addressService: SpotSearchPreviewAddressService(),
            locationService: SpotSearchPreviewLocationService()
        ),
        onSelectAddress: { _ in }
    )
}

private struct SpotSearchPreviewAddressService: AddressServiceProtocol {
    func searchAddress(query: String) async throws -> [Address] {
        [
            Address(
                id: "preview-address",
                name: "잠원 한강공원",
                fullAddress: "서울 서초구 잠원로 221-124 잠원한강공원",
                roadAddress: "서울 서초구 잠원로 221-124 잠원한강공원",
                jibunAddress: nil,
                zipCode: nil,
                city: "서울",
                district: "서초구",
                coordinate: Coordinate(latitude: 37.5209, longitude: 127.0116)
            ),
        ]
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> Address {
        throw URLError(.unsupportedURL)
    }
}

private struct SpotSearchPreviewLocationService: LocationServiceProtocol {
    var lastKnownLocation: Coordinate? { Coordinate(latitude: 37.5209, longitude: 126.9833) }
    func requestAuthorization() {}

    func authorizationStatus() -> CLAuthorizationStatus {
        .authorizedWhenInUse
    }

    func currentLocation() async throws -> Coordinate {
        Coordinate(latitude: 37.5209, longitude: 126.9833)
    }

    func startUpdatingLocation() -> AsyncStream<Coordinate> {
        AsyncStream { continuation in
            continuation.yield(Coordinate(latitude: 37.5209, longitude: 126.9833))
            continuation.finish()
        }
    }
}
