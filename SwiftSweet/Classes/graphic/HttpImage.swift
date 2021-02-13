//
// Created by entaoyang on 2019-02-13.
// Copyright (c) 2019 yet.net. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif

public class ImageOption {
    var forceDownload: Bool = false
    var failedImage = ""
}


public extension XImageView {
    fileprivate var _httpUrl: String? {
        get {
            return getAttr("__httpurl__") as? String
        }
        set {
            setAttr("__httpurl__", newValue)
        }
    }

    func loadUrl(_ url: String, _ finishCallback: @escaping (XImageView) -> Void = { a in
    }) {
        HttpImage(url).display(self, finishCallback)
    }
}

public class HttpImage {
    public let url: String
    private var opt = ImageOption()

    public weak var imageView: XImageView? = nil

    public init(_ url: String) {
        self.url = url
    }
}

public extension HttpImage {

    func opt(_ op: ImageOption) -> HttpImage {
        self.opt = op
        return self
    }

    func image(_ block: @escaping (XImage?) -> Void) {
        if opt.forceDownload {
            FileDownloader.download(url) { file in
                if let d = file?.readData() {
                    block(XImage(data: d))
                } else {
                    block(nil)
                }
            }
        } else {
            FileDownloader.retrive(url) { file in
                if let d = file?.readData() {
                    block(XImage(data: d))
                } else {
                    block(nil)
                }
            }
        }
    }

    func display(_ view: XImageView, _ finishCallback: @escaping (XImageView) -> Void = { a in
    }) {
        view._httpUrl = url
        self.imageView = view
        self.image { img in
            let iv = self.imageView
            if iv != nil {
                self.setupImage(img, iv!, finishCallback)
            }
        }
    }

    private func setupImage(_ img: XImage?, _ iv: XImageView, _ finishCallback: @escaping (XImageView) -> Void = { a in
    }) {
        if iv._httpUrl != self.url {
            return
        }
        if img != nil {
            iv.image = img
        } else if !self.opt.failedImage.isEmpty {
            iv.image = XImage(named: opt.failedImage)
        } else {
            iv.image = nil
        }
        finishCallback(iv)
    }

    static func batch(_ lsUrl: [String], _ callback: @escaping ([XImage]) -> Void) {
        self.batch(lsUrl, ImageOption(), callback)
    }

    static func batch(_ lsUrl: [String], _ opt: ImageOption, _ callback: @escaping ([XImage]) -> Void) {
        var lsImg = [XImage?]()
        if lsUrl.isEmpty {
            callback(lsImg.compactMap({ $0 }))
        }
        for url in lsUrl {
            HttpImage(url).opt(opt).image { img in
                logd("http image: ", img == nil)
                lsImg.append(img)
                if lsImg.count == lsUrl.count {
                    logd("batch callback ")
                    callback(lsImg.compactMap({ $0 }))
                }
            }
        }
    }

}
