//
// Created by entaoyang@163.com on 2017/10/26.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation
import SQLite3

public extension Cursor {
    //第一列字符串的集合
    func stringSetResult() -> Set<String> {
        defer {
            close()
        }
        var set = Set<String>(minimumCapacity: 128)
        while moveToNext() {
            if let s = str(0) {
                set.insert(s)
            }
        }
        return set
    }

    func intResult() -> Int? {
        let n = longResult()
        if n != nil {
            return Int(n!)
        }
        return nil
    }

    func longResult() -> Int64? {
        defer {
            close()
        }
        if moveToNext() {
            return int(0)
        }
        return nil
    }

    func realResult() -> Double? {
        defer {
            close()
        }
        if moveToNext() {
            return real(0)
        }
        return nil
    }

    func strResult() -> String? {
        defer {
            close()
        }
        if moveToNext() {
            return str(0)
        }
        return nil
    }

    func blobResult() -> Data? {
        defer {
            close()
        }
        if moveToNext() {
            return blob(0)
        }
        return nil
    }

    func existResult() -> Bool {
        defer {
            close()
        }
        if moveToNext() {
            return true
        }
        return false
    }

    func firstRow() -> YsonObject? {
        defer {
            close()
        }
        if moveToNext() {
            return currentRow()
        }
        return nil
    }

    func allRows() -> YsonArray {
        defer {
            close()
        }
        let yar = YsonArray()
        yar.data.reserveCapacity(128)
        while moveToNext() {
            yar += currentRow()
        }
        return yar
    }

    func eachRow(_ block: (YsonObject) -> Void) {
        defer {
            close()
        }
        while moveToNext() {
            let yo = currentRow()
            block(yo)
        }
    }

    private func currentRow() -> YsonObject {
        let yo = YsonObject()
        for i in 0..<columnCount {
            let ctype = columnType(i)
            let name = columnNames[i]
            switch ctype {
            case SQLITE3_TEXT:
                yo.put(name, str(i))
            case SQLITE_INTEGER:
                yo.put(name, int(i))
            case SQLITE_FLOAT:
                yo.put(name, real(i))
            case SQLITE_BLOB:
                yo.put(name, blob(i))
            case SQLITE_NULL:
                yo.putNull(name)
            default:
                break
            }
        }
        return yo
    }

    private func currentMap() -> RowData {
        var map = RowData()
        for i in 0..<columnCount {
            let ctype = columnType(i)
            let name = columnNames[i]
            switch ctype {
            case SQLITE3_TEXT:
                map[name] = str(i)
            case SQLITE_INTEGER:
                map[name] = int(i)
            case SQLITE_FLOAT:
                map[name] = real(i)
            case SQLITE_BLOB:
                map[name] = blob(i)
            case SQLITE_NULL:
                map[name] = SQLNull.inst
            default:
                break
            }
        }
        return map
    }

    func firstMap() -> RowData {
        defer {
            close()
        }
        if self.moveToNext() {
            return self.currentMap()
        }
        return [:]
    }

    func allMap() -> [RowData] {
        defer {
            close()
        }
        var ls = [RowData]()
        for _ in self {
            ls += self.currentMap()
        }
        return ls
    }

    func decodeOne<V: Decodable>() -> V? {
        if let yo = firstRow() {
            return yo.toModel()
        }
        return nil
    }

    func decodeArray<V: Decodable>() -> [V] {
        let yarr: YsonArray = allRows()
        var vs: [V] = []
        vs.reserveCapacity(yarr.count)
        for yv: YsonValue in yarr {
            if let v: V = yv.toModel() {
                vs.append(v)
            }
        }
        return vs
    }
}