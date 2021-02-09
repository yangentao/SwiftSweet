//
// Created by entaoyang@163.com on 2017/10/26.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

public class SQLQuery {
	private var _db: SQLite
	private var _distinct = false
	private var _args = [SQLValue]()

	private var _columns = [String]()
	private var fromClause = [String]()

	private var joinClause: String = ""
	private var onClause: String = ""

	private var whereClause: String = ""
	private var orderbyClause: String = ""
	private var limitClause: String = ""

	private var groupByClause: String = ""
	private var havingClause: String = ""

	public init(_ db: SQLite) {
		self._db = db
	}
}

public extension SQLQuery {

	@discardableResult
	func groupBy(_ s: String) -> SQLQuery {
		self.groupByClause = "GROUP BY \(s)"
		return self
	}

	@discardableResult
	func having(_ s: String) -> SQLQuery {
		self.havingClause = "HAVING  \(s)"
		return self
	}

	@discardableResult
	func distinct_() -> SQLQuery {
		self._distinct = true
		return self
	}

	@discardableResult
	func select(_ columns: [ColumnName]) -> SQLQuery {
		self._columns += columns.map {
			$0.toName
		}
		return self
	}

	@discardableResult
	func select(_ columns: ColumnName...) -> SQLQuery {
		self._columns += columns.map {
			$0.toName
		}
		return self
	}

	func from(_ from: [String]) -> SQLQuery {
		self.fromClause.append(contentsOf: from)
		return self
	}

	func from(_ from: String) -> SQLQuery {
		self.fromClause.append(from)
		return self
	}

	func join(_ tables: [String], joinType: String = "LEFT") -> SQLQuery {
		let s = tables.joined(separator: ", ")
		self.joinClause = "\(joinType) JOIN ( \(s) )"
		return self
	}

	func on(s: String) -> SQLQuery {
		self.onClause = " ON ( \(s) ) "
		return self
	}

	@discardableResult
	func where_(_ w: String?) -> SQLQuery {
		return self.where_(w, [])
	}

	@discardableResult
	func where_(_ w: String?, _  args: [SQLValue]) -> SQLQuery {
		if let ww = w {
			self.whereClause = "WHERE \(ww)"
			self._args.append(contentsOf: args)
		}
		return self
	}

	@discardableResult
	func where_(_ w: Where?) -> SQLQuery {
		if let ww = w {
			self.where_(ww.cond, ww.args)
		}
		return self
	}

	@discardableResult
	func desc(_ col: ColumnName) -> SQLQuery {
		if (orderbyClause.isEmpty) {
			orderbyClause = "ORDER BY \(col.toName)  DESC"
		} else {
			orderbyClause += ", \(col) DESC"
		}
		return self
	}

	@discardableResult
	func asc(_ col: ColumnName) -> SQLQuery {
		if (orderbyClause.isEmpty) {
			orderbyClause = "ORDER BY \(col.toName)  ASC"
		} else {
			orderbyClause += ", \(col) ASC"
		}
		return self
	}

	@discardableResult
	func limit(_ size: Int) -> SQLQuery {
		return self.limit(size, offset: 0)
	}

	@discardableResult
	func limit(_ size: Int, offset: Int) -> SQLQuery {
		self.limitClause = "LIMIT \(size) OFFSET \(offset)"
		return self
	}

	func queryCount() -> Int {
		let sql = buildSql(true)
		return _db.query(sql: sql, args: _args).intResult() ?? 0
	}

	func query() -> Cursor {
		let sql = buildSql()
		return _db.query(sql: sql, args: _args)
	}

	private func buildSql(_ countSql: Bool = false) -> String {
		var sql = "SELECT "
		let cols = _columns.joined(separator: ",")
		let ds = self._distinct ? "DISTINCT" : ""
		if countSql {
			if (cols.isEmpty) {
				sql += " COUNT(*) "
			} else {
				sql += " COUNT(\(ds) \(cols) ) "
			}
		} else {
			sql += ds + (cols.isEmpty ? " * " : cols)

		}
		sql += " FROM " + fromClause.joined(separator: ",")
		sql += " "

		if (self.joinClause.isEmpty) {
			self.onClause = ""
		}
		if (self.groupByClause.isEmpty) {
			self.havingClause = ""
		}
		let ls = [self.joinClause, self.onClause, self.whereClause, self.groupByClause, self.havingClause, self.orderbyClause, self.limitClause]
		sql += ls.map({ $0.trimed }).filter({ !$0.isEmpty }).joined(separator: " ")
		return sql
	}

	@discardableResult
	//可以多次调用
	func args(_ args: SQLValue...) -> SQLQuery {
		for arg in args {
			self._args.append(arg)
		}
		return self
	}

	@discardableResult
	func argsArray(_ args: [SQLValue]) -> SQLQuery {
		for arg in args {
			self._args.append(arg)
		}
		return self
	}
}

extension SQLite {
	func find() -> SQLQuery {
		return SQLQuery(self)
	}

	func from(_ table: String) -> SQLQuery {
		return SQLQuery(self).from([table])
	}

	func selfctFrom(_ table: String, _ columns: [String]) -> SQLQuery {
		return SQLQuery(self).from(table).select(columns)
	}

}


