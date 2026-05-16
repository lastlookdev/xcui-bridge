#if canImport(XCTest)
import XCTest

// MARK: - Element Types

/// A structured representation of a UI element in the accessibility tree.
public struct ElementNode: Sendable {
    public let type: String
    public let identifier: String
    public let label: String
    public let value: String
    public let frame: ElementFrame
    public let isEnabled: Bool
    public let isSelected: Bool?
    public let children: [ElementNode]?

    /// Converts this node and its subtree into a `JSONValue` for serialization.
    public var jsonValue: JSONValue {
        var fields: [String: JSONValue] = [
            "type": .string(type),
            "identifier": .string(identifier),
            "label": .string(label),
            "value": .string(value),
            "frame": frame.jsonValue,
            "isEnabled": .bool(isEnabled),
        ]
        if let isSelected {
            fields["isSelected"] = .bool(isSelected)
        }
        if let children, !children.isEmpty {
            fields["children"] = .array(children.map(\.jsonValue))
        }
        return .object(fields)
    }
}

/// Frame rectangle for a UI element.
public struct ElementFrame: Sendable {
    public let x: Int
    public let y: Int
    public let width: Int
    public let height: Int

    public init(from rect: CGRect) {
        self.x = Int(rect.origin.x)
        self.y = Int(rect.origin.y)
        self.width = Int(rect.size.width)
        self.height = Int(rect.size.height)
    }

    public var jsonValue: JSONValue {
        .object([
            "x": .int(x),
            "y": .int(y),
            "width": .int(width),
            "height": .int(height),
        ])
    }
}

// MARK: - Accessibility Reader

/// Reads the XCUITest element tree into structured `ElementNode` values.
public enum AccessibilityReader {

    /// Maps an `XCUIElement.ElementType` to a human-readable string.
    public static func elementTypeName(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .button: "button"
        case .staticText: "text"
        case .textField: "textField"
        case .secureTextField: "secureTextField"
        case .textView: "textView"
        case .image: "image"
        case .cell: "cell"
        case .table: "table"
        case .collectionView: "collectionView"
        case .scrollView: "scrollView"
        case .tabBar: "tabBar"
        case .navigationBar: "navigationBar"
        case .toolbar: "toolbar"
        case .switch: "switch"
        case .slider: "slider"
        case .picker: "picker"
        case .pageIndicator: "pageIndicator"
        case .activityIndicator: "activityIndicator"
        case .segmentedControl: "segmentedControl"
        case .alert: "alert"
        case .sheet: "sheet"
        case .popover: "popover"
        case .window: "window"
        case .other: "other"
        case .application: "application"
        case .group: "group"
        case .link: "link"
        case .toggle: "toggle"
        case .map: "map"
        case .webView: "webView"
        case .searchField: "searchField"
        case .datePicker: "datePicker"
        case .menu: "menu"
        case .menuItem: "menuItem"
        case .icon: "icon"
        default: "unknown"
        }
    }

    /// Maps a human-readable element name back to an `XCUIElement.ElementType`.
    /// Returns `.any` for unrecognized names.
    public static func elementType(from name: String) -> XCUIElement.ElementType {
        switch name.lowercased() {
        case "button": .button
        case "text", "statictext": .staticText
        case "textfield": .textField
        case "securetextfield": .secureTextField
        case "image": .image
        case "cell": .cell
        case "table": .table
        case "collectionview": .collectionView
        case "scrollview": .scrollView
        case "textview": .textView
        case "switch", "toggle": .switch
        case "slider": .slider
        case "picker": .picker
        case "pickerwheel": .pickerWheel
        case "pageindicator": .pageIndicator
        case "activityindicator": .activityIndicator
        case "segmentedcontrol": .segmentedControl
        case "alert": .alert
        case "sheet": .sheet
        case "popover": .popover
        case "menu": .menu
        case "menuitem": .menuItem
        case "datepicker": .datePicker
        case "link": .link
        case "navigationbar": .navigationBar
        case "toolbar": .toolbar
        case "tabbar": .tabBar
        case "searchfield": .searchField
        default: .any
        }
    }

    /// Reads the accessibility tree starting from the given element.
    public static func readTree(
        root: XCUIElement,
        maxDepth: Int = 5,
        currentDepth: Int = 0
    ) -> [ElementNode] {
        guard currentDepth < maxDepth else { return [] }

        var nodes: [ElementNode] = []
        let children = root.children(matching: .any)
        let count = children.count

        for i in 0..<count {
            let element = children.element(boundBy: i)

            let frame = element.frame
            guard frame.width > 0, frame.height > 0, element.exists else { continue }

            let childNodes = readTree(
                root: element,
                maxDepth: maxDepth,
                currentDepth: currentDepth + 1
            )

            let isSelected: Bool? = switch element.elementType {
            case .cell, .button, .segmentedControl: element.isSelected
            default: nil
            }

            let node = ElementNode(
                type: elementTypeName(element.elementType),
                identifier: element.identifier,
                label: element.label,
                value: element.value as? String ?? "",
                frame: ElementFrame(from: frame),
                isEnabled: element.isEnabled,
                isSelected: isSelected,
                children: childNodes.isEmpty ? nil : childNodes
            )

            nodes.append(node)
        }

        return nodes
    }
}
#endif
