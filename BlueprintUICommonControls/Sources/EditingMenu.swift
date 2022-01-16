//
//  EditingMenu.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 1/5/22.
//

import BlueprintUI
import Foundation
import UIKit


///
/// Allows showing the system's `UIMenuController` editing menu.
///
/// You can show the menu upon tap or long press:
/// ```
/// myElement.editingMenu(show: .onLongPress) {
///     EditingMenuItem.copying("A String")
///
///     EditingMenuItem(.select) {
///         print("Selected!")
///     }
/// }
/// ```
///
/// You can also show the menu as a result of another element's `onTap` closure,
/// using the trigger-based API:
/// ```
/// EditingMenu { menu in
///     MyRow(text: "Hello, World") {
///         menu.show()
///     }
/// } items: {
///     EditingMenuItem.copying("A String")
/// }
/// ```
public struct EditingMenu: Element {

    /// The wrapped element to display.
    public var wrapped: Element

    /// The editing items to show in the editing menu.
    public var items: [EditingMenuItem]

    let presentationMode: PresentationMode

    /// Creates a new editing menu, wrapping the provided element, and displaying the provided items.
    public init(
        show gesture: Gesture,
        wrapping: Element,
        @Builder<EditingMenuItem> with items: () -> [EditingMenuItem]
    ) {
        let items = items()

        precondition(items.isEmpty == false, "Must provide at least one `EditingMenuItem` to the `EditingMenu`.")

        presentationMode = .gesture(gesture)

        wrapped = wrapping
        self.items = items
    }

    /// Creates a new editing menu, wrapping the provided element, and displaying the provided items.
    public init(
        wrapping: (MenuTrigger) -> Element,
        @Builder<EditingMenuItem> items: () -> [EditingMenuItem]
    ) {
        let trigger = MenuTrigger()

        let items = items()

        precondition(items.isEmpty == false, "Must provide at least one `EditingMenuItem` to the `EditingMenu`.")

        presentationMode = .trigger(trigger)

        wrapped = wrapping(trigger)

        self.items = items
    }

    // MARK: Element

    public var content: ElementContent {
        ElementContent(child: wrapped)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        View.describe { config in

            config.builder = {
                View(presentationMode: presentationMode, frame: context.bounds)
            }

            config[\.items] = EditingMenuItem.resolved(with: items)
            config[\.presentationMode] = presentationMode
        }
    }
}


extension EditingMenu {

    /// The gesture to use to show the menu.
    public enum Gesture {

        /// The menu will be shown when the element is tapped.
        case onTap

        /// The menu will be shown when the element is long pressed.
        case onLongPress
    }

    /// A trigger that you can use to show the menu based on the result of some other
    /// action firing, such as the `onTap` or `onSelect` of another element.
    ///
    /// ```
    /// EditingMenu { menu in
    ///     MyRow(text: "Hello, World") {
    ///         menu.show()
    ///     }
    /// } items: {
    ///     EditingMenuItem.copying("A String")
    /// }
    /// ```
    public final class MenuTrigger {

        fileprivate var trigger: () -> Void = {}

        /// Call this method to show the menu.
        public func show() {
            trigger()
        }
    }
}


/// A single item in an editing menu.
public struct EditingMenuItem {

    /// The type of menu item.
    public var kind: Kind

    /// A callback, invoked when the user selects the menu item.
    public var onSelect: () -> Void

    /// Creates a new menu item of the given kind.
    public init(
        title: String,
        onSelect: @escaping () -> Void
    ) {
        kind = .custom(title)
        self.onSelect = onSelect
    }

    /// Creates a new menu item of the given kind.
    public init(
        _ kind: Kind.System,
        onSelect: @escaping () -> Void
    ) {
        self.kind = .system(kind)
        self.onSelect = onSelect
    }

    /// Creates a new menu item of the given kind.
    fileprivate init(
        kind: Kind,
        onSelect: @escaping () -> Void
    ) {
        self.kind = kind
        self.onSelect = onSelect
    }

    /// A `.copy` type item, which will copy the given string to the provided pasteboard.
    public static func copying(_ string: String, to pasteboard: UIPasteboard? = .general) -> Self {
        EditingMenuItem(.copy) {
            pasteboard?.string = string
        }
    }

    /// A `.copy` type item, which will copy the given image to the provided pasteboard.
    public static func copying(_ image: UIImage, to pasteboard: UIPasteboard? = .general) -> Self {
        EditingMenuItem(.copy) {
            pasteboard?.image = image
        }
    }

    /// A `.copy` type item, which will copy the given url to the provided pasteboard.
    public static func copying(_ url: URL, to pasteboard: UIPasteboard? = .general) -> Self {
        EditingMenuItem(.copy) {
            pasteboard?.url = url
        }
    }
}


extension Element {

    ///
    /// Allows showing the system's `UIMenuController` editing menu upon long press of the wrapped element.
    ///
    /// ```
    /// myElement.editingMenu(show: .onLongPress) {
    ///     EditingMenuItem.copying("A String")
    ///
    ///     EditingMenuItem(.select) {
    ///         print("Selected!")
    ///     }
    /// }
    /// ```
    public func editingMenu(
        show gesture: EditingMenu.Gesture,
        @Builder<EditingMenuItem> with items: () -> [EditingMenuItem]
    ) -> EditingMenu {
        EditingMenu(show: gesture, wrapping: self, with: items)
    }
}


extension EditingMenuItem {

    /// The menu item types you may place into a menu.
    public enum Kind: Equatable {

        /// A standard system item.
        case system(System)

        /// A custom item with a custom title.
        case custom(String)


        /// The system menu item kinds supported by an editing menu.
        ///
        /// **Note** – Matches methods from `UIResponderStandardEditActions`.
        public enum System: Equatable {

            case cut
            case copy
            case paste
            case delete
            case select
            case selectAll
            case toggleBoldface
            case toggleItalics
            case toggleUnderline
            case increaseSize
            case decreaseSize

            #if swift(>=5.5)
                @available(iOS 15.0, *)
                case printContent
                @available(iOS 15.0, *)
                case pasteAndGo
                @available(iOS 15.0, *)
                case pasteAndMatchStyle
                @available(iOS 15.0, *)
                case pasteAndSearch
            #endif
        }
    }
}


extension EditingMenuItem {

    fileprivate enum Resolved {

        typealias OnSelect = () -> Void

        case system(Kind.System, OnSelect)
        case custom(String, Selector, OnSelect)

        var selector: Selector {
            switch self {
            case .system(let kind, _):
                return kind.selector
            case .custom(_, let selector, _):
                return selector
            }
        }

        var onSelect: OnSelect {
            switch self {
            case .system(_, let onSelect):
                return onSelect
            case .custom(_, _, let onSelect):
                return onSelect
            }
        }

        var isCustom: Bool {
            switch self {
            case .system: return false
            case .custom: return true
            }
        }

        var isSystem: Bool {
            switch self {
            case .system: return true
            case .custom: return false
            }
        }

        var asMenuItem: UIMenuItem? {
            switch self {
            case .system:
                return nil

            case .custom(let title, let selector, _):
                return UIMenuItem(title: title, action: selector)
            }
        }
    }

    fileprivate static func resolved(with items: [EditingMenuItem]) -> [Resolved] {

        var customSelectors: [Selector] = [
            #selector(EditingMenu.View.customAction0),
            #selector(EditingMenu.View.customAction1),
            #selector(EditingMenu.View.customAction2),
            #selector(EditingMenu.View.customAction3),
            #selector(EditingMenu.View.customAction4),
            #selector(EditingMenu.View.customAction5),
            #selector(EditingMenu.View.customAction6),
            #selector(EditingMenu.View.customAction7),
            #selector(EditingMenu.View.customAction8),
            #selector(EditingMenu.View.customAction9),
        ]

        return items.map { item in

            switch item.kind {
            case .custom(let title):
                precondition(
                    customSelectors.isEmpty == false,
                    """
                    More than 10 custom actions were provided which is not supported.
                    More custom action selectors need to be added.
                    """
                )

                return .custom(title, customSelectors.removeFirst(), item.onSelect)

            case .system(let kind):
                return .system(kind, item.onSelect)
            }
        }
    }
}

extension EditingMenuItem.Kind.System {

    fileprivate var selector: Selector {

        let actions = UIResponderStandardEditActions.self

        switch self {
        case .cut:
            return #selector(actions.cut)
        case .copy:
            return #selector(actions.copy)
        case .paste:
            return #selector(actions.paste)
        case .delete:
            return #selector(actions.delete)
        case .select:
            return #selector(actions.select)
        case .selectAll:
            return #selector(actions.selectAll)
        case .toggleBoldface:
            return #selector(actions.toggleBoldface)
        case .toggleItalics:
            return #selector(actions.toggleItalics)
        case .toggleUnderline:
            return #selector(actions.toggleUnderline)
        case .increaseSize:
            return #selector(actions.increaseSize)
        case .decreaseSize:
            return #selector(actions.decreaseSize)

        #if swift(>=5.5)
            case .printContent:
                guard #available(iOS 15.0, *) else { fatalError() }
                return #selector(actions.printContent)
            case .pasteAndGo:
                guard #available(iOS 15.0, *) else { fatalError() }
                return #selector(actions.pasteAndGo)
            case .pasteAndMatchStyle:
                guard #available(iOS 15.0, *) else { fatalError() }
                return #selector(actions.pasteAndMatchStyle)
            case .pasteAndSearch:
                guard #available(iOS 15.0, *) else { fatalError() }
                return #selector(actions.pasteAndSearch)
        #endif
        }
    }
}


extension EditingMenu {

    enum PresentationMode {
        case trigger(MenuTrigger)
        case gesture(Gesture)
    }

    fileprivate final class View: UIView {

        var items: [EditingMenuItem.Resolved] = [] {
            didSet {
                updateMenuItemsIfVisible()
            }
        }

        var presentationMode: PresentationMode {
            didSet {
                presentationModeDidChange()
            }
        }

        private func presentationModeDidChange() {
            switch presentationMode {
            case .gesture(let gesture):
                switch gesture {
                case .onTap:
                    longPress.isEnabled = false
                    tapped.isEnabled = true

                case .onLongPress:
                    longPress.isEnabled = true
                    tapped.isEnabled = false
                }
            case .trigger(let trigger):
                longPress.isEnabled = false
                tapped.isEnabled = false

                trigger.trigger = { [weak self] in
                    self?.showMenu()
                }
            }
        }

        private let longPress: UILongPressGestureRecognizer
        private let tapped: UITapGestureRecognizer

        private let menu = UIMenuController.shared
        private var isShowingMenu: Bool = false

        init(presentationMode: PresentationMode, frame: CGRect) {

            self.presentationMode = presentationMode

            longPress = UILongPressGestureRecognizer()
            tapped = UITapGestureRecognizer()

            super.init(frame: frame)

            longPress.addTarget(self, action: #selector(handleLongPress))
            addGestureRecognizer(longPress)

            tapped.addTarget(self, action: #selector(handleTap))
            addGestureRecognizer(tapped)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didHideMenu),
                name: UIMenuController.didHideMenuNotification,
                object: nil
            )

            presentationModeDidChange()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        // MARK: UIView

        override var canBecomeFirstResponder: Bool {
            true
        }

        @objc override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            items.map(\.selector).contains(action)
        }

        // MARK: UIResponderStandardEditActions

        @objc override func cut(_ any: Any?) {
            perform(kind: .cut)
        }

        @objc override func copy(_ any: Any?) {
            perform(kind: .copy)
        }

        @objc override func paste(_ any: Any?) {
            perform(kind: .paste)
        }

        @objc override func delete(_ any: Any?) {
            perform(kind: .delete)
        }

        @objc override func select(_ any: Any?) {
            perform(kind: .select)
        }

        @objc override func selectAll(_ any: Any?) {
            perform(kind: .selectAll)
        }

        @objc override func toggleBoldface(_ any: Any?) {
            perform(kind: .toggleBoldface)
        }

        @objc override func toggleItalics(_ any: Any?) {
            perform(kind: .toggleItalics)
        }

        @objc override func toggleUnderline(_ any: Any?) {
            perform(kind: .toggleUnderline)
        }

        @objc override func increaseSize(_ any: Any?) {
            perform(kind: .increaseSize)
        }

        @objc override func decreaseSize(_ any: Any?) {
            perform(kind: .decreaseSize)
        }

        #if swift(>=5.5)

            @available(iOS 15.0, *)
            @objc override func printContent(_ any: Any?) {
                perform(kind: .printContent)
            }

            @available(iOS 15.0, *)
            @objc override func pasteAndGo(_ any: Any?) {
                perform(kind: .pasteAndGo)
            }

            @available(iOS 15.0, *)
            @objc override func pasteAndMatchStyle(_ any: Any?) {
                perform(kind: .pasteAndMatchStyle)
            }

            @available(iOS 15.0, *)
            @objc override func pasteAndSearch(_ any: Any?) {
                perform(kind: .pasteAndSearch)
            }

        #endif

        @objc func customAction0() {
            perform(custom: 0)
        }

        @objc func customAction1() {
            perform(custom: 1)
        }

        @objc func customAction2() {
            perform(custom: 2)
        }

        @objc func customAction3() {
            perform(custom: 3)
        }

        @objc func customAction4() {
            perform(custom: 4)
        }

        @objc func customAction5() {
            perform(custom: 5)
        }

        @objc func customAction6() {
            perform(custom: 6)
        }

        @objc func customAction7() {
            perform(custom: 7)
        }

        @objc func customAction8() {
            perform(custom: 8)
        }

        @objc func customAction9() {
            perform(custom: 9)
        }

        private func perform(custom index: Int) {
            let custom = items.filter { $0.isCustom }

            let action = custom[index]

            action.onSelect()
        }

        private func perform(kind kindToPerform: EditingMenuItem.Kind.System) {
            let action = items.first { item in
                switch item {
                case .system(let kind, _): return kind == kindToPerform
                case .custom: return false
                }
            }

            action?.onSelect()
        }

        @objc private func handleLongPress() {

            guard longPress.state == .began else { return }

            showMenu()
        }

        @objc private func handleTap() {

            guard tapped.state == .began else { return }

            showMenu()
        }

        @objc private func didHideMenu() {
            isShowingMenu = false

            if isFirstResponder {
                resignFirstResponder()
            }
        }

        private func showMenu() {

            guard isShowingMenu == false else { return }

            menu.menuItems = items.compactMap(\.asMenuItem)

            becomeFirstResponder()

            if #available(iOS 13.0, *) {
                menu.showMenu(from: self, rect: self.bounds)
            } else {
                menu.setTargetRect(bounds, in: self)
                menu.setMenuVisible(true, animated: true)
            }

            isShowingMenu = menu.isMenuVisible

            if isShowingMenu == false {
                resignFirstResponder()
            }
        }

        private func updateMenuItemsIfVisible() {
            guard isShowingMenu else { return }

            menu.menuItems = items.compactMap(\.asMenuItem)

            menu.update()
        }
    }
}
