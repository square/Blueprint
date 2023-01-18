//
//  RootViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 6/26/20.
//  Copyright © 2020 Square. All rights reserved.
//

import Foundation


import BlueprintUI
import BlueprintUICommonControls
import UIKit


final class RootViewController: UIViewController {
    fileprivate var demos: [Element] {
        [
            DemoItem(title: "Text Links", onTap: { [weak self] in
                self?.push(TextLinkViewController())
            }),
            DemoItem(title: "Post List", badgeText: "3", onTap: { [weak self] in
                self?.push(PostsViewController())
            }),
            DemoItem(title: "Keyboard Scrolling", onTap: { [weak self] in
                self?.push(ScrollViewKeyboardViewController())
            }),
            DemoItem(title: "GeometryReader Responsive Layout", onTap: { [weak self] in
                self?.push(ResponsiveViewController())
            }),

            EditingMenu { menu in
                DemoItem(title: "Show A Menu Controller") {
                    menu.show()
                }
            } items: {
                EditingMenuItem.copying("A string goes on the pasteboard")

                EditingMenuItem(.paste) {
                    print("Pasted!")
                }

                EditingMenuItem(title: "A Custom Item") {
                    // Do something here...
                    print("Performed!")
                }
            },
        ]
    }

    override func loadView() {
        let leftBlueprintView = BlueprintView(element: contents)
        leftBlueprintView.backgroundColor = .clear
        leftBlueprintView.layer.borderColor = UIColor.black.cgColor
        leftBlueprintView.layer.borderWidth = 1

        leftBlueprintView.layoutMode = .strictSinglePass

        let rightBlueprintView = BlueprintView(element: contents)
        rightBlueprintView.backgroundColor = .clear
        rightBlueprintView.layer.borderColor = UIColor.black.cgColor
        rightBlueprintView.layer.borderWidth = 1

        rightBlueprintView.layoutMode = .standard

        let stackView = UIStackView(arrangedSubviews: [
            leftBlueprintView,
            rightBlueprintView,
        ])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        view = stackView

        view.backgroundColor = .init(white: 0.9, alpha: 1.0)
    }

    var contents: Element {
        demoScreenWrapper
    }
    
    var demoScreenWrapper: Element {
        Column(alignment: .leading, underflow: .justifyToCenter) {
            Label(text: "Date Picker") { label in
                label.font = .preferredFont(forTextStyle: .caption1)
            }

            datePicker
                .box(borders: .solid(color: .blue, width: 1))
        }
    }
    
    var datePicker: Element {
        var daySegment: Element {
            Spacer(5)
                .box(background: .red, borders: .solid(color: .black, width: 1))
        }
        
        var weekdaySymbols: Element {
            EqualStack(direction: .horizontal) {
                for weekday in ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"] {
                    Label(text: weekday) { label in
                        label.font = .preferredFont(forTextStyle: .body)
                    }
                    .box(borders: .solid(color: .green, width: 1))
                }
            }
            .constrainedTo(height: .atLeast(40))
        }
        
        var header: Element {
            Row(
                alignment: .center,
                underflow: .growProportionally,
                minimumSpacing: 8
            ) {
                Label(text: "Jan 2023") { label in
                    label.font = .preferredFont(forTextStyle: .title2)
                }

                Spacer(40)
                    .box(background: .lightGray, corners: .rounded(radius: 6))
                    .stackLayoutChild(priority: .fixed)

                Spacer(40)
                    .box(background: .lightGray, corners: .rounded(radius: 6))
                    .stackLayoutChild(priority: .fixed)
            }
        }


        var monthGrid: Element {
            return Column(alignment: .fill, minimumSpacing: 8) {

                weekdaySymbols
                    .box(borders: .solid(color: .brown, width: 1))

                for _ in 0..<4 {
                    EqualStack(direction: .horizontal) {
                        for _ in 0..<7 {
                            daySegment
                        }
                    }
                    .constrainedTo(height: .atLeast(40))
                    .box(borders: .solid(color: .brown, width: 1))
                }
            }

        }

        return Column(
            alignment: .fill,
            underflow: .justifyToStart,
            minimumSpacing: 8
        ) {
            header.stackLayoutChild(priority: .fixed)
            monthGrid.stackLayoutChild(priority: .flexible)
        }
        .box(borders: .solid(color: .yellow, width: 1))
        .constrainedTo(width: .atLeast(280))
    }

    var contents2: Element {
        Column { column in
            column.minimumVerticalSpacing = 20.0
            column.horizontalAlignment = .leading

            self.demos.forEach { demo in
                column.add(child: demo)
            }
        }
        .constrainedTo(width: .within(300...400))
        .aligned(vertically: .top, horizontally: .center)
        .inset(uniform: 40.0)
        .scrollable(.fittingHeight) { scrollView in
            scrollView.alwaysBounceVertical = true
        }
    }

    private func push(_ viewController: UIViewController) {
        navigationController?.pushViewController(viewController, animated: true)
    }
}


fileprivate struct DemoItem: ProxyElement {
    var title: String
    var badgeText: String?

    var onTap: () -> Void

    var elementRepresentation: Element {

        Label(text: title) { label in
            label.font = .systemFont(ofSize: 18.0, weight: .semibold)
        }
        .inset(uniform: 20.0)
        .box(
            background: .white,
            corners: .rounded(radius: 15.0),
            shadow: .simple(
                radius: 5.0,
                opacity: 0.3,
                offset: .init(width: 0, height: 2.0),
                color: .black
            )
        )
        .tappable {
            self.onTap()
        }
        .decorate(layering: .below, position: .inset(5)) {
            Box(backgroundColor: .init(white: 0.0, alpha: 0.1), cornerStyle: .rounded(radius: 17))
        }
        .decorate(layering: .above, position: .corner(.topLeft)) {
            guard let badge = self.badgeText else {
                return Empty()
            }

            return Label(text: badge) {
                $0.font = .systemFont(ofSize: 22.0, weight: .bold)
                $0.color = .white
            }
            .inset(uniform: 7.0)
            .box(background: .systemRed, corners: .capsule)
        }
        .accessibilityElement(
            label: title,
            value: nil,
            traits: [.staticText],
            accessibilityFrameCornerStyle: .rounded(radius: 15)
        )
    }
}
