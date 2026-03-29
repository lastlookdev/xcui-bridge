import Foundation

/// File-based IPC server for the XCUIBridge.
///
/// Communication protocol:
/// 1. MCP server writes command JSON to the bridge directory's `command.json`
/// 2. Bridge reads, deletes, and executes it
/// 3. Bridge writes result to `response.json`
/// 4. MCP server reads and deletes the response
public final class BridgeServer {

    private let bridgeDirectory: URL
    private var commandFileURL: URL { bridgeDirectory.appendingPathComponent("command.json") }
    private var responseFileURL: URL { bridgeDirectory.appendingPathComponent("response.json") }
    private var readyFileURL: URL { bridgeDirectory.appendingPathComponent("ready") }
    private var configFileURL: URL { bridgeDirectory.appendingPathComponent("config.json") }

    public init(directory: URL = URL(fileURLWithPath: "/tmp/xcuitest-bridge")) {
        self.bridgeDirectory = directory
    }

    /// Create the bridge directory and signal readiness.
    public func signalReady() {
        try? FileManager.default.createDirectory(
            at: bridgeDirectory,
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: readyFileURL.path, contents: Data())
    }

    /// Poll for an incoming command. Returns `nil` if no command is waiting.
    public func readCommand() -> BridgeCommand? {
        let fm = FileManager.default
        let url = commandFileURL
        guard fm.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            try fm.removeItem(at: url)
            return try JSONDecoder().decode(BridgeCommand.self, from: data)
        } catch {
            try? fm.removeItem(at: url)
            print("BridgeServer: failed to read command: \(error)")
            return nil
        }
    }

    /// Write a response for the MCP server to pick up.
    public func writeResponse(_ response: BridgeResponse) {
        do {
            let data = try JSONEncoder().encode(response)
            try data.write(to: responseFileURL)
        } catch {
            print("BridgeServer: failed to write response: \(error)")
        }
    }

    /// Read the target bundle ID from the config file written by the MCP server.
    public func readBundleId() -> String? {
        guard let data = try? Data(contentsOf: configFileURL) else { return nil }
        return try? JSONDecoder().decode(BridgeConfig.self, from: data).bundleId
    }
}

// MARK: - Config

private struct BridgeConfig: Codable {
    let bundleId: String
}
