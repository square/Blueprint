import BlueprintUI
import BlueprintUICommonControls
import UIKit


final class PlaygroundViewController: UIViewController {

    let gridSize = 30
    private let blueprintView = BlueprintView()

    private lazy var model: [[Int]] = {
        var cols = [[Int]]()
        for i in 0..<gridSize {
            var row = [Int]()
            for j in 0..<gridSize {
                row.append(0)
            }
            cols.append(row)
        }
        return cols
    }()

    override func loadView() {
        view = blueprintView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        update()
    }

    private func update() {
        blueprintView.element = element
    }

    var element: Element {

        Column { col in
            for (i, values) in model.enumerated() {
                col.horizontalAlignment = .fill
                let row = Row { row in
                    for (j, value) in values.enumerated() {
                        let label = Label(text: String(value))
                            .centered()
                            .constrainedTo(size: .init(width: 20, height: 20))
                            .box(background: .red)
                            .tappable {
                                self.model[i][j] = self.model[i][j] + 1
                                self.update()
                            }
                        row.add(child: label)
                    }
                }
                col.add(child: row)
            }
        }.inset(uniform: 20)
    }
}
