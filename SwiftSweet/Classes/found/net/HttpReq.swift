//
// Created by yangentao on 2019/10/28.
// Copyright (c) 2019 yangentao. All rights reserved.
//

import Foundation

public extension HttpReq {
    var method: HttpMethod? {
        get {
            if let m = self._request.httpMethod {
                return HttpMethod(rawValue: m)
            }
            return nil
        }
        set {
            self._request.httpMethod = newValue?.rawValue
        }
    }

    func setHeader(key: String, value: String?) {
        self._request.setValue(value, forHTTPHeaderField: key)
    }

    func setHeader(named: HttpHeader, value: String?) {
        self._request.setValue(value, forHTTPHeaderField: named.rawValue)
    }

    func getHeader(key: String) -> String? {
        self._request.value(forHTTPHeaderField: key)
    }

    func getHeader(named: HttpHeader) -> String? {
        self._request.value(forHTTPHeaderField: named.rawValue)
    }

    func addHeader(named: HttpHeader, value: String) {
        self._request.addValue(value, forHTTPHeaderField: named.rawValue)
    }

    func addHeader(key: String, value: String) {
        self._request.addValue(value, forHTTPHeaderField: key)
    }

    subscript(_ key: String) -> String? {
        get {
            self.getHeader(key: key)
        }
        set {
            self.setHeader(key: key, value: newValue)
        }
    }
    subscript(_ named: HttpHeader) -> String? {
        get {
            self.getHeader(named: named)
        }
        set {
            self.setHeader(named: named, value: newValue)
        }
    }
    var contentType: String? {
        get {
            self.getHeader(named: .ContentType)
        }
        set {
            self.setHeader(named: .ContentType, value: newValue)
        }
    }
}

open class HttpReq {
    public var _request: URLRequest
    public var urlComponents: URLComponents
    public var queryItems: [URLQueryItem] = []

    public var progressRecv: HttpProgress? = nil
    public var progressSend: HttpProgress? = nil
    fileprivate var sendStart = false
    fileprivate var recvStart = false

    var task: URLSessionTask? = nil

    public init(url: URL) {
        self.urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        self.queryItems = self.urlComponents.queryItems ?? []
        self._request = URLRequest(url: url, timeoutInterval: 20.0)
        self._request.cachePolicy = .reloadIgnoringLocalCacheData
        self._request.httpShouldHandleCookies = true
    }

    open func beforeRequest() {

    }

    public func cancelTask() {
        self.task?.cancel()
    }

    open func dump() {
        if !isDebug {
            return
        }
        println()
        let req = self._request
        println(req.httpMethod, " ", req.url)
        if let m = req.allHTTPHeaderFields {
            for (k, v) in m {
                println(k, ":", v)
            }
        }
        if let ct = self.contentType {
            if ct.contains("xml") || ct.contains("json") || ct.contains("html") || ct.contains("text") {
                if let data = req.httpBody {
                    if data.count < 1024 {
                        if let s = String(data: data, encoding: .utf8) {
                            println("Body: ")
                            println(s)
                        }
                    }
                }
            }
        }
        println()
    }

    open func requestSync() -> HttpResp {
        self.beforeRequest()
        let req = self._request
        self.dump()

        var hr: HttpResp!
        let sem = DispatchSemaphore(value: 0);
        let task: URLSessionTask = URLSession.shared.dataTask(with: req, completionHandler: { (nsdata: Data?, urlResp: URLResponse?, err: Error?) -> Void in
            hr = HttpResp(response: urlResp as? HTTPURLResponse, data: nsdata, error: err)
            sem.signal()
        })
        self.task = task
        task.resume()
        self.watchRecv(task: task)
        self.watchSend(task: task)
        sem.wait()
        if isDebug {
            hr.dump()
        }

        return hr
    }

    open func requestAsync(_ callback: @escaping HttpCallback) -> URLSessionTask {
        self.beforeRequest()
        let req = self._request
        let task: URLSessionTask = URLSession.shared.dataTask(with: req, completionHandler: { (nsdata: Data?, urlResp: URLResponse?, err: Error?) -> Void in
            let result = HttpResp(response: urlResp as? HTTPURLResponse, data: nsdata, error: err)
            callback(result)
        })
        self.task = task
        task.resume()
        self.watchRecv(task: task)
        self.watchSend(task: task)
        return task
    }
}

private extension HttpReq {
    func watchRecv(task: URLSessionTask) {
        guard let pp = self.progressRecv else {
            return
        }
        Task.foreDelay(seconds: 0.2) {
            self.calcRecvProgress(p: pp, task: task)
        }
    }

    func calcRecvProgress(p: HttpProgress, task: URLSessionTask) {
        let received = Int(task.countOfBytesReceived)
        let total: Int = Int(task.countOfBytesExpectedToReceive)
        if received > 0 || total > 0 {
            if !recvStart {
                recvStart = true
                p.onHttpStart(total)
                p.onHttpProgress(0, total, 0)
            }
            let percent: Int = received * 100 / total
            p.onHttpProgress(received, total, percent)
        }
        if task.state == URLSessionTask.State.running || task.state == URLSessionTask.State.suspended {
            self.watchRecv(task: task)
        } else {
            let OK = task.state == URLSessionTask.State.completed
            if OK {
                p.onHttpProgress(total, total, 100)
            }
            p.onHttpFinish(OK)
        }

    }

    func watchSend(task: URLSessionTask) {
        guard let pp = self.progressSend else {
            return
        }
        Task.foreDelay(seconds: 0.2) {
            self.calcSendProgress(p: pp, task: task)
        }
    }

    func calcSendProgress(p: HttpProgress, task: URLSessionTask) {
        let sent = Int(task.countOfBytesSent)
        let total = Int(task.countOfBytesExpectedToSend)
        if sent > 0 || total > 0 {
            if !sendStart {
                sendStart = true
                p.onHttpStart(total)
                p.onHttpProgress(0, total, 0)
            }
            let percent = sent * 100 / total
            p.onHttpProgress(sent, total, percent)
        }
        if task.state == URLSessionTask.State.running || task.state == URLSessionTask.State.suspended {
            self.watchSend(task: task)
        } else {
            let OK = task.state == URLSessionTask.State.completed
            if OK {
                p.onHttpProgress(total, total, 100)
            }
            p.onHttpFinish(OK)
        }
    }
}

public extension HttpReq {

    @discardableResult
    func authBasic(user: String, pwd: String) -> Self {
        let s = user + ":" + pwd
        let ss = s.dataUtf8.base64
        self[.Authorization] = "Basic " + ss
        return self
    }

    @discardableResult
    func arg(key: String, value: String) -> Self {
        self.queryItems += URLQueryItem(name: key, value: value)
        return self
    }

    @discardableResult
    func args(@AnyBuilder _ block: AnyBuildBlock) -> Self {
        let ls: [KeyAny] = block().itemsTyped(false)
        for item in ls {
            if let v = item.value ?? nil {
                arg(key: item.key, value: "\(v)")
            } else {
                arg(key: item.key, value: "")
            }
        }
        return self
    }

}

public class HttpGet: HttpReq {

    public override init(url: URL) {
        super.init(url: url)
        self.method = .GET
    }

    public override func beforeRequest() {
        self.urlComponents.queryItems = self.queryItems
        self._request.url = self.urlComponents.url!
    }

}

public class HttpPost: HttpReq {

    public override init(url: URL) {
        super.init(url: url)
        self.method = .POST
        self.setHeader(named: .ContentType, value: "application/x-www-form-urlencoded; charset=utf-8")
    }

    public override func beforeRequest() {
        self.urlComponents.query = ""
        self._request.url = self.urlComponents.url!

        let query = self.queryItems.map { qi in
            qi.name + "=" + ((qi.value?.urlEncoded) ?? "")
        }.joined(separator: "&")
        self._request.httpBody = query.dataUtf8

    }

}

public class HttpPostRaw: HttpReq {

    public override init(url: URL) {
        super.init(url: url)
        self.method = .POST
    }

    @discardableResult
    public func bodyJson(data: Data) -> Self {
        self.body(contentType: Mimes.JSON, data: data)
    }

    @discardableResult
    public func bodyXML(data: Data) -> Self {
        self.body(contentType: Mimes.XML, data: data)
    }

    @discardableResult
    public func body(contentType: String, data: Data) -> Self {
        self[.ContentType] = contentType
        self._request.httpBody = data
        return self
    }

    public override func beforeRequest() {
        self.urlComponents.queryItems = self.queryItems
        self._request.url = self.urlComponents.url!

    }

}

public class HttpMultipart: HttpReq {
    private lazy var BOUNDARY = UUID().uuidString
    private lazy var BOUNDARY_START: String = "--" + self.BOUNDARY + CRLF
    private lazy var BOUNDARY_END: String = "--" + self.BOUNDARY + "--" + CRLF

    private var files: [String: HttpFileParam] = [:]

    public override init(url: URL) {
        super.init(url: url)
        self.method = .POST
        self.setHeader(named: .ContentType, value: "multipart/form-data; boundary=\(BOUNDARY)")
    }

    @discardableResult
    public func file(name: String, fileParam: HttpFileParam) -> Self {
        self.files[name] = fileParam
        return self
    }

    @discardableResult
    public func file(name: String, url: URL) -> Self {
        self.file(name: name, fileParam: HttpFileParam(url: url))
    }

    @discardableResult
    public func file(name: String, path: String) -> Self {
        self.file(name: name, fileParam: HttpFileParam(filePath: path))
    }

    public override func beforeRequest() {
        self.urlComponents.query = ""
        self._request.url = self.urlComponents.url!
        self._request.httpBody = self.buildMultipartData()

    }

    private func buildMultipartData() -> Data {
        var data: Data = Data(capacity: 4096)
        for item in self.queryItems {
            data.appendUtf8(BOUNDARY_START)
            data.appendUtf8("Content-Disposition: form-data; name=\"\(item.name)\"")
            data.appendNewLine()
            data.appendUtf8("Content-Type:text/plain;charset=utf-8")
            data.appendNewLine()
            data.appendNewLine()
            data.appendUtf8(item.value ?? "")
            data.appendNewLine()
        }
        for (k, f) in self.files {
            if let v = f.fileData {
                data.appendUtf8(BOUNDARY_START)
                data.appendUtf8("Content-Disposition:form-data;name=\"\(k)\";filename=\"\(f.fileName)\"")
                data.appendNewLine()
                data.appendUtf8("Content-Type:\(f.mime)")
                data.appendNewLine()
                data.appendUtf8("Content-Transfer-Encoding: binary")
                data.appendNewLine()
                data.appendNewLine()
                data.append(v)
                data.appendNewLine()
            }
        }
        data.appendUtf8(BOUNDARY_END)
        return data
    }

}

