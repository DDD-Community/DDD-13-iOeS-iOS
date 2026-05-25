# KAN-107 — CustomTabBar 가 콘텐츠를 가리는 문제

## 증상

지도 화면 하단의 `MapListToggle` (지도/리스트 토글) 과 `trailingControls` (우측 + / 위치 버튼) 가 `CustomTabBar` 뒤로 깔려서 일부가 잘려 보임. 리스트 모드에서는 `SpotListView` 의 ScrollView 마지막 셀도 동일 현상.

## 세 프로젝트 탭바 패턴 비교

| 항목 | Pickflow (우리, 현재) | Dori | Hambug |
|---|---|---|---|
| 탭바 타입 | Custom (`HStack` 기반) | Custom (`HStack` 기반) | Custom + 기본 `TabView` outer |
| 호스팅 방식 | `safeAreaInset(edge: .bottom, spacing: 0)` | `VStack { content; if visible { tabBar } }` | `ZStack { TabView; VStack { Spacer; tabBar }.ignoresSafeArea(.container, edges: .bottom) }` |
| 콘텐츠 inset 처리 | safeAreaInset 자동 (부모-1회) | VStack 의 layout shift 로 자동 (부모-1회) | 각 콘텐츠 root 에서 `.safeAreaPadding(.bottom, 60~100)` 명시 |
| 탭바 hide 토글 | `if isTabBarVisible` + transition | `if store.isTabBarVisible` + transition | preference key 전파 + `withAnimation` |
| 콘텐츠 가림 | **있었음** (자식 ignoresSafeArea + ZStack layout cascade) | 없음 | 없음 |

세 패턴 모두 유효. 호스팅(`safeAreaInset`) 자체는 Pickflow 가 가장 간결한 SwiftUI 표준 패턴이고, 문제는 자식 view 쪽 layout 설계에 있었다.

## 근본 원인 (두 갈래)

### 1) 자식이 `.ignoresSafeArea(edges: .bottom)` 로 부모 inset 무력화 — `SpotListView`

`HomeMapView.swift` 의 list 모드 진입 코드:
```swift
SpotListView(viewModel: spotList, contentTopInset: ...)
    .ignoresSafeArea(edges: .bottom)   // ← 이게 ContentView 의 safeAreaInset 무력화
    .transition(.opacity)
```
ContentView 의 `safeAreaInset(edge: .bottom)` 은 부모-1회로 콘텐츠 영역을 탭바 높이만큼 자동 inset 한다. 자식이 `.ignoresSafeArea` 를 호출하면 그 효과가 깨진다.

### 2) `NaverMapView().ignoresSafeArea()` 가 ZStack 의 layout cascade 흔듦

```swift
ZStack(alignment: .top) {
    NaverMapView(...).ignoresSafeArea()     // 자식 하나가 풀블리드
    // sibling overlay 들 (MapListToggle, trailingControls, topBar)
}
```
SwiftUI 의 ZStack 은 자식 중 하나가 `.ignoresSafeArea()` 면 부모 ZStack 의 bounds 자체가 풀블리드까지 확장된다. 결과: 다른 sibling overlay (VStack { Spacer; MapListToggle.padding(.bottom, 24) }) 도 풀블리드 bottom 기준으로 정렬 → 탭바 뒤로 깔림.

## 시도한 해법들 (4단계)

### 1차: `SpotListView` 의 `.ignoresSafeArea(edges: .bottom)` 삭제 — ✅ 리스트 부분 해결
- 리스트 모드의 SpotListView 는 ContentView 의 safeAreaInset 을 받아 ScrollView 마지막 셀이 탭바 위에서 자연 종료됨.
- 단 지도 모드의 `MapListToggle` / `trailingControls` 는 여전히 가려짐 (원인 2).

### 2차: `.safeAreaPadding(.bottom)` 적용 — ❌ 효과 부족
- 두 VStack 에 `.safeAreaPadding(.bottom)` modifier 추가.
- ZStack 의 layout cascade 가 더 강해서 modifier 만으로 위치 조정 실패.

### 3차: `GeometryReader.safeAreaInsets` 로 동적 padding — ❌ 성능 우려로 폐기
```swift
GeometryReader { proxy in
    ZStack { ... }
    .padding(.bottom, Padding.containerBottom + proxy.safeAreaInsets.bottom)
}
```
- 정확히 동작하지만 GeometryReader 가 NaverMapView 와 같은 트리에 있어 layout pass 마다 size 측정 + 자식 view 트리 invalidate. 지도 redraw 가 잦은 화면이라 성능 부담.

### 4차: `NaverMapView` 를 `.background` 로 이동 — ✅ ZStack cascade 차단
```swift
ZStack(alignment: .top) {
    // overlay layers 만
}
.background {
    NaverMapView(...).ignoresSafeArea()  // 부모 layout 에 영향 안 줌
}
```
- `.background` 의 자식은 부모 view 의 frame 안에서 layout 받지만, 자기 자신의 `.ignoresSafeArea()` 가 부모 ZStack 의 bounds 결정에 cascade up 하지 않는다.
- ZStack 본체는 safe area 안 normal layout 유지. overlay 들이 자동으로 inset 안에서 배치됨.
- GeometryReader 없이 해결.

### 5차 (최종): `CustomTabBar.height` 상수 + `.padding(.bottom, containerBottom + CustomTabBar.height)`
- 4차 후에도 디자인 의도 (탭바 위로 충분히 떠 있는 토글) 와 위치 차이 발생.
- `CustomTabBar` 에 `static let height: CGFloat = 60` 노출 (icon 24 + spacing 8 + label ~14 + top padding 14, safe area 별도).
- HomeMapView 의 두 VStack `.padding(.bottom)` 에 그 값을 더함:
  ```swift
  .padding(.bottom, Padding.containerBottom + CustomTabBar.height)
  ```
- ZStack layout 동작과 무관하게 절대값 기준으로 정확한 위치 보장.

## 최종 코드

```swift
// CustomTabBar.swift
struct CustomTabBar: View {
    /// CustomTabBar 컨텐츠 높이(아이콘 24 + spacing 8 + label ~14 + top padding 14).
    /// safe area inset 은 별도. 콘텐츠를 탭바 위로 올리고 싶을 때 padding.bottom 에 더한다.
    static let height: CGFloat = 60
    @Binding var selectedTab: Tab
    ...
}

// HomeMapView.swift
NavigationStack {
    ZStack(alignment: .top) {
        // List overlay, top bar, bottom trailing, bottom toggle ...
        if mapListMode == .map {
            VStack { Spacer(); HStack { Spacer(); trailingControls
                .padding(.trailing, Padding.containerHorizontal)
                .padding(.bottom, Padding.containerBottom + CustomTabBar.height) } }
        }
        VStack { Spacer(); MapListToggle(selectedMode: $mapListMode)
            .padding(.bottom, Padding.containerBottom + CustomTabBar.height) }
    }
    .background {
        NaverMapView(...).ignoresSafeArea()
    }
    .onChange(of: selectedMood) { ... }
    .navigationDestination(...) { ... }
}
```

## Lesson

- `safeAreaInset` 호스팅 패턴은 부모-1회로 콘텐츠 영역을 자동 inset 한다. **자식이 `.ignoresSafeArea` 를 쓰면 그 효과가 깨진다.**
- ZStack 의 한 자식이 `.ignoresSafeArea` 면 ZStack 의 bounds 자체가 풀블리드까지 확장되어 다른 sibling 의 alignment 도 영향 받는다. 풀블리드가 필요한 view (지도 등) 는 **`.background` 로 분리**해서 부모 layout cascade 를 차단한다.
- `GeometryReader.safeAreaInsets` 는 정확한 값을 주지만 **layout pass 마다 자식 트리를 invalidate** 한다. 지도/맵뷰처럼 redraw 가 잦은 화면에서는 비용이 크다 — 정적 상수 + `.padding` 조합이 더 가볍다.
- "콘텐츠가 탭바에 가려진다" → 호스팅(부모) 만 보지 말고 자식 view 의 `.ignoresSafeArea` / ZStack layout cascade / GeometryReader 남용을 차례로 의심해야 한다.
- 탭바처럼 시스템 컴포넌트가 아닌 Custom view 의 높이가 다른 view 의 padding 계산에 필요하면, **그 view 의 정적 상수로 노출**해서 magic number 분산을 막는다 (`CustomTabBar.height`).

## Critical Files
- `Pickflow/Sources/Feature/Map/HomeMapView.swift` — `SpotListView` 의 `.ignoresSafeArea(edges: .bottom)` 삭제, `NaverMapView` 를 `.background` 로 이동, MapListToggle / trailingControls padding.bottom 에 `CustomTabBar.height` 추가.
- `Pickflow/Sources/App/CustomTabBarView/CustomTabBar.swift` — `static let height: CGFloat = 60` 상수 노출.
