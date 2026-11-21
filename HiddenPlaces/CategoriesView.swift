import SwiftUI

struct CategoriesView: View {
    @State private var categories: [Category] = []
    
    var body: some View {
        NavigationStack {
            List(categories) { category in
                NavigationLink(category.name) {
                    CategoryPlacesView(category: category)
                }
            }
            .navigationTitle("Categorie")
            .task {
                // categories = try? await APIClient.shared.fetchCategories()
            }
        }
    }
}

struct CategoryPlacesView: View {
    let category: Category
    @State private var places: [Place] = []
    
    var body: some View {
        List(places) { place in
            NavigationLink(place.name) {
                PlaceDetailView(place: place)
            }
        }
        .navigationTitle(category.name)
    }
}
