import KeyboardKit

class HiActionHandler: KeyboardAction.StandardActionHandler {
    
    private weak var viewModel: HiKeyboardViewModel?
    
    var isInterceptingInput = false
    
    init(controller: KeyboardInputViewController, viewModel: HiKeyboardViewModel) {
        self.viewModel = viewModel
        
        super.init(
            controller: controller,
            keyboardContext: controller.state.keyboardContext,
            keyboardBehavior: controller.services.keyboardBehavior,
            autocompleteContext: controller.state.autocompleteContext,
            autocompleteService: controller.services.autocompleteService,
            emojiContext: controller.state.emojiContext,
            feedbackContext: controller.state.feedbackContext,
            feedbackService: controller.services.feedbackService,
            spacebarDragGestureHandler: controller.services.spacebarDragGestureHandler
        )
    }
    
    override func handle(_ gesture: Keyboard.Gesture, on action: KeyboardAction) {
        guard isInterceptingInput else {
            super.handle(gesture, on: action)
            return
        }
        
        switch (gesture, action) {
            
        case (.release, .character(let char)):
            MainActor.assumeIsolated {
                viewModel?.addToPrompt(char)
            }
            
        case (.release, .space):
            MainActor.assumeIsolated {
                viewModel?.addToPrompt(" ")
                // "123 -> . -> space -> back to ABC" behavior
                keyboardController?.setKeyboardType(.alphabetic)
            }
            
        case (.press, .backspace), (.repeat, .backspace):
            MainActor.assumeIsolated {
                viewModel?.deleteCharacter()
            }
            
        case (.release, .primary):
            // Return key - do nothing, keep focus on prompt
            break
            
        default:
            super.handle(gesture, on: action)
        }
    }

    // MARK: - Auto-Capitalization Logic
    
    func autoCapitalize(shouldCapitalize: Bool) {
        MainActor.assumeIsolated {
            if shouldCapitalize {
                keyboardController?.setKeyboardCase(.uppercased)
            } else {
                keyboardController?.setKeyboardCase(.lowercased)
            }
        }
    }
}
