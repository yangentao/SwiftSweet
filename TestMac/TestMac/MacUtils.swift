//
// Created by entaoyang@163.com on 2021/2/10.
//

import Foundation
import AppKit

public extension NSView {

    func backColor(_ c: NSColor) -> Self {
        self.wantsLayer = true
        self.layer?.backgroundColor = c.cgColor
        return self
    }
}