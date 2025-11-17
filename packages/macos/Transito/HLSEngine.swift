import Foundation

enum HLSEngineError: Error {
    case ffmpegNotFound
    case invalidURL
    case downloadFailed(String)
}

struct HLSEngine {
    typealias ProgressHandler = (Double, String) -> Void
    
    static func download(
        url: String,
        outputPath: String,
        extractSubtitles: Bool = false,
        userAgent: String? = nil,
        referer: String? = nil,
        progressHandler: ProgressHandler? = nil
    ) async throws -> DownloadResult {
        // Validate URL
        guard URL(string: url) != nil else {
            throw HLSEngineError.invalidURL
        }
        
        // Check if ffmpeg is available
        guard let ffmpegPath = findFFmpeg() else {
            throw HLSEngineError.ffmpegNotFound
        }
        
        // Create output directory if needed
        let outputURL = URL(fileURLWithPath: outputPath)
        let outputDir = outputURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        // Build ffmpeg command
        var arguments = [
            "-hide_banner",
            "-loglevel", "warning",
            "-nostdin",
            "-reconnect", "1",
            "-reconnect_streamed", "1",
            "-reconnect_delay_max", "30"
        ]
        
        // Add custom headers if provided
        if let userAgent = userAgent, let referer = referer {
            let headers = "User-Agent: \(userAgent)\r\nReferer: \(referer)\r\n"
            arguments.append(contentsOf: ["-headers", headers])
        } else if let userAgent = userAgent {
            let headers = "User-Agent: \(userAgent)\r\n"
            arguments.append(contentsOf: ["-headers", headers])
        } else if let referer = referer {
            let headers = "Referer: \(referer)\r\n"
            arguments.append(contentsOf: ["-headers", headers])
        }
        
        // Add input and output options
        arguments.append(contentsOf: [
            "-i", url,
            "-map", "0",
            "-c", "copy",
            "-bsf:a", "aac_adtstoasc",
            "-movflags", "+faststart"
        ])
        
        // Add progress reporting
        arguments.append(contentsOf: ["-progress", "pipe:1"])
        
        arguments.append(outputPath)
        
        // Execute ffmpeg
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        var totalDuration: Double = 0
        var currentTime: Double = 0
        
        // Read progress in background
        let progressTask = Task {
            for try await line in outputPipe.fileHandleForReading.bytes.lines {
                if line.hasPrefix("out_time_ms=") {
                    if let timeString = line.components(separatedBy: "=").last,
                       let timeMs = Double(timeString) {
                        currentTime = timeMs / 1_000_000.0 // Convert to seconds
                        
                        if totalDuration > 0 {
                            let progress = min(currentTime / totalDuration, 1.0)
                            let message = String(format: "Downloading: %.0f%%", progress * 100)
                            progressHandler?(progress, message)
                        } else {
                            let message = String(format: "Downloading: %.0fs", currentTime)
                            progressHandler?(0.0, message)
                        }
                    }
                } else if line.hasPrefix("duration=") {
                    if let durationString = line.components(separatedBy: "=").last,
                       let durationMs = Double(durationString) {
                        totalDuration = durationMs / 1_000_000.0
                    }
                }
            }
        }
        
        // Read errors in background
        let errorTask = Task {
            var errorOutput = ""
            for try await line in errorPipe.fileHandleForReading.bytes.lines {
                errorOutput += line + "\n"
            }
            return errorOutput
        }
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Wait for background tasks to complete
            await progressTask.value
            let errorOutput = await errorTask.value
            
            let exitCode = process.terminationStatus
            
            if exitCode == 0 {
                progressHandler?(1.0, "Download completed!")
                return DownloadResult(
                    success: true,
                    outputPath: outputPath,
                    outputURL: URL(fileURLWithPath: outputPath),
                    error: nil
                )
            } else {
                let errorMessage = errorOutput.isEmpty ? "ffmpeg exited with code \(exitCode)" : errorOutput
                throw HLSEngineError.downloadFailed(errorMessage)
            }
        } catch let error as HLSEngineError {
            throw error
        } catch {
            throw HLSEngineError.downloadFailed(error.localizedDescription)
        }
    }
    
    private static func findFFmpeg() -> String? {
        // Check common locations
        let paths = [
            "/usr/local/bin/ffmpeg",
            "/opt/homebrew/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Check in Application Support directory (downloaded by FFmpegInstaller)
        if let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let transitoDir = appSupportDir.appendingPathComponent("Transito")
            let ffmpegPath = transitoDir.appendingPathComponent("ffmpeg").path
            if FileManager.default.fileExists(atPath: ffmpegPath) {
                return ffmpegPath
            }
        }
        
        // Try to find in PATH
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            return nil
        }
        
        return nil
    }
}
