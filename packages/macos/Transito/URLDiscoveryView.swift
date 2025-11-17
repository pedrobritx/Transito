import SwiftUI

/// View for URL discovery feature
/// Allows users to input a webpage URL to automatically find streaming links
struct URLDiscoveryView: View {
    @StateObject private var discoveryManager = URLDiscoveryManager()
    @State private var pageURL: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("URL Discovery")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Automatically find M3U8 links from web pages")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Webpage URL:")
                    .font(.headline)
                
                TextField("Enter webpage URL", text: $pageURL)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    Task {
                        await discoveryManager.discoverURLs(from: pageURL)
                    }
                }) {
                    HStack {
                        if discoveryManager.isDiscovering {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(discoveryManager.isDiscovering ? "Discovering..." : "Find URLs")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(pageURL.isEmpty || discoveryManager.isDiscovering)
            }
            .padding()
            
            if !discoveryManager.discoveredURLs.isEmpty {
                List(discoveryManager.discoveredURLs, id: \.self) { url in
                    Text(url)
                        .font(.caption)
                }
                .frame(height: 200)
            }
            
            if let error = discoveryManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

#Preview {
    URLDiscoveryView()
}
