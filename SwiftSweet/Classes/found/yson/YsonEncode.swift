//
// Created by entaoyang@163.com on 2017/10/29.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation

class YsonEncoder {

	enum DateEncodingStrategy {
		/// Defer to `Date` for choosing an encoding. This is the default strategy.
		case deferredToDate

		/// Encode the `Date` as a UNIX timestamp (as a JSON number).
		case secondsSince1970

		/// Encode the `Date` as UNIX millisecond timestamp (as a JSON number).
		case millisecondsSince1970

		/// Encode the `Date` as a string formatted by the given formatter.
		case formatted(DateFormatter)

		/// Encode the `Date` as a custom value encoded by the given closure.
		///
		/// If the closure fails to encode a value into the given encoder, the encoder will encode an empty automatic container in its place.
		case custom((Date, Encoder) throws -> Void)
	}

	enum NonConformingFloatEncodingStrategy {
		/// Throw upon encountering non-conforming values. This is the default strategy.
		case `throw`

		/// Encode the values using the given representation strings.
		case convertToString(positiveInfinity: String, negativeInfinity: String, nan: String)
	}

	open var dateEncodingStrategy: DateEncodingStrategy = .millisecondsSince1970

	open var nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy = .throw

	open var userInfo: [CodingUserInfoKey: Any] = [:]

	fileprivate struct _Options {
		let dateEncodingStrategy: DateEncodingStrategy
		let nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy
		let userInfo: [CodingUserInfoKey: Any]
	}

	fileprivate var options: _Options {
		_Options(dateEncodingStrategy: dateEncodingStrategy, nonConformingFloatEncodingStrategy: nonConformingFloatEncodingStrategy, userInfo: userInfo)
	}

	init() {
	}

	func encode<T: Encodable>(_ value: T) throws -> YsonValue {
		let encoder = _YsonEncoder(options: self.options)

		guard let topLevel = try encoder.box_(value) else {
			throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
		}
		return topLevel
	}
}

fileprivate class _YsonEncoder: Encoder {
	fileprivate var storage: _YsonEncodingStorage = _YsonEncodingStorage()
	fileprivate let options: YsonEncoder._Options
	var codingPath: [CodingKey]
	var userInfo: [CodingUserInfoKey: Any] {
		self.options.userInfo
	}

	fileprivate init(options: YsonEncoder._Options, codingPath: [CodingKey] = []) {
		self.options = options
		self.codingPath = codingPath
	}

	/// Returns whether a new element can be encoded at this coding path.
	///
	/// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
	fileprivate var canEncodeNewValue: Bool {
		// Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
		// At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
		// If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
		//
		// This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
		// Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
		self.storage.count == self.codingPath.count
	}

	func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
		let topContainer: YsonObject
		if self.canEncodeNewValue {
			topContainer = self.storage.pushObject()
		} else {
			guard let container = self.storage.stack.last as? YsonObject else {
				preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
			}
			topContainer = container
		}
		let container = _YsonObjectEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
		return KeyedEncodingContainer(container)
	}

	func unkeyedContainer() -> UnkeyedEncodingContainer {
		let topContainer: YsonArray
		if self.canEncodeNewValue {
			topContainer = self.storage.pushArray()
		} else {
			guard let container = self.storage.stack.last as? YsonArray else {
				preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
			}
			topContainer = container
		}
		return _YsonArrayEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
	}

	func singleValueContainer() -> SingleValueEncodingContainer {
		self
	}
}

fileprivate struct _YsonEncodingStorage {
	private(set) fileprivate var stack: [YsonValue] = []

	fileprivate init() {
	}

	fileprivate var count: Int {
		self.stack.count
	}

	fileprivate mutating func pushObject() -> YsonObject {
		let yo = YsonObject()
		self.stack.append(yo)
		return yo
	}

	fileprivate mutating func pushArray() -> YsonArray {
		let array = YsonArray()
		self.stack.append(array)
		return array
	}

	fileprivate mutating func push(container: YsonValue) {
		self.stack.append(container)
	}

	fileprivate mutating func pop() -> YsonValue {
		precondition(self.stack.count > 0, "Empty container stack.")
		return self.stack.popLast()!
	}
}

fileprivate struct _YsonObjectEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
	typealias Key = K
	private let encoder: _YsonEncoder
	private var container: YsonObject
	private(set) public var codingPath: [CodingKey]

	fileprivate init(referencing encoder: _YsonEncoder, codingPath: [CodingKey], wrapping container: YsonObject) {
		self.encoder = encoder
		self.codingPath = codingPath
		self.container = container
	}

	// MARK: - KeyedEncodingContainerProtocol Methods

	mutating func encodeNil(forKey key: Key) throws {
		self.container[key.stringValue] = YsonNull.inst
	}

	mutating func encode(_ value: Bool, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: Int, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: Int8, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: Int16, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: Int32, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: Int64, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: UInt, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: UInt8, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: UInt16, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: UInt32, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: UInt64, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: String, forKey key: Key) throws {
		self.container[key.stringValue] = self.encoder.box(value)
	}

	mutating func encode(_ value: Float, forKey key: Key) throws {
		// Since the float may be invalid and throw, the coding path needs to contain this key.
		self.encoder.codingPath.append(key)
		defer {
			self.encoder.codingPath.removeLast()
		}
		self.container[key.stringValue] = try self.encoder.box(value)
	}

	mutating func encode(_ value: Double, forKey key: Key) throws {
		// Since the double may be invalid and throw, the coding path needs to contain this key.
		self.encoder.codingPath.append(key)
		defer {
			self.encoder.codingPath.removeLast()
		}
		self.container[key.stringValue] = try self.encoder.box(value)
	}

	mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
		self.encoder.codingPath.append(key)
		defer {
			self.encoder.codingPath.removeLast()
		}
		self.container[key.stringValue] = try self.encoder.box(value)
	}

	mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
		let dictionary = YsonObject()
		self.container[key.stringValue] = dictionary

		self.codingPath.append(key)
		defer {
			self.codingPath.removeLast()
		}

		let container = _YsonObjectEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
		return KeyedEncodingContainer(container)
	}

	mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
		let array = YsonArray()
		self.container[key.stringValue] = array

		self.codingPath.append(key)
		defer {
			self.codingPath.removeLast()
		}
		return _YsonArrayEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
	}

	mutating func superEncoder() -> Encoder {
		_YsonReferencingEncoder(referencing: self.encoder, at: _YsonKey.super, wrapping: self.container)
	}

	mutating func superEncoder(forKey key: Key) -> Encoder {
		_YsonReferencingEncoder(referencing: self.encoder, at: key, wrapping: self.container)
	}
}

fileprivate struct _YsonArrayEncodingContainer: UnkeyedEncodingContainer {
	private let encoder: _YsonEncoder
	private let container: YsonArray
	private(set) public var codingPath: [CodingKey]

	var count: Int {
		self.container.count
	}

	fileprivate init(referencing encoder: _YsonEncoder, codingPath: [CodingKey], wrapping container: YsonArray) {
		self.encoder = encoder
		self.codingPath = codingPath
		self.container = container
	}

	mutating func encodeNil() throws {
		self.container.add(YsonNull.inst)
	}

	mutating func encode(_ value: Bool) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: Int) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: Int8) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: Int16) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: Int32) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: Int64) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: UInt) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: UInt8) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: UInt16) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: UInt32) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: UInt64) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: String) throws {
		self.container.add(self.encoder.box(value))
	}

	mutating func encode(_ value: Float) throws {
		// Since the float may be invalid and throw, the coding path needs to contain this key.
		self.encoder.codingPath.append(_YsonKey(index: self.count))
		defer {
			self.encoder.codingPath.removeLast()
		}
		self.container.add(try self.encoder.box(value))
	}

	mutating func encode(_ value: Double) throws {
		// Since the double may be invalid and throw, the coding path needs to contain this key.
		self.encoder.codingPath.append(_YsonKey(index: self.count))
		defer {
			self.encoder.codingPath.removeLast()
		}
		self.container.add(try self.encoder.box(value))
	}

	mutating func encode<T: Encodable>(_ value: T) throws {
		self.encoder.codingPath.append(_YsonKey(index: self.count))
		defer {
			self.encoder.codingPath.removeLast()
		}
		self.container.add(try self.encoder.box(value))
	}

	mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
		self.codingPath.append(_YsonKey(index: self.count))
		defer {
			self.codingPath.removeLast()
		}
		let dic = YsonObject()
		self.container.add(dic)
		let container = _YsonObjectEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dic)
		return KeyedEncodingContainer(container)
	}

	mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
		self.codingPath.append(_YsonKey(index: self.count))
		defer {
			self.codingPath.removeLast()
		}
		let array = YsonArray()
		self.container.add(array)
		return _YsonArrayEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
	}

	mutating func superEncoder() -> Encoder {
		_YsonReferencingEncoder(referencing: self.encoder, at: self.container.count, wrapping: self.container)
	}
}

extension _YsonEncoder: SingleValueEncodingContainer {
	fileprivate func assertCanEncodeNewValue() {
		precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
	}

	func encodeNil() throws {
		assertCanEncodeNewValue()
		self.storage.push(container: YsonNull.inst)
	}

	func encode(_ value: Bool) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: Int) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: Int8) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: Int16) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: Int32) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: Int64) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: UInt) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: UInt8) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: UInt16) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: UInt32) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: UInt64) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: String) throws {
		assertCanEncodeNewValue()
		self.storage.push(container: self.box(value))
	}

	func encode(_ value: Float) throws {
		assertCanEncodeNewValue()
		try self.storage.push(container: self.box(value))
	}

	func encode(_ value: Double) throws {
		assertCanEncodeNewValue()
		try self.storage.push(container: self.box(value))
	}

	func encode<T: Encodable>(_ value: T) throws {
		assertCanEncodeNewValue()
		try self.storage.push(container: self.box(value))
	}
}

fileprivate extension _YsonEncoder {
	func box(_ value: Bool) -> YsonValue {
		YsonBool(value)
	}

	func box(_ value: Int) -> YsonValue {
		YsonNum(value)
	}

	func box(_ value: Int8) -> YsonValue {
		YsonNum(value)
	}

	func box(_ value: Int16) -> YsonValue {
		YsonNum(value)
	}

	func box(_ value: Int32) -> YsonValue {
		YsonNum(value)
	}

	func box(_ value: Int64) -> YsonValue {
		YsonNum(value)
	}

	func box(_ value: UInt) -> YsonValue {
		YsonNum(value)
	}

	func box(_ value: UInt8) -> YsonValue {
		YsonNum(value)
	}

	func box(_ value: UInt16) -> YsonValue {
		YsonNum(value)
	}

	func box(_ value: UInt32) -> YsonValue {
		YsonNum(value)
	}

	func box(_ value: UInt64) -> YsonValue {
		YsonNum(value)
	}

	func box(_ value: String) -> YsonValue {
		YsonString(value)
	}

	func box(_ float: Float) throws -> YsonValue {
		guard !float.isInfinite && !float.isNaN else {
			guard case let .convertToString(positiveInfinity:posInfString, negativeInfinity:negInfString, nan:nanString) = self.options.nonConformingFloatEncodingStrategy else {
				throw EncodingError._invalidFloatingPointValue(float, at: codingPath)
			}

			if float == Float.infinity {
				return YsonString(posInfString)
			} else if float == -Float.infinity {
				return YsonString(negInfString)
			} else {
				return YsonString(nanString)
			}
		}

		return YsonNum(float)
	}

	func box(_ double: Double) throws -> YsonValue {
		guard !double.isInfinite && !double.isNaN else {
			guard case let .convertToString(positiveInfinity:posInfString, negativeInfinity:negInfString, nan:nanString) = self.options.nonConformingFloatEncodingStrategy else {
				throw EncodingError._invalidFloatingPointValue(double, at: codingPath)
			}

			if double == Double.infinity {
				return YsonString(posInfString)
			} else if double == -Double.infinity {
				return YsonString(negInfString)
			} else {
				return YsonString(nanString)
			}
		}

		return YsonNum(double)
	}

	func box(_ date: Date) throws -> YsonValue {
		switch self.options.dateEncodingStrategy {
		case .deferredToDate:
			// Must be called with a surrounding with(pushedKey:) call.
			try date.encode(to: self)
			return self.storage.pop()

		case .secondsSince1970:
			return YsonNum(date.timeIntervalSince1970)

		case .millisecondsSince1970:
			return YsonNum(1000 * date.timeIntervalSince1970)

		case .formatted(let formatter):
			return YsonString(formatter.string(from: date))

		case .custom(let closure):
			let depth = self.storage.count
			try closure(date, self)

			guard self.storage.count > depth else {
				// The closure didn't encode anything. Return the default keyed container.
				return YsonObject()
			}

			// We can pop because the closure encoded something.
			return self.storage.pop()
		}
	}

	func box(_ data: Data) throws -> YsonValue {
		YsonBlob(data)
	}

	func box<T: Encodable>(_ value: T) throws -> YsonValue {
		try self.box_(value) ?? YsonObject()
	}

	// This method is called "box_" instead of "box" to disambiguate it from the overloads. Because the return type here is different from all of the "box" overloads (and is more general), any "box" calls in here would call back into "box" recursively instead of calling the appropriate overload, which is not what we want.
	func box_<T: Encodable>(_ value: T) throws -> YsonValue? {
		switch value {
		case let d as Data:
			return try self.box(d)
		case let nd as NSData:
			return try self.box(Data(referencing: nd))
		case let d as Date:
			return try self.box(d)
		case let nd as NSDate:
			return try self.box(nd as Date)
		case let u as URL:
			return YsonString(u.absoluteString)
		case let u as NSURL:
			return YsonString(u.absoluteString ?? "")
		case let u as Decimal:
			return YsonNum(u)
		case let u as NSDecimalNumber:
			return YsonNum(u)
		default:
			break
		}

		let depth = self.storage.count
		try value.encode(to: self)
		guard self.storage.count > depth else {
			return nil
		}
		return self.storage.pop()
	}
}

/// _JSONReferencingEncoder is a special subclass of _JSONEncoder which has its own storage,
/// but references the contents of a different encoder.
/// It's used in superEncoder(), which returns a new encoder for encoding a superclass
/// -- the lifetime of the encoder should not escape the scope it's created in,
/// but it doesn't necessarily know when it's done being used (to write to the original container).
fileprivate class _YsonReferencingEncoder: _YsonEncoder {
	/// The type of container we're referencing.
	private enum Reference {
		/// Referencing a specific index in an array container.
		case array(YsonArray, Int)

		/// Referencing a specific key in a dictionary container.
		case dictionary(YsonObject, String)
	}

	let encoder: _YsonEncoder
	private let reference: Reference

	init(referencing encoder: _YsonEncoder, at index: Int, wrapping array: YsonArray) {
		self.encoder = encoder
		self.reference = .array(array, index)
		super.init(options: encoder.options, codingPath: encoder.codingPath)

		self.codingPath.append(_YsonKey(index: index))
	}

	/// Initializes `self` by referencing the given dictionary container in the given encoder.
	init(referencing encoder: _YsonEncoder, at key: CodingKey, wrapping dictionary: YsonObject) {
		self.encoder = encoder
		self.reference = .dictionary(dictionary, key.stringValue)
		super.init(options: encoder.options, codingPath: encoder.codingPath)

		self.codingPath.append(key)
	}

	override var canEncodeNewValue: Bool {
		// With a regular encoder, the storage and coding path grow together.
		// A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
		// We have to take this into account.
		self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
	}

	// MARK: - Deinitialization

	// Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
	deinit {
		let value: YsonValue
		switch self.storage.count {
		case 0: value = YsonObject()
		case 1: value = self.storage.pop()
		default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
		}

		switch self.reference {
		case .array(let array, let index):
			array.data.insert(value, at: index)

		case .dictionary(let dictionary, let key):
			dictionary[key] = value
		}
	}
}

struct _YsonKey: CodingKey {
	var stringValue: String
	var intValue: Int?

	init?(stringValue: String) {
		self.stringValue = stringValue
		self.intValue = nil
	}

	init?(intValue: Int) {
		self.stringValue = "\(intValue)"
		self.intValue = intValue
	}

	init(index: Int) {
		self.stringValue = "Index \(index)"
		self.intValue = index
	}

	static let `super` = _YsonKey(stringValue: "super")!
}

fileprivate extension EncodingError {

	static func _invalidFloatingPointValue<T: FloatingPoint>(_ value: T, at codingPath: [CodingKey]) -> EncodingError {
		let valueDescription: String
		if value == T.infinity {
			valueDescription = "\(T.self).infinity"
		} else if value == -T.infinity {
			valueDescription = "-\(T.self).infinity"
		} else {
			valueDescription = "\(T.self).nan"
		}

		let debugDescription = "Unable to encode \(valueDescription) directly in JSON. Use JSONEncoderX.NonConformingFloatEncodingStrategy.convertToString to specify how the value should be encoded."
		return .invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: debugDescription))
	}
}