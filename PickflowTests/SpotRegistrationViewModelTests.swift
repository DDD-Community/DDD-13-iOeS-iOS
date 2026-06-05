import XCTest
@testable import Pickflow

@MainActor
final class SpotRegistrationViewModelTests: XCTestCase {
    private var spotService: MockSpotService!
    private var viewModel: SpotRegistrationViewModel!

    override func setUp() async throws {
        try await super.setUp()
        spotService = MockSpotService()
        viewModel = SpotRegistrationViewModel(spotService: spotService)
    }

    override func tearDown() async throws {
        viewModel = nil
        spotService = nil
        try await super.tearDown()
    }

    // MARK: - isRegisterEnabled

    func test_isRegisterEnabled_모든필수값충족시_true() {
        fillRequiredFields()

        XCTAssertTrue(viewModel.isRegisterEnabled)
    }

    func test_isRegisterEnabled_테마미선택시_false() {
        fillRequiredFields()
        viewModel.theme = nil

        XCTAssertFalse(viewModel.isRegisterEnabled)
    }

    func test_isRegisterEnabled_사진미선택시_false() {
        fillRequiredFields()
        viewModel.setPhotoData(nil)

        XCTAssertFalse(viewModel.isRegisterEnabled)
    }

    // MARK: - submit

    func test_submit_테마미선택시_등록을호출하지않는다() async {
        fillRequiredFields()
        viewModel.theme = nil

        await viewModel.submit()

        XCTAssertTrue(spotService.registerDrafts.isEmpty)
        XCTAssertNil(viewModel.registeredSpotId)
    }

    func test_submit_모든조건충족시_선택한테마를draft에담아등록한다() async {
        fillRequiredFields()
        viewModel.toggleTheme(.reflection)

        await viewModel.submit()

        XCTAssertEqual(spotService.registerDrafts.count, 1)
        XCTAssertEqual(spotService.registerDrafts.first?.theme, .reflection)
        XCTAssertEqual(viewModel.registeredSpotId, SpotId(rawValue: "mock-spot-id"))
    }

    // MARK: - Helpers

    /// 테마를 제외한 모든 필수값을 채우고 테마는 `.sunset`으로 선택한다.
    private func fillRequiredFields() {
        viewModel.setPhotoData(Data([0x01]))
        viewModel.applyAddressSelection(.fixtureWithCoordinate())
        viewModel.setSpotName("테스트 스팟")
        viewModel.toggleTheme(.sunset)
        viewModel.setCapturedDate(Date())
        viewModel.setCapturedTime(Date())
    }
}

private extension Address {
    static func fixtureWithCoordinate() -> Address {
        Address(
            id: "addr-1",
            name: "테스트 장소",
            fullAddress: "서울 동작구 테스트로 1",
            roadAddress: "서울 동작구 테스트로 1",
            jibunAddress: nil,
            zipCode: nil,
            city: "서울",
            district: "동작구",
            coordinate: Coordinate(latitude: 37.501, longitude: 126.951)
        )
    }
}
