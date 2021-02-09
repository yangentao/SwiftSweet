//
// Created by entaoyang@163.com on 2017/10/25.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation


public extension File {
    static let tempDir: String = NSTemporaryDirectory()
    static let homeDir: String = NSHomeDirectory()
    static let cacheDir: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    static let docDir: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

    static func cacheFile(_ cacheName: String) -> File {
        File(cacheDir.appendPath(cacheName))
    }

    static func docFile(_ docName: String) -> File {
        File(docDir.appendPath(docName))
    }

    static func tempFile(_ name: String) -> File {
        File(tempDir.appendPath(name))
    }
}

public class File {
    public let fullPath: String

    private lazy var fm: FileManager = FileManager.default

    public init(_ fullPath: String) {
        self.fullPath = fullPath
    }

    public convenience init(_ parentPath: String, _ filename: String) {
        self.init(parentPath.appendPath(filename))
    }

    public convenience init(_ parentFile: File, _ filename: String) {
        self.init(parentFile.fullPath.appendPath(filename))
    }

    public var readHandle: FileHandleX? {
        try? FileHandleX.open(reading: FileURL(fullPath))
    }
    public var writeHandle: FileHandleX? {
        try? FileHandleX.open(writing: FileURL(fullPath))
    }
    public var apendHandle: FileHandleX? {
        try? FileHandleX.open(appending: FileURL(fullPath))
    }
}

public extension File {

    static var mainBundle: File {
        File(Bundle.main.bundlePath)
    }

    var lastPath: String {
        fullPath.lastPath
    }
    var parentPath: String {
        fullPath.parentPath
    }
    var parentFile: File {
        File(self.parentPath)
    }

    var size: Int {
        if self.isFile {
            if let attr = try? fm.attributesOfItem(atPath: fullPath) {
                return attr[FileAttributeKey.size] as! Int
            }
        }
        return 0
    }

    var exist: Bool {
        fm.fileExists(atPath: fullPath)
    }

    var isFile: Bool {
        var ob = ObjCBool(false)
        let b = fm.fileExists(atPath: fullPath, isDirectory: &ob)
        return b && !ob.boolValue
    }
    var isDir: Bool {
        var ob = ObjCBool(true)
        let b = fm.fileExists(atPath: fullPath, isDirectory: &ob)
        return b && ob.boolValue
    }

    func readText(_ encoding: String.Encoding = String.Encoding.utf8) -> String? {
        if !self.isFile {
            return nil
        }
        do {
            return try String(contentsOfFile: fullPath, encoding: encoding)
        } catch (let err) {
            print(err)
            logd(err)
        }
        return nil
    }

    @discardableResult
    func writeText(text: String) -> Bool {
        do {
            try text.write(toFile: fullPath, atomically: true, encoding: String.Encoding.utf8)
            return true
        } catch (let err) {
            logd(err)
        }
        return false
    }

    func readData() -> Data? {
        if !self.isFile {
            return nil
        }
        do {
            return try Data(contentsOf: FileURL(fullPath), options: Data.ReadingOptions.uncached)
        } catch (let err) {
            logd(err)
        }
        return nil
    }

    @discardableResult
    func writeData(data: Data) -> Bool {
        do {
            try data.write(to: URL(fileURLWithPath: fullPath))
            return true
        } catch {
            loge("write error \(error)")
            return false
        }

    }

    @discardableResult
    func remove() -> Bool {
        do {
            try FileManager.default.removeItem(atPath: fullPath)
            return true
        } catch {
            return false
        }
    }

    func list() -> [String] {
        do {
            return try fm.contentsOfDirectory(atPath: self.fullPath)
        } catch {
            loge("list error: \(error)")
            return []
        }
    }

    func listDeep() -> [String] {
        do {
            return try fm.subpathsOfDirectory(atPath: self.fullPath)
        } catch {
            loge("list error: \(error)")
            return []
        }
    }

    @discardableResult
    func mkdir() -> Bool {
        do {
            try fm.createDirectory(atPath: self.fullPath, withIntermediateDirectories: true)
            return true
        } catch {
            loge("mkdir error: \(error)")
            return false
        }
    }
}

public func FileURL(_ file: String) -> URL {
    URL(fileURLWithPath: file, isDirectory: false)
}

public func DirURL(_ dir: String) -> URL {
    URL(fileURLWithPath: dir, isDirectory: true)
}
