#if canImport(XCTest)
import XCTest

/// Reads the XCUITest element tree and serializes it to a JSON-compatible dictionary.
public class AccessibilityReader {

    /// Map XCUIElement.ElementType to a human-readable string.
    public static func elementTypeName(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .button: return "button"
        case .staticText: return "text"
        case .textField: return "textField"
        case .secureTextField: return "secureTextField"
        case .textView: return "textView"
        case .image: return "image"
        case .cell: return "cell"
        case .table: return "table"
        case .collectionView: return "collectionView"
        case .scrollView: return "scrollView"
        case .tabBar: return "tabBar"
        case .navigationBar: return "navigationBar"
        case .toolbar: return "toolbar"
        case .switch: return "switch"
        case .slider: return "slider"
        case .picker: return "picker"
        case .pageIndicator: return "pageIndicator"
        case .activityIndicator: return "activityIndicator"
        case .segmentedControl: return "segmentedControl"
        case .alert: return "alert"
        case .sheet: return "sheet"
        case .popover: return "popover"
        case .window: return "window"
        case .other: return "other"
        case .application: return "application"
        case .group: return "group"
        case .link: return "link"
        case .toggle: return "toggle"
        case .map: return "map"
        case .webView: return "webView"
        case .searchField: return "searchField"
        case .datePicker: return "datePicker"
        case .menu: return "menu"
        case .menuItem: return "menuItem"
        case .icon: return "icon"
        default: return "unknown"
        }
    }

    /// Read the accessibility tree starting from the given element.
    public static func readTree(
        root: XCUIElement,
        maxDepth: Int = 5,
        currentDepth: Int = 0
    ) -> [[String: Any]] {
        guard currentDepth < maxDepth else { return [] }

        var nodes: [[String: Any]] = []
        let children = root.children(matching: .any)
        let count = children.count

        for i in 0..<count {
            let element = children.element(boundBy: i)

            let frame = element.frame
            guard frame.width > 0 && frame.height > 0 else { continue }
            guard element.exists else { continue }

            var node: [String: Any] = [
                "type": elementTypeName(element.elementType),
                "identifier": element.identifier,
                "label": element.label,
                "value": element.value as? String ?? "",
                "frame": [
                    "x": Int(frame.origin.x),
                    "y": Int(frame.origin.y),
                    "width": Int(frame.size.width),
                    "height": Int(frame.size.height),
                ],
                "isEnabled": element.isEnabled,
            ]

            if element.elementType == .cell ||
               element.elementType == .button ||
               element.elementType == .segmentedControl {
                node["isSelected"] = element.isSelected
            }

            let childNodes = readTree(
                root: element,
                maxDepth: maxDepth,
                currentDepth: currentDepth + 1
            )
            if !childNodes.isEmpty {
                node["children"] = childNodes
            }

            nodes.append(node)
        }

        return nodes
    }
}
#endif
