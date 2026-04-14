// Main test file — individual case tests are in Case*.swift files.
// This file kept for Xcode target compatibility.
import Testing

@Suite("Дымовой тест")
struct SmokeTests {
    @Test("тесты запускаются")
    func smokeTest() {
        #expect(true)
    }
}
