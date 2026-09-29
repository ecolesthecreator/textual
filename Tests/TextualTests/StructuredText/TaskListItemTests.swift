import Foundation
import Testing

@testable import Textual

struct TaskListItemTests {
  /// The first list item of `markdown`, sliced the way `UnorderedList` hands it to an item.
  private func firstItem(_ markdown: String) throws -> AttributedSubstring {
    let document = try AttributedString(markdown: markdown, options: .init(interpretedSyntax: .full))
    let list = document.blockRuns()[0]
    let item = document[list.range].blockRuns(parent: list.intent)[0]
    return document[item.range]
  }

  @Test func openTask() throws {
    let task = try #require(try firstItem("- [ ] buy milk").taskListItem())
    #expect(task.isChecked == false)
    #expect(String(task.content.characters) == "buy milk")
  }

  @Test func checkedTaskEitherCase() throws {
    for markdown in ["- [x] **done**", "- [X] **done**"] {
      let task = try #require(try firstItem(markdown).taskListItem())
      #expect(task.isChecked)
      #expect(String(task.content.characters) == "done")
      #expect(task.content.runs.first?.inlinePresentationIntent == .stronglyEmphasized)
    }
  }

  @Test func ordinaryItemsAreNotTasks() throws {
    #expect(try firstItem("- plain").taskListItem() == nil)
    #expect(try firstItem("- [link](https://example.com)").taskListItem() == nil)
    #expect(try firstItem("- [y] not a box").taskListItem() == nil)
    #expect(try firstItem("- `[ ] ` in code").taskListItem() == nil)
  }
}
