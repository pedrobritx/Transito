import Foundation
import AppKit

class FFmpegInstaller {
    private let ffmpegURL = "https://evermeet.cx/ffmpeg/getrelease/ffmpeg/zip"
    private let ffprobeURL = "https://evermeet.cx/ffmpeg/getrelease/ffprobe/zip"
    
    func ensureInstalled() async -> Bool {
        if isFFmpegInstalled() {
            return true
        }
        
        // Show alert asking to download
        let alert = NSAlert()
        alert.messageText = "ffmpeg Required"
        alert.informativeText = "Transito needs ffmpeg to download HLS streams.\n\nDownload ffmpeg now? (~50MB)"
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return false
        }
        
        // Download ffmpeg binary to app support directory
        return await downloadFFmpeg()
    }
    
    private func isFFmpegInstalled() -> Bool {
        // Check if ffmpeg is available in PATH
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
    
    private func downloadFFmpeg() async -> Bool {
        let appSupportURL = getAppSupportURL()
        
        do {
            // Create app support directory
            try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            
            // Download ffmpeg
            let ffmpegPath = appSupportURL.appendingPathComponent("ffmpeg")
            let ffprobePath = appSupportURL.appendingPathComponent("ffprobe")
            
            let ffmpegSuccess = await downloadBinary(from: ffmpegURL, to: ffmpegPath)
            let ffprobeSuccess = await downloadBinary(from: ffprobeURL, to: ffprobePath)
            
            if ffmpegSuccess && ffprobeSuccess {
                // Make binaries executable
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: ffmpegPath.path)
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: ffprobePath.path)
                
                // Add to PATH for this session
                addToPath(appSupportURL)
                
                return true
            } else {
                return false
            }
            
        } catch {
            print("Error setting up ffmpeg: \(error)")
            return false
        }
    }
    
    private func downloadBinary(from urlString: String, to destination: URL) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Extract ZIP file
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            let zipPath = tempDir.appendingPathComponent("binary.zip")
            try data.write(to: zipPath)
            
            // Unzip
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = ["-o", zipPath.path, "-d", tempDir.path]
            process.currentDirectoryURL = tempDir
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                // Find the extracted binary
                let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                if let binaryFile = contents.first(where: { $0.lastPathComponent.hasPrefix("ffmpeg") || $0.lastPathComponent.hasPrefix("ffprobe") }) {
                    try FileManager.default.moveItem(at: binaryFile, to: destination)
                    return true
                }
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempDir)
            return false
            
        } catch {
            print("Error downloading binary: \(error)")
            return false
        }
    }
    
    private func getAppSupportURL() -> URL {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupportDir.appendingPathComponent("Transito")
    }
    
    private func addToPath(_ directory: URL) {
        // Add to PATH for this process
        var path = ProcessInfo.processInfo.environment["PATH"] ?? ""
        if !path.contains(directory.path) {
            path = "\(directory.path):\(path)"
            setenv("PATH", path, 1)
        }
    }
}
