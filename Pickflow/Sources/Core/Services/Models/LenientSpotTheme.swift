import Foundation

/// 카테고리 코드가 모르는 값이거나 아예 없어도 응답 전체를 깨뜨리지 않게 감싸는 래퍼.
///
/// 서버가 카테고리를 추가하면 앱을 배포하기 전까지 그 코드를 해석할 수 없다.
/// 그때 디코딩이 던져지면 스팟 하나 때문에 **목록 전체**가 "불러오지 못했어요" 로 떨어지므로,
/// 해석 못 한 값은 `nil` 로 흘려보내고 화면에서는 카테고리 표기만 생략한다.
///
/// 필터링은 서버가 하므로(`?theme=...`), 해석 못 한 스팟이 필터 결과에 섞일 일은 없다.
/// 전체 조회에서만 나타나고, 거기서는 노출되는 게 맞는 동작이다.
@propertyWrapper
struct LenientSpotTheme: Codable, Sendable, Equatable {
    var wrappedValue: SpotTheme?

    init(wrappedValue: SpotTheme?) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let code = try? container.decode(String.self)
        wrappedValue = code.flatMap(SpotTheme.init(apiCode:))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        if let wrappedValue {
            try container.encode(wrappedValue.apiCode)
        } else {
            try container.encodeNil()
        }
    }
}

extension KeyedDecodingContainer {
    /// 키 자체가 빠져 있어도 실패하지 않게 한다.
    /// 합성된 `Decodable` 이 이 오버로드를 집어간다.
    func decode(_ type: LenientSpotTheme.Type, forKey key: Key) throws -> LenientSpotTheme {
        try decodeIfPresent(type, forKey: key) ?? LenientSpotTheme(wrappedValue: nil)
    }
}
