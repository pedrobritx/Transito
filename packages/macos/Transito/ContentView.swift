import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @StateObject private var downloadManager = DownloadManager()
    @State private var url: String = ""
    @State private var isDragging = false
    @State private var outputPath: String = ""
    
    var body: some View {
        ZStack {
            // Background glass gradient with vibrancy
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            AngularGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.35),
                    Color.blue.opacity(0.20),
                    Color.purple.opacity(0.20),
                    Color.white.opacity(0.35)
                ]),
                center: .center
            )
            .blur(radius: 40)
            .ignoresSafeArea()

            // Content card with ultraThinMaterial
            VStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text("Transito")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 8)
                    Text("HLS Downloader")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    // URL input with drag-drop support
                    VStack(alignment: .leading, spacing: 6) {
                        Text("M3U8 URL")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            Image(systemName: "link")
                                .foregroundStyle(.secondary)
                            TextField("Paste M3U8 URL or drag here", text: $url)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .onDrop(of: [.url, .text], isTargeted: $isDragging) { providers in
                                    handleDrop(providers: providers)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isDragging ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.12), lineWidth: 1)
                                        .shadow(color: .black.opacity(isDragging ? 0.2 : 0.05), radius: isDragging ? 8 : 4, x: 0, y: 2)
                                )
                        }
                    }

                    // Output path
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Save to")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            Image(systemName: "folder")
                                .foregroundStyle(.secondary)
                            TextField("Output filename", text: $outputPath)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                            Button(action: selectOutputPath) {
                                Label("Choose", systemImage: "ellipsis.circle")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    // Download button
                    Button(action: {
                        Task { await downloadManager.download(url: url, outputPath: outputPath) }
                    }) {
                        HStack(spacing: 8) {
                            if downloadManager.isDownloading { ProgressView().scaleEffect(0.8) }
                            Text(downloadManager.isDownloading ? "Downloading…" : "Download")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(url.isEmpty || downloadManager.isDownloading)

                    // Progress view
                    if downloadManager.isDownloading {
                        VStack(spacing: 10) {
                            ProgressView(value: downloadManager.progress)
                                .tint(.accentColor)
                            Text(downloadManager.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }

                    // Status message
                    if !downloadManager.statusMessage.isEmpty && !downloadManager.isDownloading {
                        Text(downloadManager.statusMessage)
                            .font(.caption)
                            .foregroundColor(downloadManager.isError ? .red : .green)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(20)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 20)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .padding(.top, 36)
        }
        .onAppear { downloadManager.requestNotificationPermission() }
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

// MARK: - VisualEffectView wrapper for NSVisualEffectView
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .appearanceBased
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}
