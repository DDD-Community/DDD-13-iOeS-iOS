import Foundation

struct ClusterableSpot: Codable, Sendable, Identifiable, Equatable {
    let id: Int64
    let coordinate: Coordinate
}
