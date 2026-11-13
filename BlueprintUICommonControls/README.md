BlueprintUICommonControls
=====

Blueprint elements wrapping commonly used UIKit primitives.

## Attributed text

Use `AttributedLabel` for label content. On iOS 16 and later, `AttributedTextView`
displays selectable, read-only content through a native TextKit 2 `UITextView`.
It accepts `NSAttributedString`, including paragraph styles with `NSTextList`
membership, and keeps UIKit's accessibility behavior.

```swift
let list = NSTextList(markerFormat: .disc, options: 0)
let paragraph = NSMutableParagraphStyle()
paragraph.textLists = [list]

let content = NSAttributedString(string: "First item\nSecond item", attributes: [
    .font: UIFont.preferredFont(forTextStyle: .body),
    .foregroundColor: UIColor.label,
    .paragraphStyle: paragraph,
])

AttributedTextView(attributedText: content)
    .onLinkTapped { url in /* Handle the URL. */ }
```

Reuse one list object across its item paragraphs. For nested items, set
`textLists` to the enclosing lists followed by the nested list. UIKit generates
the markers; the string does not need bullet characters or tabs.

The view expands to fit the available width and its content. Put long documents
inside a scrolling container. Callers supply the text's fonts and other
attributes, including updated fonts when Dynamic Type changes. The public
`AttributedTextView.View` provides the same UIKit implementation for other hosts.
