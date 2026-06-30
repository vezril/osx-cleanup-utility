import Testing
// Temporary: verifies CI reports red on a failing test (M0 task 5.3). Deleted after.
@Test("deliberate failure to confirm CI red path")
func deliberateRedPathFailure() {
    #expect(1 == 2)
}
