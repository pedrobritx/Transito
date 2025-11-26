import Foundation

enum HLSEngineError: Error {
    case invalidURL
    case ffmpegNotFound
    case downloadFailed(String)
}

class HLSEngine {
    static func download(
        url: String,
        outputPath: String,
        extractSubtitles: Bool,
        userAgent: String?,
        referer: String?,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> DownloadResult {
        
        // 1. Validate URL
        guard let _ = URL(string: url) else {
            throw HLSEngineError.invalidURL
        }
        
        // 2. Find ffmpeg
        let ffmpegPath = await findFFmpeg()
        guard !ffmpegPath.isEmpty else {
            throw HLSEngineError.ffmpegNotFound
        }
        
        // 3. Build arguments
        var args = [
            "-hide_banner", "-loglevel", "warning", "-nostdin",
            "-reconnect", "1", "-reconnect_streamed", "1", "-reconnect_delay_max", "30",
            "-i", url,
            "-map", "0",
            "-c", "copy",
            "-bsf:a", "aac_adtstoasc",
            "-movflags", "+faststart",
            "-progress", "pipe:1"
        ]
        
        // Add headers
        var headerPairs: [String] = []
        if let ua = userAgent, !ua.isEmpty {
            headerPairs.append("User-Agent: \(ua)")
        }
        if let ref = referer, !ref.isEmpty {
            headerPairs.append("Referer: \(ref)")
        }
        if !headerPairs.isEmpty {
            args.append(contentsOf: ["-headers", headerPairs.joined(separator: "\r\n") + "\r\n"])
        }
        
        // Output path
        args.append(outputPath)
        
        // 4. Run process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe // ffmpeg writes progress to stdout with -progress pipe:1, but errors to stderr
        
        return await withCheckedContinuation { continuation in
            var outputBuffer = ""
            
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty { return }
                
                if let str = String(data: data, encoding: .utf8) {
                    outputBuffer += str
                    
                    // Parse progress
                    let lines = str.components(separatedBy: .newlines)
                    for line in lines {
                        if line.startsWith("out_time_ms=") {
                            let valueStr = line.replacingOccurrences(of: "out_time_ms=", with: "")
                            if let ms = Double(valueStr) {
                                // We don't know total duration easily with HLS, so we just show time downloaded
                                let seconds = ms / 1000000.0 // out_time_ms is in microseconds
                                let durationStr = formatDuration(seconds: seconds)
                                progressHandler(0.5, "Downloaded: \(durationStr)") // Indeterminate progress
                            }
                        }
                    }
                }
            }
            
            process.terminationHandler = { proc in
                pipe.fileHandleForReading.readabilityHandler = nil
                
                let success = proc.terminationStatus == 0
                let result = DownloadResult(
                    success: success,
                    outputPath: outputPath,
                    outputURL: success ? URL(fileURLWithPath: outputPath) : nil,
                    error: success ? nil : "ffmpeg exited with code \(proc.terminationStatus)"
                )
                continuation.resume(returning: result)
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(returning: DownloadResult(
                    success: false,
                    outputPath: outputPath,
                    outputURL: nil,
                    error: error.localizedDescription
                ))
            }
        }
    }
    
    private static func findFFmpeg() async -> String {
        // Check app support first (where FFmpegInstaller puts it)
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let localFFmpeg = appSupportDir.appendingPathComponent("Transito/ffmpeg")
        
        if FileManager.default.fileExists(atPath: localFFmpeg.path) {
            return localFFmpeg.path
        }
        
        // Fallback to system path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try? process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
            return path
        }
        
        return ""
    }
    
    private static func formatDuration(seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }
}

private extension String {
    func startsWith(_ prefix: String) -> Bool {
        return self.hasPrefix(prefix)
    }
}
