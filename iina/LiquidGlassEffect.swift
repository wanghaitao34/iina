//
//  LiquidGlassEffect.swift
//  iina
//
//  Provides centralized Liquid Glass styling utilities for macOS 26+ (Tahoe).
//  On older systems, these helpers gracefully fall back to the existing appearance.
//

import Cocoa

// MARK: - Liquid Glass Constants

/// Central design tokens for the Liquid Glass effect throughout IINA.
enum LiquidGlass {
  // Corner radii
  static let cornerRadiusLarge: CGFloat = 22
  static let cornerRadiusMedium: CGFloat = 16
  static let cornerRadiusSmall: CGFloat = 12
  static let cornerRadiusMini: CGFloat = 8

  // Shadow
  static let shadowBlurRadius: CGFloat = 28
  static let shadowOffset = NSSize(width: 0, height: -8)
  static let shadowColor = NSColor.black.withAlphaComponent(0.55)

  // Rim border
  static let rimLineWidth: CGFloat = 0.8
  static let rimColor = NSColor.white.withAlphaComponent(0.38)

  // Specular highlight
  static let specularTopAlpha: CGFloat = 0.16
  static let specularBottomAlpha: CGFloat = 0.0

  // Inner glow
  static let innerGlowColor = NSColor.white.withAlphaComponent(0.06)
}

// MARK: - Glass Overlay View

/// A passthrough overlay that renders the glass rim border and top specular highlight.
/// Used by all Liquid Glass surfaces. Returns nil from `hitTest` to never intercept events.
@available(macOS 26, *)
class GlassOverlayView: NSView {

  var cornerRadius: CGFloat

  override var isOpaque: Bool { false }

  init(frame: NSRect, cornerRadius: CGFloat = LiquidGlass.cornerRadiusLarge) {
    self.cornerRadius = cornerRadius
    super.init(frame: frame)
    self.autoresizingMask = [.width, .height]
  }

  required init?(coder: NSCoder) {
    self.cornerRadius = LiquidGlass.cornerRadiusLarge
    super.init(coder: coder)
    self.autoresizingMask = [.width, .height]
  }

  override func draw(_ dirtyRect: NSRect) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }

    let insetRect = bounds.insetBy(dx: LiquidGlass.rimLineWidth / 2, dy: LiquidGlass.rimLineWidth / 2)
    let path = CGPath(roundedRect: insetRect,
                      cornerWidth: cornerRadius,
                      cornerHeight: cornerRadius,
                      transform: nil)

    // Top specular highlight — white glint fading from top to centre
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradColors = [
      NSColor.white.withAlphaComponent(LiquidGlass.specularTopAlpha).cgColor,
      NSColor.white.withAlphaComponent(LiquidGlass.specularBottomAlpha).cgColor,
    ] as CFArray
    let locations: [CGFloat] = [0, 1]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradColors, locations: locations) {
      ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: bounds.midX, y: bounds.maxY),
        end: CGPoint(x: bounds.midX, y: bounds.midY),
        options: []
      )
    }
    ctx.restoreGState()

    // Hairline glass rim border
    ctx.setStrokeColor(LiquidGlass.rimColor.cgColor)
    ctx.setLineWidth(LiquidGlass.rimLineWidth)
    ctx.addPath(path)
    ctx.strokePath()
  }

  override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

// MARK: - NSVisualEffectView extensions

extension NSVisualEffectView {

  /// Apply full Liquid Glass treatment on macOS 26+, with fallback for older systems.
  func applyLiquidGlass(cornerRadius: CGFloat = LiquidGlass.cornerRadiusLarge,
                        addOverlay: Bool = true,
                        addShadow: Bool = true) {
    if #available(macOS 26, *) {
      material = .hudWindow
      blendingMode = .withinWindow
      state = .active
      roundCorners(withRadius: cornerRadius)

      if addShadow {
        let glsShadow = NSShadow()
        glsShadow.shadowBlurRadius = LiquidGlass.shadowBlurRadius
        glsShadow.shadowOffset = LiquidGlass.shadowOffset
        glsShadow.shadowColor = LiquidGlass.shadowColor
        shadow = glsShadow
      }

      if addOverlay {
        // Remove existing glass overlays to avoid duplication
        subviews.filter { $0 is GlassOverlayView }.forEach { $0.removeFromSuperview() }
        let overlay = GlassOverlayView(frame: bounds, cornerRadius: cornerRadius)
        addSubview(overlay)
      }
    } else {
      roundCorners(withRadius: max(cornerRadius / 3, 6))
    }
  }

  /// Apply a lighter Liquid Glass for sidebar/panel backgrounds.
  func applyLiquidGlassPanel(cornerRadius: CGFloat = LiquidGlass.cornerRadiusSmall) {
    if #available(macOS 26, *) {
      material = .sidebar
      blendingMode = .behindWindow
      state = .active
      roundCorners(withRadius: cornerRadius)

      // Subtle inner glow
      wantsLayer = true
      layer?.borderWidth = 0.5
      layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
    }
  }

  /// Apply Liquid Glass for HUD-style overlays (OSD, buffer, info display).
  func applyLiquidGlassHUD(cornerRadius: CGFloat = LiquidGlass.cornerRadiusMedium,
                            addOverlay: Bool = true) {
    if #available(macOS 26, *) {
      material = .hudWindow
      blendingMode = .withinWindow
      state = .active
      roundCorners(withRadius: cornerRadius)

      // Floating HUD shadow
      let hudShadow = NSShadow()
      hudShadow.shadowBlurRadius = 20
      hudShadow.shadowOffset = NSSize(width: 0, height: -4)
      hudShadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
      shadow = hudShadow

      if addOverlay {
        subviews.filter { $0 is GlassOverlayView }.forEach { $0.removeFromSuperview() }
        let overlay = GlassOverlayView(frame: bounds, cornerRadius: cornerRadius)
        addSubview(overlay)
      }
    } else {
      roundCorners(withRadius: 10)
    }
  }
}

// MARK: - NSWindow extensions for Liquid Glass

extension NSWindow {

  /// Configure a window for Liquid Glass toolbar appearance on macOS 26+.
  func applyLiquidGlassToolbar() {
    if #available(macOS 26, *) {
      titlebarAppearsTransparent = true
      titlebarSeparatorStyle = .none
      toolbarStyle = .unified
    }
  }

  /// Configure a window with full-content glass background.
  func applyLiquidGlassWindow() {
    if #available(macOS 26, *) {
      titlebarAppearsTransparent = true
      titlebarSeparatorStyle = .none
      isMovableByWindowBackground = true

      // Enable the full-height content view behind the titlebar
      if !styleMask.contains(.fullSizeContentView) {
        styleMask.insert(.fullSizeContentView)
      }
    }
  }
}

// MARK: - NSView Liquid Glass helpers

extension NSView {

  /// Add a glass morphism background layer to any view.
  func addGlassBackground(cornerRadius: CGFloat = LiquidGlass.cornerRadiusMedium,
                           fillColor: NSColor = NSColor.white.withAlphaComponent(0.08)) {
    if #available(macOS 26, *) {
      wantsLayer = true
      layer?.cornerRadius = cornerRadius
      layer?.cornerCurve = .continuous
      layer?.backgroundColor = fillColor.cgColor
      layer?.borderWidth = 0.5
      layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
    }
  }

  /// Remove any glass background styling.
  func removeGlassBackground() {
    layer?.backgroundColor = nil
    layer?.borderWidth = 0
    layer?.borderColor = nil
  }
}

// MARK: - NSButton Liquid Glass styling

extension NSButton {

  /// Style a button with Liquid Glass pill/capsule appearance.
  func applyLiquidGlassButtonStyle() {
    if #available(macOS 26, *) {
      wantsLayer = true
      layer?.cornerRadius = bounds.height / 2
      layer?.cornerCurve = .continuous
      layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
      layer?.borderWidth = 0.5
      layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
    }
  }
}
