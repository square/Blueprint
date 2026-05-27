import BlueprintUI
import XCTest
@testable import BlueprintUIAccessibilityCore


class AccessibilityDeferralTests: XCTestCase {

    // MARK: - CompositeRepresentation.merge chaining

    func test_merge_multiple_representations() {
        let rep1 = makeRepresentation(label: "Label 1", value: "Value 1", hint: "Hint 1")
        let rep2 = makeRepresentation(label: "Label 2", value: "Value 2", hint: "Hint 2")
        let rep3 = makeRepresentation(label: "Label 3", value: "Value 3", hint: "Hint 3")

        let representations = [rep1, rep2, rep3]

        // This mirrors the exact reduce pattern used in updateDeferredAccessibility
        let merged = representations.dropFirst()
            .reduce(representations.first!) { result, value in
                result.merge(with: value)
            }

        XCTAssertEqual(merged.label, "Label 1, Label 2, Label 3")
        XCTAssertEqual(merged.value, "Value 1, Value 2, Value 3")
        XCTAssertEqual(merged.hint, "Hint 1, Hint 2, Hint 3")
    }

    func test_merge_two_representations() {
        let rep1 = makeRepresentation(label: "First", value: "A")
        let rep2 = makeRepresentation(label: "Second", value: "B")

        let merged = rep1.merge(with: rep2)

        XCTAssertEqual(merged.label, "First, Second")
        XCTAssertEqual(merged.value, "A, B")
    }

    func test_merge_preserves_traits() {
        let container = NSObject()
        let element1 = UIAccessibilityElement(accessibilityContainer: container)
        element1.accessibilityLabel = "Header"
        element1.accessibilityTraits = .header

        let element2 = UIAccessibilityElement(accessibilityContainer: container)
        element2.accessibilityLabel = "Static"
        element2.accessibilityTraits = .staticText

        let rep1 = AccessibilityComposition.CompositeRepresentation([element1]) {}
        let rep2 = AccessibilityComposition.CompositeRepresentation([element2]) {}

        let merged = rep1.merge(with: rep2)

        XCTAssertTrue(merged.traits.contains(.header))
        XCTAssertTrue(merged.traits.contains(.staticText))
    }

    func test_merge_with_nil_returns_self() {
        let rep = makeRepresentation(label: "Only", value: "One")
        let merged = rep.merge(with: nil)

        XCTAssertEqual(merged.label, "Only")
        XCTAssertEqual(merged.value, "One")
    }

    // MARK: - Receiver apply / replace / merge

    func test_apply_replaces_content_on_new_updateID() {
        let receiver = TestReceiver()

        var content1 = AccessibilityDeferral.Content(kind: .inherited(), identifier: "source1")
        content1.updateIdentifier = UUID()
        content1.inheritedAccessibility = makeRepresentation(label: "First")

        receiver.apply(content: [content1], frameProvider: nil)

        XCTAssertEqual(receiver.deferredAccessibilityContent?.count, 1)
        XCTAssertEqual(receiver.deferredAccessibilityContent?.first?.inheritedAccessibility?.label, "First")
    }

    func test_apply_merges_content_on_same_updateID() {
        let receiver = TestReceiver()
        let sharedID = UUID()

        var content1 = AccessibilityDeferral.Content(kind: .inherited(), identifier: "source1")
        content1.updateIdentifier = sharedID
        content1.inheritedAccessibility = makeRepresentation(label: "First")

        var content2 = AccessibilityDeferral.Content(kind: .inherited(), identifier: "source2")
        content2.updateIdentifier = sharedID
        content2.inheritedAccessibility = makeRepresentation(label: "Second")

        // First call replaces
        receiver.apply(content: [content1], frameProvider: nil)
        XCTAssertEqual(receiver.deferredAccessibilityContent?.count, 1)

        // Second call with same updateID merges
        receiver.apply(content: [content2], frameProvider: nil)
        XCTAssertEqual(receiver.deferredAccessibilityContent?.count, 2)
    }

    func test_apply_clears_content_when_nil() {
        let receiver = TestReceiver()

        var content = AccessibilityDeferral.Content(kind: .inherited(), identifier: "source1")
        content.updateIdentifier = UUID()
        content.inheritedAccessibility = makeRepresentation(label: "Something")

        receiver.apply(content: [content], frameProvider: nil)
        XCTAssertEqual(receiver.deferredAccessibilityContent?.count, 1)

        receiver.apply(content: nil, frameProvider: nil)
        XCTAssertEqual(receiver.deferredAccessibilityContent?.count, 0)
    }

    func test_apply_propagates_actions_from_sources() {
        let receiver = TestReceiver()

        let container = NSObject()
        let element = UIAccessibilityElement(accessibilityContainer: container)
        element.accessibilityLabel = "Action Source"
        element.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Test Action") { _ in true },
        ]

        let rep = AccessibilityComposition.CompositeRepresentation([element]) {}

        var content = AccessibilityDeferral.Content(kind: .inherited(), identifier: "source1")
        content.updateIdentifier = UUID()
        content.inheritedAccessibility = rep

        receiver.apply(content: [content], frameProvider: nil)
        XCTAssertEqual(receiver.accessibilityCustomActions?.first?.name, "Test Action")
    }

    // MARK: - Content customContent generation

    func test_content_inherited_customContent() {
        var content = AccessibilityDeferral.Content(kind: .inherited(.high), identifier: "id")
        content.inheritedAccessibility = makeRepresentation(label: "Error Label", value: "Error Value")

        let customContent = content.customContent
        XCTAssertNotNil(customContent)
        XCTAssertEqual(customContent?.label, "Error Label")
        XCTAssertEqual(customContent?.value, "Error Value")
        XCTAssertEqual(customContent?.importance, .high)
    }

    func test_content_error_customContent() {
        var content = AccessibilityDeferral.Content(kind: .error, identifier: "id")
        content.inheritedAccessibility = makeRepresentation(label: "Field", value: "is required")

        let customContent = content.customContent
        XCTAssertNotNil(customContent)
        XCTAssertEqual(customContent?.importance, .high)
    }

    func test_content_nil_accessibility_returns_nil() {
        let content = AccessibilityDeferral.Content(kind: .inherited(), identifier: "id")
        XCTAssertNil(content.customContent)
    }

    // MARK: - Helpers

    private func makeRepresentation(
        label: String? = nil,
        value: String? = nil,
        hint: String? = nil
    ) -> AccessibilityComposition.CompositeRepresentation {
        let container = NSObject()
        let element = UIAccessibilityElement(accessibilityContainer: container)
        element.accessibilityLabel = label
        element.accessibilityValue = value
        element.accessibilityHint = hint
        return AccessibilityComposition.CompositeRepresentation([element]) {}
    }
}

// MARK: - Test Doubles

private final class TestReceiver: UIView, AccessibilityDeferral.Receiver, AXCustomContentProvider {

    var accessibilityCustomContent: [AXCustomContent]! = []

    var customContent: [Accessibility.CustomContent]?

    var rotorSequencer: AccessibilityComposition.RotorSequencer?

    var deferredAccessibilityContent: [AccessibilityDeferral.Content]?

    func updateDeferredAccessibility(frameProvider: AccessibilityDeferral.FrameProvider?) {
        // No-op for unit testing the apply/replace/merge flow
    }
}

extension TestReceiver: AccessibilityDeferral.DeferralView {}
