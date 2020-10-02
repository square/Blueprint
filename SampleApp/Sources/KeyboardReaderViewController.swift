//
//  KeyboardReaderViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 9/30/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class KeyboardReaderViewController : UIViewController
{
    override func loadView() {
        
        let view = BlueprintView()
        
        view.element = self.content()
        
        self.view = view
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(dismissKeyboard))
    }
    
    private func content() -> Element {
                
        KeyboardReader { keyboard in
            
            Overlay { overlay in
                overlay.add {
                    Column {
                        $0.verticalUnderflow = .justifyToCenter
                        
                        $0.addFixed {
                            TextField(text: "I'm a text field, tap me!")
                        }
                        
                        $0.addFixed {
                            TextField(text: "I am also a text field.")
                        }
                    }
                    .map {
                        switch keyboard.keyboardFrame {
                        case .nonOverlapping:
                            return $0.constrainedTo(height: .absolute(keyboard.size.height))
                            
                        case .overlapping(let frame):
                            return $0.constrainedTo(height: .absolute(keyboard.size.height - frame.height))
                        }
                    }
                    .aligned(vertically: .top, horizontally: .fill)
                }
                
                overlay.add {
                    EnvironmentReader { env in
                        Column { col in
                            col.horizontalAlignment = .fill
                            
                            col.addFixed {
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
                            }
                            
                            if case let .overlapping(frame) = keyboard.keyboardFrame {
                                col.addFixed {
                                    Spacer(width: 0, height: frame.height)
                                }
                            } else {
                                col.addFixed {
                                    Spacer(width: 0, height: env.safeAreaInsets.bottom)
                                }
                            }
                        }
                        .aligned(vertically: .bottom, horizontally: .fill)
                    }
                }
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
}
