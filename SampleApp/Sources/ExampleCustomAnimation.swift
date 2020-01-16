//
//  StatusProgressView.swift
//  SquareLoyaltyTransactionUI
//
//  Created by Zach Olson on 3/23/16.
//

import Foundation
import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class StatusProgressViewController : UIViewController
{
    let blueprintView = BlueprintView()
    
    override func loadView() {
        
        self.view = self.blueprintView
        
        self.blueprintView.setElement(animated: true, self.element)
                
        self.view.backgroundColor = .init(white: 0.9, alpha: 1.0)
    }
    
    var showingProgress : Bool = true
    
    var element : Element {
        Column { column in
            column.minimumVerticalSpacing = 50.0
            column.verticalUnderflow = .justifyToCenter
            column.horizontalAlignment = .center
            
            if self.showingProgress {
                let spinner = Transition(
                    onAppear: TransitionAnimation(custom: StatusProgressAnimation()),
                    wrapping: StatusProgressElement(
                        model: .init(initialPoints: 1, earnedPoints: 10, lowestTierPoints: 15),
                        config: .init(radius: 100, lineWidth: 5, duration: 1.0)
                    )
                )
                
                column.add(growPriority: 0.0, shrinkPriority: 0.0, child: spinner)
            }
                            
            column.add(
                growPriority: 0.0,
                shrinkPriority: 0.0,
                child: Tappable(
                    onTap: {
                        self.showingProgress.toggle()
                        self.reloadElement()
                    },
                    wrapping: Button(title: "Show/Hide Spinner")
                )
            )
        }
    }
    
    func reloadElement()
    {
        self.blueprintView.setElement(animated: true, self.element)
    }
    
    struct Button : ProxyElement
    {
        var title : String
        
        var elementRepresentation: Element {
            let content = Centered(ConstrainedSize(height: .atLeast(60.0), wrapping: Label(text: self.title) { label in
                label.font = .systemFont(ofSize: 16.0, weight: .semibold)
            }))
            
            return BlueprintUICommonControls.Button(wrapping: Box(backgroundColor: .init(white: 0.95, alpha: 1.0), wrapping: content))
        }
    }
}


struct StatusProgressAnimation : CustomTransitionAnimation
{
    typealias ViewType = StatusProgressView
    
    func animate(
        direction: TransitionAnimation.Direction,
        with view: StatusProgressAnimation.ViewType,
        currentProperties: AnimatableViewProperties,
        completion: @escaping (Bool) -> ()
    ) {
        view.animate()
        
        completion(true)
    }
}

public struct StatusProgressConfig {
    let radius: CGFloat
    let lineWidth: CGFloat
    
    let textCornerRadius: CGFloat = 20.0
    let textBorderSize: CGFloat = 5.0
    let textSidePadding: CGFloat = 10.0
    let textTopPadding: CGFloat = 5.0
    
    let lineColor: UIColor
    let trackColor: UIColor
    let contentBackgroundColor: UIColor
    
    let font: UIFont
    
    let duration: CFTimeInterval
    
    public init(radius: CGFloat, lineWidth: CGFloat, duration: CFTimeInterval = 0.7) {
        self.radius = radius
        self.lineWidth = lineWidth
        self.duration = duration
        lineColor = UIColor.darkGray
        trackColor = UIColor.lightGray
        contentBackgroundColor = UIColor.white
        font = UIFont.systemFont(ofSize: 18.0, weight: .semibold)
    }
}

public struct StatusProgressModel {
    
    public let startPercentage: CGFloat
    public let endPercentage: CGFloat
    
    public let earnedPointsText: String?
    
    public init(initialPoints: Int, earnedPoints: Int, lowestTierPoints: Int) {
        startPercentage = StatusProgressModel.percentage(numerator: initialPoints, denominator: lowestTierPoints)
        endPercentage = StatusProgressModel.percentage(numerator: (initialPoints + earnedPoints), denominator: lowestTierPoints)
        
        if (earnedPoints > 0) {
            let earnedPointsFormatted = NumberFormatter.localizedString(from: NSNumber(value: earnedPoints), number: .decimal)
            earnedPointsText = String(format: "+%@", earnedPointsFormatted)
        } else {
            earnedPointsText = nil
        }
    }
    
    private static func percentage(numerator: Int, denominator: Int) -> CGFloat
    {
        guard denominator > 0 else {
            return 0
        }
        
        return numerator >= denominator ? 1 : CGFloat(numerator) / CGFloat(denominator)
    }
}

struct StatusProgressElement : Element
{
    var model : StatusProgressModel
    var config : StatusProgressConfig
    
    var content: ElementContent {
        ElementContent { _ in
            StatusProgressView.intrinsicContentSize(with: self.model, config: self.config)
        }
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        ViewDescription(StatusProgressView.self) { config in
            config.builder = {
                StatusProgressView(model: self.model, config: self.config)
            }
        }
    }
}


class StatusProgressView: UIView
{
    let model: StatusProgressModel
    let config: StatusProgressConfig
    
    lazy var circleTrack: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = config.trackColor.cgColor
        layer.lineCap = .round
        layer.lineWidth = config.lineWidth
        layer.path = path()
        return layer
    }()
    
    lazy var circleFillLine: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = config.lineColor.cgColor
        layer.lineCap = .round
        layer.lineWidth = config.lineWidth
        layer.path = path()
        layer.strokeStart = 0.0
        return layer
    }()
    
    lazy var pointsLabel: StatusProgressPointsLabel? = {
        if let text = model.earnedPointsText {
            return StatusProgressPointsLabel(text: text, config: config)
        } else {
            return nil
        }
    }()
    
    lazy var labelHeight: CGFloat = {
        if let label = pointsLabel {
            return config.font.lineHeight * 2
        } else {
            return 0
        }
    }()
    
    let starImage = UIImageView(image: UIImage(imageLiteralResourceName: "StatusStar"))
    
    init(model: StatusProgressModel, config: StatusProgressConfig) {
        self.model = model
        self.config = config
        super.init(frame: .zero)
        
        layer.addSublayer(circleTrack)
        layer.addSublayer(circleFillLine)
        
        var starVerticalAdjustment: CGFloat = 0.0
        if let label = pointsLabel {
            addSubview(label)
            let height = labelHeight
            starVerticalAdjustment = height / 3.0
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: height).isActive = true
            NSLayoutConstraint(item: label, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: (config.radius)).isActive = true
        }
        
        addSubview(starImage)
        let starSize = config.radius
        starImage.translatesAutoresizingMaskIntoConstraints = false
        starImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: (starVerticalAdjustment * -1)).isActive = true
        starImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        starImage.heightAnchor.constraint(equalToConstant: starSize).isActive = true
        starImage.widthAnchor.constraint(equalToConstant: starSize).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func intrinsicContentSize(with model: StatusProgressModel, config: StatusProgressConfig) -> CGSize
    {
        let fullRadius = config.radius + (config.lineWidth / 2)
        let circleSize = fullRadius * 2
        
        var labelHeightAdjustment: CGFloat = 0.0
        
        if model.earnedPointsText != nil {
            labelHeightAdjustment = config.font.lineHeight - config.lineWidth
        }
        
        return CGSize(
            width: circleSize,
            height: circleSize + labelHeightAdjustment
        )
    }
    
    override var intrinsicContentSize: CGSize {
        return StatusProgressView.intrinsicContentSize(with: self.model, config: self.config)
    }
    
    public func animate() {
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.duration = config.duration
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        strokeAnimation.fromValue = model.startPercentage
        strokeAnimation.toValue = model.endPercentage
        
        circleFillLine.strokeEnd = model.endPercentage
        circleFillLine.add(strokeAnimation, forKey: "strokeEndAnimation")
    }
    
    private func path() -> CGPath {
        let size = intrinsicContentSize.width
        let center = CGPoint(x: size / 2, y: size / 2)
        let startAngle = CGFloat(.pi * (-0.5))
        let endAngle = CGFloat(.pi * (1.5))
        return UIBezierPath(arcCenter: center, radius: config.radius, startAngle: startAngle, endAngle: endAngle, clockwise: true).cgPath
    }
}

class StatusProgressPointsLabel: UIView {
    
    let config: StatusProgressConfig
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = config.font
        label.textColor = config.contentBackgroundColor
        return label
    }()

    lazy var contentArea: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = config.lineColor
        view.layer.cornerRadius = config.textCornerRadius
        return view
    }()

    lazy var centeringConstraints: [NSLayoutConstraint] = {
        
        label.sizeToFit()
        let labelConstraints = StatusProgressPointsLabel.centeringConstraints(
            inner: label,
            outer: contentArea,
            paddingSide: config.textSidePadding,
            paddingTop: config.textTopPadding
        )
        let contentConstraints = StatusProgressPointsLabel.centeringConstraints(
            inner: contentArea,
            outer: self,
            paddingSide: config.textBorderSize,
            paddingTop: config.textBorderSize
        )
        return labelConstraints + contentConstraints
    }()
    
    init(text: String, config: StatusProgressConfig) {
        self.config = config
        super.init(frame: .zero)
        
        backgroundColor = config.contentBackgroundColor
        layer.cornerRadius = config.textCornerRadius
        layer.masksToBounds = true
        
        label.text = text
        accessibilityLabel = text
        
        contentArea.addSubview(label)
        addSubview(contentArea)
        NSLayoutConstraint.activate(centeringConstraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func centeringConstraints(inner: UIView, outer: UIView, paddingSide: CGFloat, paddingTop: CGFloat) -> Array<NSLayoutConstraint> {
        return [
            NSLayoutConstraint(item: inner, attribute: .centerX, relatedBy: .equal, toItem: outer, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: inner, attribute: .centerY, relatedBy: .equal, toItem: outer, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: outer, attribute: .width, relatedBy: .equal, toItem: inner, attribute: .width, multiplier: 1, constant: paddingSide),
            NSLayoutConstraint(item: outer, attribute: .height, relatedBy: .equal, toItem: inner, attribute: .height, multiplier: 1, constant: paddingTop),
        ]
    }
}
