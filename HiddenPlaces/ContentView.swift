import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HiddenPlacesMapView()
                .tabItem {
                    Label("Mappa", systemImage: "map")
                }
            
            CategoriesView()
                .tabItem {
                    Label("Categorie", systemImage: "list.bullet")
                }
            
            MessagesView()
                .tabItem {
                    Label("Messaggi", systemImage: "message")
                }
        }
    }
}
