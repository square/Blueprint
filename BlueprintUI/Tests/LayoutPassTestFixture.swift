//
//  LayoutPassTestFixture.swift
//
//
//  Created by Kyle Van Essen on 11/3/22.
//

import Foundation

final class LayoutPassTestFixture {

    private(set) var events: [Event] = []

    func removeAll() {
        events.removeAll()
    }
}


extension LayoutPassTestFixture {

    enum Event {
        enum Element: Equatable {
            case accessedContent
        }

        enum ComparableElement: Equatable {
            case isEquivalent
        }

        enum ElementState: Equatable {
            case updated
            case measure
            case layout
            case created
        }

        enum NativeViewController: Equatable {}
    }
}
