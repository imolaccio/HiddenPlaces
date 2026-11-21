import SwiftUI
import MapKit
import Translation

struct PlaceDetailView: View {
    let place: Place
    @State private var showReport = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(place.name)
                    .font(.largeTitle.bold())
                
                if let description = place.description {
                    TranslatedText(originalText: description)
                }
                
                if let history = place.history {
                    Text("Storia")
                        .font(.headline)
                    TranslatedText(originalText: history)
                }
                
                if let lat = place.latitude, let lon = place.longitude {
                    Map(position: .constant(.region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )))) {
                        Annotation("", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                }
                
                if let analyses = place.analyses, !analyses.isEmpty {
                    AnalysisView(analyses: analyses)
                }
                
                Button("Segnala") {
                    showReport = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReport) {
            ReportView(type: "place", targetId: place.id)
        }
    }
}

struct TranslatedText: View {
    let originalText: String
    @State private var translated: String?
    @State private var config: TranslationSession.Configuration?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(translated ?? originalText)
            if translated == nil {
                Button("Traduci") {
                    config = .init(source: nil, target: Locale.current.language)
                }
                .font(.caption)
            }
        }
        .translationTask(config) { session in
            if let response = try? await session.translate(originalText) {
                translated = response.targetText
            }
        }
    }
}
