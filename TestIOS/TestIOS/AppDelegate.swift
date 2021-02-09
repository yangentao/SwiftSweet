//
//  AppDelegate.swift
//  TestIOS
//
//  Created by yangentao on 2021/2/9.
//
//

import UIKit


private var gWindow: UIWindow? = nil

func WindowRootController(_ c: UIViewController) -> UIWindow {
    if #available(iOS 11.0, *) {
        UINavigationBar.appearance().prefersLargeTitles = false
    }
    let w = UIWindow()
    gWindow = w
    w.frame = UIScreen.main.bounds
    w.rootViewController = c
    w.makeKeyAndVisible()
    return w
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = WindowRootController(ViewController(nibName: nil, bundle: nil))
        return true
    }


}
