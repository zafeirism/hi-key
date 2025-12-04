import SwiftUI
import UIKit

struct ImageGalleryViewController: UIViewControllerRepresentable {
    let images: [GeneratedImage]
    let currentIndex: Int
    let onPageChange: (Int) -> Void
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator
        pageVC.view.backgroundColor = .clear
        
        // Set initial page
        if let initialVC = context.coordinator.viewController(for: currentIndex) {
            pageVC.setViewControllers([initialVC], direction: .forward, animated: false)
        }
        
        return pageVC
    }
    
    func updateUIViewController(_ pageVC: UIPageViewController, context: Context) {
        context.coordinator.images = images
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(images: images, onPageChange: onPageChange)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var images: [GeneratedImage]
        let onPageChange: (Int) -> Void
        
        init(images: [GeneratedImage], onPageChange: @escaping (Int) -> Void) {
            self.images = images
            self.onPageChange = onPageChange
        }
        
        func viewController(for index: Int) -> ZoomableImageVC? {
            guard index >= 0 && index < images.count else { return nil }
            let vc = ZoomableImageVC()
            vc.index = index
            vc.image = images[index]
            return vc
        }
        
        func pageViewController(_ pageVC: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
            guard let zoomVC = vc as? ZoomableImageVC else { return nil }
            return viewController(for: zoomVC.index - 1)
        }
        
        func pageViewController(_ pageVC: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard let zoomVC = vc as? ZoomableImageVC else { return nil }
            return viewController(for: zoomVC.index + 1)
        }
        
        func pageViewController(_ pageVC: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed, let zoomVC = pageVC.viewControllers?.first as? ZoomableImageVC else { return }
            onPageChange(zoomVC.index)
        }
    }
}

