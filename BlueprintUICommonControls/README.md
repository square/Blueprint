BlueprintUICommonControls
=====

Blueprint elements wrapping commonly used UIKit primitives.

## Attributed text

Use `AttributedLabel` for ordinary display text. On iOS 17 and later, use
`AttributedTextView` to display read-only text with TextKit 2. It accepts
`NSAttributedString`, including paragraph styles with `NSTextList` membership.
UIKit provides native links and exposes separate accessible paragraphs by default.

Label-specific link APIs are deprecated starting with iOS 17; use `AttributedTextView`
for links. The shared `.onLinkTapped` and URL-handler environment APIs remain supported.
Both controls use `Set<TextLinkDetectionType>` for `linkDetectionTypes`; supported
cases are `.link`, `.phoneNumber`, `.address`, and `.date`. Both controls use the same
data detection, which is disabled by default and works with selection off.
`AttributedTextView` exposes detected links through UIKit as attributed links.
The old nested `AttributedLabel.LinkDetectionType` name remains as a deprecated alias.

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

Set `isSelectable` to `true` to enable text selection and copying. Links are
interactive by default. When selection is off, text without links passes taps to
its containing view.

Configure `numberOfLines` (zero means unlimited), `textRectOffset`, `shadow`,
single-line font fitting, tightening, and explicit accessibility properties on
the element. Paragraph styles supply alignment and line-break behavior. These
settings apply during both measurement and display and reset on reused views.
Accessibility traits are added to UIKit's native traits, so heading styles retain
native link semantics.

`isAccessibilityElement` defaults to `nil` to preserve native paragraph navigation;
`true` groups the content into one element and `false` hides its accessibility.
Set `textAccessibilityRole` to route the view's text to the label, value, or hint of
a combined element. Explicit field overrides take precedence. Set
`accessibilityAttributedLabel`, `accessibilityAttributedValue`, or
`accessibilityAttributedHint` to preserve speech attributes in an override.
The String properties use the same backing.
Single-line fitting scales the supplied fonts proportionally; UIKit's label and
text-view engines can still differ in rounding, underlines, and pressed links.

For attributed accessibility composition and String API compatibility, see
[BlueprintUIAccessibilityCore](../BlueprintUIAccessibilityCore/README.md#attributed-accessibility-content).
