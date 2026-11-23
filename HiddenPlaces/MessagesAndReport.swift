import SwiftUI

struct MessagesAndReportView: View {
    var body: some View {
        Text("Messaggi")
            .navigationTitle("Messaggi")
    }
}

struct AnalysisView: View {
    let analyses: [WaterAnalysis]
    
    var body: some View {
        List(analyses) { analysis in
            VStack(alignment: .leading) {
                Text(analysis.date ?? "Data non disponibile")
                if let ph = analysis.ph {
                    Text("pH: \(ph, specifier: "%.1f")")
                }
                if let notes = analysis.notes {
                    Text(notes)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Analisi")
    }
}

struct ReportView: View {
    let type: String
    let targetId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var details = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Segnala \(type)")
                        .font(.headline)
                }
                
                Section("Motivo") {
                    TextField("Motivo della segnalazione", text: $reason)
                }
                
                Section("Dettagli (opzionale)") {
                    TextField("Ulteriori dettagli", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Segnala")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invia") {
                        Task { await sendReport() }
                    }
                    .disabled(reason.isEmpty || isLoading)
                }
            }
            .alert("Segnalazione inviata", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    func sendReport() async {
        isLoading = true
        errorMessage = nil
        do {
            try await APIClient.shared.report(type: type, targetId: targetId, reason: reason, details: details)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

typealias MessagesView = MessagesAndReportView
