import SwiftUI

struct HomeView: View {
    @State private var photos: [String] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                MultiLayerTiles(photos: photos)
                
                VStack {
                    Text("HiddenPlaces")
                        .font(.title)
                        .bold()
                        .foregroundStyle(.white)
                        .padding(.top, 70)
                        .shadow(radius: 8)
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
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
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .task {
                await loadPhotos()
            }
        }
    }
    
    func loadPhotos() async {
        do {
            let result = try await APIClient.shared.fetchPhotos()
            photos = result.isEmpty ? samplePhotos() : result.map { $0.url }
        } catch {
            photos = samplePhotos()
        }
    }
    
    func samplePhotos() -> [String] {
        (1...15).map { "https://picsum.photos/400/300?\($0)" }
    }
}

struct MultiLayerTiles: View {
    let photos: [String]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LayerRow(photos: photos, speed: 12, direction: .right, yOffset: -geo.size.height * 0.25, tileSize: CGSize(width: 90, height: 65))
                    .opacity(0.65)
                
                LayerRow(photos: photos.shuffled(), speed: 20, direction: .left, yOffset: -geo.size.height * 0.05, tileSize: CGSize(width: 140, height: 100))
                    .opacity(0.8)
                
                LayerRow(photos: photos, speed: 28, direction: .right, yOffset: geo.size.height * 0.1, tileSize: CGSize(width: 180, height: 130))
                
                LayerRow(photos: photos.reversed(), speed: 16, direction: .left, yOffset: geo.size.height * 0.25, tileSize: CGSize(width: 110, height: 80))
                    .opacity(0.85)
                
                LayerRow(photos: photos.shuffled(), speed: 10, direction: .right, yOffset: geo.size.height * 0.4, tileSize: CGSize(width: 100, height: 70))
                    .opacity(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }
}

struct LayerRow: View {
    let photos: [String]
    let speed: Double
    let direction: Direction
    let yOffset: CGFloat
    let tileSize: CGSize
    
    enum Direction { case left, right }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let offset = t * speed * (direction == .right ? 1 : -1)
            
            HStack(spacing: 6) {
                ForEach(0..<8, id: \.self) { _ in
                    ForEach(photos.prefix(5), id: \.self) { url in
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Color.gray.opacity(0.3)
                            }
                        }
                        .frame(width: tileSize.width, height: tileSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .offset(x: CGFloat(offset.truncatingRemainder(dividingBy: 2000)), y: yOffset)
        }
    }
}
