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
    
    @IBAction func fetchWorkouts() {
        let sampleType = HKWorkoutType.workoutType()
    
        let query = HKSampleQuery.init(sampleType: sampleType,
                                  predicate: nil,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil)
        {
            (query, samples, error) in
            
            guard let samples = samples else {
                DispatchQueue.main.async {
                    self.messageLabel.text = "so sad"
                }
                return
            }

            var reduction = [String: Int]()
            for sample in samples {
                if let workoutSample = sample as? HKWorkout {
                    let name = workoutSample.workoutActivityType.humanReadableName()
                    reduction[name, default: 0] += 1
                } else {
                    print("BOO")
                }
            }
            
            DispatchQueue.main.async {
                let workouts = reduction.reduce("", { (result, keyvalue) -> String in
                    return result + "\(keyvalue.key) : \(keyvalue.value)\n"
                })

                self.messageLabel.text = workouts
            }
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














