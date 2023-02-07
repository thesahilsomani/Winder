import SwiftUI


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
    var body: some View
    {
        // Placeholder
        Text("Track Miles and Calories")
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
