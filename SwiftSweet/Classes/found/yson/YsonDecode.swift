//
// Created by entaoyang@163.com on 2017/10/25.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

class YsonDecoder {
	public enum DateDecodingStrategy {
		/// Defer to `Date` for decoding. This is the default strategy.
		case deferredToDate
		case secondsSince1970
		case millisecondsSince1970
		/// Decode the `Date` as a string parsed by the given formatter.
		case formatted(DateFormatter)
		/// Decode the `Date` as a custom value decoded by the given closure.
		case custom((_ decoder: Decoder) throws -> Date)
	}

	public enum NonConformingFloatDecodingStrategy {
		case `throw`
		case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
	}

	open var dateDecodingStrategy: DateDecodingStrategy = .millisecondsSince1970
	open var nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw
	open var userInfo: [CodingUserInfoKey: Any] = [:]

	fileprivate struct _Options {
		let dateDecodingStrategy: DateDecodingStrategy
		let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
		let userInfo: [CodingUserInfoKey: Any]
	}

	fileprivate var options: _Options {
		_Options(dateDecodingStrategy: dateDecodingStrategy, nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy, userInfo: userInfo)
	}

	public init() {
	}

	func decode<T: Decodable>(_ type: T.Type, from jsonValue: YsonValue) throws -> T {
		let decoder = _YsonDecoder(referencing: jsonValue, options: self.options)
		guard let value = try decoder.unbox(jsonValue, as: T.self) else {
			throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
		}
		return value
	}
}

fileprivate class _YsonDecoder: Decoder {
	fileprivate var storage: _YsonDecodingStorage = _YsonDecodingStorage()
	fileprivate let options: YsonDecoder._Options
	fileprivate(set) public var codingPath: [CodingKey]
	public var userInfo: [CodingUserInfoKey: Any] {
		self.options.userInfo
	}

	fileprivate init(referencing ysonValue: YsonValue, at codingPath: [CodingKey] = [], options: YsonDecoder._Options) {
		self.codingPath = codingPath
		self.options = options
		self.storage.push(container: ysonValue)
	}

	public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
		guard !(self.storage.top is YsonNull) else {
			throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get keyed decoding container -- found null value instead."))
		}

		guard let topContainer = self.storage.top as? YsonObject else {
			throw DecodingError.typeMismatch(YsonObject.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
		}

		let container = _YsonObjectDecodingContainer<Key>(referencing: self, wrapping: topContainer)
		return KeyedDecodingContainer(container)
	}

	public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
		guard !(self.storage.top is YsonNull) else {
			throw DecodingError.typeMismatch(YsonArray.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
		}

		guard let topContainer = self.storage.top as? YsonArray else {
			throw DecodingError.typeMismatch(YsonArray.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
		}

		return _YsonArrayDecodingContainer(referencing: self, wrapping: topContainer)
	}

	public func singleValueContainer() throws -> SingleValueDecodingContainer {
		self
	}
}

fileprivate struct _YsonDecodingStorage {
	private(set) fileprivate var stack: [YsonValue] = []

	fileprivate init() {
	}

	fileprivate var count: Int {
		self.stack.count
	}

	fileprivate var top: YsonValue {
		precondition(self.stack.count > 0, "Empty container stack.")
		return self.stack.last!
	}

	fileprivate mutating func push(container: YsonValue) {
		self.stack.append(container)
	}

	fileprivate mutating func pop() {
		precondition(self.stack.count > 0, "Empty container stack.")
		self.stack.removeLast()
	}
}

fileprivate struct _YsonObjectDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
	typealias Key = K
	private let decoder: _YsonDecoder
	private let container: YsonObject
	private(set) public var codingPath: [CodingKey]

	fileprivate init(referencing decoder: _YsonDecoder, wrapping container: YsonObject) {
		self.decoder = decoder
		self.container = container
		self.codingPath = decoder.codingPath
	}

	public var allKeys: [Key] {
		self.container.keys.compactMap {
			Key(stringValue: $0)
		}
	}

	public func contains(_ key: Key) -> Bool {
		self.container.has(key.stringValue)
	}

	public func decodeNil(forKey key: Key) throws -> Bool {
		let entry = self.container[key.stringValue]
		return entry is YsonNull
	}

	public func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
		try self.decodeOf(type, forKey: key) ?? false
	}

	public func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
		try self.decodeOf(type, forKey: key) ?? 0
	}

	public func decode(_ type: String.Type, forKey key: Key) throws -> String {
		try self.decodeOf(type, forKey: key) ?? ""
	}

	private func decodeOf<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
		let entry = self.container[key.stringValue]
		if entry is YsonNull {
			return nil
		}

		self.decoder.codingPath.append(key)
		defer {
			self.decoder.codingPath.removeLast()
		}

		guard let value = try self.decoder.unbox(entry, as: type) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}

		return value
	}

	public func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
		if let v = try self.decodeOf(type, forKey: key) {
			return v
		}
		throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
	}

	public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
		self.decoder.codingPath.append(key)
		defer {
			self.decoder.codingPath.removeLast()
		}

		let value = self.container[key.stringValue]
		if value is YsonNull {
			throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \"\(key.stringValue)\""))

		}

		guard let dictionary = value as? YsonObject else {
			throw DecodingError.typeMismatch(YsonObject.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
		}

		let container = _YsonObjectDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
		return KeyedDecodingContainer(container)
	}

	public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
		self.decoder.codingPath.append(key)
		defer {
			self.decoder.codingPath.removeLast()
		}

		let value = self.container[key.stringValue]
		if value is YsonNull {
			throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \"\(key.stringValue)\""))
		}

		guard let array = value as? YsonArray else {
			throw DecodingError.typeMismatch(YsonArray.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
		}

		return _YsonArrayDecodingContainer(referencing: self.decoder, wrapping: array)
	}

	private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
		self.decoder.codingPath.append(key)
		defer {
			self.decoder.codingPath.removeLast()
		}

		let value: YsonValue = self.container[key.stringValue]
		return _YsonDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
	}

	public func superDecoder() throws -> Decoder {
		try _superDecoder(forKey: _YsonKey.super)
	}

	public func superDecoder(forKey key: Key) throws -> Decoder {
		try _superDecoder(forKey: key)
	}
}

fileprivate struct _YsonArrayDecodingContainer: UnkeyedDecodingContainer {
	private let decoder: _YsonDecoder
	private let container: YsonArray
	private(set) public var codingPath: [CodingKey]
	private(set) public var currentIndex: Int

	fileprivate init(referencing decoder: _YsonDecoder, wrapping container: YsonArray) {
		self.decoder = decoder
		self.container = container
		self.codingPath = decoder.codingPath
		self.currentIndex = 0
	}

	var count: Int? {
		self.container.count
	}

	var isAtEnd: Bool {
		self.currentIndex >= self.count!
	}

	mutating func decodeNil() throws -> Bool {
		guard !self.isAtEnd else {
			throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: self.decoder.codingPath + [_YsonKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
		}

		if self.container[self.currentIndex] is YsonNull {
			self.currentIndex += 1
			return true
		} else {
			return false
		}
	}

	mutating func decode(_ type: Bool.Type) throws -> Bool {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: Int.Type) throws -> Int {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: Int8.Type) throws -> Int8 {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: Int16.Type) throws -> Int16 {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: Int32.Type) throws -> Int32 {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: Int64.Type) throws -> Int64 {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: UInt.Type) throws -> UInt {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: Float.Type) throws -> Float {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: Double.Type) throws -> Double {
		try self.decodeOf(type)
	}

	mutating func decode(_ type: String.Type) throws -> String {
		try self.decodeOf(type)
	}

	mutating func decodeOf<T: Decodable>(_ type: T.Type) throws -> T {
		guard !self.isAtEnd else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_YsonKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
		}

		self.decoder.codingPath.append(_YsonKey(index: self.currentIndex))
		defer {
			self.decoder.codingPath.removeLast()
		}

		guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: type) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_YsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
		}

		self.currentIndex += 1
		return decoded
	}

	mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
		guard !self.isAtEnd else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_YsonKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
		}

		self.decoder.codingPath.append(_YsonKey(index: self.currentIndex))
		defer {
			self.decoder.codingPath.removeLast()
		}

		guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: T.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_YsonKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
		}

		self.currentIndex += 1
		return decoded
	}

	mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
		self.decoder.codingPath.append(_YsonKey(index: self.currentIndex))
		defer {
			self.decoder.codingPath.removeLast()
		}

		guard !self.isAtEnd else {
			throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
		}

		let value = self.container[self.currentIndex]
		guard !(value is YsonNull) else {
			throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get keyed decoding container -- found null value instead."))
		}

		guard let dictionary = value as? YsonObject else {
			throw DecodingError.typeMismatch(YsonObject.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
		}

		self.currentIndex += 1
		let container = _YsonObjectDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
		return KeyedDecodingContainer(container)
	}

	mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
		self.decoder.codingPath.append(_YsonKey(index: self.currentIndex))
		defer {
			self.decoder.codingPath.removeLast()
		}

		guard !self.isAtEnd else {
			throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
		}

		let value = self.container[self.currentIndex]
		guard !(value is YsonNull) else {
			throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get keyed decoding container -- found null value instead."))
		}

		guard let array = value as? YsonArray else {
			throw DecodingError.typeMismatch(YsonArray.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
		}

		self.currentIndex += 1
		return _YsonArrayDecodingContainer(referencing: self.decoder, wrapping: array)
	}

	mutating func superDecoder() throws -> Decoder {
		self.decoder.codingPath.append(_YsonKey(index: self.currentIndex))
		defer {
			self.decoder.codingPath.removeLast()
		}

		guard !self.isAtEnd else {
			throw DecodingError.valueNotFound(Decoder.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."))
		}

		let value = self.container[self.currentIndex]
		self.currentIndex += 1
		return _YsonDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
	}
}

extension _YsonDecoder: SingleValueDecodingContainer {

	private func expectNonNull<T>(_ type: T.Type) throws {
		guard !self.decodeNil() else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) but found null value instead."))
		}
	}

	func decodeNil() -> Bool {
		self.storage.top is YsonNull
	}

	func decode(_ type: Bool.Type) throws -> Bool {
		try expectNonNull(Bool.self)
		return try self.unbox(self.storage.top, as: Bool.self)!
	}

	func decode(_ type: Int.Type) throws -> Int {
		try expectNonNull(Int.self)
		return try self.unbox(self.storage.top, as: Int.self)!
	}

	func decode(_ type: Int8.Type) throws -> Int8 {
		try expectNonNull(Int8.self)
		return try self.unbox(self.storage.top, as: Int8.self)!
	}

	func decode(_ type: Int16.Type) throws -> Int16 {
		try expectNonNull(Int16.self)
		return try self.unbox(self.storage.top, as: Int16.self)!
	}

	func decode(_ type: Int32.Type) throws -> Int32 {
		try expectNonNull(Int32.self)
		return try self.unbox(self.storage.top, as: Int32.self)!
	}

	func decode(_ type: Int64.Type) throws -> Int64 {
		try expectNonNull(Int64.self)
		return try self.unbox(self.storage.top, as: Int64.self)!
	}

	func decode(_ type: UInt.Type) throws -> UInt {
		try expectNonNull(UInt.self)
		return try self.unbox(self.storage.top, as: UInt.self)!
	}

	func decode(_ type: UInt8.Type) throws -> UInt8 {
		try expectNonNull(UInt8.self)
		return try self.unbox(self.storage.top, as: UInt8.self)!
	}

	func decode(_ type: UInt16.Type) throws -> UInt16 {
		try expectNonNull(UInt16.self)
		return try self.unbox(self.storage.top, as: UInt16.self)!
	}

	func decode(_ type: UInt32.Type) throws -> UInt32 {
		try expectNonNull(UInt32.self)
		return try self.unbox(self.storage.top, as: UInt32.self)!
	}

	func decode(_ type: UInt64.Type) throws -> UInt64 {
		try expectNonNull(UInt64.self)
		return try self.unbox(self.storage.top, as: UInt64.self)!
	}

	func decode(_ type: Float.Type) throws -> Float {
		try expectNonNull(Float.self)
		return try self.unbox(self.storage.top, as: Float.self)!
	}

	func decode(_ type: Double.Type) throws -> Double {
		try expectNonNull(Double.self)
		return try self.unbox(self.storage.top, as: Double.self)!
	}

	func decode(_ type: String.Type) throws -> String {
		try expectNonNull(String.self)
		return try self.unbox(self.storage.top, as: String.self)!
	}

	func decode<T: Decodable>(_ type: T.Type) throws -> T {
		try expectNonNull(T.self)
		return try self.unbox(self.storage.top, as: T.self)!
	}
}

fileprivate extension _YsonDecoder {
	func unbox(_ value: YsonValue, as type: Bool.Type) throws -> Bool? {
		switch value {
		case is YsonNull:
			return nil
		case let b as YsonBool:
			return b.data
		case let s as YsonString:
			if s.data == "true" {
				return true
			} else if s.data == "false" {
				return false
			}
		case let n as YsonNum:
			if n.hasDot && n.data.intValue == 1 {
				return true
			}
			return false
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonBool.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: Int.Type) throws -> Int? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.intValue
		case let b as YsonBool:
			return b.data ? 1 : 0
		default:
			break
		}

		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: Int8.Type) throws -> Int8? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.int8Value
		case let b as YsonBool:
			return b.data ? 1 : 0
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: Int16.Type) throws -> Int16? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.int16Value
		case let b as YsonBool:
			return b.data ? 1 : 0
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: Int32.Type) throws -> Int32? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.int32Value
		case let b as YsonBool:
			return b.data ? 1 : 0
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: Int64.Type) throws -> Int64? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.int64Value
		case let b as YsonBool:
			return b.data ? 1 : 0
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: UInt.Type) throws -> UInt? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.uintValue
		case let b as YsonBool:
			return b.data ? 1 : 0
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: UInt8.Type) throws -> UInt8? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.uint8Value
		case let b as YsonBool:
			return b.data ? 1 : 0
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: UInt16.Type) throws -> UInt16? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.uint16Value
		case let b as YsonBool:
			return b.data ? 1 : 0
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: UInt32.Type) throws -> UInt32? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.uint32Value
		case let b as YsonBool:
			return b.data ? 1 : 0
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: UInt64.Type) throws -> UInt64? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.uint64Value
		case let b as YsonBool:
			return b.data ? 1 : 0
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: Float.Type) throws -> Float? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.floatValue
		default:
			break
		}

		if let ys = value as? YsonString, case .convertFromString(let posInfString, let negInfString, let nanString) = self.options.nonConformingFloatDecodingStrategy {
			let string = ys.data
			if string == posInfString {
				return Float.infinity
			} else if string == negInfString {
				return -Float.infinity
			} else if string == nanString {
				return Float.nan
			}
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: Double.Type) throws -> Double? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.doubleValue
		default:
			break
		}

		if let ys = value as? YsonString, case .convertFromString(let posInfString, let negInfString, let nanString) = self.options.nonConformingFloatDecodingStrategy {
			let string = ys.data
			if string == posInfString {
				return Double.infinity
			} else if string == negInfString {
				return -Double.infinity
			} else if string == nanString {
				return Double.nan
			}
		}
		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: String.Type) throws -> String? {
		switch value {
		case is YsonNull:
			return nil
		case let s as YsonString:
			return s.data
		default:
			break
		}
		throw DecodingError.typeMismatch(YsonString.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
	}

	func unbox(_ value: YsonValue, as type: Date.Type) throws -> Date? {
		if value is YsonNull {
			return nil
		}

		switch self.options.dateDecodingStrategy {
		case .deferredToDate:
			self.storage.push(container: value)
			let date = try Date(from: self)
			self.storage.pop()
			return date

		case .secondsSince1970:
			let double = try self.unbox(value, as: Double.self)!
			return Date(timeIntervalSince1970: double)

		case .millisecondsSince1970:
			let double = try self.unbox(value, as: Double.self)!
			return Date(timeIntervalSince1970: double / 1000.0)

		case .formatted(let formatter):
			let string = try self.unbox(value, as: String.self)!
			guard let date = formatter.date(from: string) else {
				throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Date string does not match format expected by formatter."))
			}

			return date

		case .custom(let closure):
			self.storage.push(container: value)
			let date = try closure(self)
			self.storage.pop()
			return date
		}
	}

	func unbox(_ value: YsonValue, as type: Data.Type) throws -> Data? {
		if value is YsonNull {
			return nil
		}
		if let yb = value as? YsonBlob {
			return yb.data
		}

		guard let ysonString = value as? YsonString else {
			throw DecodingError.typeMismatch(YsonString.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))
		}

		guard let data = Data(base64Encoded: ysonString.data) else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Data is not valid Base64."))
		}

		return data

	}

	func unbox(_ value: YsonValue, as type: Decimal.Type) throws -> Decimal? {
		switch value {
		case is YsonNull:
			return nil
		case let f as YsonNum:
			return f.data.decimalValue
		default:
			break
		}

		throw DecodingError.typeMismatch(YsonNum.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: ""))

	}

	func unbox<T: Decodable>(_ value: YsonValue, as type: T.Type) throws -> T? {

		if T.self == Date.self || T.self == NSDate.self {
			guard let date = try self.unbox(value, as: Date.self) else {
				return nil
			}
			return (date as! T)
		}
		if T.self == Data.self || T.self == NSData.self {
			guard let data = try self.unbox(value, as: Data.self) else {
				return nil
			}
			return (data as! T)
		}
		if T.self == URL.self || T.self == NSURL.self {
			guard let urlString = try self.unbox(value, as: String.self) else {
				return nil
			}
			guard let url = URL(string: urlString) else {
				throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid URL string."))
			}
			return (url as! T)
		}
		if T.self == Decimal.self || T.self == NSDecimalNumber.self {
			guard let decimal = try self.unbox(value, as: Decimal.self) else {
				return nil
			}
			return (decimal as! T)
		}
		self.storage.push(container: value)
		let decoded: T = try T(from: self)
		self.storage.pop()
		return decoded
	}
}


