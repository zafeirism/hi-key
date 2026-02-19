import SwiftUI

/// Reusable header for sheet presentations.
/// Shows a centered title with an optional close button on the right.
struct HiSheetHeader: View {
    let title: String
    var onClose: (() -> Void)?

    var body: some View {
        ZStack {
            Text(title)
                .font(.title2.weight(.semibold))

            if let onClose {
                HStack {
                    Spacer()

                    HiIconButton("xmark", size: .sheet) {
                        onClose()
                    }
                }
            }
        }
        .padding(.top, HiTheme.spacingMD)
        .padding(.bottom, HiTheme.spacingXL)
    }
}

#Preview {
    ZStack {
        HiTheme.backgroundRoot.ignoresSafeArea()

        VStack {
            HiSheetHeader(title: "Select a plan", onClose: { print("Close") })
                .padding(.horizontal, HiTheme.spacingMD)
            Spacer()
        }
    }
}
