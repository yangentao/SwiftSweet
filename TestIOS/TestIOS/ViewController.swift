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
        print("Hello")
        view.backgroundColor = .green
        view.addView(UILabel(frame: .zero)) { lb in
            lb.constraints{ c in
                c.centerParent().widthParent(constant: -20).heightRatio(multi: 1)
            }
            lb.textAlignment = .center
            lb.text = "Hello"
            lb.backgroundColor = .yellow
            lb.textColor = .red
        }
    }


}
