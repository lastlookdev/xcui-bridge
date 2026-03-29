import Foundation

// MARK: - JSON Value

/// A type-safe JSON value, replacing untyped `Any` wrappers with exhaustive pattern matching.
public enum JSONValue: Sendable, Equatable, Codable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    // MARK: Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        }
    }

    // MARK: Typed Accessors

    /// Returns the underlying `String` if this is a `.string` case, otherwise `nil`.
    public var stringValue: String? {
        guard case .string(let v) = self else { return nil }
        return v
    }

    /// Returns the underlying `Int` if this is an `.int` case, otherwise `nil`.
    public var intValue: Int? {
        guard case .int(let v) = self else { return nil }
        return v
    }

    /// Returns the underlying `Double` if this is a `.double` case,
    /// or converts from `.int` if applicable. Otherwise `nil`.
    public var doubleValue: Double? {
        switch self {
        case .double(let v): return v
        case .int(let v): return Double(v)
        default: return nil
        }
    }

    /// Returns the underlying `Bool` if this is a `.bool` case, otherwise `nil`.
    public var boolValue: Bool? {
        guard case .bool(let v) = self else { return nil }
        return v
    }

    /// Returns the underlying `[JSONValue]` if this is an `.array` case, otherwise `nil`.
    public var arrayValue: [JSONValue]? {
        guard case .array(let v) = self else { return nil }
        return v
    }

    /// Returns the underlying `[String: JSONValue]` if this is an `.object` case, otherwise `nil`.
    public var objectValue: [String: JSONValue]? {
        guard case .object(let v) = self else { return nil }
        return v
    }
}

// MARK: - JSON Value Literals

extension JSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
}

extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = .int(value) }
}

extension JSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}

extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) { self = .array(elements) }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

// MARK: - Command Name

/// Type-safe names for all supported bridge commands.
///
/// Adding a new command here requires handling it in `CommandHandler.execute`,
/// enforced at compile time by the exhaustive `switch`.
public enum CommandName: String, Sendable {
    case tap
    case type
    case swipe
    case scroll
    case readTree = "read_tree"
    case screenshot
    case launch
    case terminate
    case waitFor = "wait_for"
    case longPress = "long_press"
    case doubleTap = "double_tap"
    case adjustSlider = "adjust_slider"
    case adjustPicker = "adjust_picker"
    case pinch
    case drag
    case elementInfo = "element_info"
    case elementCount = "element_count"
    case dismissKeyboard = "dismiss_keyboard"
    case dismissModal = "dismiss_modal"
    case quit
}

// MARK: - Command & Response

public struct BridgeCommand: Codable, Sendable {
    public let id: String
    public let command: String
    public let params: [String: JSONValue]

    /// Parsed command name, or `nil` if the command string is unrecognized.
    public var commandName: CommandName? {
        CommandName(rawValue: command)
    }

    public init(id: String, command: String, params: [String: JSONValue] = [:]) {
        self.id = id
        self.command = command
        self.params = params
    }
}

public struct BridgeResponse: Codable, Sendable {
    public let id: String
    public let success: Bool
    public let data: [String: JSONValue]?
    public let error: String?

    public static func success(id: String, data: [String: JSONValue]) -> BridgeResponse {
        BridgeResponse(id: id, success: true, data: data, error: nil)
    }

    public static func failure(id: String, error: String) -> BridgeResponse {
        BridgeResponse(id: id, success: false, data: nil, error: error)
    }
}
