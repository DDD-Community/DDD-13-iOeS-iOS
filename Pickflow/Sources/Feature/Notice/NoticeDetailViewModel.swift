import Foundation

@MainActor
final class NoticeDetailViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(NoticeDetail)
        case failed(String)
    }

    static let errorMessage = "공지사항을 불러오지 못했어요"

    @Published private(set) var state: LoadState = .idle

    private let postId: Int64
    private let masterId: Int64
    private let noticeService: NoticeServiceProtocol

    init(postId: Int64, noticeService: NoticeServiceProtocol, masterId: Int64 = 1) {
        self.postId = postId
        self.noticeService = noticeService
        self.masterId = masterId
    }

    func onAppear() async {
        guard case .idle = state else { return }
        await load()
    }

    func retry() async {
        await load()
    }

    private func load() async {
        state = .loading
        do {
            let detail = try await noticeService.fetchNoticeDetail(postId: postId, masterId: masterId)
            state = .loaded(detail)
        } catch {
            state = .failed(Self.errorMessage)
        }
    }
}
