//
//  KeyboardReaderViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 9/30/20.
//  Copyright © 2020 Square. All rights reserved.
//

import BlueprintUI
import BlueprintUICommonControls
import UIKit


final class KeyboardReaderViewController: UIViewController {
    override func loadView() {

        let view = BlueprintView()

        view.element = content()

        self.view = view

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Dismiss",
            style: .plain,
            target: self,
            action: #selector(dismissKeyboard)
        )
    }

    private func content() -> Element {

        KeyboardReader { keyboard in

            Overlay {

                Column(underflow: .justifyToCenter) {
                    TextField(text: "I'm a text field, tap me!")
                        .stackLayoutChild(priority: .fixed)

                    TextField(text: "I am also a text field.")
                        .stackLayoutChild(priority: .fixed)
                }
                .map {
                    switch keyboard.keyboardFrame {
                    case .nonOverlapping:
                        return $0.constrainedTo(height: .absolute(keyboard.layoutSize.height))

                    case .overlapping(let frame):
                        return $0.constrainedTo(height: .absolute(keyboard.layoutSize.height - frame.height))
                    }
                }
                .aligned(vertically: .top, horizontally: .fill)

                EnvironmentReader { env in
                    Column(alignment: .fill) {

                        Label(text: "Hello, I am a button") {
                            $0.color = .white
                            $0.font = .systemFont(ofSize: 16.0, weight: .semibold)
                        }
                        .inset(uniform: 20.0)
                        .box(background: .systemBlue, corners: .rounded(radius: 6.0))
                        .tappable {
                            print("Tapped me!")
                        }
                        .inset(uniform: 10.0)
                        .stackLayoutChild(priority: .fixed)

                        if case let .overlapping(frame) = keyboard.keyboardFrame {
                            Spacer(width: 0, height: frame.height)
                                .stackLayoutChild(priority: .fixed)
                        } else {
                            Spacer(width: 0, height: env.safeAreaInsets.bottom)
                                .stackLayoutChild(priority: .fixed)
                        }
                    }
                    .aligned(vertically: .bottom, horizontally: .fill)
                }
            }
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
