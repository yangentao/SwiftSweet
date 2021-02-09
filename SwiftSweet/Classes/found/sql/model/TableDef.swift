//
// Created by entaoyang@163.com on 2017/10/26.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation
import SQLite3

public class Column {
	public let property: Property
	//列名
	public let name: String

	//SQLTYPE_INTEGER, SQLTYPE_REAL,SQLTYPE_TEXT,SQLTYPE_BLOB
	//如未指定type, 则使用SQLTYPE_TEXT
	public var type: CInt = SQLITE3_TEXT

	//是否主键
	//如果有两个列都声明成主键, 则自增autoInc无效
	public var primaryKey: Bool = false
	public var autoInc: Bool = false
	//unique的值仅仅用于区分是否联合唯一约束, 并不是定义唯一约束的名称
	//单一列的唯一约束, unique的值 等于 name的值, 如 age列, unique="age"
	//两列联合唯一约束, 两列unique的值相等, 且不等于任何一个列的名称, 如 age列和addr列的 unique的值都是"age_addr" 则创建联合唯一约束
	//如果age的unique="age", addr的unique="age" 则会创建俩个单一列的约束 table_age, table_addr
	public var unique: String = ""
	public var notNull: Bool = false
	//"123", "'abc'"
	public var defaultValue: String = ""
	//完整的check语句,包含列名, 如:"age BETWEEN 1 AND 100"
	public var check: String = ""
	//是否在此列上创建索引
	public var indexable: Bool = false

	public init(_ prop: Property) {
		self.property = prop
		self.name = prop.name
	}
}

public extension Column {
	@discardableResult
	func PrimaryKey() -> Column {
		self.primaryKey = true
		return self
	}

	@discardableResult
	func AutoInc() -> Column {
		self.autoInc = true
		return self
	}

	@discardableResult
	func Unique() -> Column {
		self.unique = name
		return self
	}

	@discardableResult
	func Unique(_ uniqueName: String) -> Column {
		self.unique = uniqueName
		return self
	}

	@discardableResult
	func NotNull() -> Column {
		self.notNull = true
		return self
	}

	@discardableResult
	func Default(_ value: String) -> Column {
		self.defaultValue = value
		return self
	}

	@discardableResult
	func Check(_ c: String) -> Column {
		self.check = c
		return self
	}

	@discardableResult
	func Index() -> Column {
		self.indexable = true
		return self
	}

	@discardableResult
	func Text() -> Column {
		self.type = SQLITE3_TEXT
		return self
	}

	@discardableResult
	func Integer() -> Column {
		self.type = SQLITE_INTEGER
		return self
	}

	@discardableResult
	func Real() -> Column {
		self.type = SQLITE_FLOAT
		return self
	}

	@discardableResult
	func Blob() -> Column {
		self.type = SQLITE_BLOB
		return self
	}

	//http://www.sqlite.org/lang_createtable.html
	func defColumnSQL(_ withPK: Bool, _ cc: String) -> String {
		var s = "\(name) "
		switch type {
		case SQLITE3_TEXT:
			s += "TEXT "
		case SQLITE_INTEGER:
			s += "INTEGER "
		case SQLITE_FLOAT:
			s += "REAL "
		case SQLITE_BLOB:
			s += "BLOB "
		default:
			s += "TEXT "
			break
		}

		if withPK && primaryKey {
			s += "PRIMARY KEY \(cc) "
			if autoInc {
				s += "AUTOINCREMENT "
			}
		} else {
			if unique == name {
				s += "UNIQUE \(cc) "
			}

			if notNull {
				s += "NOT NULL "
			}
		}
		if !defaultValue.isEmpty {
			s += "DEFAULT \(defaultValue) "
		}
		if !check.isEmpty {
			s += "CHECK(" + check + ") "
		}
		return s
	}
}

public class Table {
	public var databaseName: String = "default.db"
	public var name: String = ""

	//https://sqlite.org/lang_conflict.html
	//ROLLBACK, ABORT, FAIL, IGNORE, REPLACE
	public var onConflict: String = "ABORT"

	public var colMap: [String: Column] = [:]

	public var columns: [Column] {
		return colMap.valueArray
	}

	public init(_ name: String) {
		self.name = name
	}

	public lazy var columnsDefine: [String] = {
		var items = [String]()
		let CC: String
		if onConflict == "ABORT" {
			CC = ""
		} else {
			CC = "ON CONFLICT \(self.onConflict) "
		}

		//主键
		let pkCols = self.columns.filter {
			$0.primaryKey
		}
		let singlePK = pkCols.count == 1
		items += self.columns.map {
			$0.defColumnSQL(singlePK, CC)
		}
		//联合主键
		if !singlePK {
			let pk = pkCols.map {
				$0.name
			}.joined(separator: ",")

			if pk.notEmpty {
				items.append("CONSTRAINT primary_key PRIMARY KEY (" + pk + ") " + CC)
			}
		}
		//联合唯一约束
		var uniCols = self.columns.filter {
			$0.unique.notEmpty && $0.unique != $0.name
		}
		if uniCols.notEmpty {
			repeat {
				var ucArr = [Column]()
				let uc = uniCols.popLast()!
				ucArr.append(uc)
				ucArr += uniCols.removeAllIf {
					$0.unique == uc.unique
				}

				let us = ucArr.map {
					$0.name
				}.joined(separator: ",")

				let uname = ucArr.map {
					$0.name
				}.joined(separator: "_")
				items.append("CONSTRAINT \(uname)  UNIQUE (" + us + ") " + CC)
			} while !uniCols.isEmpty
		}
		return items
	}()
}

public extension Table {
	var sqlite: SQLite {
		return SQLite(file: File.docFile(self.databaseName))
	}

	subscript(colName: ColumnName) -> Column {
		return colMap[colName.toName]!
	}

	var primaryKeys: [Column] {
		return self.columns.filter {
			$0.primaryKey
		}
	}

	func dropTable() {
		self.sqlite.dropTable(name: self.name)
	}

	func existTable() -> Bool {
		return self.sqlite.existTable(self.name)
	}

	func createTable() {
		let indexs = self.columns.filter {
			$0.indexable
		}.map {
			$0.name
		}
		self.sqlite.createTable(name: self.name, cols: self.columnsDefine)
		for c in indexs {
			self.sqlite.createIndex(table: self.name, col: c)
		}
	}

	func dumpTable() {
		logd("Dump Table: ", self.name)
		self.sqlite.dumpTable(self.name)
	}
}