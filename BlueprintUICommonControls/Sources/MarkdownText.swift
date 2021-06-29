//
//  MarkdownText.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 6/28/21.
//

import BlueprintUI

// https://github.com/johnxnguyen/Down
import Down


public struct MarkdownText : ProxyElement {
    
    public var text : String
        
    public init(_ text : String) {
        self.text = text
    }
    
    public var elementRepresentation: Element {
        TextViewElement(text: self.text)
    }
}


extension MarkdownText {
    
    public struct Style : Equatable {
        
    }
}


private struct TextViewElement : UIViewElement {
    
    var text : String
    
    static func makeUIView() -> View {
        
        let textView = View()
        textView.delegate = textView
        
        textView.backgroundColor = .clear
        
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = true
        
        return textView
    }
    
    func updateUIView(_ view: View, with context: UIViewElementContext) {
        guard view.rawMarkdown != self.text else {
            return
        }
        
        do {
            let down = Down(markdownString: self.text)
            let string = try down.toAttributedString(styler: DownStyler())
            
            view.attributedText = string
        } catch {
            
        }
    }
    
    final class View : UITextView, UITextViewDelegate {
        
        // MARK: UITextViewDelegate
        
        func textView(
            _ textView: UITextView,
            shouldInteractWith URL: URL,
            in characterRange: NSRange,
            interaction: UITextItemInteraction
        ) -> Bool
        {
            return true
        }
    }
}


private extension UITextView {
    
    static var rawMarkdownKey = NSObject()
    
    var rawMarkdown : String? {
        get { objc_getAssociatedObject(self, &UITextView.rawMarkdownKey) as? String ?? nil }
        set { objc_setAssociatedObject(self, &UITextView.rawMarkdownKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
}
