//
//  EnvironmentViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 4/3/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class EnvironmentViewController : UIViewController
{
    override func loadView() {
        let view = BlueprintView()
        
        view.environment.theme = Theme(
            backgroundColor: .white,
            borderColor: .init(white: 0.8, alpha: 1.0)
        )
        
        view.element = self.element()
        
        self.view = view
    }
    
    func element() -> Element {
        ExampleElement()
    }
}

fileprivate struct ExampleElement : ProxyElement, EnvironmentElement
{
    var environment : Environment = .empty
    
    var elementRepresentation : Element {
        
        var scrollView = ScrollView(wrapping: Column {
            for _ in 1...20 {
                $0.add(child: RowElement())
            }
        })
        
        scrollView.contentSize = .fittingHeight
        
        scrollView.contentInset = environment.safeAreaInsets
        
        return scrollView
    }
}

fileprivate struct Theme
{
    var backgroundColor : UIColor
    var borderColor : UIColor
}

fileprivate extension Environment {
    var theme : Theme {
        get {
            return self[ThemeKey.self]
        }
        set {
            self[ThemeKey.self] = newValue
        }
    }
    
    private struct ThemeKey : EnvironmentKey {
        typealias Value = Theme
        
        static var defaultValue: Value {
            fatalError()
        }
    }
}

fileprivate struct RowElement : ProxyElement, EnvironmentElement
{
    var environment : Environment = .empty
    
    var elementRepresentation: Element {
        
        let theme = environment.theme
        
        var box = Box(
            backgroundColor: theme.backgroundColor,
            cornerStyle: .rounded(radius: 6.0),
            wrapping: Inset(
                uniformInset: 10.0,
                wrapping: Label(text: "This is a row")
            )
        )

        box.borderStyle = .solid(color: theme.borderColor, width: 2.0)
        
        return box
    }
}

