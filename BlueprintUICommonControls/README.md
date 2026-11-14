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

AttributedTextView(attributedText: content) {
    $0.isSelectable = false
}
    .onLinkTapped { url in /* Handle the URL. */ }
```

Reuse one list object across its item paragraphs. For nested items, set
`textLists` to the enclosing lists followed by the nested list. UIKit generates
the markers; the string does not need bullet characters or tabs.

The view expands to fit the available width and its content. Put long documents
inside a scrolling container. Callers supply the text's fonts and other
attributes, including updated fonts when Dynamic Type changes. The public
`AttributedTextView.View` provides the same UIKit implementation for other hosts.

Selection is enabled by default. On iOS 17+, disabling it keeps native link
activation and menus available through the text-item delegate API. On iOS 16,
link interaction follows UIKit's selection setting.

Configure `numberOfLines` (zero means unlimited), `textRectOffset`, `shadow`,
single-line font fitting, tightening, and explicit accessibility properties on
the element. Paragraph styles supply alignment and line-break behavior. These
settings apply during both measurement and display and reset on reused views.
Single-line fitting scales the supplied fonts proportionally; UIKit's label and
text-view engines can still differ in rounding, underlines, and pressed links.
