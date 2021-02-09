//
// Created by entaoyang@163.com on 2017/10/25.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation
import CoreGraphics

public enum Conflict: String {
	case abort = "ABORT" //default
	case replace = "REPLACE"
	case rollback = "ROLLBACK"
	case fail = "FAIL"
	case ignore = "IGNORE"
}

public typealias ColumnName = String

public extension ColumnName {
	var toName: String {
		return self
	}
}

public func =>(k: ColumnName, v: SQLValue) -> KeyValue {
	return KeyValue(k.toName, v)
}

public extension KeyValue {
	var sqlValue: SQLValue {
		return self.value as! SQLValue
	}
}

public protocol SQLValue {
}

extension NSNull: SQLValue {
	public static var inst: NSNull {
		return NSNull()
	}
}

public typealias SQLNull = NSNull

public typealias RowData = [String: SQLValue]

public protocol SQLText: SQLValue {
	var toSQLText: String { get }
}

public protocol SQLInt: SQLValue {
	var toSQLInt: Int64 { get }
}

public protocol SQLReal: SQLValue {
	var toSQLReal: Double { get }
}

public protocol SQLBlob: SQLValue {
	var toSQLBlob: Data { get }
}

extension Bool: SQLInt {
	public var toSQLInt: Int64 {
		return self ? 1 : 0
	}
}

extension Int8: SQLInt {
	public var toSQLInt: Int64 {
		return Int64(self)
	}
}

extension UInt8: SQLInt {
	public var toSQLInt: Int64 {
		return Int64(self)
	}
}

extension Int16: SQLInt {
	public var toSQLInt: Int64 {
		return Int64(self)
	}
}

extension UInt16: SQLInt {
	public var toSQLInt: Int64 {
		return Int64(self)
	}
}

extension Int32: SQLInt {
	public var toSQLInt: Int64 {
		return Int64(self)
	}
}

extension UInt32: SQLInt {
	public var toSQLInt: Int64 {
		return Int64(self)
	}
}

extension Int: SQLInt {
	public var toSQLInt: Int64 {
		return Int64(self)
	}
}

extension UInt: SQLInt {
	public var toSQLInt: Int64 {
		return Int64(self)
	}
}

extension Int64: SQLInt {
	public var toSQLInt: Int64 {
		return Int64(self)
	}
}

extension UInt64: SQLInt {
	public var toSQLInt: Int64 {
		return Int64(self)
	}
}

extension Float: SQLReal {
	public var toSQLReal: Double {
		return Double(self)
	}
}

extension Double: SQLReal {
	public var toSQLReal: Double {
		return self
	}
}

extension CGFloat: SQLReal {
	public var toSQLReal: Double {
		return Double(self)
	}
}

extension Character: SQLText {
	public var toSQLText: String {
		return String(self)
	}
}

extension String: SQLText {
	public var toSQLText: String {
		return self
	}
}

extension NSString: SQLText {
	public var toSQLText: String {
		return String(self)
	}
}

extension Data: SQLBlob {
	public var toSQLBlob: Data {
		return self
	}
}

extension NSData: SQLBlob {
	public var toSQLBlob: Data {
		return Data(referencing: self)
	}
}



