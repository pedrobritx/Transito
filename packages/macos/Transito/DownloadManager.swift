import Foundation
import UserNotifications
import AppKit

@MainActor
class DownloadManager: ObservableObject {
    @Published var isDownloading = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var errorMessage: String? = nil
    
    private let ffmpegInstaller = FFmpegInstaller()
    private var downloadTask: Task<Void, Never>?
    
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
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.runTransitoCLI(
                    url: url,
                    outputPath: outputPath,
                    extractSubtitles: extractSubtitles,
                    userAgent: userAgent,
                    referer: referer
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    private func runTransitoCLI(
        url: String,
        outputPath: String,
        extractSubtitles: Bool,
        userAgent: String?,
        referer: String?
    ) -> DownloadResult {
        let process = Process()
        
        // Get the bundled transito CLI tool
        guard let transitoPath = Bundle.main.url(forResource: "transito", withExtension: nil) else {
            return DownloadResult(
                success: false,
                outputPath: "",
                outputURL: nil,
                error: "transito CLI tool not found in app bundle"
            )
        }
        
        var arguments: [String] = [url]
        
        // Determine output file path (MP4)
        let outputMP4 = outputPath.hasSuffix("/") ?
            outputPath + "video.mp4" :
            outputPath + "/video.mp4"
        arguments.append(outputMP4)
        
        // Add optional headers
        if let ua = userAgent {
            arguments.append("--user-agent")
            arguments.append(ua)
        }
        if let ref = referer {
            arguments.append("--referer")
            arguments.append(ref)
        }
        
        // Add subtitle extraction if enabled
        if extractSubtitles {
            arguments.append("--extract-subtitles")
        }
        
        process.executableURL = transitoPath
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            
            // Read output line by line to parse progress
            let fileHandle = pipe.fileHandleForReading
            var buffer = Data()
            
            while process.isRunning {
                let data = fileHandle.availableData
                if data.isEmpty { break }
                
                buffer.append(data)
                
                // Process complete lines
                while let lineRange = buffer.range(of: Data("\n".utf8)) {
                    let lineData = buffer.subdata(in: 0..<lineRange.lowerBound)
                    if let line = String(data: lineData, encoding: .utf8) {
                        processProgressLine(line)
                    }
                    buffer.removeFirst(lineRange.upperBound)
                }
                
                usleep(100_000) // 100ms
            }
            
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let outputURL = URL(fileURLWithPath: outputMP4)
                return DownloadResult(
                    success: true,
                    outputPath: outputMP4,
                    outputURL: outputURL,
                    error: nil
                )
            } else {
                return DownloadResult(
                    success: false,
                    outputPath: "",
                    outputURL: nil,
                    error: "Process exited with code \(process.terminationStatus)"
                )
            }
            
        } catch {
            return DownloadResult(
                success: false,
                outputPath: "",
                outputURL: nil,
                error: error.localizedDescription
            )
        }
    }
    
    private func processProgressLine(_ line: String) {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedLine.hasPrefix("Progress:") {
            let components = trimmedLine.components(separatedBy: ":")
            if components.count >= 2 {
                let timeString = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if let timeMs = Int(timeString.replacingOccurrences(of: "ms", with: "")) {
                    let progressValue = min(Double(timeMs) / 1000000.0, 1.0)
                    DispatchQueue.main.async {
                        self.progress = progressValue
                        self.statusMessage = "Downloading… \(self.formatBytes(timeMs))"
                    }
                }
            }
        } else if trimmedLine.contains("Downloaded") {
            DispatchQueue.main.async {
                self.statusMessage = trimmedLine
                self.progress = 1.0
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .decimal
        return formatter.string(fromByteCount: Int64(bytes))
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
