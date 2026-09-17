import SwiftUI

// MARK: - Overview
//
// Attachments are stored in attributed content as a `Textual.Attachment` attribute, but SwiftUI
// `Text` can’t embed arbitrary views. The rendering pipeline converts these runs into placeholder
// `Text` segments and uses an overlay to draw the real views at the resolved layout positions.
//
// `AttachmentAttribute` is attached to the placeholder runs during `Text` construction. It carries:
// - the original attachment value (type-erased as `AnyAttachment`)
// - the run's `PresentationIntent` (used by formatters and higher-level rendering)
//
// `Text.Layout.Run` exposes lightweight accessors so overlay code can discover attachments without
// reaching back into the original attributed string.

struct AttachmentAttribute: TextAttribute {
  var attachment: AnyAttachment
  var presentationIntent: PresentationIntent?

  init(_ attachment: AnyAttachment, presentationIntent: PresentationIntent?) {
    self.attachment = attachment
    self.presentationIntent = presentationIntent
  }
}

extension Text.Layout.Run {
  /// The attachment drawn in this run, if any.
  ///
  /// Attachment bodies are rasterized into a `Canvas`, so they are never hit-tested. An app that
  /// needs an inline image to be interactive hosts the control in an overlay instead, and needs to
  /// know which run holds which attachment in order to place it. Downcast ``AnyAttachment/base``
  /// to the type your loader returns:
  ///
  /// ```swift
  /// if let image = run.attachment?.base as? NoteImageAttachment {
  ///   // position a control over run.typographicBounds
  /// }
  /// ```
  ///
  /// Unlike ``Text/Layout/Run/linkURL``, this needs no change to the markup — the attachment is
  /// already there.
  public var attachment: AnyAttachment? {
    self[AttachmentAttribute.self]?.attachment
  }

  var attachmentPresentationIntent: PresentationIntent? {
    self[AttachmentAttribute.self]?.presentationIntent
  }
}
