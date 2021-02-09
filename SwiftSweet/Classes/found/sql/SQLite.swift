//
// Created by entaoyang@163.com on 2017/10/25.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation
import SQLite3

public var DEBUG_SQL = true

let ROWID = "_ROWID_"

fileprivate let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
fileprivate let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

fileprivate extension CInt {
	var sqlMsg: String {
		return "SQL Error: \(self), MSG:" + String(cString: sqlite3_errstr(self))
	}
	var sqlOK: Bool {
		return (self == SQLITE_OK || self == SQLITE_DONE || self == SQLITE_ROW)
	}
}

fileprivate class SQLiteData {
	private var dbRaw: OpaquePointer? = nil
	let path: String
	let lock = NSRecursiveLock()

	init(path: String) {
		self.path = path
	}

	@discardableResult
	func open() -> Bool {
		let flags: Int32 = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
		let err = sqlite3_open_v2(path, &dbRaw, flags, nil)
		if SQLITE_OK != err {
			close()
			loge(err.sqlMsg)
			return false
		}
		sqlite3_busy_timeout(dbRaw, 30000) // 30sec timeout
		return true
	}

	var isOpen: Bool {
		return dbRaw != nil
	}

	deinit {
		close()
	}

	func close() {
		self.lock.lock()
		defer {
			self.lock.unlock()
		}
		if dbRaw != nil {
			sqlite3_close_v2(dbRaw)
			dbRaw = nil
		}
	}

	@discardableResult
	func use<T>(_ block: (OpaquePointer) -> T) -> T? {
		self.lock.lock()
		defer {
			self.lock.unlock()
		}
		if let db = self.dbRaw {
			return block(db)
		}
		return nil
	}

}

private var databaseInstanceMap: [String: WeakRef<SQLiteData>] = [:]

fileprivate func makeSQLData(path: String) -> SQLiteData {
	objc_sync_enter(databaseInstanceMap)
	defer {
		objc_sync_exit(databaseInstanceMap)
	}
	if let d = databaseInstanceMap[path]?.value {
		if d.isOpen {
			return d
		} else {
			databaseInstanceMap.removeValue(forKey: path)
		}
	}
	let a = SQLiteData(path: path)
	a.open()
	databaseInstanceMap[path] = WeakRef(a)
	return a
}

public class SQLite {
	fileprivate let handle: SQLiteData

	public init(path: String) {
		self.handle = makeSQLData(path: path)
	}

	public convenience init(file: File) {
		self.init(path: file.fullPath)
	}
}

public extension SQLite {

	func lock() {
		self.handle.lock.lock()
	}

	func unlock() {
		self.handle.lock.unlock()
	}

	var errorMessage: String? {
		return self.handle.use { db in
			String(cString: sqlite3_errmsg(db))
		}
	}

	var insertRowId: Int64 {
		return self.handle.use { db in
			sqlite3_last_insert_rowid(db)
		} ?? 0
	}
	var changeCount: Int {
		return self.handle.use { db in
			Int(sqlite3_changes(db))
		} ?? 0
	}

	var inTransation: Bool {
		return self.handle.use { db in
			sqlite3_get_autocommit(db) == CInt(0)
		} ?? false
	}

	func transaction(_ callback: () throws -> Void) {
		self.lock()
		defer {
			self.unlock()
		}

		do {
			self.exec(sql: "BEGIN")
			try callback()
			self.exec(sql: "COMMIT")
		} catch (let err) {
			self.exec(sql: "ROLLBACK")
			loge("error: \(err)")
		}

	}

	func query(sql: String) -> Cursor {
		return   prepare(sql).query()
	}

	func query(sql: String, args: [SQLValue]) -> Cursor {
		return   prepare(sql).bind(args).query()
	}

	func query(sql: String, args: [String: SQLValue]) -> Cursor {
		return   prepare(sql).bind(args).query()
	}

	//返回更新条数, -1失败, 0:没有记录被更新, >0:已经更新的条数
	@discardableResult
	func update(sql: String) -> Int {
		return   prepare(sql).update()
	}

	@discardableResult
	func update(sql: String, args: [SQLValue]) -> Int {
		return   prepare(sql).bind(args).update()
	}

	@discardableResult
	func update(sql: String, args: [String: SQLValue]) -> Int {
		return   prepare(sql).bind(args).update()
	}

	//返回ROWID, 行号, >0成功, -1:失败
	@discardableResult
	func insert(sql: String) -> Int64 {
		return   prepare(sql).insert()
	}

	@discardableResult
	func insert(sql: String, args: [SQLValue]) -> Int64 {
		return   prepare(sql).bind(args).insert()
	}

	@discardableResult
	func insert(sql: String, args: [String: SQLValue]) -> Int64 {
		return   prepare(sql).bind(args).insert()
	}

	//返回是否执行成功
	func exec(sql: String) {
		prepare(sql).exec()
	}

	func exec(sql: String, args: [SQLValue]) {
		prepare(sql).bind(args).exec()
	}

	func exec(sql: String, args: [String: SQLValue]) {
		prepare(sql).bind(args).exec()
	}

	func prepare(_ sql: String) -> Statement {
		if DEBUG_SQL {
			logd("PREPARE: ", sql)
		}
		if !self.handle.isOpen {
			fatalError("database not inited! " + sql)
		}
		return Statement(self, sql)
	}

}

public class Statement {
	fileprivate var stmt: OpaquePointer? = nil
	fileprivate var paramCount: Int = 0
	fileprivate var db: SQLite
	let sql: String

	fileprivate init(_ db: SQLite, _ sql: String) {
		self.db = db
		self.sql = sql
		let err: CInt? = db.handle.use { d in
			sqlite3_prepare_v2(d, sql, -1, &stmt, nil)
		}
		if let code = err {
			if !code.sqlOK {
				close()
				fatalError(code.sqlMsg)
			}
		} else {
			fatalError("无效的数据库")
		}
		self.db.lock()
		defer {
			self.db.unlock()
		}
		self.paramCount = Int(sqlite3_bind_parameter_count(stmt))
	}

	deinit {
		close()
	}

	public func close() {
		self.db.lock()
		defer {
			self.db.unlock()
		}
		if stmt != nil {
			sqlite3_finalize(stmt)
			stmt = nil
		}
	}

	@discardableResult
	fileprivate func step() -> Int32 {
		self.db.lock()
		defer {
			self.db.unlock()
		}
		let code: CInt = sqlite3_step(self.stmt)
		if !code.sqlOK {
			loge(code.sqlMsg)
			fatalError(sql)
		}
		return code
	}
}

public extension Statement {
	func bind(_ args: [SQLValue]) -> Statement {
		if args.count != paramCount {
			fatalError("参数个数不匹配: \(args)")
		}
		if DEBUG_SQL {
			logd("Bind:", args)
		}
		self.db.lock()
		defer {
			self.db.unlock()
		}
		for index in 0..<args.count {
			let arg = args[index]
			bind(at: CInt(index + 1), arg: arg)
		}
		return self
	}

	func bind(_ values: [String: SQLValue]) -> Statement {
		self.db.lock()
		defer {
			self.db.unlock()
		}
		for (name, value) in values {
			let idx = sqlite3_bind_parameter_index(stmt, name)
			if idx > 0 {
				bind(at: idx, arg: value)
			} else {
				fatalError("参数未找到: \(name)")
			}
		}
		return self
	}

	//index 从 1 开始
	private func bind(at index: CInt, arg: SQLValue?) {
		var code: CInt = SQLITE_OK
		switch arg {
		case nil:
			code = sqlite3_bind_null(stmt, index)
		case is SQLNull:
			code = sqlite3_bind_null(stmt, index)
			break
		case is YsonNull:
			code = sqlite3_bind_null(stmt, index)
		case let n as SQLInt:
			code = sqlite3_bind_int64(stmt, index, n.toSQLInt)
		case let r as SQLReal:
			code = sqlite3_bind_double(stmt, index, r.toSQLReal)
		case let d as SQLBlob:
			let bs = d.toSQLBlob.bytes
			code = sqlite3_bind_blob(stmt, index, bs, CInt(bs.count), SQLITE_TRANSIENT)
		case let s as SQLText:
			code = sqlite3_bind_text(stmt, index, s.toSQLText, -1, SQLITE_TRANSIENT)

		default:
			close()
			fatalError("不能识别的类型 index=\(index) value= \(arg ?? "nil")")
		}
		if !code.sqlOK {
			close()
			fatalError(" bind failed: \(index): \(arg ?? "nil")  SQL:" + sql)
		}
	}

	func query() -> Cursor {
		return Cursor(stmt: self)
	}

	//返回-1表示失败
	func insert() -> Int64 {
		defer {
			self.close()
		}
		self.step()
		return self.db.insertRowId
	}

	func update() -> Int {
		defer {
			self.close()
		}
		self.step()
		return self.db.changeCount
	}

	func exec() {
		defer {
			self.close()
		}
		self.step()
	}

}

public class RowGenerator: IteratorProtocol {
	var c: Cursor

	public typealias Element = Cursor

	fileprivate init(_ c: Cursor) {
		self.c = c
	}

	public func next() -> Cursor? {
		if c.moveToNext() {
			return c
		}
		return nil
	}
}

public class Cursor: Sequence {
	var stmt: Statement

	public typealias Iterator = RowGenerator

	fileprivate init(stmt: Statement) {
		self.stmt = stmt
	}

	deinit {
		stmt.close()
	}

	public func makeIterator() -> RowGenerator {
		return RowGenerator(self)
	}

	public lazy var rowCount: Int = Int(sqlite3_data_count(stmt.stmt))

	public lazy var columnCount: Int = Int(sqlite3_column_count(stmt.stmt))

	public lazy var columnNames: [String] = {
		self.stmt.db.lock()
		defer {
			self.stmt.db.unlock()
		}
		var arr = Array<String>()
		arr.reserveCapacity(16)
		for i in 0..<columnCount {
			let name = sqlite3_column_name(stmt.stmt, CInt(i))
			arr.append(String(cString: name!))
		}
		return arr
	}()

	private lazy var nameIndexDic: [String: Int] = {
		var dic: [String: Int] = [String: Int]()
		dic.reserveCapacity(16)
		for i in 0..<columnCount {
			dic[columnNames[i]] = i
		}
		return dic
	}()
}

public extension Cursor {
	func close() {
		stmt.close()
	}

	//不存在则返回-1
	func columnIndex(_ name: String) -> Int {
		return nameIndexDic[name] ?? -1
	}

	func columnName(_ index: Int) -> String {
		return columnNames[index]
	}

	//SQLITE_TYPE_XXX
	func columnType(_ index: Int) -> CInt {
		return sqlite3_column_type(stmt.stmt, CInt(index))
	}

	func moveToNext() -> Bool {
		let result = stmt.step()
		switch result {
		case SQLITE_ROW:
			return true
		case SQLITE_DONE:
			return false
		default:
			close()
			loge(" moveToNext failed: \(stmt.sql)")
			fatalError()
		}

	}

	func str(_ column: Int) -> String? {
		if columnType(column) == SQLITE3_TEXT {
			if let buf: UnsafePointer<UInt8> = sqlite3_column_text(stmt.stmt, CInt(column)) {
				return String(cString: buf)
			}
		}
		return nil
	}

	func int(_ column: Int) -> Int64? {
		if columnType(column) == SQLITE_INTEGER {
			return sqlite3_column_int64(stmt.stmt, CInt(column))
		}
		return nil
	}

	func real(_ column: Int) -> Double? {
		if columnType(column) == SQLITE_FLOAT {
			return sqlite3_column_double(stmt.stmt, CInt(column))
		}
		return nil
	}

	func blob(_ column: Int) -> Data? {
		if columnType(column) == SQLITE_BLOB {
			let data = sqlite3_column_blob(stmt.stmt, CInt(column))
			let size = sqlite3_column_bytes(stmt.stmt, CInt(column))
			if data != nil {
				return Data(bytes: data!, count: Int(size))
			}
		}
		return nil
	}

	func str(_ name: ColumnName) -> String? {
		let index = columnIndex(name.toName)
		if index >= 0 {
			return str(index)
		}
		return nil
	}

	func int(_ name: ColumnName) -> Int64? {
		let index = columnIndex(name.toName)
		if index >= 0 {
			return int(index)
		}
		return nil
	}

	func real(_ name: ColumnName) -> Double? {
		let index = columnIndex(name.toName)
		if index >= 0 {
			return real(index)
		}
		return nil
	}

	func blob(_ name: ColumnName) -> Data? {
		let index = columnIndex(name.toName)
		if index >= 0 {
			return blob(index)
		}
		return nil
	}

}


