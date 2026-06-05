import XCTest
@testable import Pickflow

final class SemanticVersionTests: XCTestCase {

    // MARK: - 파싱

    func test_init_정상버전문자열을_컴포넌트로파싱한다() {
        XCTAssertEqual(SemanticVersion("1.3.0")?.components, [1, 3, 0])
        XCTAssertEqual(SemanticVersion("1")?.components, [1])
        XCTAssertEqual(SemanticVersion("10.20.30")?.components, [10, 20, 30])
    }

    func test_init_공백은트림한다() {
        XCTAssertEqual(SemanticVersion(" 1.2.3 ")?.components, [1, 2, 3])
    }

    func test_init_숫자가아니거나빈문자열이면nil이다() {
        XCTAssertNil(SemanticVersion(""))
        XCTAssertNil(SemanticVersion("1.a.0"))
        XCTAssertNil(SemanticVersion("v1.0.0"))
        XCTAssertNil(SemanticVersion("1.-2.0"))
    }

    // MARK: - 숫자 비교 (문자열 비교 함정 방지)

    func test_비교_문자열로비교하면틀리는케이스를_숫자로올바르게비교한다() {
        // 문자열 비교 시 "1.10.0" < "1.2.0" 이 되는 함정.
        XCTAssertTrue(SemanticVersion("1.2.0")! < SemanticVersion("1.10.0")!)
        XCTAssertFalse(SemanticVersion("1.10.0")! < SemanticVersion("1.2.0")!)
    }

    func test_비교_컴포넌트개수가달라도_부족한쪽을0으로채워비교한다() {
        XCTAssertEqual(SemanticVersion("1.3")!, SemanticVersion("1.3.0")!)
        XCTAssertTrue(SemanticVersion("1.3")! < SemanticVersion("1.3.1")!)
        XCTAssertFalse(SemanticVersion("1.3.0")! < SemanticVersion("1.3")!)
    }

    func test_비교_같은버전은서로작지않다() {
        XCTAssertFalse(SemanticVersion("2.0.0")! < SemanticVersion("2.0.0")!)
        XCTAssertEqual(SemanticVersion("2.0.0")!, SemanticVersion("2.0.0")!)
    }
}
