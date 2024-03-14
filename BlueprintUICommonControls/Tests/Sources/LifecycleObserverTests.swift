import BlueprintUICommonControls
import XCTest
@testable import BlueprintUI

final class LifecycleObserverTests: XCTestCase {
    enum Event: Equatable {
        case appear(Int)
        case update(Int)
        case disappear(Int)
    }

    func test_coalescingCallbacks() {
        var events: [Event] = []

        let element = LifecycleObserver(
            onAppear: { events.append(.appear(1)) },
            onUpdate: { events.append(.update(1)) },
            onDisappear: { events.append(.disappear(1)) },
            wrapping: Empty()
        )
        .onAppear {
            events.append(.appear(2))
        }
        .onUpdate {
            events.append(.update(2))
        }
        .onDisappear {
            events.append(.disappear(2))
        }

        element.onAppear?()
        XCTAssertEqual(events, [.appear(1), .appear(2)])

        events.removeAll()
        element.onUpdate?()
        XCTAssertEqual(events, [.update(1), .update(2)])

        events.removeAll()
        element.onDisappear?()
        XCTAssertEqual(events, [.disappear(1), .disappear(2)])
    }

    func test_viewDescription() {
        var events: [Event] = []

        let element = LifecycleObserver(
            onAppear: { events.append(.appear(1)) },
            onUpdate: { events.append(.update(1)) },
            onDisappear: { events.append(.disappear(1)) },
            wrapping: Empty()
        )

        let viewDescription = element.backingViewDescription(
            with: ViewDescriptionContext(
                bounds: .zero,
                subtreeExtent: nil,
                environment: .empty
            )
        )

        viewDescription?.onAppear?()
        XCTAssertEqual(events, [.appear(1)])

        events.removeAll()
        viewDescription?.onUpdate?()
        XCTAssertEqual(events, [.update(1)])

        events.removeAll()
        viewDescription?.onDisappear?()
        XCTAssertEqual(events, [.disappear(1)])
    }
}
