import SwiftUI
import UniformTypeIdentifiers

extension StructuredText {
  /// A proxy for a rendered block that custom block styles can use.
  ///
  /// Code blocks get this through ``StructuredText/CodeBlockStyleConfiguration/codeBlock``.
  /// Blocks that carry text content — paragraphs and block quotes — get it through
  /// ``StructuredText/BlockStyleConfiguration/block``, so a custom
  /// ``StructuredText/BlockQuoteStyle`` can offer the same copy affordance a code block style can.
  public struct BlockProxy {
    private let content: AttributedSubstring
    private let softBreakMode: SoftBreakMode

    internal init(_ content: AttributedSubstring, softBreakMode: SoftBreakMode = .space) {
      self.content = content
      self.softBreakMode = softBreakMode
    }

    /// The block contents as plain text, with all formatting stripped.
    ///
    /// Emphasis, strong, strikethrough and link markup are flattened to their text. A block
    /// quote's content is also dedented: `Formatter` indents quoted blocks by two spaces per
    /// level, which is right for a transcript of a whole document but wrong for a copy of this
    /// one block.
    ///
    /// Use this to feed a share sheet, a "quote this" composer, or any action that needs the
    /// text rather than the pasteboard.
    public var plainText: String {
      var attributedString = AttributedString(content)

      // Match the rendering: under `.softBreakMode(.lineBreak)` the reader saw a line break, so
      // the copy carries one too.
      if softBreakMode == .lineBreak {
        attributedString.renderSoftBreaksAsLineBreaks()
      }

      return Formatter(attributedString).plainText().dedented()
    }

    /// Copies the block contents to the system pasteboard as plain text.
    ///
    /// Unlike ``StructuredText/CodeBlockProxy/copyToPasteboard()``, this writes *only* a
    /// plain-text flavor. A block quote pasted into a rich-text target should arrive as the words
    /// the reader saw, not as a styled quotation carrying the document's fonts and colors.
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

extension String {
  /// Removes the indentation shared by every non-empty line.
  fileprivate func dedented() -> String {
    let lines = split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)

    let commonIndent =
      lines
      .filter { !$0.allSatisfy(\.isWhitespace) }
      .map { $0.prefix(while: { $0 == " " }).count }
      .min() ?? 0

    guard commonIndent > 0 else {
      return self
    }

    return
      lines
      .map { String($0.dropFirst(min(commonIndent, $0.prefix(while: { $0 == " " }).count))) }
      .joined(separator: "\n")
  }
}
