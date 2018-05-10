import UIKit
import HealthKit

class HeartRateGraphView: UIView {
    var heartRateSamples: [HKQuantitySample] = [] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let sample = heartRateSamples.first else { return }
        print("\(sample.quantity)")  // "89 count/min"

        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        
        let heartRates = heartRateSamples.map { Int($0.quantity.doubleValue(for: unit)) }
        print("got \(heartRateSamples.count) heart rates")

    }

}

