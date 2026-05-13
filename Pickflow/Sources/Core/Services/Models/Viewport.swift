import Foundation

struct Viewport: Codable, Sendable, Equatable {
    let topLeft: Coordinate
    let topRight: Coordinate
    let bottomLeft: Coordinate
    let bottomRight: Coordinate
}
