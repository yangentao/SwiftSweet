//
//  ViewController.swift
//  TestIOS
//
//  Created by yangentao on 2021/2/9.
//
//

import UIKit
import SwiftSweet

class ViewController: UIViewController {
    lazy var label: UILabel = NamedView(self, "label")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        view += LinearLayout(.vertical).apply { ll in
            ll.constraints { c in
                c.centerParent().widthParent(constant: -20).heightRatio(multi: 1)
            }
            ll.backgroundColor = .blue
            ll += UILabel(frame: .zero).apply { lb in
                lb.named("label")
                lb.textAlignment = .center
                lb.text = "Hello"
                lb.backgroundColor = .yellow
                lb.textColor = .red
                lb.linearParams { p in
                    p.sizeWrap()
                    p.gravityX = .center
                    p.gravityY = .center
                    p.weight = 1
                }
                lb.keepContent(.horizontal)
            }
        }
        Task.foreDelay(seconds: 2) {
            logd(self.label.intrinsicContentSize)
            self.label.text = "Hello Yang "
            logd(self.label.intrinsicContentSize)
            self.label.superview?.setNeedsLayout()
        }

        //(10000.0, 10000.0) (0.0, 0.0)
//        logd( UIView.layoutFittingExpandedSize, UIView.layoutFittingCompressedSize)

    }


}
