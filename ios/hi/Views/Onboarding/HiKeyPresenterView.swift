import SwiftUI

struct HiKeyPresenterView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    @State private var startTime: Date?
    @State private var currentTextIndex: Int = 0
    @State private var isAnimationComplete: Bool = false
    @State private var textChangeTasks: [DispatchWorkItem] = []
    
//    private let textStates = [
//        "Meet hi-key.",
//        "It lives behind the globe, so you can use it in any app.",
//        "Describe a scene. Get multiple images. Paste instantly.",
//        "Oh, and it's fast. So you can capture the moment."
//    ]
    
    private let textStates: [(startWith: String, startWithAccent: Bool, endWith: String, endWithAccent: Bool)] = [
        (startWith: "Meet ", startWithAccent: false, endWith: "hi-key.", endWithAccent: true),
        (startWith: "It lives behind the globe", startWithAccent: true, endWith: ", so you can use it in any app.", endWithAccent: false),
        (startWith: "Describe a scene. Get multiple images. ", startWithAccent: false, endWith: "Paste instantly.", endWithAccent: true),
        (startWith: "Oh, and it's fast", startWithAccent: true, endWith: ". So you can capture the moment.", endWithAccent: false),
    ]
    
    private let animationDuration: TimeInterval = 16.0
    private let textChangeInterval: TimeInterval = 4
    
    private var progress: Double {
        guard let startTime = startTime else { return 0.0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return min(elapsed / animationDuration, 1.0)
    }
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.03)) { timeline in
            VStack(spacing: 0) {
                
                progressBar
                    .padding(.top, HiTheme.spacingXL)
                
                (Text(textStates[currentTextIndex].startWith)
                    .foregroundColor(textStates[currentTextIndex].startWithAccent ? .accent : .primary) +
                 Text(textStates[currentTextIndex].endWith)
                    .foregroundColor(textStates[currentTextIndex].endWithAccent ? .accent : .primary))
                .font(.title.bold())
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, HiTheme.spacingXXL)
                
                Spacer()
                
                // Middle space for future assets
                
                Spacer()
                
                // CTA at bottom
                Group{
                    if isAnimationComplete || progress >= 1.0 {
                        Button {
                            onboardingManager.goToNextStep()
                        } label: {
                            Text("Let's try it")
                        }
                        .buttonStyle(HiPrimaryButtonStyle())
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        Button {
                            onboardingManager.goToNextStep()
                        } label: {
                            Text("Skip")
                        }
                        .buttonStyle(HiTertiaryButtonStyle())
                    }
                }
                .padding(.bottom, HiTheme.spacingXXL)
            }
            .padding(.horizontal, HiTheme.spacingLG)
            .onChange(of: progress) { _, newProgress in
                if newProgress >= 1.0 && !isAnimationComplete {
                    isAnimationComplete = true
                }
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            cancelTextChanges()
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.5
            
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: width, height: 4)
                
                // Progress fill
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: width * progress, height: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 4)
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        startTime = Date()
        currentTextIndex = 0
        isAnimationComplete = false
        cancelTextChanges()
        
        // Change text at intervals
        for index in 1..<textStates.count {
            let task = DispatchWorkItem {
                if currentTextIndex < textStates.count - 1 {
                    withAnimation(HiTheme.animationNormal) {
                        currentTextIndex = index
                    }
                }
            }
            textChangeTasks.append(task)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * textChangeInterval, execute: task)
        }
    }
    
    private func cancelTextChanges() {
        textChangeTasks.forEach { $0.cancel() }
        textChangeTasks.removeAll()
    }
}

#Preview {
    ZStack {
        HiTheme.onboardingGradient
            .ignoresSafeArea()
        
        HiKeyPresenterView()
    }
}
