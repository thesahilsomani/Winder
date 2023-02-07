//
//  ContentView.swift
//  Winder
//
//  Created by Sahil Somani on 1/27/23.
//

import SwiftUI


struct CustomColor {
    static let customLightBlue = Color("customLightBlue")
}


struct LaunchView: View {
    var body: some View {
        ZStack {
            CustomColor.customLightBlue
                .ignoresSafeArea()
            
            VStack {
                Text("Winder")
                    .padding(.bottom, 30)
                Image(systemName: "figure.walk")
                        .foregroundColor(.white)
            }
            .bold()
            .font(.system(size: 50))
            .foregroundColor(.white)
            .padding(.bottom, 300)
        }
    }
}

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
        TabsView()
    }
}
