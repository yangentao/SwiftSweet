//
// Created by entaoyang@163.com on 2021/2/9.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif


public typealias ViewClickBlock = (View) -> Void


//lazy var label: UILabel = NamedView("hello", self)
public func NamedView<T: View>(_ page: XViewController, _ viewName: String) -> T {
    guard  let v = page.view.child(named: viewName, deep: true) else {
        fatalError("NO view named: \(viewName)")
    }
    return v as! T
}

public func NamedView<T: View>(_ parentView: View, _ viewName: String) -> T {
    guard  let v = parentView.child(named: viewName, deep: true) else {
        fatalError("NO view named: \(viewName)")
    }
    return v as! T
}

public extension View {
    var name: String? {
        get {
            self.getAttr("__view_name__") as? String
        }
        set {
            self.setAttr("__view_name__", newValue)
        }
    }

    @discardableResult
    func named(_ name: String) -> Self {
        self.name = name
        return self
    }

    func findByName(_ name: String) -> View? {
        if name == self.name {
            return self
        }
        for v in self.subviews {
            if let a = v.findByName(name) {
                return a
            }
        }
        return nil
    }

    func child(named: String, deep: Bool = false) -> View? {
        if deep {
            for v in self.subviews {
                if let a = v.findByName(named) {
                    return a
                }
            }
        } else {
            for v in self.subviews {
                if v.name == named {
                    return v
                }
            }
        }
        return nil
    }

}


public extension View {
    @discardableResult
    func addView<T: View>(_ child: T) -> T {
        self.addSubview(child)
        child.installSelfConstraints()
        return child
    }

    @discardableResult
    func addView<T: View>(_ child: T, _ block: (T) -> Void) -> T {
        self.addSubview(child)
        block(child)
        child.installSelfConstraints()
        return child
    }

    func firstView(_ block: (View) -> Bool) -> View? {
        for v in self.subviews {
            if block(v) {
                return v
            }
            if let vv = v.firstView(block) {
                return vv
            }
        }
        return nil
    }

    func firstView<T: View>(_ t: T.Type) -> T? {
        firstView {
            $0 is T
        } as? T
    }

    func firstView<T: View>() -> T? {
        firstView {
            $0 is T
        } as? T
    }

    func siblings<T>(_: T.Type) -> [T] {
        self.superview!.subviews.filter {
            $0 != self
        }.compactMap {
            $0 as? T
        }
    }


}