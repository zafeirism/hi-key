import UIKit
import SwiftUI
import KeyboardKit

class KeyboardViewController: KeyboardInputViewController {
    
    private let hiViewModel = HiKeyboardViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        HiLogger.configure()

        FullAccessMonitor.shared.update(hasFullAccess)

        setup(for: .hi) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                print("KeyboardKit setup succeeded")
                let handler = HiActionHandler(controller: self, viewModel: self.hiViewModel)
                self.services.actionHandler = handler
                self.hiViewModel.actionHandler = handler

            case .failure(let error):
                HiLogger.error("KeyboardKit setup failed", error: error, category: .keyboard)
            }
        }

        hiViewModel.openURLHandler = { [weak self] url in
            self?.openHostApp(url: url)
        }

        Task {
            try await APIClient.shared.warmup()
        }

        Task { [weak self] in
            await self?.hiViewModel.refreshFromBackend()
        }
    }
    
    // MARK: - Detect Host App Text Interaction
        
    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        
        // If we're intercepting input but text is changing in host app,
        // it means user tapped on host app's text field
        // Unfocus our prompt
        if hiViewModel.isPromptFocused {
            DispatchQueue.main.async { [weak self] in
                self?.hiViewModel.unfocusPrompt()
            }
        }
    }

    /// Open a hi-key:// URL from the keyboard. `extensionContext.open(_:)`
    /// is not honored for keyboard extensions, and `UIApplication.open(_:)`
    /// is marked unavailable in extension targets. The working path is to
    /// walk the responder chain to the connected `UIScene` and call its
    /// typed `open(_:options:completionHandler:)` API — that one IS
    /// available in extensions. Full Access is required.
    private func openHostApp(url: URL) {
        var responder: UIResponder? = self
        while let r = responder {
            if let scene = r as? UIScene {
                scene.open(url, options: nil, completionHandler: nil)
                return
            }
            responder = r.next
        }
        HiLogger.error("No UIScene found up the responder chain", category: .keyboard)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FullAccessMonitor.shared.update(hasFullAccess)
    }

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { [unowned self] controller in
            HiKeyboardView(
                services: controller.services,
                viewModel: self.hiViewModel
            )
        }
    }
}
