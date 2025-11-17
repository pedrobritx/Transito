import SwiftUI

/// Preferences/Settings view for Transito
struct PreferencesView: View {
    @AppStorage("autoOpen") private var autoOpen = false
    @AppStorage("defaultOutputPath") private var defaultOutputPath = ""
    
    var body: some View {
        Form {
            Section(header: Text("Download Settings")) {
                Toggle("Auto-open downloads when complete", isOn: $autoOpen)
                
                HStack {
                    TextField("Default output location", text: $defaultOutputPath)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Choose...") {
                        selectDefaultPath()
                    }
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version:")
                    Spacer()
                    Text("0.4.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("ffmpeg:")
                    Spacer()
                    Text(checkFFmpegInstalled() ? "Installed" : "Not Installed")
                        .foregroundColor(checkFFmpegInstalled() ? .green : .red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 300)
    }
    
    private func selectDefaultPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                defaultOutputPath = url.path
            }
        }
    }
    
    private func checkFFmpegInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

#Preview {
    PreferencesView()
}
