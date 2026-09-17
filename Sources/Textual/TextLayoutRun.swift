import SwiftUI

extension Text.Layout.Run {
  /// The destination of the link this run belongs to, if any.
  ///
  /// Textual resolves `Text.Layout` and publishes it through the `Text.LayoutKey` preference, and
  /// an app can read that same preference to position its own overlays over the rendered text.
  /// Doing so needs a way to tell *which* runs matter, and the attribute carrying that — a
  /// `TextAttribute` attached while building `Text` — is internal, so a run's link destination was
  /// unreachable from outside the module.
  ///
  /// This matters most for attachments. Textual draws attachment bodies through `Canvas` and
  /// `GraphicsContext.draw(_:in:)`, which rasterizes them: a control inside an attachment body
  /// renders but never receives a touch. Hosting the control in an overlay instead is the way to
  /// make an inline image interactive, and that overlay needs to locate the image's run:
  ///
  /// ```swift
  /// content.overlayPreferenceValue(Text.LayoutKey.self) { value in
  ///   GeometryReader { geometry in
  ///     ForEach(targets(in: value, geometry: geometry)) { target in
  ///       Button("Edit") { edit(target.url) }
  ///         .position(x: target.rect.midX, y: target.rect.midY)
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// where each target comes from a run whose `linkURL` matches, paired with its
  /// `typographicBounds`.
  public var linkURL: URL? {
    self[LinkAttribute.self]?.url
  }

}
