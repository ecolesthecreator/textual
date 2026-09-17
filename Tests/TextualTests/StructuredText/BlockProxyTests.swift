import Foundation
import Testing

@testable import Textual

struct BlockProxyTests {
  private func proxy(
    _ markdown: String,
    softBreakMode: SoftBreakMode = .space
  ) throws -> StructuredText.BlockProxy {
    let attributedString = try AttributedString(
      markdown: markdown,
      options: .init(interpretedSyntax: .full)
    )
    return StructuredText.BlockProxy(
      attributedString[attributedString.startIndex..<attributedString.endIndex],
      softBreakMode: softBreakMode
    )
  }

  @Test func stripsInlineFormatting() throws {
    // given
    let proxy = try proxy("Plain **bold** and *italic* and ~~struck~~ and [a link](https://e.com).")

    // when
    let result = proxy.plainText

    // then
    #expect(result == "Plain bold and italic and struck and a link.")
  }

  @Test func stripsInlineCodeBackticks() throws {
    // given
    let proxy = try proxy("Call `makeItWork(_:)` first.")

    // when
    let result = proxy.plainText

    // then
    #expect(result == "Call makeItWork(_:) first.")
  }

  @Test func dedentsBlockQuoteContent() throws {
    // given — `Formatter` indents quoted blocks by two spaces per level, which is wrong when
    // copying the quote on its own.
    let proxy = try proxy("> This is a quote.")

    // when
    let result = proxy.plainText

    // then
    #expect(result == "This is a quote.")
  }

  @Test func dedentsEveryLineOfAMultiLineQuote() throws {
    // given
    let proxy = try proxy(
      """
      > First line of the quote.
      >
      > Second line of the quote.
      """
    )

    // when
    let result = proxy.plainText

    // then
    #expect(!result.contains("\n  "))
    #expect(result.hasPrefix("First line"))
  }

  @Test func preservesRelativeIndentationWithinTheBlock() throws {
    // given — dedent removes the *shared* indent only; a nested list keeps its own shape.
    let proxy = try proxy(
      """
      > - one
      >   - nested
      """
    )

    // when
    let result = proxy.plainText

    // then
    #expect(!result.hasPrefix(" "))
    #expect(result.contains("nested"))
  }

  @Test func keepsHardBreaksAsLineBreaks() throws {
    // given — two trailing spaces is a hard break, and it is a line break in every mode.
    let proxy = try proxy("Line one.  \nLine two.")

    // when
    let result = proxy.plainText

    // then
    #expect(result == "Line one.\nLine two.")
  }

  @Test func collapsesSoftBreaksToSpacesByDefault() throws {
    // given
    let proxy = try proxy(
      """
      > Outside of a dog, a book is man's best friend.
      > Inside of a dog it's too dark to read.
      """
    )

    // when
    let result = proxy.plainText

    // then — CommonMark behavior: the paragraph reflows.
    #expect(!result.contains("\n"))
    #expect(result.contains("friend. Inside"))
  }

  @Test func copiesSoftBreaksAsLineBreaksWhenRenderedThatWay() throws {
    // given
    let proxy = try proxy(
      """
      > Outside of a dog, a book is man's best friend.
      > Inside of a dog it's too dark to read.
      """,
      softBreakMode: .lineBreak
    )

    // when
    let result = proxy.plainText

    // then — the copy matches what the reader saw.
    #expect(
      result == """
        Outside of a dog, a book is man's best friend.
        Inside of a dog it's too dark to read.
        """)
  }
}
