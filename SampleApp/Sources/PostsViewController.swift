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


final class PostsViewController: UIViewController {

    private let blueprintView = BlueprintView()

    override func loadView() {
        self.view = blueprintView
        
        self.blueprintView.element = MainView(posts: posts)
    }
}

fileprivate struct MainView: ProxyElement {
    
    var posts: [Post]
    
    var elementRepresentation: Element {
        Column { col in
            col.horizontalAlignment = .fill

            col.add(child: List(posts: posts))
            col.add(child: CommentForm())
        }
        .scrollable {
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

            for post in posts {
                col.add(child: AppearanceTransition(
                    onAppear: .scaleAndFade,
                    wrapping: FeedItem(post: post)
                    )
                )
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

            var nameField = TextField(text: "")
            nameField.placeholder = "Name"
            col.add(child: nameField)

            var commentField = TextField(text: "")
            commentField.placeholder = "Comment"
            col.add(child: commentField)
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

            let avatar = Box(
                backgroundColor: .lightGray,
                cornerStyle: .rounded(radius: 32.0)
            ).constrainedTo(width: .absolute(64.0), height: .absolute(64.0))

            row.add(
                growPriority: 0.0,
                shrinkPriority: 0.0,
                child: avatar
            )

            row.add(
                growPriority: 1.0,
                shrinkPriority: 1.0,
                child: FeedItemBody(post: post)
            )
        }
        .inset(uniform: 16.0)
        .box(background: .white)
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
                row.add(child: timeAgo)
            }

            col.add(child: header)

            var body = Label(text: post.body)
            body.font = UIFont.systemFont(ofSize: 13.0)

            col.add(child: body)
        }

        return column
    }

}
