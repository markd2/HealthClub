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
                DispatchQueue.main.async {
                    var messageText = "Couldn't access health store."
                    
                    if let error = error {
                        messageText += " \(error)"
                    }
                
                    self.messageLabel.text = messageText
                }
            } else {
                DispatchQueue.main.async {
                    self.messageLabel.text = "YAY"
                }
            }
        }
    }
    
    private func setMessage(_ message: String) {
        DispatchQueue.main.async {
            self.messageLabel.text = message
        }
    }
    
    private func processWorkoutSamples(_ samples: [HKSample]) {
        workouts = samples.compactMap { $0 as? HKWorkout }
        let workoutCounts = workouts.reduce(into: [String: Int]()) { $0[$1.workoutActivityType.humanReadableName(), default: 0] += 1 }
        
        let workoutMessage = workoutCounts.reduce("", { $0 + "\($1.key) : \($1.value)\n" })
        setMessage("Workouts: " + workoutMessage)
    }
    
    @IBAction func fetchWorkouts() {
        let sampleType = HKWorkoutType.workoutType()
    
        let query = HKSampleQuery.init(sampleType: sampleType,
                                  predicate: nil,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil)
        { (query, samples, error) in
            guard let samples = samples else {
                DispatchQueue.main.async {
                    self.messageLabel.text = "so sad"
                }
                return
            }
            
            self.processWorkoutSamples(samples)
        }
        
        hkstore.execute(query)
    }
    
    @IBAction func getCharacteristicData() {
        do {
            let bloodtype = try hkstore.bloodType()
            self.messageLabel.text = bloodtype.bloodType.humanReadableName()
        } catch {
            self.messageLabel.text = "Could not get blood type: \(error)"
        }

    }

    override func viewDidLoad() {
        guard HKHealthStore.isHealthDataAvailable() else {
            messageLabel.text = "OH NOES no health data available!"
            return
        }
        
        setupHealthStore()
        
        super.viewDidLoad()
    }
}














