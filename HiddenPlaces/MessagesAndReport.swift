import SwiftUI

struct MessagesView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Nessun messaggio")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Messaggi")
        }
    }
}

struct ReportView: View {
    let type: String
    let targetId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var details = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Motivo", text: $reason)
                TextField("Dettagli", text: $details, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("Segnala")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invia") {
                        Task {
                            try? await APIClient.shared.report(type: type, targetId: targetId, reason: reason, details: details)
                            dismiss()
                        }
                    }
                    .disabled(reason.isEmpty)
                }
            }
        }
    }
}

struct AnalysisView: View {
    let analyses: [WaterAnalysis]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Analisi")
                .font(.headline)
            ForEach(analyses) { analysis in
                VStack(alignment: .leading) {
                    if let ph = analysis.ph {
                        Text("pH: \(ph, specifier: "%.1f")")
                    }
                    if let notes = analysis.notes {
                        Text(notes)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
