//
// Created by entaoyang on 2019-03-01.
// Copyright (c) 2019 yet.net. All rights reserved.
//

import Foundation

//parser

fileprivate let CR: Character = "\r"
fileprivate let LF: Character = "\n"
fileprivate let SP: Character = " "
fileprivate let TAB: Character = "\t"
fileprivate let WHITE: [Character] = [CR, LF, SP, TAB]
fileprivate let NUM_START: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-"]
fileprivate let NUMS: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "e", "E", "+", "-"]

fileprivate let ESCAP: [Character] = ["\"", "\\", "/", "b", "f", "n", "r", "t", "u"]

enum YsonErr: String, Swift.Error {
	case parseError, unknownChar
}

func escapeJson(_ s: String) -> String {
	var n = 0
	for c in s {
		if c == "\\" || c == "\"" {
			n += 1
		}
	}
	if n == 0 {
		return s
	}
	var text = String()
	text.reserveCapacity(s.count + n)
	for c in s {
		if c == "\\" || c == "\"" {
			text.append("\\")
			text.append(c)
		} else {
			text.append(c)
		}
	}
	return text

}

fileprivate extension Character {

	var isWhite: Bool {
		WHITE.contains(self)
	}
}

class YParser {
	fileprivate let data: [Character]
	fileprivate let text: String

	fileprivate var current: Int = 0

	fileprivate init(_ text: String) {
		self.text = text
		var ca = Array<Character>()
		for c in text {
			ca.append(c)
		}
		data = ca

	}

	static func parseValue(_ json: String) -> YsonValue? {
		let p = YParser(json)
		if let v = try? p.parse(), p.shouldEnd() {
			return v
		}
		return nil
	}

	static func parseArray(_ json: String) -> YsonArray? {
		let v = self.parseValue(json)
		if let a = v as? YsonArray {
			return a
		}
		return nil
	}

	static func parseObject(_ json: String) -> YsonObject? {
		let v = self.parseValue(json)
		if let a = v as? YsonObject {
			return a
		}
		return nil
	}

	fileprivate func parse() throws -> YsonValue {
		skipWhite()
		if end {
			throw YsonErr.parseError
		}
		let ch = currentChar
		if ch == "{" {
			return try parseObject()
		}
		if ch == "[" {
			return try parseArray()
		}
		if ch == "\"" {
			return try parseString()
		}
		if ch == "t" {
			return try parseTrue()
		}
		if ch == "f" {
			return try parseFalse()
		}
		if ch == "n" {
			return try parseNull()
		}
		if NUM_START.contains(ch) {
			return try parseNumber()
		}

		throw YsonErr.parseError
	}

	fileprivate func parseArray() throws -> YsonArray {
		try tokenc("[")

		let ya = YsonArray()
		while !end {
			skipWhite()
			if currentChar == "]" {
				break
			}
			if currentChar == "," {
				next()
				continue
			}
			let yv = try parse()
			ya.data.append(yv)
		}
		try tokenc("]")
		return ya
	}

	fileprivate func parseObject() throws -> YsonObject {
		try tokenc("{")

		let yo = YsonObject()
		while !end {
			skipWhite()
			if currentChar == "}" {
				break
			}
			if currentChar == "," {
				next()
				continue
			}
			let key = try parseString()
			try tokenc(":")
			let yv = try parse()
			yo.data[key.data] = yv
		}
		try tokenc("}")
		return yo
	}

	fileprivate func parseString() throws -> YsonString {
		try tokenc("\"")
		var text = ""
		var escing = false
		while !end {
			let ch = currentChar
			if !escing {
				if ch == "\"" {
					break
				}
				next()
				if ch == "\\" {
					escing = true
					continue
				}
				text.append(ch)
			} else {
				escing = false
				next()
				//["\"", "\\", "/", "b", "f", "n", "r", "t", "u"]
				switch ch {
				case "\"", "\\", "/":
					text.append(ch)
				case "n":
					text.append("\n")
				case "r":
					text.append("\r")
				case "t":
					text.append("\t")
				case "u":
					if current + 4 < data.count {
						var us = ""
						us.append(data[current + 0])
						us.append(data[current + 1])
						us.append(data[current + 2])
						us.append(data[current + 3])
						current += 4
						if let hex = Int(us, radix: 16) {
							if let us = UnicodeScalar(hex) {
								text.append(Character(us))
							} else {
								throw YsonErr.parseError
							}
						} else {
							throw YsonErr.parseError
						}
					} else {
						throw YsonErr.parseError
					}
					break
				default:
					text.append(ch)
				}
			}

		}
		if escing {
			throw YsonErr.parseError
		}
		try tokenc("\"")
		return YsonString(text)
	}

	fileprivate func parseNumber() throws -> YsonValue {
		skipWhite()
		var text = ""
		while !end {
			let c = currentChar
			if !NUMS.contains(c) {
				break
			}
			text.append(c)
			next()
		}
		if text.isEmpty {
			throw YsonErr.parseError
		}
		guard let d = Double(text) else {
			throw YsonErr.parseError
		}
		let v = YsonNum(d)
		v.hasDot = text.contains(".")
		return v

	}

	fileprivate func parseTrue() throws -> YsonBool {
		try tokens("true")
		return YsonBool(true)
	}

	fileprivate func parseFalse() throws -> YsonBool {
		try tokens("false")
		return YsonBool(false)
	}

	fileprivate func parseNull() throws -> YsonNull {
		try tokens("null")
		return YsonNull.inst
	}

	fileprivate var end: Bool {
		current >= data.count
	}

	fileprivate func shouldEnd() -> Bool {
		self.skipWhite()
		return self.end
	}

	fileprivate func skipWhite() {
		while !end {
			if currentChar.isWhite {
				next()
			} else {
				return
			}
		}
	}

	fileprivate var currentChar: Character {
		data[current]
	}

	fileprivate func next() {
		current += 1
	}

	fileprivate func isChar(_ c: Character) -> Bool {
		currentChar == c
	}

	fileprivate func tokenc(_ c: Character) throws {
		skipWhite()
		if currentChar != c {
			throw YsonErr.parseError
		}
		next()
		skipWhite()
	}

	fileprivate func tokens(_ cs: String) throws {
		skipWhite()
		for c in cs {
			if currentChar != c {
				throw YsonErr.parseError
			}
			next()
		}
		skipWhite()
	}

}