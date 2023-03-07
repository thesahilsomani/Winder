import Foundation
import UIKit
import SwiftUI
import CoreData



struct SettingsView: View {
    
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selection = "Miles"
    @State private var enteredText = ""
    let goalTypes = ["Miles", "Kilometers", "Steps"]
    
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
    
    func setStepGoal(goal: Int32) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "StaticUserData")
        request.returnsObjectsAsFaults = false
        do {
            var result = try viewContext.fetch(request) as! [StaticUserData]
            if (result.count < 1) {
                let newData = StaticUserData(context: viewContext)
                newData.stepGoal = -1
                try viewContext.save()
            }
            
            result = try viewContext.fetch(request) as! [StaticUserData]
            
            for i in 0..<(result.count) { result[i].stepGoal = goal }
            if (result.count != 1) { print("ERROR: " + String(result.count) + " StaticUserData Objects") }
        } catch { print("Failed") }
        do {
          try viewContext.save()
         } catch {
          print("Error saving")
        }
        print("success in saving step goal " + String(goal))
    }
    
    var body: some View {
        ZStack {
            CustomColor.customLightBlue
            VStack {
                VStack {
                    
                    Text("Settings")
                        .font(.system(size: 50))
                        .bold()

                    
                    Button(action: { clearLocationRatings(); print("Cleared Ratings Store") })
                    { Text("Clear Location Ratings") }
                        .buttonStyle(.bordered)
                    
                    Text("Selected Goal type: \(selection)")
                        .font(.custom("Nunito", size: 20))
                    
                    Picker("Select a Goal Type", selection: $selection) {
                        ForEach(goalTypes, id: \.self) {
                            Text($0)
                                .font(.custom("Nunito", size: 50))
                        }
                    }
                    .pickerStyle(.menu)
                    
                    
                    TextField(text: $enteredText) {
                        Text("Enter a move goal")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .onSubmit {
                        self.setStepGoal(goal: Int32(enteredText) ?? -1)
                    }
                    
                }
                .frame(width: nil, height: nil)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                
                Spacer()
                .ignoresSafeArea()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
