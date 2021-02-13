//
// Created by yangentao on 2019/10/28.
//

import Foundation

extension HttpResp {

    var ysonObject: YsonObject? {
        if let s = self.text {
            return Yson.parseObject(s)
        }
        return nil
    }
}

public extension HttpReq {
    @discardableResult
    static func +=(lhs: HttpReq, rhs: KeyAny) -> HttpReq {
        if let v = rhs.value ?? nil {
            lhs.arg(key: rhs.key, value: "\(v)")
        }
        return lhs
    }
}

public extension HttpPostRaw {
    func bodyJson(@AnyBuilder _ block: AnyBuildBlock) -> Self {
        let yo = yson(block)
        bodyJson(data: yo.yson.data(using: .utf8)!)
        return self
    }
}


class _FileLocal {
    private let map: FileMap<String, String> = FileMap<String, String>(File.docFile("local_file_cache"))

    private let dirName = "file_cache"

    init() {
        let dir = File.cacheFile(dirName)
        if !dir.isDir {
            dir.mkdir()
        }
    }

    fileprivate func makeFile(_ filename: String) -> File {
        return File.cacheFile(dirName.appendPath(filename))
    }

    func find(_ url: String) -> File? {
        guard let f = map.get(url) else {
            return nil
        }
        let file = makeFile(f)
        if file.isFile {
            return file
        }
        sync(self) {
            map.remove(url)
            map.save()
        }
        return nil
    }

    func remove(_ url: String) {
        guard let f = map.get(url) else {
            return
        }
        File(f).remove()
        sync(self) {
            map.remove(url)
            map.save()
        }
    }

    func put(_ url: String, _ filename: String) {
        sync(self) {
            map.put(url, filename)
            map.save()
        }
    }

    func dump() -> [String: String] {
        return map.model.map
    }

}

let ImageLocal: _FileLocal = _FileLocal()

public typealias DownCallback = (String, Bool) -> Void

internal class _FileDownloader {
    var processSet: Set<String> = Set<String>()
    private var listenMap = [String: [DownCallback]]()
    private let taskQueue = TaskQueue("file_download")

    func isDownloading(_ url: String) -> Bool {
        return listenMap.keys.contains(url)
    }

    func retrive(_ url: String, _ block: @escaping (File?) -> Void) {
        let f = ImageLocal.find(url)
        if f != nil {
            logd("使用缓存文件")
            block(f)
            return
        }
        logd("没有缓存")
        self.download(url, block)
    }

    func download(_ url: String, _ block: @escaping (File?) -> Void) {
        logd("下载文件")
        self.taskQueue.back {
            self.downSync(url) { u, ok in
                let f = ImageLocal.find(u)
                block(f)
            }
        }
    }

    private func downSync(_ url: String, _ callback: @escaping DownCallback) {
        if var arr = listenMap[url] {
            arr.append(callback)
            listenMap[url] = arr
        } else {
            listenMap[url] = [callback]
        }
        if self.processSet.contains(url) {
            return
        }
        self.processSet.insert(url)
        let filename = Date.tempFileName
        let file = ImageLocal.makeFile(filename)
        let ok = httpDown(url, file)
        if ok {
            ImageLocal.put(url, filename)
        } else {
            file.remove()
        }
        self.processSet.remove(url)
        Task.fore {
            let ls: [DownCallback]? = self.listenMap[url]
            self.listenMap.removeValue(forKey: url)
            if ls != nil {
                for l in ls! {
                    l(url, ok)
                }
            }
        }
    }

    private func httpDown(_ url: String, _ file: File) -> Bool {
        guard let u = URL(string: url) else {
            return false
        }
        if url.count < 8 {
            return false
        }
        let r = HttpGet(url: u).requestSync()
        //let r = Http(url).get()
        if !r.OK {
            return false
        }
        guard let data = r.content else {
            return false
        }
        file.writeData(data: data)
        return file.isFile
    }

    func lock(_ obj: Any, _ block: BlockVoid) {
        objc_sync_enter(obj)
        block()
        objc_sync_exit(obj)
    }

}

internal let FileDownloader: _FileDownloader = _FileDownloader()
