import SwiftUI

struct StatusBarView: View {
    var transientMessage: String? = nil

    private static let defaultMessage = "Copy an image, then paste to use it"

    var body: some View {
        Text(transientMessage ?? Self.defaultMessage)
            .font(.system(.callout))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.top, 18)
            .animation(.easeInOut(duration: 0.2), value: transientMessage)
    }
}
