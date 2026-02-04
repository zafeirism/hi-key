import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    var loop: Bool = false
    var scaleAspectFill = false

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.clipsToBounds = true

        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = scaleAspectFill ? .scaleAspectFill : .scaleAspectFit
        animationView.loopMode = loop ? .loop : .playOnce
        animationView.play()

        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
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
