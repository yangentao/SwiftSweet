//
// Created by entaoyang@163.com on 2017/10/29.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

public class YsonValue: CustomStringConvertible, Equatable {
    public func writeTo(_ buf: inout String) {
        fatalError()
    }

    public final var yson: String {
        var text = ""
        text.reserveCapacity(512)
        writeTo(&text)
        return text
    }
    public final var jsonText: String {
        return yson
    }
    public subscript(index: Int) -> YsonValue {
        YsonNull.inst
    }
    public subscript(key: String) -> YsonValue {
        YsonNull.inst
    }

    public var description: String {
        self.yson
    }

    public static func ==(lhs: YsonValue, rhs: YsonValue) -> Bool {
        if lhs === rhs {
            return true
        }
        if type(of: lhs) != type(of: rhs) {
            return false
        }
        switch lhs {
        case is YsonNull:
            return rhs is YsonNull
        case is YsonNum:
            return rhs is YsonNum && (rhs as! YsonNum).data == (lhs as! YsonNum).data
        case is YsonString:
            return rhs is YsonString && (rhs as! YsonString).data == (lhs as! YsonString).data
        case is YsonBlob:
            return rhs is YsonBlob && (rhs as! YsonBlob).data == (lhs as! YsonBlob).data
        case is YsonArray:
            return rhs is YsonArray && (rhs as! YsonArray).data == (lhs as! YsonArray).data
        case is YsonObject:
            return rhs is YsonObject && (rhs as! YsonObject).data == (lhs as! YsonObject).data
        default:
            return false
        }
    }

}

public extension YsonValue {
    var boolValue: Bool? {
        (self as? YsonBool)?.data
    }
    var stringValue: String? {
        (self as? YsonString)?.data
    }
    var intValue: Int? {
        (self as? YsonNum)?.data.intValue
    }
    var doubleValue: Double? {
        (self as? YsonNum)?.data.doubleValue
    }
    var blobValue: Data? {
        (self as? YsonBlob)?.data
    }
    var isNull: Bool {
        self is YsonNull
    }
}

public class YsonNull: YsonValue, ExpressibleByNilLiteral {

    public static var inst: YsonNull = YsonNull()

    private override init() {
        super.init()
    }

    public required init(nilLiteral: ()) {
    }


    public override func writeTo(_ buf: inout String) {
        buf.append("null")
    }
}

public class YsonBool: YsonValue, ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool

    public var data: Bool

    public init(_ b: Bool) {
        self.data = b
        super.init()
    }

    public required init(booleanLiteral value: BooleanLiteralType) {
        self.data = value
    }


    public override func writeTo(_ buf: inout String) {
        buf.append("\(data)")
    }
}

//用于encode/decode
public class YsonBlob: YsonValue {
    public var data: Data

    public init(_ data: Data) {
        self.data = data
        super.init()
    }

    public override func writeTo(_ buf: inout String) {
        let s = data.base64EncodedString()
        buf.append("\"")
        buf.append(escapeJson(s))
        buf.append("\"")
    }
}

//用于encode/decode
public class YsonNum: YsonValue, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {

    public typealias IntegerLiteralType = Int
    public typealias FloatLiteralType = Double

    public var data: NSNumber = 0
    public var hasDot: Bool = false
    private var initedByInteger: Bool? = nil

    public init(_ v: NSNumber) {
        self.data = v
        super.init()
    }

    public convenience init<T: Numeric>(_ v: T) {
        self.init(v.toNSNumber)
        initedByInteger = v.isIntegers
    }

    public required init(integerLiteral value: Int) {
        data = value.toNSNumber
        initedByInteger = true
        super.init()
    }

    public required init(floatLiteral value: Double) {
        data = value.toNSNumber
        initedByInteger = false
        super.init()
    }

    public override func writeTo(_ buf: inout String) {
        buf.append(String(describing: data))
    }

}

public class YsonString: YsonValue, ExpressibleByStringLiteral, ExpressibleByExtendedGraphemeClusterLiteral, ExpressibleByUnicodeScalarLiteral {
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String

    public var data: String = ""

    public init(_ s: String) {
        self.data = s
        super.init()
    }

    public required init(stringLiteral value: StringLiteralType) {
        self.data = value
        super.init()
    }

    public required init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.data = value
        super.init()
    }

    public required init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.data = value
        super.init()
    }

    public override func writeTo(_ buf: inout String) {
        buf.append("\"")
        buf.append(escapeJson(data))
        buf.append("\"")
    }
}

public class YsonArray: YsonValue, ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Any?
    public var data: [YsonValue] = [YsonValue]()
    var count: Int {
        data.count
    }

    public init(_ capcity: Int = 16) {
        if capcity > 4 {
            data.reserveCapacity(capcity)
        }
        super.init()
    }

    public required init(arrayLiteral elements: ArrayLiteralElement...) {
        data = arrayValueToArrayYson(es: elements)
        super.init()
    }

    public convenience init?(_ json: String) {
        guard let a = YParser.parseArray(json) else {
            return nil
        }
        self.init()
        self.data = a.data
    }

    public override subscript(index: Int) -> YsonValue {
        get {
            if index < self.data.count {
                return self.data[index]
            }
            return YsonNull.inst
        }
        set {
            if index < self.data.count {
                self.data[index] = newValue
            } else if index == self.data.count {
                self.data.append(newValue)
            }
        }
    }

    public override func writeTo(_ buf: inout String) {
        buf.append("[")
        var first = true
        for v in data {
            if !first {
                buf.append(",")
            }
            buf.append(v.yson)
            first = false
        }
        buf.append("]")
    }

    @discardableResult
    public func add<T: Numeric>(_ value: T) -> Self {
        data.append(YsonNum(value))
        return self
    }

    @discardableResult
    public func add(_ value: YsonValue) -> Self {
        data.append(value)
        return self
    }

    @discardableResult
    public func add(_ value: Any?) -> Self {
        if let v = value ?? nil {
            if let yv = v as? YsonValue {
                self.data += yv
            } else {
                self.data += anyValueToYsonValue(v)
            }
        } else {
            self.data += YsonNull.inst
        }
        return self
    }

    @discardableResult
    public static func +=(lhs: YsonArray, rhs: Any) -> YsonArray {
        lhs.add(rhs)
        return lhs
    }
}

extension YsonArray: Sequence {
    public func makeIterator() -> IndexingIterator<[YsonValue]>.Iterator {
        data.makeIterator()
    }
}

public extension YsonArray {
    var firstObject: YsonObject? {
        if !self.data.isEmpty {
            return self[0] as? YsonObject
        }
        return nil
    }

    var arrayInt: [Int] {
        self.data.map {
            ($0 as! YsonNum).data.intValue
        }
    }
    var arrayDouble: [Double] {
        self.data.map {
            ($0 as! YsonNum).data.doubleValue
        }
    }
    var arrayString: [String] {
        self.data.map {
            ($0 as! YsonString).data
        }
    }
    var arrayObject: [YsonObject] {
        self.data.map {
            $0 as! YsonObject
        }
    }

    func arrayModel<V: Decodable>() -> [V] {
        var ls = [V]()
        for ob in self.arrayObject {
            if let m: V = ob.toModel() {
                ls.append(m)
            }
        }
        return ls
    }

}


@dynamicMemberLookup
public class YsonObject: YsonValue, ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = Any?

    public var data: [String: YsonValue] = [String: YsonValue]()

    public init(_ capcity: Int = 16) {
        if capcity > 4 {
            data.reserveCapacity(capcity)
        }
        super.init()
    }

    public required init(dictionaryLiteral elements: (Key, Value)...) {
        let d = [String: Any?](uniqueKeysWithValues: elements)
        self.data = dicValueToDicYson(d)
        super.init()
    }

    public convenience init?(_ json: String) {
        guard let a = YParser.parseObject(json) else {
            return nil
        }
        self.init(16)
        self.data = a.data
    }

    public override subscript(key: String) -> YsonValue {
        get {
            self.data[key] ?? YsonNull.inst
        }
        set {
            self.data[key] = newValue
        }
    }

    public subscript(dynamicMember member: String) -> String? {
        get {
            (data[member] as? YsonString)?.data
        }
        set {
            if let v = newValue {
                data[member] = YsonString(v)
            } else {
                data[member] = YsonNull.inst
            }
        }
    }
    public subscript(dynamicMember member: String) -> Int? {
        get {
            if let v = (data[member] as? YsonNum)?.data {
                return v.intValue
            }
            return nil
        }
        set {
            if let v = newValue {
                data[member] = YsonNum(v)
            } else {
                data[member] = YsonNull.inst
            }
        }
    }
    public subscript(dynamicMember member: String) -> Double? {
        get {
            (data[member] as? YsonNum)?.data.doubleValue

        }
        set {
            if let v = newValue {
                data[member] = YsonNum(v)
            } else {
                data[member] = YsonNull.inst
            }
        }
    }

    public override func writeTo(_ buf: inout String) {
        buf.append("{")
        var first = true
        for (k, v) in data {
            if !first {
                buf.append(",")
            }
            buf.append("\"")
            buf.append(escapeJson(k))
            buf.append("\"")
            buf.append(":")
            buf.append(v.yson)
            first = false
        }
        buf.append("}")
    }

    public var keys: [String] {
        Array<String>(self.data.keys)
    }

    public func has(_ key: String) -> Bool {
        self.data[key] != nil
    }

    public func put(_ key: String, _ value: Any?) {
        data[key] = anyValueToYsonValue(value)
    }

    public func putNull(_ key: String) {
        put(key, YsonNull.inst)
    }

    public func bool(_ key: String) -> Bool? {
        let a = data[key]
        switch a {
        case let yb as YsonBool:
            return yb.data
        case let yn as YsonNum:
            return yn.data.intValue == 1
        default:
            return nil
        }
    }

    public func int(_ key: String) -> Int? {
        let a = data[key]
        switch a {
        case let n as YsonNum:
            return n.data.intValue
        default:
            return nil
        }
    }

    public func double(_ key: String) -> Double? {
        let a = data[key]
        switch a {
        case let n as YsonNum:
            return n.data.doubleValue
        default:
            return nil
        }
    }

    public func str(_ key: String) -> String? {
        let a = data[key]
        switch a {
        case let s as YsonString:
            return s.data
        case let n as YsonNum:
            return n.data.description
        default:
            return nil
        }
    }

    public func obj(_ key: String) -> YsonObject? {
        let a = data[key]
        if let b = a as? YsonObject {
            return b
        }
        return nil
    }

    public func array(_ key: String) -> YsonArray? {
        let a = data[key]
        if let b = a as? YsonArray {
            return b
        }
        return nil
    }
}

extension YsonObject: Sequence {
    public func makeIterator() -> DictionaryIterator<String, YsonValue> {
        data.makeIterator()
    }
}



