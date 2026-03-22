# XCUIBridge

Swift package that runs inside an XCUITest target and exposes app control via file-based IPC.

> Most users do not need this package directly. The iOS MCP server includes a built-in runner that handles everything.

## How It Works

A `BridgeTestCase` subclass runs as an XCUITest. It launches the target app, then enters a command loop polling `/tmp/xcuitest-bridge/command.json` for instructions from the MCP server. Responses are written to `/tmp/xcuitest-bridge/response.json`.

The protocol:
1. MCP server writes `config.json` (with `bundleId`) and starts the test
2. Bridge launches the app, creates `/tmp/xcuitest-bridge/ready`
3. MCP server writes command JSON, bridge reads/deletes/executes, writes response JSON
4. MCP server reads/deletes the response

## Supported Commands

| Command | Description |
|---|---|
| `tap` | Tap element by identifier, label, or type+index |
| `type` | Type text into a field |
| `swipe` | Swipe in a direction (up/down/left/right) |
| `scroll` | Scroll within a scrollable container |
| `read_tree` | Read the accessibility tree |
| `screenshot` | Capture screenshot as base64 PNG |
| `launch` | Launch/activate an app by bundle ID |
| `terminate` | Terminate an app by bundle ID |
| `wait_for` | Wait for an element to appear |
| `long_press` | Press and hold an element |
| `double_tap` | Double tap an element |
| `adjust_slider` | Set slider to normalized position (0.0-1.0) |
| `adjust_picker` | Select a picker wheel value |
| `pinch` | Pinch to zoom on element or screen |
| `drag` | Drag from one element to another |
| `element_info` | Get element properties (exists, enabled, frame, etc.) |
| `element_count` | Count elements of a given type |
| `dismiss_keyboard` | Dismiss the on-screen keyboard |
| `dismiss_modal` | Dismiss alerts, sheets, popovers, or menus |
| `quit` | Stop the bridge |

## Integration (Advanced)

Only needed if you want a custom runner instead of the built-in one.

Add to your `Package.swift` or Xcode project as an SPM dependency, then create a subclass in your UI test target:

```swift
import XCUIBridge

final class MyBridgeTests: BridgeTestCase {}
```

The `ObjCExceptionCatcher` target wraps command execution to catch NSExceptions that would otherwise crash the test runner.

## Requirements

- iOS 16+
- Swift 5.9+
