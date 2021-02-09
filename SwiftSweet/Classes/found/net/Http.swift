//
// Created by entaoyang@163.com on 2017/10/10.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation
import Dispatch

//TODO 大文件上传下载, 参考: https://swift.gg/2019/01/21/streaming-multipart-requests/
//httpBodyStream

let CRLF: String = "\r\n"

public protocol HttpProgress {
    func onHttpStart(_ total: Int)

    func onHttpProgress(_ current: Int, _ total: Int, _ percent: Int)

    func onHttpFinish(_ success: Bool)
}

public typealias HttpCallback = (HttpResp) -> Void

//文件上传用multipart方法, 文件合计大小不超过10M

public struct HttpMethod: Hashable, Equatable, RawRepresentable {
    public private(set) var rawValue: String

    public init(_ value: String) {
        self.rawValue = value
    }

    public init(rawValue: String) {
        self.init(rawValue)
    }

    public static let GET = HttpMethod("GET")
    public static let POST = HttpMethod("POST")
    public static let HEAD = HttpMethod("HEAD")
    public static let PUT = HttpMethod("PUT")
    public static let DELETE = HttpMethod("DELETE")
    public static let OPTIONS = HttpMethod("OPTIONS")
    public static let TRACE = HttpMethod("TRACE")
    public static let CONNECT = HttpMethod("CONNECT")
}

public struct HttpHeader: Hashable, Equatable, RawRepresentable {
    public var rawValue: String

    public init(_ value: String) {
        self.rawValue = value
    }

    public init(rawValue: String) {
        self.init(rawValue)
    }

    public static let ContentType = HttpHeader(rawValue: "Content-Type")
    public static let Authorization = HttpHeader(rawValue: "Authorization")
    public static let Accept = HttpHeader(rawValue: "Accept")
    public static let AccepLanguage = HttpHeader(rawValue: "Accept-Language")
    public static let UserAgent = HttpHeader(rawValue: "User-Agent")

}

public class HttpFileParam {
    public var fileName: String = ""
    public var fileData: Data? = nil
    public var mime: String = Mimes.OCTET_STREAM

    public convenience init(url: URL) {
        do {
            self.init(fileName: url.lastPathComponent, fileData: try Data(contentsOf: url))
        } catch {
            self.init(fileName: url.lastPathComponent, fileData: nil)
            loge("HttpFileParam Error:", url)
            loge("HttpFileParam Error:", error)
        }

    }

    public convenience init(filePath: String) {
        self.init(url: URL(fileURLWithPath: filePath, isDirectory: false))

    }

    public init(fileName: String, fileData: Data?) {
        self.fileName = fileName
        self.fileData = fileData
        self.mime = Mimes[fileName]
    }
}

