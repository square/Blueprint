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
        Column(alignment: .fill) { col in
            col += List(posts: posts)
            col += CommentForm()
        }.scrollable {
            $0.contentSize = .fittingHeight
            $0.alwaysBounceVertical = true
            $0.keyboardDismissMode = .onDrag
        }
        .box(background: UIColor(white: 0.95, alpha: 1.0))
    }
}

fileprivate struct List: ProxyElement {

    var posts: [Post]

    var elementRepresentation: Element {
        Column { col in
            col.horizontalAlignment = .fill
            col.minimumVerticalSpacing = 8.0

            col += posts.map { post in
                .fixed { FeedItem(post: post) }
            }
        }
    }
}

fileprivate struct CommentForm: ProxyElement {
    
    var elementRepresentation: Element {
        Column { col in
            col.horizontalAlignment = .fill

            col += .fixed {
                Label(text: "Add your comment:")
            }

            col += .fixed {
                TextField(text: "") {
                    $0.placeholder = "Name"
                }
            }

            col += .fixed {
                TextField(text: "") {
                    $0.placeholder = "Comment"
                }
            }
        }
        .inset(uniform: 16.0)
        .box(background: .lightGray)
    }
}


fileprivate struct FeedItem: ProxyElement {

    var post: Post

    var elementRepresentation: Element {
        Row { row in
            row.verticalAlignment = .leading
            row.minimumHorizontalSpacing = 16.0
            row.horizontalUnderflow = .growUniformly
            
            row += .fixed {
                Box(
                    backgroundColor: .lightGray,
                    cornerStyle: .rounded(radius: 32.0),
                    wrapping: nil
                ).constrainedTo(width: .absolute(64), height: .absolute(64))
            }
            
            row += .flexible {
                FeedItemBody(post: post)
            }
        }
        .inset(uniform: 16.0)
        .box(background: .white)
    }

}

fileprivate struct FeedItemBody: ProxyElement {

    var post: Post

    var elementRepresentation: Element {
        Column { col in
            col.horizontalAlignment = .leading
            col.minimumVerticalSpacing = 8.0

            col += .fixed {
                Row { row in
                    row.minimumHorizontalSpacing = 8.0
                    row.verticalAlignment = .center

                    row += .flexible {
                        Label(text: post.authorName) {
                            $0.font = UIFont.boldSystemFont(ofSize: 14.0)
                        }
                    }

                    row += .flexible {
                        Label(text: post.timeAgo) {
                            $0.font = UIFont.systemFont(ofSize: 14.0)
                            $0.color = .lightGray
                        }
                    }
                }
            }

            col += .flexible {
                Label(text: post.body) {
                    $0.font = UIFont.systemFont(ofSize: 13.0)
                }
            }
        }
    }

}
