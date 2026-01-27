import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    var loopMode: LottieLoopMode = .playOnce
    @Binding var isFinished: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = loopMode
        animationView.play { finished in
            if finished {
                DispatchQueue.main.async {
                    isFinished = true
                }
            }
        }

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No-op; not needed for simple playback
    }
}
