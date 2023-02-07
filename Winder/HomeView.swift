import SwiftUI
import HealthKit


struct WalkView : View
{
    var body: some View
    {
        Form
        {
            // Placeholder
            Text("Placeholder")
        }
    }
}

struct ActivityView : View
{
    @State var currentStepCount: Int = -1
    
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
    
    var body: some View
    {
        VStack {
            Text("Track Miles and Calories")
            Text("Current Step Count: " + String(currentStepCount))
                .onAppear { self.updateStepCount() }
        }
    }
}

struct SettingsView : View
{
    var body: some View
    {
        // Placeholder
        Text("smth")
    }
}


struct TabsView: View
{
    var body: some View
    {
        TabView
        {
            WalkView()
                .tabItem
            {
                Image(systemName: "figure.walk")
                Text("Walks")
            }
            
            ActivityView()
                .tabItem
            {
                Image(systemName: "heart")
                Text("Activity")
            }
            
            SettingsView()
                .tabItem
            {
                Image(systemName: "gearshape")
                Text("Settings")
            }
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        TabsView()
    }
}
