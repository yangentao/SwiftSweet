//
// Created by entaoyang@163.com on 2017/10/11.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

//example
extension MsgID {
	static let userChanged = MsgID("msg.userChanged")
}

public struct MsgID: Hashable, Equatable, RawRepresentable {
	public typealias RawValue = String
	public var rawValue: String

	public init(_ rawValue: String) {
		self.rawValue = rawValue
	}

	public init?(rawValue: String) {
		self.rawValue = rawValue
	}

	public static func ==(lhs: MsgID, rhs: MsgID) -> Bool {
		lhs.rawValue == rhs.rawValue
	}

	public static func ==(lhs: MsgID, rhs: String) -> Bool {
		lhs.rawValue == rhs
	}
}

public class Msg: Equatable {
	public var msg: MsgID
	public var result = Array<Any>()
	public var any: Any? = nil
	public var anyObject: AnyObject? = nil
	public var n1 = 0
	public var n2 = 0
	public var s1 = ""
	public var s2 = ""
	public var b1 = false
	public var b2 = false

	public init(_ msg: MsgID) {
		self.msg = msg
	}
}

public extension Msg {
	func fire() {
		Task.fore {
			MsgCenter.fireCurrent(self)
		}
	}

	static func ==(lhs: Msg, rhs: String) -> Bool {
		lhs.msg == rhs
	}

	static func ==(lhs: Msg, rhs: Msg) -> Bool {
		lhs.msg == rhs.msg
	}
}

public protocol MsgListener: class {
	func onMsg(msg: Msg)
}

fileprivate class ListenerAllItem: Equatable {
	weak var listener: MsgListener?

	init(_ l: MsgListener) {
		self.listener = l
	}

	static func ==(lhs: ListenerAllItem, rhs: ListenerAllItem) -> Bool {
		if lhs === rhs {
			return true
		}
		if let a = lhs.listener, let b = rhs.listener {
			return a === b
		}
		return false
	}
}

public class MsgCenterObject {
	private var allItems = [ListenerAllItem]()

	public func remove(_ listener: MsgListener) {
		sync(self) {
			allItems.removeAll(where: { $0.listener === listener })
		}
	}

	public func listenAll(_ listener: MsgListener) {
		sync(self) {
			let item = ListenerAllItem(listener)
			if !allItems.contains(item) {
				allItems.append(item)
			}
		}
	}

	public func fireCurrent(_ msg: Msg) {
		_ = allItems.drop {
			$0.listener == nil
		}
		let aItems = allItems
		aItems.forEach { item in
			item.listener?.onMsg(msg: msg)
		}
	}

}

public let MsgCenter = MsgCenterObject()

public extension MsgID {
	func fire() {
		let m = Msg(self)
		m.fire()
	}

	func fire(_ block: (Msg) -> Void) {
		let m = Msg(self)
		block(m)
		m.fire()
	}
}

