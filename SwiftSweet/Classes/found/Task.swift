//
// Created by entaoyang@163.com on 2017/10/10.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation
//import Combine

public extension Double {
	var afterNow: DispatchTime {
		DispatchTime.now() + self
	}
}

public extension Int {
	var afterNow: DispatchTime {
		DispatchTime.now() + Double(self)
	}
}

fileprivate var onceSet: Set<String> = Set<String>()

public class ScheduleItem {
	public let name: String
	fileprivate var block: BlockVoid?
	fileprivate var time: Double = Date().timeIntervalSince1970

	init(name: String, block: @escaping BlockVoid) {
		self.name = name
		self.block = block
	}

	public var canceled: Bool {
		self.block == nil
	}

	public func cancel() {
		block = nil
	}
}

public class Task {
	private static var tasks = [ScheduleItem]()
}

public extension Task {
	static func mergeFore(_ name: String, _ block: @escaping BlockVoid) {
		self.mergeFore(name, 0.3, block)
	}

	static func mergeFore(_ name: String, _ second: Double, _ block: @escaping BlockVoid) {

		let item = ScheduleItem(name: name, block: block)
		self.tasks.append(item)
		DispatchQueue.main.asyncAfter(deadline: second.afterSeconds) {
			if let b = item.block {
				for t in self.tasks {
					if t.name == name {
						t.cancel()
					}
				}
				self.tasks.removeAllIf {
					$0.block == nil
				}
				b()
			}
		}
	}

	static func fore(_ block: @escaping BlockVoid) {
		DispatchQueue.main.async(execute: block)
	}

	static func foreDelay(seconds: Double, _ block: @escaping BlockVoid) {
		let a = DispatchTime.now() + seconds
		DispatchQueue.main.asyncAfter(deadline: a, execute: block)
	}

	static func back(_ block: @escaping BlockVoid) {
		DispatchQueue.global().async(execute: block)
	}

	static func backDelay(seconds: Double, _ block: @escaping BlockVoid) {
		let a = DispatchTime.now() + seconds
		DispatchQueue.global().asyncAfter(deadline: a, execute: block)
	}

	static func foreSchedule(_ second: Double, _ block: @escaping BlockVoid) -> ScheduleItem {
		let item = ScheduleItem(name: "", block: block)
		DispatchQueue.main.asyncAfter(deadline: second.afterSeconds) {
			item.block?()
			item.block = nil
		}
		return item
	}

	static func runOnce(_ key: String, _ block: () -> Void) {
		if !onceSet.contains(key) {
			onceSet.insert(key)
			block()
		}
	}
}

public class TaskQueue {
	public let queue: DispatchQueue

	public init(_ label: String) {
		self.queue = DispatchQueue(label: label, qos: .default)
	}

	public func fore(_ block: @escaping BlockVoid) {
		DispatchQueue.main.async(execute: block)
	}

	public func foreDelay(seconds: Double, _ block: @escaping BlockVoid) {
		let a = DispatchTime.now() + seconds
		DispatchQueue.main.asyncAfter(deadline: a, execute: block)
	}

	public func sync(_ block: @escaping BlockVoid) {
		self.queue.sync(execute: block)
	}

	public func backDelay(seconds: Double, _ block: @escaping BlockVoid) {
		let a = DispatchTime.now() + seconds
		self.queue.asyncAfter(deadline: a, execute: block)
	}

	public func back(_ block: @escaping BlockVoid) {
		self.queue.async(execute: block)
	}
}

public class Sync {
	private weak var obj: AnyObject? = nil
	private var state: Int = 0

	public init(_ obj: AnyObject) {
		self.obj = obj
		state = 0
	}

	@discardableResult
	public func enter() -> Sync {
		if let ob = self.obj {
			objc_sync_enter(ob)
			state = 1
		}
		return self
	}

	public func exit() {
		if let ob = self.obj {
			objc_sync_exit(ob)
			state = 2
		}

	}

	deinit {
		if self.state == 1 {
			self.exit()
		}
	}
}

public func sync(_ obj: Any, _ block: () -> Void) {
	objc_sync_enter(obj)
	defer {
		objc_sync_exit(obj)
	}
	block()
}

public func syncRet<T>(_ obj: Any, _ block: () -> T) -> T {
	objc_sync_enter(obj)
	defer {
		objc_sync_exit(obj)
	}
	return block()
}

public func syncR<T>(_ obj: Any, _ block: () -> T) -> T {
	objc_sync_enter(obj)
	defer {
		objc_sync_exit(obj)
	}
	return block()
}

//extension DispatchQueue {
//	@available(iOS 13.0, *)
//	func scheduleAfter(_ seconds: Double, interval: Double, block: @escaping () -> Void) -> Cancellable {
//		let b = DispatchQueue.SchedulerTimeType.Stride(floatLiteral: interval)
//		return DispatchQueue.main.schedule(after: DispatchQueue.SchedulerTimeType(seconds.afterNow), interval: b, block)
//	}
//}