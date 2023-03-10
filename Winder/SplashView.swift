import SwiftUI
import HealthKit
import CoreData

struct CustomColor {
    static let customLightBlue = Color("customLightBlue")
}

struct SplashView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var shouldShowOnboarding: Bool = true

    var body: some View {
        NavigationView {
            TabsView()
                .navigationTitle("Home")
                .environment(\.managedObjectContext, viewContext)
        }
        .fullScreenCover(isPresented: $shouldShowOnboarding) {
            SplashPopupView(shouldShowOnboarding: $shouldShowOnboarding)
        }
    }
}

struct SplashPopupView: View {
    @Binding var shouldShowOnboarding: Bool

    var body: some View {
        ZStack {
            CustomColor.customLightBlue
                .ignoresSafeArea()

            VStack {
                Text("Winder")
                    .padding(.bottom, 30)
                    .bold()
                    .font(.system(size: 50))
                    .foregroundColor(.white)

                Image(systemName: "figure.walk")
                        .foregroundColor(.white)
                        .bold()
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .padding(.bottom, 300)

                Button {
                    let healthStore = HKHealthStore()
                    let allTypes = Set([HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier .stepCount)!])
                    healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in}
                    shouldShowOnboarding.toggle()
                } label: {
                    Text("Get Started")
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 250, height: 50)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
