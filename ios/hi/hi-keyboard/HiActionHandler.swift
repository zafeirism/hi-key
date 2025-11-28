import KeyboardKit

class HiActionHandler: KeyboardAction.StandardActionHandler {
    
    private weak var viewModel: HiKeyboardViewModel?
    
    // Simple flag we can check without actor isolation issues
    var isInterceptingInput = false
    
    init(controller: KeyboardInputViewController, viewModel: HiKeyboardViewModel) {
        self.viewModel = viewModel
        
        // Call the designated initializer with all required dependencies
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
        // If not intercepting, use default keyboard behavior
        guard isInterceptingInput else {
            super.handle(gesture, on: action)
            return
        }
        
        // Handle keys for our prompt field
        switch (gesture, action) {
            
        case (.release, .character(let char)):
            DispatchQueue.main.async { [weak self] in
                self?.viewModel?.appendToPrompt(char)
            }
            
        case (.release, .space):
            DispatchQueue.main.async { [weak self] in
                self?.viewModel?.appendToPrompt(" ")
            }
            
        case (.press, .backspace), (.repeat, .backspace):
            DispatchQueue.main.async { [weak self] in
                self?.viewModel?.deleteLastCharacter()
            }
            
        case (.release, .primary):
            DispatchQueue.main.async { [weak self] in
                self?.viewModel?.isPromptFocused = false
                self?.isInterceptingInput = false
            }
            
        default:
            super.handle(gesture, on: action)
        }
    }
}
