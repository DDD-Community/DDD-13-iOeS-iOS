import CoreLocation
@preconcurrency import NMapsMap
import SwiftUI

struct SpotLocationDetailMapView: UIViewControllerRepresentable {
    let initialCoordinate: Coordinate
    var userLocation: Coordinate?
    var cameraMoveRequest: CameraMoveRequest?
    var onCenterCoordinateChange: ((Coordinate) -> Void)?

    func makeUIViewController(context: Context) -> SpotLocationDetailMapViewController {
        let vc = SpotLocationDetailMapViewController()
        vc.configure(initialCoordinate: initialCoordinate)
        return vc
    }

    func updateUIViewController(_ vc: SpotLocationDetailMapViewController, context: Context) {
        vc.onCenterCoordinateChange = onCenterCoordinateChange
        vc.updateUserLocation(userLocation)
        if let request = cameraMoveRequest {
            vc.applyCameraMoveRequest(request)
        }
    }
}

@MainActor
final class SpotLocationDetailMapViewController: UIViewController, @preconcurrency NMFMapViewCameraDelegate {
    var onCenterCoordinateChange: ((Coordinate) -> Void)?

    private var naverMapView: NMFNaverMapView?
    private var lastAppliedCameraRequestId: UUID?
    private var initialCoordinate: Coordinate = Coordinate(latitude: 37.5665, longitude: 126.9780)

    func configure(initialCoordinate: Coordinate) {
        self.initialCoordinate = initialCoordinate
    }

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

        let initial = NMGLatLng(lat: initialCoordinate.latitude, lng: initialCoordinate.longitude)
        let cameraPosition = NMFCameraPosition(initial, zoom: 16)
        mapView.mapView.moveCamera(NMFCameraUpdate(position: cameraPosition))
        mapView.mapView.addCameraDelegate(delegate: self)
    }

    func updateUserLocation(_ coordinate: Coordinate?) {
        guard let mapView = naverMapView?.mapView else { return }
        let overlay = mapView.locationOverlay
        if let coordinate {
            overlay.location = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
            overlay.icon = NMFOverlayImage(image: Self.userLocationDotImage)
            overlay.iconWidth = 22
            overlay.iconHeight = 22
            overlay.circleColor = UIAsset.Colors.sunsetOrange.uiColor.withAlphaComponent(0.25)
            overlay.hidden = false
        } else {
            overlay.hidden = true
        }
    }

    private static let userLocationDotImage: UIImage = {
        let size = CGSize(width: 22, height: 22)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = max(UIScreen.main.scale, 3.0)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(origin: .zero, size: size))
            cg.setFillColor(UIAsset.Colors.sunsetOrange.uiColor.cgColor)
            cg.fillEllipse(in: CGRect(origin: .zero, size: size).insetBy(dx: 3, dy: 3))
        }
    }()

    func applyCameraMoveRequest(_ request: CameraMoveRequest) {
        guard request.id != lastAppliedCameraRequestId else { return }
        guard let mapView = naverMapView?.mapView else { return }
        // 이 화면(주소 선택)은 단일 좌표 이동만 쓴다 — 지역(bounds) 이동은 탐색 지도 전용.
        guard case let .point(coordinate, zoom, _) = request.target else { return }
        lastAppliedCameraRequestId = request.id
        let latlng = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        let position = NMFCameraPosition(latlng, zoom: zoom ?? mapView.zoomLevel)
        let update = NMFCameraUpdate(position: position)
        update.animation = .easeOut
        mapView.moveCamera(update)
    }

    nonisolated func mapViewCameraIdle(_ mapView: NMFMapView) {
        let target = mapView.cameraPosition.target
        let coordinate = Coordinate(latitude: target.lat, longitude: target.lng)
        Task { @MainActor in
            self.onCenterCoordinateChange?(coordinate)
        }
    }
}
