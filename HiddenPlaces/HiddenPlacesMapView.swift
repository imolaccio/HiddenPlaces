import SwiftUI
import MapKit

struct HiddenPlacesMapView: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.9, longitude: 12.5),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )
    )
    
    var body: some View {
        Map(position: $position)
            .navigationTitle("Mappa")
            .navigationBarTitleDisplayMode(.inline)
    }
}
