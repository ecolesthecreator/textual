import SwiftUI
import UniformTypeIdentifiers

extension StructuredText {
  /// A proxy for a rendered code block that custom code block styles can use.
  public struct CodeBlockProxy {
    private let content: AttributedSubstring

    internal init(_ content: AttributedSubstring) {
      self.content = content
    }

    /// The code block contents as plain text.
    ///
    /// Unlike ``StructuredText/BlockProxy/plainText``, this is *not* dedented: leading
    /// whitespace is part of the code, and stripping the indentation shared by every line would
    /// silently reformat it.
    public var plainText: String {
      Formatter(AttributedString(content)).plainText()
    }

    /// Copies the code block contents to the system pasteboard as plain text.
    ///
    /// Only a plain-text flavor is written. Code pasted into a rich-text target should arrive as
    /// source, not as the syntax-highlighted colors and fonts it happened to be rendered with.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func copyToPasteboard() {
      #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(plainText, forType: .string)
      #elseif TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
        UIPasteboard.general.setItems(
          [[UTType.plainText.identifier: plainText]]
        )
      #endif
    }
  }
}
