import Foundation

/// Information passed to content storage implementations during `sizeThatFits`.
struct MeasureContext {
    var environment: Environment
    var node: LayoutTreeNode
}
