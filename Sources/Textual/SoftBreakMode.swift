import SwiftUI

/// Determines how Textual renders soft line breaks.
///
/// A *soft break* is a single newline inside a paragraph:
///
/// ```markdown
/// Line one
/// line two
/// ```
///
/// CommonMark treats that newline as a space, so both lines render as one wrapped paragraph.
/// Foundation's Markdown parser follows suit: it marks the span with
/// `InlinePresentationIntent.softBreak` and stores a literal space.
///
/// Note-taking and chat surfaces usually want the opposite — the author pressed Return, so they
/// expect a line break. Use ``TextualNamespace/softBreakMode(_:)`` to opt into that behavior.
///
/// A *hard* break (a line ending in two spaces or a backslash) always renders as a line break,
/// regardless of this setting.
public enum SoftBreakMode: Sendable, Hashable {
  /// Renders soft breaks as a space, so the paragraph reflows. This is CommonMark's behavior and
  /// the default.
  case space

  /// Renders soft breaks as line breaks, preserving the line structure the author typed.
  case lineBreak
}

extension EnvironmentValues {
  @usableFromInline
  @Entry var softBreakMode: SoftBreakMode = .space
}

extension TextualNamespace where Base: View {
  /// Sets how soft line breaks render in the views below this one.
  ///
  /// ```swift
  /// StructuredText(markdown: note.body)
  ///   .textual.softBreakMode(.lineBreak)
  /// ```
  @MainActor public func softBreakMode(_ softBreakMode: SoftBreakMode) -> some View {
    base.environment(\.softBreakMode, softBreakMode)
  }
}
