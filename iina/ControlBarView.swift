//
//  ControlBarView.swift
//  iina
//
//  Created by lhc on 16/7/16.
//  Copyright © 2016 lhc. All rights reserved.
//

import Cocoa

class ControlBarView: NSVisualEffectView {

  @IBOutlet weak var xConstraint: NSLayoutConstraint!
  @IBOutlet weak var yConstraint: NSLayoutConstraint!

  var mousePosRelatedToView: CGPoint?

  var isDragging: Bool = false

  private var isAlignFeedbackSent = false

  override func awakeFromNib() {
    if #available(macOS 26, *) {
      applyLiquidGlassEffect()
    } else {
      applyFrostedGlassEffect()
    }
    self.translatesAutoresizingMaskIntoConstraints = false
  }

  /// Apple-style frosted glass for pre-macOS 26
  private func applyFrostedGlassEffect() {
    material = .hudWindow
    blendingMode = .withinWindow
    state = .active
    self.roundCorners(withRadius: 16)

    wantsLayer = true
    layer?.borderWidth = 0.5
    layer?.borderColor = NSColor.white.withAlphaComponent(0.25).cgColor

    let glassShadow = NSShadow()
    glassShadow.shadowBlurRadius = 20
    glassShadow.shadowOffset = NSSize(width: 0, height: -4)
    glassShadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
    shadow = glassShadow
  }

  @available(macOS 26, *)
  private func applyLiquidGlassEffect() {
    // Aggressive Liquid Glass: full translucent glass with deep depth
    material = .hudWindow
    blendingMode = .withinWindow
    state = .active
    roundCorners(withRadius: LiquidGlass.cornerRadiusLarge)

    // Multi-layer shadow for maximum depth perception
    let outerShadow = NSShadow()
    outerShadow.shadowBlurRadius = 36
    outerShadow.shadowOffset = NSSize(width: 0, height: -10)
    outerShadow.shadowColor = NSColor.black.withAlphaComponent(0.6)
    shadow = outerShadow

    // Hairline glass rim + top specular highlight + inner glow overlay
    let overlay = GlassOverlayView(frame: bounds, cornerRadius: LiquidGlass.cornerRadiusLarge)
    addSubview(overlay)
  }

  override func mouseDown(with event: NSEvent) {
    mousePosRelatedToView = NSEvent.mouseLocation
    mousePosRelatedToView!.x -= frame.origin.x
    mousePosRelatedToView!.y -= frame.origin.y
    isAlignFeedbackSent = abs(frame.origin.x - (window!.frame.width - frame.width) / 2) <= 5
    isDragging = true
  }

  override func mouseDragged(with event: NSEvent) {
    guard let mousePos = mousePosRelatedToView, let windowFrame = window?.frame else { return }
    let currentLocation = NSEvent.mouseLocation
    var newOrigin = CGPoint(
      x: currentLocation.x - mousePos.x,
      y: currentLocation.y - mousePos.y
    )
    // stick to center
    if Preference.bool(for: .controlBarStickToCenter) {
      let xPosWhenCenter = (windowFrame.width - frame.width) / 2
      if abs(newOrigin.x - xPosWhenCenter) <= 5 {
        newOrigin.x = xPosWhenCenter
        if !isAlignFeedbackSent {
          NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
          isAlignFeedbackSent = true
        }
      } else {
        isAlignFeedbackSent = false
      }
    }
    // bound to window frame
    let xMax = windowFrame.width - frame.width - 10
    let yMax = windowFrame.height - frame.height - 25
    newOrigin = newOrigin.constrained(to: NSRect(x: 10, y: 0, width: xMax, height: yMax))
    // apply position
    let newConstraint = newOrigin.x + frame.width / 2
    xConstraint.constant = userInterfaceLayoutDirection == .rightToLeft ?
      windowFrame.width - newConstraint : newConstraint
    yConstraint.constant = newOrigin.y
  }

  override func mouseUp(with event: NSEvent) {
    isDragging = false
    guard let windowFrame = window?.frame else { return }
    // save final position
    Preference.set(xConstraint.constant / windowFrame.width, for: .controlBarPositionHorizontal)
    Preference.set(yConstraint.constant / windowFrame.height, for: .controlBarPositionVertical)
  }

}

// MARK: - Liquid Glass Overlay (macOS 26+)
// Now uses shared GlassOverlayView from LiquidGlassEffect.swift
