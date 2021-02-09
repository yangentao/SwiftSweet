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
        let lb = NSTextField(labelWithString: "Hello")
        lb.wantsLayer = true
        lb.backgroundColor = .red
        lb.textColor = .green
        lb.layer?.backgroundColor = NSColor.red.cgColor

//        let ll = LinearLayout(NSLayoutConstraint.Orientation.vertical)
        view += LinearLayout(.vertical).apply { ll in
            ll.constraints{ c in
                c.centerParent()
                c.width(400)
                c.height(300)
            }
            ll.wantsLayer = true
            ll.layer?.backgroundColor = NSColor.green.cgColor
            for i in 0...4 {
                let lb = NSTextField(labelWithString: "Hello \(i)")
                lb.wantsLayer = true
                lb.backgroundColor = .red
                lb.textColor = .green
                lb.layer?.backgroundColor = NSColor.red.cgColor
                ll += lb.linearParams{ p in
                    p.width = MatchParent
                    p.weight = 1
                    p.margins.ver(1).hor(5)
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
