import Foundation
import UserNotifications
import AppKit

@MainActor
class DownloadManager: ObservableObject {
    @Published var isDownloading = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var errorMessage: String? = nil
    @Published var lastDownloadedURL: URL? = nil
    
    private let ffmpegInstaller: FFmpegInstaller
    private var downloadTask: Task<Void, Never>?
    
    init(ffmpegInstaller: FFmpegInstaller = FFmpegInstaller()) {
        self.ffmpegInstaller = ffmpegInstaller
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func download(
        url: String,
        outputPath: String,
        extractSubtitles: Bool = false,
        userAgent: String? = nil,
        referer: String? = nil,
        autoOpen: Bool = false
    ) async {
        guard !url.isEmpty else {
            errorMessage = "Please enter a URL"
            return
        }
        
        guard !outputPath.isEmpty else {
            errorMessage = "Please select an output folder"
            return
        }
        
        // Check/install ffmpeg if needed
        guard await ffmpegInstaller.ensureInstalled() else {
            errorMessage = "ffmpeg installation required"
            return
        }
        
        isDownloading = true
        errorMessage = nil
        progress = 0.0
        statusMessage = "Starting download..."
        lastDownloadedURL = nil
        
        downloadTask = Task {
            do {
                let result = try await performDownload(
                    url: url,
                    outputPath: outputPath,
                    extractSubtitles: extractSubtitles,
                    userAgent: userAgent,
                    referer: referer
                )
                
                if !Task.isCancelled {
                    if result.success {
                        statusMessage = "✅ Download completed!"
                        errorMessage = nil
                        progress = 1.0
                        lastDownloadedURL = result.outputURL
                        
                        // Open file if autoOpen is enabled
                        if autoOpen, let outputURL = result.outputURL {
                            NSWorkspace.shared.open(outputURL)
                        }
                        
                        sendNotification(
                            title: "Download Complete",
                            body: "HLS stream downloaded successfully"
                        )
                    } else {
                        statusMessage = "Download failed"
                        errorMessage = result.error ?? "Unknown error"
                        sendNotification(
                            title: "Download Failed",
                            body: result.error ?? "Unknown error"
                        )
                    }
                }
            } catch {
                if !Task.isCancelled {
                    statusMessage = "Download failed"
                    errorMessage = error.localizedDescription
                    sendNotification(
                        title: "Download Failed",
                        body: error.localizedDescription
                    )
                }
            }
            
            isDownloading = false
        }
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        statusMessage = "Download cancelled"
        errorMessage = nil
    }
    
    private func performDownload(
        url: String,
        outputPath: String,
        extractSubtitles: Bool,
        userAgent: String?,
        referer: String?
    ) async throws -> DownloadResult {
        // Use native Swift HLS engine
        // outputPath is now the full path to the file, not just the directory
        
        return try await HLSEngine.download(
            url: url,
            outputPath: outputPath,
            extractSubtitles: extractSubtitles,
            userAgent: userAgent,
            referer: referer,
            progressHandler: { [weak self] progress, message in
                Task { @MainActor in
                    self?.progress = progress
                    self?.statusMessage = message
                }
            }
        )
    }

    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}

struct DownloadResult {
    let success: Bool
    let outputPath: String
    let outputURL: URL?
    let error: String?
}
