import SwiftUI

struct CategoriesView: View {
    @State private var categories: [Category] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showRequestCategory = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Caricamento...")
                } else if let errorMessage {
                    ContentUnavailableView("Errore", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else if categories.isEmpty {
                    ContentUnavailableView("Nessuna categoria", systemImage: "folder")
                } else {
                    List(categories) { category in
                        NavigationLink {
                            PlacesListView(category: category)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: iconForCategory(category.id))
                                    .foregroundStyle(colorForCategory(category.id))
                                    .frame(width: 32, height: 32)
                                    .background(colorForCategory(category.id).opacity(0.15))
                                    .clipShape(Circle())
                                
                                Text(category.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Categorie")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showRequestCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showRequestCategory) {
                CategoryRequestView()
            }
            .task {
                do {
                    categories = try await APIClient.shared.fetchCategories()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
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

struct PlacesListView: View {
    let category: Category
    @State private var places: [Place] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                ContentUnavailableView("Errore", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
            } else if places.isEmpty {
                ContentUnavailableView("Nessun luogo", systemImage: "mappin.slash", description: Text("Nessun luogo in questa categoria"))
            } else {
                List(places) { place in
                    NavigationLink {
                        PlaceDetailView(place: place)
                    } label: {
                        HStack(spacing: 12) {
                            if let url = place.thumbnailUrl, let imageURL = URL(string: url) {
                                AsyncImage(url: imageURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    default:
                                        Color.gray.opacity(0.3)
                                    }
                                }
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 70, height: 70)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .foregroundStyle(.gray)
                                    }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name)
                                    .font(.headline)
                                if let desc = place.description {
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(category.name)
        .task {
            do {
                places = try await APIClient.shared.fetchPlaces(categoryId: category.id)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
