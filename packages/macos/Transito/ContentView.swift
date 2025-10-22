import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @StateObject private var downloadManager = DownloadManager()
    @AppStorage("defaultFolder") private var defaultFolderPath: String = ""
    @AppStorage("autoOpenOnComplete") private var autoOpen: Bool = false

    @State private var urlText = ""
    @State private var outputFolder: URL?
    @State private var extractSubtitles = false
    @State private var showAdvanced = false
    @State private var userAgent: String = ""
    @State private var referer: String = ""
    @State private var isDragging = false

    var body: some View {
        ZStack {
            // Liquid glass background with vibrancy
            VisualEffectView(material: .hudWindow, blending: .behindWindow)
                .ignoresSafeArea()

            // Subtle gradient overlay for light reflection
            AngularGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.15),
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.08),
                    Color.white.opacity(0.15)
                ]),
                center: .center
            )
            .blur(radius: 50)
            .ignoresSafeArea()

            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Transito")
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        Text("Paste an HLS URL (.m3u8) to download")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)

                    // Main controls card
                    VStack(spacing: 14) {
                        // URL Input
                        VStack(alignment: .leading, spacing: 6) {
                            Label("M3U8 URL", systemImage: "link.circle")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                TextField("https://example.com/video.m3u8", text: $urlText)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .onDrop(of: [.url, .text], isTargeted: $isDragging) { providers in
                                        handleDrop(providers: providers)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(isDragging ? Color.accentColor.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .disabled(downloadManager.isDownloading)

                                // Paste button
                                Button {
                                    if let pasteboardString = NSPasteboard.general.string(forType: .string) {
                                        urlText = pasteboardString
                                    }
                                } label: {
                                    Image(systemName: "doc.on.clipboard")
                                }
                                .help("Paste from clipboard")

                                // Clear button
                                if !urlText.isEmpty {
                                    Button {
                                        urlText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .help("Clear URL")
                                }
                            }
                        }

                        // Output Folder Selector
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Save to", systemImage: "folder.circle")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                Button(action: chooseOutputFolder) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "folder")
                                        Text(outputFolder?.lastPathComponent ?? "Select folder")
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                .disabled(downloadManager.isDownloading)
                            }
                        }

                        // Subtitles & Advanced Options
                        VStack(spacing: 10) {
                            Toggle("Extract subtitles (.vtt file)", isOn: $extractSubtitles)
                                .help("Save subtitles separately as .vtt (not muxed into MP4)")
                                .disabled(downloadManager.isDownloading)

                            DisclosureGroup("Advanced options", isExpanded: $showAdvanced) {
                                VStack(spacing: 10) {
                                    TextField("User-Agent (optional)", text: $userAgent)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(downloadManager.isDownloading)

                                    TextField("Referer header (optional)", text: $referer)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(downloadManager.isDownloading)
                                }
                                .padding(.top, 8)
                            }
                        }

                        Divider()
                            .opacity(0.3)

                        // Progress
                        if downloadManager.isDownloading {
                            VStack(spacing: 10) {
                                ProgressView(value: downloadManager.progress)
                                    .tint(.accentColor)

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(downloadManager.statusMessage)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        if downloadManager.progress > 0 {
                                            Text("\(Int(downloadManager.progress * 100))%")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }

                                    Spacer()

                                    Button("Stop", role: .destructive) {
                                        downloadManager.cancelDownload()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        // Error Display
                        if let error = downloadManager.errorMessage, !error.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text("Error")
                                        .font(.caption.bold())
                                    Spacer()
                                    Button {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(error, forType: .string)
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .help("Copy error to clipboard")
                                }

                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                            .padding(10)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        }

                        // Status Message (Success)
                        if !downloadManager.statusMessage.isEmpty && !downloadManager.isDownloading && downloadManager.errorMessage == nil {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(downloadManager.statusMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(18)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            .blendMode(.overlay)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 16)
                    .padding(.horizontal, 20)

                    // Download Button
                    Button(action: startDownload) {
                        HStack(spacing: 8) {
                            if downloadManager.isDownloading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(downloadManager.isDownloading ? "Downloading…" : "Download")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(urlText.isEmpty || outputFolder == nil || downloadManager.isDownloading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            downloadManager.requestNotificationPermission()
            if let path = defaultFolderPath, !path.isEmpty {
                outputFolder = URL(fileURLWithPath: path)
            }
            userAgent = UserDefaults.standard.string(forKey: "defaultUA") ?? ""
            referer = UserDefaults.standard.string(forKey: "defaultRef") ?? ""
        }
    }

    private func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Select download folder"

        if panel.runModal() == .OK {
            outputFolder = panel.url
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    DispatchQueue.main.async {
                        urlText = url.absoluteString
                    }
                }
            }
            return true
        } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                if let text = item as? String {
                    DispatchQueue.main.async {
                        urlText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
            return true
        }

        return false
    }

    private func startDownload() {
        Task {
            await downloadManager.download(
                url: urlText,
                outputPath: outputFolder?.path ?? "",
                extractSubtitles: extractSubtitles,
                userAgent: userAgent.isEmpty ? nil : userAgent,
                referer: referer.isEmpty ? nil : referer,
                autoOpen: autoOpen
            )
        }
    }
}

#Preview {
    ContentView()
}
