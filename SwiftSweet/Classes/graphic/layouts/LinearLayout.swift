//
// Created by yangentao on 2021/2/1.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif

public extension View {
    var linearParams: LinearParams? {
        get {
            return getAttr("__linearParam__") as? LinearParams
        }
        set {
            setAttr("__linearParam__", newValue)
        }
    }

    var linearParamEnsure: LinearParams {
        if let L = self.linearParams {
            return L
        } else {
            let a = LinearParams()
            self.linearParams = a
            return a
        }
    }

    @discardableResult
    func linearParams(_ width: CGFloat, _ height: CGFloat) -> Self {
        linearParamEnsure.width(width).height(height)
        return self
    }

    @discardableResult
    func linearParams(_ width: CGFloat, _ height: CGFloat, _ block: (LinearParams) -> Void) -> Self {
        let a = linearParamEnsure.width(width).height(height)
        block(a)
        return self
    }

    @discardableResult
    func linearParams(_ block: (LinearParams) -> Void) -> Self {
        block(linearParamEnsure)
        return self
    }
}

public extension LinearLayout {
    @discardableResult
    func appendChild<T: View>(_ view: T, _ width: CGFloat, _ height: CGFloat) -> T {
        view.linearParamEnsure.width(width).height(height)
        addSubview(view)
        return view
    }
}

public class LinearParams: Applyable {

    //weight指Cell的大小,
    //当weight == 0时, cell大小取决于width/height
    @GreatEQ(minValue: 0)
    public var weight: CGFloat = 0


    public var width: CGFloat = 0
    public var height: CGFloat = 0


    public var gravityX: GravityX = .none
    public var gravityY: GravityY = .none

    @GreatEQ(minValue: 0)
    public var minWidth: CGFloat = 0
    @GreatEQ(minValue: 0)
    public var minHeight: CGFloat = 0

    @GreatEQ(minValue: 0)
    public var maxWidth: CGFloat = 0
    @GreatEQ(minValue: 0)
    public var maxHeight: CGFloat = 0

    public var margins: Edge = Edge()

    public init() {

    }

}

public extension LinearParams {
    @discardableResult
    func margins(_ left: CGFloat, _ top: CGFloat, _ right: CGFloat, _ bottom: CGFloat) -> Self {
        self.margins.left = left
        self.margins.top = top
        self.margins.right = right
        self.margins.bottom = bottom
        return self
    }

    @discardableResult
    func margins(_ all: CGFloat) -> Self {
        self.margins.all(all)
        return self
    }

    @discardableResult
    func marginsX(_ hor: CGFloat) -> Self {
        self.margins.hor(hor)
        return self
    }

    @discardableResult
    func marginsY(_ ver: CGFloat) -> Self {
        self.margins.ver(ver)
        return self
    }

    @discardableResult
    func minWidth(_ n: CGFloat) -> Self {
        self.minWidth = n
        return self
    }

    @discardableResult
    func maxWidth(_ n: CGFloat) -> Self {
        self.maxWidth = n
        return self
    }

    @discardableResult
    func minHeight(_ n: CGFloat) -> Self {
        self.minHeight = n
        return self
    }

    @discardableResult
    func maxHeight(_ n: CGFloat) -> Self {
        self.maxHeight = n
        return self
    }

    @discardableResult
    func widthFill() -> Self {
        self.width = MatchParent
        return self
    }

    @discardableResult
    func widthMatch() -> Self {
        self.width = MatchParent
        return self
    }

    #if os(iOS)
    @discardableResult
    func widthWrap() -> Self {
        self.width = WrapContent
        return self
    }

    @discardableResult
    func heightWrap() -> Self {
        self.height = WrapContent
        return self
    }

    @discardableResult
    func sizeWrap() -> Self {
        self.width = WrapContent
        self.height = WrapContent
        return self
    }
    #endif

    @discardableResult
    func heightFill() -> Self {
        self.height = MatchParent
        return self
    }

    @discardableResult
    func heightMatch() -> Self {
        self.height = MatchParent
        return self
    }


    @discardableResult
    func width(_ w: CGFloat) -> Self {
        self.width = w
        return self
    }

    @discardableResult
    func height(_ h: CGFloat) -> Self {
        self.height = h
        return self
    }

    @discardableResult
    func weight(_ w: CGFloat) -> Self {
        self.weight = w
        return self
    }

    @discardableResult
    func gravityX(_ g: GravityX) -> Self {
        self.gravityX = g
        return self
    }

    @discardableResult
    func gravityY(_ g: GravityY) -> Self {
        self.gravityY = g
        return self
    }

    @discardableResult
    func size(_ size: Size) -> Self {
        self.width = size.width
        self.height = size.height
        return self
    }

}

public class LinearLayout: BaseLayout {
    public var axis: LayoutAxis = .vertical {
        didSet {
            postLayout()
        }
    }
    public var padding: Edge = Edge() {
        didSet {
            postLayout()
        }
    }
    //view gravity in cell
    public var defaultGravityX: GravityX = .fill {
        didSet {
            postLayout()
        }
    }
    //view gravity in cell
    public var defaultGravityY: GravityY = .fill {
        didSet {
            postLayout()
        }
    }

    public convenience init(_ axis: LayoutAxis) {
        self.init(frame: .zero)
        self.axis = axis
    }

    @discardableResult
    public func axis(_ ax: LayoutAxis) -> Self {
        self.axis = ax
        return self
    }

    public func paddings(left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat) -> Self {
        padding = Edge(left: left, top: top, right: right, bottom: bottom)
        return self
    }

    public var heightSumFixed: CGFloat {
        let ls = self.subviews
        var total: CGFloat = self.padding.top + self.padding.bottom
        for v in ls {
            if let p = v.linearParams {
                if p.height > 0 {
                    total += p.height
                } else if p.minHeight > 0 {
                    total += p.minHeight
                }
                total += p.margins.top + p.margins.bottom
            }
        }
        return total
    }

    override func layoutChildren() {

        let viewList = self.subviews.filter {
            $0.linearParams != nil
        }
        if viewList.count == 0 {
            return
        }
        let tmpBounds = bounds
        var sz = tmpBounds.size
        sz.width -= padding.left + padding.right
        sz.height -= padding.top + padding.bottom
        let cells: [LinearCell] = viewList.map {
            LinearCell($0)
        }
        if axis == .vertical {

            calcSizesVertical(sz, cells)
            let maxY = calcCellRectVer(cells)
            layoutChildrenVertical(cells)
            contentSize = CGSize(width: tmpBounds.size.width, height: max(0, maxY - tmpBounds.minY))
        } else {
            calcSizesHor(sz, cells)
            let maxX = calcCellRectHor(cells)
            layoutChildrenHor(cells)
            contentSize = CGSize(width: max(0, maxX - tmpBounds.minX), height: tmpBounds.size.height)
        }
    }

    private func calcSizesHor(_ size: CGSize, _ cells: [LinearCell]) {
        #if os(iOS)
        for cell in cells {
            if cell.param.width == WrapContent || cell.param.height == WrapContent {
                cell.wrapSize = cell.view.fitSize(size)
            }
        }
        #endif
        var avaliableWidth = size.width
        var weightSum: CGFloat = 0
        var matchSum = 0

        var weightList: [LinearCell] = []
        var matchList: [LinearCell] = []

        for cell in cells {
            avaliableWidth -= cell.param.margins.left + cell.param.margins.right
            if cell.param.weight > 0 {
                weightSum += cell.param.weight
                weightList += cell
                if cell.param.maxWidth > 0 {
                    assert(cell.param.maxWidth >= cell.param.minWidth)
                }
                continue
            }
            if cell.param.width == MatchParent {
                matchSum += 1
                matchList += cell
                if cell.param.maxWidth > 0 {
                    assert(cell.param.maxWidth >= cell.param.minWidth)
                }
                continue
            }

            if cell.param.width > 0 {
                cell.width = cell.param.width
                avaliableWidth -= cell.width
                continue
            }
            #if os(iOS)
            if cell.param.width == WrapContent {
                cell.width = cell.wrapSize.width
                avaliableWidth -= cell.width
                continue
            }
            #endif

            fatalError("LinearParam.height < 0 ")
        }

        if matchSum > 0 && weightSum > 0 {
            fatalError("LinearParam error , Can not use MatchParent and weight in same time!")
        }

        if weightSum > 0 {
            let ls = weightList.sortedDesc {
                $0.param.minWidth / $0.param.weight
            }
            for cell: LinearCell in ls {
                let p: LinearParams = cell.param
                let w = max(0, avaliableWidth) / weightSum
                let WW = w * p.weight
                if WW < p.minWidth {
                    cell.width = p.minWidth
                } else if p.maxWidth > 0 && p.maxWidth < WW {
                    cell.width = p.maxWidth
                } else {
                    cell.width = WW
                }
                avaliableWidth -= cell.width
                weightSum -= p.weight
            }
        } else if matchSum > 0 {
            let ls = matchList.sortedDesc {
                $0.param.minWidth
            }
            for cell: LinearCell in ls {
                let w = max(0, avaliableWidth) / matchSum
                if w < cell.param.minWidth {
                    cell.width = cell.param.minWidth
                } else if cell.param.maxWidth > 0 && cell.param.maxWidth < w {
                    cell.width = cell.param.maxWidth
                } else {
                    cell.width = w
                }
                avaliableWidth -= cell.width
                matchSum -= 1
            }
        }
    }

    private func calcCellRectHor(_ cells: [LinearCell]) -> CGFloat {

        let Y = bounds.minY + padding.top
        let H = bounds.height - padding.top - padding.bottom
        for cell in cells {
            let m = cell.param.margins
            cell.y = Y + m.top
            cell.height = max(0, H - m.top - m.bottom)
        }
        var fromX = bounds.minX + padding.left
        for cell in cells {
            fromX += cell.param.margins.left
            cell.x = fromX
            cell.width = max(0, cell.width)
            fromX += cell.width + cell.param.margins.right
        }
        return fromX + padding.right
    }

    private func layoutChildrenHor(_ cells: [LinearCell]) {
        logd("HOR: ", bounds)
        for cell in cells {
            let rect = cell.rect
            logd("Cell: ", rect, rect.minX, rect.maxX)
            let p = cell.param
            var gX = p.gravityX
            if gX == .none {
                gX = defaultGravityX
            }
            var gY = p.gravityY
            if gY == .none {
                gY = defaultGravityY
            }
            var x: CGFloat = rect.minX
            var y: CGFloat = rect.minY
            var w: CGFloat = rect.width
            var h: CGFloat = rect.height

            if p.height > 0 {
                h = p.height
            } else if gY == .fill {
                h = rect.height
            } else {
                if p.height == MatchParent {
                    h = rect.height
                } else {
                    #if os(iOS)
                    if p.height == WrapContent {
                        h = cell.wrapSize.height
                    }
                    #endif
                }
            }

            switch gY {
            case .none, .top, .fill:
                y = rect.minY
            case .center:
                y = rect.center.y - h / 2
            case .bottom:
                y = rect.maxY - h
            }


            if p.width > 0 {
                w = p.width
            } else if gX == .fill {
                w = rect.width
            } else {
                if p.width == MatchParent {
                    w = rect.width
                } else {
                    #if os(iOS)
                    if p.width == WrapContent {
                        w = cell.wrapSize.width
                    }
                    #endif
                }
            }

            switch gX {
            case .none, .left, .fill:
                x = rect.minX
            case .center:
                x = rect.center.x - w / 2
            case .right:
                x = rect.maxX - w
            }

            let r = Rect(x: x, y: y, width: w, height: h)
            if cell.view.frame != r {
                cell.view.customLayoutConstraintParams.update(r)
            }
        }

    }

    //=========

    private func calcSizesVertical(_ size: CGSize, _ cells: [LinearCell]) {
        #if os(iOS)
        for cell in cells {
            if cell.param.width == WrapContent || cell.param.height == WrapContent {
                cell.wrapSize = cell.view.fitSize(size)
            }
        }
        #endif

        var avaliableHeight = size.height
        var weightSum: CGFloat = 0
        var matchSum = 0

        var weightList: [LinearCell] = []
        var matchList: [LinearCell] = []

        for cell in cells {
            avaliableHeight -= cell.param.margins.top + cell.param.margins.bottom
            if cell.param.weight > 0 {
                weightSum += cell.param.weight
                weightList += cell
                if cell.param.maxHeight > 0 {
                    assert(cell.param.maxHeight >= cell.param.minHeight)
                }
                continue
            }
            if cell.param.height == MatchParent {
                matchSum += 1
                matchList += cell
                if cell.param.maxHeight > 0 {
                    assert(cell.param.maxHeight >= cell.param.minHeight)
                }
                continue
            }

            if cell.param.height > 0 {
                cell.height = cell.param.height
                avaliableHeight -= cell.height
                continue
            }
            #if os(iOS)
            if cell.param.height == WrapContent {
                cell.height = cell.wrapSize.height
                avaliableHeight -= cell.height
                continue
            }
            #endif

            fatalError("LinearParam.height < 0 ")
        }

        if matchSum > 0 && weightSum > 0 {
            fatalError("LinearParam error , Can not use MatchParent and weight in same time!")
        }

        if weightSum > 0 {
            let ls = weightList.sortedDesc {
                $0.param.minHeight / $0.param.weight
            }
            for cell: LinearCell in ls {
                let p: LinearParams = cell.param
                let h = max(0, avaliableHeight) / weightSum
                let HH = h * p.weight
                if HH < p.minHeight {
                    cell.height = p.minHeight
                } else if p.maxHeight > 0 && p.maxHeight < HH {
                    cell.height = p.maxHeight
                } else {
                    cell.height = HH
                }
                avaliableHeight -= cell.height
                weightSum -= p.weight
            }
        } else if matchSum > 0 {
            let ls = matchList.sortedDesc {
                $0.param.minHeight
            }
            for cell: LinearCell in ls {
                let h = max(0, avaliableHeight) / matchSum
                if h < cell.param.minHeight {
                    cell.height = cell.param.minHeight
                } else if cell.param.maxHeight > 0 && cell.param.maxHeight < h {
                    cell.height = cell.param.maxHeight
                } else {
                    cell.height = h
                }
                avaliableHeight -= cell.height
                matchSum -= 1
            }
        }
    }

    private func calcCellRectVer(_ cells: [LinearCell]) -> CGFloat {
        logd("Bounds.Height: ", self.bounds.height)
        for c in cells {
            logd("Height: ", c.height)
        }


        let X = bounds.minX + padding.left
        let W = bounds.width - padding.left - padding.right
        for cell in cells {
            let m = cell.param.margins
            cell.x = X + m.left
            cell.width = max(0, W - m.left - m.right)
        }
        var fromY = bounds.minY + padding.top
        for cell in cells {
            fromY += cell.param.margins.top
            cell.y = fromY
            cell.height = max(0, cell.height)
            fromY += cell.height + cell.param.margins.bottom
        }
        return fromY + padding.bottom
    }

    private func layoutChildrenVertical(_ cells: [LinearCell]) {

        for cell in cells {
            let rect = cell.rect
            let p = cell.param
            var gX = p.gravityX
            if gX == .none {
                gX = defaultGravityX
            }
            var gY = p.gravityY
            if gY == .none {
                gY = defaultGravityY
            }
            var x: CGFloat = rect.minX
            var y: CGFloat = rect.minY
            var w: CGFloat = rect.width
            var h: CGFloat = rect.height

            if p.width > 0 {
                w = p.width
            } else if gX == .fill {
                w = rect.width
            } else {
                if p.width == MatchParent {
                    w = rect.width
                } else {
                    #if os(iOS)
                    if p.width == WrapContent {
                        w = cell.wrapSize.width
                    }
                    #endif
                }
            }

            switch gX {
            case .none, .left, .fill:
                x = rect.minX
            case .center:
                x = rect.center.x - w / 2
            case .right:
                x = rect.maxX - w
            }

            if p.height > 0 {
                h = p.height
            } else if gY == .fill {
                h = rect.height
            } else {
                if p.height == MatchParent {
                    h = rect.height
                } else {
                    #if os(iOS)
                    if p.height == WrapContent {
                        h = cell.wrapSize.height
                    }
                    #endif
                }
            }

            switch gY {
            case .none, .top, .fill:
                y = rect.minY
            case .center:
                y = rect.center.y - h / 2
            case .bottom:
                y = rect.maxY - h
            }

            let r = Rect(x: x, y: y, width: w, height: h)
            if cell.view.frame != r {
                cell.view.customLayoutConstraintParams.update(r)
            }
        }
    }
}

fileprivate let LINEAR_UNSPEC: CGFloat = -1

fileprivate class LinearCell {
    var view: View
    lazy var param: LinearParams = view.linearParams!
    var x: CGFloat = LINEAR_UNSPEC
    var y: CGFloat = LINEAR_UNSPEC
    var width: CGFloat = LINEAR_UNSPEC
    var height: CGFloat = LINEAR_UNSPEC

    var wrapSize: Size = Size(width: 0, height: 0)

    init(_ view: View) {
        self.view = view
    }

    var rect: Rect {
        return Rect(x: x, y: y, width: width, height: height)
    }
}