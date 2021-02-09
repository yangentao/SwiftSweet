//
// Created by entaoyang@163.com on 2017/10/10.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

public extension Date {

	var formated: String {
		self.format(fmt: .yyyy_MM_dd)
	}
	var formatedDateTime: String {
		self.format(fmt: .yyyy_MM_dd__HH_mm_ss)
	}
	var formatedDateTimeMill: String {
		self.format(fmt: .yyyy_MM_dd__HH_mm_ss_SSS)
	}

	var formatedTime: String {
		self.format(fmt: .HH_mm_ss)
	}

	static var tempFileName: String {
		let s = Date.format(Date(), "yyyyMMdd_HHmmss_SSS")
		if s != preTempFileName {
			preTempFileName = s
			return s
		} else {
			let a = Int(ProcessInfo.processInfo.systemUptime * 1000000000)
			return s + "_\(a)"
		}
	}

	static var formatDateTimeMill: String {
		Date.format(Date(), "yyyy-MM-dd HH:mm:ss.SSS")
	}
	static var formatDateTime: String {
		Date.format(Date(), "yyyy-MM-dd HH:mm:ss")
	}
	static var formatDate: String {
		Date.format(Date(), "yyyy-MM-dd")
	}

	static func format(_ date: Date, _ format: String) -> String {
		let f = DateFormatter()
		f.dateFormat = format
		return f.string(from: date)
	}

	static func byDate(year: Int, month: Int, day: Int) -> Date {
		let c = Calendar.current
		var b = DateComponents()
		b.year = year
		b.month = month
		b.day = day
		return c.date(from: b)!
	}
}

private var preTempFileName = ""

public struct DateFormats: Hashable, Equatable, RawRepresentable {
	public var rawValue: String

	public init(rawValue: String) {
		self.rawValue = rawValue
	}

	public init(_ s: String) {
		self.rawValue = s
	}

	public static let HH_mm = DateFormats(rawValue: "HH:mm")
	public static let HH_mm_ss = DateFormats(rawValue: "HH:mm:ss")
	public static let HH_mm_ss_SSS = DateFormats(rawValue: "HH:mm:ss.SSS")
	public static let yyyy_MM_dd = DateFormats(rawValue: "yyyy-MM-dd")
	public static let yyyy_MM_dd__HH_mm_ss = DateFormats(rawValue: "yyyy-MM-dd HH:mm:ss")
	public static let yyyy_MM_dd__HH_mm_ss_SSS = DateFormats(rawValue: "yyyy-MM-dd HH:mm:ss.SSS")
	public static let UTC = DateFormats(rawValue: "yyyy-MM-dd'T'HH:mm:ssZ")
	public static let GMT = DateFormats(rawValue: "ccc, dd MMM yyyy HH:mm:ss 'GMT'")
}

public extension Date {

	func format(fmt: String) -> String {
		let f = DateFormatter()
		f.dateFormat = fmt
		return f.string(from: self)
	}

	func format(fmt: DateFormats) -> String {
		self.format(fmt: fmt.rawValue)
	}

	static func parse(fmt: String, value: String) -> Date? {
		let f = DateFormatter()
		f.dateFormat = fmt
		return f.date(from: value)
	}

	static func parse(fmt: DateFormats, value: String) -> Date? {
		Self.parse(fmt: fmt.rawValue, value: value)
	}

	static func parseUTC(_ s: String) -> Date? {
		Self.parse(fmt: .UTC, value: s)
	}
}

extension TimeInterval {
	var toDate1970: Date {
		Date(timeIntervalSince1970: self)
	}
}