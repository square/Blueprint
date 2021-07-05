//
//  ElementStateViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 7/3/21.
//  Copyright © 2021 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class ElementStateViewController: UIViewController {
    
    let blueprintView = BlueprintView()

    override func loadView() {
        blueprintView.backgroundColor = .white
        self.view = blueprintView
        
        self.title = "Dril's Twitter Emporium"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        update()
        
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(update)),
            UIBarButtonItem(title: "Reload Loop", style: .plain, target: self, action: #selector(updateLoop))
        ]
    }
    
    @objc func updateLoop() {
        for _ in 0...100 {
            autoreleasepool {
                self.update()
            }
        }
    }

    @objc func update() {
        
        let start = Date()
        
        self.blueprintView.element = element
        self.blueprintView.layoutIfNeeded()
        
        let end = Date()
        print("Layout Time: \(end.timeIntervalSince(start))")
    }

    var element: Element {
        Column { column in
            column.horizontalAlignment = .fill
            column.verticalUnderflow = .growUniformly
            column.minimumVerticalSpacing = 20.0
            
            while column.children.count < 500 {
                for tweet in tweets {
                    column.addFixed(child: tweet)
                }
            }
        }
        .inset(horizontal: 15.0)
        .scrollable {
            $0.alwaysBounceVertical = true
        }
    }
}


fileprivate struct Tweet : EnvironmentElement, Equatable, EquatableElement {
    
    var fullName : String
    var userName : String
    var time : String
    var content : String
    
    func content(in size: SizeConstraint, with environment: Environment) -> Element {
        Row { row in
            row.verticalAlignment = .top
            row.horizontalUnderflow = .growUniformly
            row.minimumHorizontalSpacing = 10
            
            row.addFixed(
                child: Image(image: .init(named: "dril"), contentMode: .aspectFill)
                    .box(background: .systemGray, corners: .capsule, clipsContent: true)
                    .constrainedTo(width: 70, height: 70)
            )
            
            row.addFlexible(child: Column { col in
                col.minimumVerticalSpacing = 10.0
                
                col.horizontalAlignment = .fill
                
                col.addFixed(
                    child: Row { row in
                    row.minimumHorizontalSpacing = 5.0
                    row.verticalAlignment = .center
                    row.horizontalUnderflow = .growUniformly
                    
                    row.addFixed(child: Label(text: self.fullName) {
                        $0.font = .systemFont(ofSize: 18.0, weight: .semibold)
                    })
                    
                    row.addFixed(child: Label(text: self.userName) {
                        $0.font = .systemFont(ofSize: 18.0, weight: .regular)
                        $0.color = .darkGray
                    })
                    
                    row.addFlexible(child: Spacer(width: 1.0))
                    
                    row.addFixed(child: Label(text: self.time) {
                        $0.font = .systemFont(ofSize: 18.0, weight: .light)
                        $0.color = .lightGray
                    })
                })
                
                col.addFixed(
                    child: Label(text: self.content) {
                        $0.font = .systemFont(ofSize: 16.0, weight: .regular)
                    }
                )
            })
        }
    }
}



fileprivate let tweets : [Tweet] = tweetContents.map { tweet in
    Tweet(
        fullName: "Drilathan",
        userName: "@dril",
        time: "no",
        content: tweet
    )
}


fileprivate let tweetContents : [String] = [
    "the worst part of having an ass is always, having to wipe the damn thing. the best part of having an ass is shitting. #ElectionFinalThoughts",
    "my screen play explores the question: what if master cheif smoked a big cigarette from the year 3000 that worked through his space suit",
    "((frowning) cause im the Apps Man (depression) YEah yeah im the apps man",
    "[apps help us day to day in our lifes... but some men have twisted the apps to fulfill their oqwn selfish desires. beware these 'dark apps']",
    "63 updates available? youre telling me thyere making my apps even better, for FREE? And to think these guys, get so much greif",
    "\"Give me an App that will make me say, 'Wow'\"  \"Apps will help us in our lives\" \"An App is always just a download away\" some good app quotes",
    "if big tech keeps loading their apps with features that i can accidentally post my dick on, i will have no choice but to enter crisis mode .",
    "Keep an eye on \"Apps\", in 2013 and beyond.",
    "people who use \"APPS\" think they are such pimps ... but theyer nothing but hoochie mammas",
    "i will never apologize for being wild about apps and upgrades",
    "if I download just ONe more app I will need an APP to keep track of my APPS!!!  #TheThursdayNiteRant",
    "A dog with five tattoos has appeared online",
    "surgery to make my head drier",
    "\"i Fucking do it all — For the fans...\" - Dril",
    "Beer is like pepsi on crack .",
    "you ask me to play \"The beer song\" ... I smile and ask, \"Which one?\"",
    "These are the most important jeans you will ever wear",
    "if someone posts something that is good then i will look at it and think its good.  Simple",
    "me & the boys can never hold a Luau (hula maidens, pig w/ apple in mouth, limbo) thanks to the loud mouth craop going on at college campuses",
    "delta variant? wake me up when theres a WINE varirant",
    ".@saddamhussein take a lap chowder head",
]
