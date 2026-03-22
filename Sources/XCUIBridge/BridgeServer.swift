import Foundation

/// File-based IPC server for the XCUIBridge.
///
/// Communication protocol:
/// 1. MCP server writes command JSON to `/tmp/xcuitest-bridge/command.json`
/// 2. Bridge reads, deletes, and executes it
/// 3. Bridge writes result to `/tmp/xcuitest-bridge/response.json`
/// 4. MCP server reads and deletes the response
public class BridgeServer {

    private let bridgeDir = "/tmp/xcuitest-bridge"
    private let commandFile: String
    private let responseFile: String
    private let readyFile: String

    public init() {
        commandFile = "\(bridgeDir)/command.json"
        responseFile = "\(bridgeDir)/response.json"
        readyFile = "\(bridgeDir)/ready"
    }

    /// Create the bridge directory and signal readiness.
    public func signalReady() {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: bridgeDir, withIntermediateDirectories: true)
        fm.createFile(atPath: readyFile, contents: Data())
    }

    /// Poll for an incoming command. Returns nil if no command is waiting.
    public func readCommand() -> BridgeCommand? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: commandFile) else { return nil }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: commandFile))
            try fm.removeItem(atPath: commandFile)
            let command = try JSONDecoder().decode(BridgeCommand.self, from: data)
            return command
        } catch {
            // Clean up malformed command file
            try? fm.removeItem(atPath: commandFile)
            print("BridgeServer: failed to read command: \(error)")
            return nil
        }
    }

    /// Write a response for the MCP server to pick up.
    public func writeResponse(_ response: BridgeResponse) {
        do {
            let data = try JSONEncoder().encode(response)
            try data.write(to: URL(fileURLWithPath: responseFile))
        } catch {
            print("BridgeServer: failed to write response: \(error)")
        }
    }

    /// Read the target bundle ID from the config file written by the MCP server.
    public func readBundleId() -> String? {
        let configPath = "\(bridgeDir)/config.json"
        guard let data = FileManager.default.contents(atPath: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["bundleId"] as? String else {
            return nil
        }
        return id
    }
}
