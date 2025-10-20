import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var downloadManager = DownloadManager()
    @State private var url: String = ""
    @State private var isDragging = false
    @State private var outputPath: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Transito")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("HLS Downloader")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                // URL input with drag-drop support
                VStack(alignment: .leading, spacing: 5) {
                    Text("M3U8 URL:")
                        .font(.headline)
                    
                    TextField("Paste M3U8 URL or drag here", text: $url)
                        .textFieldStyle(.roundedBorder)
                        .onDrop(of: [.url, .text], isTargeted: $isDragging) { providers in
                            handleDrop(providers: providers)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isDragging ? Color.blue : Color.clear, lineWidth: 2)
                        )
                }
                
                // Output path
                VStack(alignment: .leading, spacing: 5) {
                    Text("Save to:")
                        .font(.headline)
                    
                    HStack {
                        TextField("Output filename", text: $outputPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Choose...") {
                            selectOutputPath()
                        }
                    }
                }
                
                // Download button
                Button(action: {
                    Task {
                        await downloadManager.download(url: url, outputPath: outputPath)
                    }
                }) {
                    HStack {
                        if downloadManager.isDownloading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(downloadManager.isDownloading ? "Downloading..." : "Download")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty || downloadManager.isDownloading)
                
                // Progress view
                if downloadManager.isDownloading {
                    VStack(spacing: 10) {
                        ProgressView(value: downloadManager.progress)
                        Text(downloadManager.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Status message
                if !downloadManager.statusMessage.isEmpty && !downloadManager.isDownloading {
                    Text(downloadManager.statusMessage)
                        .font(.caption)
                        .foregroundColor(downloadManager.isError ? .red : .green)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .padding()
        .frame(width: 600, height: 500)
        .onAppear {
            // Request notification permissions
            downloadManager.requestNotificationPermission()
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                if let url = item as? URL {
                    DispatchQueue.main.async {
                        self.url = url.absoluteString
                    }
                }
            }
            return true
        } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
                if let text = item as? String {
                    DispatchQueue.main.async {
                        self.url = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
            return true
        }
        
        return false
    }
    
    private func selectOutputPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.mpeg4Movie, UTType.movie]
        panel.nameFieldStringValue = "video.mp4"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                outputPath = url.path
            }
        }
    }
}

#Preview {
    ContentView()
}
