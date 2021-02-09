//
// Created by entaoyang@163.com on 2017/10/25.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

infix operator ?=: ComparisonPrecedence
infix operator ?>: ComparisonPrecedence
infix operator ?<: ComparisonPrecedence
infix operator ?>=: ComparisonPrecedence
infix operator ?<=: ComparisonPrecedence
//LIKE %rhs%
infix operator ?%*%: ComparisonPrecedence
//LIKE %rhs
infix operator ?%*: ComparisonPrecedence
//LIKE rhs%
infix operator ?*%: ComparisonPrecedence
//IN
infix operator ?->: ComparisonPrecedence

public class Where: CustomStringConvertible {
	public var cond: String = ""
	public var args: [SQLValue] = []

	//"name=?",["ZhangSan"]
	public init(_ cond: String, _ args: [SQLValue] = []) {
		self.cond = cond
		self.args = args
	}

	public var description: String {
		return cond + " Args: " + args.description
	}
}

public func ||(lhs: Where?, rhs: Where) -> Where {
	guard let L = lhs else {
		return rhs
	}
	var args = [SQLValue]()
	args += L.args
	args += rhs.args
	return Where("(" + L.cond + ") OR (" + rhs.cond + ")", args)
}

public func &&(lhs: Where?, rhs: Where) -> Where {
	guard let L = lhs else {
		return rhs
	}
	var args = [SQLValue]()
	args += L.args
	args += rhs.args
	return Where("(" + L.cond + ") AND (" + rhs.cond + ")", args)
}

public func ?=(lhs: ColumnName, rhs: SQLValue) -> Where {
	if rhs is YsonNull {
		return Where(lhs.toName + " IS NULL ")
	} else {
		return Where(lhs.toName + " =? ", [rhs])
	}
}

public func ?>(lhs: ColumnName, rhs: SQLValue) -> Where {
	return Where(lhs.toName + " >? ", [rhs])
}

public func ?<(lhs: ColumnName, rhs: SQLValue) -> Where {
	return Where(lhs.toName + " <? ", [rhs])
}

public func ?>=(lhs: ColumnName, rhs: SQLValue) -> Where {
	return Where(lhs.toName + " >=? ", [rhs])
}

public func ?<=(lhs: ColumnName, rhs: SQLValue) -> Where {
	return Where(lhs.toName + " <=? ", [rhs])
}

public func ?%*%(lhs: ColumnName, rhs: String) -> Where {
	if rhs.isEmpty {
		debugFatal("LIKE 参数是空字符串")
	}
	return Where(lhs.toName + " LIKE '%\(rhs.escapedSQL)%'")
}

public func ?%*(lhs: ColumnName, rhs: String) -> Where {
	if rhs.isEmpty {
		debugFatal("LIKE 参数是空字符串")
	}
	return Where(lhs.toName + " LIKE '%\(rhs.escapedSQL)'")
}

public func ?*%(lhs: CodingKey, rhs: String) -> Where {
	if rhs.isEmpty {
		debugFatal("LIKE 参数是空字符串")
	}
	return Where(lhs.stringValue + " LIKE '\(rhs.escapedSQL)%'")
}

public func ?->(lhs: ColumnName, rhs: [SQLValue]) -> Where {
	if rhs.isEmpty {
		debugFatal("IN 参数是空集合")
	}
	let args = rhs.map { v in
		"?"
	}.joined(separator: ",")
	return Where(lhs.toName + " IN (\(args))", rhs)
}