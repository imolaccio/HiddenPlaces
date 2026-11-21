import SwiftUI
import MapKit

struct HiddenPlacesMapView: View {
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
            span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
        )
    )
    @State private var places: [Place] = []
    @State private var showAddPlace = false
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(places) { place in
                    if let lat = place.latitude, let lon = place.longitude {
                        Annotation(place.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                Text(place.name)
                                    .font(.caption2)
                                    .padding(4)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("HiddenPlaces")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddPlace = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddPlace) {
                AddPlaceView()
            }
            .task {
                // places = (try? await APIClient.shared.fetchPlaces()) ?? []
            }
        }
    }
}
