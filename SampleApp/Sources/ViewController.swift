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

    private let blueprintView = BlueprintView()

    override func loadView() {
        self.view = blueprintView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        update()
    }

    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        update()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        update()
    }

    private func update() {
        blueprintView.element = element
    }

    private var viewSafeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return .zero
        }
    }

    var element: Element {
        let safeAreaInsets = viewSafeAreaInsets
        let screenScale = traitCollection.displayScale
        let theme = FeedTheme(authorColor: .green)

        return AdaptedEnvironment(
            by: { (environment) in
                environment.safeAreaInsets = safeAreaInsets
                environment.screenScale = screenScale
                environment.feedTheme = theme
            },
            wrapping: MainView(posts: posts))
    }
}

enum SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue = UIEdgeInsets.zero
}

extension Environment {
    var safeAreaInsets: UIEdgeInsets {
        get { return self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

enum ScreenScaleKey: EnvironmentKey {
    static let defaultValue = UIScreen.main.scale
}

extension Environment {
    var screenScale: CGFloat {
        get { return self[ScreenScaleKey.self] }
        set { self[ScreenScaleKey.self] = newValue }
    }
}

enum FeedThemeKey: EnvironmentKey {
    static let defaultValue = FeedTheme(authorColor: .black)
}

extension Environment {
    var feedTheme: FeedTheme {
        get { return self[FeedThemeKey.self] }
        set { self[FeedThemeKey.self] = newValue }
    }
}

struct FeedTheme {
    var authorColor: UIColor
}

fileprivate struct MainView: DynamicElement {
    
    var posts: [Post]
    
    func elementRepresentation(in environment: Environment) -> Element {
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
        .inset(by: environment.safeAreaInsets)
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
                col.add(child: FeedItem(post: post))
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

fileprivate struct FeedItemBody: DynamicElement {

    var post: Post

    func elementRepresentation(in environment: Environment) -> Element {
        let column = Column { col in

            col.horizontalAlignment = .leading
            col.minimumVerticalSpacing = 8.0

            let header = Row { row in
                row.minimumHorizontalSpacing = 8.0
                row.verticalAlignment = .center

                var name = Label(text: post.authorName)
                name.font = UIFont.boldSystemFont(ofSize: 14.0)
                name.color = environment.feedTheme.authorColor
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
