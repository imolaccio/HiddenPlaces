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
    
    var body: some View {
        NavigationStack {
            Form {
                Text("Segnala \(type)")
                Button("Invia") {
                    dismiss()
                }
            }
            .navigationTitle("Segnala")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
    }
}

typealias MessagesView = MessagesAndReportView
