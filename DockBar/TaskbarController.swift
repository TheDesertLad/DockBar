import AppKit
import Combine

class TaskbarController {

    static let shared = TaskbarController()

    private var cancellables = Set<AnyCancellable>()

    // The launcher button (only item for now)
    private(set) var launcherButton = LauncherButton()

    // Container view that holds all taskbar items
    private(set) var contentContainer = NSView()

    // Constraint used for center mode
    private var centerXConstraint: NSLayoutConstraint?

    private init() {
        setupObservers()
        buildInitialLayout()
    }

    // MARK: - Observers
    private func setupObservers() {
        let settings = TaskbarSettings.shared

        // Launcher Enabled
        settings.$launcherEnabled
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.rebuildLayout()
                }
            }
            .store(in: &cancellables)

        // Launcher Position
        settings.$launcherPosition
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.rebuildLayout()
                }
            }
            .store(in: &cancellables)

        // Launcher Icon Changed
        NotificationCenter.default.publisher(for: .launcherAppChanged)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateLauncherIcon()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Initial Layout
    private func buildInitialLayout() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        rebuildLayout()
    }

    // MARK: - Rebuild Layout
    func rebuildLayout() {
        // Remove all subviews
        contentContainer.subviews.forEach { $0.removeFromSuperview() }

        let settings = TaskbarSettings.shared

        // Launcher Enabled?
        if settings.launcherEnabled {
            contentContainer.addSubview(launcherButton)
            launcherButton.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                launcherButton.widthAnchor.constraint(equalToConstant: 40),
                launcherButton.heightAnchor.constraint(equalToConstant: 40),
                launcherButton.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor)
            ])
        }

        // Remove old center constraint
        centerXConstraint?.isActive = false
        centerXConstraint = nil

        // Apply new layout based on setting
        switch settings.launcherPosition {
        case "Left":
            applyLeftLayout()
        case "Center":
            applyCenterLayout()
        default:
            applyLeftLayout()
        }
    }

    // MARK: - Left Layout
    private func applyLeftLayout() {
        guard TaskbarSettings.shared.launcherEnabled else { return }

        NSLayoutConstraint.activate([
            launcherButton.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 8)
        ])
    }

    // MARK: - Center Layout
    private func applyCenterLayout() {
        guard TaskbarSettings.shared.launcherEnabled else { return }

        centerXConstraint = launcherButton.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor)
        centerXConstraint?.isActive = true
    }

    // MARK: - Update Launcher Icon
    private func updateLauncherIcon() {
        launcherButton.updateIcon()
    }
}

