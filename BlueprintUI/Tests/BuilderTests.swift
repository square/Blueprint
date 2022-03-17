//
//  BuilderTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 11/10/21.
//

import BlueprintUI
import XCTest



/// Note: The tests in this type should be kept in sync with `ElementBuilderTests`.
class BuilderTests: XCTestCase {

    func test_empty() {
        let content: [String] = build {}

        XCTAssertEqual(content, [])
    }

    func test_single() {
        let content: [String] = build {
            "1"
        }

        XCTAssertEqual(
            content, ["1"]
        )
    }

    func test_multiple() {
        let content: [String] = build {
            "1"
            "2"
        }

        XCTAssertEqual(
            content, ["1", "2"]
        )
    }

    func test_array() {

        let content: [String] = build {
            ["1", "2"]
        }

        XCTAssertEqual(
            content, ["1", "2"]
        )
    }

    func test_if_else() {

        /// If we use just `true` or `false`, the compiler (rightly) complains about unreachable code.
        let trueValue = "true" == "true"
        let falseValue = "true" == "false"

        let content: [String] = build {
            "1"

            if trueValue {
                "2"
            } else {
                "3"
            }

            if falseValue {
                "4"
            } else {
                "5"
            }

            if falseValue {
                "6"
            } else if falseValue {
                "7"
            }
        }

        XCTAssertEqual(
            content, ["1", "2", "5"]
        )
    }

    func test_for_in() {

        let content: [String] = build {
            for item in 1...6 {
                if item % 2 == 0 {
                    "\(item)"
                }
            }
        }

        XCTAssertEqual(
            content, ["2", "4", "6"]
        )
    }

    func test_map() {

        let numbers: [Int] = [1, 2, 3]

        let content: [String] = build {
            numbers.map(String.init)
        }

        XCTAssertEqual(
            content, ["1", "2", "3"]
        )
    }

    func test_switch() {

        enum TestEnum: CaseIterable {
            case first
            case second
            case third
        }

        let content: [String] = build {
            for item in TestEnum.allCases {
                switch item {
                case .first:
                    "1"
                case .second:
                    "2"
                case .third:
                    "3"
                }
            }
        }

        XCTAssertEqual(
            content, ["1", "2", "3"]
        )
    }

    func test_optional() {
        let optionalNil: String? = nil
        let optional: String? = "1"

        let content: [String] = build {

            if let optional = optional {
                optional
            }

            if let optionalNil = optionalNil {
                optionalNil
            }

            optional
            optionalNil

            optional.map { _ in "2" }
            optionalNil.map { _ in "3" }
        }

        XCTAssertEqual(
            content, ["1", "1", "2"]
        )
    }

    func test_available() {

        let content: [String] = build {

            if #available(iOS 20, *) {
                "1"
            } else {
                "2"
            }

            if #available(iOS 11, *) {
                "3"
            } else {
                "4"
            }
        }

        XCTAssertEqual(
            content, ["2", "3"]
        )
    }

    fileprivate func build<Content>(
        @Builder<Content> using builder: () -> [Content]
    ) -> [Content] {
        builder()
    }
}
