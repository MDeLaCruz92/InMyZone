//
//  String+AddText.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 1/13/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import Foundation

extension String {
  mutating func add(text: String?, separatedBy separator: String = "") {
    if let text = text {
      if !isEmpty {
        self += separator
      }
      self += text
    }
  }
}
