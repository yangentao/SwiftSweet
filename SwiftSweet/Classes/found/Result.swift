//
// Created by entaoyang@163.com on 2019-08-09.
// Copyright (c) 2019 entao.dev. All rights reserved.
//

import Foundation



public class Result {
	var code: Int = 0
	var msg: String = ""

	init(code: Int, msg: String) {
		self.code = code
		self.msg = msg
	}

	convenience init() {
		self.init(code: 0, msg: "")
	}

	var OK: Bool {
		return code == 0
	}

	static var success: Result {
		return Result()
	}

	static func error(_ code: Int, _ msg: String) -> Result {
		return Result(code: code, msg: msg)
	}

	static func error(_ msg: String) -> Result {
		return Result(code: -1, msg: msg)
	}
}