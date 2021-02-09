//
// Created by yangentao on 2021/1/30.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif


public extension View {

    @discardableResult
    func constraints(_ block: (ConstraintBuilder) -> Void) -> Self {
        block(ConstraintBuilder(self))
        if self.superview != nil {
            installSelfConstraints()
        }
        return self
    }


    internal var constraintItems: ConstraintItems {
        if let a = getAttr("__ConstraintItems__") as? ConstraintItems {
            return a
        }
        let ls = ConstraintItems()
        setAttr("__ConstraintItems__", ls)
        return ls
    }


    @discardableResult
    func installSelfConstraints() -> Self {
        if superview == nil {
            fatalError("installonstraints() error: superview is nil!")
        }
        constraintItems.items.each {
            $0.install()
        }
        constraintItems.items = []
        return self
    }

}

internal class ConstraintItems {
    var items: [ConstraintItem] = []

    func removeByID(_ id: Int) {
        items.removeFirstIf {
            $0._ID == id
        }
    }
}

public class ConstraintItem {
    public let _ID: Int = IDGen()
    unowned var view: View // view
    var attr: LayoutAttribute
    var relation: LayoutRelation = .equal
    unowned var otherView: View? = nil
    var otherName: String? = nil
    var otherAttr: LayoutAttribute = .notAnAttribute
    var multiplier: CGFloat = 1
    var constant: CGFloat = 0
    var ident: String? = nil
    var priority: LayoutPriority = .required

    init(view: View, attr: LayoutAttribute) {
        self.view = view
        self.attr = attr
    }

    var identifierValue: String {
        ident ?? "autoID_\(self._ID)"
    }

    public func install() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.autoresizesSubviews = false
        let cp = NSLayoutConstraint(item: view as Any, attribute: attr, relatedBy: relation, toItem: makeOtherView(), attribute: otherAttr, multiplier: multiplier, constant: constant)
        cp.priority = priority
        cp.identifier = identifierValue
        view.sysConstraintParams.items.append(cp)
        cp.isActive = true

//        view.layoutSubtreeIfNeeded()
//        view.updateConstraintsForSubtreeIfNeeded()
    }

    private func makeOtherView() -> View? {
        if otherView != nil {
            return otherView
        }
        switch otherName {
        case nil:
            return nil
        case SelfViewName:
            return view
        case ParentViewName:
            return view.superview!
        default:
            if otherName == view.superview!.name {
                return view.superview!
            }
            return view.superview!.child(named: otherName!)!
        }
    }

    public func ident(_ id: String) -> Self {
        ident = id
        return self
    }

    public func priority(_ p: LayoutPriority) -> Self {
        priority = p
        return self
    }

    public func priority(_ p: Float) -> Self {
        priority = LayoutPriority(rawValue: p)
        return self
    }

    @discardableResult
    fileprivate func relationTo(rel: LayoutRelation, otherView: View, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        self.relation = rel
        self.multiplier = multi
        self.constant = constant
        self.otherView = otherView
        if let p2 = otherAttr {
            self.otherAttr = p2
        } else {
            self.otherAttr = self.attr
        }
        return self
    }

    @discardableResult
    fileprivate func relationTo(rel: LayoutRelation, otherName: String? = nil, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        relation = rel
        self.multiplier = multi
        self.constant = constant
        self.otherName = otherName
        if otherName != nil {
            if let p2 = otherAttr {
                self.otherAttr = p2
            } else {
                self.otherAttr = self.attr
            }
        }
        return self
    }

}

public class ConstraintBuilder {
    fileprivate unowned var view: View

    fileprivate init(_ view: View) {
        self.view = view
    }
}

public extension ConstraintBuilder {

    @discardableResult
    func ident(_ id: String) -> Self {
        view.constraintItems.items.last!.ident = id
        return self
    }

    @discardableResult
    func priority(_ p: LayoutPriority) -> Self {
        view.constraintItems.items.last!.priority = p
        return self
    }

    @discardableResult
    func priority(_ p: Float) -> Self {
        priority(LayoutPriority(rawValue: p))
    }

    private func append(_ attr: LayoutAttribute) -> ConstraintItem {
        let item = ConstraintItem(view: view, attr: attr)
        view.constraintItems.items.append(item)
        return item
    }
}

//combine


public extension ConstraintBuilder {

    @discardableResult
    func left(_ c: CGFloat) -> Self {
        append(.left).relationTo(rel: .equal, constant: c)
        return self
    }

    @discardableResult
    func right(_ c: CGFloat) -> Self {
        append(.right).relationTo(rel: .equal, constant: c)
        return self
    }

    @discardableResult
    func top(_ c: CGFloat) -> Self {
        append(.top).relationTo(rel: .equal, constant: c)
        return self
    }

    @discardableResult
    func bottom(_ c: CGFloat) -> Self {
        append(.bottom).relationTo(rel: .equal, constant: c)
        return self
    }

    @discardableResult
    func width(_  constant: CGFloat = 0) -> Self {
        append(.width).relationTo(rel: .equal, constant: constant)
        return self
    }

    @discardableResult
    func height(_  constant: CGFloat = 0) -> Self {
        append(.height).relationTo(rel: .equal, constant: constant)
        return self
    }


    //w = h * multi + constant
    @discardableResult
    func widthRatio(multi: CGFloat, constant: CGFloat = 0) -> Self {
        append(.width).relationTo(rel: .equal, otherView: view, otherAttr: .height, multi: multi, constant: constant)
        return self
    }

    //h = w * multi + constant
    @discardableResult
    func heightRatio(multi: CGFloat, constant: CGFloat = 0) -> Self {
        append(.height).relationTo(rel: .equal, otherView: view, otherAttr: .width, multi: multi, constant: constant)
        return self
    }
}

//parent
public extension ConstraintBuilder {
    @discardableResult
    func centerParent(xConst: CGFloat = 0, yConst: CGFloat = 0) -> Self {
        centerXParent(xConst).centerYParent(yConst)
    }

    @discardableResult
    func edgeXParent(leftConst: CGFloat = 0, rightConst: CGFloat = 0) -> Self {
        leftParent(leftConst).rightParent(rightConst)
    }

    @discardableResult
    func edgeYParent(topConst: CGFloat = 0, bottomConst: CGFloat = 0) -> Self {
        topParent(topConst).bottomParent(bottomConst)
    }

    @discardableResult
    func edgesParent(leftConst: CGFloat = 0, rightConst: CGFloat = 0, topConst: CGFloat = 0, bottomConst: CGFloat = 0) -> Self {
        leftParent(leftConst).rightParent(rightConst).topParent(topConst).bottomParent(bottomConst)
    }

    @discardableResult
    func leftParent(_ c: CGFloat = 0) -> Self {
        append(.left).relationTo(rel: .equal, otherName: ParentViewName, constant: c)
        return self
    }

    @discardableResult
    func rightParent(_ c: CGFloat = 0) -> Self {
        append(.right).relationTo(rel: .equal, otherName: ParentViewName, constant: c)
        return self
    }

    @discardableResult
    func topParent(_ c: CGFloat = 0) -> Self {
        append(.top).relationTo(rel: .equal, otherName: ParentViewName, constant: c)
        return self
    }

    @discardableResult
    func bottomParent(_ c: CGFloat = 0) -> Self {
        append(.bottom).relationTo(rel: .equal, otherName: ParentViewName, constant: c)
        return self
    }

    @discardableResult
    func widthParent(multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        append(.width).relationTo(rel: .equal, otherName: ParentViewName, multi: multi, constant: constant)
        return self
    }

    @discardableResult
    func heightParent(multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        append(.height).relationTo(rel: .equal, otherName: ParentViewName, multi: multi, constant: constant)
        return self
    }

    @discardableResult
    func centerXParent(_ c: CGFloat = 0) -> Self {
        append(.centerX).relationTo(rel: .equal, otherName: ParentViewName, constant: c)
        return self
    }

    @discardableResult
    func centerYParent(_ c: CGFloat = 0) -> Self {
        append(.centerY).relationTo(rel: .equal, otherName: ParentViewName, constant: c)
        return self
    }
}

public extension ConstraintBuilder {
    @discardableResult
    func left(_ otherName: String, _ c: CGFloat = 0) -> Self {
        append(.left).relationTo(rel: .equal, otherName: otherName, constant: c)
        return self
    }

    @discardableResult
    func right(_  otherName: String, _ c: CGFloat = 0) -> Self {
        append(.right).relationTo(rel: .equal, otherName: otherName, constant: c)
        return self
    }

    @discardableResult
    func top(_  otherName: String, _ c: CGFloat = 0) -> Self {
        append(.top).relationTo(rel: .equal, otherName: otherName, constant: c)
        return self
    }

    @discardableResult
    func bottom(_  otherName: String, _ c: CGFloat = 0) -> Self {
        append(.bottom).relationTo(rel: .equal, otherName: otherName, constant: c)
        return self
    }

    @discardableResult
    func centerX(_  otherName: String, _ c: CGFloat = 0) -> Self {
        append(.centerX).relationTo(rel: .equal, otherName: otherName, constant: c)
        return self
    }

    @discardableResult
    func centerY(_  otherName: String, _ c: CGFloat = 0) -> Self {
        append(.centerY).relationTo(rel: .equal, otherName: otherName, constant: c)
        return self
    }

    @discardableResult
    func center(_  otherName: String, xConst: CGFloat = 0, yConst: CGFloat = 0) -> Self {
        centerX(otherName, xConst).centerY(otherName, yConst)
    }

    @discardableResult
    func width(_ otherName: String, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        append(.width).relationTo(rel: .equal, otherName: otherName, multi: multi, constant: constant)
        return self
    }

    @discardableResult
    func height(_ otherName: String, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        append(.height).relationTo(rel: .equal, otherName: otherName, multi: multi, constant: constant)
        return self
    }
}


//to other
public extension ConstraintBuilder {
    @discardableResult
    func center(_ otherView: View, xConst: CGFloat = 0, yConst: CGFloat = 0) -> Self {
        centerX(otherView, xConst).centerY(otherView, yConst)
    }

    @discardableResult
    func width(_ otherView: View, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        append(.width).relationTo(rel: .equal, otherView: otherView, multi: multi, constant: constant)
        return self
    }

    @discardableResult
    func height(_ otherView: View, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        append(.height).relationTo(rel: .equal, otherView: otherView, multi: multi, constant: constant)
        return self
    }


    @discardableResult
    func left(_ otherView: View, _ c: CGFloat = 0) -> Self {
        append(.left).relationTo(rel: .equal, otherView: otherView, constant: c)
        return self
    }

    @discardableResult
    func right(_ otherView: View, _ c: CGFloat = 0) -> Self {
        append(.right).relationTo(rel: .equal, otherView: otherView, constant: c)
        return self
    }

    @discardableResult
    func top(_ otherView: View, _ c: CGFloat = 0) -> Self {
        append(.top).relationTo(rel: .equal, otherView: otherView, constant: c)
        return self
    }

    @discardableResult
    func bottom(_ otherView: View, _ c: CGFloat = 0) -> Self {
        append(.bottom).relationTo(rel: .equal, otherView: otherView, constant: c)
        return self
    }

    @discardableResult
    func centerX(_ otherView: View, _ c: CGFloat = 0) -> Self {
        append(.centerX).relationTo(rel: .equal, otherView: otherView, constant: c)
        return self
    }

    @discardableResult
    func centerY(_ otherView: View, _ c: CGFloat = 0) -> Self {
        append(.centerY).relationTo(rel: .equal, otherView: otherView, constant: c)
        return self
    }

}


public extension ConstraintBuilder {
    private func props(_ attrs: LayoutAttribute...) -> ConstraintBuilderEnd {
        let ls = attrs.map {
            ConstraintItem(view: self.view, attr: $0)
        }
        return ConstraintBuilderEnd(ls)
    }

    var edges: ConstraintBuilderEnd {
        props(.left, .top, .right, .bottom)
    }
    var edgeX: ConstraintBuilderEnd {
        props(.left, .right)
    }
    var edgeY: ConstraintBuilderEnd {
        props(.top, .bottom)
    }

    var leftTop: ConstraintBuilderEnd {
        props(.left, .top)
    }
    var leftBottom: ConstraintBuilderEnd {
        props(.left, .bottom)
    }
    var rightTop: ConstraintBuilderEnd {
        props(.right, .top)
    }
    var rightBottom: ConstraintBuilderEnd {
        props(.right, .bottom)
    }
    var size: ConstraintBuilderEnd {
        props(.width, .height)
    }
    var center: ConstraintBuilderEnd {
        props(.centerX, .centerY)
    }

    //------
    var left: ConstraintBuilderEnd {
        props(.left)
    }
    var right: ConstraintBuilderEnd {
        props(.right)
    }
    var top: ConstraintBuilderEnd {
        props(.top)
    }
    var bottom: ConstraintBuilderEnd {
        props(.bottom)
    }
    var centerX: ConstraintBuilderEnd {
        props(.centerX)
    }
    var centerY: ConstraintBuilderEnd {
        props(.centerY)
    }
    var width: ConstraintBuilderEnd {
        props(.width)
    }
    var height: ConstraintBuilderEnd {
        props(.height)
    }
    var leading: ConstraintBuilderEnd {
        props(.leading)
    }
    var trailing: ConstraintBuilderEnd {
        props(.trailing)
    }

    var lastBaseline: ConstraintBuilderEnd {
        props(.lastBaseline)
    }
    var firstBaseline: ConstraintBuilderEnd {
        props(.firstBaseline)
    }

    #if os(iOS)
    var leftMargin: ConstraintBuilderEnd {
        props(.leftMargin)
    }
    var rightMargin: ConstraintBuilderEnd {
        props(.rightMargin)
    }
    var topMargin: ConstraintBuilderEnd {
        props(.topMargin)
    }
    var bottomMargin: ConstraintBuilderEnd {
        props(.bottomMargin)
    }
    var leadingMargin: ConstraintBuilderEnd {
        props(.leadingMargin)
    }
    var trailingMargin: ConstraintBuilderEnd {
        props(.trailingMargin)
    }
    var centerXWithinMargins: ConstraintBuilderEnd {
        props(.centerXWithinMargins)
    }
    var centerYWithinMargins: ConstraintBuilderEnd {
        props(.centerYWithinMargins)
    }
    #endif
}

public class ConstraintBuilderEnd {
    fileprivate var items: [ConstraintItem] = []

    fileprivate init(_ items: [ConstraintItem]) {
        self.items = items
        items.first?.view.constraintItems.items.append(contentsOf: items)
    }

    @discardableResult
    public func ident(_ id: String) -> Self {
        items.each {
            $0.ident = id
        }
        return self
    }

    @discardableResult
    public func priority(_ p: LayoutPriority) -> Self {
        items.each {
            $0.priority = p
        }
        return self
    }

    @discardableResult
    public func priority(_ p: Float) -> Self {
        priority(LayoutPriority(rawValue: p))
    }

}

public extension ConstraintBuilderEnd {

    @discardableResult
    private func relationTo(rel: LayoutRelation, otherView: View, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        for a in self.items {
            a.relationTo(rel: rel, otherView: otherView, otherAttr: otherAttr, multi: multi, constant: constant)
        }
        return self
    }

    @discardableResult
    private func relationTo(rel: LayoutRelation, otherName: String?, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        for a in self.items {
            a.relationTo(rel: rel, otherName: otherName, otherAttr: otherAttr, multi: multi, constant: constant)
        }
        return self
    }

    @discardableResult
    private func relationParent(rel: LayoutRelation, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        for a in self.items {
            a.relationTo(rel: rel, otherName: ParentViewName, otherAttr: otherAttr, multi: multi, constant: constant)
        }
        return self
    }

    @discardableResult
    private func relationSelf(rel: LayoutRelation, otherAttr: LayoutAttribute?, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        for a in self.items {
            a.relationTo(rel: rel, otherView: a.view, otherAttr: otherAttr, multi: multi, constant: constant)
        }
        return self
    }

    @discardableResult
    func eq(_ otherView: View, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        relationTo(rel: .equal, otherView: otherView, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func ge(_ otherView: View, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        relationTo(rel: .greaterThanOrEqual, otherView: otherView, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func le(_ otherView: View, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        relationTo(rel: .lessThanOrEqual, otherView: otherView, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func eq(_ otherName: String, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        relationTo(rel: .equal, otherName: otherName, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func ge(_ otherName: String, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        relationTo(rel: .greaterThanOrEqual, otherName: otherName, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func le(_ otherName: String, otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        relationTo(rel: .lessThanOrEqual, otherName: otherName, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func eqParent(otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        relationParent(rel: .equal, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func geParent(otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        relationParent(rel: .greaterThanOrEqual, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func leParent(otherAttr: LayoutAttribute? = nil, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        relationParent(rel: .lessThanOrEqual, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func eqSelf(_ otherAttr: LayoutAttribute, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        return relationSelf(rel: .equal, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func geSelf(_ otherAttr: LayoutAttribute, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        return relationSelf(rel: .greaterThanOrEqual, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func leSelf(_ otherAttr: LayoutAttribute, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        return relationSelf(rel: .lessThanOrEqual, otherAttr: otherAttr, multi: multi, constant: constant)
    }

    @discardableResult
    func eqConst(_ constant: CGFloat) -> Self {
        relationTo(rel: .equal, otherName: nil, otherAttr: .notAnAttribute, multi: 1, constant: constant)
    }

    @discardableResult
    func geConst(_ constant: CGFloat) -> Self {
        relationTo(rel: .greaterThanOrEqual, otherName: nil, otherAttr: .notAnAttribute, multi: 1, constant: constant)
    }

    @discardableResult
    func leConst(_ constant: CGFloat) -> Self {
        relationTo(rel: .lessThanOrEqual, otherName: nil, otherAttr: .notAnAttribute, multi: 1, constant: constant)
    }

}



