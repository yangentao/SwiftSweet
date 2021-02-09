//
// Created by yangentao on 2021/2/3.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif


public extension View {
    //不需要指定gridParams, 默认值, 也可以布局, GridLayout有默认的行和列参数
    var gridParams: GridParams {
        get {
            if let p = getAttr("__gridParam__") as? GridParams {
                return p
            }
            let p = GridParams()
            setAttr("__gridParam__", p)
            return p
        }
        set {
            setAttr("__gridParam__", newValue)
        }
    }

    @discardableResult
    func gridParams(_ block: (GridParams) -> Void) -> Self {
        block(gridParams)
        return self
    }
}

public class GridParams: Applyable {

    @GreatEQ(minValue: 1)
    public var columnSpan: Int = 1
    @GreatEQ(minValue: 1)
    public var rowSpan: Int = 1

    @GreatEQ(minValue: 0)
    public var width: CGFloat = 0
    @GreatEQ(minValue: 0)
    public var height: CGFloat = 0
    public var gravityX: GravityX = .none
    public var gravityY: GravityY = .none
    public var margins: Edge = Edge()

}

public extension GridParams {
    func width(_ w: CGFloat) -> Self {
        self.width = w
        return self
    }

    func height(_ h: CGFloat) -> Self {
        self.height = h
        return self
    }
}

//vertical layout only!
public class GridLayout: BaseLayout {
    public var paddings: Edge = Edge() {
        didSet {
            postLayout()
        }
    }

//    public var axis: LayoutAxis = .vertical {
//        didSet {
//            setNeedsLayout()
//        }
//    }

    @GreatEQ(minValue: 1)
    public var columns: Int = 3 {
        didSet {
            postLayout()
        }
    }


    @GreatEQ(minValue: 0)
    public var spaceHor: CGFloat = 0 {
        didSet {
            postLayout()
        }
    }
    @GreatEQ(minValue: 0)
    public var spaceVer: CGFloat = 0 {
        didSet {
            postLayout()
        }
    }


    private var defaultColumnInfo: GridCellInfo = GridCellInfo(value: 0, weight: 1)
    private var defaultRowInfo: GridCellInfo = GridCellInfo(value: 60, weight: 0)
    private var columnInfoMap: [Int: GridCellInfo] = [:]
    private var rowInfoMap: [Int: GridCellInfo] = [:]

    public func setColumnInfoDefault(value: CGFloat, weight: CGFloat) {
        defaultColumnInfo = GridCellInfo(value: value, weight: weight)
        postLayout()
    }

    public func setRowInfoDefault(value: CGFloat, weight: CGFloat) {
        defaultRowInfo = GridCellInfo(value: value, weight: weight)
        postLayout()
    }

    public func setColumnInfo(_ col: Int, value: CGFloat, weight: CGFloat) {
        columnInfoMap[col] = GridCellInfo(value: value, weight: weight)
        postLayout()
    }

    public func setRowInfo(_ row: Int, value: CGFloat, weight: CGFloat) {
        self.rowInfoMap[row] = GridCellInfo(value: value, weight: weight)
        postLayout()
    }

    @discardableResult
    public func spaces(_ hor: CGFloat, _ ver: CGFloat) -> Self {
        self.spaceHor = hor
        self.spaceVer = ver
        return self
    }

    var fixedHeight: CGFloat {
        var fh: CGFloat = paddings.top + paddings.bottom
        let childViews = self.subviews
        if childViews.isEmpty {
            return fh
        }
        let cells: CellMatrix = calcCellsVertical(childViews)
        for r in 0..<cells.rows {
            var rowH: CGFloat = 0
            for c in 0..<cells.cols {
                let cell = cells[r, c]
                if let p = cell?.param {
                    var hh: CGFloat = 0
//                    if p.height > 0 {
//                        hh = p.height
//                    } else {
                    let a = self.rowInfoMap[r] ?? self.defaultRowInfo
                    hh = a.value
//                    }
                    rowH = max(rowH, (hh + p.margins.top + p.margins.bottom))
                }
            }
            fh += rowH
        }
        fh += spaceVer * (cells.rows - 1)
        return fh
    }


    override func layoutChildren() {
        let childViews = self.subviews
        if childViews.isEmpty {
            return
        }
//        if axis == .vertical {
        let cells: CellMatrix = calcCellsVertical(childViews)
        calcWidthsVertical(cells)
        calcHeightsVertical(cells)
        let maxY = calcRectVertical(cells)
        self.contentSize = Size(width: self.bounds.width, height: maxY - self.bounds.minY)
//        } else {

//        }

    }

    private func calcRectVertical(_ cells: CellMatrix) -> CGFloat {
        var maxY: CGFloat = self.bounds.minY

        for row in 0..<cells.rows {
            var y: CGFloat = paddings.top
            for i in 0..<row {
                y += (cells[i, 0]?.height ?? 0) + spaceVer
            }
            for col in 0..<cells.cols {
                guard let cell = cells[row, col], let view = cell.view else {
                    continue
                }
                if col > 0 && cell.view === cells[row, col - 1]?.view {
                    continue
                }
                if row > 0 && cell.view === cells[row - 1, col]?.view {
                    continue
                }
                let param = view.gridParams
                var x: CGFloat = paddings.left // (cell.width + hSpace) * cell.view.gridParams!.spanColumns
                for i in 0..<col {
                    x += (cells[row, i]?.width ?? 0) + spaceHor
                }

                var ww: CGFloat = 0
                for c in col..<(col + param.columnSpan) {
                    ww += cells[row, c]?.width ?? 0
                    ww += spaceHor
                }
                ww -= spaceHor

                var hh: CGFloat = 0
                for r in row..<(row + param.rowSpan) {
                    hh += cells[r, col]?.height ?? 0
                    hh += spaceHor
                }
                hh -= spaceHor
//                let h = (cell.height + vSpace) * param.spanRows - vSpace
                let rect = Rect(x: x, y: y, width: ww, height: hh)
                if let view = cell.view {
                    let rect = placeView(view, rect, row, col)
                    view.customLayoutConstraintParams.update(rect)
//                    view.frame = rect
                }
                maxY = max(maxY, rect.maxY)
            }
        }
        return maxY
    }

    private func placeView(_ view: View, _ rect: Rect, _ row: Int, _ col: Int) -> Rect {
        let param = view.gridParams
        let x: CGFloat
        let y: CGFloat
        let w: CGFloat
        let h: CGFloat

        switch param.gravityX {
        case .none, .fill:
            w = rect.width
            x = rect.minX
            break
        case .left:
            if param.width > 0 {
                w = param.width
            } else {
                let a = self.columnInfoMap[col] ?? self.defaultColumnInfo
                w = a.value
            }
            x = rect.minX
        case .right:
            if param.width > 0 {
                w = param.width
            } else {
                let a = self.columnInfoMap[col] ?? self.defaultColumnInfo
                w = a.value
            }
            x = rect.maxX - w
            break
        case .center:
            if param.width > 0 {
                w = param.width
            } else {
                let a = self.columnInfoMap[col] ?? self.defaultColumnInfo
                w = a.value
            }
            x = rect.center.x - w / 2
            break
        }
        switch param.gravityY {
        case .none, .fill:
            h = rect.height
            y = rect.minY
        case .top:
            if param.height > 0 {
                h = param.height
            } else {
                let a = self.rowInfoMap[row] ?? self.defaultRowInfo
                h = a.value
            }
            y = rect.minY
        case .bottom:
            if param.height > 0 {
                h = param.height
            } else {
                let a = self.rowInfoMap[row] ?? self.defaultRowInfo
                h = a.value
            }
            y = rect.maxY - h
        case .center:
            if param.height > 0 {
                h = param.height
            } else {
                let a = self.rowInfoMap[row] ?? self.defaultRowInfo
                h = a.value
            }
            y = rect.center.y - h / 2
        }
        var r = Rect(x: x, y: y, width: w, height: h)
        r.origin.x += param.margins.left
        r.origin.y += param.margins.top
        r.size.width -= param.margins.left + param.margins.right
        r.size.height -= param.margins.top + param.margins.bottom
        return r
    }

    private func calcHeightsVertical(_ cells: CellMatrix) {
        var rowInfos: [GridCellInfo] = .init(repeating: GridCellInfo(other: defaultRowInfo), count: cells.rows)
        for (k, v) in self.rowInfoMap {
            rowInfos[k] = v
        }

        let totalValue: CGFloat = self.bounds.height - self.spaceVer * (cells.rows - 1) - paddings.top - paddings.bottom
        var weightSum: CGFloat = 0
        var ls: [GridCellInfo] = []
        var ls2: [GridCellInfo] = []
        var leftValue: CGFloat = totalValue

        for r in 0..<cells.rows {
            let info = rowInfos[r]
            info.realValue = GRID_UNSPEC
            if info.weight > 0 {
                weightSum += info.weight
                if info.value > 0 {
                    ls += info
                } else {
                    ls2 += info
                }
            } else {
                info.realValue = info.value
                leftValue -= info.value
            }
        }
        for info in ls.sortedAsc({ $0.value }) {
            let v = leftValue * info.weight / weightSum
            if v < info.value {
                info.realValue = info.value
            } else {
                info.realValue = v
            }
            leftValue -= info.realValue
            weightSum -= info.weight
        }
        for info in ls2 {
            info.realValue = leftValue * info.weight / weightSum
        }
        for row in 0..<cells.rows {
            for col in 0..<cells.cols {
                cells[row, col]?.height = rowInfos[row].realValue
            }
        }
    }


    private func calcWidthsVertical(_ cells: CellMatrix) {
        var columnInfos: [GridCellInfo] = .init(repeating: GridCellInfo(other: defaultColumnInfo), count: cells.cols)
        for (k, v) in self.columnInfoMap {
            columnInfos[k] = v
        }

        let totalValue: CGFloat = self.bounds.width - self.spaceHor * (self.columns - 1) - paddings.left - paddings.right
        var leftValue: CGFloat = totalValue

        var weightSum: CGFloat = 0
        var ls: [GridCellInfo] = []
        var ls2: [GridCellInfo] = []

        for c in 0..<self.columns {
            let info = columnInfos[c]
            info.realValue = GRID_UNSPEC
            if info.weight > 0 {
                weightSum += info.weight
                if info.value > 0 {
                    ls += info
                } else {
                    ls2 += info
                }
            } else {
                info.realValue = info.value
                leftValue -= info.value
            }
        }
        // weight > 0 and value > 0
        for info in ls.sortedAsc({ $0.value }) {
            let v = leftValue * info.weight / weightSum
            if v < info.value {
                info.realValue = info.value
            } else {
                info.realValue = v
            }
            leftValue -= info.realValue
            weightSum -= info.weight
        }
        for info in ls2 {
            info.realValue = leftValue * info.weight / weightSum
        }


        for row in 0..<cells.rows {
            for col in 0..<cells.cols {
                cells[row, col]?.width = columnInfos[col].realValue
            }
        }
    }


    private func calcCellsVertical(_ viewList: [View]) -> CellMatrix {
        let cellMatrix = CellMatrix(cols: self.columns)
        var row = 0
        var col = 0
        for v in viewList {
            pos(v, matrix: cellMatrix, row: &row, col: &col)
        }
        return cellMatrix
    }

    private func pos(_ v: View, matrix: CellMatrix, row: inout Int, col: inout Int) {
        let param = v.gridParams
        while matrix[row, col] != nil {
            col += 1
            if col >= self.columns {
                row += 1
                col = 0
            }
        }
        let colSpan = min(self.columns, param.columnSpan)
        if col == 0 || col + colSpan - 1 < self.columns {
            for r in 0..<param.rowSpan {
                for c in 0..<colSpan {
                    matrix[row + r, col + c] = CellItem(v)
                }
            }
            return
        }
        matrix[row, col] = CellItem(nil)
        col += 1
        if col >= self.columns {
            row += 1
            col = 0
        }
        pos(v, matrix: matrix, row: &row, col: &col)

    }
}

fileprivate class CellItem {
    var view: View?
    lazy var param: GridParams? = view?.gridParams
    var left: CGFloat = 0
    var right: CGFloat = 0
    var width: CGFloat = 0
    var height: CGFloat = 0


    init(_ v: View?) {
        self.view = v
    }
}

fileprivate let GRID_UNSPEC: CGFloat = -1

public class GridCellInfo {
    @GreatEQ(minValue: 0)
    public var weight: CGFloat = 0
    @GreatEQ(minValue: 0)
    public var value: CGFloat = 0

    fileprivate var realValue: CGFloat = GRID_UNSPEC

    public init(value: CGFloat, weight: CGFloat) {
        self.value = value
        self.weight = weight
    }

    public convenience init(other: GridCellInfo) {
        self.init(value: other.value, weight: other.weight)
    }
}


fileprivate struct Coords: Hashable {
    let row: Int
    let col: Int
}

fileprivate class CellMatrix {
    var map: [Coords: CellItem] = [:]

    let cols: Int

    init(cols: Int) {
        assert(cols > 0)
        self.cols = cols
    }

    var rows: Int {
        if let a = map.keySet.max(by: { a, b in
            a.row < b.row
        }) {
            return a.row + 1
        }
        return 0
    }

    subscript(row: Int, col: Int) -> CellItem? {
        get {
            return map[Coords(row: row, col: col)]
        }
        set {
            map[Coords(row: row, col: col)] = newValue
        }
    }
}
