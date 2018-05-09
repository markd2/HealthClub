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
        
        let types = Set([HKObjectType.workoutType(),
                         HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
                         HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
                         HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
                         
                         HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.bloodType)!,
                         ])
        hkstore.requestAuthorization(toShare: [], read: types) {
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

extension ViewController: UITableViewDataSource {
    
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

}














