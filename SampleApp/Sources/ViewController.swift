import UIKit
import BlueprintUI
import BlueprintUICommonControls


struct Post {
    var authorName: String
    var timeAgo: String
    var body: String
}

let posts = [
    Post(
        authorName: "Tim",
        timeAgo: "1 hour ago",
        body: "Lorem Ipsum"),
    Post(
        authorName: "Jane",
        timeAgo: "2 days ago",
        body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
    Post(
        authorName: "John",
        timeAgo: "2 days ago",
        body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit!")

]


final class ViewController: UIViewController {

    private let blueprintView = BlueprintView(element: nil)

//    override func loadView() {
//        self.view = blueprintView
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let labelElement = Label(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse in maximus nibh. Praesent porta tincidunt luctus. Maecenas mollis porta laoreet. Morbi auctor, justo vitae aliquam consectetur, libero mauris varius ante, a consectetur tellus eros sed risus. Integer egestas luctus neque sed scelerisque. Mauris suscipit molestie magna vitae imperdiet. Morbi id felis id justo vulputate interdum sed nec diam. Proin euismod odio ut velit ultricies sollicitudin. Maecenas ipsum nulla, scelerisque vitae nulla tincidunt, tristique sollicitudin odio. Interdum et malesuada fames ac ante ipsum primis in faucibus.")

        let label = UILabel()
        label.text = " Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse in maximus nibh. Praesent porta tincidunt luctus. Maecenas mollis porta laoreet. Morbi auctor, justo vitae aliquam consectetur, libero mauris varius ante, a consectetur tellus eros sed risus. Integer egestas luctus neque sed scelerisque. Mauris suscipit molestie magna vitae imperdiet. Morbi id felis id justo vulputate interdum sed nec diam. Proin euismod odio ut velit ultricies sollicitudin. Maecenas ipsum nulla, scelerisque vitae nulla tincidunt, tristique sollicitudin odio. Interdum et malesuada fames ac ante ipsum primis in faucibus."
        label.numberOfLines = 0
        label.font = labelElement.font


        blueprintView.element = labelElement
        view.addSubview(blueprintView)
        blueprintView.translatesAutoresizingMaskIntoConstraints = false
        blueprintView.backgroundColor = .red

        NSLayoutConstraint.activate([
            blueprintView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            blueprintView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            blueprintView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
            blueprintView.trailingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: view.trailingAnchor, multiplier: 1)
        ])

        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .blue
        label.alpha = 0.5

        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
            label.trailingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: view.trailingAnchor, multiplier: 1)
        ])

    }

}

struct Grid: Element {

    var layout: GridLayout = GridLayout()

    var children: [(element: Element, key: AnyHashable?)] = []

    init(_ configure: (inout Grid) -> Void) {
        configure(&self)
    }

    var content: ElementContent {
        return ElementContent(layout: layout) {
            for child in self.children {
                $0.add(traits: (), key: child.key, element: child.element)
            }
        }
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

    mutating func add(key: AnyHashable? = nil, child: Element) {
        children.append((child, key))
    }

}


fileprivate struct MainView: ProxyElement {
    
    var posts: [Post]
    
    var elementRepresentation: Element {

        struct Item: ProxyElement {

            var title: String
            var subtitle: String

            var elementRepresentation: Element {
                return Box(
                    backgroundColor: UIColor(red: 1, green: 0, blue: 0, alpha: 0.1),
                    cornerStyle: .rounded(radius: 6),
                    wrapping: Column { column in

                        column.horizontalAlignment = .center
                        column.verticalUnderflow = .justifyToCenter

                        column.add(
                            child: Label(text: title) { label in

                            })
                        column.add(
                            child: Label(text: subtitle) { label in

                            })
                    })
            }

        }

        return Grid { grid in

            grid.add(
                child: ContextMenu(
                    wrapping: Pointer(
                        style: .effect(.automatic),
                        wrapping: Item(title: "Automatic", subtitle: "no shape"))))
            grid.add(
                child: Pointer(
                    style: .effect(.automatic, .roundedRect(CGRect(x: 0, y: 0, width: 10, height: 10), radius: 5)),
                    wrapping: Item(title: "Automatic", subtitle: "round rect")))

            grid.add(
                child: Pointer(
                    style: .effect(.highlight),
                    wrapping: Item(title: "Highlight", subtitle: "no shape")))

            grid.add(
                child: Pointer(
                    style: .effect(.lift),
                    wrapping: Item(title: "Lift", subtitle: "no shape")))

            grid.add(
                child: Pointer(
                    style: .effect(.hover(
                        tintMode: .none,
                        prefersShadow: false,
                        prefersScaledContent: false)),
                    wrapping: Item(title: "Hover (no tint)", subtitle: "no shape")))
            grid.add(
                child: Pointer(
                    style: .effect(.hover(
                        tintMode: .overlay,
                        prefersShadow: false,
                        prefersScaledContent: false)),
                    wrapping: Item(title: "Hover (overlay tint)", subtitle: "no shape")))
            grid.add(
                child: Pointer(
                    style: .effect(.hover(
                        tintMode: .underlay,
                        prefersShadow: false,
                        prefersScaledContent: false)),
                    wrapping: Item(title: "Hover (underlay tint)", subtitle: "no shape")))

            grid.add(
                child: Pointer(
                    style: .shape(.horizontalBeam(length: 10), constrainedAxes: []),
                    wrapping: Item(title: "Horizontal beam", subtitle: "no axes")))
            grid.add(
                child: Pointer(
                    style: .shape(.horizontalBeam(length: 10), constrainedAxes: .vertical),
                    wrapping: Item(title: "Horizontal beam", subtitle: "vertical")))
            grid.add(
                child: Pointer(
                    style: .shape(.horizontalBeam(length: 10), constrainedAxes: .horizontal),
                    wrapping: Item(title: "Horizontal beam", subtitle: "horizontal")))
            grid.add(
                child: Pointer(
                    style: .shape(.horizontalBeam(length: 10), constrainedAxes: .both),
                    wrapping: Item(title: "Horizontal beam", subtitle: "both")))

            grid.add(
                child: Pointer(
                    style: .shape(.verticalBeam(length: 10), constrainedAxes: []),
                    wrapping: Item(title: "Vertical beam", subtitle: "no axes")))
            grid.add(
                child: Pointer(
                    style: .shape(.verticalBeam(length: 10), constrainedAxes: .vertical),
                    wrapping: Item(title: "Vertical beam", subtitle: "vertical")))
            grid.add(
                child: Pointer(
                    style: .shape(.verticalBeam(length: 10), constrainedAxes: .horizontal),
                    wrapping: Item(title: "Vertical beam", subtitle: "horizontal")))
            grid.add(
                child: Pointer(
                    style: .shape(.verticalBeam(length: 10), constrainedAxes: .both),
                    wrapping: Item(title: "Vertical beam", subtitle: "both")))

            grid.add(
                child: Pointer(
                    style: .shape(.verticalBeam(length: 10), constrainedAxes: .both),
                    wrapping: Item(title: "Vertical beam", subtitle: "both")))
        }

//        return

//        let col = Column { col in
//            col.horizontalAlignment = .fill
//
//            col.add(child: List(posts: posts))
//            col.add(child: CommentForm())
//        }
//
//        var scroll = ScrollView(wrapping: col)
//        scroll.contentSize = .fittingHeight
//        scroll.alwaysBounceVertical = true
//        scroll.keyboardDismissMode = .onDrag
//
//        let background = Box(
//            backgroundColor: UIColor(white: 0.95, alpha: 1.0),
//            wrapping: scroll)
//
//        return background
    }
}

fileprivate struct List: ProxyElement {

    var posts: [Post]

    var elementRepresentation: Element {
        let col = Column { col in
            col.horizontalAlignment = .fill
            col.minimumVerticalSpacing = 8.0

            for post in posts {
                col.add(child: FeedItem(post: post))
            }
        }

        return col
    }
}

fileprivate struct CommentForm: ProxyElement {
    
    var elementRepresentation: Element {
        let col = Column { col in
            col.horizontalAlignment = .fill

            let label = Label(text: "Add your comment:")
            col.add(child: label)

            var nameField = TextField(text: "")
            nameField.placeholder = "Name"
            col.add(child: nameField)

            var commentField = TextField(text: "")
            commentField.placeholder = "Comment"
            col.add(child: commentField)
        }
        
        return Box(
            backgroundColor: .lightGray,
            wrapping: Inset(
                uniformInset: 16.0,
                wrapping: col))
    }
}


fileprivate struct FeedItem: ProxyElement {

    var post: Post

    var elementRepresentation: Element {
        let element = Row { row in
            row.verticalAlignment = .leading
            row.minimumHorizontalSpacing = 16.0
            row.horizontalUnderflow = .growUniformly

            let avatar = ConstrainedSize(
                width: .absolute(64),
                height: .absolute(64),
                wrapping: Box(
                    backgroundColor: .lightGray,
                    cornerStyle: .rounded(radius: 32.0),
                    wrapping: nil))

            row.add(
                growPriority: 0.0,
                shrinkPriority: 0.0,
                child: avatar)

            row.add(
                growPriority: 1.0,
                shrinkPriority: 1.0,
                child: FeedItemBody(post: post))
        }

        let box = Box(
            backgroundColor: .white,
            wrapping: Inset(
                uniformInset: 16.0,
                wrapping: element))


        return box
    }

}

fileprivate struct FeedItemBody: ProxyElement {

    var post: Post

    var elementRepresentation: Element {
        let column = Column { col in

            col.horizontalAlignment = .leading
            col.minimumVerticalSpacing = 8.0

            let header = Row { row in
                row.minimumHorizontalSpacing = 8.0
                row.verticalAlignment = .center

                var name = Label(text: post.authorName)
                name.font = UIFont.boldSystemFont(ofSize: 14.0)
                row.add(child: name)

                var timeAgo = Label(text: post.timeAgo)
                timeAgo.font = UIFont.systemFont(ofSize: 14.0)
                timeAgo.color = .lightGray
                row.add(
                    child: Pointer(
                        style: .effect(.lift),
                        wrapping: Button(
                            isEnabled: true,
                            onTap: { print("post: \(self.post)") },
                            wrapping: timeAgo)))
            }

            col.add(child: header)

            var body = Label(text: post.body)
            body.font = UIFont.systemFont(ofSize: 13.0)

            col.add(child: body)
        }

        return column
    }
    

}

#if DEBUG && canImport(SwiftUI)

import SwiftUI

@available(iOS 13.0.0, *)
struct Blueprint: UIViewRepresentable {

    var element: Element

    func makeUIView(context: Context) -> BlueprintView {
        return BlueprintView(element: element)
    }

    func updateUIView(_ uiView: BlueprintView, context: Context) {
        uiView.element = element
    }

}

@available(iOS 13.0.0, *)
struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
      Group {
        Blueprint(element: MainView(posts: posts))
            .previewLayout(.sizeThatFits)
        Blueprint(element: Label(text: "Hello"))
            .previewLayout(.sizeThatFits)
      }
   }
}



#endif
