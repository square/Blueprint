//
//  ElementPreview.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/14/20.
//

#if DEBUG && canImport(SwiftUI) && !arch(i386) && !arch(arm)

    import SwiftUI
    import UIKit


    /// A SwiftUI view which wraps a Blueprint element, which can be used to preview Blueprint elements
    /// via Xcode's preview functionality (enable via the `Editor > Canvas` menu).
    ///
    /// You can leverage `ElementPreview` by adding something like this to the bottom of the file which contains
    /// your Blueprint element, then as you edit and work on your element, the live preview will update to show the
    /// current state of your element:
    ///
    /// ```
    ///
    /// struct MyElement : Element {
    ///    ...
    /// }
    ///
    /// // Add this at the bottom of your element's source file.
    ///
    /// #if DEBUG && canImport(SwiftUI) && !arch(i386) && !arch(arm)
    ///
    /// import SwiftUI
    ///
    /// @available(iOS 13.0, *)
    /// struct MyElement_Preview: PreviewProvider {
    ///     static var previews: some View {
    ///         ElementPreview {
    ///             MyElement()
    ///         }
    ///     }
    /// }
    ///
    /// #endif
    ///
    /// ```
    /// Uhhh
    /// -----
    /// You're probably asking...
    /// Why the `!arch(i386)` check above? Turns out, a compiler bug!
    /// SwiftUI is only available on 64 bit devices, but the `canImport` check erroneously
    /// finds it when building to target iOS 10 devices. Until we drop iOS 10, this part of the check is also required.
    ///
    /// Details
    /// --------
    /// It's important that you keep the `PreviewProvider` in the same file as the element that you are editing.
    ///
    /// Why? Xcode uses a new feature called "Dynamic Replacement" to re-compile the source file you are editing,
    /// and inject it back into the running app which drives the preview. This only works on the level of a single
    /// file – if your preview and element live in separate files, Xcode needs to recompile your entire module
    /// which will slow down preview updates greatly.
    ///
    /// You can learn more about Xcode previews here: https://nshipster.com/swiftui-previews/
    ///
    /// Requirements
    /// --------
    /// You must be running Xcode 11 and Catalina to take advantage of live previews.
    /// They do not work on Mojave. Your selected simulator must also be an iOS 13 device.
    ///
    @available(iOS 13.0, *)
    public struct ElementPreview: View {

        // MARK: Properties

        /// A provider which returns a new element.
        public typealias ElementProvider = () -> Element

        private let name: String

        /// The types of previews to include in the Xcode preview.
        private let previewTypes: [PreviewType]

        /// The provider which vends a new element.
        private let provider: ElementProvider

        // MARK: Initialization

        /// Creates a new `ElementPreview` with several common devices that your users may use.
        public static func commonDevices(
            named name: String = "",
            with provider: @escaping ElementProvider
        ) -> Self {
            Self(
                named: name,
                with: [
                    .device(.iPhoneSE_1),
                    .device(.iPhone8),
                    .device(.iPhone8Plus),
                    .device(.iPhoneXs),
                    .device(.iPhoneXsMax),

                    .device(.iPadPro_9_7),
                    .device(.iPadPro_10_5),
                    .device(.iPadPro_12_9_3),
                ],
                with: provider
            )
        }

        /// Creates a new `ElementPreview` with the provided preview type.
        /// If you do not pass a preview type, `.thatFits` is used.
        public init(
            named name: String = "",
            with previewType: PreviewType = .thatFits(),
            with provider: @escaping ElementProvider
        ) {
            self.init(
                named: name,
                with: [previewType],
                with: provider
            )
        }

        /// Creates a new `ElementPreview` with the provided preview types.
        ///
        /// You can pass as many preview types as you would like to see your
        /// element rendered in those different environments.
        ///
        /// If you do not pass a preview type, `.thatFits` is used.
        public init(
            named name: String = "",
            with previewTypes: [PreviewType],
            with provider: @escaping ElementProvider
        ) {
            self.name = name
            self.previewTypes = previewTypes
            self.provider = provider
        }

        // MARK: View

        public var body: some View {
            ForEach(self.previewTypes, id: \.identifier) { previewType in
                previewType.previewView(
                    with: self.name,
                    for: self.provider()
                )
            }
        }
    }


    @available(iOS 13.0, *)
    extension ElementPreview {

        fileprivate struct ElementView: UIViewRepresentable {

            var element: Element

            func makeUIView(context: Context) -> BlueprintView {
                let view = BlueprintView()
                view.backgroundColor = .clear
                view.element = element

                return view
            }

            func updateUIView(_ view: BlueprintView, context: Context) {
                view.element = element
            }
        }

        /// The preview type to use to display an element in an Xcode preview.
        ///
        /// We provide three preview types: A specific device type, a fixed size, and the size that fits the view.
        public enum PreviewType {

            /// The preview will be inside the provided device (eg, iPhone X).
            ///
            /// **Note**: You can use the provided extension on `PreviewDevice`
            /// to access devices in a type-safe way, eg: `.device(.iPhone7).`
            case device(PreviewDevice)

            /// The preview will be the provided size
            case fixed(width: CGFloat, height: CGFloat)

            /// The preview will be as large as needed to preview the content.
            case thatFits(padding: CGFloat = 10.0)

            public var identifier: AnyHashable {
                switch self {
                case .device(let device): return device.rawValue
                case .fixed(let width, let height): return "(\(width), \(height))"
                case .thatFits(let padding): return "thatFits (\(padding)"
                }
            }

            public func previewView(
                with name: String,
                for element: Element
            ) -> AnyView {

                let formattedName: String = {
                    if name.isEmpty == false {
                        return " – " + name
                    } else {
                        return ""
                    }
                }()

                switch self {
                case .device(let device):
                    return AnyView(
                        constrained(element: element)
                            .previewDevice(.init(rawValue: device.rawValue))
                            .previewDisplayName(device.rawValue + formattedName)
                    )

                case .fixed(let width, let height):
                    return AnyView(
                        constrained(element: element)
                            .previewLayout(.fixed(width: width, height: height))
                            .previewDisplayName("Fixed Size: (\(width), \(height))" + formattedName)
                    )

                case .thatFits(let padding):
                    return AnyView(
                        constrained(element: element)
                            .previewLayout(.sizeThatFits)
                            .previewDisplayName("Size That Fits" + formattedName)
                            .padding(.all, padding)
                    )
                }
            }

            private func constrained(
                element: Element
            ) -> some View {

                /// `GeometryReader` differs between iOS 13 and iOS 14.
                /// On iOS 13; the `GeometryReader` reports back the size
                /// of its child. In iOS 14; it reports the size of the device within a preview.

                if #available(iOS 14.0, *) {
                    return AnyView(ElementView(element: element))
                } else {
                    return AnyView(SwiftUI.GeometryReader { info in
                        ElementView(
                            element: ConstrainedSize(
                                width: .atMost(info.size.width),
                                height: .atMost(info.size.height),
                                wrapping: element
                            )
                        )
                    })
                }
            }
        }
    }

    /// The available devices to be used for previewing elements in an Xcode preview.
    ///
    /// Via https://developer.apple.com/documentation/swiftui/securefield/3289399-previewdevice
    @available(iOS 13.0, *)
    extension PreviewDevice {

        /// iPhone 7

        public static var iPhone7 = PreviewDevice("iPhone 7")
        public static var iPhone7Plus = PreviewDevice("iPhone 7 Plus")

        /// iPhone 8

        public static var iPhone8 = PreviewDevice("iPhone 8")
        public static var iPhone8Plus = PreviewDevice("iPhone 8 Plus")

        /// iPhone SE

        public static var iPhoneSE_1: PreviewDevice {
            if #available(iOS 13.4.1, *) {
                return PreviewDevice("iPhone SE (1st generation)")
            } else {
                return PreviewDevice("iPhone SE")
            }
        }

        @available(iOS 13.4.1, *)
        public static var iPhoneSE_2: PreviewDevice {
            PreviewDevice("iPhone SE (2nd generation)")
        }

        /// iPhone X

        public static var iPhoneX = PreviewDevice("iPhone X")

        public static var iPhoneXs = PreviewDevice("iPhone Xs")
        public static var iPhoneXsMax = PreviewDevice("iPhone Xs Max")

        /// iPhone Xr

        public static var iPhoneXr = PreviewDevice("iPhone Xr")

        /// iPad Mini

        public static var iPadMini_4 = PreviewDevice("iPad mini 4")
        public static var iPadMini_5 = PreviewDevice("iPad mini (5th generation)")

        /// iPad Air

        public static var iPadAir_2 = PreviewDevice("iPad Air 2")
        public static var iPadAir_3 = PreviewDevice("iPad Air (3rd generation)")

        /// iPad

        public static var iPad_5 = PreviewDevice("iPad (5th generation)")
        public static var iPad_6 = PreviewDevice("iPad (6th generation)")

        /// iPad Pro

        public static var iPadPro_9_7 = PreviewDevice("iPad Pro (9.7-inch)")

        public static var iPadPro_10_5 = PreviewDevice("iPad Pro (10.5-inch)")

        public static var iPadPro_11_1 = PreviewDevice("iPad Pro (11-inch) (1st generation)")
        public static var iPadPro_11_2 = PreviewDevice("iPad Pro (11-inch) (2nd generation)")

        public static var iPadPro_12_9_1 = PreviewDevice("iPad Pro (12.9-inch)")
        public static var iPadPro_12_9_2 = PreviewDevice("iPad Pro (12.9-inch) (2nd generation)")
        public static var iPadPro_12_9_3 = PreviewDevice("iPad Pro (12.9-inch) (3rd generation)")
    }

#endif
