import SwiftUI
import MapKit
import CoreLocation

struct HiddenPlacesMapView: View {
    @State private var places: [Place] = []
    @State private var categories: [Category] = []
    @State private var selectedCategoryId: Int?
    @State private var position: MapCameraPosition = .automatic
    @State private var isLoading = true
    @State private var selectedPlace: Place?
    @State private var showFilters = false
    @StateObject private var locationManager = LocationManager()
    
    var filteredPlaces: [Place] {
        if let categoryId = selectedCategoryId {
            return places.filter { $0.categoryId == categoryId }
        }
        return places
    }
    
    var body: some View {
        ZStack {
            Map(position: $position) {
                ForEach(filteredPlaces) { place in
                    if let lat = place.latitude, let lon = place.longitude {
                        let category = categories.first { $0.id == place.categoryId }
                        let iconName = (category?.iconName.isEmpty == false && category?.iconName != "mappin") 
                            ? category!.iconName 
                            : iconForCategory(place.categoryId)
                        
                        Annotation(place.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            Button {
                                selectedPlace = place
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(colorForCategory(place.categoryId))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: iconName)
                                        .foregroundStyle(.white)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                        }
                    }
                }
                
                UserAnnotation()
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .ignoresSafeArea(edges: .bottom)
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 8)
                }
                .padding(.top, 8)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button {
                        zoomToCurrentLocation()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                if isLoading {
                    ProgressView("Caricamento...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Mappa")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFilters) {
            FilterSheet(
                categories: categories,
                selectedCategoryId: $selectedCategoryId
            )
        }
        .sheet(item: $selectedPlace) { place in
            NavigationStack {
                PlaceDetailView(place: place)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Chiudi") { selectedPlace = nil }
                        }
                    }
            }
        }
        .task {
            await loadData()
            locationManager.requestPermission()
        }
    }
    
    func zoomToCurrentLocation() {
        guard let location = locationManager.location else {
            locationManager.requestPermission()
            return
        }
        position = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    func loadData() async {
        do {
            async let placesTask = APIClient.shared.fetchPlaces()
            async let categoriesTask = APIClient.shared.fetchCategories()
            
            places = try await placesTask
            categories = try await categoriesTask
            
            if let first = places.first, let lat = first.latitude, let lon = first.longitude {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
                ))
            }
        } catch {
            print("Errore: \(error)")
        }
        isLoading = false
    }
    
    func colorForCategory(_ categoryId: Int?) -> Color {
        guard let id = categoryId else { return .blue }
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .cyan, .pink, .yellow, .indigo, .mint]
        return colors[id % colors.count]
    }
    
    func iconForCategory(_ categoryId: Int?) -> String {
        switch categoryId {
        case 1: return "drop.fill"
        case 2: return "water.waves"
        case 3: return "mountain.2.fill"
        case 4: return "tree.fill"
        case 5: return "building.columns"
        case 6: return "fossil.shell.fill"
        case 7: return "building.2.fill"
        case 8: return "party.popper.fill"
        case 9: return "house.fill"
        case 10: return "ghost.fill"
        default: return "mappin"
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
}

struct FilterSheet: View {
    let categories: [Category]
    @Binding var selectedCategoryId: Int?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedCategoryId = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 28)
                        Text("Tutte le categorie")
                        Spacer()
                        if selectedCategoryId == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                ForEach(categories) { category in
                    Button {
                        selectedCategoryId = category.id
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: iconForCategory(category.id))
                                .foregroundStyle(colorForCategory(category.id))
                                .frame(width: 28)
                            Text(category.name)
                            Spacer()
                            if selectedCategoryId == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filtra per categoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    func colorForCategory(_ categoryId: Int?) -> Color {
        guard let id = categoryId else { return .blue }
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .cyan, .pink, .yellow, .indigo, .mint]
        return colors[id % colors.count]
    }
    
    func iconForCategory(_ categoryId: Int?) -> String {
        switch categoryId {
        case 1: return "drop.fill"
        case 2: return "water.waves"
        case 3: return "mountain.2.fill"
        case 4: return "tree.fill"
        case 5: return "building.columns"
        case 6: return "fossil.shell.fill"
        case 7: return "building.2.fill"
        case 8: return "party.popper.fill"
        case 9: return "house.fill"
        case 10: return "ghost.fill"
        case 11: return "binoculars.fill"
        case 12: return "leaf.fill"
        default: return "mappin"
        }
    }
}
