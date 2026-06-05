import XCTest
@testable import Pickflow

@MainActor
final class ForceUpdateViewModelTests: XCTestCase {
    private var service: MockAppVersionService!

    override func setUp() async throws {
        try await super.setUp()
        service = MockAppVersionService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - 초기 상태

    func test_초기상태는_checking이다() {
        let viewModel = makeViewModel(currentVersion: "1.0.0")
        XCTAssertEqual(viewModel.state, .checking)
        XCTAssertFalse(viewModel.isForceUpdateRequired)
    }

    // MARK: - 강제 업데이트가 필요한 경우

    func test_현재버전이최소버전보다낮고_forceUpdate가true면_needsForceUpdate가된다() async {
        service.fetchResult = .success(.fixture(
            minimumVersion: "1.3.0",
            forceUpdate: true,
            storeUrl: "https://apps.apple.com/app/id123"
        ))
        let viewModel = makeViewModel(currentVersion: "1.2.0")

        await viewModel.checkForUpdate()

        XCTAssertEqual(viewModel.state, .needsForceUpdate(storeURL: URL(string: "https://apps.apple.com/app/id123")!))
        XCTAssertTrue(viewModel.isForceUpdateRequired)
        XCTAssertEqual(viewModel.forceUpdateStoreURL, URL(string: "https://apps.apple.com/app/id123"))
    }

    // MARK: - 앱 진입 허용 케이스

    func test_forceUpdate가false면_버전이낮아도_available이다() async {
        service.fetchResult = .success(.fixture(minimumVersion: "1.3.0", forceUpdate: false))
        let viewModel = makeViewModel(currentVersion: "1.0.0")

        await viewModel.checkForUpdate()

        XCTAssertEqual(viewModel.state, .available)
        XCTAssertFalse(viewModel.isForceUpdateRequired)
    }

    func test_현재버전이최소버전과같으면_available이다() async {
        service.fetchResult = .success(.fixture(minimumVersion: "1.3.0", forceUpdate: true))
        let viewModel = makeViewModel(currentVersion: "1.3.0")

        await viewModel.checkForUpdate()

        XCTAssertEqual(viewModel.state, .available)
    }

    func test_현재버전이최소버전보다높으면_available이다() async {
        service.fetchResult = .success(.fixture(minimumVersion: "1.3.0", forceUpdate: true))
        let viewModel = makeViewModel(currentVersion: "1.10.0")

        await viewModel.checkForUpdate()

        XCTAssertEqual(viewModel.state, .available)
    }

    func test_storeUrl이유효하지않으면_available이다() async {
        service.fetchResult = .success(.fixture(
            minimumVersion: "1.3.0",
            forceUpdate: true,
            storeUrl: ""
        ))
        let viewModel = makeViewModel(currentVersion: "1.0.0")

        await viewModel.checkForUpdate()

        XCTAssertEqual(viewModel.state, .available)
    }

    // MARK: - 실패 정책 (fail-open)

    func test_API호출이실패하면_앱진입을허용한다() async {
        service.fetchResult = .failure(APIError(code: "E500", message: "server error"))
        let viewModel = makeViewModel(currentVersion: "1.0.0")

        await viewModel.checkForUpdate()

        XCTAssertEqual(viewModel.state, .available)
        XCTAssertFalse(viewModel.isForceUpdateRequired)
    }

    // MARK: - Helpers

    private func makeViewModel(currentVersion: String) -> ForceUpdateViewModel {
        ForceUpdateViewModel(service: service, currentVersion: currentVersion)
    }
}
