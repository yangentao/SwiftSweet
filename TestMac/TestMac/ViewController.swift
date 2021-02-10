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

        let styleText = styledText {
            $0.append("a", .foregroundColor, Color.blue)
            $0.append("b", .backgroundColor, Color.white)
        }


        func label(_ n: Int) -> NSTextField {
            let lb = NSTextField(labelWithString: "Hello \(n)")
            lb.backColor(.red)
            return lb
        }

//        let ll = LinearLayout(NSLayoutConstraint.Orientation.vertical)
        view += LinearLayout(.horizontal).apply { ll in
            ll.constraints { c in
                c.centerParent()
                c.widthParent(multi: 1, constant: -10)
                c.heightParent(multi: 1, constant: -10)
            }
            ll.backColor(.green)
            for i in 1 ... 20 {
                ll += label(i).linearParams { p in
//                    p.width = 0
//                    p.height = 0
                    p.weight = 1
//                    p.gravityX = .fill
//                    p.gravityY = .fill
                    p.margins.ver(5).hor(5)
                }
            }

        }

//        view += lb.constraints { c in
//            c.centerParent()
//            c.widthParent(multi: 1, constant: -20)
//            c.heightParent(multi: 1, constant: -40)
//        }
    }


}
