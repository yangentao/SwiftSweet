//
// Created by entaoyang@163.com on 2021/2/9.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif

#if os(iOS) || os(tvOS)
public typealias Color = UIColor
public typealias Font = UIFont
public typealias View = UIView
public typealias LayoutPriority = UILayoutPriority
public typealias LayoutAxis = NSLayoutConstraint.Axis
public typealias EdgeInsets = UIEdgeInsets
public typealias XViewController = UIViewController
public typealias XScrollView = UIScrollView
public typealias XScreen = UIScreen
#else
public typealias Color = NSColor
public typealias Font = NSFont
public typealias View = NSView
public typealias LayoutPriority = NSLayoutConstraint.Priority
public typealias LayoutAxis = NSLayoutConstraint.Orientation
public typealias EdgeInsets = NSEdgeInsets
public typealias XViewController = NSViewController
public typealias XScrollView = NSScrollView
public typealias XScreen = NSScreen
#endif

public typealias LayoutRelation = NSLayoutConstraint.Relation
public typealias LayoutAttribute = NSLayoutConstraint.Attribute


extension View {
    func fitSize(_ size: Size) -> CGSize {
        #if os(iOS)
        return sizeThatFits(size)
        #else
        return fittingSize
        #endif
    }

    func postUpdateContraints() {
        #if os(iOS)
        setNeedsUpdateConstraints()
        #else
        needsUpdateConstraints = true
        #endif
    }

    func postLayout() {
        #if os(iOS)
        setNeedsLayout()
        #else
        self.needsLayout = true
        #endif
    }
}