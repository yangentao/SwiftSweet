//
// Created by entaoyang@163.com on 2019-07-28.
// Copyright (c) 2019 entao.dev. All rights reserved.
// ios

import Foundation

public let Log = LogImpl()

public struct LogLevel: Hashable, Equatable, RawRepresentable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ value: String) {
        self.rawValue = value
    }
}

public extension LogLevel {
    static let success = LogLevel("SUCCESS")
    static let error = LogLevel("ERROR")
    static let warning = LogLevel("WARNING")
    static let info = LogLevel("INFO")
    static let debug = LogLevel("DEBUG")
    static let verbose = LogLevel("VERBOSE")
}

public struct LogItem: Hashable, Equatable, ToString {
    var level: LogLevel
    var tag: String = ""
    var message: String
    var time: TimeInterval = Date().timeIntervalSince1970

    public var toString: String {
        Date(timeIntervalSince1970: time).format(fmt: .yyyy_MM_dd__HH_mm_ss_SSS) + " " + level.rawValue + ": " + tag + " " + message
    }
}

public typealias LogAcceptor = (LogItem) -> Bool

//强引用
public struct LogPrinterItem: Equatable {
    var printer: LogPrinter
    var acceptor: LogAcceptor = { _ in
        true
    }

    public static func ==(lhs: LogPrinterItem, rhs: LogPrinterItem) -> Bool {
        lhs.printer === rhs.printer
    }
}

public struct LogListenerItem: Equatable {
    weak var listener: LogListener? = nil
    var acceptor: LogAcceptor = { _ in
        true
    }

    public static func ==(lhs: LogListenerItem, rhs: LogListenerItem) -> Bool {
        lhs.listener === rhs.listener
    }
}

public class LogImpl {
    private let lock: NSRecursiveLock = NSRecursiveLock()
    private var printerItems: [LogPrinterItem] = []
    private var listenerItems: [LogListenerItem] = []

    public private(set ) var historyItems: [LogItem] = []

    public var keepSize: Int = 1000 {
        didSet {
            if self.keepSize < 0 {
                self.keepSize = 0
            }
            if self.historyItems.count > keepSize {
                self.historyItems.removeFirst(self.historyItems.count - keepSize)
            }
        }
    }

    fileprivate init() {
        set(printer: LogConsolePrinter())
    }

    deinit {
        let ls = self.printerItems
        ls.forEach { p in
            p.printer.logFlush()
            p.printer.logUninstall()
        }
    }
}

public extension LogImpl {
    func filterItems(_ block: (LogItem) -> Bool) -> [LogItem] {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.historyItems.filter(block)
    }

    func itemsToString(_ items: [Any?]) -> String {
        var buf = ""
        for a in items {
            if let b = a ?? nil {
                print(b, terminator: " ", to: &buf)
            } else {
                print("nil", terminator: " ", to: &buf)
            }
        }
        return buf
    }
}

public extension LogImpl {
    func add(listener: LogListener) {
        self.listenerItems.addOnAbsence(LogListenerItem(listener: listener))
    }

    func add(listener: LogListener, acceptor: @escaping LogAcceptor) {
        self.listenerItems.addOnAbsence(LogListenerItem(listener: listener, acceptor: acceptor))
    }

    func remove(listener: LogListener) {
        self.listenerItems.removeAll { item in
            item.listener === listener
        }
    }
}

public extension LogImpl {

    func add(printer: LogPrinter) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        self.printerItems.addOnAbsence(LogPrinterItem(printer: printer))
    }

    func add(printer: LogPrinter, acceptor: @escaping LogAcceptor) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        self.printerItems.addOnAbsence(LogPrinterItem(printer: printer, acceptor: acceptor))
    }

    func set(printer: LogPrinter) {
        self.clearPrinters()
        self.add(printer: printer)
    }

    func set(printer: LogPrinter, acceptor: @escaping LogAcceptor) {
        self.clearPrinters()
        self.add(printer: printer, acceptor: acceptor)
    }

    func clearPrinters() {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        let ls = self.printerItems
        self.printerItems = []
        ls.forEach {
            $0.printer.logUninstall()
        }
    }

    func remove(printer: LogPrinter) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        self.printerItems.removeAll { item in
            item.printer === printer
        }
        printer.logUninstall()
    }

    func flush() {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        let ls = self.printerItems
        ls.forEach {
            $0.printer.logFlush()
        }
    }

    func log(item: LogItem) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        if self.keepSize > 0 {
            if self.historyItems.count > self.keepSize + 20 {
                let n = self.historyItems.count - self.keepSize
                self.historyItems.removeFirst(n)
            }
            self.historyItems.append(item)
        }
        let ls = self.printerItems
        for pi in ls {
            if pi.acceptor(item) {
                pi.printer.logWrite(item: item)
            }
        }

        Task.fore {
            var needClean = false
            let ls = self.listenerItems
            for l in ls {
                if let L = l.listener {
                    if l.acceptor(item) {
                        L.onLog(item: item)
                    }
                } else {
                    needClean = true
                }
            }
            if needClean {
                self.listenerItems.removeAll {
                    $0.listener == nil
                }
            }
        }

    }

}

public extension LogImpl {

    func logItems(level: LogLevel, tag: String = "", items: [Any?]) {
        self.log(item: LogItem(level: level, tag: tag, message: itemsToString(items)))
    }

    func info(_ items: Any?...) {
        self.logItems(level: .info, items: items)
    }

    func debug(_ items: Any?...) {
        self.logItems(level: .debug, items: items)
    }

    func warn(_ items: Any?...) {
        self.logItems(level: .warning, items: items)
    }

    func error(_ items: Any?...) {
        self.logItems(level: .error, items: items)
    }

    func success(_ items: Any?...) {
        self.logItems(level: .success, items: items)
    }

    func verbose(_ items: Any?...) {
        self.logItems(level: .verbose, items: items)
    }
}

public extension LogImpl {


    func info(tag: String, _ items: Any?...) {
        self.logItems(level: .info, tag: tag, items: items)
    }

    func debug(tag: String, _ items: Any?...) {
        self.logItems(level: .debug, tag: tag, items: items)
    }

    func warn(tag: String, _ items: Any?...) {
        self.logItems(level: .warning, tag: tag, items: items)
    }

    func error(tag: String, _ items: Any?...) {
        self.logItems(level: .error, tag: tag, items: items)
    }

    func success(tag: String, _ items: Any?...) {
        self.logItems(level: .success, tag: tag, items: items)
    }

    func verbose(tag: String, _ items: Any?...) {
        self.logItems(level: .verbose, tag: tag, items: items)
    }
}


public func logd(_ ss: Any?...) {
    Log.logItems(level: .debug, items: ss)
}

public func loge(_ ss: Any?...) {
    Log.logItems(level: .error, items: ss)
}

public func log(tag: String, _ ss: Any?...) {
    Log.logItems(level: .debug, tag: tag, items: ss)
}

public func logd(tag: String, _ ss: Any?...) {
    Log.logItems(level: .debug, tag: tag, items: ss)
}

public func loge(tag: String, _ ss: Any?...) {
    Log.logItems(level: .error, tag: tag, items: ss)
}

public protocol LogListener: class {
    func onLog(item: LogItem)
}

public protocol LogPrinter: class {
    func logWrite(item: LogItem)
    func logFlush()
    func logUninstall()
}

public class LogConsolePrinter: LogPrinter {
    public func logWrite(item: LogItem) {
        if item.level == .error {
            print(item.toString, to: &StdError)
        } else {
            print(item.toString)
        }
    }

    public func logFlush() {

    }

    public func logUninstall() {

    }
}

fileprivate class _StdError: TextOutputStream {
    func write(_ string: String) {
        fputs(string, stderr)
    }
}

fileprivate var StdError = _StdError()
