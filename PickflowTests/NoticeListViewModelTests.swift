import XCTest
@testable import Pickflow

@MainActor
final class NoticeListViewModelTests: XCTestCase {
    private var service: MockNoticeService!
    private var viewModel: NoticeListViewModel!

    override func setUp() async throws {
        try await super.setUp()
        service = MockNoticeService()
        viewModel = NoticeListViewModel(noticeService: service)
    }

    override func tearDown() async throws {
        viewModel = nil
        service = nil
        try await super.tearDown()
    }

    // MARK: - onAppear

    func test_onAppear_정상응답_상태가loaded로전환된다() async {
        let items = [NoticeListItem.fixture(postId: 1), .fixture(postId: 2)]
        service.listResponder = { _, _ in .success(NoticePage(items: items, page: 0, hasNext: false)) }

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .loaded(items))
        XCTAssertEqual(service.requestedListPages, [0])
        XCTAssertEqual(service.lastMasterId, 1)
    }

    func test_onAppear_빈응답_상태가empty로전환된다() async {
        service.listResponder = { _, _ in .success(NoticePage(items: [], page: 0, hasNext: false)) }

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func test_onAppear_실패_상태가failed로전환되고에러메시지가포함된다() async {
        service.listResponder = { _, _ in .failure(NoticeTestError.stubbed) }

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .failed(NoticeListViewModel.errorMessage))
    }

    func test_onAppear_이미로딩이후면_중복요청하지않는다() async {
        service.listResponder = { _, _ in .success(NoticePage(items: [.fixture()], page: 0, hasNext: false)) }
        await viewModel.onAppear()

        await viewModel.onAppear()

        XCTAssertEqual(service.requestedListPages, [0])
    }

    func test_onAppear_커스텀masterId가서비스에전달된다() async {
        viewModel = NoticeListViewModel(noticeService: service, masterId: 7)

        await viewModel.onAppear()

        XCTAssertEqual(service.lastMasterId, 7)
    }

    // MARK: - loadNextPageIfNeeded

    func test_loadNextPageIfNeeded_마지막항목이고hasNext_다음페이지를append한다() async {
        let firstPage = [NoticeListItem.fixture(postId: 1), .fixture(postId: 2)]
        service.listResponder = { _, page in
            if page == 0 { return .success(NoticePage(items: firstPage, page: 0, hasNext: true)) }
            return .success(NoticePage(items: [.fixture(postId: 3)], page: 1, hasNext: false))
        }
        await viewModel.onAppear()

        await viewModel.loadNextPageIfNeeded(currentItem: firstPage.last!)

        XCTAssertEqual(viewModel.state, .loaded(firstPage + [.fixture(postId: 3)]))
        XCTAssertEqual(service.requestedListPages, [0, 1])
        XCTAssertFalse(viewModel.isLoadingNextPage)
    }

    func test_loadNextPageIfNeeded_hasNext가false면_요청하지않는다() async {
        let firstPage = [NoticeListItem.fixture(postId: 1)]
        service.listResponder = { _, _ in .success(NoticePage(items: firstPage, page: 0, hasNext: false)) }
        await viewModel.onAppear()

        await viewModel.loadNextPageIfNeeded(currentItem: firstPage.last!)

        XCTAssertEqual(service.requestedListPages, [0])
    }

    func test_loadNextPageIfNeeded_마지막항목이아니면_요청하지않는다() async {
        let firstPage = [NoticeListItem.fixture(postId: 1), .fixture(postId: 2)]
        service.listResponder = { _, _ in .success(NoticePage(items: firstPage, page: 0, hasNext: true)) }
        await viewModel.onAppear()

        await viewModel.loadNextPageIfNeeded(currentItem: firstPage.first!)

        XCTAssertEqual(service.requestedListPages, [0])
    }

    func test_loadNextPageIfNeeded_다음페이지실패시_기존목록을유지한다() async {
        let firstPage = [NoticeListItem.fixture(postId: 1)]
        service.listResponder = { _, page in
            if page == 0 { return .success(NoticePage(items: firstPage, page: 0, hasNext: true)) }
            return .failure(NoticeTestError.stubbed)
        }
        await viewModel.onAppear()

        await viewModel.loadNextPageIfNeeded(currentItem: firstPage.last!)

        XCTAssertEqual(viewModel.state, .loaded(firstPage))
        XCTAssertFalse(viewModel.isLoadingNextPage)
    }

    // MARK: - retry

    func test_retry_실패후_재시도하면loaded로전환된다() async {
        service.listResponder = { _, _ in .failure(NoticeTestError.stubbed) }
        await viewModel.onAppear()
        XCTAssertEqual(viewModel.state, .failed(NoticeListViewModel.errorMessage))

        let items = [NoticeListItem.fixture(postId: 1)]
        service.listResponder = { _, _ in .success(NoticePage(items: items, page: 0, hasNext: false)) }
        await viewModel.retry()

        XCTAssertEqual(viewModel.state, .loaded(items))
    }
}
