import SwiftUI
import MapKit
import PhotosUI

struct PlaceDetailView: View {
    let place: Place
    @State private var showReport = false
    @State private var showAddPhoto = false
    @State private var showMessage = false
    @State private var selectedPhotoIndex: Int?
    @State private var photos: [PlacePhoto] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Mostra foto dalla tabella photos O image_url del luogo
                if !photos.isEmpty {
                    PhotoGalleryView(photos: photos, selectedIndex: $selectedPhotoIndex)
                } else if let imageUrl = place.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Color.gray.opacity(0.3)
                        }
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if let lat = place.latitude, let lon = place.longitude {
                    Map(position: .constant(.region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )))) {
                        Marker(place.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text(place.name)
                    .font(.title)
                    .bold()
                
                if let description = place.description {
                    Text(description)
                }
                
                if let history = place.history {
                    Text(history)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 12) {
                    Button {
                        showAddPhoto = true
                    } label: {
                        Label("Aggiungi foto", systemImage: "photo.badge.plus")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        showMessage = true
                    } label: {
                        Label("Messaggio", systemImage: "message")
                    }
                    .buttonStyle(.bordered)
                }
                
                if !place.analyses.isEmpty {
                    NavigationLink("Vedi analisi") {
                        AnalysisView(analyses: place.analyses)
                    }
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
        .sheet(isPresented: $showAddPhoto) {
            AddPhotoView(placeId: place.id) {
                Task { await loadPhotos() }
            }
        }
        .sheet(isPresented: $showMessage) {
            MessageView(placeId: place.id, placeName: place.name)
        }
        .task {
            await loadPhotos()
        }
    }
    
    func loadPhotos() async {
        photos = (try? await APIClient.shared.fetchPlacePhotos(placeId: place.id)) ?? []
    }
}

struct PlacePhoto: Identifiable, Codable {
    let id: Int
    let url: String
    let userId: Int?
    let username: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, url
        case userId = "user_id"
        case username
        case createdAt = "created_at"
    }
}

struct PhotoGalleryView: View {
    let photos: [PlacePhoto]
    @Binding var selectedIndex: Int?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(photos.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 4) {
                        AsyncImage(url: URL(string: photos[index].url)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Color.gray.opacity(0.3)
                            }
                        }
                        .frame(width: 120, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { selectedIndex = index }
                        
                        if let username = photos[index].username {
                            Text(username)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct AddPhotoView: View {
    let placeId: Int
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let data = photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay {
                                Label("Seleziona foto", systemImage: "photo")
                            }
                    }
                }
                
                if isLoading {
                    ProgressView()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Aggiungi foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Carica") {
                        Task { await upload() }
                    }
                    .disabled(photoData == nil || isLoading)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }
    
    func upload() async {
        guard let data = photoData else { return }
        isLoading = true
        _ = try? await APIClient.shared.uploadPhoto(placeId: placeId, imageData: data)
        isLoading = false
        onComplete()
        dismiss()
    }
}

struct MessageView: View {
    let placeId: Int
    let placeName: String
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Messaggio per il creatore di \(placeName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    TextField("Scrivi il messaggio...", text: $message, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("Messaggio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invia") {
                        Task { await send() }
                    }
                    .disabled(message.isEmpty || isLoading)
                }
            }
            .alert("Messaggio inviato", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            }
        }
    }
    
    func send() async {
        isLoading = true
        try? await APIClient.shared.sendMessage(placeId: placeId, message: message)
        isLoading = false
        showSuccess = true
    }
}
