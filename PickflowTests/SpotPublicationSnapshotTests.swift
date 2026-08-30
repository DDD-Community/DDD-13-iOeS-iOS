import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

/// PV-40 유저 스팟 공개 시스템 — 컴포넌트 단위 스냅샷.
/// 케이스 정의는 `docs/PV-40/ui-test-cases.md` 가 단일 진실 소스다.
@MainActor
final class SpotPublicationSnapshotTests: XCTestCase {

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yDark = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .dark),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    private let screenWidth: CGFloat = 390

    // MARK: - SpotStatusBadge

    func test_spot_status_badge_myspot_light() {
        assert(badge(.mySpot), width: 200, height: 60, traits: Self.light)
    }

    func test_spot_status_badge_myspot_dark() {
        assert(badge(.mySpot), width: 200, height: 60, traits: Self.dark)
    }

    func test_spot_status_badge_review_light() {
        assert(badge(.underReview), width: 200, height: 60, traits: Self.light)
    }

    func test_spot_status_badge_review_dark() {
        assert(badge(.underReview), width: 200, height: 60, traits: Self.dark)
    }

    func test_spot_status_badge_rejected_light() {
        assert(badge(.rejected), width: 200, height: 60, traits: Self.light)
    }

    func test_spot_status_badge_rejected_dark() {
        assert(badge(.rejected), width: 200, height: 60, traits: Self.dark)
    }

    // MARK: - SpotPublicationHeader

    func test_spot_detail_header_draft_light() {
        assert(header(status: .draft, likeCount: nil), width: screenWidth, height: 100, traits: Self.light)
    }

    func test_spot_detail_header_draft_dark() {
        assert(header(status: .draft, likeCount: nil), width: screenWidth, height: 100, traits: Self.dark)
    }

    func test_spot_detail_header_review_light() {
        assert(header(status: .pending, likeCount: nil), width: screenWidth, height: 100, traits: Self.light)
    }

    func test_spot_detail_header_review_dark() {
        assert(header(status: .pending, likeCount: nil), width: screenWidth, height: 100, traits: Self.dark)
    }

    func test_spot_detail_header_rejected_light() {
        assert(header(status: .rejected, likeCount: nil), width: screenWidth, height: 100, traits: Self.light)
    }

    func test_spot_detail_header_rejected_dark() {
        assert(header(status: .rejected, likeCount: nil), width: screenWidth, height: 100, traits: Self.dark)
    }

    func test_spot_detail_header_published_light() {
        assert(header(status: .published, likeCount: 0), width: screenWidth, height: 100, traits: Self.light)
    }

    func test_spot_detail_header_published_dark() {
        assert(header(status: .published, likeCount: 0), width: screenWidth, height: 100, traits: Self.dark)
    }

    func test_spot_detail_header_published_a11y() {
        assert(header(status: .published, likeCount: 1234), width: screenWidth, height: 200, traits: Self.a11yDark)
    }

    // MARK: - SpotActionButtons (내 스팟)

    func test_spot_action_row_draft_light() {
        assert(actionRow(status: .draft), width: screenWidth, height: 90, traits: Self.light)
    }

    func test_spot_action_row_draft_dark() {
        assert(actionRow(status: .draft), width: screenWidth, height: 90, traits: Self.dark)
    }

    func test_spot_action_row_review_light() {
        assert(actionRow(status: .pending), width: screenWidth, height: 90, traits: Self.light)
    }

    func test_spot_action_row_review_dark() {
        assert(actionRow(status: .pending), width: screenWidth, height: 90, traits: Self.dark)
    }

    func test_spot_action_row_published_light() {
        assert(actionRow(status: .published, canLike: true), width: screenWidth, height: 94, traits: Self.light)
    }

    func test_spot_action_row_published_dark() {
        assert(actionRow(status: .published, canLike: true), width: screenWidth, height: 94, traits: Self.dark)
    }

    func test_spot_action_row_rejected_light() {
        assert(actionRow(status: .rejected, canLike: false), width: screenWidth, height: 94, traits: Self.light)
    }

    func test_spot_action_row_rejected_dark() {
        assert(actionRow(status: .rejected, canLike: false), width: screenWidth, height: 94, traits: Self.dark)
    }

    func test_spot_detail_header_user_registered_light() {
        assert(userRegisteredHeader, width: screenWidth, height: 100, traits: Self.light)
    }

    func test_spot_detail_header_user_registered_dark() {
        assert(userRegisteredHeader, width: screenWidth, height: 100, traits: Self.dark)
    }

    func test_spot_action_row_other_spot_light() {
        assert(otherSpotActionRow, width: screenWidth, height: 94, traits: Self.light)
    }

    func test_spot_action_row_other_spot_dark() {
        assert(otherSpotActionRow, width: screenWidth, height: 94, traits: Self.dark)
    }

    // MARK: - SpotLikeButton

    func test_spot_like_button_default_light() {
        assert(SpotLikeButton(isLiked: false) {}, width: 88, height: 88, traits: Self.light)
    }

    func test_spot_like_button_default_dark() {
        assert(SpotLikeButton(isLiked: false) {}, width: 88, height: 88, traits: Self.dark)
    }

    func test_spot_like_button_active_light() {
        assert(SpotLikeButton(isLiked: true) {}, width: 88, height: 88, traits: Self.light)
    }

    func test_spot_like_button_active_dark() {
        assert(SpotLikeButton(isLiked: true) {}, width: 88, height: 88, traits: Self.dark)
    }

    // MARK: - SpotRejectionBanner

    func test_spot_rejection_banner_light() {
        assert(rejectionBanner(), width: screenWidth, height: 190, traits: Self.light)
    }

    func test_spot_rejection_banner_dark() {
        assert(rejectionBanner(), width: screenWidth, height: 190, traits: Self.dark)
    }

    func test_spot_rejection_banner_a11y() {
        assert(
            rejectionBanner(message: "선택하신 카테고리와 사진이 일치하지 않습니다. 사진을 다시 확인해 주세요."),
            width: screenWidth,
            height: 420,
            traits: Self.a11yDark
        )
    }

    // MARK: - SpotVisibilityToggle

    func test_spot_visibility_toggle_on_light() {
        assert(visibilityToggle(isPublic: true), width: screenWidth, height: 110, traits: Self.light)
    }

    func test_spot_visibility_toggle_on_dark() {
        assert(visibilityToggle(isPublic: true), width: screenWidth, height: 110, traits: Self.dark)
    }

    func test_spot_visibility_toggle_off_light() {
        assert(visibilityToggle(isPublic: false), width: screenWidth, height: 110, traits: Self.light)
    }

    func test_spot_visibility_toggle_off_dark() {
        assert(visibilityToggle(isPublic: false), width: screenWidth, height: 110, traits: Self.dark)
    }

    // MARK: - SpotDeleteLink

    func test_spot_delete_link_light() {
        assert(SpotDeleteLink {}, width: screenWidth, height: 70, traits: Self.light)
    }

    func test_spot_delete_link_dark() {
        assert(SpotDeleteLink {}, width: screenWidth, height: 70, traits: Self.dark)
    }

    // MARK: - SpotPublicationSheetContent

    func test_spot_sheet_open_request_light() {
        assert(sheet(.openRequest), width: screenWidth, height: 280, traits: Self.light, padded: false)
    }

    func test_spot_sheet_open_request_dark() {
        assert(sheet(.openRequest), width: screenWidth, height: 280, traits: Self.dark, padded: false)
    }

    func test_spot_sheet_withdraw_light() {
        assert(sheet(.withdraw), width: screenWidth, height: 238, traits: Self.light, padded: false)
    }

    func test_spot_sheet_withdraw_dark() {
        assert(sheet(.withdraw), width: screenWidth, height: 238, traits: Self.dark, padded: false)
    }

    func test_spot_sheet_delete_light() {
        assert(sheet(.delete), width: screenWidth, height: 238, traits: Self.light, padded: false)
    }

    func test_spot_sheet_delete_dark() {
        assert(sheet(.delete), width: screenWidth, height: 238, traits: Self.dark, padded: false)
    }

    func test_spot_sheet_open_request_a11y() {
        assert(sheet(.openRequest), width: screenWidth, height: 560, traits: Self.a11yDark, padded: false)
    }

    // MARK: - SpotOpenCompletePopup

    func test_spot_open_complete_popup_light() {
        assert(SpotOpenCompletePopup {}, width: screenWidth, height: 250, traits: Self.light)
    }

    func test_spot_open_complete_popup_dark() {
        assert(SpotOpenCompletePopup {}, width: screenWidth, height: 250, traits: Self.dark)
    }

    func test_spot_open_complete_popup_a11y() {
        assert(SpotOpenCompletePopup {}, width: screenWidth, height: 520, traits: Self.a11yDark)
    }

    // MARK: - SpotPublicationToast

    func test_spot_toast_open_submitted_light() {
        assert(SpotPublicationToast(message: "오픈 신청이 접수되었어요."), width: screenWidth, height: 70, traits: Self.light)
    }

    func test_spot_toast_open_submitted_dark() {
        assert(SpotPublicationToast(message: "오픈 신청이 접수되었어요."), width: screenWidth, height: 70, traits: Self.dark)
    }

    // MARK: - Builders

    private func badge(_ style: SpotStatusBadge.Style) -> some View {
        SpotStatusBadge(style: style)
    }

    private func header(status: MySpotStatus, likeCount: Int?) -> some View {
        SpotPublicationHeader(
            name: "석촌호수 산책길",
            theme: .reflection,
            status: status,
            isMySpot: true,
            metric: likeCount.map { "추천 \($0)" }
        )
    }

    /// 타 유저가 등록해 공개한 스팟. 타이틀 옆 "유저 등록" 뱃지와 추천 수가 붙는다.
    private var userRegisteredHeader: some View {
        SpotPublicationHeader(
            name: "석촌호수 산책길",
            theme: .reflection,
            status: nil,
            isMySpot: false,
            isUserRegistered: true,
            metric: "추천 34"
        )
    }

    /// 타인 스팟은 길 안내 + 북마크 + 추천 세 버튼이다.
    private var otherSpotActionRow: some View {
        SpotActionButtons(
            isMine: false,
            isBookmarked: false,
            onRoute: {},
            onBookmark: {},
            onOpenSpot: {},
            canLike: true,
            isLiked: false
        )
    }

    private func actionRow(status: MySpotStatus, canLike: Bool = false) -> some View {
        SpotActionButtons(
            isMine: true,
            isBookmarked: false,
            onRoute: {},
            onBookmark: {},
            onOpenSpot: {},
            publicationStatus: status,
            canLike: canLike,
            isLiked: false
        )
    }

    private func rejectionBanner(
        message: String = "선택하신 카테고리와 사진이 일치하지 않습니다."
    ) -> some View {
        SpotRejectionBanner(
            rejection: SpotRejectionInfo(
                reason: "FILTER_MISMATCH",
                reasonLabel: "카테고리 불일치",
                guideMessage: message,
                detail: nil,
                rejectedAt: "2026-07-21T10:00:00Z"
            ),
            onWithdraw: {},
            onResubmit: {}
        )
    }

    private func visibilityToggle(isPublic: Bool) -> some View {
        StatefulPreviewWrapper(isPublic) { SpotVisibilityToggle(isPublic: $0) }
    }

    private func sheet(_ sheet: SpotPublicationSheet) -> some View {
        SpotPublicationSheetContent(sheet: sheet, onCancel: {}, onConfirm: {})
    }

    // MARK: - Snapshot helper

    /// 전 케이스 공통 환경: ko_KR, 화면 배경(gray95) 위, 좌우 16pt 내부 여백.
    private func assert(
        _ view: some View,
        width: CGFloat,
        height: CGFloat,
        traits: UITraitCollection,
        padded: Bool = true,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let container = VStack(spacing: 0) { view }
            .padding(.horizontal, padded ? 16 : 0)
            .frame(width: width, height: height, alignment: padded ? .center : .bottom)
            .background(UIAsset.Colors.gray95.swiftUIColor)
            .environment(\.locale, Locale(identifier: "ko_KR"))

        assertSnapshot(
            of: container,
            as: .image(layout: .fixed(width: width, height: height), traits: traits),
            file: file,
            testName: testName,
            line: line
        )
    }
}

/// `@Binding` 을 요구하는 컴포넌트를 스냅샷에서 고정 상태로 렌더링하기 위한 래퍼.
private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View { content($value) }
}
