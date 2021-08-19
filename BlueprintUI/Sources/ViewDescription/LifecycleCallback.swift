import Foundation

/// This is the type used by all lifecycle callback hooks.
///
/// - Tag: ElementLifecycle
///
/// # The Element Lifecycle
///
/// View-backed elements have a lifecycle with 3 states:
///
/// 1. **Unmounted**
///
///    This is the initial state of an element, before a render pass, as well as the final state,
///    after an element is removed.
///
/// 2. **Mounted**
///
///    When an element is present during a render pass, it is "mounted". This means the element's
///    backing view has been created and added to the hosting `BlueprintView`. However, the
///    element's backing view may not yet be visible, if the hosting view is not part of the view
///    hierarchy yet.
///
/// 3. **Visible**
///
///    Finally, when the hosting view is added to the view hierarchy, the element becomes visible.
///    If the hosting view is already in a view hierarchy when the element is mounted, it will
///    immediately transition to this state.
///
/// There are 4 lifecycle events that occur when an element transitions between these states. An
/// element will always be mounted before it is visible, and will disappear before it is unmounted.
///
/// The following diagram shows how an element may transition between states:
///
/// ```
///           ┌───onMount───┐   ┌──onAppear───┐
///           │             │   │             │
///   ┌───────┴───┐     ┌───▼───┴───┐     ┌───▼───────┐
///   │ Unmounted │     │  Mounted  │     │  Visible  │
///   └───────▲───┘     └───┬───▲───┘     └───┬───────┘
///           │             │   │             │
///           └──onUnmount──┘   └─onDisappear─┘
/// ```
///
public typealias LifecycleCallback = () -> Void
