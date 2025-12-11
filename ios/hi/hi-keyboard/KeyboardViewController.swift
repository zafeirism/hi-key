import UIKit
import SwiftUI
import KeyboardKit

class KeyboardViewController: KeyboardInputViewController {
    
    private let hiViewModel = HiKeyboardViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup(for: .hi) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                print("KeyboardKit setup succeeded")
                let handler = HiActionHandler(controller: self, viewModel: self.hiViewModel)
                self.services.actionHandler = handler
                self.hiViewModel.actionHandler = handler
                
            case .failure(let error):
                print("KeyboardKit setup failed: \(error)")
            }
        }
     
        Task {
            await AuthManager.shared.restoreSession()
        }
    }
    
    override func viewWillSetupKeyboardView() {
        setupKeyboardView { [unowned self] controller in
            HiKeyboardView(
                services: controller.services,
                viewModel: self.hiViewModel
            )
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
}
