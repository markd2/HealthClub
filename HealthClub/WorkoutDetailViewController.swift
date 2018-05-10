import UIKit
import HealthKit

private let dateFormatter = DateFormatter()

class WorkoutDetailViewController: UIViewController {
    var workout: HKWorkout!
    var hkstore: HKHealthStore!

        
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var samplesTableView: UITableView!
    @IBOutlet var heartRateGraphView: HeartRateGraphView!
    private let cellReuseIdentifier = "Cat."

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let workoutName = workout.workoutActivityType.humanReadableName()

        let start = workout.startDate
        dateFormatter.dateFormat = "MM / dd / YYYY"
        let startString = dateFormatter.string(from: start)
    
        titleLabel.text = "\(workoutName)\n\(startString)"
        
        self.samplesTableView.register(UITableViewCell.self,
                                       forCellReuseIdentifier: cellReuseIdentifier)
        loadWorkoutSamples()
    }
    
    private func loadWorkoutSamples() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            print("OOK!")
            return
        }

        // The Workout app on Apple Watch does not associate heart rate samples with its HKWorkout instances, so querying for heart rate samples using +[HKQuery predicateForObjectsFromWorkout:] will not return any results. Instead, you should query for heart rate samples using a date range predicate spanning the duration of the workout.
        
//        let workoutPredicate =
//            HKQuery.predicateForObjects(from: workout)
        
        let rangePredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [])
        let query = HKSampleQuery.init(sampleType: heartRateType,
                                       predicate: rangePredicate, // workoutPredicate,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil)
        { (query, samples, error) in
            guard let samples = samples else {
                print("so sad")
                return
            }

            let heartRates = samples.compactMap { $0 as? HKQuantitySample }
            
            DispatchQueue.main.async {
                self.heartRateGraphView.heartRateSamples = heartRates
            }
        }
        hkstore.execute(query)
    }
    
}



extension WorkoutDetailViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 12
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, 
                                                 for: indexPath) as UITableViewCell
        
//        let workout = workouts[indexPath.row]
//        
//        let name = workout.workoutActivityType.humanReadableName()
//        let duration = workout.duration
//        let durationString = formatter.string(from: duration) ?? "-"
//        let start = workout.startDate
//        
//        cell.textLabel?.text = "\(name) - \(durationString) - \(start)"
        
        cell.textLabel?.text = "\(indexPath.row)"
        
        return cell
    }
    
}




