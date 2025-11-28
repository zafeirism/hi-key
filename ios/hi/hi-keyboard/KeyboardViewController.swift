import UIKit
import SwiftUI
import KeyboardKit

class KeyboardViewController: KeyboardInputViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up KeyboardKit with our app configuration
        setup(for: .hi) { result in
            switch result {
            case .success:
                print("KeyboardKit setup succeeded")
            case .failure(let error):
                print("KeyboardKit setup failed: \(error)")
            }
        }
    }
    
    override func viewWillSetupKeyboardView() {
        setupKeyboardView { [unowned self] controller in
            HiKeyboardView(services: controller.services)
        }
    }
}
