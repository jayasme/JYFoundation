//
//  JYBlurView.swift
//  JYFoundation
//
//  Created by 荣超 on 2021/12/31.
//  Copyright © 2021 jayasme. All rights reserved.
//

import Foundation
import UIKit

class JYBlurView: UIVisualEffectView {
  
  convenience init(style: UIBlurEffect.Style) {
      let blurEffect = UIBlurEffect(style: style)
      self.init(effect: blurEffect)
      self.translatesAutoresizingMaskIntoConstraints = false
      self.backgroundColor = UIColor(white: 0, alpha: 0)
  }
}
