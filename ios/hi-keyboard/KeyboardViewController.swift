import UIKit
import SwiftUI
import KeyboardKit

class KeyboardViewController: KeyboardInputViewController {
    
    private let hiViewModel = HiKeyboardViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        HiLogger.configure()
        
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
        
        Task {
            try await APIClient.shared.warmup()
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
}
