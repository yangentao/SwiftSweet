//
// Created by yangentao on 2021/1/29.
//

import Foundation


public class AnyGroup {
    private var _items: [Any]

    public init(_ items: [Any]) {
        self._items = items
    }


}

public extension AnyGroup {
    var items: [Any] {
        var ls = [Any]()
        for a in _items {
            if let g = a as? AnyGroup {
                ls.append(contentsOf: g.items)
            } else {
                ls.append(a)
            }
        }
        return ls
    }

    func itemsTyped<T: Any>(_ unpackArray: Bool = false) -> [T] {
        if unpackArray {
            var ls = [T]()
            for e in items {
                if let a = e as? T {
                    ls.append(a)
                } else if let aa = e as? [T] {
                    ls.append(contentsOf: aa)
                }
            }
            return ls
        }
        return items.filter {
            $0 is T
        }.map {
            $0 as! T
        }
    }
}


@_functionBuilder
public struct AnyBuilder {

    public static func buildBlock(_ cs: Any...) -> AnyGroup {
        AnyGroup(cs)
    }

    public static func buildIf(_ content: Any?) -> Any {
        content ?? AnyGroup([])
    }

    public static func buildEither(first: Any) -> Any {
        first
    }

    public static func buildEither(second: Any) -> Any {
        second
    }
}

public typealias AnyBuildBlock = () -> AnyGroup

public func buildItemsAny(@AnyBuilder _ block: AnyBuildBlock) -> [Any] {
    let c = block()
    return c.items
}

public func buildItemsTyped<T: Any>(@AnyBuilder _ block: AnyBuildBlock) -> [T] {
    let c = block()
    return c.itemsTyped()
}

