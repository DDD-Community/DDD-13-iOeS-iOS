import XCTest
@testable import Pickflow

/// PV-40 — 등록자가 삭제한 저장 스팟.
@MainActor
final class ArchiveDeletedSpotTests: XCTestCase {
    private var archiveService: MockArchiveService!
    private var bookmarkService: MockBookmarkService!
    private var viewModel: ArchiveViewModel!

    private let normal = SavedSpotItem.fixture(spotId: 1)
    private let deleted = SavedSpotItem.fixture(spotId: 2, imageUrl: nil, deleted: true)

    override func setUp() async throws {
        try await super.setUp()
        archiveService = MockArchiveService()
        bookmarkService = MockBookmarkService()
        viewModel = ArchiveViewModel(
            archiveService: archiveService,
            bookmarkService: bookmarkService,
            authService: MockAuthServiceForArchive(),
            socialLoginService: MockSocialLoginService(),
            locationService: MockLocationService()
        )
        viewModel.applyLoadedState(items: [normal, deleted])
    }

    override func tearDown() async throws {
        viewModel = nil
        bookmarkService = nil
        archiveService = nil
        try await super.tearDown()
    }

    func test_삭제된_스팟도_상세로_가지_않고_삭제확인이_뜬다() {
        viewModel.savedSpotTapped(deleted)

        XCTAssertEqual(viewModel.removalCandidate, deleted)
        XCTAssertNil(viewModel.openedSpotId)
    }

    func test_삭제된_스팟은_목록에서_뺄_수_있다() async {
        viewModel.savedSpotTapped(deleted)

        await viewModel.confirmRemoveFromSaved()

        XCTAssertEqual(bookmarkService.deletedSpotIds, [deleted.spotId])
        guard case let .loaded(items, _) = viewModel.state else {
            return XCTFail("loaded 상태여야 한다")
        }
        XCTAssertEqual(items.map(\.spotId), [normal.spotId])
    }

    func test_열_수_없는_상태는_삭제와_비공개_두_가지다() {
        XCTAssertTrue(deleted.isUnavailable)
        XCTAssertTrue(SavedSpotItem.fixture(isPrivate: true).isUnavailable)
        XCTAssertFalse(normal.isUnavailable)
    }

    /// 삭제와 비공개는 안내 문구가 다르다.
    func test_상태별_안내문구() {
        XCTAssertEqual(deleted.unavailableNotice, "등록한 유저가\n삭제한 스팟이에요")
        XCTAssertEqual(
            SavedSpotItem.fixture(isPrivate: true).unavailableNotice,
            "등록한 유저가\n비공개로 전환하였어요"
        )
        XCTAssertNil(normal.unavailableNotice)
    }
}
