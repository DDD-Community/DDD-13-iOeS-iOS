import CoreLocation
@preconcurrency import NMapsMap
import SwiftUI

/// `NMCClusterer` 사용은 `UIViewController` + `UIViewControllerRepresentable` 래핑 필수.
/// `UIViewRepresentable`(NMFNaverMapView 직접 반환) 형태에서는 `leafMarkerUpdater`/`clusterMarkerUpdater`
/// 콜백이 호출되지 않는 이슈가 KAN-82 검증에서 확인됨.
/// 동일 좌표 재탭에서도 카메라 이동이 다시 트리거되도록 UUID 기반 식별자를 함께 보낸다.
struct CameraMoveRequest: Equatable {
    let id: UUID
    let coordinate: Coordinate
    let zoom: Double?

    init(coordinate: Coordinate, zoom: Double? = nil) {
        self.id = UUID()
        self.coordinate = coordinate
        self.zoom = zoom
    }
}

struct NaverMapView: UIViewControllerRepresentable {
    var spots: [ClusterableSpot] = []
    var mySpots: [MySpot] = []
    var selectedSpotId: Int64?
    var cameraMoveRequest: CameraMoveRequest?
    var userLocation: Coordinate?
    var onViewportChange: ((Viewport) -> Void)?
    var onSpotTap: ((Int64) -> Void)?
    var onMapBackgroundTap: (() -> Void)?

    func makeUIViewController(context: Context) -> NaverMapViewController {
        NaverMapViewController()
    }

    func updateUIViewController(_ vc: NaverMapViewController, context: Context) {
        vc.onViewportChange = onViewportChange
        vc.onSpotTap = onSpotTap
        vc.onMapBackgroundTap = onMapBackgroundTap
        vc.update(spots: spots, mySpots: mySpots, selectedSpotId: selectedSpotId)
        vc.updateUserLocation(userLocation)
        if let request = cameraMoveRequest {
            vc.applyCameraMoveRequest(request)
        }
    }
}

// MARK: - ViewController

@MainActor
final class NaverMapViewController: UIViewController, @preconcurrency NMFMapViewCameraDelegate, @preconcurrency NMFMapViewTouchDelegate {
    var onViewportChange: ((Viewport) -> Void)?
    var onSpotTap: ((Int64) -> Void)?
    var onMapBackgroundTap: (() -> Void)?
    fileprivate var selectedSpotId: Int64?

    private var naverMapView: NMFNaverMapView?
    private var clusterer: NMCClusterer<MapSpotClusterKey>?
    private var idleTask: Task<Void, Never>?
    private let debounceMillis: Int = 300
    private var hasTriggeredInitialViewport = false
    private var lastAppliedCameraRequestId: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let mapView = NMFNaverMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.showZoomControls = false
        mapView.showCompass = false
        mapView.showScaleBar = false
        mapView.showLocationButton = false
        mapView.mapView.isNightModeEnabled = true
        view.addSubview(mapView)
        self.naverMapView = mapView

        // 디버그 fixture(왕십리·영동대교·잠원) 영역이 한 화면에 보이도록 카메라 + 줌 설정.
        let cameraPosition = NMFCameraPosition(
            NMGLatLng(lat: 37.538, lng: 127.038),
            zoom: 12.5
        )
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        mapView.mapView.moveCamera(cameraUpdate)

        mapView.mapView.addCameraDelegate(delegate: self)
        mapView.mapView.touchDelegate = self

        // clusterer는 update(spots:)마다 재생성 — NMC SDK가 mapView 설정 시점에만 클러스터링 트리거하므로
        // 동적 spots 갱신을 위해 매번 fresh clusterer를 만든다.
    }

    private var lastSpotIdsHash: Int?
    private var lastMySpotIdsHash: Int?
    private var mySpotMarkers: [NMFMarker] = []
    fileprivate var leafMarkerRefs: [Int64: NMFMarker] = [:]
    private var mySpotMarkerRefs: [Int64: NMFMarker] = [:]
    /// spotId → 로드 완료된 마커 이미지. 뷰포트 재진입 시 동기 렌더 경로에서 즉시 재사용한다.
    fileprivate var loadedImages: [Int64: UIImage] = [:]
    private var imageLoadTask: Task<Void, Never>?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasTriggeredInitialViewport, let mapView = naverMapView?.mapView else { return }
        hasTriggeredInitialViewport = true
        // 첫 진입 시 cameraIdle 자동 호출이 보장되지 않으므로 한 번 트리거.
        mapViewCameraIdle(mapView)
    }

    func update(spots: [ClusterableSpot], mySpots: [MySpot], selectedSpotId: Int64?) {
        let previousSelected = self.selectedSpotId
        self.selectedSpotId = selectedSpotId
        guard let mapView = naverMapView?.mapView else { return }
        updateCurationClusterer(spots: spots, mapView: mapView)
        if previousSelected != selectedSpotId {
            // clusterer 재생성 없이 leaf marker iconImage만 교체 — cluster 위치 안정 유지.
            applyLeafSelectionDelta(previous: previousSelected, current: selectedSpotId)
        }
        updateMySpotMarkers(mySpots: mySpots, mapView: mapView)
        loadMarkerImages(spots: spots, mySpots: mySpots)
    }

    func updateUserLocation(_ coordinate: Coordinate?) {
        guard let mapView = naverMapView?.mapView else { return }
        let overlay = mapView.locationOverlay
        if let coordinate {
            overlay.location = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
            overlay.icon = NMFOverlayImage(image: Self.userLocationDotImage)
            overlay.iconWidth = 18
            overlay.iconHeight = 18
            overlay.circleColor = UIAsset.Colors.sunsetOrange.uiColor.withAlphaComponent(0.25)
            overlay.hidden = false
        } else {
            overlay.hidden = true
        }
    }

    /// locationOverlay 아이콘 스펙: 18pt 전체 / 흰 테두리 ~2.5pt / 안쪽 disc ~13pt.
    /// 색만 sunsetOrange 로 교체.
    private static let userLocationDotImage: UIImage = {
        let size = CGSize(width: 18, height: 18)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = max(UIScreen.main.scale, 3.0)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(origin: .zero, size: size))
            cg.setFillColor(UIAsset.Colors.sunsetOrange.uiColor.cgColor)
            cg.fillEllipse(in: CGRect(origin: .zero, size: size).insetBy(dx: 2.5, dy: 2.5))
        }
    }()

    func applyCameraMoveRequest(_ request: CameraMoveRequest) {
        guard request.id != lastAppliedCameraRequestId else { return }
        guard let mapView = naverMapView?.mapView else { return }
        lastAppliedCameraRequestId = request.id
        let latlng = NMGLatLng(
            lat: request.coordinate.latitude,
            lng: request.coordinate.longitude
        )
        let position = NMFCameraPosition(latlng, zoom: request.zoom ?? mapView.zoomLevel)
        let update = NMFCameraUpdate(position: position)
        update.animation = .easeOut
        mapView.moveCamera(update)
    }

    fileprivate func applyLeafSelectionDelta(previous: Int64?, current: Int64?) {
        if let previous, let marker = leafMarkerRefs[previous] {
            marker.iconImage = NMFOverlayImage(image: ClusteringMarkerImage.spotMarker(isSelected: false, image: loadedImages[previous]))
        }
        if let current, let marker = leafMarkerRefs[current] {
            marker.iconImage = NMFOverlayImage(image: ClusteringMarkerImage.spotMarker(isSelected: true, image: loadedImages[current]))
        }
    }

    private func updateCurationClusterer(spots: [ClusterableSpot], mapView: NMFMapView) {
        // clusterer 재생성은 spots 변경 시만 — selectedSpotId 변경은 별도로 leaf marker만 갱신.
        let newHash = spots.map(\.id).reduce(into: Hasher()) { $0.combine($1) }.finalize()
        guard newHash != lastSpotIdsHash else { return }
        lastSpotIdsHash = newHash
        leafMarkerRefs.removeAll()

        clusterer?.mapView = nil

        let builder = NMCBuilder<MapSpotClusterKey>()
        builder.maxZoom = 15
        builder.leafMarkerUpdater = MapLeafMarkerUpdater(controller: self)
        builder.clusterMarkerUpdater = MapClusterMarkerUpdater()
        let newClusterer = builder.build()
        let pairs: [(MapSpotClusterKey, NSObject)] = spots.map { spot in
            (MapSpotClusterKey(spot: spot), NSNull())
        }
        newClusterer.addAll(Dictionary(uniqueKeysWithValues: pairs))
        newClusterer.mapView = mapView
        clusterer = newClusterer
    }

    /// my spots는 클러스터링 미참여. NMCClusterer 외부에서 NMFMarker로 직접 add/remove.
    private func updateMySpotMarkers(mySpots: [MySpot], mapView: NMFMapView) {
        var hasher = Hasher()
        for id in mySpots.map(\.id) { hasher.combine(id) }
        hasher.combine(selectedSpotId)  // 선택 변경 시 my marker 재렌더 위해 포함
        let newHash = hasher.finalize()
        guard newHash != lastMySpotIdsHash else { return }
        lastMySpotIdsHash = newHash

        // 기존 my markers 제거.
        for marker in mySpotMarkers {
            marker.mapView = nil
        }
        mySpotMarkers.removeAll()
        mySpotMarkerRefs.removeAll()

        // 신규 my markers 추가.
        let currentSelectedId = selectedSpotId
        for spot in mySpots {
            let isSelected = (spot.id == currentSelectedId)
            let marker = NMFMarker(position: NMGLatLng(
                lat: spot.coordinate.latitude,
                lng: spot.coordinate.longitude
            ))
            marker.iconImage = NMFOverlayImage(image: ClusteringMarkerImage.mySpotMarker(isSelected: isSelected, image: loadedImages[spot.id]))
            marker.width = MyClusterPinView.diameter
            marker.height = MyClusterPinView.diameter
            marker.anchor = CGPoint(x: 0.5, y: 0.5)
            marker.zIndex = 250  // 큐레이션 클러스터(300)보다 낮고 리프(200)보다 높음
            marker.isForceShowIcon = true
            let spotId = spot.id
            let box = WeakControllerBox(self)
            marker.touchHandler = { _ in
                MainActor.assumeIsolated {
                    box.ref?.handleSpotTap(spotId)
                }
                return true
            }
            marker.mapView = mapView
            mySpotMarkers.append(marker)
            mySpotMarkerRefs[spot.id] = marker
        }
    }

    /// 마커 URL을 비동기로 UIImage 로드 후, 살아있는 marker의 iconImage를 교체한다.
    /// ImageRenderer가 동기라 뷰 내부 AsyncImage는 불가 — 미리 로드해 주입하는 방식.
    private func loadMarkerImages(spots: [ClusterableSpot], mySpots: [MySpot]) {
        imageLoadTask?.cancel()
        var targets: [(id: Int64, url: String)] = []
        for spot in spots where loadedImages[spot.id] == nil {
            targets.append((spot.id, spot.imageUrl))
        }
        for spot in mySpots where loadedImages[spot.id] == nil {
            targets.append((spot.id, spot.imageUrl))
        }
        guard !targets.isEmpty else { return }

        imageLoadTask = Task { [weak self] in
            await withTaskGroup(of: (Int64, UIImage?).self) { group in
                for target in targets {
                    group.addTask {
                        (target.id, await MarkerImageLoader.shared.image(for: target.url))
                    }
                }
                for await (id, image) in group {
                    guard let image else { continue }
                    await MainActor.run { self?.applyLoadedImage(spotId: id, image: image) }
                }
            }
        }
    }

    private func applyLoadedImage(spotId: Int64, image: UIImage) {
        loadedImages[spotId] = image
        let isSelected = (spotId == selectedSpotId)
        if let marker = leafMarkerRefs[spotId] {
            marker.iconImage = NMFOverlayImage(image: ClusteringMarkerImage.spotMarker(isSelected: isSelected, image: image))
        }
        if let marker = mySpotMarkerRefs[spotId] {
            marker.iconImage = NMFOverlayImage(image: ClusteringMarkerImage.mySpotMarker(isSelected: isSelected, image: image))
        }
    }

    // MARK: - NMFMapViewCameraDelegate

    func mapViewCameraIdle(_ mapView: NMFMapView) {
        idleTask?.cancel()
        let viewport = Self.viewport(from: mapView)
        let millis = debounceMillis
        idleTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(millis))
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.onViewportChange?(viewport) }
        }
    }

    // MARK: - NMFMapViewTouchDelegate

    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        // 빈 공간 탭 시 선택 해제.
        onMapBackgroundTap?()
    }

    private static func viewport(from mapView: NMFMapView) -> Viewport {
        let bounds = mapView.contentBounds
        let neLat = bounds.northEastLat
        let neLng = bounds.northEastLng
        let swLat = bounds.southWestLat
        let swLng = bounds.southWestLng
        return Viewport(
            topLeft: Coordinate(latitude: neLat, longitude: swLng),
            topRight: Coordinate(latitude: neLat, longitude: neLng),
            bottomLeft: Coordinate(latitude: swLat, longitude: swLng),
            bottomRight: Coordinate(latitude: swLat, longitude: neLng)
        )
    }

    fileprivate func handleSpotTap(_ spotId: Int64) {
        onSpotTap?(spotId)
    }
}

// MARK: - SwiftUI → UIImage 어댑터

/// NaverMap 마커 콜백은 메인 스레드에서 호출되므로 `MainActor.assumeIsolated`로 SwiftUI ImageRenderer를 안전하게 호출.
enum ClusteringMarkerImage {
    static func cluster(count: Int) -> UIImage {
        MainActor.assumeIsolated {
            render(ClusterPinView(count: count), size: ClusterPinView.diameter(forCount: count))
        }
    }

    static func spotMarker(isSelected: Bool, image: UIImage? = nil) -> UIImage {
        MainActor.assumeIsolated {
            render(SpotMarkerView(isSelected: isSelected, image: image), size: 44)
        }
    }

    static func mySpotMarker(isSelected: Bool, image: UIImage? = nil) -> UIImage {
        MainActor.assumeIsolated {
            render(MyClusterPinView(isSelected: isSelected, image: image), size: MyClusterPinView.diameter)
        }
    }

    @MainActor
    private static func render<V: View>(_ view: V, size: CGFloat) -> UIImage {
        let renderer = ImageRenderer(content: view.frame(width: size, height: size))
        // 마커 jagged 방지 — UIScreen scale의 1.5배로 충분한 해상도 확보 (NMFOverlayImage가 다시 sample 시 부드럽게).
        renderer.scale = max(UIScreen.main.scale, 3.0) * 1.5
        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - Marker Updaters

/// `marker.touchHandler` 등 nonisolated 클로저에서 `NaverMapViewController`(@MainActor) reference를 캡처할 때
/// Swift 6 strict concurrency가 data race 경고를 띄운다. weak reference를 sendable wrapper로 감싸 우회.
/// (NMC SDK는 메인 스레드에서 콜백을 호출한다는 외부 약속을 기반으로 한다.)
private final class WeakControllerBox: @unchecked Sendable {
    weak var ref: NaverMapViewController?
    init(_ ref: NaverMapViewController?) { self.ref = ref }
}

private final class MapLeafMarkerUpdater: NMCDefaultLeafMarkerUpdater {
    weak var controller: NaverMapViewController?

    init(controller: NaverMapViewController) {
        self.controller = controller
        super.init()
    }

    override func updateLeafMarker(_ info: NMCLeafMarkerInfo, _ marker: NMFMarker) {
        super.updateLeafMarker(info, marker)
        // tag는 NSNull이므로 cluster key에서 spot id 추출 (NMC SDK 헤더상 info.key가 NMCClusteringKey).
        let spotId = (info.key as? MapSpotClusterKey)?.spotId
        let (isSelected, image): (Bool, UIImage?) = MainActor.assumeIsolated { [weak controller] in
            guard let spotId, let controller else { return (false, nil) }
            controller.leafMarkerRefs[spotId] = marker  // selected 토글용 reference 등록 (clusterer 재생성 없이 iconImage 교체)
            return (spotId == controller.selectedSpotId, controller.loadedImages[spotId])
        }
        let img = ClusteringMarkerImage.spotMarker(isSelected: isSelected, image: image)

        marker.iconImage = NMFOverlayImage(image: img)
        marker.width = 44
        marker.height = 44
        marker.anchor = CGPoint(x: 0.5, y: 0.5)
        marker.captionText = ""
        marker.zIndex = 200
        marker.isForceShowIcon = true

        if let spotId {
            let box = WeakControllerBox(controller)
            marker.touchHandler = { _ in
                MainActor.assumeIsolated {
                    box.ref?.handleSpotTap(spotId)
                }
                return true
            }
        }
    }
}

private final class MapClusterMarkerUpdater: NMCDefaultClusterMarkerUpdater {
    override func updateClusterMarker(_ info: NMCClusterMarkerInfo, _ marker: NMFMarker) {
        super.updateClusterMarker(info, marker)
        let count = info.size
        let diameter = ClusterPinView.diameter(forCount: count)
        let img = ClusteringMarkerImage.cluster(count: count)

        marker.iconImage = NMFOverlayImage(image: img)
        marker.width = diameter
        marker.height = diameter
        marker.anchor = CGPoint(x: 0.5, y: 0.5)
        marker.captionText = ""
        marker.zIndex = 300
        marker.isForceShowIcon = true
    }
}
