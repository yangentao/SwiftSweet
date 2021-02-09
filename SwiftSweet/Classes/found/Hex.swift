//
// Created by yet on 2018/7/25.
// Copyright (c) 2018 yet.net. All rights reserved.
//

import Foundation

public class Hex {
	private static var AR = "0123456789ABCDEF"

	public static func encodeByte(_ b: UInt8) -> String {
		var ret = ""
		let hi: Int = Int(0x0f & (b >> 4))
		let lo: Int = Int(0x0f & b)
		ret.append(AR.charAt(n: hi)!)
		ret.append(AR.charAt(n: lo)!)
		return ret
	}

	public static func encodeChars(_ bytes: [Int8]) -> String {
		var ret = ""
		bytes.forEach { b in
			let hi: Int = Int(0x0f & (b >> 4))
			let lo: Int = Int(0x0f & b)
			ret.append(AR.charAt(n: hi)!)
			ret.append(AR.charAt(n: lo)!)
		}
		return ret
	}

	public static func encodeBytes(_ bytes: [UInt8]) -> String {
		var ret = ""
		bytes.forEach { b in
			let hi: Int = Int(0x0f & (b >> 4))
			let lo: Int = Int(0x0f & b)
			ret.append(AR.charAt(n: hi)!)
			ret.append(AR.charAt(n: lo)!)
		}
		return ret
	}

	public static func encode(_ s: String) -> String {
		return encodeBytes(s.dataUtf8.bytes)
	}

	public static func decode(_ s: String) -> String {
		let ar = decodeBytes(s)
		return String(bytes: ar, encoding: String.Encoding.utf8)!
	}

	public static func decodeBytes(_ s: String) -> [UInt8] {
		var arr = [UInt8]()
		let us = s.unicodeScalars

		for i in 0..<(us.count / 2) {
			let n1 = us.index(us.startIndex, offsetBy: i * 2)
			let n2 = us.index(us.startIndex, offsetBy: i * 2 + 1)
			let hi: UInt8 = toByte(ch: us[n1])
			let lo: UInt8 = toByte(ch: us[n2])
			let b: UInt8 = (hi << 4 & 0xf0) | (lo & 0x0f)
			arr.append(b)
		}
		return arr
	}

	private static func toByte(ch: Unicode.Scalar) -> UInt8 {
		let chV = ch.value

		if (chV >= 0x30 && chV <= 0x39) {
			return UInt8(chV - 0x30)
		}
		if (chV >= 0x61 && chV <= 0x66) {
			return UInt8(chV - 0x61) + 10
		}
		if (chV >= 0x41 && chV <= 0x46) {
			return UInt8(chV - 0x41) + 10
		}
		return 0
	}
}