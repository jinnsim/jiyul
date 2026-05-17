import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var settings: Settings?
    @State private var nameDraft: String = ""
    @State private var showResetConfirm = false

    var body: some View {
        Form {
            if let settings {
                Section(String(localized: "Settings.Language")) {
                    Picker(String(localized: "Settings.Language"),
                           selection: Binding(
                            get: { AppLanguage(rawValue: settings.languageOverride ?? "system") ?? .system },
                            set: { newValue in
                                try? store().update { $0.languageOverride = newValue == .system ? nil : newValue.rawValue }
                                self.settings = try? store().current()
                            })) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                }
                Section(String(localized: "Settings.Sound")) {
                    Toggle(String(localized: "Settings.Sound"),
                           isOn: Binding(
                            get: { settings.soundEnabled },
                            set: { newValue in
                                try? store().update { $0.soundEnabled = newValue }
                                SoundService.shared.setEnabled(newValue)
                                self.settings = try? store().current()
                            }))
                }
                Section(String(localized: "Settings.PlayerName")) {
                    TextField(String(localized: "Settings.PlayerName"), text: $nameDraft)
                        .onSubmit {
                            let trimmed = nameDraft.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            try? store().update { $0.playerName = trimmed }
                            self.settings = try? store().current()
                        }
                }
                Section(String(localized: "Settings.OtherApps")) {
                    Link(destination: URL(string: "https://apps.apple.com/app/id6765893581")!) {
                        HStack {
                            Text("Nomori").foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text(String(localized: "Settings.ResetData"))
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "Settings.Title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            settings = try? store().current()
            nameDraft = settings?.playerName ?? "지율"
        }
        .alert(String(localized: "Settings.ResetConfirm"),
               isPresented: $showResetConfirm) {
            Button(String(localized: "Action.Cancel"), role: .cancel) { }
            Button(String(localized: "Action.Delete"), role: .destructive) {
                try? store().resetAllData()
            }
        }
    }

    private func store() -> SettingsStore { SettingsStore(modelContext: modelContext) }
}
