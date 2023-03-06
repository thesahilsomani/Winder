import SwiftUI
import Foundation
import MapKit
import CoreLocation
import Combine


struct GuideView : View
{
    @State private var directions: [String] = []
    @State private var showDirections = false

    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion.defaultRegion
    @State private var userTrackingMode: MKUserTrackingMode = .follow
    @State private var cancellable: AnyCancellable?
    
    @Binding var destCoords: CLLocationCoordinate2D
    
    private func setCurrentRegion()
    {
        print("our region is set")
        cancellable = locationManager.$location.sink{ location in
            region = MKCoordinateRegion(center: location?.coordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
    }
    
    var body: some View
    {
        VStack
        {
            MapView(directions: $directions, region: $region, userTrackingMode: $userTrackingMode, destCoords: $destCoords)
                .onAppear(perform: setCurrentRegion)

            Button(action: {
                self.showDirections.toggle()
            }, label: {
                Text("Show Directions")
            })
            .disabled(directions.isEmpty)
            .padding()
        }
        .onAppear(perform: self.setCurrentRegion)
        .sheet(isPresented: $showDirections, content: {
            VStack(spacing: 0) {
                Text("Directions")
                .font(.largeTitle)
                .bold()
                .padding()

                Divider().background(Color(UIColor.systemBlue))

                List(0..<self.directions.count, id: \.self) { i in
                    Text(self.directions[i]).padding()
                }
            }
        })
    }
}

struct MapView : UIViewRepresentable {
    typealias UIViewType = MKMapView

    @Binding var directions: [String]
    @Binding var region: MKCoordinateRegion
    @Binding var userTrackingMode: MKUserTrackingMode
    @Binding var destCoords: CLLocationCoordinate2D
    
    func makeCoordinator() -> MapViewCoordinator {
        return MapViewCoordinator()
    }

    func makeUIView(context: Context) -> MKMapView
    {
        let mapView = MKMapView(frame: UIScreen.main.bounds)
        mapView.delegate = context.coordinator
        mapView.userTrackingMode = userTrackingMode
        mapView.setRegion(region, animated: true)
        
        // User's Location
        let start = CLLocationCoordinate2D(
            latitude: mapView.userLocation.location?.coordinate.latitude ?? region.center.latitude,
            longitude: mapView.userLocation.location?.coordinate.longitude ?? region.center.longitude
        )
        let p1 = MKPlacemark(coordinate: start)
        
        // Disney
        /*
        let destination = CLLocationCoordinate2D(
            latitude: 33.8121,
            longitude: -117.9190
        )
        */
        let p2 = MKPlacemark(coordinate: destCoords)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: p1)
        request.destination = MKMapItem(placemark: p2)
        request.transportType = .walking
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else { return }
            mapView.addAnnotations([p1, p2])
            mapView.addOverlay(route.polyline)
            mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
            self.directions = route.steps.map { $0.instructions }.filter { !$0.isEmpty }
        }
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context)
    {
        uiView.userTrackingMode = userTrackingMode
    }

    class MapViewCoordinator: NSObject, MKMapViewDelegate
    {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
        {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            return renderer
        }
    }
}

extension MKCoordinateRegion
{
    static var defaultRegion: MKCoordinateRegion {
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.8, longitude: -117.8), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    }
}
