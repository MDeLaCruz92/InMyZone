//
//  AppDelegate.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 12/28/16.
//  Copyright © 2016 Michael De La Cruz. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "DataModel")
    container.loadPersistentStores(completionHandler: {
      storeDescription, error in
      if let error = error {
        fatalError("Could load data source: \(error)")
      }
    })
    return container
  }()
  
  lazy var managedObjectContext: NSManagedObjectContext = self.persistentContainer.viewContext
  
  func listenForCoreDataNotifications() {
    // Tells NotificationCenter that you want to be notified whenever DidFailNotification is posted
    NotificationCenter.default.addObserver(
        forName: MyManagedObjectContextSaveDidFailNotification,
        object: nil, queue: OperationQueue.main, using: { notification in
       
      // Create a UIAlertController to show the error message
      let alert = UIAlertController(
        title: "Internal Error",
        message: "There was a fatal error in the app and it cannot continue. \n\n"
                + "Press OK to terminate the app. Sorry for the inconvenience.",
        preferredStyle: .alert)
          
      // Add an action for the alert's OK button through closure
      let action = UIAlertAction(title: "OK", style: .default) { _ in
        let exception = NSException(
          name: NSExceptionName.internalInconsistencyException,
          reason: "Fatal Core Data error", userInfo: nil)
        exception.raise()
      }
          
      alert.addAction(action)
      
      // presents the alert
      self.viewControllerForShowingAlert().present(alert, animated: true, completion: nil)
    })
  }
  
  // to show the alert with present you need a VC that is currently visible, this method finds one
  func viewControllerForShowingAlert() -> UIViewController {
    let rootViewController = self.window!.rootViewController!
    if let presentViewController = rootViewController.presentedViewController {
      return presentViewController
    } else {
      return rootViewController
    }
  }
  
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    print(applicationDocumentsDirectory)
    
    let tabBarController = window!.rootViewController as! UITabBarController
    
    if let tabBarViewControllers = tabBarController.viewControllers {
      let currentLocationVC = tabBarViewControllers[0] as! CurrentLocationVC
      let navigationController = tabBarViewControllers[1] as! UINavigationController
      let mapViewController = tabBarViewControllers[2] as! MapVC
      mapViewController.managedObjectContext = managedObjectContext
      let locationsViewController = navigationController.viewControllers[0] as! LocationsVC
      
      locationsViewController.managedObjectContext = managedObjectContext
      let _ = locationsViewController.view
      currentLocationVC.managedObjectContext = managedObjectContext
    }
    listenForCoreDataNotifications()
    return true
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  
}

