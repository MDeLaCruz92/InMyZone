//
//  MyTabBarController.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 1/13/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  override var childViewControllerForStatusBarStyle: UIViewController? {
    return nil
  }
}
