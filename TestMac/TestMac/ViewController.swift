//
//  ViewController.swift
//  TestMac
//
//  Created by yangentao on 2021/2/9.
//
//

import Cocoa
import AppKit
import SwiftSweet

class ViewController: NSViewController {

    override func loadView() {
        self.view = NSView(frame: Rect(x: 100, y: 100, width: 800, height: 500))
    }

    override func viewDidLoad() {
        super.viewDidLoad()


        view += LinearLayout(.horizontal).constraints { c in
            c.centerParent()
            c.widthParent(multi: 1, constant: -10)
            c.heightParent(multi: 1, constant: -10)
        }.apply { ll in
//            ll.backColor(.green)
        }.buildViews {
            NSTextField(labelWithString: "HaHa").linearParams { p in
                p.weight = 1
                p.width = MatchParent
                p.gravityX = .center
                p.gravityY = .center
            }.apply { v in
                v.backColor(.green)
                v.textColor = .red
                v.alignment = .center
            }
        }

    }


}
