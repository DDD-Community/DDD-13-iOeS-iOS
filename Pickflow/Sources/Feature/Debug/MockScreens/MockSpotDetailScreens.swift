#if DEBUG
import SwiftUI
import UIKit

/// 공개 상태만 바꿔 가며 스팟 상세를 띄우기 위한 목 서비스.
final class MockPublicationSpotService: SpotServiceProtocol, @unchecked Sendable {
    private let spot: SpotDetail

    init(spot: SpotDetail) { self.spot = spot }

    func fetchSpotDetail(id _: Int64, latitude _: Double?, longitude _: Double?) async throws -> SpotDetail { spot }

    func fetchSpotPreview(id _: Int64, latitude _: Double?, longitude _: Double?) async throws -> SpotPreviewResponse {
        SpotPreviewResponse(
            spotId: spot.spotId,
            name: spot.name,
            isMySpot: spot.isMySpot,
            theme: spot.theme,
            bookmarkCount: spot.bookmarkCount,
            isBookmarked: spot.isBookmarked,
            distanceKm: 2.5,
            imageUrl: spot.imageUrl,
            addressSimple: spot.address ?? "",
            addressRoad: nil,
            addressJibun: nil,
            isCurated: spot.isCurated,
            likeCount: spot.likeCount,
            isLiked: spot.isLiked,
            isLikeable: spot.isLikeable
        )
    }

    func registerSpot(draft _: SpotRegistrationDraft) async throws -> SpotId { SpotId(rawValue: "mock") }
    func reportSpot(id _: Int64, content _: String) async throws {}
    func likeSpot(id _: Int64) async throws -> SpotLikeResponse {
        SpotLikeResponse(likeCount: (spot.likeCount ?? 0) + 1, isLiked: true)
    }
    func unlikeSpot(id _: Int64) async throws -> SpotLikeResponse {
        SpotLikeResponse(likeCount: max(0, (spot.likeCount ?? 1) - 1), isLiked: false)
    }
}

/// 오픈 신청·철회·삭제가 성공한 것처럼 응답한다.
final class MockMySpotPublicationService: MySpotServiceProtocol, @unchecked Sendable {
    private let currentStatus: MySpotStatus

    init(currentStatus: MySpotStatus) {
        self.currentStatus = currentStatus
    }

    func updateMySpot(spotId: Int64, draft _: MySpotUpdateDraft) async throws -> UpdateMySpotResponse {
        UpdateMySpotResponse(spotId: spotId, status: .rejected, imageUrl: nil)
    }
    func deleteMySpot(spotId _: Int64) async throws {}
    func requestOpen(spotId: Int64) async throws -> OpenMySpotResponse {
        OpenMySpotResponse(spotId: spotId, status: .pending)
    }
    func cancelPublication(spotId: Int64) async throws -> CancelPublicationResponse {
        CancelPublicationResponse(spotId: spotId, previousStatus: currentStatus, status: .draft)
    }
}

/// 오픈 완료 팝업을 매번 보기 위해 "확인한 적 없음" 으로 고정한다.
struct NeverAcknowledgedStore: OpenCompleteAcknowledging {
    func hasAcknowledged(spotId _: Int64) -> Bool { false }
    func acknowledge(spotId _: Int64) {}
}

@MainActor
enum MockSpotDetailFactory {
    static func spot(status: MySpotStatus, isMySpot: Bool = true, isCurated: Bool = false) -> SpotDetail {
        SpotDetail(
            spotId: 1,
            name: "석촌호수 산책길",
            comment: "노을빛에 반사된 윤슬이 가장 반짝여요.",
            theme: .reflection,
            latitude: 37.5065,
            longitude: 127.0785,
            address: "서울특별시 송파구 올림픽로 240",
            addressRoad: "서울특별시 송파구 올림픽로 240",
            addressJibun: "서울특별시 송파구 잠실동 47",
            imageUrl: nil,
            recordedDate: "2026-04-11",
            recordedTime: "18:33",
            weatherSky: .clear,
            precipitation: SpotDetail.fixtureNone,
            precipitationProbability: 15,
            congestionLevel: .relaxed,
            sunsetTime: "18:40",
            astronomyDate: "2026-04-11",
            weatherUpdatedAt: nil,
            congestionUpdatedAt: nil,
            parkingInfo: nil,
            bookmarkCount: 3,
            isBookmarked: false,
            isMySpot: isMySpot,
            status: status,
            isCurated: isCurated,
            likeCount: status == .published ? 34 : nil,
            isLiked: false,
            isLikeable: status == .published,
            rejection: status == .rejected
                ? SpotRejectionInfo(
                    reason: "FILTER_MISMATCH",
                    reasonLabel: "카테고리 불일치",
                    guideMessage: "선택하신 카테고리와 사진이 일치하지 않습니다.",
                    detail: nil,
                    rejectedAt: "2026-07-21T10:00:00Z"
                )
                : nil
        )
    }

    static func makeViewModel(
        status: MySpotStatus,
        isMySpot: Bool = true,
        isCurated: Bool = false
    ) -> SpotDetailViewModel {
        SpotDetailViewModel(
            spotId: 1,
            spotService: MockPublicationSpotService(
                spot: spot(status: status, isMySpot: isMySpot, isCurated: isCurated)
            ),
            mySpotService: MockMySpotPublicationService(currentStatus: status),
            bookmarkService: DebugBookmarkService(),
            locationService: DebugLocationService(),
            externalAppLauncher: getExternalAppLauncher(),
            shareSheetPresenter: getShareSheetPresenter(),
            deviceIdProvider: { "mock-device" },
            openCompleteStore: NeverAcknowledgedStore()
        )
    }
}

extension SpotDetail {
    /// Precipitation.none 을 옵셔널 문맥에서 쓰면 nil 로 해석되어 헷갈리므로 이름을 따로 둔다.
    static var fixtureNone: Precipitation { .none }
}

/// 목 데이터로 띄우는 스팟 상세.
struct MockSpotDetailScreen: View {
    let status: MySpotStatus
    var isMySpot: Bool = true
    var isCurated: Bool = false

    var body: some View {
        MockScreenContainer {
            SpotDetailView(
                viewModel: MockSpotDetailFactory.makeViewModel(
                    status: status,
                    isMySpot: isMySpot,
                    isCurated: isCurated
                )
            )
        }
    }
}

/// 지도에서 타 유저 등록 스팟을 선택했을 때 뜨는 미리보기 시트.
struct MockUserSpotPreviewSheet: View {
    var body: some View {
        MockScreenContainer {
            ZStack(alignment: .bottom) {
                UIAsset.Colors.gray80.swiftUIColor.ignoresSafeArea()
                SpotDetailSheetContentView(
                    preview: SpotPreviewResponse(
                        spotId: 2,
                        name: "잠원 한강공원",
                        isMySpot: false,
                        theme: .sunlight,
                        bookmarkCount: 12,
                        isBookmarked: false,
                        distanceKm: 2.5,
                        imageUrl: nil,
                        addressSimple: "서울시 강동구",
                        addressRoad: "서울 강동구 올림픽로 240",
                        addressJibun: nil,
                        isCurated: false,
                        likeCount: 34,
                        isLiked: false,
                        isLikeable: true
                    ),
                    isBookmarked: false
                )
                .padding(20)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                        .fill(UIAsset.Colors.gray95.swiftUIColor)
                )
            }
        }
    }
}

/// 검수 결과 스낵바. 승인·반려를 나란히 본다.
struct MockReviewSnackbarScreen: View {
    var body: some View {
        MockScreenContainer {
            ZStack {
                UIAsset.Colors.gray80.swiftUIColor.ignoresSafeArea()
                VStack(spacing: 20) {
                    SpotReviewSnackbar(
                        notice: SpotReviewNotice(spotId: 1, kind: .approved),
                        onAction: {},
                        onClose: {}
                    )
                    SpotReviewSnackbar(
                        notice: SpotReviewNotice(spotId: 2, kind: .rejected),
                        onAction: {},
                        onClose: {}
                    )
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

/// V2 업데이트 안내 모달.
struct MockV2NoticeScreen: View {
    var body: some View {
        MockScreenContainer {
            ZStack {
                UIAsset.Colors.gray80.swiftUIColor.ignoresSafeArea()
                Color.black.opacity(0.5).ignoresSafeArea()
                V2UpdateNoticeModal(onConfirm: {})
            }
        }
    }
}
#endif
