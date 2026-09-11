import XCTest
@testable import Pickflow

/// PV-40 — 재신청 성공 시 "나만의 스팟이 등록되었어요!" 토스트.
@MainActor
final class SpotResubmissionToastTests: XCTestCase {
    private var spotService: MockSpotService!
    private var mySpotService: MockMySpotService!

    override func setUp() async throws {
        try await super.setUp()
        spotService = MockSpotService()
        mySpotService = MockMySpotService()
    }

    override func tearDown() async throws {
        mySpotService = nil
        spotService = nil
        try await super.tearDown()
    }

    func test_재신청_제출이_성공하면_등록완료_토스트_문구를_알린다() async {
        let viewModel = SpotRegistrationViewModel(
            spotService: spotService,
            mySpotService: mySpotService,
            mode: .resubmit(spotId: 7)
        )
        viewModel.prefill(from: .fixture(spotId: 7, isMySpot: true, status: .rejected))

        await viewModel.submit()

        XCTAssertTrue(viewModel.didResubmit)
        XCTAssertEqual(viewModel.resubmitSuccessSpotId, SpotId(rawValue: "7"))
    }

    func test_등록모드에서는_별도의_완료_신호를_주지_않는다() {
        // 신규 등록은 registeredSpotId 하나로 이미 처리된다. resubmitSuccessSpotId 는 재신청 전용이다.
        let viewModel = SpotRegistrationViewModel(spotService: spotService, mySpotService: mySpotService, mode: .create)

        XCTAssertNil(viewModel.resubmitSuccessSpotId)
    }
}
