import SwiftUI
import PhotosUI
import CoreLocation
import ImageIO

struct AddPlaceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var history = ""
    @State private var selectedCategory = 1
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var location: CLLocationCoordinate2D?
    @State private var photoLocation: CLLocationCoordinate2D?
    @State private var showLocationChoice = false
    @State private var showConfirmation = false
    @State private var selectedSource = ""
    
    let categories = ["Sorgente", "Cascata", "Grotta", "Albero secolare", "Rudere", "Fossile", "Chiesa antica", "Sagra di paese", "Luogo abbandonato", "Luogo infestato", "Vista panoramica", "Curiosità naturale"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informazioni") {
                    TextField("Nome del luogo", text: $name)
                    Picker("Categoria", selection: $selectedCategory) {
                        ForEach(0..<categories.count, id: \.self) { i in
                            Text(categories[i]).tag(i + 1)
                        }
                    }
                    TextField("Descrizione", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Storia", text: $history, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Foto") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Seleziona foto", systemImage: "photo")
                    }
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
                
                Section("Posizione") {
                    if photoLocation != nil {
                        Button("Scegli posizione") {
                            showLocationChoice = true
                        }
                    } else {
                        Button("Usa posizione attuale") {
                            selectedSource = "posizione attuale"
                            showConfirmation = true
                        }
                    }
                    
                    if let location {
                        Text("Lat: \(location.latitude, specifier: "%.5f"), Lon: \(location.longitude, specifier: "%.5f")")
                            .font(.caption)
                        Text("Fonte: \(selectedSource)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Aggiungi luogo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        photoData = data
                        photoLocation = extractLocation(from: data)
                        if photoLocation != nil {
                            showLocationChoice = true
                        }
                    }
                }
            }
            .confirmationDialog("Scegli la posizione", isPresented: $showLocationChoice) {
                Button("Usa posizione attuale") {
                    selectedSource = "posizione attuale"
                    showConfirmation = true
                }
                if let photoLoc = photoLocation {
                    Button("Usa posizione della foto") {
                        location = photoLoc
                        selectedSource = "foto"
                        showConfirmation = true
                    }
                }
                Button("Annulla", role: .cancel) {}
            }
            .alert("Posizione selezionata", isPresented: $showConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Hai scelto di usare la \(selectedSource).")
            }
        }
    }
    
    private func extractLocation(from data: Data) -> CLLocationCoordinate2D? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any],
              let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double else {
            return nil
        }
        
        let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String
        let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String
        
        let latitude = (latRef == "S") ? -lat : lat
        let longitude = (lonRef == "W") ? -lon : lon
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
