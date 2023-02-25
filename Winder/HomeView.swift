import SwiftUI
import HealthKit
import CoreData

struct TabsView: View
{
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View
    {
        TabView
        {
            WalkView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem
            {
                Image(systemName: "figure.walk")
                Text("Walks")
            }
            
            ActivityView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem
            {
                Image(systemName: "heart")
                Text("Activity")
            }
            
            SettingsView()
                .environment(\.managedObjectContext, viewContext)
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
