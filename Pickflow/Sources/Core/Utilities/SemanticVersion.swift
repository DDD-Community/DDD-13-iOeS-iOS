import Foundation

/// `1.10.0` 처럼 `.`으로 구분된 버전 문자열을 숫자 단위로 비교하기 위한 값 타입.
///
/// 문자열 비교(`"1.10.0" < "1.2.0"`)의 오류를 피하기 위해 각 컴포넌트를 정수로 변환해 비교한다.
/// 컴포넌트 개수가 다르면 부족한 쪽을 `0`으로 채워 비교한다. (예: `1.3` == `1.3.0`)
struct SemanticVersion: Comparable, Equatable, Sendable {
    let components: [Int]

    /// 버전 문자열을 파싱한다. 빈 문자열이거나 숫자가 아닌 컴포넌트가 있으면 `nil`을 반환한다.
    init?(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        var parsed: [Int] = []
        for part in trimmed.split(separator: ".", omittingEmptySubsequences: false) {
            guard let number = Int(part), number >= 0 else { return nil }
            parsed.append(number)
        }
        self.components = parsed
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return false }
        }
        return true
    }
}
