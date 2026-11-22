import SwiftUI

struct CategoriesView: View {
    @State private var categories: [Category] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
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
                        NavigationLink(category.name) {
                            Text("Luoghi in \(category.name)")
                        }
                    }
                }
            }
            .navigationTitle("Categorie")
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
}
