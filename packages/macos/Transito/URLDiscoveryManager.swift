import Foundation
import WebKit

@MainActor
class URLDiscoveryManager: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var isScanning = false
    @Published var foundURLs: [String] = []
    
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<[String], Error>?
    
    func findM3U8Links(in urlString: String) async throws -> [String] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        isScanning = true
        foundURLs = []
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let config = WKWebViewConfiguration()
            config.websiteDataStore = .nonPersistent()
            
            let webView = WKWebView(frame: .zero, configuration: config)
            webView.navigationDelegate = self
            self.webView = webView
            
            let request = URLRequest(url: url)
            webView.load(request)
            
            // Timeout after 15 seconds
            Task {
                try? await Task.sleep(nanoseconds: 15 * 1_000_000_000)
                if self.isScanning {
                    self.finishScanning()
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject JS to find m3u8 links
        let js = """
        (function() {
            var urls = new Set();
            
            // Check all video tags
            var videos = document.getElementsByTagName('video');
            for (var i = 0; i < videos.length; i++) {
                if (videos[i].src && videos[i].src.includes('.m3u8')) {
                    urls.add(videos[i].src);
                }
                // Check sources inside video tags
                var sources = videos[i].getElementsByTagName('source');
                for (var j = 0; j < sources.length; j++) {
                    if (sources[j].src && sources[j].src.includes('.m3u8')) {
                        urls.add(sources[j].src);
                    }
                }
            }
            
            // Check all links
            var links = document.getElementsByTagName('a');
            for (var i = 0; i < links.length; i++) {
                if (links[i].href && links[i].href.includes('.m3u8')) {
                    urls.add(links[i].href);
                }
            }
            
            // Check page source for regex matches (simple fallback)
            var html = document.documentElement.outerHTML;
            var regex = /https?:\\/\\/[^"']+\\.m3u8/g;
            var matches = html.match(regex);
            if (matches) {
                matches.forEach(url => urls.add(url));
            }
            
            return Array.from(urls);
        })()
        """
        
        webView.evaluateJavaScript(js) { [weak self] result, error in
            guard let self = self else { return }
            
            if let urls = result as? [String] {
                self.foundURLs = urls
            }
            
            self.finishScanning()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView failed: \(error.localizedDescription)")
        finishScanning()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView provisional failed: \(error.localizedDescription)")
        finishScanning()
    }
    
    private func finishScanning() {
        guard isScanning else { return }
        isScanning = false
        
        // Clean up
        webView = nil
        
        if let continuation = continuation {
            continuation.resume(returning: foundURLs)
            self.continuation = nil
        }
    }
}
