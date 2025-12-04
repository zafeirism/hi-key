import UIKit

class ZoomableImageVC: UIViewController, UIScrollViewDelegate {
    var index: Int = 0
    var image: GeneratedImage?
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup scroll view
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        
        // Setup image view
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
        
        // Load image
        if let data = image?.imageData {
            imageView.image = UIImage(data: data)
        }
        
        // Double-tap gesture
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = view.bounds.size
        imageView.frame = view.bounds
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Center image when smaller than scroll view
        let boundsSize = scrollView.bounds.size
        var frame = imageView.frame
        
        frame.origin.x = frame.width < boundsSize.width ? (boundsSize.width - frame.width) / 2 : 0
        frame.origin.y = frame.height < boundsSize.height ? (boundsSize.height - frame.height) / 2 : 0
        
        imageView.frame = frame
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let location = gesture.location(in: imageView)
            let size = CGSize(width: view.bounds.width / 2.5, height: view.bounds.height / 2.5)
            let origin = CGPoint(x: location.x - size.width / 2, y: location.y - size.height / 2)
            scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
        }
    }
}

