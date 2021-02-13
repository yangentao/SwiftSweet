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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
       let lb =  view.addView(UILabel(frame: .zero)) { lb in
            lb.constraints{ c in
                c.centerParent().widthParent(constant: -20).heightRatio(multi: 1)
            }
            lb.textAlignment = .center
            lb.text = "Hello"
            lb.backgroundColor = .yellow
            lb.textColor = .red
        }
        //(10000.0, 10000.0) (0.0, 0.0)
        logd( UIView.layoutFittingExpandedSize, UIView.layoutFittingCompressedSize)
        logd(lb.sizeThatFits(UIView.layoutFittingCompressedSize))
        logd(lb.sizeThatFits(UIView.layoutFittingExpandedSize))
        logd(lb.intrinsicContentSize)

        lb.addObserver(self, forKeyPath: "intrinsicContentSize", options: [.new, .old], context: nil)

    }


}
