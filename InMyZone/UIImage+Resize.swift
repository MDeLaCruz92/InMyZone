//
//  UIImage+Resize.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 1/9/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import UIKit

// calculates how big the image can be in order to fit inside the bounds rectangle.
extension UIImage {
  func resizedImage(withBounds bounds: CGSize) -> UIImage {
    let horizontalRatio = bounds.width / size.width
    let verticalRatio = bounds.height / size.height
    let ratio = min(horizontalRatio, verticalRatio)
    let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
    
    UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
    draw(in: CGRect(origin: CGPoint.zero, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
}
