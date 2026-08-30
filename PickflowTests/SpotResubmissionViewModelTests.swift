import XCTest
@testable import Pickflow

/// PV-40 — 반려된 스팟의 "수정 후 재신청".
@MainActor
final class SpotResubmissionViewModelTests: XCTestCase {
    private var spotService: MockSpotService!
    private var mySpotService: MockMySpotService!
    private var viewModel: SpotRegistrationViewModel!

    private let rejected = SpotDetail.fixture(
        spotId: 7,
        isMySpot: true,
        theme: .reflection,
        imageUrl: "https://example.com/old.jpg",
        comment: "노을빛에 반사된 윤슬이 가장 반짝여요.",
        addressRoad: "서울특별시 송파구 올림픽로 240",
        addressJibun: "서울특별시 송파구 잠실동 47",
        status: .rejected
    )

    override func setUp() async throws {
        try await super.setUp()
        spotService = MockSpotService()
        mySpotService = MockMySpotService()
        viewModel = SpotRegistrationViewModel(
            spotService: spotService,
            mySpotService: mySpotService,
            mode: .resubmit(spotId: rejected.spotId)
        )
        viewModel.prefill(from: rejected)
    }

    override func tearDown() async throws {
        viewModel = nil
        mySpotService = nil
        spotService = nil
        try await super.tearDown()
    }

    // MARK: - 프리필

    func test_반려스팟의_기존값이_폼에_채워진다() {
        XCTAssertEqual(viewModel.spotName, rejected.name)
        XCTAssertEqual(viewModel.theme, .reflection)
        XCTAssertEqual(viewModel.comment, rejected.comment)
        XCTAssertEqual(viewModel.selectedAddress?.coordinate?.latitude, rejected.latitude)
        XCTAssertEqual(viewModel.selectedAddress?.fullAddress, rejected.addressRoad)
        XCTAssertEqual(viewModel.selectedAddress?.roadAddress, rejected.addressRoad)
        XCTAssertEqual(viewModel.selectedAddress?.jibunAddress, rejected.addressJibun)
        XCTAssertNotNil(viewModel.capturedDate)
        XCTAssertNotNil(viewModel.capturedTime)
    }

    func test_도로명주소가_없으면_지번주소로_프리필한다() {
        let spot = SpotDetail.fixture(
            address: "서울 송파구",
            addressRoad: nil,
            addressJibun: "서울특별시 송파구 잠실동 47"
        )

        viewModel.prefill(from: spot)

        XCTAssertEqual(viewModel.selectedAddress?.fullAddress, spot.addressJibun)
    }

    func test_사진을_새로_고르지_않아도_제출할_수_있다() {
        // 서버는 이미지 미첨부 시 기존 이미지를 유지한다.
        XCTAssertNil(viewModel.photoData)
        XCTAssertEqual(viewModel.existingImageUrl, rejected.imageUrl)
        XCTAssertTrue(viewModel.isRegisterEnabled)
    }

    func test_등록모드에서는_사진이_없으면_제출할_수_없다() {
        let createVM = SpotRegistrationViewModel(
            spotService: spotService,
            mySpotService: mySpotService,
            mode: .create
        )
        createVM.setSpotName("이름")
        XCTAssertFalse(createVM.isRegisterEnabled)
    }

    // MARK: - 제출

    func test_재신청은_기존_스팟을_수정한_뒤_오픈신청한다() async {
        await viewModel.submit()

        XCTAssertEqual(mySpotService.updatedDrafts.map(\.spotId), [rejected.spotId])
        XCTAssertEqual(mySpotService.requestedOpenSpotIds, [rejected.spotId])
        // 새 스팟을 만들지 않는다. 만들면 반려된 원본이 중복으로 남는다.
        XCTAssertTrue(spotService.registerDrafts.isEmpty)
    }

    func test_재신청_수정이_실패하면_오픈신청까지_가지_않는다() async {
        mySpotService.updateResult = .failure(TestError.failed)

        await viewModel.submit()

        XCTAssertTrue(mySpotService.requestedOpenSpotIds.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func test_사진을_새로_고르면_그_이미지가_함께_전송된다() async {
        let newPhoto = Data([0x01, 0x02])
        viewModel.setPhotoData(newPhoto)

        await viewModel.submit()

        XCTAssertEqual(mySpotService.updatedDrafts.first?.draft.photoData, newPhoto)
    }

    // MARK: - 이탈 확인

    func test_재신청_폼에서_뒤로가면_이탈_확인을_먼저_묻는다() {
        viewModel.backTapped()

        XCTAssertTrue(viewModel.isExitConfirmPresented)
        XCTAssertFalse(viewModel.dismissRequested)
    }

    func test_계속하기를_고르면_폼에_머문다() {
        viewModel.backTapped()

        viewModel.cancelExit()

        XCTAssertFalse(viewModel.isExitConfirmPresented)
        XCTAssertFalse(viewModel.dismissRequested)
    }

    func test_나가기를_고르면_화면을_닫는다() {
        viewModel.backTapped()

        viewModel.confirmExit()

        XCTAssertFalse(viewModel.isExitConfirmPresented)
        XCTAssertTrue(viewModel.dismissRequested)
    }

    func test_등록모드에서는_뒤로가기가_바로_닫는다() {
        let createVM = SpotRegistrationViewModel(
            spotService: spotService,
            mySpotService: mySpotService,
            mode: .create
        )

        createVM.backTapped()

        XCTAssertFalse(createVM.isExitConfirmPresented)
        XCTAssertTrue(createVM.dismissRequested)
    }
}
