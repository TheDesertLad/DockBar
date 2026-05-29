import AppKit

class TaskbarView: NSVisualEffectView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        blendingMode = .behindWindow
        material = .sidebar
        state = .active
        isEmphasized = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBlur(intensity: Double) {
        // Convert 0–100 slider → 0.0–1.0 alpha
        let alpha = CGFloat(intensity / 100.0)

        // Adjust transparency
        self.alphaValue = 0.4 + (alpha * 0.6)
        // Range: 0.4 → 1.0

        // Adjust blur strength by switching materials
        if intensity < 33 {
            material = .hudWindow      // very transparent
        } else if intensity < 66 {
            material = .sidebar        // medium blur (Dock-like)
        } else {
            material = .fullScreenUI   // strong blur
        }
    }
}
