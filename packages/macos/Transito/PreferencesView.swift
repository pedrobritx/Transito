import SwiftUI
import AppKit

struct PreferencesView: View {
    @AppStorage("defaultFolder") private var defaultFolderPath: String = ""
    @AppStorage("defaultUA") private var defaultUA: String = ""
    @AppStorage("defaultRef") private var defaultRef: String = ""
    @AppStorage("autoOpenOnComplete") private var autoOpen: Bool = false

    var body: some View {
        TabView {
            Form {
                Section(header: Text("Output")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Default Folder")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(defaultFolderPath.isEmpty ? "Not set" : defaultFolderPath)
                                .font(.callout)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button(action: chooseDefaultFolder) {
                            Label("Choose", systemImage: "folder")
                        }
                    }

                    Toggle("Open file on completion", isOn: $autoOpen)
                }

                Section(header: Text("Network")) {
                    TextField("User-Agent (optional)", text: $defaultUA)
                    TextField("Referer (optional)", text: $defaultRef)
                }
            }
            .tabItem {
                Label("Output", systemImage: "square.and.arrow.down")
            }
        }
        .padding()
    }

    private func chooseDefaultFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Select default download folder"

        if panel.runModal() == .OK, let url = panel.url {
            defaultFolderPath = url.path
        }
    }
}

#Preview {
    PreferencesView()
}
