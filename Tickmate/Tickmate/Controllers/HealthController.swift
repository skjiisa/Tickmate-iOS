//
//  HealthController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 7/19/21.
//

import HealthKit

class HealthController: ObservableObject {
    static let shared = HealthController()
    private init() {}
    
    let healthStore = HKHealthStore()
    
    func requestAuth(completion: @escaping (Bool) -> Void) {
        healthStore.requestAuthorization(toShare: nil, read: [.activitySummaryType()]) { success, error in
            completion(success)
        }
    }
    
    func readActivity(completion: @escaping (_ stand: Bool, _ exercise: Bool, _ energy: Bool) -> Void) {
        requestAuth { [unowned self] success in
            guard success else { return }
            
            let calendar = Calendar.autoupdatingCurrent
            
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            dateComponents.calendar = calendar
            let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)
            
            let query = HKActivitySummaryQuery(predicate: predicate) { query, summaries, error in
                if let error = error {
                    return NSLog("Error querying activity summary: \(error)")
                }
                guard let summary = summaries?.first else { return }
                
                let stand = summary.appleStandHours.compare(summary.appleStandHoursGoal) != .orderedAscending
                let exercise =  summary.appleExerciseTime.compare(summary.appleExerciseTimeGoal) != .orderedAscending
                let energy = summary.activeEnergyBurned.compare(summary.activeEnergyBurnedGoal) != .orderedAscending
                
                completion(stand, exercise, energy)
            }
            
            healthStore.execute(query)
        }
    }
}
