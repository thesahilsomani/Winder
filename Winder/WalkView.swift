import Foundation
import UIKit
import SwiftUI
import CoreData
import CoreLocation
import MapKit
import HealthKit

struct WalkView : View
{
    @ObservedObject var locationManager = LocationManager()
    @Environment(\.managedObjectContext) private var viewContext
    
    private let stepDelta: Double = 1000
    @State private var currentStepCount: Double = 0
    @State private var stepGoal: Double = 0
    
    func updateStepCount() async {
        // Setting Up Health Store
        let healthStore = HKHealthStore()
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier .stepCount)!])
        do {
            try await healthStore.requestAuthorization(toShare: allTypes, read: allTypes)
        }  catch { }
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
            self.currentStepCount = (totalSteps!)
        }
        healthStore.execute(query)
    }
    
    func fetchStepGoal() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "StaticUserData")
        request.returnsObjectsAsFaults = false
        do {
            let result = try viewContext.fetch(request) as! [StaticUserData]
            for i in 0..<(result.count) {
                self.stepGoal = Double(result[i].stepGoal)
            }
            if (result.count > 1) { print("ERROR: Multiple StaticUserData Objects") }
        } catch { print("Failed") }
    }
    
    
    func getStepsLeft() async -> Double {
        await self.updateStepCount()
        usleep(5000) // TODO: figure out synchronizations so we can remove this
        self.fetchStepGoal()
        return self.stepGoal - self.currentStepCount
    }

    func locationRating(name: String) -> Int32 {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Destination")
        request.returnsObjectsAsFaults = false
        do {
            let result = try viewContext.fetch(request) as! [Destination]
            for i in 0..<(result.count) {
                if result[i].name == name {
                    return result[i].rating
                }
            }
        } catch { print("Failed to get Ratings from CoreData") }
        return 0
    }

    func modifyLocationRating(name: String, modification: Int32) {
        // Location Exists
        print(name, modification)
        var request = NSFetchRequest<NSFetchRequestResult>(entityName: "Destination")
        request.returnsObjectsAsFaults = false
        do {
            let result = try viewContext.fetch(request) as! [Destination]
            for i in 0..<(result.count) {
                if result[i].name == name {
                    result[i].rating += modification
                    try viewContext.save()
                    return
                }
            }
        } catch { print("Failed to modify Ratings in CoreData") }
        
        // New Location
        request = NSFetchRequest<NSFetchRequestResult>(entityName: "Destination")
        request.returnsObjectsAsFaults = false
        do {
            let newData = Destination(context: viewContext)
            newData.name = name
            newData.rating = modification
            try viewContext.save()
        } catch { print("Failed to add Rating to CoreData") }
    }
    
    private func getDestinations(steps: Double) async -> [MKMapItem] {
        guard let location = locationManager.location else {
                print("Location is nil!")
                return []
        }
        
        let lowerRadius: CLLocationDistance = Double(steps) / 1.5
        let higherRadius: CLLocationDistance = (Double(steps) + self.stepDelta) / 1.5
        
        let lowerRadiusRequest = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: lowerRadius)
        let higherRadiusRequest = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: higherRadius)
        
        higherRadiusRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant])
        lowerRadiusRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant])
        
        let higherRadiusSearch = MKLocalSearch(request: higherRadiusRequest)
        let lowerRadiusSearch = MKLocalSearch(request: lowerRadiusRequest)
        
        var higherRadiusMapItems: [MKMapItem] = []
        var lowerRadiusMapItems: [MKMapItem] = []
        
        
        var destinations: [MKMapItem] = []
        
        var resp: MKLocalSearch.Response = MKLocalSearch.Response()
        do {
            resp = try await lowerRadiusSearch.start()
            lowerRadiusMapItems += resp.mapItems
        }  catch { }
        
        resp = MKLocalSearch.Response()
        do {
            resp = try await higherRadiusSearch.start()
            higherRadiusMapItems += resp.mapItems
        }  catch { }
        
        for highItem in higherRadiusMapItems {
            var duplicate = false
            for lowItem in lowerRadiusMapItems {
                if (highItem.name == lowItem.name) {
                    duplicate = true
                }
            }
            if (!duplicate) {
                destinations.append(highItem)
            }
        }

//        print("LOWER COUNT: ", lowerRadiusMapItems.count, " HIGHER COUNT:  ",
//              higherRadiusMapItems.count, " DESTINATIONS: ", destinations.count)
        return destinations
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Button("FIND LOCATIONS") {
                Task {
                    let stepsLeft = await getStepsLeft()
                    var items = await getDestinations(steps: stepsLeft)
                    //modifyLocationRating(name: items[0].name!, modification: 3)
                    //modifyLocationRating(name: items[1].name!, modification: -10)
                    //modifyLocationRating(name: items[7].name!, modification:20)
                    items.sort{self.locationRating(name: $0.name!) > self.locationRating(name: $1.name!)}
                    
                    print("\nTOP 3 ITEMS:")
                    var i = 0
                    for item in items {
                        print(item.name ?? "NIL LOCATION", " RATING: ", locationRating(name: item.name!))
                        i += 1
                        if (i == 3) {
                            break
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}


struct WalkView_Previews: PreviewProvider {
    static var previews: some View {
        WalkView()
    }
}


// EXTRA OR TESTING CODE

//print("\nALL ITEMS:")
//for item in items {
//    print(item.name ?? "NIL LOCATION", " RATING: ", locationRating(name: item.name!))
//}
