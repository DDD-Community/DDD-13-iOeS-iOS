import XCTest
@testable import Pickflow

@MainActor
final class NoticeDetailViewModelTests: XCTestCase {
    private var service: MockNoticeService!

    override func setUp() async throws {
        try await super.setUp()
        service = MockNoticeService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    private func makeViewModel(postId: Int64 = 1, masterId: Int64 = 1) -> NoticeDetailViewModel {
        NoticeDetailViewModel(postId: postId, noticeService: service, masterId: masterId)
    }

    func test_onAppear_정상응답_상태가loaded로전환된다() async {
        let detail = NoticeDetail.fixture(postId: 42, title: "점검 안내", content: "본문")
        service.detailResponder = { _, _ in .success(detail) }
        let viewModel = makeViewModel(postId: 42)

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .loaded(detail))
        XCTAssertEqual(service.requestedDetailIds, [42])
        XCTAssertEqual(service.lastMasterId, 1)
    }

    func test_onAppear_실패_상태가failed로전환되고에러메시지가포함된다() async {
        service.detailResponder = { _, _ in .failure(NoticeTestError.stubbed) }
        let viewModel = makeViewModel()

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .failed(NoticeDetailViewModel.errorMessage))
    }

    func test_onAppear_이미로딩이후면_중복요청하지않는다() async {
        service.detailResponder = { _, _ in .success(.fixture()) }
        let viewModel = makeViewModel()
        await viewModel.onAppear()

        await viewModel.onAppear()

        XCTAssertEqual(service.requestedDetailIds, [1])
    }

    func test_onAppear_커스텀masterId가서비스에전달된다() async {
        let viewModel = makeViewModel(postId: 5, masterId: 9)

        await viewModel.onAppear()

        XCTAssertEqual(service.lastMasterId, 9)
        XCTAssertEqual(service.requestedDetailIds, [5])
    }

    func test_retry_실패후_재시도하면loaded로전환된다() async {
        service.detailResponder = { _, _ in .failure(NoticeTestError.stubbed) }
        let viewModel = makeViewModel()
        await viewModel.onAppear()
        XCTAssertEqual(viewModel.state, .failed(NoticeDetailViewModel.errorMessage))

        let detail = NoticeDetail.fixture()
        service.detailResponder = { _, _ in .success(detail) }
        await viewModel.retry()

        XCTAssertEqual(viewModel.state, .loaded(detail))
    }
}
