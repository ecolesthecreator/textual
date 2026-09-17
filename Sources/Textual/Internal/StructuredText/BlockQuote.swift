import SwiftUI

extension StructuredText {
  struct BlockQuote: View {
    @Environment(\.blockQuoteStyle) private var blockQuoteStyle
    @Environment(\.softBreakMode) private var softBreakMode

    private let intent: PresentationIntent.IntentType?
    private let content: AttributedSubstring

    init(intent: PresentationIntent.IntentType?, content: AttributedSubstring) {
      self.intent = intent
      self.content = content
    }

    var body: some View {
      let configuration = BlockStyleConfiguration(
        label: .init(
          BlockContent(
            parent: intent,
            content: content
          )
        ),
        indentationLevel: indentationLevel,
        block: BlockProxy(content, softBreakMode: softBreakMode)
      )
      let resolvedStyle = blockQuoteStyle.resolve(configuration: configuration)

      AnyView(resolvedStyle)
    }

    private var indentationLevel: Int {
      content.runs.first?.presentationIntent?.indentationLevel ?? 0
    }
  }
}
