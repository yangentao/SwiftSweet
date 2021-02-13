//
// Created by entaoyang@163.com on 2017/10/18.
// Copyright (c) 2017 yet.net. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif

public let SelfViewName = "__.__"
public let ParentViewName = "__..__"
public let MatchParent: CGFloat = -1

public let WrapContent: CGFloat = -2

extension CGFloat {
    var geZero: CGFloat {
        if self < 0 {
            return 0
        }
        return self
    }
}

public func Max(_ a: CGFloat, _ items: CGFloat?...) -> CGFloat {
    max(a, items.compactMap({ $0 ?? nil }).max() ?? a)
}

public class SysConstraintParams {
    var items = [NSLayoutConstraint]()

    func removeByID(_ ident: String) {
        let a = items.removeFirstIf {
            $0.identifier == ident
        }
        a?.isActive = false
    }
}

public extension View {
    var sysConstraintParams: SysConstraintParams {
        if let ls = getAttr("_conkey_") as? SysConstraintParams {
            return ls
        }
        let c = SysConstraintParams()
        setAttr("_conkey_", c)
        return c
    }

    @discardableResult
    func constraintUpdate(ident: String, constant: CGFloat) -> Self {
        if let a = sysConstraintParams.items.first({ $0.identifier == ident }) {
            a.constant = constant
            postUpdateContraints()
            superview?.postUpdateContraints()
        }
        return self
    }

    func constraintRemoveAll() {
        for c in sysConstraintParams.items {
            c.isActive = false
        }
        sysConstraintParams.items = []
    }

    func constraintRemove(_ ident: String) {
        sysConstraintParams.removeByID(ident)
    }

    //resist larger than intrinsic content size
    @discardableResult
    func stretchContent(_ axis: LayoutAxis) -> Self {
        setContentHuggingPriority(LayoutPriority(rawValue: LayoutPriority.defaultLow.rawValue - 1), for: axis)
        return self
    }

    //resist smaller than intrinsic content size
    @discardableResult
    func keepContent(_ axis: LayoutAxis) -> Self {
        setContentCompressionResistancePriority(LayoutPriority(rawValue: LayoutPriority.defaultHigh.rawValue + 1), for: axis)
        return self
    }

    @available(macOS 11.0, *)
    @discardableResult
    func topAnchorParentSafeArea() -> Self {
        self.topAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.topAnchor).isActive = true
        return self
    }

    @available(macOS 11.0, *)
    @discardableResult
    func bottomAnchorParentSafeArea() -> Self {
        self.bottomAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.bottomAnchor).isActive = true
        return self
    }
}

public extension View {

    @discardableResult
    func buildViews(@AnyBuilder _ block: AnyBuildBlock) -> Self {
        let b = block()
        let viewList: [View] = b.itemsTyped(true).filter {
            $0 !== self
        }
        viewList.each {
            addSubview($0)
        }
        viewList.each {
            $0.installSelfConstraints()
        }
        return self
    }

    @discardableResult
    static func ++=(lhs: View, @AnyBuilder _ rhs: AnyBuildBlock) -> View {
        lhs.buildViews(rhs)
    }

    @discardableResult
    static func ++=(lhs: View, rhs: View) -> View {
        lhs.addSubview(rhs)
        rhs.installSelfConstraints()
        return lhs
    }

    @discardableResult
    static func +=(lhs: View, rhs: View) -> View {
        lhs.addSubview(rhs)
        rhs.installSelfConstraints()
        return lhs
    }
}

public enum GravityX: Int {
    case none = 0
    case left
    case right
    case center
    case fill
}

public enum GravityY: Int {
    case none = 0
    case top
    case bottom
    case center
    case fill
}

public class Edge: Equatable, Codable {
    public var left: CGFloat
    public var right: CGFloat
    public var top: CGFloat
    public var bottom: CGFloat

    public init(left: CGFloat = 0, top: CGFloat = 0, right: CGFloat = 0, bottom: CGFloat = 0) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }
}

public extension Edge {
    @discardableResult
    func all(_ v: CGFloat) -> Edge {
        self.left = v
        self.right = v
        self.top = v
        self.bottom = v
        return self
    }

    @discardableResult
    func hor(_ lr: CGFloat) -> Edge {
        self.left = lr
        self.right = lr
        return self
    }

    @discardableResult
    func ver(_ tb: CGFloat) -> Edge {
        self.top = tb
        self.bottom = tb
        return self
    }

    var edgeInsets: EdgeInsets {
        return EdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }

    static let zero: Edge = Edge()

    static func from(_ edgeInsets: EdgeInsets) -> Edge {
        return Edge(left: edgeInsets.left, top: edgeInsets.top, right: edgeInsets.right, bottom: edgeInsets.bottom)
    }

    static func ==(lhs: Edge, rhs: Edge) -> Bool {
        return lhs.left == rhs.left && lhs.right == rhs.right && lhs.top == rhs.right && lhs.bottom == rhs.bottom
    }

}

internal class CustomLayoutConstraintParams {
    unowned let view: View
    private var map: [LayoutAttribute: NSLayoutConstraint] = [:]

    init(_ view: View) {
        self.view = view
    }

    private func update(_ attr: LayoutAttribute, _ value: CGFloat) {

        var changed = false
        switch attr {
        case .left, .top:
            if map[attr]?.constant != value {
                logd("UpdateXY: ", attr, map[attr]?.constant, value)
                map[attr]?.isActive = false
                map[attr] = NSLayoutConstraint(item: view, attribute: attr, relatedBy: .equal, toItem: view.superview, attribute: attr, multiplier: 1, constant: value)
                map[attr]?.isActive = true
                changed = true
            }
        case .width, .height:
            if map[attr]?.constant != value {
                logd("Update, W?: ", attr == .width, " H:?", attr == .height, " oldValue: ", map[attr]?.constant, " newValue:", value, view.frame)
                map[attr]?.isActive = false
                map[attr] = NSLayoutConstraint(item: view, attribute: attr, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: value)
                map[attr]?.isActive = true
                changed = true
            }
        default:
            break
        }
        if changed {
            Task.foreDelay(seconds: 0) { [weak self] in
                self?.view.superview?.postLayout()
            }
        }
    }

    func update(_ rect: Rect) {
        if view.superview != nil {
            update(.left, rect.minX)
            update(.top, rect.minY)
        }
        update(.width, rect.width)
        update(.height, rect.height)
    }

}

internal extension View {
    var customLayoutConstraintParams: CustomLayoutConstraintParams {
        if let ls = getAttr("_CustomLayoutLinearConstraintParams_") as? CustomLayoutConstraintParams {
            return ls
        }
        let c = CustomLayoutConstraintParams(self)
        setAttr("_CustomLayoutLinearConstraintParams_", c)
        return c
    }
}

public class BaseLayout: View {

    public internal (set) var contentSize: CGSize = .zero {
        didSet {
            if oldValue != contentSize {
                processScroll()
            }
        }
    }
    public override class var requiresConstraintBasedLayout: Bool {
        true
    }

    public override func addSubview(_ view: View) {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.autoresizesSubviews = false
        super.addSubview(view)
    }

    #if os(iOS)
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        processScroll()
    }
    #else
    public override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        processScroll()
    }
    #endif

    private func processScroll() {
        if let pv = self.superview as? XScrollView {
            #if os(iOS)
            pv.contentSize = contentSize
            #endif
        }
    }

    #if os(iOS)
    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds.width == 0 && self.bounds.height == 0 {
            return
        }
        layoutChildren()
    }
    #else
    public override func layout() {
        super.layout()
        if self.bounds.width == 0 && self.bounds.height == 0 {
            return
        }
        layoutChildren()
    }
    #endif

    internal func layoutChildren() {

    }

}
