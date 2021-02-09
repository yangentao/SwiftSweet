//
// Created by entaoyang@163.com on 2017/10/26.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation
import SQLite3

public class SQLError: Error, CustomStringConvertible {
	public var msg: String

	public init(_ msg: String) {
		self.msg = msg
		logd("SQLError: ", msg)
	}

	public convenience init(_ code: Int32) {
		let s = String(cString: sqlite3_errstr(code))
		self.init(s)
	}

	public var description: String {
		return msg
	}
}