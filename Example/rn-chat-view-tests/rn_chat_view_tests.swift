// Main test file — individual case tests are in Case*.swift files.
// This file kept for Xcode target compatibility.
import Testing

@Suite("Smoke")
struct SmokeTests {
    @Test("tests are running")
    func smokeTest() {
        #expect(true)
    }
}
