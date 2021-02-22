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

        textWrap()

//        let lb = NSTextField(labelWithString: "HaHa").constraints{ c in
//            c.centerParent()
//            c.width(38)
//            c.height(16)
//        }.apply { v in
//            logd(v.fittingSize)
//        }
//        view += lb
//        Task.foreDelay(seconds: 2) {
//            logd(lb.fittingSize,  lb.frame, lb.sizeThatFits(.zero))
//        }
//
//        print(lb.sizeThatFits(.zero))

    }

    func textWrap() {
        view += LinearLayout(.horizontal).constraints { c in
            c.centerParent()
            c.widthParent(multi: 1, constant: -10)
            c.heightParent(multi: 1, constant: -10)
        }.apply { ll in
//            ll.backColor(.green)
        }.buildViews {
            NSTextField(labelWithString: "HaHa").linearParams { p in
                p.sizeWrap()
                p.weight = 1
//                p.width = MatchParent
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
