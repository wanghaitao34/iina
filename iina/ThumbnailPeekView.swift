//
//  ThumbnailPeekView.swift
//  iina
//
//  Created by lhc on 12/6/2017.
//  Copyright © 2017 lhc. All rights reserved.
//

import Cocoa

class ThumbnailPeekView: NSView {

  @IBOutlet var imageView: NSImageView!

  override func awakeFromNib() {
    self.wantsLayer = true
    if #available(macOS 26, *) {
      // Liquid Glass thumbnail preview
      self.layer?.cornerRadius = LiquidGlass.cornerRadiusSmall
      self.layer?.cornerCurve = .continuous
      self.layer?.masksToBounds = false
      self.layer?.borderWidth = LiquidGlass.rimLineWidth
      self.layer?.borderColor = NSColor.white.withAlphaComponent(0.3).cgColor
      self.layer?.shadowRadius = 16
      self.layer?.shadowOffset = CGSize(width: 0, height: -4)
      self.layer?.shadowColor = NSColor.black.cgColor
      self.layer?.shadowOpacity = 0.5
      self.imageView.wantsLayer = true
      self.imageView.layer?.cornerRadius = LiquidGlass.cornerRadiusSmall
      self.imageView.layer?.cornerCurve = .continuous
      self.imageView.layer?.masksToBounds = true
      self.imageView.imageScaling = .scaleAxesIndependently
    } else {
      self.layer?.cornerRadius = 4
      self.layer?.masksToBounds = true
      self.layer?.shadowRadius = 2
      self.layer?.borderWidth = 1
      self.layer?.borderColor = CGColor(gray: 0.6, alpha: 0.5)
      self.imageView.wantsLayer = true
      self.imageView.layer?.cornerRadius = 4
      self.imageView.layer?.masksToBounds = true
      self.imageView.imageScaling = .scaleAxesIndependently
    }
  }

}
