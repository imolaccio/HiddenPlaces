import SwiftUI

struct CategoryRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var categoryName = ""
    @State private var reason = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome della categoria", text: $categoryName)
                } header: {
                    Text("Nuova categoria")
                } footer: {
                    Text("Proponi una nuova categoria per i luoghi")
                }
                
                Section {
                    TextField("Perché serve questa categoria?", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Motivazione")
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Proponi categoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invia") {
                        Task { await submit() }
                    }
                    .disabled(categoryName.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Invio...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Richiesta inviata", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("La tua proposta sarà valutata.")
            }
        }
    }
    
    func submit() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await APIClient.shared.requestCategory(name: categoryName, reason: reason)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
