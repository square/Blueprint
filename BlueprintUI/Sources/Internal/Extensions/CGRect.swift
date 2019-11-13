import QuartzCore


extension CGRect {

    init(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
        self.init(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY)
    }

    func rounded(toScale scale: CGFloat) -> CGRect {
        return CGRect(
            minX: minX.rounded(.toNearestOrAwayFromZero, by: scale),
            minY: minY.rounded(.toNearestOrAwayFromZero, by: scale),
            maxX: maxX.rounded(.toNearestOrAwayFromZero, by: scale),
            maxY: maxY.rounded(.toNearestOrAwayFromZero, by: scale))
    }

    mutating func round(toScale scale: CGFloat) {
        self = rounded(toScale: scale)
    }

}
