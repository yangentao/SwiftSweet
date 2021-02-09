//
// Created by entaoyang@163.com on 2019/9/21.
//

import Foundation

let integerTypes: [Any.Type] = [Bool.self, Int8.self, UInt8.self, Int16.self, UInt16.self, Int32.self, UInt32.self, Int.self, UInt.self, Int64.self, UInt64.self]
let realTypes: [Any.Type] = [Float.self, Double.self]
let textTypes: [Any.Type] = [String.self, NSString.self]
let blobTypes: [Any.Type] = [Data.self, NSData.self]

extension Property {

	var isSQLInteger: Bool {
		return integerTypes.contains(where: { $0 == self.type })
	}
	var isSQLReal: Bool {
		return realTypes.contains(where: { $0 == self.type })
	}
	var isSQLText: Bool {
		return textTypes.contains(where: { $0 == self.type })
	}
	var isSQLBlob: Bool {
		return blobTypes.contains(where: { $0 == self.type })
	}
}