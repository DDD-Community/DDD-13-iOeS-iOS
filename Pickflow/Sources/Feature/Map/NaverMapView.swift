import NMapsMap
import SwiftUI

struct NaverMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> NMFNaverMapView {
        let mapView = NMFNaverMapView()
        mapView.showZoomControls = false
        mapView.showCompass = false
        mapView.showScaleBar = false
        mapView.showLocationButton = false
        // MARK: 다크 모드 고정
        mapView.mapView.isNightModeEnabled = true
        return mapView
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {}
}
