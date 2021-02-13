//
// Created by entaoyang on 2019-01-10.
// Copyright (c) 2019 yet.net. All rights reserved.
//

import Foundation


public class ProtoResult {
	public let httpResult: HttpResp
	public var CodeOKValue = ProtoResult.CODE_OK
	public var CodeName = ProtoResult.CODE
	public var DataName = ProtoResult.DATA
	public var MsgName = ProtoResult.MSG

	public init(_ r: HttpResp) {
		httpResult = r
	}

	public lazy var yo: YsonObject = self.httpResult.ysonObject ?? YsonObject()

}

public extension ProtoResult {

	var code: Int {
		if httpResult.OK {
			return yo.int(CodeName) ?? -1
		} else {
			return httpResult.statusCode
		}
	}
	var OK: Bool {
		httpResult.OK && code == CodeOKValue
	}
	var msg: String {
		if httpResult.OK {
			return yo.str(MsgName) ?? ""
		} else {
			return httpResult.message ?? "未知错误"
		}
	}

	var dataObject: YsonObject? {
		yo.obj(DataName)
	}
	var dataArray: YsonArray? {
		yo.array(DataName)
	}
	var dataInt: Int? {
		yo.int(DataName)
	}
	var dataDouble: Double? {
		yo.double(DataName)
	}
	var dataString: String? {
		yo.str(DataName)
	}

	func dataListObject() -> [YsonObject] {
		if OK {
			if let ar = self.dataArray {
				return ar.arrayObject
			}
		}
		return []
	}

	func dataModel<V: Decodable>() -> V? {
		if let d = self.dataObject {
			return d.toModel()
		}
		return nil
	}

	func dataListModel<V: Decodable>() -> [V] {
		var ls = [V]()
		if OK {
			if let ar = self.dataArray {
				for n in ar {
					if let ob = n as? YsonObject {
						if let m: V = ob.toModel() {
							ls.append(m)
						}
					}
				}
			}
		}
		return ls
	}

	static var CODE_OK = 0
	static var CODE = "code"
	static var DATA = "data"
	static var MSG = "msg"

}