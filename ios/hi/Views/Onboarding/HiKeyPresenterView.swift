import SwiftUI

struct HiKeyPresenterView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    @State private var startTime: Date?
    @State private var currentTextIndex: Int? = nil
    @State private var isAnimationComplete: Bool = false
    @State private var textChangeTasks: [DispatchWorkItem] = []
    @State private var isLottieFinished = false
    
    private let textStates: [(startWith: String, startWithAccent: Bool, endWith: String, endWithAccent: Bool)] = [
        (startWith: "Meet ", startWithAccent: false, endWith: "hi-key.", endWithAccent: true),
        (startWith: "It lives behind the globe", startWithAccent: true, endWith: " so you can use it in any app.", endWithAccent: false),
        (startWith: "Describe a scene and get a few images ", startWithAccent: false, endWith: "instantly.", endWithAccent: true),
        (startWith: "So the moment ", startWithAccent: false, endWith: "hits right.", endWithAccent: true),
    ]
    
    private let textAlignment: [Alignment] = [.center, .leading, .leading, .leading]
    private let textIsAtTheTop: [Bool] = [true, false, false, true]
    
    private let animationDuration: TimeInterval = 23.7
    
    private struct TextCue {
        let at: TimeInterval       // seconds from start
        let stateIndex: Int?       // nil means "no text"
    }

    private let textCues: [TextCue] = [
        TextCue(at: 0.8, stateIndex: 0),    // first title appears after 2s, animated
        TextCue(at: 7.5, stateIndex: nil),  // gap with no text
        TextCue(at: 9, stateIndex: 1),
        TextCue(at: 13, stateIndex: nil), // another gap
        TextCue(at: 14, stateIndex: 2),
        TextCue(at: 19.5, stateIndex: nil),
        TextCue(at: 23.3, stateIndex: 3)
    ]

    private var progress: Double {
        guard let startTime = startTime else { return 0.0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return min(elapsed / animationDuration, 1.0)
    }
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.03)) { timeline in
            ZStack{
                LottieView(name: "hi-key-overview", isFinished: $isLottieFinished)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    progressBar
                        .padding(.top, HiTheme.spacingXL)
                    
                    if let index = currentTextIndex, !textIsAtTheTop[index] {
                        Spacer()
                        Spacer()
                        Spacer()
                    }
                    
                    if let index = currentTextIndex {
                        (Text(textStates[index].startWith)
                            .foregroundColor(textStates[index].startWithAccent ? .accent : .primary) +
                         Text(textStates[index].endWith)
                            .foregroundColor(textStates[index].endWithAccent ? .accent : .primary))
                        .font(.title.bold())
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: textAlignment[index])
                        .padding(.top, HiTheme.spacingXL)
                        .id(index)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                    
                    Spacer()
                
                    // CTA at bottom
                    Group{
                        if isAnimationComplete || progress >= 1.0 {
                            Button {
                                onboardingManager.goToNextStep()
                            } label: {
                                Text("Try it")
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
                .padding(.horizontal, HiTheme.spacingXL)
                .onChange(of: progress) { _, newProgress in
                    if newProgress >= 1.0 && !isAnimationComplete {
                        isAnimationComplete = true
                    }
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
        currentTextIndex = nil
        isAnimationComplete = false
        cancelTextChanges()
        
        for cue in textCues {
            let task = DispatchWorkItem {
                withAnimation(.spring(response: 0.5)) {
                    currentTextIndex = cue.stateIndex
                }
            }
            textChangeTasks.append(task)
            DispatchQueue.main.asyncAfter(deadline: .now() + cue.at, execute: task)
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
