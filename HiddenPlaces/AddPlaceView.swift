import SwiftUI

struct AddPlaceView: View {
    @State private var name = ""
    @State private var description = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            TextField("Nome", text: $name)
            TextField("Descrizione", text: $description, axis: .vertical)
            
            Button("Salva") {
                dismiss()
            }
            .disabled(name.isEmpty)
        }
        .navigationTitle("Aggiungi luogo")
    }
}
