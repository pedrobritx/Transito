import Foundation
import UserNotifications
import AppKit

@MainActor
class DownloadManager: ObservableObject {
    @Published var isDownloading = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var isError = false
    
    private let ffmpegInstaller = FFmpegInstaller()
    private var downloadTask: Task<Void, Never>?
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func download(url: String, outputPath: String) async {
        guard !url.isEmpty else {
            statusMessage = "Please enter a URL"
            isError = true
            return
        }
        
        // Check/install ffmpeg if needed
        guard await ffmpegInstaller.ensureInstalled() else {
            statusMessage = "ffmpeg installation required"
            isError = true
            return
        }
        
        isDownloading = true
        isError = false
        progress = 0.0
        statusMessage = "Starting download..."
        
        downloadTask = Task {
            do {
                let result = try await performDownload(url: url, outputPath: outputPath)
                
                if !Task.isCancelled {
                    if result.success {
                        statusMessage = "✅ Download completed: \(result.outputPath)"
                        isError = false
                        progress = 1.0
                        sendNotification(title: "Download Complete", 
                                      body: "HLS stream downloaded successfully")
                    } else {
                        statusMessage = "❌ Download failed: \(result.error ?? "Unknown error")"
                        isError = true
                    }
                }
            } catch {
                if !Task.isCancelled {
                    statusMessage = "❌ Download failed: \(error.localizedDescription)"
                    isError = true
                }
            }
            
            isDownloading = false
        }
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        statusMessage = "Download cancelled"
    }
    
    private func performDownload(url: String, outputPath: String) async throws -> DownloadResult {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.runTransitoCLI(url: url, outputPath: outputPath)
                continuation.resume(returning: result)
            }
        }
    }
    
    private func runTransitoCLI(url: String, outputPath: String) -> DownloadResult {
        let process = Process()
        
        // Get the bundled transito CLI tool
        guard let transitoPath = Bundle.main.url(forResource: "transito", withExtension: nil) else {
            return DownloadResult(success: false, outputPath: "", error: "transito CLI tool not found in app bundle")
        }
        
        process.executableURL = transitoPath
        process.arguments = [url, outputPath, "--progress"]
        
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
                while let line = String(data: buffer, encoding: .utf8)?.components(separatedBy: .newlines).first,
                      buffer.count > line.utf8.count {
                    buffer.removeFirst(line.utf8.count + 1)
                    processProgressLine(line)
                }
            }
            
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                return DownloadResult(success: true, outputPath: outputPath, error: nil)
            } else {
                return DownloadResult(success: false, outputPath: "", error: "Process exited with code \(process.terminationStatus)")
            }
            
        } catch {
            return DownloadResult(success: false, outputPath: "", error: error.localizedDescription)
        }
    }
    
    private func processProgressLine(_ line: String) {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedLine.hasPrefix("Progress:") {
            // Extract time from "Progress: 12345ms"
            let components = trimmedLine.components(separatedBy: ":")
            if components.count >= 2 {
                let timeString = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if let timeMs = Int(timeString.replacingOccurrences(of: "ms", with: "")) {
                    // Convert to progress (this is a rough estimate)
                    let progressValue = min(Double(timeMs) / 1000000.0, 1.0) // Assume max 1000 seconds
                    DispatchQueue.main.async {
                        self.progress = progressValue
                        self.statusMessage = "Downloading... \(timeMs)ms"
                    }
                }
            }
        }
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
    let error: String?
}
