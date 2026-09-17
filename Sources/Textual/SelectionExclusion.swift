import SwiftUI

extension TextualNamespace where Base: View {
  /// Excludes the receiver's frame from the text-selection hit-test overlay.
  ///
  /// Textual's iOS selection overlay (`UITextInteractionView`) and macOS
  /// equivalent read a set of exclusion rectangles when deciding whether to
  /// claim a touch. Rectangles that overlap the receiver's frame are excluded,
  /// so touches inside pass through to whatever's beneath — a `Button`, a
  /// scroll view, a custom control.
  ///
  /// Use this modifier when embedding interactive views (buttons, controls,
  /// scrollable regions) inside a custom `StructuredText.CodeBlockStyle`,
  /// `BlockQuoteStyle`, etc. Without it, `.textual.textSelection(.enabled)`
  /// swallows short taps to the selection recognizer.
  ///
  /// ```swift
  /// HStack {
  ///   Text(language)
  ///   Spacer()
  ///   Button("Copy", action: copy)
  /// }
  /// .textual.selectionExclusion()
  /// ```
  ///
  /// `Overflow` already emits exclusion frames for horizontal-scroll regions,
  /// so you don't need this modifier if your custom style uses `Overflow` for
  /// the interactive area.
  @MainActor public func selectionExclusion() -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      base.background(
        GeometryReader { geometry in
          Color.clear
            .preference(
              key: OverflowFrameKey.self,
              value: [geometry.frame(in: .textContainer)]
            )
        }
      )
    #else
      base
    #endif
  }
}
