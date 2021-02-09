//
// Created by entaoyang on 2019-07-10.
// Copyright (c) 2019 entao.dev. All rights reserved.
//

import Foundation

public class FileArrayModel<T: Codable > {
	public var items: Array<T> = Array<T>()
	public var file: File

	fileprivate init(_ f: File) {
		self.file = f
	}

}

//use model.items for update
public class FileArray<T: Codable >: Sequence {

	public typealias Element = T
	public typealias Iterator = Array<T>.Iterator

	public var model: FileArrayModel<T>

	public init(_ file: File) {
		self.model = fileArrayOf(file)
		load()
	}

	public func makeIterator() -> Iterator {
		return self.model.items.makeIterator()
	}

	private func load() {
		if let text = self.model.file.readText() {
			if let ls: Array<T> = JSON.decode(text) {
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
		self.model.items.append(value)
	}

	public func remove(at n: Int) {
		self.model.items.remove(at: n)
	}

}

private var _FileArrayStore = [String: WeakRef<AnyObject>]()

private func fileArrayOf<T: Codable >(_ f: File) -> FileArrayModel<T> {
	return syncR(_FileArrayStore) {
		if let old = _FileArrayStore[f.fullPath]?.value {
			return old as! FileArrayModel<T>
		}
		let a = FileArrayModel<T>(f)
		_FileArrayStore[f.fullPath] = WeakRef(a as AnyObject)
		return a
	}
}
