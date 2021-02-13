//
// Created by entaoyang@163.com on 2017/10/14.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation


public class PropChangedInfo: NSObject {
    public unowned let obj: NSObject
    public let keyPath: String
    public var oldValue: Any? = nil
    public var newValue: Any? = nil

    public init(_ obj: NSObject, _ keyPath: String) {
        self.obj = obj
        self.keyPath = keyPath
    }
}

public extension NSObject {
    func propChangedInfo(_ keyPath: String, target: NSObject, selector: Selector) {
        let info = propChangedAction(keyPath)
        info.target = target
        info.selector1 = selector
    }

    func propChanged(_ keyPath: String, target: NSObject, selector: Selector) {
        let info = propChangedAction(keyPath)
        info.target = target
        info.selector = selector
    }

    func propChanged(_ keyPath: String, fire msg: Msg) {
        let info = propChangedAction(keyPath)
        info.msg = msg
    }

    @discardableResult
    func propChanged(_ keyPath: String, fire msgId: MsgID) -> Msg {
        let m = Msg(msgId)
        propChanged(keyPath, fire: m)
        return m
    }

    fileprivate func propChangedAction(_ keyPath: String) -> PropChangedActionInfo {
        if let a = propChangedActionMap.map[keyPath] {
            return a
        }
        let b = PropChangedActionInfo(self, keyPath)
        propChangedActionMap.map[keyPath] = b
        addObserver(PropObserver.inst, forKeyPath: keyPath, options: [.old, .new], context: nil)
        return b
    }

    private var propChangedActionMap: MyMap<String, PropChangedActionInfo> {
        if let a = self.getAttr("__propFireMap__") as? MyMap<String, PropChangedActionInfo> {
            return a
        }
        let b = MyMap<String, PropChangedActionInfo>()
        setAttr("__propFireMap__", b)
        return b
    }
}

fileprivate class PropObserver: NSObject {
    private override init() {

    }

    fileprivate static let inst = PropObserver()

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let obj = object as? NSObject, let kp = keyPath else {
            return
        }
        obj.propChangedAction(kp).changed(change)
    }

}

fileprivate class PropChangedActionInfo {
    unowned let obj: NSObject
    let keyPath: String
    var msg: Msg? = nil
    weak var target: NSObject? = nil
    var selector: Selector? = nil
    var selector1: Selector? = nil

    init(_ obj: NSObject, _ keyPath: String) {
        self.obj = obj
        self.keyPath = keyPath
    }

    func changed(_ values: [NSKeyValueChangeKey: Any]?) {
        if let m = msg {
            m.sender = obj
            m["oldValue"] = values?[.oldKey]
            m["newValue"] = values?[.newKey]
            m.fire()
        }
        if let s = selector {
            target?.perform(s)
        }
        if let ss = selector1 {
            let info = PropChangedInfo(obj, keyPath)
            info.oldValue = values?[.oldKey]
            info.newValue = values?[.newKey]
            target?.perform(ss, with: info)
        }
    }
}