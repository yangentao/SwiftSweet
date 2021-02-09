//
// Created by entaoyang@163.com on 2017/10/27.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

fileprivate func sqlValueToModelValue(_ sqlVal: SQLValue, _ modelType: Any.Type) -> Any? {
    switch sqlVal {
    case nil:
        return nil
    case is SQLNull:
        return nil
    case is YsonNull:
        return nil
    case let n as SQLInt:
        return n.toSQLInt.toNSNumber
    case let f as SQLReal:
        return f.toSQLReal.toNSNumber
    case let t as SQLText:
        return t.toSQLText
    case let b as SQLBlob:
        return b.toSQLBlob
    default:
        return nil
    }
}

fileprivate func modelValueToSqlValue(_ value: Any, _ p: Property) -> SQLValue? {
    switch value {
    case nil:
        return SQLNull.inst
    case is SQLNull:
        return SQLNull.inst
    case is YsonNull:
        return SQLNull.inst
    default:
        break;
    }
    if p.isSQLInteger {
        if value is NSNumber {
            return (value as! NSNumber).int64Value
        }
    } else if p.isSQLReal {
        if value is NSNumber {
            return (value as! NSNumber).doubleValue
        }
    } else if p.isSQLText {
        if value is String {
            return value as! String
        } else if value is NSString {
            return value as! NSString
        }
    } else if p.isSQLBlob {
        if value is NSData {
            return value as! NSData
        } else if value is Data {
            return value as! Data
        }
    }
    loge("unknuwn property \(p.name), value: \(value)")
    return nil
}

private func getClassNameOnly(_ t: AnyObject.Type) -> String {
    let tableName = NSStringFromClass(t)
    let n = tableName.lastIndexOf(".")
    if n >= 0 {
        return tableName[(n + 1)...].toString()
    } else {
        return tableName
    }
}

public protocol IModel: class {

}

fileprivate var modelTableMap: [String: Table] = [:]

open class Model: NSObject, IModel {
    fileprivate var _updating: Bool = false
    fileprivate var _updateKeySet = Set<String>()

    public required override init() {
        super.init()
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if self._updating, let k = keyPath {
            self._updateKeySet.insert(k)
        }
    }

    open class func onTableDefine(_ table: Table) {

    }

    open class func onTableCreated(_ table: Table) {

    }

    open override var description: String {
        let t = type(of: self)
        var s = getClassNameOnly(t) + " : "
        let ls = Reflect.listProp(t)
        for p in ls {
            if let v = self.value(forKey: p.name) {
                s += "\(p.name) = \(v), "
            } else {
                s += "\(p.name) = null, "
            }
        }
        return s
    }

}

public extension IModel where Self: Model {

    static var tableName: String {
        return getClassNameOnly(self)
    }
    static var _table: Table {
        objc_sync_enter(modelTableMap)
        defer {
            objc_sync_exit(modelTableMap)
        }
        if let t = modelTableMap[self.tableName] {
            return t
        }
        let t = self.makeTable()
        return t
    }

    static var _sqlite: SQLite {
        return self._table.sqlite
    }
    static var columnNames: Set<String> {
        return self._table.colMap.keySet
    }
    static var columnProperties: [Property] {
        var ls = [Property]()
        let set = self.columnNames
        for p in Reflect.listProp(self) {
            if p.name =* set {
                ls += p
            }
        }
        return ls
    }

    fileprivate static func makeTable() -> Table {
        let tableName = getClassNameOnly(self)
        let t = Table(tableName)
        let ls = Reflect.listProp(self).filter {
            !$0.isReadonly && !$0.isWeak
        }
        for p in ls {
            let c = Column(p)
            if NSNumber.self == p.type {
                c.Real()
            } else if integerTypes.contains(where: { $0 == p.type }) {
                c.Integer()
            } else if realTypes.contains(where: { $0 == p.type }) {
                c.Real()
            } else if textTypes.contains(where: { $0 == p.type }) {
                c.Text()
            } else if blobTypes.contains(where: { $0 == p.type }) {
                c.Blob()
            } else {
                continue
            }
            t.colMap[p.name] = c
        }
        self.onTableDefine(t)
        if !t.existTable() {
            t.createTable()
            modelTableMap[tableName] = t
            self.onTableCreated(t)
        } else {
            modelTableMap[tableName] = t
            let cols = t.sqlite.tableInfo(t.name).map({ $0.name })
            let tableColNames = t.colMap.keySet
            let a = tableColNames.subtracting(cols)
            for colName in a {
                t.sqlite.addColumn(t.name, t.colMap[colName]!.defColumnSQL(false, ""))
            }
            let newIndexCols: [Column] = t.colMap.valueArray.filter {
                $0.indexable
            }
            let oldIndexs = t.sqlite.indexList(t.name).map({ $0.name })
            let b: [Column] = newIndexCols.filter { c in
                SQLite.indexNameOfColumn(table: t.name, col: c.name) !=* oldIndexs
            }
            for idx in b {
                t.sqlite.createIndex(table: t.name, col: idx.name)
            }
        }
        return t
    }

}

public extension IModel where Self: Model {

    func fromRowData(_ map: RowData) {
        for p in Self.columnProperties {
            if let sqlVal = map[p.name] {
                if let v = sqlValueToModelValue(sqlVal, p.type) {
                    self.setValue(v, forKey: p.name)
                }
            }
        }
    }

    var toRowData: RowData {
        var map = RowData()
        for p in Self.columnProperties {
            if let v = self.value(forKey: p.name) {
                if let sv: SQLValue = modelValueToSqlValue(v, p) {
                    map[p.name] = sv
                }
            }
        }
        return map
    }

    static func findOne(_ w: Where?) -> Self? {
        return self.finder.where_(w).limit(1).query().firstModel()
    }

    static func findAll() -> [Self] {
        return find(nil)
    }

    static func find(_ w: Where?) -> [Self] {
        return finder.where_(w).query().allModel()
    }

    static func find(_ w: Where?, _ block: (SQLQuery) -> Void) -> [Self] {
        let f = finder.where_(w)
        block(f)
        return f.query().allModel()
    }

    static var finder: SQLQuery {
        return Self._sqlite.from(Self._table.name)
    }

    static func exist(_  w: Where) -> Bool {
        return   finder.where_(w).limit(1).query().existResult()
    }

    @discardableResult
    static func delete(_ w: Where?) -> Int {
        return self._sqlite.delete(table: self._table.name, where: w)
    }

    @discardableResult
    func deleteByKey() -> Int {
        guard let pkWhere = self._primaryKeyWhere else {
            return 0
        }
        return Self.delete(pkWhere)

    }

    fileprivate var _primaryKeyWhere: Where? {
        var w: Where? = nil
        for pk: Column in Self._table.primaryKeys {
            if let mVal = self.value(forKey: pk.name) {
                if let sqlVal = modelValueToSqlValue(mVal, pk.property) {
                    w = w && pk.name ?= sqlVal
                } else {
                    loge("主键值不可识别: \(pk.name) = \(mVal)")
                    return nil
                }
            } else {
                return nil
            }
        }
        return w
    }

    @discardableResult
    func updateByKey() -> Int {
        return self.updateByKey([])
    }

    @discardableResult
    func updateByKey(_ cols: [ColumnName]) -> Int {
        guard let pkWhere = self._primaryKeyWhere else {
            return 0
        }
        var map = self.toRowData
        if cols.notEmpty {
            map.retain(cols.map({ $0.toName }))
        }
        for pkCol in Self._table.primaryKeys {
            map.removeValue(forKey: pkCol.name)
        }
        return Self.update(map, pkWhere)
    }

    @discardableResult
    func update(_ block: BlockVoid) -> Int {
        guard let _ = self._primaryKeyWhere else {
            return 0
        }
        let sync = Sync(self).enter()
        defer {
            sync.exit()
        }
        for c in Self._table.columns {
            self.addObserver(self, forKeyPath: c.name, options: .new, context: nil)
        }
        self._updateKeySet.clear()
        self._updating = true
        block()
        self._updating = false
        for c in Self._table.columns {
            self.removeObserver(self, forKeyPath: c.name)
        }
        var n = 0
        if self._updateKeySet.notEmpty {
            n = updateByKey(self._updateKeySet.toArray)
        }
        self._updateKeySet.removeAll()
        return n
    }

    @discardableResult
    static func update(_ values: [KeyValue], _   w: Where) -> Int {
        var vs = [String: SQLValue]()
        for kv in values {
            vs[kv.key] = kv.sqlValue
        }
        return Self.update(vs, w)
    }

    @discardableResult
    static func update(_ values: [String: SQLValue], _ w: Where) -> Int {
        return Self._sqlite.update(table: Self._table.name, values: values, where: w)
    }

    @discardableResult
    static func insert(_ conflict: Conflict, _ values: [String: SQLValue]) -> Int64 {
        return Self._table.sqlite.insert(or: conflict, table: Self._table.name, values: values)
    }

    func replace(_ cols: [ColumnName] = []) {
        insert(.replace, cols)
    }

    func insert(_ cols: [ColumnName] = []) {
        insert(.abort, cols)
    }

    func insert(_ conflict: Conflict, _ cols: [ColumnName] = []) {
        var map = self.toRowData
        var ai: Bool = false
        var pkCol: Column? = nil
        let pkCols = Self._table.primaryKeys
        if pkCols.count == 1 {
            if pkCols[0].autoInc {
                pkCol = pkCols[0]
            }
        }
        if let col = pkCol {
            if let pkValue: SQLValue = map[col.name], pkValue is SQLInt {
                if (pkValue as! SQLInt).toSQLInt == 0 {
                    map.removeValue(forKey: col.name)
                    ai = true
                }
            }
        }
        if cols.notEmpty {
            map.retain(cols.map {
                $0.toName
            })
        }
        let n: Int64 = Self.insert(conflict, map)
        if ai {
            self.setValue(n, forKey: pkCol!.name)
        }
    }

}

fileprivate func ysonValueToModelValue(_ ysonVal: YsonValue?, _ modelType: Any.Type) -> Any? {
    switch ysonVal {
    case nil:
        return nil
    case is YsonNull:
        return nil
    case let b as YsonBool:
        let n = b.data
        return n ? 1.toNSNumber : 0.toNSNumber
    case let f as YsonNum:
        return f.data
    case let s as YsonString:
        return s.data
    case let yb as YsonBlob:
        return yb.data.base64EncodedString()
    case is YsonArray:
        loge("不支持 YsonArray")
    case is YsonObject:
        loge("不支持 YsonObject")
    default:
        break
    }
    return nil
}

public extension IModel where Self: Model {
    func fromYson(_ yo: YsonObject) {
        for c in Self._table.columns {
            if let yv = yo.data[c.name] {
                if let v = ysonValueToModelValue(yv, c.property.type) {
                    self.setValue(v, forKey: c.name)
                }
            }
        }
    }

    func toYson() -> YsonObject {
        let yo = YsonObject()
        let map = self.toRowData
        for (k, v) in map {
            switch v {
            case is SQLNull:
                yo.putNull(k)
            case let sn as SQLInt:
                let n = sn.toSQLInt
                if Self._table[k].property.type == Bool.self {
                    yo.put(k, n == 0 ? false : true)
                } else {
                    yo.put(k, n)
                }
            case let sr as SQLReal:
                yo.put(k, sr.toSQLReal)
            case let st as SQLText:
                yo.put(k, st.toSQLText)
            case let sb as SQLBlob:
                yo.put(k, sb.toSQLBlob)
            default:
                break
            }
        }

        return yo
    }
}


public extension Cursor {

    func firstModel<T>() -> T? where T: Model {
        let map = self.firstMap()
        if map.notEmpty {
            let model = T.self.init()
            model.fromRowData(map)
            return model
        }
        return nil
    }

    func allModel<T>() -> [T] where T: Model {
        var ls = [T]()
        let rows = self.allMap()
        for map in rows {
            let model = T.self.init()
            model.fromRowData(map)
            ls += model
        }
        return ls
    }
}
