import Foundation

/// 사용자가 직접 등록한 my spot. 큐레이션과 분리된 모델 — 클러스터링에 참여하지 않고 단일 마커로 표시된다.
struct MySpot: Codable, Sendable, Identifiable, Equatable {
    let id: Int64
    let coordinate: Coordinate
}
