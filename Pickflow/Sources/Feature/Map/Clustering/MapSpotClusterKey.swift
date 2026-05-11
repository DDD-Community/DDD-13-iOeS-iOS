import Foundation
import NMapsMap

// NMFMarker는 메인 스레드에서만 사용한다는 전제로 @unchecked Sendable 적용.
// MapLeafMarkerUpdater가 main thread에서 호출되는 NMC 콜백 안에서만 marker reference를 잡고,
// applySelectionDelta도 NaverMapViewController(@MainActor)에서만 호출하므로 main 스레드 격리됨.
extension NMFMarker: @unchecked @retroactive Sendable {}

/// `NMCClusterer`가 받아들이는 클러스터링 키. `ClusterableSpot`을 NMCClusteringKey로 어댑팅한다.
final class MapSpotClusterKey: NSObject, NMCClusteringKey {
    let spotId: Int64
    let position: NMGLatLng

    init(spot: ClusterableSpot) {
        self.spotId = spot.id
        self.position = NMGLatLng(
            lat: spot.coordinate.latitude,
            lng: spot.coordinate.longitude
        )
        super.init()
    }

    private init(spotId: Int64, position: NMGLatLng) {
        self.spotId = spotId
        self.position = position
        super.init()
    }

    override var hash: Int { Int(spotId) }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MapSpotClusterKey else { return false }
        return other.spotId == spotId
    }

    func copy(with zone: NSZone? = nil) -> Any {
        MapSpotClusterKey(
            spotId: spotId,
            position: NMGLatLng(lat: position.lat, lng: position.lng)
        )
    }
}
