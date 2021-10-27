//
//  MarkdownLabel.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 6/29/21.
//

import BlueprintUI

// https://github.com/johnxnguyen/Down
import Down


public struct MarkdownLabel : ProxyElement {
    
    public var text : String
        
    public init(_ text : String) {
        self.text = text
    }
    
    public var elementRepresentation: Element {
        LabelElement(text: self.text)
    }
}


extension MarkdownLabel {
    
    public struct Style : Equatable {
        
        var fonts : Fonts
        var colors : Colors
        
        struct Fonts : Equatable {
            var heading1: UIFont
            var heading2: UIFont
            var heading3: UIFont
            var heading4: UIFont
            var heading5: UIFont
            var heading6: UIFont
            var body: UIFont
        }
        
        struct Colors : Equatable {
            var heading1: UIFont
            var heading2: UIFont
            var heading3: UIFont
            var heading4: UIFont
            var heading5: UIFont
            var heading6: UIFont
            var body: UIFont
        }
    }
}


private struct LabelElement : UIViewElement {
    
    var text : String
    
    /// TODO: Switch back to a label and do manual link tracking... We can't seem to
    /// turn off text selection but allow links.
    
    static func makeUIView() -> Label {
        
        let label = Label()
        
        label.backgroundColor = .clear
        
        return label
    }
    
    func updateUIView(_ view: Label, with context: UIViewElementContext) {
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
    
    final class Label : UILabel {
        
        private let recognizer : PressGestureRecognizer
        
        private var linkHighlight : BlueprintView? = nil
        
        override init(frame: CGRect) {
            self.recognizer = PressGestureRecognizer()
            super.init(frame: frame)
            
            self.recognizer.addTarget(self, action: #selector(Label.gestureChanged))
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            
        }
        
        @objc private func gestureChanged() {
//            switch self.recognizer.state {
//            case .possible:
//                <#code#>
//            case .began:
//                <#code#>
//            case .changed:
//                <#code#>
//            case .ended:
//                <#code#>
//            case .cancelled:
//                <#code#>
//            case .failed:
//                <#code#>
//            @unknown default:
//                assert(false, "Unknown state")
//            }
        }
        
        private func newLayoutManager() -> (NSLayoutManager, NSTextContainer, NSTextStorage) {
            
            let layoutManager = NSLayoutManager()
            
            let textContainer = NSTextContainer(size: bounds.size)
            textContainer.lineFragmentPadding = 0
            
            let textStorage = NSTextStorage()
            
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
                  
            textContainer.lineBreakMode = lineBreakMode
            textContainer.size = textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).size
            
            textStorage.setAttributedString(self.attributedText ?? .init())
                  
            return (layoutManager, textContainer, textStorage)
        }
        
        private func link(at point : CGPoint) -> (URL, CGRect)? {
            let (layoutManager, textContainer, textStorage) = self.newLayoutManager()
            
            // TODO: Or glyphIndex?
            let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            
            guard index != NSNotFound else { return nil }
            
            let range = layoutManager.glyphRange(forCharacterRange: NSRange(location: index, length: 1), actualCharacterRange: nil)
            let rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
            
            guard rect.contains(point) else { return nil }
            
            var effectiveRange : NSRange = .init()
            
            if let link = textStorage.attribute(.link, at: index, effectiveRange: &effectiveRange) as? URL {
                return nil
            } else {
                return nil
            }
        }
    }
}


private extension UILabel {
    
    static var rawMarkdownKey = NSObject()
    
    var rawMarkdown : String? {
        get { objc_getAssociatedObject(self, &UILabel.rawMarkdownKey) as? String ?? nil }
        set { objc_setAssociatedObject(self, &UILabel.rawMarkdownKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
}


fileprivate final class PressGestureRecognizer : UILongPressGestureRecognizer {
    
    var allowableMovementAfterBegin : CGFloat
    
    private var initialPoint : CGPoint? = nil
    
    override init(target: Any?, action: Selector?) {
        
        self.allowableMovementAfterBegin = 5.0
        
        super.init(target: target, action: action)
        
        self.minimumPressDuration = 0.0
    }
    
    override func reset() {
        super.reset()
        
        self.initialPoint = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        self.initialPoint = self.location(in: self.view)
    }
    
    override func canPrevent(_ gesture: UIGestureRecognizer) -> Bool {
        
        // We want to allow the pan gesture of our containing scroll view to continue to track
        // when the user moves their finger vertically or horizontally, when we are cancelled.
        
        if let panGesture = gesture as? UIPanGestureRecognizer, panGesture.view is UIScrollView {
            return false
        }
        
        return super.canPrevent(gesture)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if let initialPoint = self.initialPoint {
            let currentPoint = self.location(in: self.view)
            
            let distance = sqrt(pow(abs(initialPoint.x - currentPoint.x), 2) + pow(abs(initialPoint.y - currentPoint.y), 2))
            
            if distance > self.allowableMovementAfterBegin {
                self.state = .failed
            }
        }
    }
}

