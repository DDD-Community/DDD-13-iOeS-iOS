import Foundation

@MainActor
final class NoticeListViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded([NoticeListItem])
        case empty
        case failed(String)
    }

    static let errorMessage = "공지사항을 불러오지 못했어요"

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var isLoadingNextPage = false

    private let noticeService: NoticeServiceProtocol
    private let masterId: Int64
    private var currentPage = 0
    private var hasNext = false

    init(noticeService: NoticeServiceProtocol, masterId: Int64 = 1) {
        self.noticeService = noticeService
        self.masterId = masterId
    }

    func onAppear() async {
        guard case .idle = state else { return }
        await loadFirstPage()
    }

    func retry() async {
        await loadFirstPage()
    }

    func loadNextPageIfNeeded(currentItem: NoticeListItem) async {
        guard case let .loaded(items) = state else { return }
        guard hasNext, !isLoadingNextPage else { return }
        guard currentItem.id == items.last?.id else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }
        do {
            let page = try await noticeService.fetchNotices(masterId: masterId, page: currentPage + 1)
            currentPage = page.page
            hasNext = page.hasNext
            state = .loaded(items + page.items)
        } catch {
            // 다음 페이지 로드 실패는 기존 목록을 유지한 채 조용히 중단. hasNext 유지로 재시도 가능.
        }
    }

    private func loadFirstPage() async {
        state = .loading
        do {
            let page = try await noticeService.fetchNotices(masterId: masterId, page: 0)
            currentPage = page.page
            hasNext = page.hasNext
            state = page.items.isEmpty ? .empty : .loaded(page.items)
        } catch {
            state = .failed(Self.errorMessage)
        }
    }
}
