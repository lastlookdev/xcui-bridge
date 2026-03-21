#if canImport(XCTest)
import XCTest

/// Executes bridge commands against the target app via XCUITest APIs.
public class CommandHandler {

    private var app: XCUIApplication

    public init(app: XCUIApplication) {
        self.app = app
    }

    /// Execute a bridge command and return the response.
    public func execute(_ command: BridgeCommand) -> BridgeResponse {
        switch command.command {
        case "tap":
            return handleTap(command)
        case "type":
            return handleType(command)
        case "swipe":
            return handleSwipe(command)
        case "scroll":
            return handleScroll(command)
        case "read_tree":
            return handleReadTree(command)
        case "screenshot":
            return handleScreenshot(command)
        case "launch":
            return handleLaunch(command)
        case "terminate":
            return handleTerminate(command)
        case "wait_for":
            return handleWaitFor(command)
        case "quit":
            return .success(id: command.id, data: ["quit": AnyCodable(true)])
        default:
            return .failure(id: command.id, error: "Unknown command: \(command.command)")
        }
    }

    // MARK: - Command Handlers

    private func handleTap(_ command: BridgeCommand) -> BridgeResponse {
        let element: XCUIElement?

        if let identifier = command.params["identifier"]?.value as? String, !identifier.isEmpty {
            element = findElement(byIdentifier: identifier)
        } else if let label = command.params["label"]?.value as? String, !label.isEmpty {
            element = findElement(byLabel: label)
        } else if let elementType = command.params["elementType"]?.value as? String,
                  let index = command.params["index"]?.value as? Int {
            element = findElement(byType: elementType, index: index)
        } else {
            return .failure(id: command.id, error: "Must provide identifier, label, or elementType+index")
        }

        guard let el = element, el.exists else {
            return .failure(id: command.id, error: "Element not found")
        }

        el.tap()
        return .success(id: command.id, data: [
            "tapped": AnyCodable(true),
            "element": AnyCodable(el.debugDescription),
        ])
    }

    private func handleType(_ command: BridgeCommand) -> BridgeResponse {
        guard let text = command.params["text"]?.value as? String else {
            return .failure(id: command.id, error: "Missing 'text' parameter")
        }

        // If an identifier is provided, tap the field first to focus it
        if let identifier = command.params["identifier"]?.value as? String, !identifier.isEmpty {
            let field = findElement(byIdentifier: identifier)
            guard let f = field, f.exists else {
                return .failure(id: command.id, error: "Text field not found: \(identifier)")
            }
            f.tap()
            // Wait for keyboard to appear
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Type into whatever currently has focus
        let keyboards = app.keyboards
        if keyboards.count == 0 {
            let firstField = app.textFields.element(boundBy: 0)
            if firstField.exists {
                firstField.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        app.typeText(text)
        return .success(id: command.id, data: ["typed": AnyCodable(true)])
    }

    private func handleSwipe(_ command: BridgeCommand) -> BridgeResponse {
        guard let direction = command.params["direction"]?.value as? String else {
            return .failure(id: command.id, error: "Missing 'direction' parameter")
        }

        let target: XCUIElement
        if let elementId = command.params["element"]?.value as? String, !elementId.isEmpty,
           let el = findElement(byIdentifier: elementId), el.exists {
            target = el
        } else {
            target = app
        }

        switch direction {
        case "up": target.swipeUp()
        case "down": target.swipeDown()
        case "left": target.swipeLeft()
        case "right": target.swipeRight()
        default:
            return .failure(id: command.id, error: "Invalid direction: \(direction)")
        }

        return .success(id: command.id, data: ["swiped": AnyCodable(true)])
    }

    private func handleScroll(_ command: BridgeCommand) -> BridgeResponse {
        guard let direction = command.params["direction"]?.value as? String else {
            return .failure(id: command.id, error: "Missing 'direction' parameter")
        }

        let target: XCUIElement
        if let elementId = command.params["element"]?.value as? String, !elementId.isEmpty {
            let scrollView = app.scrollViews[elementId]
            if scrollView.exists {
                target = scrollView
            } else {
                let table = app.tables[elementId]
                target = table.exists ? table : app
            }
        } else {
            let scrollView = app.scrollViews.element(boundBy: 0)
            if scrollView.exists {
                target = scrollView
            } else {
                let table = app.tables.element(boundBy: 0)
                target = table.exists ? table : app
            }
        }

        switch direction {
        case "up": target.swipeDown()
        case "down": target.swipeUp()
        default:
            return .failure(id: command.id, error: "Invalid scroll direction: \(direction)")
        }

        return .success(id: command.id, data: ["scrolled": AnyCodable(true)])
    }

    private func handleReadTree(_ command: BridgeCommand) -> BridgeResponse {
        let depth = (command.params["depth"]?.value as? Int) ?? 5
        let tree = AccessibilityReader.readTree(root: app, maxDepth: depth)
        return .success(id: command.id, data: ["tree": AnyCodable(tree)])
    }

    private func handleScreenshot(_ command: BridgeCommand) -> BridgeResponse {
        let screenshot = XCUIScreen.main.screenshot()
        let pngData = screenshot.pngRepresentation
        let base64 = pngData.base64EncodedString()
        let size = screenshot.image.size

        return .success(id: command.id, data: [
            "base64": AnyCodable(base64),
            "width": AnyCodable(Int(size.width)),
            "height": AnyCodable(Int(size.height)),
        ])
    }

    private func handleLaunch(_ command: BridgeCommand) -> BridgeResponse {
        guard let bundleId = command.params["bundleId"]?.value as? String else {
            return .failure(id: command.id, error: "Missing 'bundleId' parameter")
        }

        let newApp = XCUIApplication(bundleIdentifier: bundleId)
        newApp.activate()
        self.app = newApp

        return .success(id: command.id, data: ["launched": AnyCodable(true)])
    }

    private func handleTerminate(_ command: BridgeCommand) -> BridgeResponse {
        guard let bundleId = command.params["bundleId"]?.value as? String else {
            return .failure(id: command.id, error: "Missing 'bundleId' parameter")
        }

        let targetApp = XCUIApplication(bundleIdentifier: bundleId)
        targetApp.terminate()

        return .success(id: command.id, data: ["terminated": AnyCodable(true)])
    }

    private func handleWaitFor(_ command: BridgeCommand) -> BridgeResponse {
        let timeout = (command.params["timeout"]?.value as? Int) ?? 10

        let predicate: NSPredicate
        let element: XCUIElement

        if let identifier = command.params["identifier"]?.value as? String, !identifier.isEmpty {
            element = app.descendants(matching: .any)[identifier]
            predicate = NSPredicate(format: "exists == true")
        } else if let label = command.params["label"]?.value as? String, !label.isEmpty {
            element = app.staticTexts[label]
            predicate = NSPredicate(format: "exists == true")
        } else {
            return .failure(id: command.id, error: "Must provide identifier or label")
        }

        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: TimeInterval(timeout))

        if result == .completed {
            let nodeData: [String: Any] = [
                "type": AccessibilityReader.elementTypeName(element.elementType),
                "identifier": element.identifier,
                "label": element.label,
                "value": element.value as? String ?? "",
            ]
            return .success(id: command.id, data: [
                "found": AnyCodable(true),
                "element": AnyCodable(nodeData),
            ])
        } else {
            return .success(id: command.id, data: ["found": AnyCodable(false)])
        }
    }

    // MARK: - Element Finding

    private func findElement(byIdentifier identifier: String) -> XCUIElement? {
        let element = app.descendants(matching: .any)[identifier]
        return element.exists ? element : nil
    }

    private func findElement(byLabel label: String) -> XCUIElement? {
        let types: [XCUIElement.ElementType] = [
            .button, .staticText, .cell, .link, .image,
            .textField, .secureTextField, .switch, .slider,
        ]

        for type in types {
            let query = app.descendants(matching: type).matching(
                NSPredicate(format: "label == %@", label)
            )
            if query.count > 0 {
                return query.element(boundBy: 0)
            }
        }

        let allQuery = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", label)
        )
        return allQuery.count > 0 ? allQuery.element(boundBy: 0) : nil
    }

    private func findElement(byType typeName: String, index: Int) -> XCUIElement? {
        let type = elementType(from: typeName)
        let query = app.descendants(matching: type)
        guard index < query.count else { return nil }
        return query.element(boundBy: index)
    }

    private func elementType(from name: String) -> XCUIElement.ElementType {
        switch name.lowercased() {
        case "button": return .button
        case "text", "statictext": return .staticText
        case "textfield": return .textField
        case "securetextfield": return .secureTextField
        case "image": return .image
        case "cell": return .cell
        case "table": return .table
        case "scrollview": return .scrollView
        case "switch", "toggle": return .switch
        case "slider": return .slider
        case "link": return .link
        case "navigationbar": return .navigationBar
        case "tabbar": return .tabBar
        case "searchfield": return .searchField
        default: return .any
        }
    }
}
#endif
