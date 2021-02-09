//
// Created by entaoyang on 2019-02-22.
// Copyright (c) 2019 yet.net. All rights reserved.
//

import Foundation

//
//  SwiftReflection.swift
//  SwiftReflection
//
//  Created by Cyon Alexander (Ext. Netlight) on 01/09/16.
//  Copyright © 2016 com.cyon. All rights reserved.
//

import Foundation
import ObjectiveC.runtime

//T@"NSString",N,C,Vname
//Tq,N,Vage
//Tc,N,Vn8
//TC,N,Vun8
//Ts,N,Vn16
//TS,N,Vun16
//Ti,N,Vn32
//TI,N,Vun32
//Tq,N,Vn64
//TQ,N,Vun64
//Tf,N,Vf32
//Td,N,Vf64
//Tf,N,Vf
//Td,N,Vlf

//https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
//https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW1
public class Property {
	public var name: String = ""
	public var type: Any.Type = Any.self
	public var isReadonly: Bool = false
	public var isCopy: Bool = false
	public var isNonatomic: Bool = false
	//oc中的@dynamic, 不是swift的dynamic
	public var isDynamic: Bool = false
	public var isWeak: Bool = false

	public init(_ property: objc_property_t) {
		self.name = String(utf8String: property_getName(property))!
		let attr: String = String(utf8String: property_getAttributes(property)!)!
		let ls = attr.split(separator: ",").map {
			String($0)
		}
		self.isReadonly = "R" =* ls
		self.isCopy = "C" =* ls
		self.isNonatomic = "N" =* ls
		self.isDynamic = "D" =* ls
		self.isWeak = "W" =* ls

		let ts = ls.first {
			$0.startWith("T")
		}
		if let TS = ts {
			self.type = self.findType(ts: TS)
		}
	}

	private func findType(ts: String) -> Any.Type {
		let c1 = ts.at(1)
		if c1 == "@" {
			if ts.count > 2 {
				let cs = ts[3..<(ts.count - 1)].toString()
				return NSClassFromString(cs)!.self
			} else {
				return AnyObject.self //id
			}
		} else {
			switch c1 {
			case "c": return Int8.self
			case "C": return UInt8.self
			case "s": return Int16.self
			case "S": return UInt16.self
			case "i": return Int32.self
			case "I": return UInt32.self
			case "q": return Int.self //also: Int64, NSInteger, only true on 64 bit platforms
			case "Q": return UInt.self //also UInt64, only true on 64 bit platforms
			case "f": return Float.self
			case "d": return Double.self
			case "B": return Bool.self
			case "{": return Decimal.self
			default: return Any.self
			}
		}
	}

	public func dump() {
		logd(self.name, self.type, self.isReadonly)
	}
}

public class Reflect {
	private static var cache: [String: [Property]] = [:]

	public static func listProp(_ ob: NSObject.Type) -> [Property] {
        objc_sync_enter(Reflect.cache)
        defer {
            objc_sync_exit(Reflect.cache)
        }
        
		let clsName: String = NSStringFromClass(ob)
		if let old = self.cache[clsName] {
			return old
		}

		var propList = [Property]()
		var count: UInt32 = 0
		guard  let ls = class_copyPropertyList(ob, &count) else {
			return propList
		}
		for i in 0..<Int(count) {
			let p: objc_property_t = ls[i]
			propList += Property(p)
		}
		free(ls)
		self.cache[clsName] = propList
		return propList
	}
}

public func mirrorOf(_ v: Any) -> Mirror {
	return Mirror(reflecting: v)
}

public func mirrorInfo(_ v: Any) {
	let m = Mirror(reflecting: v)
	logd("description: ", m.description)
	logd("subjectType: ", m.subjectType)
	logd("displayStyle: ", m.displayStyle)
	logd("Children: ", m.children.count)
	for c in m.children {
		logd("    ", c.label, " = ", c.value)
	}
}
