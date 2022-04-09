import BlueprintUI
import BlueprintUICommonControls


struct RuleElement: ProxyElement {
    var elementRepresentation: Element {
        ConstrainedSize(
            height: .absolute(1.0),
            wrapping: Box(backgroundColor: .black)
        )
    }
}
