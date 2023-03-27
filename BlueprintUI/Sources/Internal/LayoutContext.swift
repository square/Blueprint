import Foundation

/// Information passed to content storage implementations during layout.
struct LayoutContext {
    var environment: Environment
    var node: LayoutTreeNode
}
