import KeyboardKit

class HiActionHandler: KeyboardAction.StandardActionHandler {
    
    private weak var viewModel: HiKeyboardViewModel?
    
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
        keyboardContext.returnKeyTypeOverride = .go
    }
    
    override func handle(_ gesture: Keyboard.Gesture, on action: KeyboardAction) {
        switch (gesture, action) {
            
        case (.release, .character(let char)):
            MainActor.assumeIsolated {
                viewModel?.addToPrompt(char)
            }
            break
            
        case (.release, .characterMargin(let char)):
            MainActor.assumeIsolated {
                viewModel?.addToPrompt(char)
            }
            break
            
        case (.release, .space):
            MainActor.assumeIsolated {
                viewModel?.addToPrompt(" ")
                // "123 -> . -> space -> back to ABC" behavior
                keyboardController?.setKeyboardType(.alphabetic)
            }
            break

        case (.press, .backspace), (.repeat, .backspace):
            MainActor.assumeIsolated {
                viewModel?.deleteCharacter()
            }
            break
            
        case (.release, .primary):
            MainActor.assumeIsolated {
                Task {
                    await viewModel?.generate()
                }
            }
            break
            
        default:
            super.handle(gesture, on: action)
            break
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

