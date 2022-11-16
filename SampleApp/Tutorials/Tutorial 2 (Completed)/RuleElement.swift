import BlueprintUI
import BlueprintUICommonControls


struct RuleElement: ProxyElement {
    var elementRepresentation: Element {
        Box(backgroundColor: .black)
            .constrainedTo(height: .absolute(1.0))
    }
}
