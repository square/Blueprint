import UIKit

/// Marker protocol used by generic extensions to native views (e.g. `UIView`).
public protocol NativeView {}

extension UIView: NativeView {}

extension NativeView where Self: UIView {

    /// Generates a view description for the receiving class.
    /// Example:
    /// ```
    /// let viewDescription = UILabel.describe { config in
    ///     config[\.text] = "Hello, world"
    ///     config[\.textColor] = UIColor.orange
    /// }
    /// ```
    /// - parameter configuring: A closure that is responsible for populating a configuration object.
    ///
    /// - returns: The resulting view description.
    public static func describe(_ configuring: (inout ViewDescription.Configuration<Self>) -> Void) -> ViewDescription {
        ViewDescription(Self.self, configuring: configuring)
    }
}

/// Marker protocol used by generic extensions to native views (e.g. `UIViewController`).
public protocol NativeUIViewController {}

extension UIViewController: NativeUIViewController {}

extension NativeUIViewController where Self: UIViewController {

    /// Generates a view description for the receiving class.
    /// Example:
    /// ```
    /// let viewDescription = UILabel.describe { config in
    ///     config[\.text] = "Hello, world"
    ///     config[\.textColor] = UIColor.orange
    /// }
    /// ```
    /// - parameter configuring: A closure that is responsible for populating a configuration object.
    ///
    /// - returns: The resulting view description.
    public static func describe(_ configuring: (inout ViewDescription.ControllerConfiguration<Self>) -> Void) -> ViewDescription {
        ViewDescription(Self.self, configuring: configuring)
    }
}

/// Contains a _description_ of a UIView instance. A description includes
/// logic to handle all parts of a view lifecycle from instantiation onward.
///
/// View descriptions include:
/// - The view's class.
/// - How an instance of the view should be instantiated.
/// - How to update a view instance by setting properties appropriately.
/// - Which subview of a view instance should be used as a contain for
///   additional subviews.
/// - How to animate transitions for appearance, layout changes, and
///   disappearance.
/// - Hooks to be called during lifecycle events.
///
/// A view description does **not** contain a concrete view instance. It simply
/// contains functionality for creating, updating, and animating view instances.
public struct ViewDescription {

    public var layoutTransition: LayoutTransition
    public var appearingTransition: VisibilityTransition?
    public var disappearingTransition: VisibilityTransition?

    let onAppear: LifecycleCallback?
    let onDisappear: LifecycleCallback?

    let frameRoundingBehavior: FrameRoundingBehavior

    let content: Content

    func ifView<Output>(_ ifView: (Content.View) -> Output, ifController: (Content.Controller) -> Output) -> Output {
        switch content {
        case .view(let view):
            return ifView(view)
        case .controller(let controller):
            return ifController(controller)
        }
    }

    /// Generates a view description for the given view class.
    /// - parameter viewType: The class of the described view.
    public init<View>(_ viewType: View.Type) where View: UIView {
        self.init(viewType, configuring: { _ in })
    }

    /// Generates a view description for the given view class.
    /// - parameter viewType: The class of the described view.
    /// - parameter configuring: A closure that is responsible for populating a configuration object.
    public init<View>(_ type: View.Type, configuring: (inout Configuration<View>) -> Void) {
        var configuration = Configuration<View>()
        configuring(&configuration)
        self.init(configuration: configuration)
    }

    /// Generates a view description for the given view class.
    /// - parameter viewType: The class of the described view.
    /// - parameter configuring: A closure that is responsible for populating a configuration object.
    public init<Controller>(_ type: Controller.Type, configuring: (inout ControllerConfiguration<Controller>) -> Void) {
        var configuration = ControllerConfiguration<Controller>()
        configuring(&configuration)
        self.init(configuration: configuration)
    }

    /// Generates a view description with the given configuration object.
    /// - parameter configuration: The configuration object.
    private init<View>(configuration: Configuration<View>) {

        content = .view(.init(configuration: configuration))

        layoutTransition = configuration.layoutTransition
        appearingTransition = configuration.appearingTransition
        disappearingTransition = configuration.disappearingTransition

        onAppear = configuration.onAppear
        onDisappear = configuration.onDisappear

        frameRoundingBehavior = configuration.frameRoundingBehavior
    }

    /// Generates a view description with the given configuration object.
    /// - parameter configuration: The configuration object.
    private init<View>(configuration: ControllerConfiguration<View>) {

        content = .controller(.init(configuration: configuration))

        layoutTransition = configuration.layoutTransition
        appearingTransition = configuration.appearingTransition
        disappearingTransition = configuration.disappearingTransition

        onAppear = configuration.onAppear
        onDisappear = configuration.onDisappear

        frameRoundingBehavior = configuration.frameRoundingBehavior
    }
}

extension ViewDescription {

    /// The available prioritization options for rounding frames to pixel boundaries.
    public enum FrameRoundingBehavior: Equatable {
        /// Prioritize preserving frame edge positions
        case prioritizeEdges
        /// Prioritize preserving frame sizes
        case prioritizeSize
    }

    /// Represents the configuration of a specific UIView type.
    public struct Configuration<View: UIView> {

        fileprivate var bindings: [PartialKeyPath<View>: AnyViewValueBinding] = [:]

        /// A closure that is applied to the native view instance during an update cycle.
        /// - parameter view: The native view instance.
        public typealias Update = (_ view: View) -> Void

        /// A closure that is responsible for instantiating an instance of the native view.
        /// The default value instantiates the view using `init(frame:)`.
        public var builder: () -> View

        /// An array of update closures.
        public var updates: [Update]

        /// A closure that takes a native view instance as the single argument, and
        /// returns a subview of that view into which child views should be added
        /// and managed.
        public var contentView: (View) -> UIView

        /// The transition to use during layout changes.
        public var layoutTransition: LayoutTransition = .inherited

        /// The transition to use when this view appears.
        public var appearingTransition: VisibilityTransition? = nil

        /// The transition to use when this view disappears.
        public var disappearingTransition: VisibilityTransition? = nil

        /// A hook to call when the element appears.
        public var onAppear: LifecycleCallback?

        /// A hook to call when the element disappears.
        public var onDisappear: LifecycleCallback?

        /// The prioritization method to use when snapping the native view's frame to pixel
        /// boundaries.
        ///
        /// When snapping views to pixel boundaries, Blueprint prioritizes placing frame edges as
        /// close to the correct value as possible. This ensures that flush edges stay flush after
        /// rounding, but can result in frame sizes growing or shrinking by 1 pixel in either axis.
        ///
        /// Backing views that are particularly sensitive to size changes can opt-in to prioritize
        /// preserving their frame size instead of maximally correct edges. This will guarantee
        /// frame sizes, with the tradeoff that their edges may no longer be flush to other edges as
        /// they were laid out.
        ///
        /// Generally you should not change this value except in specific circumstances when all
        /// criteria are met:
        /// - The backing view is sensitive to frame size, such as a text label.
        /// - And the backing view has a transparent background, so that overlapping frames or gaps
        ///   between frames are not visible.
        ///
        public var frameRoundingBehavior: FrameRoundingBehavior = .prioritizeEdges

        /// Initializes a default configuration object.
        public init() {
            builder = { View(frame: .zero) }
            updates = []
            contentView = { $0 }
        }

        fileprivate func typeChecked(view: UIView) -> View {
            guard let typedView = view as? View else {
                fatalError("A view of type \(type(of: view)) was used with a ViewDescription instance that expects views of type \(View.self)")
            }
            return typedView
        }
    }

    /// Represents the configuration of a specific UIViewController type.
    public struct ControllerConfiguration<Controller: UIViewController> {

        fileprivate var bindings: [PartialKeyPath<Controller>: AnyControllerValueBinding] = [:]

        /// A closure that is applied to the native view instance during an update cycle.
        /// - parameter view: The native view instance.
        public typealias Update = (_ controller: Controller) -> Void

        /// A closure that is responsible for instantiating an instance of the native view.
        /// The default value instantiates the view using `init(frame:)`.
        public var builder: () -> Controller

        /// An array of update closures.
        public var updates: [Update]

        /// A closure that takes a native view instance as the single argument, and
        /// returns a subview of that view into which child views should be added
        /// and managed.
        public var contentView: (Controller) -> UIView

        /// The transition to use during layout changes.
        public var layoutTransition: LayoutTransition = .inherited

        /// The transition to use when this view appears.
        public var appearingTransition: VisibilityTransition? = nil

        /// The transition to use when this view disappears.
        public var disappearingTransition: VisibilityTransition? = nil

        /// A hook to call when the element appears.
        public var onAppear: LifecycleCallback?

        /// A hook to call when the element disappears.
        public var onDisappear: LifecycleCallback?

        /// The prioritization method to use when snapping the native view's frame to pixel
        /// boundaries.
        ///
        /// When snapping views to pixel boundaries, Blueprint prioritizes placing frame edges as
        /// close to the correct value as possible. This ensures that flush edges stay flush after
        /// rounding, but can result in frame sizes growing or shrinking by 1 pixel in either axis.
        ///
        /// Backing views that are particularly sensitive to size changes can opt-in to prioritize
        /// preserving their frame size instead of maximally correct edges. This will guarantee
        /// frame sizes, with the tradeoff that their edges may no longer be flush to other edges as
        /// they were laid out.
        ///
        /// Generally you should not change this value except in specific circumstances when all
        /// criteria are met:
        /// - The backing view is sensitive to frame size, such as a text label.
        /// - And the backing view has a transparent background, so that overlapping frames or gaps
        ///   between frames are not visible.
        ///
        public var frameRoundingBehavior: FrameRoundingBehavior = .prioritizeEdges

        /// Initializes a default configuration object.
        public init() {
            builder = { Controller() }
            updates = []
            contentView = { $0.view }
        }

        fileprivate func typeChecked(controller: UIViewController) -> Controller {
            guard let typed = controller as? Controller else {
                fatalError("A view controller of type \(type(of: controller)) was used with a ViewDescription instance that expects views of type \(Controller.self)")
            }
            return typed
        }
    }
}

extension ViewDescription.Configuration {

    /// Adds the given update closure to the `updates` array.
    public mutating func apply(_ update: @escaping Update) {
        updates.append(update)
    }

    /// Subscript for values that are not optional. We must represent these values as optional so that we can
    /// return nil from the subscript in the case where no value has been assigned for the given keypath.
    ///
    /// When getting a value for a keypath:
    /// - If a value has previously been assigned, it will be returned.
    /// - If no value has been assigned, nil will be returned.
    ///
    /// When assigning a value for a keypath:
    /// - If a value is provided, it will be applied to the view.
    /// - If `nil` is provided, no value will be applied to the view (any previous assignment will be cleared).
    public subscript<Value>(keyPath: ReferenceWritableKeyPath<View, Value>) -> Value? {
        get {
            if let binding = bindings[keyPath] as? ValueBinding<Value> {
                return binding.value
            } else {
                return nil
            }
        }
        set {
            if let value = newValue {
                bindings[keyPath] = ValueBinding(keyPath: keyPath, value: value)
            } else {
                bindings[keyPath] = nil
            }
        }
    }

    /// Subscript for values that are optional.
    ///
    /// When getting a value for a keypath:
    /// - If a value has previously been assigned (including `nil`), it will be returned.
    /// - If no value has been assigned, nil will be returned.
    ///
    /// When assigning a value for a keypath:
    /// - Any provided value will be applied to the view (including `nil`). **This means that there is a difference
    ///   between the initial state of a view description (where the view's property will not be touched), and the
    ///   state after `nil` is assigned.** After assigning `nil` to an optional keypath, `view.property = nil` will
    ///   be called on the next update.
    public subscript<Value>(keyPath: ReferenceWritableKeyPath<View, Value?>) -> Value? {
        get {
            if let binding = bindings[keyPath] as? ValueBinding<Value> {
                return binding.value
            } else {
                return nil
            }
        }
        set {
            bindings[keyPath] = ValueBinding(keyPath: keyPath, value: newValue)
        }
    }
}


extension ViewDescription.ControllerConfiguration {

    /// Adds the given update closure to the `updates` array.
    public mutating func apply(_ update: @escaping Update) {
        updates.append(update)
    }

    /// Subscript for values that are not optional. We must represent these values as optional so that we can
    /// return nil from the subscript in the case where no value has been assigned for the given keypath.
    ///
    /// When getting a value for a keypath:
    /// - If a value has previously been assigned, it will be returned.
    /// - If no value has been assigned, nil will be returned.
    ///
    /// When assigning a value for a keypath:
    /// - If a value is provided, it will be applied to the view.
    /// - If `nil` is provided, no value will be applied to the view (any previous assignment will be cleared).
    public subscript<Value>(keyPath: ReferenceWritableKeyPath<Controller, Value>) -> Value? {
        get {
            if let binding = bindings[keyPath] as? ValueBinding<Value> {
                return binding.value
            } else {
                return nil
            }
        }
        set {
            if let value = newValue {
                bindings[keyPath] = ValueBinding(keyPath: keyPath, value: value)
            } else {
                bindings[keyPath] = nil
            }
        }
    }

    /// Subscript for values that are optional.
    ///
    /// When getting a value for a keypath:
    /// - If a value has previously been assigned (including `nil`), it will be returned.
    /// - If no value has been assigned, nil will be returned.
    ///
    /// When assigning a value for a keypath:
    /// - Any provided value will be applied to the view (including `nil`). **This means that there is a difference
    ///   between the initial state of a view description (where the view's property will not be touched), and the
    ///   state after `nil` is assigned.** After assigning `nil` to an optional keypath, `view.property = nil` will
    ///   be called on the next update.
    public subscript<Value>(keyPath: ReferenceWritableKeyPath<Controller, Value?>) -> Value? {
        get {
            if let binding = bindings[keyPath] as? ValueBinding<Value> {
                return binding.value
            } else {
                return nil
            }
        }
        set {
            bindings[keyPath] = ValueBinding(keyPath: keyPath, value: newValue)
        }
    }
}


extension ViewDescription {

    enum Content {
        case view(View)
        case controller(Controller)

        struct View {

            init<ViewType: UIView>(configuration: Configuration<ViewType>) {

                viewType = ViewType.self

                build = configuration.builder

                _apply = { view in
                    let typed = configuration.typeChecked(view: view)
                    for update in configuration.updates {
                        update(typed)
                    }
                    for binding in configuration.bindings {
                        binding.value.apply(to: typed)
                    }
                }

                _contentView = { view in
                    let typed = configuration.typeChecked(view: view)
                    return configuration.contentView(typed)
                }
            }

            var viewType: UIView.Type
            var build: () -> UIView

            private let _apply: (UIView) -> Void

            func apply(to view: UIView) {
                _apply(view)
            }

            private let _contentView: (UIView) -> UIView

            func contentView(in view: UIView) -> UIView {
                _contentView(view)
            }
        }

        struct Controller {

            init<ControllerType: UIViewController>(configuration: ControllerConfiguration<ControllerType>) {

                controllerType = ControllerType.self

                build = configuration.builder

                _apply = { controller in
                    let typed = configuration.typeChecked(controller: controller)

                    for update in configuration.updates {
                        update(typed)
                    }
                    for binding in configuration.bindings {
                        binding.value.apply(to: typed)
                    }
                }

                _contentView = { controller in
                    let typed = configuration.typeChecked(controller: controller)
                    return configuration.contentView(typed)
                }
            }

            public var controllerType: UIViewController.Type
            public var build: () -> UIViewController

            private let _apply: (UIViewController) -> Void

            public func apply(to view: UIViewController) {
                _apply(view)
            }

            private let _contentView: (UIViewController) -> UIView

            public func contentView(in controller: UIViewController) -> UIView {
                _contentView(controller)
            }
        }
    }
}


fileprivate protocol AnyViewValueBinding {

    func apply(to view: UIView)
}


extension ViewDescription.Configuration {

    fileprivate struct ValueBinding<Value>: AnyViewValueBinding {

        let keyPath: ReferenceWritableKeyPath<View, Value>
        let value: Value

        func apply(to anyView: UIView) {
            let view = anyView as! View
            view[keyPath: keyPath] = value
        }
    }
}


fileprivate protocol AnyControllerValueBinding {

    func apply(to controller: UIViewController)
}


extension ViewDescription.ControllerConfiguration {

    fileprivate struct ValueBinding<Value>: AnyControllerValueBinding {

        let keyPath: ReferenceWritableKeyPath<Controller, Value>
        let value: Value

        func apply(to anyController: UIViewController) {
            let controller = anyController as! Controller
            controller[keyPath: keyPath] = value
        }
    }
}
