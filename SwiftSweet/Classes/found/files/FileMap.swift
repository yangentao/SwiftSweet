//
// Created by entaoyang on 2019-07-08.
// Copyright (c) 2019 entao.dev. All rights reserved.
//

import Foundation

public class FileMapModel<K: Codable & Hashable, V: Codable> {
	public var map: Dictionary<K, V> = Dictionary<K, V>(minimumCapacity: 256)
	public var file: File

	fileprivate init(_ file: File) {
		self.file = file
	}
}

public class FileMap<K: Codable & Hashable, V: Codable>: Sequence {

	public typealias Element = (key: K, value: V)
	public typealias Iterator = Dictionary<K, V>.Iterator

	public var model: FileMapModel<K, V>

	public init(_ file: File) {
		self.model = _FileMapOf(file)
		load()
	}

	public func makeIterator() -> Iterator {
		return self.model.map.makeIterator()
	}

	private func load() {
		if let text = self.model.file.readText() {
			if let ls: Dictionary<K, V> = JSON.decode(text) {
				self.model.map = ls
			}
		}
	}

	public func save() {
		if let s = JSON.encode(self.model.map) {
			self.model.file.writeText(text: s)
		}
	}

	public func get(_ k: K) -> V? {
		return self.model.map[k]
	}

	public func put(_ k: K, _ v: V) {
		self.model.map[k] = v
	}

	@discardableResult
	public func remove(_ k: K) -> V? {
		return self.model.map.removeValue(forKey: k)
	}

	public var keys: Set<K> {
		return self.model.map.keySet
	}
	public var values: [V] {
		return self.model.map.valueArray
	}
}

private var _FileMapStore = [String: WeakRef<AnyObject>]()

private func _FileMapOf<K: Codable & Hashable, V: Codable>(_ file: File) -> FileMapModel<K, V> {
	return syncR(_FileMapStore) {
		if let old = _FileMapStore[file.fullPath]?.value {
			return old as! FileMapModel<K, V>
		}
		let a = FileMapModel<K, V>(file)
		_FileMapStore[file.fullPath] = WeakRef(a as AnyObject)
		return a
	}
}