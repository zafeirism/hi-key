import UIKit
import SwiftUI

// MARK: - FAQ Data

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let links: [FAQLink]

    init(question: String, answer: String, links: [FAQLink] = []) {
        self.question = question
        self.answer = answer
        self.links = links
    }
}

private struct FAQLink {
    let label: String
    let systemImage: String
    let url: URL
}

private let faqItems: [FAQItem] = [
    FAQItem(
        question: "What is hi-key?",
        answer: "hi-key is a keyboard that generates AI images right where you type. Describe what you want, tap generate, and share the result — all without leaving your conversation."
    ),
    FAQItem(
        question: "How do I enable the keyboard?",
        answer: "Go to Settings → General → Keyboard → Keyboards → Add New Keyboard, and select hi-key. Then tap hi-key and enable Full Access.\n\nFull Access allows the keyboard to connect to our servers to generate images — without it, image generation won't work. We don't collect or store any typing data.",
        links: [
            FAQLink(label: "Open Settings", systemImage: "gear", url: URL(string: UIApplication.openSettingsURLString)!),
        ]
    ),
    FAQItem(
        question: "What apps work with hi-key?",
        answer: "hi-key works in any app that supports the standard iOS keyboard — iMessage, WhatsApp, Instagram, Snapchat, Telegram, and more. If you can type in it, you can use hi-key."
    ),
    FAQItem(
        question: "How do credits work?",
        answer: "Each image generation uses one credit. You can get credits in two ways: subscribe for a monthly allowance that auto-renews, or buy a one-time credit pack. Unused credits from one-time packs never expire."
    ),
    FAQItem(
        question: "Can I use hi-key for free?",
        answer: "You get free credits when you sign up to try hi-key. After that, you can earn more by inviting friends — when a friend joins with your code and starts a free trial or buys credits, you both get 50 bonus credits."
    ),
    FAQItem(
        question: "Where can I learn more?",
        answer: "Visit our website for the latest updates, tips, and examples of what people are creating.",
        links: [
            FAQLink(label: "hi-key.ai", systemImage: "safari", url: URL(string: "https://hi-key.ai")!),
        ]
    ),
    FAQItem(
        question: "Contact & Legal",
        answer: "Have a question or issue? Reach us by email. You can also review our Terms of Service and Privacy Policy.",
        links: [
            FAQLink(label: "support@hi-key.ai", systemImage: "envelope", url: URL(string: "mailto:support@hi-key.ai")!),
            FAQLink(label: "Terms of Service", systemImage: "doc.text", url: URL(string: "https://hi-key.ai/terms")!),
            FAQLink(label: "Privacy Policy", systemImage: "lock.shield", url: URL(string: "https://hi-key.ai/privacy")!),
        ]
    ),
]

// MARK: - FAQ View

struct FAQView: View {
    @State private var expandedID: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(faqItems.enumerated()), id: \.element.id) { index, item in
                    FAQRow(
                        item: item,
                        isExpanded: expandedID == item.id,
                        onTap: {
                            withAnimation(HiTheme.animationNormal) {
                                expandedID = expandedID == item.id ? nil : item.id
                            }
                        }
                    )

                    if index < faqItems.count - 1 {
                        Divider()
                            .background(HiTheme.divider)
                            .padding(.horizontal, HiTheme.spacingMD)
                            
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: HiTheme.radiusXL, style: .continuous)
                    .fill(HiTheme.surfacePrimary)
            )
            .padding(.horizontal, HiTheme.spacingMD)
            .padding(.top, HiTheme.spacingSM)
        }
        .background(HiTheme.backgroundRoot)
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FAQ Row

private struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(item.question)
                        .font(.body.weight(.medium))
                        .foregroundStyle(HiTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HiTheme.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? -180 : 0))
                }
                .padding(.horizontal, HiTheme.spacingMD)
                .padding(.vertical, HiTheme.spacingMD)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
                    Text(item.answer)
                        .font(.subheadline)
                        .foregroundStyle(HiTheme.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    if !item.links.isEmpty {
                        VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
                            ForEach(item.links, id: \.label) { link in
                                Link(destination: link.url) {
                                    HStack(spacing: 6) {
                                        Image(systemName: link.systemImage)
                                            .font(.caption)
                                        Text(link.label)
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .foregroundStyle(HiTheme.accentPrimary)
                                }
                            }
                        }
                        .padding(.top, HiTheme.spacingMD)
                    }
                }
                .padding(.horizontal, HiTheme.spacingMD)
                .padding(.bottom, HiTheme.spacingLG)
                .transition(.opacity)
            }
        }
        .clipped()
    }
}

#Preview {
    NavigationStack {
        FAQView()
    }
    .preferredColorScheme(.dark)
}
