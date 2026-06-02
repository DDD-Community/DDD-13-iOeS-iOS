import UIKit

/// 지도 마커용 원격 이미지 로더.
/// 마커는 `ImageRenderer`로 동기 렌더되므로 SwiftUI `AsyncImage`를 쓸 수 없다.
/// URL을 미리 `UIImage`로 받아 뷰에 주입하기 위한 전용 로더이며, NSCache 캐싱과 in-flight 중복 제거를 한다.
actor MarkerImageLoader {
    static let shared = MarkerImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    /// 빈 문자열/잘못된 URL/다운로드·디코드 실패 시 `nil`을 반환해 호출부가 placeholder로 폴백하도록 한다.
    func image(for urlString: String) async -> UIImage? {
        guard !urlString.isEmpty else { return nil }

        let key = urlString as NSString
        if let cached = cache.object(forKey: key) { return cached }
        if let existing = inFlight[urlString] { return await existing.value }

        let task = Task<UIImage?, Never> {
            guard let url = URL(string: urlString),
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data)
            else { return nil }
            return image
        }
        inFlight[urlString] = task
        let result = await task.value
        inFlight[urlString] = nil

        if let result { cache.setObject(result, forKey: key) }
        return result
    }
}
