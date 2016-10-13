//
//  AppDelegate.swift
//  MCFlashCard
//
//  Created by Thanh Tu on 10/13/16.
//  Copyright © 2016 Thanh Tu. All rights reserved.
//

import UIKit

extension UIStoryboard {
  class func viewController(identifier: String) -> UIViewController {
    return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier)
  }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  
  
  func applicationDidFinishLaunching(_ application: UIApplication) {
    window = UIWindow(frame: UIScreen.main.bounds)
    window!.rootViewController = MCFlashCardNavigationController()
    window!.makeKeyAndVisible()
  }
}

