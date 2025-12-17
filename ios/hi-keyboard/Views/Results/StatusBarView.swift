import SwiftUI

struct StatusBarView: View {
    var body: some View {
        Text("Copy an image, then paste to use it")
            .font(.system(.callout))
            .foregroundStyle(.secondary)
            .padding(.top, 18)
    }
}
