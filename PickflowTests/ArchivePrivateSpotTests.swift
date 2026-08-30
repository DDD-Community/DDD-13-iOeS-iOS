import XCTest
@testable import Pickflow

/// PV-40 — 저장한 타 유저 스팟이 비공개로 전환된 경우.
@MainActor
final class ArchivePrivateSpotTests: XCTestCase {
    private var archiveService: MockArchiveService!
    private var bookmarkService: MockBookmarkService!
    private var authService: MockAuthServiceForArchive!
    private var socialLoginService: MockSocialLoginService!
    private var locationService: MockLocationService!
    private var viewModel: ArchiveViewModel!

    private let publicSpot = SavedSpotItem.fixture(spotId: 1)
    private let privateSpot = SavedSpotItem.fixture(spotId: 2, imageUrl: nil, isPrivate: true)

    override func setUp() async throws {
        try await super.setUp()
        archiveService = MockArchiveService()
        bookmarkService = MockBookmarkService()
        authService = MockAuthServiceForArchive()
        socialLoginService = MockSocialLoginService()
        locationService = MockLocationService()
        viewModel = ArchiveViewModel(
            archiveService: archiveService,
            bookmarkService: bookmarkService,
            authService: authService,
            socialLoginService: socialLoginService,
            locationService: locationService
        )
        viewModel.applyLoadedState(items: [publicSpot, privateSpot])
    }

    override func tearDown() async throws {
        viewModel = nil
        locationService = nil
        socialLoginService = nil
        authService = nil
        bookmarkService = nil
        archiveService = nil
        try await super.tearDown()
    }

    // MARK: - 탭 분기

    func test_비공개스팟을_탭하면_상세로_가지_않고_삭제확인이_뜬다() {
        viewModel.savedSpotTapped(privateSpot)

        XCTAssertEqual(viewModel.removalCandidate, privateSpot)
        XCTAssertNil(viewModel.openedSpotId)
    }

    func test_공개스팟을_탭하면_상세로_간다() {
        viewModel.savedSpotTapped(publicSpot)

        XCTAssertNil(viewModel.removalCandidate)
        XCTAssertEqual(viewModel.openedSpotId, publicSpot.spotId)
    }

    // MARK: - 삭제 확정 / 취소

    func test_삭제를_확정하면_목록에서_빠지고_북마크가_해제된다() async {
        viewModel.savedSpotTapped(privateSpot)

        await viewModel.confirmRemoveFromSaved()

        XCTAssertEqual(bookmarkService.deletedSpotIds, [privateSpot.spotId])
        XCTAssertNil(viewModel.removalCandidate)
        guard case let .loaded(items, _) = viewModel.state else {
            return XCTFail("loaded 상태여야 한다")
        }
        XCTAssertEqual(items.map(\.spotId), [publicSpot.spotId])
    }

    func test_삭제를_취소하면_목록이_그대로다() {
        viewModel.savedSpotTapped(privateSpot)

        viewModel.cancelRemoveFromSaved()

        XCTAssertNil(viewModel.removalCandidate)
        XCTAssertTrue(bookmarkService.deletedSpotIds.isEmpty)
        guard case let .loaded(items, _) = viewModel.state else {
            return XCTFail("loaded 상태여야 한다")
        }
        XCTAssertEqual(items.count, 2)
    }

    func test_삭제가_실패하면_항목이_되돌아오고_토스트가_뜬다() async {
        bookmarkService.deleteError = TestError.failed
        viewModel.savedSpotTapped(privateSpot)

        await viewModel.confirmRemoveFromSaved()

        guard case let .loaded(items, _) = viewModel.state else {
            return XCTFail("loaded 상태여야 한다")
        }
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(viewModel.toast, "북마크 해제에 실패했어요.")
    }

    func test_확인창_없이_확정을_호출하면_아무_일도_없다() async {
        await viewModel.confirmRemoveFromSaved()

        XCTAssertTrue(bookmarkService.deletedSpotIds.isEmpty)
    }
}
