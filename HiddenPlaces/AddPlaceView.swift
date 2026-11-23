import SwiftUI
import MapKit
import PhotosUI
import ImageIO
import CoreLocation

struct AddPlaceView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var history = ""
    @State private var categories: [Category] = []
    @State private var selectedCategoryId: Int?
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var showMap = false
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showLocationChoice = false
    @State private var photoLatitude: Double?
    @State private var photoLongitude: Double?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informazioni") {
                    TextField("Nome del luogo", text: $name)
                    TextField("Descrizione", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Storia (opzionale)", text: $history, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Categoria") {
                    Picker("Categoria", selection: $selectedCategoryId) {
                        Text("Seleziona").tag(nil as Int?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category.id as Int?)
                        }
                    }
                }
                
                Section("Posizione") {
                    if let lat = latitude, let lon = longitude {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.green)
                            Text(String(format: "%.5f, %.5f", lat, lon))
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        showMap = true
                    } label: {
                        Label(latitude == nil ? "Seleziona sulla mappa" : "Cambia posizione", systemImage: "map")
                    }
                    
                    Button {
                        getCurrentLocation()
                    } label: {
                        Label("Usa posizione attuale", systemImage: "location.fill")
                    }
                }
                
                Section("Foto") {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                        Label("Aggiungi foto (\(photoData.count)/5)", systemImage: "photo.on.rectangle.angled")
                    }
                    
                    if !photoData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(photoData.indices, id: \.self) { index in
                                    if let uiImage = UIImage(data: photoData[index]) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(alignment: .topTrailing) {
                                                Button {
                                                    photoData.remove(at: index)
                                                    if index < selectedPhotos.count {
                                                        selectedPhotos.remove(at: index)
                                                    }
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.white)
                                                        .background(Circle().fill(.black.opacity(0.5)))
                                                }
                                                .offset(x: 4, y: -4)
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Aggiungi luogo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invia") {
                        Task { await submit() }
                    }
                    .disabled(!isValid || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Invio in corso...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .sheet(isPresented: $showMap) {
                LocationPickerView(latitude: $latitude, longitude: $longitude)
            }
            .alert("Posizione trovata nella foto", isPresented: $showLocationChoice) {
                Button("Usa posizione foto") {
                    latitude = photoLatitude
                    longitude = photoLongitude
                }
                Button("Usa posizione attuale") {
                    getCurrentLocation()
                }
                Button("Annulla", role: .cancel) {}
            } message: {
                if let lat = photoLatitude, let lon = photoLongitude {
                    Text(String(format: "Coordinate: %.5f, %.5f", lat, lon))
                }
            }
            .alert("Luogo inviato", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Il luogo sarà visibile dopo l'approvazione.")
            }
            .task {
                categories = (try? await APIClient.shared.fetchCategories()) ?? []
            }
            .onChange(of: selectedPhotos) { _, newValue in
                Task { await loadPhotos(from: newValue) }
            }
        }
    }
    
    var isValid: Bool {
        !name.isEmpty && selectedCategoryId != nil && latitude != nil && longitude != nil
    }
    
    func loadPhotos(from items: [PhotosPickerItem]) async {
        photoData = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photoData.append(data)
                
                if photoLatitude == nil, let coords = extractGPS(from: data) {
                    photoLatitude = coords.latitude
                    photoLongitude = coords.longitude
                    showLocationChoice = true
                }
            }
        }
    }
    
    func extractGPS(from data: Data) -> CLLocationCoordinate2D? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            return nil
        }
        
        guard let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
              let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String else {
            return nil
        }
        
        let latitude = latRef == "S" ? -lat : lat
        let longitude = lonRef == "W" ? -lon : lon
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func getCurrentLocation() {
        latitude = 41.9028
        longitude = 12.4964
    }
    
    func submit() async {
        guard let categoryId = selectedCategoryId,
              let lat = latitude,
              let lon = longitude else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let placeId = try await APIClient.shared.addPlace(
                name: name,
                description: description,
                history: history.isEmpty ? nil : history,
                categoryId: categoryId,
                latitude: lat,
                longitude: lon
            )
            
            for data in photoData {
                _ = try? await APIClient.shared.uploadPhoto(placeId: placeId, imageData: data)
            }
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct LocationPickerView: View {
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLatitude: Double = 41.9028
    @State private var selectedLongitude: Double = 12.4964
    
    var body: some View {
        NavigationStack {
            ZStack {
                if #available(iOS 17.0, *) {
                    MapPickerNew(latitude: $selectedLatitude, longitude: $selectedLongitude)
                } else {
                    MapPickerLegacy(latitude: $selectedLatitude, longitude: $selectedLongitude)
                }
                
                VStack {
                    Spacer()
                    Text("Sposta la mappa per selezionare il centro")
                        .font(.caption)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Seleziona posizione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Conferma") {
                        latitude = selectedLatitude
                        longitude = selectedLongitude
                        dismiss()
                    }
                }
            }
        }
    }
}

@available(iOS 17.0, *)
struct MapPickerNew: View {
    @Binding var latitude: Double
    @Binding var longitude: Double
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
        span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
    ))
    
    var body: some View {
        Map(position: $position) {
            Marker("Centro", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                .tint(.red)
        }
        .onMapCameraChange { context in
            latitude = context.region.center.latitude
            longitude = context.region.center.longitude
        }
    }
}

struct MapPickerLegacy: View {
    @Binding var latitude: Double
    @Binding var longitude: Double
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
        span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [MapPoint(coordinate: region.center)]) { item in
            MapMarker(coordinate: item.coordinate, tint: .red)
        }
        .onChange(of: region.center.latitude) { _, newValue in
            latitude = newValue
        }
        .onChange(of: region.center.longitude) { _, newValue in
            longitude = newValue
        }
    }
}

struct MapPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
