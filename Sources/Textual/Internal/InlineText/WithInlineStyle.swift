import SwiftUI

// MARK: - Overview
//
// `WithInlineStyle` applies an `InlineStyle` to an `AttributedString` before it reaches the
// rendering pipeline.
//
// The input `AttributedString` is expected to carry inline semantics using standard Foundation
// attributes:
// - `inlinePresentationIntent` identifies spans like code, emphasis, strong, and strikethrough.
// - `link` identifies URLs.
//
// The view reads `InlineStyle` and `TextEnvironmentValues` from the environment, then derives a
// styled copy of the attributed string by merging attributes into each matching span.
//
// Styling is recomputed whenever the input, style, or environment snapshot changes.

struct WithInlineStyle<Content: View>: View {
  /// Memoizes the styled output so `body` can derive it directly.
  ///
  /// The previous shape seeded `@State` from `onChange(of:initial:)` and rendered an empty
  /// `AttributedString` until that fired. SwiftUI does not guarantee appear-family events for
  /// every view it materializes — a row built lazily inside a scroll container while content
  /// updates quickly can miss them — and a view that missed it kept rendering nothing: layout
  /// ran, space was reserved, but no text was drawn and none reached accessibility.
  ///
  /// Deriving in `body` also means the first pass draws the styled text, instead of rendering
  /// empty and waiting for a second pass.
  @MainActor
  final class StyleCache {
    private var input: AttributedString?
    private var style: InlineStyle?
    private var environment: TextEnvironmentValues?
    private var softBreakMode: SoftBreakMode?
    private var output = AttributedString()

    func output(
      for input: AttributedString,
      style: InlineStyle,
      environment: TextEnvironmentValues,
      softBreakMode: SoftBreakMode
    ) -> AttributedString {
      if input == self.input, style == self.style, environment == self.environment,
        softBreakMode == self.softBreakMode
      {
        return output
      }

      self.input = input
      self.style = style
      self.environment = environment
      self.softBreakMode = softBreakMode
      self.output = Self.resolve(
        attributedString: input,
        style: style,
        in: environment,
        softBreakMode: softBreakMode
      )

      return output
    }
  }

  @Environment(\.inlineStyle) private var style
  @Environment(\.textEnvironment) private var environment
  @Environment(\.softBreakMode) private var softBreakMode

  @State private var cache = StyleCache()

  private let input: AttributedString
  private let content: (AttributedString) -> Content

  init(
    _ input: AttributedString,
    @ViewBuilder content: @escaping (AttributedString) -> Content
  ) {
    self.input = input
    self.content = content
  }

  var body: some View {
    content(
      cache.output(
        for: input,
        style: style,
        environment: environment,
        softBreakMode: softBreakMode
      )
    )
  }
}

extension WithInlineStyle.StyleCache {
  fileprivate static func resolve(
    attributedString: AttributedString,
    style: InlineStyle,
    in environment: TextEnvironmentValues,
    softBreakMode: SoftBreakMode
  ) -> AttributedString {
    var output = attributedString

    for run in attributedString.runs {
      var attributes = AttributeContainer()

      if let intent = run.inlinePresentationIntent {
        if intent.contains(.code) {
          style.code.apply(in: &attributes, environment: environment)
        }

        if intent.contains(.emphasized) {
          style.emphasis.apply(in: &attributes, environment: environment)
        }

        if intent.contains(.stronglyEmphasized) {
          style.strong.apply(in: &attributes, environment: environment)
        }

        if intent.contains(.strikethrough) {
          style.strikethrough.apply(in: &attributes, environment: environment)
        }
      }

      if run.link != nil {
        style.link.apply(in: &attributes, environment: environment)
      }

      output[run.range].mergeAttributes(attributes, mergePolicy: .keepNew)
    }

    if softBreakMode == .lineBreak {
      output.renderSoftBreaksAsLineBreaks()
    }

    return output
  }
}
