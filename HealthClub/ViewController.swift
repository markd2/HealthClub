//
//  ViewController.swift
//  HealthClub
//
//  Created by markd on 5/7/18.
//  Copyright © 2018 Borkware. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    var hkstore: HKHealthStore!
    @IBOutlet var messageLabel: UILabel!
    var workouts: [HKWorkout] = []
    
    @IBOutlet var workoutsTableView : UITableView!
    private let cellReuseIdentifier = "Cell"
    
    let formatter = DateComponentsFormatter()
    
    private func setMessage(_ message: String) {
        DispatchQueue.main.async {
            self.messageLabel.text = message
        }
    }
    
    private func setupHealthStore() {
        hkstore = HKHealthStore()
        
        let readTypes = Set([HKObjectType.workoutType(),
                         HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
                         HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
                         HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
                         
                         HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.bloodType)!,
                         ])
        
        let writeTypes = Set([HKObjectType.workoutType(),
                              HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!])
        hkstore.requestAuthorization(toShare: writeTypes, read: readTypes) {
            (success, error) in
            if !success {
                var messageText = "Couldn't access health store."
                
                if let error = error {
                    messageText += " \(error)"
                }
                self.setMessage(messageText)
                
            } else {
                self.setMessage("YAY")
            }
        }
    }
    
    private func processWorkoutSamples(_ samples: [HKSample]) {
        workouts = samples.compactMap { $0 as? HKWorkout }.reversed() // comes sorted by time
        let workoutCounts = workouts.reduce(into: [String: Int]()) { $0[$1.workoutActivityType.humanReadableName(), default: 0] += 1 }
        
        let workoutMessage = workoutCounts.reduce("", { $0 + "\($1.key) : \($1.value)\n" })
        setMessage("Workouts: " + workoutMessage)
        
        DispatchQueue.main.async {
            self.workoutsTableView.reloadData()
        }
    }
    
    @IBAction func fetchWorkouts() {
        let sampleType = HKWorkoutType.workoutType()
        
        let query = HKSampleQuery.init(sampleType: sampleType,
                                       predicate: nil,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil)
        { (query, samples, error) in
            guard let samples = samples else {
                self.setMessage("so sad")
                return
            }
            
            self.processWorkoutSamples(samples)
        }
        
        hkstore.execute(query)
    }
    
    @IBAction func getCharacteristicData() {
        do {
            let bloodtype = try hkstore.bloodType()
            setMessage(bloodtype.bloodType.humanReadableName())
        } catch {
            setMessage("Could not get blood type: \(error)")
        }
    }
    
    private func addWorkout() {
        let finish = Date()
        let start = finish.addingTimeInterval(-3600)
        

        // public convenience init(activityType workoutActivityType: HKWorkoutActivityType, start startDate: Date, end endDate: Date)
        // good luck trying to do completion with HKWorkout.init... #ilyxc

        let workout = HKWorkout(activityType: .americanFootball, 
                                start: start, end: finish)

//        let workout = HKWorkout.init(activityType: .americanFootball, start: start, end: finish, workoutEvents: workoutEvents, totalEnergyBurned: nil, totalDistance: nil, metadata: nil)
        
        hkstore.save(workout) { (success, error) in
            guard success else {
                self.setMessage("Bummer, couldn't make workout")
                return
            }
            self.setMessage("WOO!")

            // now add the heart rates
            var fakeSamples: [HKQuantitySample] = []
            
            for x in 0..<360 {
                let hrStart = start.addingTimeInterval(TimeInterval(x * 10)) // 10 seconds per heart rate
                
                guard let heartRateQuantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
                    fatalError("*** Unable to create a heart rate type ***")
                }
                
                let heartRate = 100 + 20 * sin(Double(x) / 50)
                let heartRateForIntervalQuantity = HKQuantity(unit: HKUnit(from: "count/min"),
                                                              doubleValue: heartRate)
                
                let heartRateForIntervalSample =
                    HKQuantitySample(type: heartRateQuantityType, 
                                     quantity: heartRateForIntervalQuantity,
                                     start: hrStart,
                                     end: hrStart)
                
                // Ethel the Aardvark goes Quantity Surveying
                
                fakeSamples.append(heartRateForIntervalSample)
            }
            
            self.hkstore.add(fakeSamples, to: workout) { (success, error) in
                guard success else {
                    self.setMessage("Bummer, couldn't add samples")
                    return
                }
                self.setMessage("Woo2")
            }

        }
    }
    
    @IBAction func makeWorkout() {
        addWorkout()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard HKHealthStore.isHealthDataAvailable() else {
            setMessage("OH NOES no health data available!")
            return
        }
        
        setupHealthStore()
        
        self.workoutsTableView.register(UITableViewCell.self,
                                        forCellReuseIdentifier: cellReuseIdentifier)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, 
                                                 for: indexPath) as UITableViewCell
        
        let workout = workouts[indexPath.row]
        
        let name = workout.workoutActivityType.humanReadableName()
        let duration = workout.duration
        let durationString = formatter.string(from: duration) ?? "-"
        let start = workout.startDate

        cell.textLabel?.text = "\(name) - \(durationString) - \(start)"
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let workout = workouts[indexPath.row]
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "WorkoutDetailViewController") 
            as! WorkoutDetailViewController
        vc.workout = workout
        vc.hkstore = hkstore
        self.navigationController?.pushViewController(vc, animated: true)
    }
}














