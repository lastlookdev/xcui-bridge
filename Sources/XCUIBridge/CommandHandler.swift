#if canImport(XCTest)
import XCTest

/// Executes bridge commands against the target app via XCUITest APIs.
public final class CommandHandler {

    private var app: XCUIApplication

    public init(app: XCUIApplication) {
        self.app = app
    }

    /// Execute a bridge command and return the response.
    public func execute(_ command: BridgeCommand) -> BridgeResponse {
        guard let name = command.commandName else {
            return .failure(id: command.id, error: "Unknown command: \(command.command)")
        }

        switch name {
        case .tap: return handleTap(command)
        case .type: return handleType(command)
        case .swipe: return handleSwipe(command)
        case .scroll: return handleScroll(command)
        case .readTree: return handleReadTree(command)
        case .screenshot: return handleScreenshot(command)
        case .launch: return handleLaunch(command)
        case .terminate: return handleTerminate(command)
        case .waitFor: return handleWaitFor(command)
        case .longPress: return handleLongPress(command)
        case .doubleTap: return handleDoubleTap(command)
        case .adjustSlider: return handleAdjustSlider(command)
        case .adjustPicker: return handleAdjustPicker(command)
        case .pinch: return handlePinch(command)
        case .drag: return handleDrag(command)
        case .elementInfo: return handleElementInfo(command)
        case .elementCount: return handleElementCount(command)
        case .dismissKeyboard: return handleDismissKeyboard(command)
        case .dismissModal: return handleDismissModal(command)
        case .quit: return .success(id: command.id, data: ["quit": true])
        }
    }

    // MARK: - Element Resolution

    private enum ElementResult {
        case found(XCUIElement)
        case error(BridgeResponse)
    }

    /// Resolves an element from standard command parameters (identifier, label, or elementType+index).
    private func resolveElement(from command: BridgeCommand) -> ElementResult {
        if let identifier = command.params["identifier"]?.stringValue, !identifier.isEmpty {
            guard let el = findElement(byIdentifier: identifier), el.exists else {
                return .error(.failure(id: command.id, error: "Element not found"))
            }
            return .found(el)
        }

        if let label = command.params["label"]?.stringValue, !label.isEmpty {
            guard let el = findElement(byLabel: label), el.exists else {
                return .error(.failure(id: command.id, error: "Element not found"))
            }
            return .found(el)
        }

        if let typeName = command.params["elementType"]?.stringValue,
           let index = command.params["index"]?.intValue {
            guard let el = findElement(byType: typeName, index: index), el.exists else {
                return .error(.failure(id: command.id, error: "Element not found"))
            }
            return .found(el)
        }

        return .error(.failure(
            id: command.id,
            error: "Must provide identifier, label, or elementType+index"
        ))
    }

    // MARK: - Command Handlers

    private func handleTap(_ command: BridgeCommand) -> BridgeResponse {
        switch resolveElement(from: command) {
        case .error(let response):
            return response
        case .found(let el):
            // For Switch elements in Forms, tapping the row center hits the label
            // instead of the switch control. Tap the inner switch sub-element.
            if el.elementType == .switch {
                let innerSwitch = el.switches.firstMatch
                if innerSwitch.exists {
                    innerSwitch.tap()
                } else {
                    el.tap()
                }
            } else {
                el.tap()
            }
            return .success(id: command.id, data: [
                "tapped": true,
                "element": .string(el.debugDescription),
            ])
        }
    }

    private func handleType(_ command: BridgeCommand) -> BridgeResponse {
        guard let text = command.params["text"]?.stringValue else {
            return .failure(id: command.id, error: "Missing 'text' parameter")
        }

        // If an identifier is provided, tap the field first to focus it
        if let identifier = command.params["identifier"]?.stringValue, !identifier.isEmpty {
            guard let field = findElement(byIdentifier: identifier), field.exists else {
                return .failure(id: command.id, error: "Text field not found: \(identifier)")
            }
            field.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Type into whatever currently has focus
        if app.keyboards.count == 0 {
            let firstField = app.textFields.element(boundBy: 0)
            if firstField.exists {
                firstField.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        app.typeText(text)
        return .success(id: command.id, data: ["typed": true])
    }

    private func handleSwipe(_ command: BridgeCommand) -> BridgeResponse {
        guard let direction = command.params["direction"]?.stringValue else {
            return .failure(id: command.id, error: "Missing 'direction' parameter")
        }

        let target: XCUIElement
        if let elementId = command.params["element"]?.stringValue, !elementId.isEmpty,
           let el = findElement(byIdentifier: elementId), el.exists {
            target = el
        } else if let label = command.params["label"]?.stringValue, !label.isEmpty,
                  let el = findElement(byLabel: label), el.exists {
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

        return .success(id: command.id, data: ["swiped": true])
    }

    private func handleScroll(_ command: BridgeCommand) -> BridgeResponse {
        guard let direction = command.params["direction"]?.stringValue else {
            return .failure(id: command.id, error: "Missing 'direction' parameter")
        }

        let target: XCUIElement
        if let elementId = command.params["element"]?.stringValue, !elementId.isEmpty {
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

        // Invert direction: "scroll up" means content moves up -> swipe down
        switch direction {
        case "up": target.swipeDown()
        case "down": target.swipeUp()
        default:
            return .failure(id: command.id, error: "Invalid scroll direction: \(direction)")
        }

        return .success(id: command.id, data: ["scrolled": true])
    }

    private func handleReadTree(_ command: BridgeCommand) -> BridgeResponse {
        let depth = command.params["depth"]?.intValue ?? 5
        var nodes = AccessibilityReader.readTree(root: app, maxDepth: depth)

        // Also read modal containers that live outside app's child hierarchy
        let modalTypes: [(String, XCUIElementQuery)] = [
            ("alert", app.alerts),
            ("sheet", app.sheets),
            ("popover", app.popovers),
            ("menu", app.menus),
            ("datePicker", app.datePickers),
        ]

        for (typeName, query) in modalTypes {
            for i in 0..<query.count {
                let modal = query.element(boundBy: i)
                guard modal.exists else { continue }
                let children = AccessibilityReader.readTree(root: modal, maxDepth: depth)
                let node = ElementNode(
                    type: typeName,
                    identifier: modal.identifier,
                    label: modal.label,
                    value: modal.value as? String ?? "",
                    frame: ElementFrame(from: modal.frame),
                    isEnabled: modal.isEnabled,
                    isSelected: nil,
                    children: children.isEmpty ? nil : children
                )
                nodes.append(node)
            }
        }

        return .success(id: command.id, data: [
            "tree": .array(nodes.map(\.jsonValue)),
        ])
    }

    private func handleScreenshot(_ command: BridgeCommand) -> BridgeResponse {
        let screenshot = XCUIScreen.main.screenshot()
        let base64 = screenshot.pngRepresentation.base64EncodedString()
        let size = screenshot.image.size

        return .success(id: command.id, data: [
            "base64": .string(base64),
            "width": .int(Int(size.width)),
            "height": .int(Int(size.height)),
        ])
    }

    private func handleLaunch(_ command: BridgeCommand) -> BridgeResponse {
        guard let bundleId = command.params["bundleId"]?.stringValue else {
            return .failure(id: command.id, error: "Missing 'bundleId' parameter")
        }

        let newApp = XCUIApplication(bundleIdentifier: bundleId)
        newApp.activate()
        self.app = newApp

        return .success(id: command.id, data: ["launched": true])
    }

    private func handleTerminate(_ command: BridgeCommand) -> BridgeResponse {
        guard let bundleId = command.params["bundleId"]?.stringValue else {
            return .failure(id: command.id, error: "Missing 'bundleId' parameter")
        }

        let targetApp = XCUIApplication(bundleIdentifier: bundleId)
        targetApp.terminate()

        return .success(id: command.id, data: ["terminated": true])
    }

    private func handleWaitFor(_ command: BridgeCommand) -> BridgeResponse {
        let timeout = command.params["timeout"]?.intValue ?? 10

        var candidates: [XCUIElement] = []

        if let identifier = command.params["identifier"]?.stringValue, !identifier.isEmpty {
            for query in modalQueries {
                candidates.append(query.descendants(matching: .any)[identifier].firstMatch)
            }
            candidates.append(app.descendants(matching: .any)[identifier].firstMatch)
        } else if let label = command.params["label"]?.stringValue, !label.isEmpty {
            let predicate = NSPredicate(format: "label == %@", label)
            for query in modalQueries {
                candidates.append(query.descendants(matching: .any).matching(predicate).firstMatch)
            }
            candidates.append(app.descendants(matching: .any).matching(predicate).firstMatch)
        } else {
            return .failure(id: command.id, error: "Must provide identifier or label")
        }

        // Poll candidates until one exists or timeout
        let deadline = Date().addingTimeInterval(TimeInterval(timeout))
        while Date() < deadline {
            for candidate in candidates {
                if candidate.waitForExistence(timeout: 0.3) {
                    let nodeInfo: [String: JSONValue] = [
                        "type": .string(AccessibilityReader.elementTypeName(candidate.elementType)),
                        "identifier": .string(candidate.identifier),
                        "label": .string(candidate.label),
                        "value": .string(candidate.value as? String ?? ""),
                    ]
                    return .success(id: command.id, data: [
                        "found": true,
                        "element": .object(nodeInfo),
                    ])
                }
            }
        }

        return .success(id: command.id, data: ["found": false])
    }

    // MARK: - Gestures

    private func handleLongPress(_ command: BridgeCommand) -> BridgeResponse {
        let duration = command.params["duration"]?.doubleValue ?? 1.0

        switch resolveElement(from: command) {
        case .error(let response): return response
        case .found(let el):
            el.press(forDuration: duration)
            return .success(id: command.id, data: ["longPressed": true])
        }
    }

    private func handleDoubleTap(_ command: BridgeCommand) -> BridgeResponse {
        switch resolveElement(from: command) {
        case .error(let response): return response
        case .found(let el):
            el.doubleTap()
            return .success(id: command.id, data: ["doubleTapped": true])
        }
    }

    private func handleAdjustSlider(_ command: BridgeCommand) -> BridgeResponse {
        guard let value = command.params["value"]?.doubleValue else {
            return .failure(id: command.id, error: "Missing 'value' parameter (0.0 to 1.0)")
        }

        let slider: XCUIElement
        if let identifier = command.params["identifier"]?.stringValue, !identifier.isEmpty {
            slider = app.sliders[identifier]
        } else {
            slider = app.sliders.element(boundBy: 0)
        }

        guard slider.exists else {
            return .failure(id: command.id, error: "Slider not found")
        }

        slider.adjust(toNormalizedSliderPosition: CGFloat(value))
        return .success(id: command.id, data: ["adjusted": true, "value": .double(value)])
    }

    private func handleAdjustPicker(_ command: BridgeCommand) -> BridgeResponse {
        guard let targetValue = command.params["value"]?.stringValue else {
            return .failure(id: command.id, error: "Missing 'value' parameter")
        }

        let wheel: XCUIElement
        if let identifier = command.params["identifier"]?.stringValue, !identifier.isEmpty {
            wheel = app.pickerWheels[identifier]
            if !wheel.exists {
                let picker = app.pickers[identifier]
                if picker.exists {
                    let firstWheel = picker.pickerWheels.element(boundBy: 0)
                    if firstWheel.exists {
                        firstWheel.adjust(toPickerWheelValue: targetValue)
                        return .success(id: command.id, data: ["adjusted": true])
                    }
                }
                return .failure(id: command.id, error: "Picker not found")
            }
        } else {
            wheel = app.pickerWheels.element(boundBy: 0)
        }

        guard wheel.exists else {
            return .failure(id: command.id, error: "Picker wheel not found")
        }

        wheel.adjust(toPickerWheelValue: targetValue)
        return .success(id: command.id, data: ["adjusted": true])
    }

    // Note: XCUITest's pinch(withScale:velocity:) may not trigger SwiftUI's
    // MagnifyGesture inside Form/List containers due to gesture conflict with
    // the scroll view. For reliable pinch testing, place pinchable views outside
    // of scroll containers, or use buttons to simulate zoom changes.
    private func handlePinch(_ command: BridgeCommand) -> BridgeResponse {
        let scale = command.params["scale"]?.doubleValue ?? 2.0
        let velocity = command.params["velocity"]?.doubleValue ?? 1.0

        let target: XCUIElement
        if let identifier = command.params["identifier"]?.stringValue, !identifier.isEmpty,
           let el = findElement(byIdentifier: identifier), el.exists {
            target = el
        } else {
            target = app
        }

        target.pinch(withScale: CGFloat(scale), velocity: CGFloat(velocity))
        return .success(id: command.id, data: ["pinched": true])
    }

    private func handleDrag(_ command: BridgeCommand) -> BridgeResponse {
        guard let fromId = command.params["from_identifier"]?.stringValue,
              let toId = command.params["to_identifier"]?.stringValue else {
            return .failure(id: command.id, error: "Must provide from_identifier and to_identifier")
        }

        let duration = command.params["duration"]?.doubleValue ?? 0.5

        guard let fromEl = findElement(byIdentifier: fromId), fromEl.exists else {
            return .failure(id: command.id, error: "Source element not found: \(fromId)")
        }
        guard let toEl = findElement(byIdentifier: toId), toEl.exists else {
            return .failure(id: command.id, error: "Target element not found: \(toId)")
        }

        fromEl.press(forDuration: duration, thenDragTo: toEl)
        return .success(id: command.id, data: ["dragged": true])
    }

    // MARK: - Element Info

    private func handleElementInfo(_ command: BridgeCommand) -> BridgeResponse {
        let el: XCUIElement

        if let identifier = command.params["identifier"]?.stringValue, !identifier.isEmpty {
            el = app.descendants(matching: .any)[identifier].firstMatch
        } else if let label = command.params["label"]?.stringValue, !label.isEmpty {
            el = app.descendants(matching: .any).matching(
                NSPredicate(format: "label == %@", label)
            ).firstMatch
        } else {
            return .failure(id: command.id, error: "Must provide identifier or label")
        }

        let exists = el.waitForExistence(timeout: 3)

        if !exists {
            return .success(id: command.id, data: ["exists": false])
        }

        return .success(id: command.id, data: [
            "exists": true,
            "isEnabled": .bool(el.isEnabled),
            "isHittable": .bool(el.isHittable),
            "label": .string(el.label),
            "value": .string(el.value as? String ?? ""),
            "identifier": .string(el.identifier),
            "type": .string(AccessibilityReader.elementTypeName(el.elementType)),
            "frame": ElementFrame(from: el.frame).jsonValue,
        ])
    }

    private func handleElementCount(_ command: BridgeCommand) -> BridgeResponse {
        guard let typeName = command.params["element_type"]?.stringValue else {
            return .failure(id: command.id, error: "Missing 'element_type' parameter")
        }

        let type = AccessibilityReader.elementType(from: typeName)
        let count: Int

        if let identifier = command.params["identifier"]?.stringValue, !identifier.isEmpty {
            count = app.descendants(matching: type).matching(
                NSPredicate(format: "identifier == %@", identifier)
            ).count
        } else if let label = command.params["label"]?.stringValue, !label.isEmpty {
            count = app.descendants(matching: type).matching(
                NSPredicate(format: "label == %@", label)
            ).count
        } else {
            count = app.descendants(matching: type).count
        }

        return .success(id: command.id, data: [
            "count": .int(count),
            "type": .string(typeName),
        ])
    }

    // MARK: - Dismiss

    private func handleDismissKeyboard(_ command: BridgeCommand) -> BridgeResponse {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else {
            return .success(id: command.id, data: [
                "dismissed": true,
                "keyboardWasVisible": false,
            ])
        }

        // Strategy 1: Tap a neutral coordinate (y=0.25 avoids nav bars at top)
        let coord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        coord.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Strategy 2: If keyboard still visible, try keyboard action buttons
        if app.keyboards.firstMatch.exists {
            let buttonNames = ["Done", "Return", "Search", "Go", "Send"]
            for name in buttonNames {
                let button = app.keyboards.buttons[name]
                if button.exists {
                    button.tap()
                    Thread.sleep(forTimeInterval: 0.3)
                    break
                }
            }
        }

        let stillVisible = app.keyboards.firstMatch.exists
        return .success(id: command.id, data: [
            "dismissed": .bool(!stillVisible),
            "keyboardWasVisible": true,
            "keyboardStillVisible": .bool(stillVisible),
        ])
    }

    private func handleDismissModal(_ command: BridgeCommand) -> BridgeResponse {
        var dismissed = false
        var modalType = "none"

        // Strategy 1: Dismiss alerts by tapping common button labels
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 0.5) {
            modalType = "alert"
            let buttonNames = ["OK", "Cancel", "Done", "Close", "Dismiss", "Yes", "No", "Got it"]
            for name in buttonNames {
                let button = alert.buttons[name]
                if button.exists {
                    button.tap()
                    dismissed = true
                    break
                }
            }
            if !dismissed {
                let firstButton = alert.buttons.element(boundBy: 0)
                if firstButton.exists {
                    firstButton.tap()
                    dismissed = true
                }
            }
        }

        // Strategy 2: Dismiss sheets by swiping down or tapping close buttons
        if !dismissed {
            let sheet = app.sheets.firstMatch
            if sheet.waitForExistence(timeout: 0.5) {
                modalType = "sheet"
                let buttonNames = ["Cancel", "Done", "Close", "Dismiss"]
                for name in buttonNames {
                    let button = sheet.buttons[name]
                    if button.exists {
                        button.tap()
                        dismissed = true
                        break
                    }
                }
                if !dismissed {
                    sheet.swipeDown()
                    dismissed = true
                }
            }
        }

        // Strategy 3: Dismiss popovers by tapping outside
        if !dismissed {
            let popover = app.popovers.firstMatch
            if popover.waitForExistence(timeout: 0.5) {
                modalType = "popover"
                let coord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
                coord.tap()
                dismissed = true
            }
        }

        // Strategy 4: Dismiss context menus by tapping outside
        if !dismissed {
            let menu = app.menus.firstMatch
            if menu.waitForExistence(timeout: 0.5) {
                modalType = "menu"
                let coord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
                coord.tap()
                dismissed = true
            }
        }

        return .success(id: command.id, data: [
            "dismissed": .bool(dismissed),
            "modalType": .string(modalType),
        ])
    }

    // MARK: - Element Finding

    private static let findTimeout: TimeInterval = 3

    /// Modal containers that live in separate window hierarchies.
    /// Querying app.descendants while these are presented can hang,
    /// so we check them first with short timeouts.
    private var modalQueries: [XCUIElementQuery] {
        [app.alerts, app.sheets, app.popovers, app.menus, app.datePickers]
    }

    private func findElement(byIdentifier identifier: String) -> XCUIElement? {
        for query in modalQueries {
            let match = query.descendants(matching: .any)[identifier].firstMatch
            if match.waitForExistence(timeout: 0.5) { return match }
        }

        let element = app.descendants(matching: .any)[identifier].firstMatch
        return element.waitForExistence(timeout: Self.findTimeout) ? element : nil
    }

    private func findElement(byLabel label: String) -> XCUIElement? {
        let predicate = NSPredicate(format: "label == %@", label)

        for query in modalQueries {
            let match = query.descendants(matching: .any).matching(predicate).firstMatch
            if match.waitForExistence(timeout: 0.5) { return match }
        }

        let element = app.descendants(matching: .any).matching(predicate).firstMatch
        return element.waitForExistence(timeout: Self.findTimeout) ? element : nil
    }

    private func findElement(byType typeName: String, index: Int) -> XCUIElement? {
        let type = AccessibilityReader.elementType(from: typeName)

        for query in modalQueries {
            let modalQuery = query.descendants(matching: type)
            if index < modalQuery.count {
                let el = modalQuery.element(boundBy: index)
                if el.waitForExistence(timeout: 0.5) { return el }
            }
        }

        let query = app.descendants(matching: type)
        guard index < query.count else { return nil }
        let el = query.element(boundBy: index)
        return el.waitForExistence(timeout: Self.findTimeout) ? el : nil
    }
}
#endif
