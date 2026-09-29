import SwiftUI

extension StructuredText {
  struct UnorderedList: View {
    @Environment(\.listItemSpacing) private var listItemSpacing
    @Environment(\.textEnvironment) private var textEnvironment

    private let intent: PresentationIntent.IntentType?
    private let content: AttributedSubstring

    init(intent: PresentationIntent.IntentType?, content: AttributedSubstring) {
      self.intent = intent
      self.content = content
    }

    var body: some View {
      let runs = content.blockRuns(parent: intent)

      BlockVStack {
        ForEach(runs.indices, id: \.self) { index in
          let run = runs[index]

          UnorderedListItem(
            intent: run.intent,
            content: content[run.range]
          )
        }
      }
      .environment(\.resolvedListItemSpacing, listItemSpacing.resolve(in: textEnvironment))
      .environment(\.listItemSpacingEnabled, true)
    }
  }
}

extension StructuredText {
  fileprivate struct UnorderedListItem: View {
    @Environment(\.listItemStyle) private var listItemStyle
    @Environment(\.unorderedListMarker) private var unorderedListMarker
    @Environment(\.taskListMarker) private var taskListMarker

    private let intent: PresentationIntent.IntentType?
    private let content: AttributedSubstring
    private let task: (isChecked: Bool, content: AttributedString)?

    init(
      intent: PresentationIntent.IntentType?,
      content: AttributedSubstring
    ) {
      self.intent = intent
      self.content = content
      self.task = content.taskListItem()
    }

    var body: some View {
      let configuration = ListItemStyleConfiguration(
        marker: .init(marker),
        block: .init(block),
        indentationLevel: indentationLevel
      )
      let resolvedStyle = listItemStyle.resolve(configuration: configuration)

      AnyView(resolvedStyle)
    }

    @ViewBuilder
    private var block: some View {
      if let task {
        BlockContent(parent: intent, content: task.content)
      } else {
        BlockContent(parent: intent, content: content)
      }
    }

    private var marker: some View {
      if let task {
        AnyView(
          taskListMarker.resolve(
            configuration: .init(
              isChecked: task.isChecked,
              indentationLevel: indentationLevel
            )
          )
        )
      } else {
        AnyView(
          unorderedListMarker.resolve(
            configuration: .init(
              indentationLevel: indentationLevel
            )
          )
        )
      }
    }

    private var indentationLevel: Int {
      content.runs.first?.presentationIntent?.indentationLevel ?? 0
    }
  }
}
