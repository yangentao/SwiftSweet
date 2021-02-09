//
// Created by entaoyang@163.com on 2019-08-09.
// Copyright (c) 2019 entao.dev. All rights reserved.
//

import Foundation

public extension Data {

	var bytes: [UInt8] {
		[UInt8](self)
	}

	mutating func appendUtf8(_ s: String) {
		self.append(s.dataUtf8)
	}

	mutating func appendNewLine() {
		self.append("\r\n".dataUtf8)
	}

	var stringUtf8: String? {
		String(data: self, encoding: .utf8)
	}

	var base64: String {
		get {
			self.base64EncodedString(options: Base64EncodingOptions.endLineWithCarriageReturn)
		}

	}
}
