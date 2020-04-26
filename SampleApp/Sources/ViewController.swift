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
        body: "Lorem Ipsum"
    ),
    Post(
        authorName: "Jane",
        timeAgo: "2 days ago",
        body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    ),
    Post(
        authorName: "John",
        timeAgo: "2 days ago",
        body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit!"
    )
]


final class ViewController: UIViewController {

    private let blueprintView = BlueprintView(element: MainView(posts: posts))

    override func loadView() {
        self.view = blueprintView
    }

}

fileprivate struct MainView: ProxyElement {
    
    var posts: [Post]
    
    var elementRepresentation: Element {
        ScrollView(
            wrapping: Column { col in
                col.horizontalAlignment = .fill
                
                col += List(posts: posts)
                col += CommentForm()
        }) {
            $0.contentSize = .fittingHeight
            $0.alwaysBounceVertical = true
            $0.keyboardDismissMode = .onDrag
        }
        .box(backgroundColor: UIColor(white: 0.95, alpha: 1.0))
    }
}

fileprivate struct List: ProxyElement {

    var posts: [Post]

    var elementRepresentation: Element {
        Column { col in
            col.horizontalAlignment = .fill
            col.minimumVerticalSpacing = 8.0

            col += posts.map {
                FeedItem(post: $0)
            }
        }
    }
}

fileprivate struct CommentForm: ProxyElement {
    
    var elementRepresentation: Element {
        Column { col in
            col.horizontalAlignment = .fill

            let label = Label(text: "Add your comment:")
            col.add(child: label)

            col += TextField(text: "") {
                $0.placeholder = "Name"
            }

            col += TextField(text: "") {
                $0.placeholder = "Comment"
            }
        }
        .inset(uniform: 16.0)
        .box(backgroundColor: .lightGray)
    }
}


fileprivate struct FeedItem: ProxyElement {

    var post: Post

    var elementRepresentation: Element {
        Row { row in
            row.verticalAlignment = .leading
            row.minimumHorizontalSpacing = 16.0
            row.horizontalUnderflow = .growUniformly
            
            let avatar = Box(
                backgroundColor: .lightGray,
                cornerStyle: .rounded(radius: 32.0),
                wrapping: nil
            ).constrainedTo(width: .absolute(64), height: .absolute(64))

            row.add(fixed: avatar)
            
            row += FeedItemBody(post: post)
        }
        .inset(uniform: 16.0)
        .box(backgroundColor: .white)
    }

}

fileprivate struct FeedItemBody: ProxyElement {

    var post: Post

    var elementRepresentation: Element {
        Column { col in
            col.horizontalAlignment = .leading
            col.minimumVerticalSpacing = 8.0

            col += Row { row in
                row.minimumHorizontalSpacing = 8.0
                row.verticalAlignment = .center

                row += Label(text: post.authorName) {
                    $0.font = UIFont.boldSystemFont(ofSize: 14.0)
                }

                row += Label(text: post.timeAgo) {
                    $0.font = UIFont.systemFont(ofSize: 14.0)
                    $0.color = .lightGray
                }
            }

            col += Label(text: post.body) {
                $0.font = UIFont.systemFont(ofSize: 13.0)
            }
        }
    }

}
