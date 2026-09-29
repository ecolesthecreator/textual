import SwiftUI

extension StructuredText {
  /// The properties of a task-list marker passed to a `TaskListMarker`.
  public struct TaskListMarkerConfiguration {
    /// Whether the task is checked (`- [x]`) or open (`- [ ]`).
    public let isChecked: Bool
    /// The indentation level of the list within the document structure.
    public let indentationLevel: Int
  }

  /// A marker view used in place of the bullet for GitHub-style task-list items
  /// (`- [ ] open`, `- [x] done`).
  ///
  /// Foundation's Markdown parser has no task-list extension, so the `[ ]` / `[x]` prefix
  /// arrives as literal text. ``StructuredText`` strips that prefix from unordered list items
  /// and renders this marker instead.
  ///
  /// You can apply a task-list marker using the ``TextualNamespace/taskListMarker(_:)`` modifier.
  public protocol TaskListMarker: DynamicProperty {
    associatedtype Body: View

    /// Creates a view that represents the marker for a task-list item.
    @MainActor @ViewBuilder func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = TaskListMarkerConfiguration
  }
}

extension EnvironmentValues {
  @usableFromInline
  @Entry var taskListMarker: any StructuredText.TaskListMarker = .checkbox
}

// MARK: - Checkbox

extension StructuredText {
  /// A task-list marker that draws an SF Symbol checkbox.
  public struct CheckboxTaskListMarker: TaskListMarker {
    private let uncheckedSymbolName: String
    private let checkedSymbolName: String
    private let scale: CGFloat
    private let minWidth: FontScaled<CGFloat>

    /// Creates a checkbox marker.
    ///
    /// - Parameters:
    ///   - uncheckedSymbolName: The SF Symbol for an open task.
    ///   - checkedSymbolName: The SF Symbol for a completed task.
    ///   - scale: A font scale applied to the symbol.
    ///   - minWidth: A font-relative minimum width for the marker.
    public init(
      uncheckedSymbolName: String = "square",
      checkedSymbolName: String = "checkmark.square.fill",
      scale: CGFloat = 0.9,
      minWidth: FontScaled<CGFloat> = .fontScaled(1.5)
    ) {
      self.uncheckedSymbolName = uncheckedSymbolName
      self.checkedSymbolName = checkedSymbolName
      self.scale = scale
      self.minWidth = minWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
      SwiftUI.Image(systemName: configuration.isChecked ? checkedSymbolName : uncheckedSymbolName)
        .foregroundStyle(.secondary)
        .textual.fontScale(scale)
        .textual.frame(minWidth: minWidth, alignment: .trailing)
        .accessibilityLabel(configuration.isChecked ? "Completed" : "Not completed")
    }
  }
}

extension StructuredText.TaskListMarker where Self == StructuredText.CheckboxTaskListMarker {
  /// A square checkbox: an outlined square when open, a filled checkmark square when done.
  public static var checkbox: Self {
    .init()
  }

  /// A round checkbox: an outlined circle when open, a filled checkmark circle when done.
  public static var circle: Self {
    .init(uncheckedSymbolName: "circle", checkedSymbolName: "checkmark.circle.fill")
  }
}

// MARK: - Detection

extension AttributedSubstring {
  /// The task state of a list item whose first paragraph opens with `[ ] `, `[x] ` or `[X] `,
  /// and the item's content with that prefix removed. `nil` for an ordinary list item.
  func taskListItem() -> (isChecked: Bool, content: AttributedString)? {
    let prefixLength = 4
    let prefix = String(characters.prefix(prefixLength))

    let isChecked: Bool
    switch prefix {
    case "[ ] ": isChecked = false
    case "[x] ", "[X] ": isChecked = true
    default: return nil
    }

    // The prefix must be plain paragraph text: `` `[ ] ` `` in inline code, or a code block
    // that happens to start with brackets, is content rather than a checkbox.
    guard let firstRun = runs.first,
      characters.distance(from: firstRun.range.lowerBound, to: firstRun.range.upperBound)
        >= prefixLength,
      firstRun.inlinePresentationIntent?.contains(.code) != true,
      case .paragraph = firstRun.presentationIntent?.components.first?.kind
    else {
      return nil
    }

    var content = AttributedString(self)
    let end = content.characters.index(content.startIndex, offsetBy: prefixLength)
    content.removeSubrange(content.startIndex..<end)
    return (isChecked, content)
  }
}
