import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pickflow

@MainActor
final class MapClusteringSnapshotTests: XCTestCase {

    // MARK: - Layout 헬퍼

    /// 핀 컴포넌트는 작은 SwiftUI 뷰. sizeThatFits로 콘텐츠 크기 그대로 찍는다.
    private let pinLayout: SwiftUISnapshotLayout = .sizeThatFits

    private func assertPin<V: View>(
        of view: V,
        named name: String,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            of: view,
            as: .image(layout: pinLayout, traits: .init(displayScale: 3)),
            named: name,
            file: file,
            testName: testName,
            line: line
        )
    }

    // MARK: - ClusterPinView (8 cases)

    func test_clusterPin_count2_light() {
        assertPin(of: ClusterPinView(count: 2).snapshotEnvironment(colorScheme: .light), named: "cluster-pin-count2-light")
    }

    func test_clusterPin_count2_dark() {
        assertPin(of: ClusterPinView(count: 2).snapshotEnvironment(colorScheme: .dark), named: "cluster-pin-count2-dark")
    }

    func test_clusterPin_count12_light() {
        assertPin(of: ClusterPinView(count: 12).snapshotEnvironment(colorScheme: .light), named: "cluster-pin-count12-light")
    }

    func test_clusterPin_count12_dark() {
        assertPin(of: ClusterPinView(count: 12).snapshotEnvironment(colorScheme: .dark), named: "cluster-pin-count12-dark")
    }

    func test_clusterPin_count75_light() {
        assertPin(of: ClusterPinView(count: 75).snapshotEnvironment(colorScheme: .light), named: "cluster-pin-count75-light")
    }

    func test_clusterPin_count75_dark() {
        assertPin(of: ClusterPinView(count: 75).snapshotEnvironment(colorScheme: .dark), named: "cluster-pin-count75-dark")
    }

    func test_clusterPin_count150_light() {
        assertPin(of: ClusterPinView(count: 150).snapshotEnvironment(colorScheme: .light), named: "cluster-pin-count150-light")
    }

    func test_clusterPin_count150_dark() {
        assertPin(of: ClusterPinView(count: 150).snapshotEnvironment(colorScheme: .dark), named: "cluster-pin-count150-dark")
    }

    func test_clusterPin_count12_a11y_light() {
        assertPin(
            of: ClusterPinView(count: 12)
                .snapshotEnvironment(colorScheme: .light, dynamicType: .accessibility3),
            named: "cluster-pin-count12-a11y-light"
        )
    }

    func test_clusterPin_count12_selected_light() {
        assertPin(
            of: ClusterPinView(count: 12, isSelected: true).snapshotEnvironment(colorScheme: .light),
            named: "cluster-pin-count12-selected-light"
        )
    }

    func test_clusterPin_count12_selected_dark() {
        assertPin(
            of: ClusterPinView(count: 12, isSelected: true).snapshotEnvironment(colorScheme: .dark),
            named: "cluster-pin-count12-selected-dark"
        )
    }

    // MARK: - MyClusterPinView (3 cases — 단일 디자인)

    func test_myClusterPin_light() {
        assertPin(of: MyClusterPinView().snapshotEnvironment(colorScheme: .light), named: "my-cluster-pin-light")
    }

    func test_myClusterPin_dark() {
        assertPin(of: MyClusterPinView().snapshotEnvironment(colorScheme: .dark), named: "my-cluster-pin-dark")
    }

    func test_myClusterPin_a11y_dark() {
        assertPin(
            of: MyClusterPinView()
                .snapshotEnvironment(colorScheme: .dark, dynamicType: .accessibility3),
            named: "my-cluster-pin-a11y-dark"
        )
    }

    func test_myClusterPin_selected_light() {
        assertPin(
            of: MyClusterPinView(isSelected: true).snapshotEnvironment(colorScheme: .light),
            named: "my-cluster-pin-selected-light"
        )
    }

    func test_myClusterPin_selected_dark() {
        assertPin(
            of: MyClusterPinView(isSelected: true).snapshotEnvironment(colorScheme: .dark),
            named: "my-cluster-pin-selected-dark"
        )
    }

    // MARK: - SpotMarkerView (4 cases)

    func test_spotMarker_default_light() {
        assertPin(of: SpotMarkerView(isSelected: false).snapshotEnvironment(colorScheme: .light), named: "spot-marker-default-light")
    }

    func test_spotMarker_default_dark() {
        assertPin(of: SpotMarkerView(isSelected: false).snapshotEnvironment(colorScheme: .dark), named: "spot-marker-default-dark")
    }

    func test_spotMarker_selected_light() {
        assertPin(of: SpotMarkerView(isSelected: true).snapshotEnvironment(colorScheme: .light), named: "spot-marker-selected-light")
    }

    func test_spotMarker_selected_dark() {
        assertPin(of: SpotMarkerView(isSelected: true).snapshotEnvironment(colorScheme: .dark), named: "spot-marker-selected-dark")
    }
}
