//
// Created by entaoyang on 2019-07-08.
// Copyright (c) 2019 entao.dev. All rights reserved.
//

import Foundation

public class FileSetModel<T: Codable & Hashable> {
	public var items: Set<T> = Set<T>(minimumCapacity: 256)
	public var file: File

	fileprivate init(_ f: File) {
		self.file = f
	}

}

//use model.items for update
public class FileSet<T: Codable & Hashable>: Sequence {

	public typealias Element = T
	public typealias Iterator = Set<T>.Iterator

	public var model: FileSetModel<T>

	public init(_ file: File) {
		self.model = fileSetOf(file)
		load()
	}

	public func makeIterator() -> Iterator {
		return self.model.items.makeIterator()
	}

	private func load() {
		if let text = self.model.file.readText() {
			if let ls: Set<T> = JSON.decode(text) {
				self.model.items = ls
			}
		}
	}

	public func save() {
		if let s = JSON.encode(self.model.items) {
			self.model.file.writeText(text: s)
		}
	}

	public func add(_ value: T) {
		self.model.items.insert(value)
	}

	public func remove(_ value: T) {
		self.model.items.remove(value)
	}
}

private var _FileSetStore = [String: WeakRef<AnyObject>]()

private func fileSetOf<T: Codable & Hashable>(_ f: File) -> FileSetModel<T> {
	return syncR(_FileSetStore) {
		if let old = _FileSetStore[f.fullPath]?.value {
			return old as! FileSetModel<T>
		}
		let a = FileSetModel<T>(f)
		_FileSetStore[f.fullPath] = WeakRef(a as AnyObject)
		return a
	}
}
