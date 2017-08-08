//
//  Functions.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 1/2/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import Foundation
import Dispatch

let applicationDocumentsDirectory: URL = {
  let paths = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                                       in: FileManager.SearchPathDomainMask.userDomainMask)
  return paths[0]
}()

let MyManagedObjectContextSaveDidFailNotification = Notification.Name(
              rawValue: "MyManagedObjectContextSaveDidFailNotification")

func fatalCoreDataError(_ error: Error) {
  print("*** Fatal error: \(error)")
  NotificationCenter.default.post(name: MyManagedObjectContextSaveDidFailNotification, object: nil)
}

func afterDelay(_ seconds: Double, closure: @escaping () -> ()) {
  DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: closure)
}
