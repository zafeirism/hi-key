import SwiftUI

struct StylePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settingsManager = SettingsManager.shared
    
    @State private var newStyleText: String = ""
    @State private var showAddStyle: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                // Built-in styles section
                Section {
                    ForEach(SettingsManager.defaultStyles, id: \.self) { style in
                        StyleRow(
                            style: style,
                            isEnabled: settingsManager.isStyleEnabled(style),
                            onToggle: { settingsManager.toggleStyle(style) }
                        )
                        .listRowBackground(HiTheme.surfacePrimary)
                    }
                } header: {
                    Text("Built-in Styles")
                } footer: {
                    Text("Enable the styles you want to be randomly applied to your images")
                }

                // Custom styles section
                Section {
                    ForEach(settingsManager.customStyles, id: \.self) { style in
                        StyleRow(
                            style: style,
                            isEnabled: settingsManager.isStyleEnabled(style),
                            isCustom: true,
                            onToggle: { settingsManager.toggleStyle(style) },
                            onDelete: { settingsManager.removeCustomStyle(style) }
                        )
                        .listRowBackground(HiTheme.surfacePrimary)
                    }

                    // Add custom style
                    Button {
                        showAddStyle = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(HiTheme.accentPrimary)
                            Text("Add custom style")
                                .foregroundStyle(HiTheme.accentPrimary)
                        }
                    }
                    .listRowBackground(HiTheme.surfacePrimary)
                } header: {
                    Text("Custom Styles")
                }

                // Quick actions section
                Section {
                    Button("Enable All") {
                        settingsManager.enableAllStyles()
                    }
                    .foregroundStyle(HiTheme.accentPrimary)
                    .listRowBackground(HiTheme.surfacePrimary)

                    Button("Disable All") {
                        settingsManager.disableAllStyles()
                    }
                    .foregroundStyle(HiTheme.statusError)
                    .listRowBackground(HiTheme.surfacePrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(HiTheme.backgroundRoot)
            .navigationTitle("Manage Styles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(HiTheme.accentPrimary)
                }
            }
            .alert("Add Custom Style", isPresented: $showAddStyle) {
                TextField("Style name", text: $newStyleText)
                    .textInputAutocapitalization(.words)

                Button("Cancel", role: .cancel) {
                    newStyleText = ""
                }

                Button("Add") {
                    addCustomStyle()
                }
            } message: {
                Text("Enter a custom style that will be applied to your images")
            }
        }
    }
    
    private func addCustomStyle() {
        let trimmed = newStyleText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            settingsManager.addCustomStyle(trimmed)
        }
        newStyleText = ""
    }
}

// MARK: - Style Row

private struct StyleRow: View {
    let style: String
    let isEnabled: Bool
    var isCustom: Bool = false
    let onToggle: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack {
                Text(style)
                    .foregroundStyle(HiTheme.textPrimary)
                Spacer()
                if isEnabled {
                    Image(systemName: "checkmark")
                        .foregroundStyle(HiTheme.accentPrimary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            if isCustom, let delete = onDelete {
                Button(role: .destructive) {
                    delete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    StylePickerView()
}
