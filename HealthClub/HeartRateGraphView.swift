import UIKit
import HealthKit

class HeartRateGraphView: UIView {
    var heartRates: [Int] = []
    
    var heartRateSamples: [HKQuantitySample] = [] {
        didSet {
            let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
            heartRates = heartRateSamples.map { Int($0.quantity.doubleValue(for: unit)) }

            self.setNeedsDisplay()
        }
    }

    private func drawBackground(_ bounds: CGRect) {
        UIColor.lightGray.set()
        UIRectFill(bounds)
    }
    
    private func drawFrame(_ bounds: CGRect) {
        UIColor.darkGray.set()
        UIRectFrame(bounds)
    }
    
    private func drawGraph(_ bounds: CGRect) {
        guard var min = heartRates.min() else { return }
        guard var max = heartRates.max() else { return }
        let count = heartRates.count
        
        let width = bounds.width
        let height = bounds.height
      
        let pad = 17 // just a random number
        min -= pad
        max += pad
        let range = max - min
        
        let xStride = width / CGFloat(count)
        let yScale = height / CGFloat(range)

        let bezPath = UIBezierPath()
        bezPath.move(to: CGPoint(x: 0.0, y: 0.0)) // y: CGFloat(max - min) * yScale / 2.0))
        
        var x = xStride
        for rate in heartRates {
            let y = CGFloat(max - rate) * yScale
            bezPath.addLine(to: CGPoint(x: x, y: y))
            x += xStride
        }
        UIColor.black.set()
        bezPath.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        guard let sample = heartRateSamples.first else { return }
        print("\(sample.quantity)")  // "89 count/min"

        print("got \(heartRateSamples.count) heart rates")
        drawBackground(bounds)
        drawGraph(bounds)
        drawFrame(bounds)
    }

}

