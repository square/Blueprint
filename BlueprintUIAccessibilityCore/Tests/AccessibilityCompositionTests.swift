import BlueprintUI
import XCTest
@testable import BlueprintUIAccessibilityCore


class AccessibilityCompositionTests: XCTestCase {

    class Interactive: UIControl {
        var action: () -> Bool
        init(_ name: String, action: @escaping () -> Bool = { false }) {
            self.action = action
            super.init(frame: .zero)
            isEnabled = true
            accessibilityLabel = name
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func accessibilityActivate() -> Bool {
            action()
        }
    }

    class InteractiveWithCustomAction: UIControl {
        var action: () -> Bool
        init(_ label: String, action: @escaping () -> Bool) {
            self.action = action
            super.init(frame: .zero)
            isEnabled = true
            accessibilityLabel = label
            accessibilityTraits = .button
            accessibilityActivationPoint = CGPoint(x: 20, y: 20)
            accessibilityCustomActions = [UIAccessibilityCustomAction(name: "Interactive Action", actionHandler: { _ in
                action()
            })]
        }

        @MainActor required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func accessibilityActivate() -> Bool {
            action()
        }

    }

    func test_basic_aggregation() {
        let accessibilityContainer = NSObject()

        let elements = (1...3).map { int in
            let element = UIAccessibilityElement(accessibilityContainer: accessibilityContainer)
            element.accessibilityLabel = "Label \(int)"
            element.accessibilityValue = "Value \(int)"
            element.accessibilityHint = "Hint \(int)"
            element.accessibilityIdentifier = "Identifier \(int)"
            return element
        }

        let combined = AccessibilityComposition.CompositeRepresentation(elements) {}
        let applied = AccessibilityCombinableTestObject()
        applied.applyAccessibility(combined)

        XCTAssertEqual(applied.accessibilityLabel, "Label 1, Label 2, Label 3")
        XCTAssertEqual(applied.accessibilityValue, "Value 1, Value 2, Value 3")
        XCTAssertEqual(applied.accessibilityHint, "Hint 1, Hint 2, Hint 3")
        XCTAssertEqual(applied.accessibilityIdentifier, "Identifier 1-Identifier 2-Identifier 3")
    }

    func test_traits_aggregation() {
        let accessibilityContainer = NSObject()

        let header = UIAccessibilityElement(accessibilityContainer: accessibilityContainer)
        header.accessibilityTraits = .header

        let image = UIAccessibilityElement(accessibilityContainer: accessibilityContainer)
        image.accessibilityTraits = .image

        let staticText = UIAccessibilityElement(accessibilityContainer: accessibilityContainer)
        staticText.accessibilityTraits = .staticText

        let interactiveTrait = UIAccessibilityElement(accessibilityContainer: accessibilityContainer)
        interactiveTrait.accessibilityTraits = .button

        let combined = AccessibilityComposition.CompositeRepresentation([header, image, staticText, interactiveTrait]) {}
        let applied = AccessibilityCombinableTestObject()
        applied.applyAccessibility(combined)

        XCTAssertEqual(
            UIAccessibilityTraits.none,
            applied.accessibilityTraits.symmetricDifference([.header, .image, .staticText, .button])
        )

        applied.applyAccessibility(nil)
        XCTAssertEqual(
            UIAccessibilityTraits.none,
            applied.accessibilityTraits
        )

        // Excludes interactive trait.
        applied.applyAccessibility(combined, mergeInteractiveSingleChild: false)
        XCTAssertEqual(
            UIAccessibilityTraits.none,
            applied.accessibilityTraits.symmetricDifference([.header, .image, .staticText])
        )
    }

    func test_rotor_aggregation() {
        let accessibilityContainer = NSObject()

        let elements = (1...3).map { int in
            let element = UIAccessibilityElement(accessibilityContainer: accessibilityContainer)
            element.accessibilityCustomRotors = [
                UIAccessibilityCustomRotor(name: "Rotor \(int)", itemSearch: { _ in
                    UIAccessibilityCustomRotorItemResult(targetElement: NSObject(), targetRange: nil)
                }),
            ]
            return element
        }

        let combined = AccessibilityComposition.CompositeRepresentation(elements) {}
        let applied = AccessibilityCombinableTestObject()
        applied.applyAccessibility(combined)

        XCTAssertEqual(applied.accessibilityCustomRotors?.count, 3)
        XCTAssertEqual(applied.accessibilityCustomRotors?[0].name, "Rotor 1")
        XCTAssertEqual(applied.accessibilityCustomRotors?[1].name, "Rotor 2")
        XCTAssertEqual(applied.accessibilityCustomRotors?[2].name, "Rotor 3")
    }

    func test_action_aggregation() {
        let accessibilityContainer = NSObject()

        let elements = (1...3).map { int in
            let element = UIAccessibilityElement(accessibilityContainer: accessibilityContainer)
            element.accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: "Action \(int)", actionHandler: { _ in
                    true
                }),
            ]
            return element
        }

        let combined = AccessibilityComposition.CompositeRepresentation(elements) {}
        let applied = AccessibilityCombinableTestObject()
        applied.applyAccessibility(combined)

        XCTAssertEqual(applied.accessibilityCustomActions?.count, 3)
        XCTAssertEqual(applied.accessibilityCustomActions?[0].name, "Action 1")
        XCTAssertEqual(applied.accessibilityCustomActions?[1].name, "Action 2")
        XCTAssertEqual(applied.accessibilityCustomActions?[2].name, "Action 3")
    }

    func test_customContent_aggregation() {
        class ContentProvider: NSObject, AXCustomContentProvider {
            var accessibilityCustomContent: [AXCustomContent]!
            init(label: String, value: String) {
                accessibilityCustomContent = [
                    AXCustomContent(label: label, value: value),
                ]
            }
        }

        let elements = (1...3).map { int in
            ContentProvider(label: "Label \(int)", value: "Value \(int)")
        }
        let combined = AccessibilityComposition.CompositeRepresentation(elements) {}

        let applied = AccessibilityCombinableTestObject()
        applied.applyAccessibility(combined)


        XCTAssertEqual(applied.accessibilityCustomContent?.count, 3)
        XCTAssertEqual(applied.accessibilityCustomContent?[0].label, "Label 1")
        XCTAssertEqual(applied.accessibilityCustomContent?[0].value, "Value 1")

        XCTAssertEqual(applied.accessibilityCustomContent?[1].label, "Label 2")
        XCTAssertEqual(applied.accessibilityCustomContent?[1].value, "Value 2")

        XCTAssertEqual(applied.accessibilityCustomContent?[2].label, "Label 3")
        XCTAssertEqual(applied.accessibilityCustomContent?[2].value, "Value 3")
    }


    func test_interactive_element_actions() {


        var activated = [Int]()

        let elements = (1...3).map { int in
            Interactive("Item \(int)") {
                activated.append(int)
                return true
            }
        }
        let combined = AccessibilityComposition.CompositeRepresentation(elements) {}
        XCTAssertEqual(combined.interactiveChildren?.count, 3)

        //  Combination of solely interactive elements should result in the first element being promoted, its action becoming the default activation, and subsequent elements being combined into it.
        let applied = AccessibilityCombinableTestObject()
        applied.applyAccessibility(combined)


        let activation = applied.accessibilityActivate()
        XCTAssertTrue(activation)
        XCTAssertEqual(activated, [1])

        guard let actions = applied.accessibilityCustomActions else { XCTFail("Actions was nil!"); return }
        XCTAssertEqual(actions.count, 2)

        for action in actions {
            let result = action.activate()
            XCTAssertTrue(result)
        }

        XCTAssertEqual(activated, [1, 2, 3])
    }

    func test_single_interactive_element_() {



        class NonInteractive: UIView {
            init(_ label: String) {
                super.init(frame: .zero)
                isAccessibilityElement = true
                accessibilityLabel = label
            }

            required init?(coder: NSCoder) {
                fatalError("lol")
            }
        }

        let interactive = [Interactive("Be sure to include me!")]

        let nonInteractive = ["Foo", "Bar", "Baz"].map { label in
            NonInteractive(label)
        }

        let combined = AccessibilityComposition.CompositeRepresentation(interactive + nonInteractive) {}
        let applied = AccessibilityCombinableTestObject()
        applied.applyAccessibility(combined)

        XCTAssertEqual(combined.interactiveChildren?.count, 1)

        XCTAssertEqual(applied.accessibilityLabel, "Foo, Bar, Baz, Be sure to include me!")

        XCTAssertNil(applied.accessibilityCustomActions)
    }

    func test_multiple_interactive_elements_() {

        class NonInteractive: UIView {
            init(_ label: String) {
                super.init(frame: .zero)
                isAccessibilityElement = true
                accessibilityLabel = label
            }

            required init?(coder: NSCoder) {
                fatalError("lol")
            }
        }

        let interactive = [Interactive("Don't include me!"), Interactive("Don't include me either!")]

        let nonInteractive = ["Foo", "Bar", "Baz"].map { label in
            NonInteractive(label)
        }

        let combined = AccessibilityComposition.CompositeRepresentation(interactive + nonInteractive) {}
        let applied = AccessibilityCombinableTestObject()
        applied.applyAccessibility(combined)

        XCTAssertEqual(combined.interactiveChildren?.count, 2)

        XCTAssertEqual(applied.accessibilityLabel, "Foo, Bar, Baz")

        XCTAssertEqual(
            applied.accessibilityCustomActions?.map { $0.name },
            ["Don't include me!", "Don't include me either!"]
        )

    }



    func test_basicValues() {
        let combinable = AccessibilityCombinableTestObject()

        let elements = (1...3).map { int in
            let element = UIAccessibilityElement(accessibilityContainer: combinable)
            element.accessibilityLabel = "Label \(int)"
            element.accessibilityValue = "Value \(int)"
            element.accessibilityHint = "Hint \(int)"
            element.accessibilityIdentifier = "Identifier \(int)"
            return element
        }

        let combined = AccessibilityComposition.CompositeRepresentation(elements) {}
        combinable.applyAccessibility(combined)
        XCTAssertNil(combinable.accessibilityInteractions?.activate)
        XCTAssertNil(combinable.accessibilityInteractions?.activationPoint)

        XCTAssertEqual(combinable.accessibilityLabel, "Label 1, Label 2, Label 3")
        XCTAssertEqual(combinable.accessibilityValue, "Value 1, Value 2, Value 3")
        XCTAssertEqual(combinable.accessibilityHint, "Hint 1, Hint 2, Hint 3")
        XCTAssertEqual(combinable.accessibilityIdentifier, "Identifier 1-Identifier 2-Identifier 3")
        XCTAssertTrue(combinable.hasAccessibilityRepresentation)
    }

    func test_hasAccessibilityRepresentation_givenEmptyAccessibility() {
        let combinable = AccessibilityCombinableTestObject()

        let elements = (1...3).map { int in
            let element = UIAccessibilityElement(accessibilityContainer: combinable)
            element.accessibilityLabel = nil
            element.accessibilityValue = nil
            element.accessibilityHint = nil
            element.accessibilityIdentifier = "Identifier \(int)"
            return element
        }

        let combined = AccessibilityComposition.CompositeRepresentation(elements) {}
        combinable.applyAccessibility(combined)
        XCTAssertEqual(combinable.accessibilityIdentifier, "Identifier 1-Identifier 2-Identifier 3")
        XCTAssertFalse(combinable.hasAccessibilityRepresentation)
    }

    func test_blockWhenNotAccessible_givenPopulatedAccessibility() {
        let view = AccessibilityComposition.CombinableView()
        view.blockWhenNotAccessible = true
        (1...3)
            .map { int in
                let subview = UIView()
                subview.isAccessibilityElement = true
                subview.accessibilityLabel = "Label \(int)"
                subview.accessibilityValue = "Value \(int)"
                subview.accessibilityHint = "Hint \(int)"
                subview.accessibilityIdentifier = "Identifier \(int)"
                return subview
            }
            .forEach {
                view.addSubview($0)
            }
        // The accessibility representation is combined upon layout.
        view.setNeedsLayout()
        view.layoutIfNeeded()

        XCTAssertEqual(view.accessibilityLabel, "Label 1, Label 2, Label 3")
        XCTAssertEqual(view.accessibilityValue, "Value 1, Value 2, Value 3")
        XCTAssertEqual(view.accessibilityHint, "Hint 1, Hint 2, Hint 3")
        XCTAssertEqual(view.accessibilityIdentifier, "Identifier 1-Identifier 2-Identifier 3")
        XCTAssertTrue(view.isAccessibilityElement)
    }

    func test_blockWhenNotAccessible_givenEmptyAccessibility() {
        let view = AccessibilityComposition.CombinableView()
        view.blockWhenNotAccessible = true
        (1...3)
            .map { int in
                let subview = UIView()
                subview.isAccessibilityElement = true
                subview.accessibilityLabel = nil
                subview.accessibilityValue = nil
                subview.accessibilityHint = nil
                subview.accessibilityIdentifier = "Identifier \(int)"
                return subview
            }
            .forEach {
                view.addSubview($0)
            }
        // The accessibility representation is combined upon layout.
        view.setNeedsLayout()
        view.layoutIfNeeded()

        XCTAssertNil(view.accessibilityLabel)
        XCTAssertNil(view.accessibilityValue)
        XCTAssertNil(view.accessibilityHint)
        XCTAssertEqual(view.accessibilityIdentifier, "Identifier 1-Identifier 2-Identifier 3")
        XCTAssertFalse(view.isAccessibilityElement, "The view should not be accessible.")
    }


    func test_applyAccessibility() {



        var activationCount = 0
        let interactive = InteractiveWithCustomAction("Please include me!", action: {
            activationCount += 1
            return true
        })
        interactive.accessibilityValue = "Please include me!"
        interactive.accessibilityHint = "Please include me!"
        interactive.accessibilityIdentifier = "Please include me!"

        let nonInteractive = (1...3).map { int in
            let element = UIAccessibilityElement(accessibilityContainer: NSObject())
            element.accessibilityLabel = "Label \(int)"
            element.accessibilityValue = "Value \(int)"
            element.accessibilityHint = "Hint \(int)"
            element.accessibilityIdentifier = "Identifier \(int)"
            element.accessibilityTraits = .header
            return element
        }

        var invalidatorCount = 0
        let combined = AccessibilityComposition.CompositeRepresentation([interactive] + nonInteractive) {
            invalidatorCount += 1
        }

        let applied = AccessibilityCombinableTestObject()
        applied.applyAccessibility(combined, mergeInteractiveSingleChild: true)

        XCTAssertEqual(combined.interactiveChildren?.count, 1)

        XCTAssertEqual(applied.accessibilityLabel, "Label 1, Label 2, Label 3, Please include me!")
        XCTAssertEqual(applied.accessibilityValue, "Value 1, Value 2, Value 3, Please include me!")
        XCTAssertEqual(applied.accessibilityHint, "Hint 1, Hint 2, Hint 3, Please include me!")
        XCTAssertEqual(applied.accessibilityIdentifier, "Identifier 1-Identifier 2-Identifier 3-Please include me!")
        XCTAssertEqual(
            UIAccessibilityTraits.none,
            applied.accessibilityTraits.symmetricDifference([.header, .button])
        )

        XCTAssertNotNil(applied.accessibilityInteractions?.activate)
        let result = applied.accessibilityInteractions?.activate?()
        XCTAssertTrue(result ?? false)
        XCTAssertEqual(activationCount, 1)
        XCTAssertEqual(invalidatorCount, 1) // Activating the override should invalidate our state

        XCTAssertEqual(applied.accessibilityInteractions?.activationPoint ?? .zero, CGPoint(x: 20, y: 20))

        XCTAssertEqual(applied.accessibilityCustomActions?.count, 1)
        let interiorAction = applied.accessibilityCustomActions?.first
        let interiorActionResult = interiorAction!.activate()
        XCTAssertTrue(interiorActionResult)
        XCTAssertEqual(activationCount, 2)
        XCTAssertEqual(invalidatorCount, 1) // InteriorAction is an inherited vanilla customAction and shouldn't invalidate our state
    }

    func test_Adjustable_single() {

        var value = 0
        let adjustable = Adjustable(increment: { value += 1 }, decrement: { value -= 1 })
        adjustable.accessibilityIncrement() // set to 1

        let element = UIAccessibilityElement(accessibilityContainer: NSObject())
        element.accessibilityLabel = "Adjustable"
        let applied = AccessibilityCombinableTestObject()

        let combined = AccessibilityComposition.CompositeRepresentation([adjustable, element]) { applied.needsAccessibilityUpdate = true }

        applied.applyAccessibility(combined, mergeInteractiveSingleChild: true)

        XCTAssertEqual(combined.interactiveChildren?.count, 1)

        XCTAssertEqual(applied.accessibilityLabel, "Adjustable")

        XCTAssertEqual(value, 1)

        XCTAssertTrue(applied.accessibilityTraits.contains(.adjustable))

        applied.accessibilityDecrement() // set back to 0
        XCTAssertEqual(value, 0)

    }

    func test_Adjustable_multiple() {

        var adjustableValue = 0
        let adjustable = Adjustable(increment: { adjustableValue += 1 }, decrement: { adjustableValue -= 1 })

        var activationCount = 0
        let interactive = InteractiveWithCustomAction("Please include me!", action: {
            activationCount += 1
            return true
        })

        let element = UIAccessibilityElement(accessibilityContainer: NSObject())
        element.accessibilityLabel = "Not interactive"
        let applied = AccessibilityCombinableTestObject()

        let combined = AccessibilityComposition.CompositeRepresentation([adjustable, element, interactive]) { applied.needsAccessibilityUpdate = true }

        applied.applyAccessibility(combined, mergeInteractiveSingleChild: true)

        XCTAssertEqual(combined.interactiveChildren?.count, 2)

        XCTAssertEqual(applied.accessibilityLabel, "Not interactive")


        XCTAssertEqual(
            applied.accessibilityCustomActions?.map { $0.name },
            ["Increment", "Decrement", "Please include me!", "Interactive Action"]
        )


        XCTAssertEqual(adjustableValue, 0)
        applied.accessibilityIncrement() // Should NOT increment
        XCTAssertEqual(adjustableValue, 0)
        XCTAssertFalse(applied.accessibilityActivate()) // Should NOT increment
        XCTAssertEqual(activationCount, 0)


        let incrementAction = applied.accessibilityCustomActions?.first(where: { $0.name == "Increment" })
        XCTAssertTrue(incrementAction?.activate() ?? false) // Should increment to one
        XCTAssertEqual(adjustableValue, 1)

        let decrementAction = applied.accessibilityCustomActions?.first(where: { $0.name == "Decrement" })
        XCTAssertTrue(decrementAction?.activate() ?? false) // Should decrement back to zero
        XCTAssertEqual(adjustableValue, 0)

        let activateAction = applied.accessibilityCustomActions?.first(where: { $0.name == "Please include me!" })
        XCTAssertTrue(activateAction?.activate() ?? false) // Should increment activation count
        XCTAssertEqual(activationCount, 1)

    }

    private final class Adjustable: UIControl {
        init(increment: @escaping () -> Void, decrement: @escaping () -> Void) {
            self.increment = increment
            self.decrement = decrement
            super.init(frame: .zero)
        }

        @MainActor required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var increment: () -> Void
        var decrement: () -> Void

        override func accessibilityIncrement() {
            increment()
        }

        override func accessibilityDecrement() {
            decrement()
        }

        override var accessibilityTraits: UIAccessibilityTraits {
            get { [.adjustable] }
            set {}
        }
    }

    private final class AccessibilityCombinableTestObject: NSObject, AccessibilityCombinable {
        var accessibilityIdentifier: String?

        var accessibilityCustomContent: [AXCustomContent]! = []
        var needsAccessibilityUpdate: Bool = true
        var rotorSequencer: AccessibilityComposition.RotorSequencer? = nil
        var accessibilityActivateOverride: UIAccessibilityCustomAction? = nil
        var accessibilityInteractions: AccessibilityComposition.Interactions?
        override func accessibilityActivate() -> Bool {
            accessibilityInteractions?.activate?() ?? false
        }

        override func accessibilityIncrement() {
            accessibilityInteractions?.increment?()
        }

        override func accessibilityDecrement() {
            accessibilityInteractions?.decrement?()
        }
    }
}

class AccessibilityComposition_RotorSequencerTests: XCTestCase {

    let accessibilityContainer = NSObject()

    lazy var firstResult: UIAccessibilityElement = {
        let element = UIAccessibilityElement(accessibilityContainer: self.accessibilityContainer)
        element.accessibilityLabel = "first result"
        return element
    }()

    lazy var secondResult: UIAccessibilityElement = {
        let element = UIAccessibilityElement(accessibilityContainer: self.accessibilityContainer)
        element.accessibilityLabel = "second result"
        return element
    }()

    lazy var thirdResult: UIAccessibilityElement = {
        let element = UIAccessibilityElement(accessibilityContainer: self.accessibilityContainer)
        element.accessibilityLabel = "third result"
        return element
    }()

    var linkRotors: [UIAccessibilityCustomRotor] {
        [
            UIAccessibilityCustomRotor(systemType: .link) { predicate in
                UIAccessibilityCustomRotorItemResult(targetElement: self.firstResult, targetRange: nil)
            },

            UIAccessibilityCustomRotor(systemType: .link) { predicate in
                UIAccessibilityCustomRotorItemResult(targetElement: self.secondResult, targetRange: nil)
            },

            UIAccessibilityCustomRotor(systemType: .link) { predicate in
                UIAccessibilityCustomRotorItemResult(targetElement: self.thirdResult, targetRange: nil)
            },
        ]
    }

    var miscRotors: [UIAccessibilityCustomRotor] {
        [
            UIAccessibilityCustomRotor(systemType: .landmark) { _ in
                UIAccessibilityCustomRotorItemResult(targetElement: NSObject(), targetRange: nil)
            },

            UIAccessibilityCustomRotor(systemType: .landmark) { _ in
                UIAccessibilityCustomRotorItemResult(targetElement: NSObject(), targetRange: nil)
            },

            UIAccessibilityCustomRotor(systemType: .underlineText) { _ in
                UIAccessibilityCustomRotorItemResult(targetElement: NSObject(), targetRange: nil)
            },
        ]
    }


    func test_consolidation() {
        let sequencer = AccessibilityComposition.RotorSequencer(rotors: linkRotors + miscRotors)
        // system rotors should be consolidated into a single rotor for each system type.
        XCTAssert(sequencer.rotors.count == 3)
    }

    func test_rotor_cycling() {
        let sequencer = AccessibilityComposition.RotorSequencer(rotors: linkRotors)
        let rotor = sequencer.rotors[0]
        XCTAssert(rotor.systemRotorType == .link)
        let predicate = UIAccessibilityCustomRotorSearchPredicate()
        predicate.searchDirection = .next

        // First rotor.
        var result = rotor.itemSearchBlock(predicate)
        var element = result?.targetElement as? NSObject
        XCTAssertEqual(element?.accessibilityLabel, firstResult.accessibilityLabel)
        predicate.currentItem = result!

        // Advance to the second rotor.
        result = rotor.itemSearchBlock(predicate)
        element = result?.targetElement as? NSObject
        XCTAssertEqual(element?.accessibilityLabel, secondResult.accessibilityLabel)
        predicate.currentItem = result!

        // Advance to the third rotor.
        result = rotor.itemSearchBlock(predicate)
        element = result?.targetElement as? NSObject
        XCTAssertEqual(element?.accessibilityLabel, thirdResult.accessibilityLabel)
        predicate.currentItem = result!

        // There is no next rotor.
        result = rotor.itemSearchBlock(predicate)
        XCTAssertNil(result)

        // Start going backwards
        predicate.searchDirection = .previous

        // Back to the second rotor.
        result = rotor.itemSearchBlock(predicate)
        element = result?.targetElement as? NSObject
        XCTAssertEqual(element?.accessibilityLabel, secondResult.accessibilityLabel)
        predicate.currentItem = result!

        // Back to the first.
        result = rotor.itemSearchBlock(predicate)
        element = result?.targetElement as? NSObject
        XCTAssertEqual(element?.accessibilityLabel, firstResult.accessibilityLabel)
        predicate.currentItem = result!

        // There is no previous rotor.
        result = rotor.itemSearchBlock(predicate)
        XCTAssertNil(result)
    }

    func test_namedRotors_ignored() {
        var namedRotors: [UIAccessibilityCustomRotor] {
            [
                UIAccessibilityCustomRotor(name: "named") { _ in
                    UIAccessibilityCustomRotorItemResult(targetElement: NSObject(), targetRange: nil)
                },

                UIAccessibilityCustomRotor(name: "also named") { _ in
                    UIAccessibilityCustomRotorItemResult(targetElement: NSObject(), targetRange: nil)
                },
            ]
        }
        let sequencer = AccessibilityComposition.RotorSequencer(rotors: namedRotors)
        XCTAssertEqual(sequencer.rotors.count, 2)
        XCTAssertEqual(sequencer.rotors[0].name, "named")
        XCTAssertEqual(sequencer.rotors[1].name, "also named")
    }

    func test_RotorSequencer_memory() {
        // This test demonstrates a common memory bug when using Rotors.
        // We must be careful when constructing our rotors and results not to accidentally retain the underlying elements.

        var rotorSequencer: AccessibilityComposition.RotorSequencer?
        weak var weakHeadingElement: NSObjectProtocol?
        weak var weakBoldElement: NSObjectProtocol?
        weak var weakUnderlinedElement: NSObjectProtocol?

        weak var weakHeadingResult: UIAccessibilityCustomRotorItemResult?
        weak var weakBoldResult: UIAccessibilityCustomRotorItemResult?
        weak var weakUnderlinedResult: UIAccessibilityCustomRotorItemResult?

        autoreleasepool {
            let headingElement = NSObject()
            weakHeadingElement = headingElement
            let boldElement = NSObject()
            weakBoldElement = boldElement
            let underlinedElement = NSObject()
            weakUnderlinedElement = underlinedElement

            let headingResult = UIAccessibilityCustomRotorItemResult(targetElement: headingElement, targetRange: nil)
            weakHeadingResult = headingResult

            let rotors = [
                // result created outside the rotor is retained but the element is not. This is largely ok.
                UIAccessibilityCustomRotor(systemType: .heading) { _ in
                    headingResult
                },

                // A result is created within the rotor will retain the element. This often unintentional.
                UIAccessibilityCustomRotor(systemType: .boldText) { _ in
                    UIAccessibilityCustomRotorItemResult(targetElement: boldElement, targetRange: nil)
                },

                // Elements properly made week are not retained.
                UIAccessibilityCustomRotor(systemType: .underlineText) { [weak underlinedElement] _ in
                    UIAccessibilityCustomRotorItemResult(targetElement: underlinedElement!, targetRange: nil)
                },
            ]

            rotorSequencer = AccessibilityComposition.RotorSequencer(rotors: rotors)

            let predicate = UIAccessibilityCustomRotorSearchPredicate()
            predicate.searchDirection = .next

            // rotors return the expected objects
            XCTAssertEqual(headingResult, rotorSequencer!.itemSearch(.heading, predicate: .init()))

            let bold = rotorSequencer!.itemSearch(.boldText, predicate: .init())
            weakBoldResult = bold
            XCTAssertEqual(boldElement, weakBoldResult!.targetElement as! NSObject)

            let underlined = rotorSequencer!.itemSearch(.underlineText, predicate: .init())
            weakUnderlinedResult = underlined
            XCTAssertEqual(underlinedElement, weakUnderlinedResult!.targetElement as! NSObject)
        }


        // the heading element itself is never retained
        XCTAssertNil(weakHeadingElement)
        // result created outside the rotor block is retained by the rotor, which is retained by the sequencer
        XCTAssertNotNil(weakHeadingResult)
        // but its element is nil
        XCTAssertNil(weakHeadingResult!.targetElement)

        // result created within the bold rotor block is not itself retained
        XCTAssertNil(weakBoldResult)
        // but the element still is
        XCTAssertNotNil(weakBoldElement)

        // result created within the underline rotor block is not itself retained
        XCTAssertNil(weakUnderlinedResult)
        // nor is the element
        XCTAssertNil(weakUnderlinedElement)

        // once the sequence.r is released
        rotorSequencer = nil

        // the element then follows
        XCTAssertNil(weakBoldElement)
        // along with the heading result
        XCTAssertNil(weakHeadingResult)
    }
}

class Accessibility_Extensions_tests: XCTestCase {
    func test_UIAccessibilityTraits_convertToBlueprintTraits() {
        let alltraits = Set(Accessibility.Trait.allTraits)
        let uiTraits = UIAccessibilityTraits(with: alltraits)
        XCTAssert(uiTraits.blueprintTraits == alltraits)
    }
}
