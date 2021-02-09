//
// Created by entaoyang@163.com on 2017/10/27.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

public extension SQLite {
	func delete(table: String, where w: Where?) -> Int {
		var sql = "DELETE FROM \(table)"
		if w != nil {
			sql += " WHERE " + w!.cond
		}
		return update(sql: sql, args: w?.args ?? [])
	}
}

public extension SQLite {

	@discardableResult
	func update(table: String, values: [KeyValue], where w: Where?) -> Int {
		var vs = [String: SQLValue]()
		for kv in values {
			vs[kv.key] = kv.sqlValue
		}
		return update(or: .abort, table: table, values: vs, where: w)
	}

	@discardableResult
	func update(table: String, values: [String: SQLValue], where w: Where?) -> Int {
		return update(or: .abort, table: table, values: values, where: w)
	}

	func update(or conflict: Conflict, table: String, values: [String: SQLValue], where w: Where?) -> Int {
		var argList = [SQLValue]()
		var sql = ""
		switch conflict {
		case .abort:
			sql = "UPDATE "
		default:
			sql = "UPDATE OR \(conflict.rawValue)  "
		}
		sql += "\(table)  SET "

		var first = true
		for (k, v) in values {
			if !first {
				sql += ","
			}
			sql += k + "=? "
			argList.append(v)
			first = false
		}
		if let w = w {
			if w.cond.notEmpty {
				sql += " WHERE " + w.cond
				argList.append(contentsOf: w.args)
			}
		}
		return update(sql: sql, args: argList)
	}
}

public extension SQLite {
	func replace(table: String, values: [String: SQLValue]) -> Int64 {
		return insert(or: .abort, table: table, values: values)
	}

	func insert(table: String, values: [String: SQLValue]) -> Int64 {
		return insert(or: .abort, table: table, values: values)
	}

	func insert(or conflict: Conflict, table: String, values: [String: SQLValue]) -> Int64 {
		var sql = ""
		switch conflict {
		case .abort:
			sql = "INSERT INTO "
		case .replace:
			sql = "REPLACE INTO "
		default:
			sql = "INSERT OR \(conflict.rawValue) INTO "
		}
		sql += "\(table) ("
		sql += values.map {
			$0.key
		}.joined(separator: ",")
		sql += ") VALUES ("
		sql += values.map { _ in
			"?"
		}.joined(separator: ",")
		sql += ")"

		return insert(sql: sql, args: values.map {
			$0.value
		})
	}

}