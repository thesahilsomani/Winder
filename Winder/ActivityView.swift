import Foundation
import UIKit
import SwiftUI
import CoreData
import HealthKit

struct ActivityView : View
{
    @Environment(\.managedObjectContext) private var viewContext
    @State var currentStepCount: Int = 0
    @State var stepGoal: Int32 = -1
    
    func updateStepCount() {
        // Setting Up Health Store
        let healthStore = HKHealthStore()
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier .stepCount)!])
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in}
        // Defining Date Predicate
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let startDate = calendar.date(from: components)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate!)
        let today = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        // Defining Query
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: today, options: .cumulativeSum) { (query, statistics, errorOrNil) in
            if statistics == nil { return }
            let sum = statistics!.sumQuantity()
            let totalSteps = sum?.doubleValue(for: HKUnit.count())
            currentStepCount = Int(totalSteps!)
        }
        healthStore.execute(query)
    }
    
    func getStepGoal() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "StaticUserData")
        request.returnsObjectsAsFaults = false
        do {
            let result = try viewContext.fetch(request) as! [StaticUserData]
            for i in 0..<(result.count) {
                stepGoal = result[i].stepGoal
                print(result[i].stepGoal)
            }
            if (result.count > 1) { print("ERROR: Multiple StaticUserData Objects") }
        } catch { print("Failed") }
        print("success")
    }
    
    var body: some View
    {
        VStack {
            Text("Your Activity\n")
                .font(.system(size: 36, weight:.heavy))
            ZStack {
                VStack {
                    Text("Step Goal: " + String(stepGoal))
                        .onAppear { self.getStepGoal() }
                    Text("Current Step Count: " + String(currentStepCount))
                        .onAppear { self.updateStepCount() }
                    Text("Current Steps Left: " + String(stepGoal - Int32(currentStepCount)))
                }
                Circle()
                    .stroke(
                        Color.blue.opacity(0.5),
                        lineWidth: 30
                    )
                    .frame(width: 300, height: 300)
                Circle()
                    .trim(from: 0, to: (Double(currentStepCount)/Double(stepGoal)))
                    .stroke(
                        Color.blue,
                        lineWidth: 30
                    )
                    .frame(width: 300, height: 300)
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}
