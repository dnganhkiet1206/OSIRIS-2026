import SwiftUI
import OsirisApplication

/// Global search (M2-3): one field, results grouped by kind. Project hits
/// switch the workspace; deliverable hits open the reader; knowledge and
/// working-context hits show their snippet in place.
struct SearchResultsView: View {
    @Bindable var model: ChatViewModel
    let onNavigateToChat: () -> Void
    /// The query that produced the current results (view state only). Lets us
    /// show a no-results state only after a real search, never while typing.
    @State private var submittedQuery = ""

    var body: some View {
        List {
            Section {
                TextField("Search projects, deliverables, knowledge…", text: $model.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .onSubmit {
                        submittedQuery = model.searchQuery
                        model.runSearch()
                    }
            }
            section(for: .project, title: "Projects")
            section(for: .deliverable, title: "Deliverables")
            section(for: .knowledge, title: "Knowledge")
            section(for: .workingContext, title: "Working notes")
            if showsNoResults {
                // A submitted search that matched nothing — otherwise the area
                // under the field is blank, which reads as broken/loading.
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Nothing matched “\(submittedQuery)”.")
                )
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle("Search")
    }

    /// True only when the field still shows the submitted query and it returned
    /// nothing — so editing the query hides the state until the next search.
    private var showsNoResults: Bool {
        !submittedQuery.isEmpty
            && model.searchQuery == submittedQuery
            && model.searchResults.isEmpty
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
            // M9-2: unified with the reference metadata stack (was 2pt).
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(hit.title).font(.subheadline)
                if !hit.snippet.isEmpty {
                    Text(hit.snippet)
                        .font(.caption)
                        .foregroundStyle(OsirisColor.textSecondary)
                        .lineLimit(2)
                }
            }
        }
    }
}
