//
// Created by entaoyang@163.com on 2017/10/21.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

public class KeyValue: CustomStringConvertible {
	public var key: String = ""
	public var value: Any

	public init(_ k: String, _ v: Any) {
		self.key = k
		self.value = v
	}

	public var strValue: String {
		return "\(value)"
	}
	public var intValue: Int {
		return value as! Int
	}
	public var longValue: Long {
		return value as! Long
	}
	public var doubleValue: Double {
		return value as! Double
	}
	public var floatValue: Float {
		return value as! Float
	}
	public var boolValue: Bool {
		return value as! Bool
	}

	public var description: String {
		return key + " = \(value)"
	}
}



public func =>(k: String, v: Any) -> KeyValue {
	return KeyValue(k, v)
}


