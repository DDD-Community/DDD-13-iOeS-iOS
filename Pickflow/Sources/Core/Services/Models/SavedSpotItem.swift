import Foundation

struct SavedSpotItem: Decodable, Sendable {
    let spotId: Int64
    let name: String
    @LenientSpotTheme var theme: SpotTheme?
    let imageUrl: String?
    let latitude: Double
    let longitude: Double
    let distanceKm: Double?
    let savedAt: String
    let deleted: Bool

    func toSpotListItem() -> SpotListItem {
        SpotListItem(spotId: spotId, name: name, theme: theme, thumbnailUrl: imageUrl, distanceKm: distanceKm, isBookmarked: true)
    }
}

struct SavedSpotPage: Decodable, Sendable {
    let spots: [SavedSpotItem]
    let page: Int
    let hasNext: Bool
}
