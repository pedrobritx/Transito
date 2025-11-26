import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var downloadManager = DownloadManager()
    @StateObject private var discoveryManager = URLDiscoveryManager()
    
    @State private var url: String = ""
    @State private var isDragging = false
    @State private var outputPath: String = ""
    @State private var showDiscoverySheet = false
    
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
                    Text("URL:")
                        .font(.headline)
                    
                    TextField("Paste M3U8 or Web Page URL", text: $url)
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
                
                // Action buttons
                HStack(spacing: 10) {
                    if downloadManager.isDownloading {
                        Button("Cancel") {
                            downloadManager.cancelDownload()
                        }
                        .buttonStyle(.bordered)
                    } else if discoveryManager.isScanning {
                        ProgressView("Scanning...")
                            .scaleEffect(0.8)
                    } else {
                        Button("Download") {
                            startProcessing()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(url.isEmpty || outputPath.isEmpty)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Progress view
                if downloadManager.isDownloading {
                    VStack(spacing: 10) {
                        ProgressView(value: downloadManager.progress)
                            .transition(.opacity)
                        Text(downloadManager.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    }
                    .animation(.easeInOut, value: downloadManager.isDownloading)
                }
                
                // Status message & Show in Finder
                if !downloadManager.isDownloading {
                    VStack(spacing: 10) {
                        if !downloadManager.statusMessage.isEmpty {
                            Text(downloadManager.statusMessage)
                                .font(.caption)
                                .foregroundColor(downloadManager.isError ? .red : .green)
                                .multilineTextAlignment(.center)
                                .transition(.scale)
                        }
                        
                        if let fileURL = downloadManager.lastDownloadedURL {
                            Button("Show in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                            }
                            .buttonStyle(.link)
                            .transition(.opacity)
                        }
                    }
                    .animation(.spring(), value: downloadManager.lastDownloadedURL)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .padding()
        .frame(width: 600, height: 500)
        .sheet(isPresented: $showDiscoverySheet) {
            URLDiscoveryView(
                urls: discoveryManager.foundURLs,
                onSelect: { selectedURL in
                    showDiscoverySheet = false
                    self.url = selectedURL
                    // Auto start download after selection
                    Task {
                        await downloadManager.download(url: selectedURL, outputPath: outputPath)
                    }
                },
                onCancel: {
                    showDiscoverySheet = false
                }
            )
        }
        .onAppear {
            // Request notification permissions
            downloadManager.requestNotificationPermission()
            
            // Set default output path if empty
            if outputPath.isEmpty {
                let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                outputPath = downloads.appendingPathComponent("video.mp4").path
            }
        }
    }
    
    private func startProcessing() {
        guard !url.isEmpty else { return }
        
        // If it's already an m3u8, download directly
        if url.lowercased().contains(".m3u8") {
            Task {
                await downloadManager.download(url: url, outputPath: outputPath)
            }
            return
        }
        
        // Otherwise, try to discover
        Task {
            do {
                let urls = try await discoveryManager.findM3U8Links(in: url)
                if urls.isEmpty {
                    downloadManager.errorMessage = "No video streams found"
                    downloadManager.statusMessage = "No video streams found"
                } else if urls.count == 1 {
                    // Found exactly one, just download it
                    self.url = urls[0]
                    await downloadManager.download(url: urls[0], outputPath: outputPath)
                } else {
                    // Found multiple, show selection
                    showDiscoverySheet = true
                }
            } catch {
                downloadManager.errorMessage = error.localizedDescription
                downloadManager.statusMessage = "Scanning failed: \(error.localizedDescription)"
            }
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
        let panel = NSSavePanel()
        panel.title = "Save Video"
        panel.nameFieldStringValue = "video.mp4"
        panel.allowedContentTypes = [UTType.mpeg4Movie, UTType.movie]
        
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
