//
//  Screen.swift
//  BlueprintUIDebugging
//
//  Created by Kyle Van Essen on 4/24/20.
//

import BlueprintUI
import BlueprintUICommonControls


struct Screen : ProxyElement {
    
    var sections : [Section]
    
    static var sideInset : CGFloat = 10.0
    
    var elementRepresentation: Element {
        Box(
            backgroundColor: UIColor(white: 0.90, alpha: 1.0),
            wrapping: self.content
        )
    }
    
    private var content : Element {
        
        let allSections = Column {
            $0.horizontalAlignment = .fill
            $0.minimumVerticalSpacing = 20.0
                                
            for section in self.sections {
                $0.add(child: section)
            }
        }
        
        return ScrollView(wrapping: allSections) {
            $0.contentSize = .fittingHeight
            $0.contentInset = .init(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)
        }
    }

    struct ContentBox : ProxyElement {
        var sideInsets : Bool
        var wrapping : Element
        
        var elementRepresentation: Element {
            let inset = self.sideInsets ? Screen.sideInset : 0.0
            
            return Box(
                wrapping: Inset(
                    insets: UIEdgeInsets(top: 20.0, left: inset, bottom: 20.0, right: inset),
                    wrapping: self.wrapping
                    )
                ) { box in
                    box.shadowStyle = .simple(
                        radius: 2.0,
                        opacity: 0.25,
                        offset: CGSize(width: 0.0, height: 1.0),
                        color: .black
                    )
                    
                    box.backgroundColor = .white
            }
        }
    }
    
    struct Section : ProxyElement {
        
        var title : String
        var detail : String = ""
        var element : Element
        var horizontallyInsetsContent : Bool = true
        
        init(
            title : String,
            detail : String = "",
            element : Element,
            horizontallyInsetsContent : Bool = true
        ) {
            self.title = title
            self.detail = detail
            self.element = element
            self.horizontallyInsetsContent = horizontallyInsetsContent
        }
        
        var elementRepresentation: Element {
            Column {
                $0.horizontalAlignment = .fill
                
                $0.add(
                    // TODO: Split into header type
                    child: Inset(
                        sideInsets: Screen.sideInset,
                        wrapping: Column {
                            
                            $0.add(child: Label(text: self.title) {
                                $0.font = .systemFont(ofSize: 28.0, weight: .bold)
                            })
                            
                            $0.add(child: Spacer(size: CGSize(width: 0.0, height: 5.0)))
                            
                            if self.detail.isEmpty == false {
                                $0.add(child: Label(text: self.detail) {
                                    $0.font = .systemFont(ofSize: 13.0, weight: .regular)
                                    $0.color = .darkGray
                                })
                                
                                $0.add(child: Spacer(size: CGSize(width: 0.0, height: 10.0)))
                            }
                        }
                    )
                )
                
                $0.add(child: ContentBox(
                    sideInsets: self.horizontallyInsetsContent,
                    wrapping: self.element
                ))
            }
        }
    }
    
    struct ElementRow : ProxyElement {
        var element : Element
        var depth : Int
        
        var onTap : (Element) -> ()

        var elementRepresentation: Element {
            Row {
                $0.verticalAlignment = .fill
                $0.horizontalUnderflow = .growUniformly
                
                let spacer = Spacer(size: CGSize(width: CGFloat(depth) * 15.0, height: 0.0))
                $0.add(growPriority: 0.0, shrinkPriority: 0.0, child: spacer)
                
                let box = Box(backgroundColor: .init(white: 0.0, alpha: 0.05), wrapping: self.content)
                
                $0.add(growPriority: 1.0, shrinkPriority: 1.0, child: box)
            }
        }
        
        private var content : Element {
            Row {
                $0.verticalAlignment = .fill
                $0.horizontalUnderflow = .justifyToStart
                
                $0.add(
                    child: Rule(orientation: .vertical, color: .darkGray, thickness: .points(2.0))
                )
                
                let elementInfo = Column {
                        
                    $0.add(child: Label(text: String(describing: type(of: self.element))) {
                        $0.font = .systemFont(ofSize: 18.0, weight: .semibold)
                        $0.color = .systemBlue
                    })
                    
                    $0.add(child: Spacer(size: CGSize(width: 0.0, height: 5.0)))
                    
                    $0.add(
                        child: Tappable(
                            onTap: { self.onTap(self.element) },
                            wrapping: Box(
                                backgroundColor: .white,
                                wrapping: self.element
                            )
                        )
                    )
                }
                
                $0.add(
                    child: Inset(uniformInset: 5.0, wrapping: elementInfo)
                )
            }
        }
    }
}
