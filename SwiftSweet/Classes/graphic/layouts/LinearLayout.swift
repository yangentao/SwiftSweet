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

    @discardableResult
    func widthWrap() -> Self {
        self.width = WrapContent
        return self
    }

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
            let maxY = layoutChildrenVertical(cells)
            contentSize = CGSize(width: tmpBounds.size.width, height: max(0, maxY - tmpBounds.minY))
        } else {
            calcSizesHor(sz, cells)
            let maxX = layoutChildrenHor(cells)
            contentSize = CGSize(width: max(0, maxX - tmpBounds.minX), height: tmpBounds.size.height)
        }
    }

    private func calcSizesHor(_ size: CGSize, _ cells: [LinearCell]) {
        var avaliableWidth = size.width
        var weightSum: CGFloat = 0
        var matchSum = 0

        var weightList: [LinearCell] = []
        var matchList: [LinearCell] = []

        for cell in cells {
            avaliableWidth -= cell.param.margins.left + cell.param.margins.right
            if cell.param.weight > 0 {
                weightSum += cell.param.weight
                avaliableWidth -= cell.param.minWidth
                weightList += cell
                if cell.param.maxWidth > 0 {
                    assert(cell.param.maxWidth >= cell.param.minWidth)
                }
                continue
            }
            if cell.param.width == MatchParent {
                matchSum += 1
                avaliableWidth -= cell.param.minWidth
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
            if cell.param.width == WrapContent {

                let sz = cell.view.fitSize(size)
                cell.width = max(0, sz.width)
                avaliableWidth -= cell.width
                continue
            }

            fatalError("LinearParam.height < 0 ")
        }

        if matchSum > 0 && weightSum > 0 {
            fatalError("LinearParam error , Can not use MatchParent and weight in same time!")
        }
        if matchSum > 0 {
            let ls = matchList.sortedAsc {
                $0.param.maxWidth
            }
            for cell in ls {
                let w = max(0, avaliableWidth) / matchSum
                if cell.param.maxWidth > 0 && cell.param.maxWidth < w {
                    cell.width = cell.param.maxWidth
                } else {
                    cell.width = cell.param.minWidth + w
                }
                avaliableWidth -= cell.width
                matchSum -= 1
            }
        }
        if weightSum > 0 {
            let ls = weightList.sortedAsc {
                $0.param.maxWidth / $0.param.weight
            }
            for cell in ls {
                let w = max(0, avaliableWidth) / weightSum
                let WW = w * cell.param.weight
                if cell.param.maxWidth > 0 && cell.param.maxWidth < WW {
                    cell.width = cell.param.maxWidth
                } else {
                    cell.width = cell.param.minHeight + WW
                }
                avaliableWidth -= cell.width
                weightSum -= cell.param.weight
            }
        }
    }

    private func layoutChildrenHor(_ cells: [LinearCell]) -> CGFloat {
        var fromX = bounds.minX + padding.left

        for cell in cells {
            let param = cell.param
            let HH = bounds.size.height - padding.top - padding.bottom - param.margins.top - param.margins.bottom
            var h: CGFloat = 0
            var gY = param.gravityY
            if gY == .none {
                gY = defaultGravityY
            }
            if param.height == MatchParent || gY == .fill {
                h = HH
            } else if param.height > 0 {
                h = param.height
            } else if param.height == WrapContent {
                let sz = cell.view.fitSize(Size(width: cell.width, height: HH))
                h = sz.height
            } else {
                h = 0
            }
            h = max(0, h)
            cell.height = min(h, HH)

            switch gY {
            case .none, .top, .fill:
                cell.y = bounds.minY + padding.top + param.margins.top
            case .bottom:
                cell.y = bounds.maxY - padding.bottom - param.margins.bottom - cell.height
            case .center:
                cell.y = bounds.center.y - cell.height / 2
            }
            cell.x = fromX + cell.param.margins.left
            let r = cell.rect
            if cell.view.frame != r {
                cell.view.customLayoutConstraintParams.update(r)
            }
            fromX = r.maxX + cell.param.margins.right
        }

        fromX += padding.right
        return fromX
    }

    //=========

    private func calcSizesVertical(_ size: CGSize, _ cells: [LinearCell]) {
        var avaliableHeight = size.height
        var weightSum: CGFloat = 0
        var matchSum = 0

        var weightList: [LinearCell] = []
        var matchList: [LinearCell] = []

        for cell in cells {
            avaliableHeight -= cell.param.margins.top + cell.param.margins.bottom
            if cell.param.weight > 0 {
                weightSum += cell.param.weight
                avaliableHeight -= cell.param.minHeight
                weightList += cell
                if cell.param.maxHeight > 0 {
                    assert(cell.param.maxHeight >= cell.param.minHeight)
                }
                continue
            }
            if cell.param.height == MatchParent {
                matchSum += 1
                avaliableHeight -= cell.param.minHeight
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
            if cell.param.height == WrapContent {
                let sz = cell.view.fitSize(size)
                cell.height = max(0, sz.height)
                avaliableHeight -= cell.height
                continue
            }

            fatalError("LinearParam.height < 0 ")
        }

        if matchSum > 0 && weightSum > 0 {
            fatalError("LinearParam error , Can not use MatchParent and weight in same time!")
        }
        if matchSum > 0 {
            let ls = matchList.sortedAsc {
                $0.param.maxHeight
            }
            for cell in ls {
                let h = max(0, avaliableHeight) / matchSum
                if cell.param.maxHeight > 0 && cell.param.maxHeight < h {
                    cell.height = cell.param.maxHeight
                } else {
                    cell.height = cell.param.minHeight + h
                }
                avaliableHeight -= cell.height
                matchSum -= 1
            }
        }
        if weightSum > 0 {
            let ls = weightList.sortedAsc {
                $0.param.maxHeight / $0.param.weight
            }
            for cell in ls {
                let h = max(0, avaliableHeight) / weightSum
                let HH = h * cell.param.weight
                if cell.param.maxHeight > 0 && cell.param.maxHeight < HH {
                    cell.height = cell.param.maxHeight
                } else {
                    cell.height = cell.param.minHeight + HH
                }
                avaliableHeight -= cell.height
                weightSum -= cell.param.weight
            }
        }
    }

    private func layoutChildrenVertical(_ cells: [LinearCell]) -> CGFloat {
        var fromY = bounds.minY + padding.top

        for cell in cells {
            let param = cell.param
            let WW = bounds.size.width - padding.left - padding.right - param.margins.left - param.margins.right
            var w: CGFloat = 0
            var gX = param.gravityX
            if gX == .none {
                gX = defaultGravityX
            }
            if param.width == MatchParent || gX == .fill {
                w = WW
            } else if param.width > 0 {
                w = param.width
            } else if param.width == WrapContent {
                let sz = cell.view.fitSize(Size(width: WW, height: cell.height))
                w = sz.width
            } else {
                w = 0
            }
            w = max(0, w)
            cell.width = min(w, WW)

            switch gX {
            case .none, .left, .fill:
                cell.x = bounds.minX + padding.left + param.margins.left
            case .right:
                cell.x = bounds.maxX - padding.right - param.margins.right - cell.width
            case .center:
                cell.x = bounds.center.x - cell.width / 2
            }
            cell.y = fromY + cell.param.margins.top
            let r = cell.rect
            if cell.view.frame != r {
                cell.view.customLayoutConstraintParams.update(r)
            }
            fromY = r.maxY + cell.param.margins.bottom
        }

        fromY += padding.bottom
        return fromY
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

    init(_ view: View) {
        self.view = view
    }

    var rect: Rect {
        return Rect(x: x, y: y, width: width, height: height)
    }
}