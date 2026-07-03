import SwiftUI
import OsirisApplication

/// Global search (M2-3): one field, results grouped by kind. Project hits
/// switch the workspace; deliverable hits open the reader; knowledge and
/// working-context hits show their snippet in place.
struct SearchResultsView: View {
    @Bindable var model: ChatViewModel
    let onNavigateToChat: () -> Void

    var body: some View {
        List {
            Section {
                TextField("Search projects, deliverables, knowledge…", text: $model.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .onSubmit { model.runSearch() }
            }
            section(for: .project, title: "Projects")
            section(for: .deliverable, title: "Deliverables")
            section(for: .knowledge, title: "Knowledge")
            section(for: .workingContext, title: "Working notes")
        }
        .navigationTitle("Search")
    }

    @ViewBuilder
    private func section(for kind: SearchHit.Kind, title: String) -> some View {
        let hits = model.searchResults.filter { $0.kind == kind }
        if !hits.isEmpty {
            Section(title) {
                ForEach(hits) { hit in
                    row(for: hit)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for hit: SearchHit) -> some View {
        switch hit.kind {
        case .project:
            Button {
                model.selectProject(id: hit.id)
                onNavigateToChat()
            } label: {
                Label(hit.title, systemImage: "folder")
            }
        case .deliverable:
            Button {
                model.openDeliverable(path: hit.id)
            } label: {
                Label(hit.title, systemImage: "doc.text")
                    .lineLimit(1)
            }
        case .knowledge, .workingContext:
            VStack(alignment: .leading, spacing: 2) {
                Text(hit.title).font(.subheadline)
                if !hit.snippet.isEmpty {
                    Text(hit.snippet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}
