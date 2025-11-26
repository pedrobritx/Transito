import SwiftUI

struct URLDiscoveryView: View {
    let urls: [String]
    let onSelect: (String) -> Void
    let onCancel: () -> Void
    
    @State private var selectedURL: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Video Stream")
                .font(.headline)
            
            Text("Found \(urls.count) potential video streams.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            List(urls, id: \.self) { url in
                HStack {
                    Image(systemName: "film")
                    Text(url)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    if selectedURL == url {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedURL = url
                }
                .padding(.vertical, 4)
            }
            .listStyle(.bordered)
            .frame(height: 200)
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Download Selected") {
                    if let url = selectedURL {
                        onSelect(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedURL == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500)
    }
}
