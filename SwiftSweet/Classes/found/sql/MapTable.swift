//
// Created by entaoyang@163.com on 2017/10/25.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

let dbMap = MapTable("map.db")

@dynamicMemberLookup
public class MapTable {
	public let db: SQLite

	public init(_ dbname: String) {
		db = SQLite(file: File.docFile(dbname))
		if !db.existTable("T") {
			db.exec(sql: "CREATE TABLE IF NOT EXISTS T(key TEXT PRIMARY KEY, value TEXT)")
			db.exec(sql: "CREATE INDEX IF NOT EXISTS T_VALUE_INDEX ON T(value)")
		}
	}

	public subscript(dynamicMember member: String) -> String? {
		get {
			return self.get(member)
		}
		set {
			self.put(member, newValue)
		}

	}
	public subscript(key: String) -> String? {
		get {
			return get(key)
		}
		set {
			if let v = newValue {
				put(key, v)
			} else {
				remove(key)
			}
		}
	}
}

public extension MapTable {

	var toMap: [String: String] {
		var dic = [String: String]()
		let cur = db.query(sql: "SELECT key, value FROM T")
		defer {
			cur.close()
		}
		for row in cur {
			let k = row.str(0)
			let v = row.str(1)
			if k != nil && v != nil {
				dic[k!] = v!
			}
		}
		return dic
	}

	func hasValue(_ value: String) -> Bool {
		let cur = db.query(sql: "SELECT 1 FROM T WHERE value=?", args: [value])
		return cur.existResult()
	}

	func hasKey(_ key: String) -> Bool {
		return nil != get(key)
	}

	func remove(_ key: String) {
		db.update(sql: "DELETE FROM T WHERE key=?", args: [key])
	}

	func put(_ key: String, _ value: String?) {
		guard let v = value else {
			self.remove(key)
			return
		}
		db.insert(sql: "INSERT OR REPLACE INTO T(key,value) values(?,?)", args: [key, v])
	}

	func get(_ key: String) -> String? {
		let cur = db.query(sql: "SELECT value FROM T WHERE key=?", args: [key])
		return cur.strResult()
	}

	func dump() {
		let cur = db.query(sql: "SELECT key, value FROM T")
		for row in cur {
			let k = row.str(0)
			let v = row.str(1)
			logd(k, "=", v)
		}
		cur.close()
	}
}




