//
// Created by yangentao on 2019/11/10.
//

import Foundation

public typealias Byte = UInt8
public typealias Long = Int64
public typealias ULong = UInt64

public typealias BytePointer = UnsafeMutablePointer<Byte>
public typealias ConstBytePointer = UnsafePointer<Byte>
public typealias CharPointer = UnsafeMutablePointer<Int8>
public typealias ConstCharPointer = UnsafePointer<Int8>
public typealias BlockVoid = () -> Void
public typealias BoolBlock = (Bool) -> Void
public typealias StringBlock = (String) -> Void
public typealias IntBlock = (Int) -> Void
public typealias DoubleBlock = (Double) -> Void

//addALL
infix operator ++=: ComparisonPrecedence

//IN
infix operator =*: ComparisonPrecedence
//NOT IN
infix operator !=*: ComparisonPrecedence

//pair, allow nil
infix operator >>: ComparisonPrecedence

//pair, NOT allow nil
infix operator =>: ComparisonPrecedence

public protocol Applyable: class {

}

public extension Applyable {

    func apply(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}

public func println(_ items: Any?...) {
    for a in items {
        if let v = a ?? nil {
            print(v, terminator: " ")
        } else {
            print("nil", terminator: " ")
        }
    }
    print("")
}

public func printStr(_ items: Any?...) -> String {
    var buf: String = ""
    for a in items {
        if let b = a ?? nil {
            print(b, terminator: " ", to: &buf)
        } else {
            print("nil", terminator: " ", to: &buf)
        }
    }
    return buf
}

public func buildStr(_ items: Any?...) -> String {
    var buf: String = ""
    for a in items {
        if let b = a ?? nil {
            print(b, terminator: "", to: &buf)
        } else {
            print("nil", terminator: "", to: &buf)
        }
    }
    return buf
}

public var isDebug: Bool {
    get {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

public class MyError: Error, CustomStringConvertible {
    public let msg: String
    public var baseError: Error? = nil

    public init(_ msg: String, _ base: Error? = nil) {
        self.msg = msg
        self.baseError = base
    }

    public var description: String {
        get {
            return "Error: \(msg)"
        }
    }
}

public func throwIf(_ cond: Bool, _ msg: String) throws {
    if (cond) {
        throw MyError(msg)
    }
}

public func fatalIf(_ cond: Bool, _ msg: String) {
    if cond {
        fatalError(msg)
    }
}

public func fataIfDebug(_ msg: String = "") {
    if isDebug {
        fatalError(msg)
    }
}

public func debugFatal(_ msg: String = "Fatal Error!") {
    if isDebug {
        fatalError(msg)
    }
}

//init只能是类的实例,
public class WeakRef<T: AnyObject>: Equatable {

    public weak var value: T?

    public init(_ value: T) {
        self.value = value
    }

    public var isNull: Bool {
        return value == nil
    }
    public var notNull: Bool {
        return value != nil
    }

    public static func ==(lhs: WeakRef, rhs: WeakRef) -> Bool {
        return lhs === rhs || lhs.value === rhs.value
    }

}

private var _idSeed: Int = 0

public func IDGen() -> Int {
    _idSeed += 1
    return _idSeed
}


public class JSON {

    public static func decode<T: Decodable>(_ json: String?) -> T? {
        return decode(T.self, json: json)
    }

    public static func decode<T>(_ type: T.Type, json: String?) -> T? where T: Decodable {
        return decode(type, json: json) {
            $0.dateDecodingStrategy = .millisecondsSince1970
        }
    }

    public static func decode<T>(_ type: T.Type, json: String?, _ block: (JSONDecoder) -> Void) -> T? where T: Decodable {
        if let s = json, s.notEmpty {
            let d = JSONDecoder()
            block(d)
            return try? d.decode(type, from: s.dataUtf8)
        }
        return nil
    }

    public static func encode<T>(_ value: T, pretty: Bool = false) -> String? where T: Encodable {
        return encode(value) {
            $0.dateEncodingStrategy = .millisecondsSince1970
            if pretty {
                $0.outputFormatting = .prettyPrinted
            }
        }
    }

    public static func encode<T>(_ value: T, _ block: (JSONEncoder) -> Void) -> String? where T: Encodable {
        let e = JSONEncoder()
        block(e)
        return (try? e.encode(value))?.stringUtf8
    }
}