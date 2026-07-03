import SwiftUI
import OsirisApplication

/// The application IS this screen: a simple sidebar, the conversation in
/// the center, the composer at the bottom. Minimal by design — Dashboard
/// and richer Settings attach to the sidebar in M2 (where this root view
/// gets restructured properly).
struct ChatView: View {
    private enum SidebarItem: Hashable {
        case chat, search, dashboard, advanced, project(String), settings
    }

    @State private var model: ChatViewModel
    @State private var selection: SidebarItem? = .chat
    @State private var isNamingProject = false
    @State private var newProjectName = ""
    /// UI preference only (AD-40) — never platform data.
    @AppStorage("osiris.advancedMode") private var advancedMode = false
    private let settings: ProviderSettings

    init(model: ChatViewModel, settings: ProviderSettings) {
        _model = State(initialValue: model)
        self.settings = settings
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Chat", systemImage: "bubble.left.and.text.bubble.right")
                    .tag(SidebarItem.chat)
                Label("Search", systemImage: "magnifyingglass")
                    .tag(SidebarItem.search)
                Label("Dashboard", systemImage: "gauge.with.needle")
                    .tag(SidebarItem.dashboard)
                Section("Projects") {
                    ForEach(model.projects) { project in
                        Label(project.name, systemImage: "folder")
                            .tag(SidebarItem.project(project.id))
                    }
                    Button {
                        isNamingProject = true
                    } label: {
                        Label("New Project", systemImage: "plus")
                    }
                }
                if advancedMode {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                        .tag(SidebarItem.advanced)
                }
                Label("Settings", systemImage: "gearshape")
                    .tag(SidebarItem.settings)
            }
            .navigationTitle("OSIRIS")
        } detail: {
            switch selection {
            case .settings:
                SettingsView(settings: settings)
            case .search:
                SearchResultsView(model: model) { selection = .chat }
            case .dashboard:
                DashboardView(model: model)
            case .advanced:
                AdvancedView(model: model)
            default:
                VStack(spacing: 0) {
                    transcript
                    statusBar
                    composer
                }
            }
        }
        .task { model.loadProjects() }
        .onChange(of: selection) { _, newValue in
            if case .project(let id) = newValue {
                model.selectProject(id: id)
            }
        }
        .alert("New Project", isPresented: $isNamingProject) {
            TextField("Name", text: $newProjectName)
            Button("Create") {
                model.createProject(named: newProjectName)
                newProjectName = ""
                selection = .chat
            }
            Button("Cancel", role: .cancel) { newProjectName = "" }
        }
    }

    private var transcript: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if model.messages.isEmpty {
                    if let overview = model.overview, !overview.isEmpty {
                        ProjectResumeView(overview: overview) { path in
                            model.openDeliverable(path: path)
                        }
                    } else {
                        emptyState
                    }
                }
                ForEach(model.messages) { message in
                    MessageRow(message: message)
                }
            }
            .padding()
        }
        .defaultScrollAnchor(.bottom)
        .sheet(item: Binding(
            get: { model.openedDeliverable },
            set: { model.openedDeliverable = $0 }
        )) { deliverable in
            NavigationStack {
                ScrollView {
                    Text(deliverable.content)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .navigationTitle("Deliverable")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("What do you want to accomplish?")
                .font(.title3)
                .fontWeight(.medium)
            Text("Describe a goal. OSIRIS handles the rest.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    @ViewBuilder
    private var statusBar: some View {
        if case .running(let activity) = model.phase {
            ExecutionStatusView(activity: activity)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Describe a goal…", text: $model.draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .onSubmit { model.send() }
            Button {
                model.send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .accessibilityLabel("Send goal")
            .disabled(model.draft.trimmingCharacters(in: .whitespaces).isEmpty || model.isWorking)
        }
        .padding()
    }
}

private struct MessageRow: View {
    let message: ChatViewModel.Message

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.role == .user
                        ? AnyShapeStyle(Color.accentColor.opacity(0.15))
                        : AnyShapeStyle(.quaternary.opacity(0.5)),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            if message.role == .osiris { Spacer(minLength: 40) }
        }
    }
}
