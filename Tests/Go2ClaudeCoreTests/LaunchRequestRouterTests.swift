import XCTest
@testable import Go2ClaudeCore

final class LaunchRequestRouterTests: XCTestCase {
    func test_storesIncomingPathBeforeInitialLaunch() {
        var router = LaunchRequestRouter()

        let action = router.receiveIncomingFinderPath("/Users/lilin/Downloads")

        XCTAssertEqual(action, .deferUntilInitialLaunch)
        XCTAssertEqual(
            router.consumeInitialLaunch(mode: .mainInterface),
            .launchFinderCommand(explicitFinderPath: "/Users/lilin/Downloads")
        )
    }

    func test_launchesImmediatelyAfterInitialLaunch() {
        var router = LaunchRequestRouter()
        _ = router.consumeInitialLaunch(mode: .mainInterface)

        let action = router.receiveIncomingFinderPath("/Users/lilin/Documents")

        XCTAssertEqual(action, .launchFinderCommand(explicitFinderPath: "/Users/lilin/Documents"))
    }

    func test_nilIncomingPathFallsBackToCoordinatorAfterInitialLaunch() {
        var router = LaunchRequestRouter()
        _ = router.consumeInitialLaunch(mode: .mainInterface)

        let action = router.receiveIncomingFinderPath(nil)

        XCTAssertEqual(action, .launchFinderCommand(explicitFinderPath: nil))
    }

    func test_preservesNilIncomingFinderPathDuringInitialLaunch() {
        var router = LaunchRequestRouter()

        let action = router.receiveIncomingFinderPath(nil)

        XCTAssertEqual(action, .deferUntilInitialLaunch)
        XCTAssertEqual(
            router.consumeInitialLaunch(mode: .mainInterface),
            .launchFinderCommand(explicitFinderPath: nil)
        )
    }

    func test_standardInitialLaunchOpensMainInterface() {
        var router = LaunchRequestRouter()

        let action = router.consumeInitialLaunch(mode: .mainInterface)

        XCTAssertEqual(action, .openMainInterface)
    }

    func test_initialLaunchCanOnlyBeConsumedOnce() {
        var router = LaunchRequestRouter()

        _ = router.consumeInitialLaunch(mode: .configuration)
        let action = router.consumeInitialLaunch(mode: .mainInterface)

        XCTAssertEqual(action, .ignore)
    }
}
