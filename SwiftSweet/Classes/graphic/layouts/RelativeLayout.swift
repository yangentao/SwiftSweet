//
// Created by yangentao on 2021/2/2.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif


public typealias RC = RelativeCondition

public extension View {
    var relativeParams: RelativeParams? {
        get {
            return getAttr("__relativeParam__") as? RelativeParams
        }
        set {
            setAttr("__relativeParam__", newValue)
        }
    }

    var relativeParamsEnsure: RelativeParams {
        if let L = self.relativeParams {
            return L
        } else {
            let a = RelativeParams()
            self.relativeParams = a
            return a
        }
    }

    @discardableResult
    func relativeConditions(@AnyBuilder _ block: AnyBuildBlock) -> Self {
        let ls: [RelativeCondition] = block().itemsTyped(true)
        self.relativeParamsEnsure.conditions.append(contentsOf: ls)
        return self
    }

    @discardableResult
    func relativeParams(_ block: (RelativeParamsBuilder) -> Void) -> Self {
        let b = RelativeParamsBuilder()
        block(b)
        self.relativeParamsEnsure.conditions.append(contentsOf: b.items)
        return self
    }
}

public enum RelativeProp: Int {
    case width, height
    case left, right, top, bottom
    case centerX, centerY

}

fileprivate let UNSPEC: CGFloat = -10000

public class RelativeCondition: Applyable {
    fileprivate weak var view: View?
    fileprivate weak var viewOther: View? = nil
    public let id: Int = nextId()
    public var prop: RelativeProp
    public let relation: LayoutRelation = .equal
    public var otherViewName: String? = nil
    public var otherProp: RelativeProp? = nil //if nil, use prop value
    public var multiplier: CGFloat = 1
    public var constant: CGFloat = 0
    //只有width,height是WrapContent的时候用到
    public var minWidth: CGFloat = 0
    public var minHeight: CGFloat = 0

    fileprivate var tempValue: CGFloat = UNSPEC
    fileprivate var OK: Bool {
        tempValue != UNSPEC
    }

    public init(prop: RelativeProp) {
        self.prop = prop
    }

    private static var _lastId: Int = 0

    private static func nextId() -> Int {
        _lastId += 1
        return _lastId
    }
}

public extension RelativeCondition {
    func multi(_ n: CGFloat) -> Self {
        self.multiplier = n
        return self
    }

    func constant(_ n: CGFloat) -> Self {
        self.constant = n
        return self
    }

    func eq(_ otherView: String, _ otherProp: RelativeProp? = nil) -> Self {
        self.otherViewName = otherView
        if let p = otherProp {
            self.otherProp = p
        } else {
            self.otherProp = self.prop
        }
        return self
    }

    func eq(_ value: CGFloat) -> Self {
        self.constant = value
        return self
    }

    var eqParent: RelativeCondition {
        eqParent(self.prop)
    }

    func eqParent(_ otherProp: RelativeProp) -> Self {
        eq(ParentViewName, otherProp)
    }

    func eqSelf(_ otherProp: RelativeProp) -> Self {
        eq(SelfViewName, otherProp)
    }
}


public extension RelativeCondition {

    static var width: RelativeCondition {
        RC(prop: .width)
    }
    static var height: RelativeCondition {
        RC(prop: .height)
    }
    static var left: RelativeCondition {
        RC(prop: .left)
    }
    static var top: RelativeCondition {
        RC(prop: .top)
    }
    static var right: RelativeCondition {
        RC(prop: .right)
    }
    static var bottom: RelativeCondition {
        RC(prop: .bottom)
    }
    static var centerX: RelativeCondition {
        RC(prop: .centerX)
    }
    static var centerY: RelativeCondition {
        RC(prop: .centerY)
    }
}

public class RelativeParams {
    public var conditions: [RelativeCondition] = []

    @discardableResult
    public func updateConstant(_ prop: RelativeProp, _ constant: CGFloat) -> Self {
        guard let c = self.conditions.first({ c in c.prop == prop }) else {
            return self
        }
        _ = c.constant(constant)
        c.view?.superview?.postLayout()
        return self
    }

    @discardableResult
    public func updateConstantIf(_ constant: CGFloat, _ block: (RelativeCondition) -> Bool) -> Self {
        for c in conditions {
            if block(c) {
                _ = c.constant(constant)
                c.view?.superview?.postLayout()
                break
            }
        }
        return self
    }
}


public class RelativeParamsBuilder {
    var items = [RelativeCondition]()
}

public extension RelativeParamsBuilder {
    #if os(iOS)
    @discardableResult
    func widthWrap(_ minWidth: CGFloat = 0) -> Self {
        let a = RC(prop: .width).constant(WrapContent)
        a.minWidth = minWidth
        items += a
        return self
    }

    @discardableResult
    func heightWrap(_ minHeight: CGFloat = 0) -> Self {
        let a = RC(prop: .height).constant(WrapContent)
        a.minHeight = minHeight
        items += a
        return self
    }
    #endif

    @discardableResult
    func eq(_ prop: RelativeProp, viewName: String, prop2: RelativeProp?, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        items += RC(prop: prop).eq(viewName, prop2).multi(multi).constant(constant)
        return self
    }

    @discardableResult
    func eqSelf(_ prop: RelativeProp, prop2: RelativeProp?, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eq(prop, viewName: SelfViewName, prop2: prop2, multi: multi, constant: constant)
    }

    @discardableResult
    func eqParent(_ prop: RelativeProp, prop2: RelativeProp?, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eq(prop, viewName: ParentViewName, prop2: prop2, multi: multi, constant: constant)
    }

    @discardableResult
    func eqConst(_ prop: RelativeProp, constant: CGFloat) -> Self {
        items += RC(prop: prop).constant(constant)
        return self
    }

    @discardableResult
    func centerParent(_ xConst: CGFloat = 0, _ yConst: CGFloat = 0) -> Self {
        centerXParent(xConst).centerYParent(yConst)
    }

    @discardableResult
    func centerXParent(_ xConst: CGFloat = 0) -> Self {
        eqParent(.centerX, prop2: .centerX, constant: xConst)
    }

    @discardableResult
    func centerYParent(_ yConst: CGFloat = 0) -> Self {
        eqParent(.centerY, prop2: .centerY, constant: yConst)
    }

    @discardableResult
    func centerXOf(_ viewName: String, _ xConst: CGFloat = 0) -> Self {
        eq(.centerX, viewName: viewName, prop2: .centerX, constant: xConst)
    }

    @discardableResult
    func centerYOf(_ viewName: String, _ yConst: CGFloat = 0) -> Self {
        eq(.centerY, viewName: viewName, prop2: .centerY, constant: yConst)
    }

    @discardableResult
    func fillX(_ leftConst: CGFloat = 0, _ rightConst: CGFloat = 0) -> Self {
        eqParent(.left, prop2: nil, constant: leftConst)
        return eqParent(.right, prop2: nil, constant: rightConst)
    }

    @discardableResult
    func fillY(_ topConst: CGFloat = 0, _ bottomConst: CGFloat = 0) -> Self {
        eqParent(.top, prop2: nil, constant: topConst)
        return eqParent(.bottom, prop2: nil, constant: bottomConst)
    }

    @discardableResult
    func left(_ c: CGFloat) -> Self {
        eqConst(.left, constant: c)
    }

    @discardableResult
    func right(_ c: CGFloat) -> Self {
        eqConst(.right, constant: c)
    }

    @discardableResult
    func top(_ c: CGFloat) -> Self {
        eqConst(.top, constant: c)
    }

    @discardableResult
    func bottom(_ c: CGFloat) -> Self {
        eqConst(.bottom, constant: c)
    }

    @discardableResult
    func leftParent(_ c: CGFloat = 0) -> Self {
        eqParent(.left, prop2: nil, constant: c)
    }

    @discardableResult
    func rightParent(_ c: CGFloat = 0) -> Self {
        eqParent(.right, prop2: nil, constant: c)
    }

    @discardableResult
    func topParent(_ c: CGFloat = 0) -> Self {
        eqParent(.top, prop2: nil, constant: c)
    }

    @discardableResult
    func bottomParent(_ c: CGFloat = 0) -> Self {
        eqParent(.bottom, prop2: nil, constant: c)
    }


    @discardableResult
    func leftEQ(_ viewName: String, _ c: CGFloat = 0) -> Self {
        eq(.left, viewName: viewName, prop2: nil, constant: c)
    }

    @discardableResult
    func rightEQ(_ viewName: String, _ c: CGFloat = 0) -> Self {
        eq(.right, viewName: viewName, prop2: nil, constant: c)
    }

    @discardableResult
    func topEQ(_ viewName: String, _ c: CGFloat = 0) -> Self {
        eq(.top, viewName: viewName, prop2: nil, constant: c)
    }

    @discardableResult
    func bottomEQ(_ viewName: String, _ c: CGFloat = 0) -> Self {
        eq(.bottom, viewName: viewName, prop2: nil, constant: c)
    }

    @discardableResult
    func toLeftOf(_ viewName: String, _ c: CGFloat = 0) -> Self {
        eq(.right, viewName: viewName, prop2: .left, constant: c)
    }

    @discardableResult
    func toRightOf(_ viewName: String, _ c: CGFloat = 0) -> Self {
        eq(.left, viewName: viewName, prop2: .right, constant: c)
    }

    @discardableResult
    func above(_ viewName: String, _ c: CGFloat = 0) -> Self {
        eq(.bottom, viewName: viewName, prop2: .top, constant: c)
    }

    @discardableResult
    func below(_ viewName: String, _ c: CGFloat = 0) -> Self {
        eq(.top, viewName: viewName, prop2: .bottom, constant: c)
    }

    @discardableResult
    func width(_ c: CGFloat) -> Self {
        eqConst(.width, constant: c)
    }

    @discardableResult
    func height(_ c: CGFloat) -> Self {
        eqConst(.height, constant: c)
    }


    @discardableResult
    func widthEQ(_ viewName: String, prop2: RelativeProp, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eq(.width, viewName: viewName, prop2: prop2, multi: multi, constant: constant)
    }

    @discardableResult
    func heightEQ(_ viewName: String, prop2: RelativeProp, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eq(.height, viewName: viewName, prop2: prop2, multi: multi, constant: constant)
    }

    @discardableResult
    func widthEQ(_ viewName: String, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eq(.width, viewName: viewName, prop2: nil, multi: multi, constant: constant)
        return self
    }

    @discardableResult
    func heightEQ(_ viewName: String, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eq(.height, viewName: viewName, prop2: nil, multi: multi, constant: constant)
    }

    @discardableResult
    func widthEQParent(multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eqParent(.width, prop2: nil, multi: multi, constant: constant)
    }

    @discardableResult
    func widthEQParent(_ prop2: RelativeProp, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eqParent(.width, prop2: prop2, multi: multi, constant: constant)
    }

    @discardableResult
    func heightEQParent(multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eqParent(.height, prop2: nil, multi: multi, constant: constant)
    }

    @discardableResult
    func heightEQParent(_ prop2: RelativeProp, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eqParent(.height, prop2: prop2, multi: multi, constant: constant)
    }

    @discardableResult
    func widthEQSelf(_ prop2: RelativeProp, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eqSelf(.width, prop2: prop2, multi: multi, constant: constant)
    }

    @discardableResult
    func heightEQSelf(_ prop2: RelativeProp, multi: CGFloat = 1, constant: CGFloat = 0) -> Self {
        eqSelf(.height, prop2: prop2, multi: multi, constant: constant)
    }
}


public class RelativeLayout: BaseLayout {


    override func layoutChildren() {

        let childList = self.subviews
        if childList.isEmpty {
            return
        }

        var allCond: [RelativeCondition] = []
        for child in childList {
            guard  let param = child.relativeParams else {
                continue
            }
            for cond in param.conditions {
                cond.view = child
                if let otherName = cond.otherViewName {
                    if otherName == ParentViewName {
                        cond.viewOther = self
                    } else if otherName == SelfViewName {
                        cond.viewOther = child
                    } else {
                        guard  let vOther = self.findByName(otherName) else {
                            fatalError("View Named '\(otherName)' is NOT found!")
                        }
                        cond.viewOther = vOther
                    }
                }
                cond.tempValue = UNSPEC
                allCond.append(cond)
            }
        }


        let vrList: ViewRects = ViewRects(childList)

        for vr in vrList.items {
            if vr.view.relativeParams == nil {
                vr.left = 0
                vr.right = 0
                vr.width = 0
                vr.height = 0
            }
        }

        for c in allCond {
            if c.viewOther == nil {
                switch c.constant {
                    #if os(iOS)
                case WrapContent:
                    let sz = c.view!.fitSize(self.bounds.size)
                    if c.prop == .width {
                        c.tempValue = max(sz.width, c.minWidth)
                    } else if c.prop == .height {
                        c.tempValue = max(sz.height, c.minHeight)
                    } else {
                        fatalError("WrapContent ONLY used on width or height property")
                    }
                    #endif
                case MatchParent:
                    if c.prop == .width || c.prop == .height {
                        c.tempValue = queryParentProp(c.prop)
                    } else {
                        fatalError("WrapContent ONLY used on width or height property")
                    }
                    break
                default:
                    c.tempValue = c.constant
                }
                vrList.assignProp(c.view!, c.prop, c.tempValue)
            } else if c.viewOther == self {
                let otherProp = c.otherProp ?? c.prop
                c.tempValue = queryParentProp(otherProp) * c.multiplier + c.constant
                vrList.assignProp(c.view!, c.prop, c.tempValue)
            }

        }

        var matchOne = false
        repeat {
            let notMatchList = allCond.filter {
                !$0.OK
            }
            if notMatchList.isEmpty {
                break
            }
            for c in notMatchList {
                guard  let otherView = c.viewOther else {
                    continue
                }
                let otherProp = c.otherProp ?? c.prop
                let otherVal = vrList.queryProp(otherView, otherProp)
                if otherVal != UNSPEC {
                    c.tempValue = otherVal * c.multiplier + c.constant
                    vrList.assignProp(c.view!, c.prop, c.tempValue)
                    matchOne = true
                }
            }
        } while matchOne

        let notMatchList = allCond.filter {
            !$0.OK
        }
        if !notMatchList.isEmpty {
            print("WARNNING! RelativeLayout: some condition is NOT satisfied ! ")
        }

        var maxX: CGFloat = self.bounds.minX
        var maxY: CGFloat = self.bounds.minY

        for vr in vrList.items {
            if vr.OK {
//                vr.view.frame = vr.rect
                vr.view.customLayoutConstraintParams.update(vr.rect)

                maxX = max(maxX, vr.right)
                maxY = max(maxY, vr.bottom)
            }
        }

        self.contentSize = CGSize(width: maxX - self.bounds.minX, height: maxY - self.bounds.minY)

    }


    private func queryParentProp(_ prop: RelativeProp) -> CGFloat {
        let rect: Rect = self.bounds
        switch prop {
        case .left:
            return rect.minX
        case .right:
            return rect.maxX
        case .top:
            return rect.minY
        case .bottom:
            return rect.maxY
        case .centerX:
            return rect.center.x
        case .centerY:
            return rect.center.y
        case .width:
            return rect.width
        case .height:
            return rect.height
        }
    }
}


fileprivate class ViewRect {
    var view: View
    var left: CGFloat = UNSPEC {
        didSet {
            checkHor()
        }
    }

    var right: CGFloat = UNSPEC {
        didSet {
            checkHor()
        }
    }
    var centerX: CGFloat = UNSPEC {
        didSet {
            checkHor()
        }
    }
    var width: CGFloat = UNSPEC {
        didSet {
            checkHor()
        }
    }


    var bottom: CGFloat = UNSPEC {
        didSet {
            checkVer()
        }
    }
    var top: CGFloat = UNSPEC {
        didSet {
            checkVer()
        }
    }
    var centerY: CGFloat = UNSPEC {
        didSet {
            checkVer()
        }
    }
    var height: CGFloat = UNSPEC {
        didSet {
            checkVer()
        }
    }
    private var checking = false

    init(_ view: View) {
        self.view = view
    }

    var OK: Bool {
        if atLeast2(width, left, right, centerX) >= 2 && atLeast2(height, top, bottom, centerY) >= 2 {
            return true
        }
        return false
    }

    var rect: Rect {
        return Rect(x: left, y: top, width: width, height: height)
    }


    private func checkVer() {
        if checking {
            return
        }
        checking = true
        let n = atLeast2(height, top, bottom, centerY)
        if n == 2 || n == 3 {
            doCheckVer()
        }
        checking = false
    }

    private func doCheckVer() {
        if height != UNSPEC && top != UNSPEC {
            bottom = top + height
            centerY = (top + bottom) / 2
            return
        }
        if height != UNSPEC && bottom != UNSPEC {
            top = bottom - height
            centerY = (top + bottom) / 2
            return
        }
        if height != UNSPEC && centerY != UNSPEC {
            top = centerY - height / 2
            bottom = centerY + height / 2
            return
        }

        if top != UNSPEC && bottom != UNSPEC {
            height = bottom - top
            centerY = (top + bottom) / 2
            return
        }
        if top != UNSPEC && centerY != UNSPEC {
            bottom = centerY * 2 - top
            height = bottom - top
            return
        }

        if bottom != UNSPEC && centerY != UNSPEC {
            height = (bottom - centerY) * 2
            top = bottom - height
        }
    }


    private func checkHor() {
        if checking {
            return
        }
        checking = true
        let n = atLeast2(width, left, right, centerX)
        if n == 2 || n == 3 {
            doCheckHor()
        }
        checking = false
    }

    private func doCheckHor() {

        //任意两个决定另外两个
        if width != UNSPEC && left != UNSPEC {
            right = left + width
            centerX = (left + right) / 2
            return
        }
        if width != UNSPEC && right != UNSPEC {
            left = right - width
            centerX = (left + right) / 2
            return
        }
        if width != UNSPEC && centerX != UNSPEC {
            left = centerX - width / 2
            right = centerX + width / 2
            return
        }

        if left != UNSPEC && right != UNSPEC {
            width = right - left
            centerX = (left + right) / 2
            return
        }
        if left != UNSPEC && centerX != UNSPEC {
            right = centerX * 2 - left
            width = right - left
            return
        }

        if right != UNSPEC && centerX != UNSPEC {
            width = (right - centerX) * 2
            left = right - width
        }
    }

    private func atLeast2(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> Int {
        var n = 0
        if a != UNSPEC {
            n += 1
        }
        if b != UNSPEC {
            n += 1
        }
        if c != UNSPEC {
            n += 1
        }
        if d != UNSPEC {
            n += 1
        }
        return n
    }

    func queryProp(_ prop: RelativeProp) -> CGFloat {
        switch prop {
        case .left:
            return left
        case .right:
            return right
        case .top:
            return top
        case .bottom:
            return bottom
        case .centerX:
            return centerX
        case .centerY:
            return centerY
        case .width:
            return width
        case .height:
            return height
        }
    }

    func assignProp(_ prop: RelativeProp, _ value: CGFloat) {
        switch prop {
        case .left:
            left = value
        case .right:
            right = value
        case .top:
            top = value
        case .bottom:
            bottom = value
        case .centerX:
            centerX = value
        case .centerY:
            centerY = value
        case .width:
            width = value
        case .height:
            height = value
        }
    }
}

fileprivate class ViewRects {
    var items: [ViewRect]

    init(_ ls: [View]) {
        items = ls.map {
            ViewRect($0)
        }
    }

    private func byView(_ view: View) -> ViewRect {
        guard  let vr = items.first({
            $0.view == view
        }) else {
            fatalError("Relative Layout Error: relative view \(view) NOT in subviews")
        }
        return vr
    }

    func queryProp(_ view: View, _ prop: RelativeProp) -> CGFloat {
        byView(view).queryProp(prop)
    }

    func assignProp(_ view: View, _ prop: RelativeProp, _ value: CGFloat) {
        byView(view).assignProp(prop, value)
    }
}