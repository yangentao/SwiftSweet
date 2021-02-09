//
// Created by entaoyang@163.com on 2019-08-09.
// Copyright (c) 2019 entao.dev. All rights reserved.
//

import Foundation

let KB = 1024
let MB = 1024 * 1024
let GB = 1024 * 1024 * 1024




@propertyWrapper
public struct GreatEQ<T: SignedNumeric & Comparable> {
    let minValue: T
    var value: T

    public init(wrappedValue: T, minValue: T) {
        self.minValue = minValue
        self.value = wrappedValue
    }

    public var wrappedValue: T {
        get {
            if value < minValue {
                return minValue
            }
            return value
        }
        set {
            value = newValue
        }
    }
}


public func /(lhs: CGFloat, rhs: Int) -> CGFloat {
    lhs / CGFloat(rhs)
}

public func *(lhs: CGFloat, rhs: Int) -> CGFloat {
    lhs * CGFloat(rhs)
}

public extension Numeric {
    var isIntegers: Bool {
        switch self {
        case is Int, is Int8, is Int16, is Int32, is Int64, is UInt, is UInt8, is UInt16, is UInt32, is UInt64:
            return true
        default:
            return false
        }
    }
    var isReals: Bool {
        switch self {
        case is Float, is Double, is Float32, is Float64, is CGFloat, is Decimal:
            return true
        default:
            return false
        }
    }

    var toNSNumber: NSNumber {
        switch self {
        case let a as Int:
            return NSNumber(value: a)
        case let a as Int8:
            return NSNumber(value: a)
        case let a as Int16:
            return NSNumber(value: a)
        case let a as Int32:
            return NSNumber(value: a)
        case let a as Int64:
            return NSNumber(value: a)

        case let a as UInt:
            return NSNumber(value: a)
        case let a as UInt8:
            return NSNumber(value: a)
        case let a as UInt16:
            return NSNumber(value: a)
        case let a as UInt32:
            return NSNumber(value: a)
        case let a as UInt64:
            return NSNumber(value: a)

        case let a as Float:
            return NSNumber(value: a)
        case let a as Double:
            return NSNumber(value: a)
        case let a as Float32:
            return NSNumber(value: a)
        case let a as Float64:
            return NSNumber(value: a)
        case let a as CGFloat:
            return NSNumber(value: Double(a))
        case let a as Decimal:
            return NSDecimalNumber(decimal: a)
        default:
            fatalError("unknown number : \(self)")
        }
    }
}

extension BinaryInteger {
    var toString: String {
        "\(self)"
    }

    var cint: Int32 {
        Int32(self)
    }
    var int32Value: Int32 {
        Int32(self)
    }
    var uint32Value: UInt32 {
        UInt32(self)
    }
    var intValue: Int {
        Int(self)
    }
    var uintValue: UInt {
        UInt(self)
    }
    var longValue: Long {
        Long(self)
    }
    var ulongValue: ULong {
        ULong(self)
    }
    var floatValue: Float {
        Float(self)
    }
    var doubleValue: Double {
        Double(self)
    }
    var cgfloatValue: CGFloat {
        CGFloat(self)
    }
}

public extension BinaryFloatingPoint {
    var toString: String {
        "\(self)"
    }

    var cint: Int32 {
        Int32(self)
    }
    var int32Value: Int32 {
        Int32(self)
    }
    var uint32Value: UInt32 {
        UInt32(self)
    }
    var intValue: Int {
        Int(self)
    }
    var uintValue: UInt {
        UInt(self)
    }
    var longValue: Long {
        Long(self)
    }
    var ulongValue: ULong {
        ULong(self)
    }
    var floatValue: Float {
        Float(self)
    }
    var doubleValue: Double {
        Double(self)
    }
    var cgfloatValue: CGFloat {
        CGFloat(self)
    }
}

public extension FixedWidthInteger {
    var f: CGFloat {
        CGFloat(self)
    }
    var s: String {
        "\(self)"
    }
}


public extension NSNumber {
    var isInteger: Bool {
        !stringValue.contains(".")
    }
}

public extension Int64 {

    var date: Date {
        Date(timeIntervalSince1970: Double(self / 1000))
    }
}


public extension Double {
    func keepDot(_ n: Int) -> String {
        String(format: "%.\(n)f", arguments: [self])
    }

    var afterSeconds: DispatchTime {
        DispatchTime.now() + self
    }

    func format(_ block: (NumberFormatter) -> Void) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        block(f)
        return f.string(from: NSNumber(value: self)) ?? ""
    }

}





