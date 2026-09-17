import SwiftUI
import Textual

/// Exercises the combination Remote Codetrol's notes preview needs:
///
/// * custom code block / block quote styles that wrap `configuration.label`,
/// * syntax highlighting preserved through those custom styles,
/// * a copy button in each block that actually receives taps,
/// * all of it under `.textual.textSelection(.enabled)` so text stays
///   selectable in place.
///
/// The chrome mirrors `CopyableCodeBlockView` and `CopyableBlockquoteView` in
/// RemoteCodetrolShared: `square.on.square` that flips to a green `checkmark`
/// for 1.5s, a language header on code blocks, and a bottom-right quarter-arc
/// on block quotes.
struct SelectableBlocksDemo: View {
  var body: some View {
    ScrollView {
      StructuredText(markdown: Self.markdown)
        .textual.codeBlockStyle(CopyableCodeBlockStyle())
        .textual.blockQuoteStyle(CopyableBlockQuoteStyle())
        .textual.softBreakMode(.lineBreak)
        .textual.textSelection(.enabled)
        .textual.textSelectionActions([
          TextSelectionAction(title: "Quote", systemImage: "quote.bubble") { text in
            print("quote: \(text.prefix(40))")
          }
        ])
        .padding()
    }
    .textual.textSelectionCoordination()
  }

  private static let markdown = """
    A note preview renders prose, code and quotes together, and every one of \
    them has to stay selectable.

    Shopping list, typed on three lines:
    milk
    eggs
    coffee

    ```swift
    struct Sightseeing: Activity {
        func perform(with sloth: inout Sloth) -> Speed {
            sloth.energyLevel -= 10
            return .slow
        }
    }
    ```

    > Outside of a dog, a book is man's best friend.
    > Inside of a dog it's too dark to read.

    ```python
    def fib(n: int) -> int:
        a, b = 0, 1
        for _ in range(n):
            a, b = b, a + b
        return a
    ```

    Long-press anywhere above to select; the copy buttons should still take \
    taps without the selection recognizer swallowing them.
    """
}

// MARK: - Shared chrome

/// `square.on.square` that flips to a green `checkmark` for 1.5s, matching
/// `CopyableCodeBlockView.copyButton`.
private struct CopyButton: View {
  let showsLabel: Bool
  let iconSize: CGFloat
  let tint: Color
  let copy: () -> Void

  @State private var showCopied = false

  init(showsLabel: Bool = true, iconSize: CGFloat = 11, tint: Color, copy: @escaping () -> Void) {
    self.showsLabel = showsLabel
    self.iconSize = iconSize
    self.tint = tint
    self.copy = copy
  }

  var body: some View {
    Button {
      copy()
      withAnimation { showCopied = true }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        withAnimation { showCopied = false }
      }
    } label: {
      HStack(spacing: 4) {
        Image(systemName: showCopied ? "checkmark" : "square.on.square")
          .font(.system(size: iconSize, weight: .medium))
        if showsLabel {
          Text(showCopied ? "Copied!" : "Copy")
            .font(.system(size: 11, weight: .medium))
        }
      }
      .foregroundColor(showCopied ? .green : tint)
      .animation(.easeInOut(duration: 0.15), value: showCopied)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Copy")
    // Without this the long-press selection recognizer claims the tap and the
    // button never fires. This is also what lets a real `Button` work on iOS,
    // where `CopyableCodeBlockView` currently falls back to a bare
    // `.contentShape` + `.onTapGesture` to dodge the same problem.
    .textual.selectionExclusion()
  }
}

// MARK: - Code block style

private struct CopyableCodeBlockStyle: StructuredText.CodeBlockStyle {
  func makeBody(configuration: Configuration) -> some View {
    CodeBlockBody(configuration: configuration)
  }

  private struct CodeBlockBody: View {
    let configuration: Configuration

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
      colorScheme == .dark ? Color(white: 0.14) : Color(white: 0.96)
    }

    private var headerBackgroundColor: Color {
      colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.92)
    }

    private var textColor: Color {
      colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.4)
    }

    private var languageDisplayName: String {
      guard let language = configuration.languageHint, !language.isEmpty else {
        return "text"
      }
      return language.lowercased()
    }

    var body: some View {
      VStack(spacing: 0) {
        HStack {
          Text(languageDisplayName)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(textColor)

          Spacer()

          CopyButton(tint: textColor) {
            configuration.codeBlock.copyToPasteboard()
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(headerBackgroundColor)

        Rectangle()
          .fill(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.85))
          .frame(height: 1)

        // `configuration.label` carries the syntax-highlighted content, so
        // wrapping it in custom chrome keeps highlighting intact.
        Overflow {
          configuration.label
            .textual.fontScale(0.85)
            .fixedSize(horizontal: false, vertical: true)
            .monospaced()
            .padding(12)
        }
      }
      .background(backgroundColor)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .textual.blockSpacing(.fontScaled(top: 0.88, bottom: 0.88))
    }
  }
}

// MARK: - Block quote style

private struct CopyableBlockQuoteStyle: StructuredText.BlockQuoteStyle {
  func makeBody(configuration: Configuration) -> some View {
    BlockQuoteBody(configuration: configuration)
  }

  private struct BlockQuoteBody: View {
    let configuration: Configuration

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
      colorScheme == .dark ? Color.gray.opacity(0.15) : Color.gray.opacity(0.08)
    }

    private var arcColor: Color {
      colorScheme == .dark ? Color.gray.opacity(0.25) : Color.gray.opacity(0.15)
    }

    private var borderColor: Color {
      colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.6)
    }

    private var headerTextColor: Color {
      colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.5)
    }

    var body: some View {
      HStack(alignment: .top, spacing: 0) {
        Rectangle()
          .fill(borderColor)
          .frame(width: 4)

        configuration.label
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .fixedSize(horizontal: false, vertical: true)
      .background(backgroundColor)
      .overlay(alignment: .bottomTrailing) {
        // Corner arc with the copy button tucked into it, matching
        // `CopyableBlockquoteView`.
        BottomRightArc()
          .fill(arcColor)
          .frame(width: 28, height: 28)
          .overlay(alignment: .bottomTrailing) {
            // `configuration.block` is the block-quote counterpart to a code
            // block's `codeBlock` proxy.
            if let block = configuration.block {
              CopyButton(showsLabel: false, iconSize: 10, tint: headerTextColor) {
                block.copyToPasteboard()
              }
              .padding(.trailing, 4)
              .padding(.bottom, 4)
            }
          }
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .textual.blockSpacing(.fontScaled(top: 0.88, bottom: 0.88))
    }
  }
}

/// A quarter-circle for the bottom-right corner of a block quote, so the copy
/// button sits on its own diagonal ground.
private struct BottomRightArc: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let radius = min(rect.width, rect.height)
    path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
    path.addArc(
      center: CGPoint(x: rect.maxX, y: rect.maxY),
      radius: radius,
      startAngle: .degrees(-90),
      endAngle: .degrees(180),
      clockwise: true
    )
    path.closeSubpath()
    return path
  }
}

#Preview {
  SelectableBlocksDemo()
}
