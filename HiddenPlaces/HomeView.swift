import SwiftUI

struct HomeView: View {
    @State private var photos: [String] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollingTilesView(photos: photos)
                
                VStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        NavigationLink {
                            HiddenPlacesMapView()
                        } label: {
                            Label("Mappa", systemImage: "map")
                        }
                        .buttonStyle(.borderedProminent)
                        
                        NavigationLink {
                            CategoriesView()
                        } label: {
                            Label("Categorie", systemImage: "square.grid.2x2")
                        }
                        .buttonStyle(.borderedProminent)
                        
                        NavigationLink {
                            AddPlaceView()
                        } label: {
                            Label("Aggiungi", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("HiddenPlaces")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadPhotos()
            }
        }
    }
    
    func loadPhotos() async {
        do {
            let url = URL(string: "https://imolaccio.it/sourcedrop/api/photos.php")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode([PhotoItem].self, from: data)
            photos = result.map { $0.url }
        } catch {
            // Fallback se non ci sono foto
            photos = [
                "https://picsum.photos/400/300?1",
                "https://picsum.photos/400/300?2",
                "https://picsum.photos/400/300?3"
            ]
        }
    }
}

struct PhotoItem: Codable {
    let url: String
}

struct ScrollingTilesView: View {
    let photos: [String]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ScrollingRow(photos: photos, speed: 25, direction: .right)
                    .frame(height: 140)
                    .offset(y: -geo.size.height * 0.25)
                
                ScrollingRow(photos: photos.reversed(), speed: 18, direction: .left)
                    .frame(height: 140)
                
                ScrollingRow(photos: photos, speed: 12, direction: .right)
                    .frame(height: 140)
                    .offset(y: geo.size.height * 0.25)
            }
        }
        .ignoresSafeArea()
    }
}

struct ScrollingRow: View {
    let photos: [String]
    let speed: Double
    let direction: Direction
    
    enum Direction { case left, right }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let offset = t * speed * (direction == .right ? 1 : -1)
            
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    ForEach(photos, id: \.self) { url in
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Color.gray.opacity(0.2)
                            }
                        }
                        .frame(width: 160, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .offset(x: CGFloat(offset.truncatingRemainder(dividingBy: 1800)))
        }
    }
}
