import Foundation
import SwiftUI
import Testing

@testable import Textual

/// Covers handing Textual content that was parsed elsewhere, which is what a host doing its own
/// caching needs — a chat thread in a lazy container, say, where the view's `@State` parse cache
/// dies every time a row is recycled.
@MainActor
struct PreparsedContentTests {
  private func parsed(_ markdown: String) throws -> AttributedString {
    try AttributedString(markdown: markdown, options: .init(interpretedSyntax: .full))
  }

  @Test func structuredTextAcceptsPreparsedContent() throws {
    // given
    let content = try parsed("A paragraph with **strong** text.")

    // when
    let view = StructuredText(content)

    // then
    #expect(String(view.content.characters) == "A paragraph with strong text.")
  }

  @Test func inlineTextAcceptsPreparsedContent() throws {
    // given
    let content = try parsed("**Hello** _world_")

    // when
    let view = InlineText(content)

    // then
    #expect(String(view.content.characters) == "Hello world")
  }

  @Test func preparsedContentIsReturnedVerbatim() throws {
    // given — the attributes have to survive, not just the characters.
    let content = try parsed("Some **strong** text.")

    // when
    let view = StructuredText(content)

    // then
    #expect(view.content == content)
  }

  @Test func markupInitializerStillParses() throws {
    // given
    let view = StructuredText(markdown: "Plain **markdown**.")

    // when
    let content = view.content

    // then
    #expect(String(content.characters) == "Plain markdown.")
  }
}
