//
//  LayoutWriter.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 10/7/20.
//


/// A parent element which allows arbitrary, custom layout and positioning of its children.
///
/// Instead of creating a custom `Element` with a custom `Layout`, you might use
/// this element to create a customized layout in a more lightweight way.
///
/// ```
/// LayoutWriter { context, layout in
///     layout.add(with: myFrame, child: myElement)
///     layout.add(with: myOtherFrame, child: myOtherElement)
///
///     layout.sizing = .unionOfChildren
/// }
/// ```
public struct LayoutWriter : Element {
    
    //
    // MARK: Initialization
    //
    
    /// Creates a new instance of the LayoutWriter with the custom layout provided by the builder.
    ///
    /// The parameters to the closure are the `Context`, which provides information about
    /// the environment and sizing of the layout, and the `Builder` itself, which you use to
    /// add child elements to the layout.
    public init(_ build : @escaping Build) {
        self.build = build
    }
    
    /// The builder type passed to the `LayoutWriter` initializer.
    public typealias Build = (Context, inout Builder) -> ()
    
    /// The builder used to create the custom layout.
    public let build : Build
    
    //
    // MARK: Element
    //
    
    public var content: ElementContent {
        ElementContent { size, env in
            var builder = Builder()
            self.build(Context(size: size, environment: env), &builder)
            return InnerElement(builder: builder)
        }
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        nil
    }
}


extension LayoutWriter {
    
    /// The builder is the primary surface area you interact with when using a `LayoutWriter`.
    ///
    /// It provides you the ability to manage the sizing and measurement of the final layout,
    /// alongside methods to add and manage the children of the layout.
    public struct Builder {
        
        //
        // MARK: Managing Sizing
        //
        
        /// How the size of the layout should be calculated. Defaults to `.unionOfChildren`,
        /// which means the size will be big enough to contain the frames of all contained children.
        public var sizing : Sizing = .unionOfChildren
        
        //
        // MARK: Managing Children
        //
        
        /// The children of the custom layout, which specifies the child element and its frame.
        ///
        /// Note
        /// ----
        /// You rarely need to access this property directly. Instead, add children via
        /// the various provided `add(...)` methods. However, if you're `map`-ing over an array
        /// or other collection of content, using this property directly is useful.
        ///
        public var children : [Child] = []
        
        /// Adds a new child element to the layout with the provided frame.
        public mutating func add(
            with frame: CGRect,
            child : Element
        ) {
            self.children.append(.init(frame: frame, element: child))
        }
        
        /// Adds a new child element to the layout with the provided frame.
        /// The frame is passed to the child provider.
        public mutating func add(
            with frame: CGRect,
            child : (CGRect) -> Element
        ) {
            self.add(with: frame, child: child(frame))
        }
        
        /// Adds a new child element to the layout with the provided frame.
        /// The frame is passed to the child provider.
        public mutating func add(
            with frame: () -> CGRect,
            child : (CGRect) -> Element
        ) {
            let frame = frame()
            self.add(with: frame, child: child(frame))
        }
        
        /// Adds a new child element to the layout.
        /// Using this method is helpful if you need to calculate both the frame and the element content in a single pass.
        public mutating func add(_ child : () -> (CGRect, Element)) {
            let result = child()
            self.add(with: result.0, child: result.1)
        }
        
        /// Enumerates each of the children, allowing you to modify them in place,
        /// eg to align them all along a common alignment axis or to set a uniform size.
        public mutating func modifyEach(using change : (inout Child) -> ()) {
            self.children = children.map {
                var updated = $0
                change(&updated)
                return updated
            }
        }
    }
    
    /// Provides the relevant information about the context in which the layout is occurring.
    public struct Context {
        
        /// The size constraint the layout is occurring in.
        public var size : SizeConstraint
        
        /// The environment the layout is occurring in.
        public var environment : Environment
    }
    
    /// Controls the sizing calculation of the custom layout.
    public enum Sizing : Equatable {
        
        /// Ensures that the final size of element is large enough to fit all children, starting from (0,0).
        case unionOfChildren
        
        /// Fixes the layout size to the provided size.
        case fixed(CGSize)
    }
    
    /// A child of the custom layout, providing its frame and element.
    public struct Child {
        
        /// The frame of the element in the coordinate space of the custom layout.
        public var frame : CGRect
        
        /// The element to be displayed.
        public var element : Element
        
        /// Creates a new child element.
        public init(
            frame : CGRect,
            element : Element
        ) {
            self.frame = frame
            self.element = element
        }
    }
}


extension LayoutWriter {
    
    /// We bounce to an inner element so we can provide the environment.
    private struct InnerElement : Element {
        var builder : Builder
        
        // MARK: Element
        
        var content: ElementContent {
            ElementContent(layout: Layout(builder: self.builder)) { builder in
                for child in self.builder.children {
                    builder.add(element: child.element)
                }
            }
        }
        
        func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
            nil
        }
        
        // MARK: Layout
        
        private struct Layout : BlueprintUI.Layout {
            var builder : Builder
            
            func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
                switch builder.sizing {
                case .unionOfChildren:
                    return builder.children.reduce(CGRect.zero) { rect, child in
                        rect.union(child.frame)
                    }.size
                    
                case .fixed(let size):
                    return size
                }
            }
            
            func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
                self.builder.children.map { child in
                    .init(frame: child.frame)
                }
            }
        }
    }
}
