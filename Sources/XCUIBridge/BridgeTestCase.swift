#if canImport(XCTest)
import XCTest
import ObjCExceptionCatcher

/// Base test case that runs the XCUIBridge command loop.
///
/// To use in your app's UI test target:
/// 1. Add the XCUIBridge package dependency
/// 2. Create a subclass:
///    ```swift
///    import XCUIBridge
///    class MyBridgeTest: BridgeTestCase {}
///    ```
/// 3. The MCP server will run this test to control your app.
open class BridgeTestCase: XCTestCase {

    override open func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// The main bridge test — starts a command loop that listens for
    /// instructions from the iOS MCP server.
    open func testBridge() throws {
        // 1. Read target bundle ID from config file (written by MCP server),
        //    falling back to environment variable
        let bundleId: String = {
            let server = BridgeServer()
            if let id = server.readBundleId() {
                return id
            }
            return ProcessInfo.processInfo.environment["TARGET_BUNDLE_ID"]
                ?? "com.apple.Preferences"
        }()

        print("XCUIBridge: starting bridge for \(bundleId)")

        // 2. Launch the target app
        let app = XCUIApplication(bundleIdentifier: bundleId)
        app.launch()

        // Wait for app to settle and verify it launched
        Thread.sleep(forTimeInterval: 1.0)
        guard app.state == .runningForeground else {
            print("XCUIBridge: app failed to launch (state: \(app.state.rawValue))")
            let server = BridgeServer()
            server.signalReady()
            // Write an error that the MCP server can detect
            server.writeResponse(.failure(id: "launch", error: "App \(bundleId) failed to launch"))
            return
        }
        print("XCUIBridge: app launched successfully")

        // 3. Initialize bridge components
        let server = BridgeServer()
        let handler = CommandHandler(app: app)

        // 4. Signal that the bridge is ready
        server.signalReady()
        print("XCUIBridge: bridge ready, waiting for commands...")

        // 5. Command loop
        var running = true
        while running {
            if let command = server.readCommand() {
                print("XCUIBridge: received command: \(command.command)")

                var response: BridgeResponse?
                let exceptionMessage = LLBTryObjC {
                    response = handler.execute(command)
                }

                if let exceptionMessage {
                    print("XCUIBridge: caught ObjC exception: \(exceptionMessage)")
                    response = .failure(
                        id: command.id,
                        error: "Internal error: \(exceptionMessage)"
                    )
                }

                server.writeResponse(response ?? .failure(id: command.id, error: "Unknown error"))

                if command.command == "quit" {
                    running = false
                }
            }

            // Poll interval — 100ms
            Thread.sleep(forTimeInterval: 0.1)
        }

        print("XCUIBridge: bridge shutting down")
    }
}
#endif
