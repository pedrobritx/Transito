import SwiftUI
import AppKit

/// NSViewRepresentable wrapper for NSVisualEffectView with material and blending support.
/// Provides glassy, translucent backgrounds with system-managed vibrancy and blur.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blending: NSVisualEffectView.BlendingMode = .behindWindow
    var emphasized: Bool = false
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.isEmphasized = emphasized
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blending
        nsView.isEmphasized = emphasized
        nsView.state = state
    }
}
