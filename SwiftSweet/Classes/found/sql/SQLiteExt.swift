//
// Created by entaoyang@163.com on 2017/10/26.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

public class IndexListItem: Codable, CustomStringConvertible {
	//index name
	public var name: String = ""
	public var origin: String = ""
	public var seq: Int = 0
	public var partial: Int = 0
	public var unique: Int = 0

	public var description: String {
		return self.toYsonObject.yson
	}
}

public class IndexInfo: Codable, CustomStringConvertible {
	//column name
	public var name: String = ""
	public var cid: Int = 0
	public var seqno: Int = 0

	public var description: String {
		return self.toYsonObject.yson
	}
}

public class ColumnInfo: Codable, CustomStringConvertible {
	//column name
	public var name: String = ""
	//INTEGER, TEXT, REAL, BLOB
	public var type: String = ""
	public var cid: Int = 0
	public var notnull: Int = 0
	public var pk: Int = 0

	public var isInteger: Bool {
		return self.type == "INTEGER"
	}
	public var isText: Bool {
		return self.type == "TEXT"
	}
	public var isReal: Bool {
		return self.type == "REAL"
	}
	public var isBlob: Bool {
		return self.type == "BLOB"
	}

	public var description: String {
		return self.toYsonObject.yson
	}
}

public extension SQLite {
	var userVersion: Int {
		get {
			return query(sql: "PRAGMA user_version").intResult() ?? 0
		}
		set {
			exec(sql: "PRAGMA user_version=\(newValue)")
		}
	}

	func createTable(name: String, cols: [String]) {
		var s = "CREATE TABLE IF NOT EXISTS \(name) ("
		s += cols.joined(separator: ",")
		s += ")"
		self.exec(sql: s)
	}

	func dropTable(name: String) {
		let s = "DROP TABLE IF EXISTS \(name)"
		self.exec(sql: s)
	}

	static func indexNameOfColumn(table: String, col: ColumnName) -> String {
		return "\(table)_\(col.toName)_INDEX"
	}

	func createIndex(table: String, col: ColumnName) {
		let indexName = SQLite.indexNameOfColumn(table: table, col: col)
		let s = "CREATE INDEX IF NOT EXISTS \(indexName) ON \(table)(\(col.toName))"
		self.exec(sql: s)
	}

	func createView(name: String, as selectStmt: String) {
		let s = "CREATE VIEW IF NOT EXISTS \(name) AS \(selectStmt)"
		self.exec(sql: s)
	}

	func dropView(name: String) {
		let s = "DROP VIEW IF EXISTS \(name)"
		self.exec(sql: s)
	}

	func dropIndex(name: String) {
		let s = "DROP INDEX IF EXISTS \(name)"
		self.exec(sql: s)
	}

	func dropIndex(table: String, col: ColumnName) {
		let name = "\(table)_\(col.toName)_INDEX"
		let s = "DROP INDEX IF EXISTS \(name)"
		self.exec(sql: s)
	}

	func indexList(_ table: String) -> [IndexListItem] {
		let a: [IndexListItem] = query(sql: "PRAGMA index_list(\(table))").decodeArray()
		return a
	}

	func indexInfo(_ indexName: String) -> IndexInfo? {
		let a: YsonObject? = query(sql: "PRAGMA index_info(\(indexName))").allRows().firstObject
		if let b = a {
			return b.toModel()
		}
		return nil
	}

	func tableInfo(_ tableName: String) -> [ColumnInfo] {
		let ls: [ColumnInfo] = query(sql: "PRAGMA table_info(\(tableName))").decodeArray()
		return ls
	}

	func addColumn(_ table: String, _ colDefine: String) {
		let s = "ALTER TABLE \(table) ADD COLUMN \(colDefine)"
		self.exec(sql: s)
	}

	func existTable(_ table: String) -> Bool {
		return   query(sql: "SELECT * from sqlite_master where type='table' and name='\(table)'").existResult()
	}

	func tables() -> Set<String> {
		return   query(sql: "SELECT name from sqlite_master where type='table'").stringSetResult()
	}

	func indexsOf(table: String) -> Set<String> {
		return   query(sql: "SELECT name from sqlite_master where type='index' and tbl_name='\(table)'").stringSetResult()
	}

	func dumpTable(_ table: String) {
		let ya: YsonArray? = query(sql: "SELECT * from \(table)").allRows()
		logd(ya)
	}
}