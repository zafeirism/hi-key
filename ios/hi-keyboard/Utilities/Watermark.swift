import UIKit

enum Watermark {
    static let badge: UIImage? = UIImage(named: "watermark")

    static func add(to imageData: Data, padding: CGFloat = 32) -> UIImage? {
        guard let badge = badge, let originalImage = UIImage(data: imageData) else {
            return nil
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: originalImage.size, format: format)
        
        let result = renderer.image { context in
            originalImage.draw(at: .zero)
            
            let badgeOrigin = CGPoint(
                x: originalImage.size.width - badge.size.width - padding,
                y: originalImage.size.height - badge.size.height - padding
            )
        
            badge.draw(in: CGRect(origin: badgeOrigin, size: badge.size))
        }
        
        return result
    }
}
