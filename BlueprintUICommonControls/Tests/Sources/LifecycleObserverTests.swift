import BlueprintUICommonControls
import XCTest
@testable import BlueprintUI

final class LifecycleObserverTests: XCTestCase {
    enum Event: Equatable {
        case appear(Int)
        case disappear(Int)
        case mount(Int)
        case unmount(Int)
    }

    func test_coalescingCallbacks() {
        var events: [Event] = []

        let element = LifecycleObserver(
            onAppear: { events.append(.appear(1)) },
            onDisappear: { events.append(.disappear(1)) },
            onMount: { events.append(.mount(1)) },
            onUnmount: { events.append(.unmount(1)) },
            wrapping: Empty()
        )
        .onAppear {
            events.append(.appear(2))
        }
        .onDisappear {
            events.append(.disappear(2))
        }
        .onMount {
            events.append(.mount(2))
        }
        .onUnmount {
            events.append(.unmount(2))
        }

        element.onAppear?()
        XCTAssertEqual(events, [.appear(1), .appear(2)])

        events.removeAll()
        element.onDisappear?()
        XCTAssertEqual(events, [.disappear(1), .disappear(2)])

        events.removeAll()
        element.onMount?()
        XCTAssertEqual(events, [.mount(1), .mount(2)])

        events.removeAll()
        element.onUnmount?()
        XCTAssertEqual(events, [.unmount(1), .unmount(2)])
    }

    func test_viewDescription() {
        var events: [Event] = []

        let element = LifecycleObserver(
            onAppear: { events.append(.appear(1)) },
            onDisappear: { events.append(.disappear(1)) },
            onMount: { events.append(.mount(1)) },
            onUnmount: { events.append(.unmount(1)) },
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
        viewDescription?.onDisappear?()
        XCTAssertEqual(events, [.disappear(1)])

        events.removeAll()
        viewDescription?.onMount?()
        XCTAssertEqual(events, [.mount(1)])

        events.removeAll()
        viewDescription?.onUnmount?()
        XCTAssertEqual(events, [.unmount(1)])
    }
}
