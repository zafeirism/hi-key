import UIKit

enum Watermark {
    static let badge: UIImage? = UIImage(named: "hi-key-watermark")

    private static let appGroupID = "group.ai.hi-key"
    private static let removeWatermarkEnabledKey = "removeWatermarkEnabled"
    private static let removeWatermarkEntitlementActiveKey = "removeWatermarkEntitlementActive"

    /// True when the user toggled "Remove watermark" on AND the
    /// `remove_watermark` entitlement is currently active. Both bits are
    /// mirrored to the app group by the main app — the keyboard extension
    /// reads them here so it never needs RC directly.
    private static var shouldApply: Bool {
        let defaults = UserDefaults(suiteName: appGroupID)
        let toggle = defaults?.bool(forKey: removeWatermarkEnabledKey) ?? false
        let entitled = defaults?.bool(forKey: removeWatermarkEntitlementActiveKey) ?? false
        return !(toggle && entitled)
    }

    static func add(to imageData: Data, padding: CGFloat = 32) -> UIImage? {
        guard shouldApply else {
            return UIImage(data: imageData)
        }
        guard let badge = badge, let originalImage = UIImage(data: imageData) else {
            return nil
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: originalImage.size, format: format)
        
        let result = renderer.image { context in
            originalImage.draw(at: .zero)

            let scale = 1.0 // change watermark size if needed
            let badgeSize = CGSize(
                width: badge.size.width * scale,
                height: badge.size.height * scale
            )

            let badgeOrigin = CGPoint(
                x: originalImage.size.width - badgeSize.width - padding,
                y: originalImage.size.height - badgeSize.height - padding
            )
            let badgeRect = CGRect(origin: badgeOrigin, size: badgeSize)

            let cgContext = context.cgContext
            cgContext.saveGState()
            cgContext.setShadow(
                offset: .zero,
                blur: 3,
                color: UIColor.black.withAlphaComponent(0.35).cgColor
            )
            badge.draw(in: badgeRect, blendMode: .normal, alpha: 0.6)
            cgContext.restoreGState()
        }
        
        return result
    }
}
