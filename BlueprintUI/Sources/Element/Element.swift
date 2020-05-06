import UIKit

/// Conforming types represent a rectangular content area in a two-dimensional
/// layout space.
///
/// ***
///
/// The ultimate purpose of an element is to provide visual content. This can be
/// done in two ways:
///
/// - By providing a view description (`ViewDescription`).
///
/// - By providing child elements that will be displayed recursively within
///   the local coordinate space.
///
/// ***
///
/// A custom element might look something like this:
///
/// ```
/// struct MyElement: Element {
///
///     var backgroundColor: UIColor = .red
///
///     // Returns a single child element.
///     var content: ElementContent {
///         return ElementContent(child: Label(text: "😂"))
///     }
///
///     // Providing a view description means that this element will be
///     // backed by a UIView instance when displayed in a `BlueprintView`.
///     func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
///         return UIView.describe { config in
///             config.bind(backgroundColor, to: \.backgrouncColor)
///         }
///     }
///
/// }
/// ```
///
public protocol Element : CustomDebugStringConvertible {

    /// Returns the content of this element.
    ///
    /// Elements generally fall into two types:
    /// - Leaf elements, or elements that have no children. These elements commonly have an intrinsic size, or some
    ///   content that can be measured. Leaf elements typically instantiate their content with
    ///   `ElementContent(measurable:)` or similar.
    /// - Container elements: these element have one or more children, which are arranged by a layout implementation.
    ///   Container elements typically use methods like `ElementContent(layout:configure:)` to instantiate
    ///   their content.
    var content: ElementContent { get }

    /// Returns an (optional) description of the view that should back this element.
    ///
    /// In Blueprint, elements that are displayed using a live `UIView` instance are referred to as "view-backed".
    /// Elements become view-backed by returning a `ViewDescription` value from this method.
    ///
    /// - Parameter bounds: The bounds of this element after layout is complete.
    /// - Parameter subtreeExtent: A rectangle in the local coordinate space that contains any children.
    ///                            `subtreeExtent` will be nil if there are no children.
    ///
    /// - Returns: An optional `ViewDescription`.
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription?

    /// The debugging info and config to use with the Blueprint element debugger.
    var debuggingAppearance : ElementDebuggingAppearance { get }
    
    /// How to allow introspecting the element in the view debugger.
    var debuggingIntrospector : ElementDebuggingIntrospector { get }
}


public extension Element {
    var debuggingAppearance : ElementDebuggingAppearance {
        ElementDebuggingAppearance()
    }
    
    var debuggingIntrospector : ElementDebuggingIntrospector {
        ElementDebuggingIntrospector()
    }
}


public struct ElementDebuggingIntrospector {
    
}


public struct ElementDebuggingAppearance {
    var borderColor : UIColor? = .init(white: 0.0, alpha: 0.35)
}


extension Element {
    
    public var debugDescription : String {
        self.debugDescription(with: UIScreen.main.bounds.size)
    }
    
    public func debugDescription(with size : CGSize) -> String {
        self.debugDescription(with: size, depth: 0)
    }
    
    internal func debugDescription(with size : CGSize, depth : Int) -> String {
        let result = self.layout(frame: CGRect(origin: .zero, size: size))
        
        var list = [DebugDescriptionElementInfo]()
        result.appendTo(info: &list, depth: depth)
        
        return DebugDescriptionElementInfo.toString(list)
    }
}


fileprivate extension LayoutResultNode {
    func appendTo(info : inout [DebugDescriptionElementInfo], depth : Int) {
        info.append(DebugDescriptionElementInfo(
            depth: depth,
            element: self.element,
            frame: self.layoutAttributes.frame
        ))
        
        self.children.forEach { _, node in
            node.appendTo(info: &info, depth: depth + 1)
        }
    }
}


fileprivate struct DebugDescriptionElementInfo {
    var depth : Int
    var element : Element
    var frame : CGRect
    
    var stringValue : String {
        let inset = String.init(repeating: "  ", count: self.depth)
        
        let typeName = String(describing:type(of: self.element))
        let frameDescription = "Frame: (\(self.frame.origin.x), \(self.frame.origin.y), \(self.frame.size.width), \(self.frame.size.height))"
        
        let viewType = self.element.backingViewDescription(bounds: self.frame, subtreeExtent: nil)?.viewType
        let viewTypeDescription : String? = {
            guard let viewType = viewType else {
                return nil
            }
            
            return "UIView Type: \(String(describing: viewType))"
        }()
        
        let components : [String?] = [
            viewTypeDescription,
            frameDescription
        ]
        
        
        return inset + "| <\(typeName): \(components.compactMap({$0}).joined(separator: ", "))>"
    }
    
    static func toString(_ list : [Self]) -> String {
        let strings : [String] = list.map {
            $0.stringValue
        }
        
        return strings.joined(separator: "\n")
    }
}
