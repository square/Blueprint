import BlueprintUI
import BlueprintUICommonControls


struct RuleElement: ProxyElement {
    var elementRepresentation: Element {
        return ConstrainedSize(
            wrapping: Box(backgroundColor: .black),
            height: .absolute(1.0))
    }
}
