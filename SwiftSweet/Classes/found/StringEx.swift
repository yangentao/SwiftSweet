//
// Created by entaoyang@163.com on 2019-08-09.
// Copyright (c) 2019 entao.dev. All rights reserved.
//

import Foundation


public protocol ToString: CustomStringConvertible {
	var toString: String { get }
}

public extension ToString {
	var description: String {
		self.toString
	}
}

fileprivate let Chars09: Array<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

public extension String.Encoding {

	static func fromName(_ name: String) -> String.Encoding? {
		let cfEncode = CFStringConvertIANACharSetNameToEncoding((name as NSString) as CFString)
		if cfEncode != kCFStringEncodingInvalidId {
			let raw = CFStringConvertEncodingToNSStringEncoding(cfEncode)
			return String.Encoding(rawValue: raw)
		}
		return nil
	}
}

public extension String {
	var formatedPhone: String {
		var s = ""
		for ch in self {
			if (ch >= "0" && ch <= "9") || ch == "+" {
				s.append(ch)
			}
		}
		return s
	}
	var cstrUtf8: [CChar] {
		self.cString(using: .utf8) ?? []
	}

	func appendPath(_ s: String) -> String {
		if self.last == "/" {
			return self + s
		}
		return self + "/" + s
	}

	var lastPath: String {
		let ls = self.split(separator: "/").filter {
			!$0.isEmpty
		}
		if ls.isEmpty {
			return ""
		}
		return String(ls.last!)
	}

	//  /home/wang/  -> /home -> /
	var parentPath: String {
		if self == "/" {
			return ""
		}
		if self.last == "/" {
			let s = self[self.startIndex..<self.index(before: self.endIndex)]
			return String(s).parentPath
		}
		if let n = self.lastIndex(of: "/") {
			if n == self.startIndex {
				return "/"
			}
			return String(self[self.startIndex..<n])
		} else {
			return ""
		}
	}

	//trim(",;"
	func trim(_ cs: String) -> String {
		self.trimmingCharacters(in: CharacterSet(charactersIn: cs))
	}

	func endWith(_ s: String) -> Bool {
		self.hasSuffix(s)
	}

	func startWith(_ s: String) -> Bool {
		self.hasPrefix(s)
	}

	func match(_ reg: String) -> Bool {
		let p = NSPredicate(format: "SELF MATCHES %@", [reg])
		return p.evaluate(with: self)
	}

	var toInt: Int? {
		Int(self)
	}
	var toDouble: Double? {
		Double(self)
	}
	var toBool: Bool? {
		Bool(self)
	}

	var trimed: String {
		self.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	var urlEncoded: String {
		self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
	}

	var notEmpty: Bool {
		!self.isEmpty
	}

	var empty: Bool {
		self.isEmpty
	}

	var dataUtf8: Data {
		self.data(using: String.Encoding.utf8, allowLossyConversion: false)!
	}
	var dataUnicode: Data {
		self.data(using: String.Encoding.unicode, allowLossyConversion: false)!
	}

	func charAt(n: Int) -> Character? {
		if n >= 0 && n < self.count {
			return self[self.idx(n)]
		}
		return nil
	}

	func at(_ n: Int) -> Character {
		self[self.idx(n)]
	}

	func substr(_ from: Int) -> String {
		if from < self.count {
			return String(self[idx(from)...])
		}
		return ""
	}

	//[from, to)
	func substr(_ from: Int, _ to: Int) -> String {
		let c = self.count
		if from >= c {
			return ""
		}
		if to >= c {
			return String(self[self.idx(from)..<self.idx(c)])
		}
		return String(self[self.idx(from)..<self.idx(to)])
	}

	func header(_ size: Int) -> String {
		substr(0, size)
	}

	func tail(_ size: Int) -> String {
		var from = self.count - size
		if from < 0 {
			from = 0
		}
		return self.substr(from)
	}

	//没有返回-1
	func lastIndexOf(_ c: Character) -> Int {
		var n = self.count - 1
		while n >= 0 {
			if c == at(n) {
				return n
			}
			n -= 1
		}
		return -1
	}

	func indexOf(_ c: Character) -> Int? {
		if let n = self.firstIndex(of: c) {
			return self.distance(from: self.startIndex, to: n)
		}
		return nil
	}

	mutating func removeAt(_ n: Int) -> Character? {
		if n >= 0 && n < self.count {
			return self.remove(at: self.idx(n))
		}
		return nil
	}

	mutating func insertAt(_ n: Int, _ c: Character) {
		if (n == self.count) {
			self.append(c)
			return
		}
		self.insert(c, at: self.idx(n))
	}

	func replaced(_ map: [Character: String]) -> String {
		var buf: String = ""
		for ch in self {
			if let s = map[ch] {
				buf.append(s)
			} else {
				buf.append(ch)
			}
		}
		return buf
	}

	func replaced(_ cs: [Character], to str: String) -> String {
		var buf: String = ""
		for ch in self {
			if cs.contains(ch) {
				buf.append(str)
			} else {
				buf.append(ch)
			}
		}
		return buf
	}

	var escapedSQL: String {
		self.replaced(["'": "''"])
	}

	var local: String {
		get {
			NSLocalizedString(self, comment: self)
		}
	}

	subscript(value: PartialRangeUpTo<Int>) -> Substring {
		get {
			self[..<self.idx(value.upperBound)]
		}
	}

	subscript(value: PartialRangeThrough<Int>) -> Substring {
		get {
			self[...self.idx(value.upperBound)]
		}
	}

	subscript(value: PartialRangeFrom<Int>) -> Substring {
		get {
			self[self.idx(value.lowerBound)...]
		}
	}
	subscript(value: ClosedRange<Int>) -> Substring {
		get {
			self[self.idx(value.lowerBound)...self.idx(value.upperBound)]
		}
	}
	subscript(value: Range<Int>) -> Substring {
		get {
			self[self.idx(value.lowerBound)..<self.idx(value.upperBound)]
		}
	}

	func idx(_ n: Int) -> String.Index {
		self.index(self.startIndex, offsetBy: n)
	}

}

public extension Substring {

	func toString() -> String {
		String(self)
	}
}

private let lowerCaseMap: Dictionary<Character, Character> = ["A": "a", "B": "b",
                                                              "C": "c", "D": "d",
                                                              "E": "e", "F": "f",
                                                              "G": "g", "H": "h",
                                                              "I": "i", "J": "j",
                                                              "K": "k", "L": "l",
                                                              "M": "m", "N": "n",
                                                              "O": "o", "P": "p",
                                                              "Q": "q", "R": "r",
                                                              "S": "s", "T": "t",
                                                              "U": "u", "V": "v",
                                                              "W": "w", "X": "x",
                                                              "Y": "y", "Z": "z"]

private let upperCaseMap: Dictionary<Character, Character> = ["a": "A", "b": "B",
                                                              "c": "C", "d": "D",
                                                              "e": "E", "f": "F",
                                                              "g": "G", "h": "H",
                                                              "i": "I", "j": "J",
                                                              "k": "K", "l": "L",
                                                              "m": "M", "n": "N",
                                                              "o": "O", "p": "P",
                                                              "q": "Q", "r": "R",
                                                              "s": "S", "t": "T",
                                                              "u": "U", "v": "V",
                                                              "w": "W", "x": "X",
                                                              "y": "Y", "z": "Z"]

public extension Character {
	var isNumber: Bool {
		(self >= "0" && self <= "9")
	}
	var isAlpha: Bool {
		(self >= "a" && self <= "z") || (self >= "A" && self <= "Z")
	}
	var lowerCase: Character {
		lowerCaseMap[self] ?? self
	}
	var upperCase: Character {
		upperCaseMap[self] ?? self
	}
}



