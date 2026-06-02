import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

@MainActor
final class NoticeSnapshotTests: XCTestCase {

    // MARK: - Trait Helpers

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yLight = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .light),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    private typealias L = NoticeSnapshotTests

    // MARK: - Fixtures

    private static let sampleItems: [NoticeListItem] = [
        .fixture(
            postId: 1,
            title: "[공지] 픽플로우 개인정보처리방침 개정 안내드립니다. 픽플로우 개인정보처리방침 개정 안내드립니다.",
            createdAt: "2026-05-09",
            pinned: true,
            content: "개인정보처리방침이 2026년 5월 9일자로 개정됩니다. 변경 사항을 확인해 주세요."
        ),
        .fixture(
            postId: 2,
            title: "[공지] 픽플로우 개인정보처리방침 개정 안내드립니다.",
            createdAt: "2026-05-09",
            content: "수집 항목 및 보유 기간 일부가 변경되었습니다."
        ),
        .fixture(
            postId: 3,
            title: "6/16 시스템 정기 점검 안내",
            createdAt: "2026-05-09",
            content: "6월 16일 02:00 ~ 04:00 동안 서비스 이용이 일시 중단됩니다."
        ),
    ]

    private static let longTitleItem: NoticeListItem = .fixture(
        postId: 10,
        title: "[공지] 픽플로우 서비스 점검 및 개인정보처리방침 개정 그리고 신규 기능 출시 안내드립니다 자세한 내용은 본문을 확인해 주세요",
        createdAt: "2026-05-09",
        content: "이번 업데이트에는 점검 일정과 신규 기능 안내가 포함되어 있습니다. 자세한 내용은 본문에서 확인하실 수 있습니다."
    )

    private static let longDetail = NoticeDetail.fixture(
        postId: 1,
        title: "[공지] 픽플로우 개인정보처리방침 개정 안내드립니다. 픽플로우 개인정보처리방침 개정 안내드립니다.",
        createdAt: "2026-05-09",
        content: Array(repeating: "본문 내용", count: 40).joined() + "\n\n\n\nㅎㅎ"
    )

    private static let shortDetail = NoticeDetail.fixture(
        postId: 2,
        title: "6/16 시스템 정기 점검 안내",
        createdAt: "2026-05-09",
        content: "6월 16일 02:00 ~ 04:00 시스템 정기 점검이 진행됩니다."
    )

    // MARK: - Screen Builders

    private func listScreen(
        _ state: NoticeListViewModel.LoadState,
        isLoadingNextPage: Bool = false
    ) -> some View {
        NoticeListContent(state: state, isLoadingNextPage: isLoadingNextPage)
    }

    private func detailScreen(_ state: NoticeDetailViewModel.LoadState) -> some View {
        NoticeDetailContent(state: state)
    }

    // MARK: - List: loaded

    func test_notice_list_loaded_light() {
        assertSnapshot(
            of: listScreen(.loaded(L.sampleItems)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_notice_list_loaded_dark() {
        assertSnapshot(
            of: listScreen(.loaded(L.sampleItems)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    func test_notice_list_loaded_a11y() {
        assertSnapshot(
            of: listScreen(.loaded(L.sampleItems)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.a11yLight)
        )
    }

    // MARK: - List: no content preview (content nil → 미리보기 줄 생략)

    private static let noPreviewItems: [NoticeListItem] = [
        .fixture(postId: 21, title: "본문 미리보기가 없는 공지", createdAt: "2026-05-09"),
        .fixture(postId: 22, title: "6/16 시스템 정기 점검 안내", createdAt: "2026-05-02"),
    ]

    func test_notice_list_no_preview_light() {
        assertSnapshot(
            of: listScreen(.loaded(L.noPreviewItems)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_notice_list_no_preview_dark() {
        assertSnapshot(
            of: listScreen(.loaded(L.noPreviewItems)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - List: long title truncation

    func test_notice_list_longtitle_light() {
        assertSnapshot(
            of: listScreen(.loaded([L.longTitleItem])),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_notice_list_longtitle_dark() {
        assertSnapshot(
            of: listScreen(.loaded([L.longTitleItem])),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - List: empty

    func test_notice_list_empty_light() {
        assertSnapshot(
            of: listScreen(.empty),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_notice_list_empty_dark() {
        assertSnapshot(
            of: listScreen(.empty),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - List: loading

    func test_notice_list_loading_light() {
        assertSnapshot(
            of: listScreen(.loading),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_notice_list_loading_dark() {
        assertSnapshot(
            of: listScreen(.loading),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - List: failed

    func test_notice_list_failed_light() {
        assertSnapshot(
            of: listScreen(.failed(NoticeListViewModel.errorMessage)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_notice_list_failed_dark() {
        assertSnapshot(
            of: listScreen(.failed(NoticeListViewModel.errorMessage)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Detail: loaded (long)

    func test_notice_detail_loaded_long_light() {
        assertSnapshot(
            of: detailScreen(.loaded(L.longDetail)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_notice_detail_loaded_long_dark() {
        assertSnapshot(
            of: detailScreen(.loaded(L.longDetail)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    func test_notice_detail_loaded_long_a11y() {
        assertSnapshot(
            of: detailScreen(.loaded(L.longDetail)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.a11yLight)
        )
    }

    // MARK: - Detail: loaded (short)

    func test_notice_detail_loaded_short_light() {
        assertSnapshot(
            of: detailScreen(.loaded(L.shortDetail)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_notice_detail_loaded_short_dark() {
        assertSnapshot(
            of: detailScreen(.loaded(L.shortDetail)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Detail: loading

    func test_notice_detail_loading_light() {
        assertSnapshot(
            of: detailScreen(.loading),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_notice_detail_loading_dark() {
        assertSnapshot(
            of: detailScreen(.loading),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Detail: failed

    func test_notice_detail_failed_light() {
        assertSnapshot(
            of: detailScreen(.failed(NoticeDetailViewModel.errorMessage)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_notice_detail_failed_dark() {
        assertSnapshot(
            of: detailScreen(.failed(NoticeDetailViewModel.errorMessage)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }
}
