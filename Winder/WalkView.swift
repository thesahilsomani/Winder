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
    
    func clearLocationRatings() -> Void {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Destination")
        request.returnsObjectsAsFaults = false
        do {
            let result = try viewContext.fetch(request) as! [Destination]
            for i in 0..<(result.count) {
                result[i].rating = 0
                try viewContext.save()
            }
        } catch { print("Failed to reset Ratings in CoreData") }
    }

    private func getTimeFilter() -> MKPointOfInterestFilter {
        let components = Calendar.current.dateComponents([.hour], from: Date())
        let hour = components.hour ?? 0
        // let parks = [1,2,3,4,5,6,10,23,0]
        let restaurants = [7,8,9,11,12,13,19,20]
        let stores = [14,15,16,17,18]
        let dessert = [21,22]

        if restaurants.contains(hour) {
            return MKPointOfInterestFilter(including: [.restaurant])
        } else if stores.contains(hour) {
            return MKPointOfInterestFilter(including: [.store])
        } else if dessert.contains(hour) {
            return MKPointOfInterestFilter(including: [.bakery,.cafe])
        } else {
            return MKPointOfInterestFilter(including: [.park])
        }
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
        
        let filter = getTimeFilter()
        higherRadiusRequest.pointOfInterestFilter = filter
        lowerRadiusRequest.pointOfInterestFilter = filter
        
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
        return destinations
    }
    
    private func getDestinations() async -> Void{
        let stepsLeft = await getStepsLeft()
        var items = await getDestinations(steps: stepsLeft)
        items.sort{self.locationRating(name: $0.name!) > self.locationRating(name: $1.name!)}
        self.destinations = items
    }
    
    @State var subPageIndex = 0
    @State var destinationName = ""
    @State var destinations: [MKMapItem] = []
    @State var destCoords: CLLocationCoordinate2D = CLLocationCoordinate2D(
        latitude: 33.8,
        longitude: -117.9
    )
    
    var body: some View {
        if (subPageIndex == 0) {
            VStack {
                Text("Time for a Walk?\n")
                    .font(.system(size: 36, weight:.heavy))
                Button(action: { self.subPageIndex = (self.subPageIndex + 1) % 4 })
                { Text("Find Walks!") }
                    .buttonStyle(.bordered)
            }
        } else if (subPageIndex == 1) {
            
            List {
                ForEach(destinations.prefix(3), id: \.self) { loc in
                    VStack {
                        Button(action: {
                            destinationName = loc.name!
                            destCoords = CLLocationCoordinate2D(
                                latitude: loc.placemark.location!.coordinate.latitude,
                                longitude: loc.placemark.location!.coordinate.longitude
                            )
                            self.subPageIndex = (self.subPageIndex + 1) % 4
                        //}) { Text(loc.name! + ",  Rating: " + String(locationRating(name: loc.name!))) }
                        }) { Text(loc.name!) }
                    }
                }
            }.task {
                await getDestinations()
            }
        } else if (subPageIndex == 2) {
            VStack {
                GuideView(destCoords: $destCoords)
                Text("Navigating To: " + destinationName + "\n")
                Button(action: {
                    let latitude = destCoords.latitude
                    let longitude = destCoords.longitude
                    let url = URL(string: "maps://?saddr=&daddr=\(latitude),\(longitude)")
                    if UIApplication.shared.canOpenURL(url!) {
                          UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    }
                })
                { Text("Open in Apple Maps") }
                    .buttonStyle(.bordered)
                Button(action: { self.subPageIndex = (self.subPageIndex + 1) % 4 })
                { Text("Done With Walk") }
                    .buttonStyle(.bordered)
                    .padding(.bottom, 40)
            }
        } else {
            VStack {
                Text("Feedback Page")
                Text("How did you feel about walking to " + destinationName + "?\n")
                Button(action: {
                    self.subPageIndex = (self.subPageIndex + 1) % 4
                    modifyLocationRating(name: destinationName, modification: 5)
                })
                { Text("I Liked It") }
                    .buttonStyle(.bordered)
                Button(action: {
                    self.subPageIndex = (self.subPageIndex + 1) % 4
                    modifyLocationRating(name: destinationName, modification: -5)
                })
                { Text("I Didn't Like It") }
                    .buttonStyle(.bordered)
            }
        }
    }
}

struct WalkView_Previews: PreviewProvider {
    static var previews: some View {
        WalkView()
    }
}
