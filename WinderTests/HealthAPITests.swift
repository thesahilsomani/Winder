//
//  HealthAPITests.swift
//  WinderTests
//
//  Created by Sahil Somani on 2/4/23.
//

import Foundation
import XCTest
import HealthKit
@testable import Winder


final class HealthAPITests: XCTestCase {

    func testExample() throws {
        print("Running Test")
        if !HKHealthStore.isHealthDataAvailable() {
            print("HEALTHKIT NOT AVAILABLE")
            return
        }
        print("HealthKit Available")
        let healthStore = HKHealthStore()
        
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier .stepCount)!])
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
            if !success {
                print("Error Message: ")
                print(error!)
            }
        }
        
        guard HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) != nil else {
            fatalError("*** Unable to get the step count type ***")
        }

        // Setting Date for Query
        let calendar = NSCalendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let startDate = calendar.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
            fatalError("*** Unable to create the end date ***")
        }
        let today = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        print(type)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: today, options: .cumulativeSum) { (query, statisticsOrNil, errorOrNil) in
            
            print("start query")
            print(statisticsOrNil)
            guard let statistics = statisticsOrNil else {
                print(errorOrNil!)
                return
            }
            print("mid query")

            let sum = statistics.sumQuantity()
            let totalSteps = sum?.doubleValue(for: HKUnit.count())
            print("STEP COUNT: ", totalSteps ?? 0)
            
            print("end query")

        }

        print("Executing Query")
        healthStore.execute(query)
        sleep(2)
        print("Test Complete")
        XCTAssertTrue(true)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }


}
