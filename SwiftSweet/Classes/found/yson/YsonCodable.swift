//
// Created by entaoyang on 2019-01-24.
// Copyright (c) 2019 yet.net. All rights reserved.
//

import Foundation

public extension Yson {

	static func toYsonObject<T: Encodable>(_ v: T) -> YsonObject? {
		do {
			let v: YsonValue? = try Yson.encode(v)
			return v as? YsonObject
		} catch {
			loge("Yson.toYsonObject Error: \(error)")
			return nil
		}
	}

	static func toYson<T: Encodable>(_ v: T) -> YsonValue? {
		do {
			let v: YsonValue? = try Yson.encode(v)
			return v
		} catch {
			loge("Yson.toYsonObject Error: \(error)")
			return nil
		}
	}

	static func encode<T: Encodable>(_ v: T) throws -> YsonValue? {
		let ye = YsonEncoder()
		return try ye.encode(v)
//		let e = JSONEncoder()
//		let d = try e.encode(v)
//		let s = String(data: d, encoding: .utf8)
//		if let ss = s {
//			return Yson.parse(ss)
//		}
//		return nil
	}

}

public extension Yson {

	static func fromYson<T: Decodable>(_ type: T.Type, _ jsonValue: YsonValue) -> T? {
		do {
			return try self.decode(type, jsonValue)
		} catch {
			loge("Yson.fromYson Error: \(error),  \(jsonValue.yson)")
			return nil
		}
	}

	static func decode<T: Decodable>(_ type: T.Type, _ jsonValue: YsonValue) throws -> T {
		return try YsonDecoder().decode(type, from: jsonValue)
//		let s = jsonValue.yson()
//		let d = JSONDecoder()
//		return try d.decode(type, from: s.dataUtf8)
	}

}

public extension YsonValue {

	func toModel<V: Decodable>() -> V? {
		Yson.fromYson(V.self, self)
	}

}

public extension Encodable {

	var toYsonValue: YsonValue {
		do {
			let y = try Yson.encode(self)
			return y!
		} catch {
			loge("toYson error: \(error)")
			return YsonNull.inst
		}
	}

	var toYsonObject: YsonObject {
		self.toYsonValue as! YsonObject
	}

	func dumpYson() {
		logd(self.toYsonValue.yson)
	}
}