//
//  VolumeSliderCell.swift
//  iina
//
//  Created by lhc on 26/7/16.
//  Copyright © 2016 lhc. All rights reserved.
//

import Cocoa

class VolumeSliderCell: NSSliderCell {

  override func awakeFromNib() {
    minValue = 0
    maxValue = Double(Preference.integer(for: .maxVolume))
  }

  override func drawKnob(_ knobRect: NSRect) {
    if isHighlighted {
      // Dragging: liquid glass knob using native compositing
      let knobDiameter: CGFloat = knobRect.height * 0.85
      let knobX = knobRect.origin.x + (knobRect.width - knobDiameter) / 2
      let knobY = knobRect.origin.y + (knobRect.height - knobDiameter) / 2
      let rect = NSRect(x: knobX, y: knobY, width: knobDiameter, height: knobDiameter)
      let path = NSBezierPath(ovalIn: rect)

      guard let ctx = NSGraphicsContext.current?.cgContext else { return }

      // Glass base — no shadow
      NSColor.white.withAlphaComponent(0.55).setFill()
      path.fill()

      // Additive glass brightening using screen blend
      ctx.saveGState()
      ctx.setBlendMode(.plusLighter)
      NSColor.white.withAlphaComponent(0.15).setFill()
      path.fill()
      ctx.restoreGState()

      // Top specular highlight
      let highlightDiameter = knobDiameter * 0.5
      let highlightRect = NSRect(x: rect.midX - highlightDiameter / 2,
                                  y: rect.midY,
                                  width: highlightDiameter,
                                  height: highlightDiameter * 0.4)
      let highlightPath = NSBezierPath(ovalIn: highlightRect)
      NSColor.white.withAlphaComponent(0.4).setFill()
      highlightPath.fill()

      // Crisp glass edge
      NSColor.white.withAlphaComponent(0.7).setStroke()
      path.lineWidth = 0.6
      path.stroke()
    } else {
      // Normal: default white knob, no extra shadow
      super.drawKnob(knobRect)
    }
  }

  override func drawBar(inside rect: NSRect, flipped: Bool) {
    NSGraphicsContext.saveGraphicsState()
    if maxValue > 100 {
      // round this value to obtain a pixel perfect clip line
      let x = round(rect.minX + rect.width * CGFloat(100 / maxValue))
      let clipPath = NSBezierPath(rect: NSRect(x: rect.minX, y: rect.minY, width: x - 1, height: rect.height))
      clipPath.append(NSBezierPath(rect: NSRect(x: x + 1, y: rect.minY, width: rect.maxX - x - 1, height: rect.height)))
      clipPath.setClip()
    }
    super.drawBar(inside: rect, flipped: flipped)
    NSGraphicsContext.restoreGraphicsState()
  }

}
