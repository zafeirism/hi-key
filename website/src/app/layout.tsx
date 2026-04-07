import type { Metadata } from "next";
import { Inter, Nunito } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

const nunito = Nunito({
  variable: "--font-nunito",
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "hi-key | AI images, right from your keyboard",
  description:
    "Create AI images in seconds, right from your keyboard. Works inside iMessage, WhatsApp, and any app you use on iPhone.",
  metadataBase: new URL("https://hi-key.ai"),
  openGraph: {
    title: "hi-key | AI images, right from your keyboard",
    description:
      "Create AI images in seconds, right from your keyboard. Works inside iMessage, WhatsApp, and any app you use on iPhone.",
    url: "https://hi-key.ai",
    siteName: "hi-key",
    locale: "en_US",
    type: "website",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "hi-key keyboard showing AI-generated images of a penguin with sunglasses surfing",
        type: "image/png",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "hi-key | AI images, right from your keyboard",
    description:
      "Create AI images in seconds, right from your keyboard. Works inside iMessage, WhatsApp, and any app you use on iPhone.",
    images: ["/og-image.png"],
  },
  keywords: [
    "ai keyboard",
    "ai image keyboard",
    "ai images iphone",
    "keyboard image generator",
    "hi-key",
    "hikey",
    "hi key",
    "hi-key app",
    "hi-key keyboard",
    "hikey app",
    "hikey iOS",
    "hi key app",
    "hi key keyboard",
    "hi-key ai",
    "hikey ai",
    "hi key ai",
    "ai image generator for texting",
    "send ai images",
    "ai images imessage",
    "generate images from keyboard",
  ],
  alternates: {
    canonical: "https://hi-key.ai",
  },
  manifest: "/site.webmanifest",
};

const jsonLdApp = {
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  name: "hi-key",
  alternateName: ["hikey", "hi key", "hi key ai", "hikey ai"],
  description:
    "Create AI images in seconds, right from your keyboard. Works inside iMessage, WhatsApp, and any app you use on iPhone.",
  operatingSystem: "iOS",
  applicationCategory: "UtilitiesApplication",
  applicationSubCategory: "AI Image Generation",
  inLanguage: "en",
  featureList:
    "AI image generation, Works in any app, 4 images per prompt, Privacy-first, Custom iOS keyboard",
  screenshot: "https://hi-key.ai/og-image.png",
  offers: {
    "@type": "Offer",
    price: "0",
    priceCurrency: "USD",
  },
  image: "https://hi-key.ai/app-icon.png",
  author: {
    "@type": "Organization",
    name: "hi-key",
    url: "https://hi-key.ai",
  },
};

const jsonLdWebsite = {
  "@context": "https://schema.org",
  "@type": "WebSite",
  name: "hi-key",
  alternateName: ["hikey", "hi key", "hi key ai", "hikey ai"],
  url: "https://hi-key.ai",
};

const jsonLdOrg = {
  "@context": "https://schema.org",
  "@type": "Organization",
  name: "hi-key",
  url: "https://hi-key.ai",
  logo: "https://hi-key.ai/app-icon.png",
  sameAs: ["https://x.com/hikey_ai"],
};

const jsonLdFaq = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: [
    {
      "@type": "Question",
      name: "What is hi-key?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "hi-key is an iOS keyboard that generates AI images from text prompts. Switch to it like you switch to the emoji keyboard, type a description, and hi-key creates 4 images in seconds. Right there, inside any app you're using.",
      },
    },
    {
      "@type": "Question",
      name: "How does hi-key work?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Enable hi-key as a keyboard on your iPhone once and it becomes available in all your apps. Switch to it using the 🌐 icon, describe a scene, and you'll have 4 images in seconds. Tap any result to copy it, then paste it wherever you want.",
      },
    },
    {
      "@type": "Question",
      name: "Which apps does hi-key work in?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "hi-key works in any app with a text input, like iMessage, WhatsApp, Instagram DMs, Telegram, Slack, Notes, email, and more. It's a system keyboard, so it's available everywhere you type.",
      },
    },
    {
      "@type": "Question",
      name: "Can I try hi-key for free?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Absolutely. There's a free trial to get started. Also, when you refer a friend, you both get free credits. And when you decide you want more, one-off credit packs and subscriptions start under a dollar.",
      },
    },
    {
      "@type": "Question",
      name: "Is hi-key safe? Can it read my messages?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "hi-key only processes the prompts you type in the hi-key prompt bar. It never reads, stores, or sends your messages, passwords, or any other content. Prompts are processed securely and used solely to generate your images.",
      },
    },
    {
      "@type": "Question",
      name: "What does \"double credits forever\" mean for early members?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Everyone who joins the waitlist gets 2× credits on every purchase, forever. Buy 50 credits, get 100. Buy 100, get 200. It applies to subscriptions and one-time packs, and it never expires. Our way of saying thanks for believing in hi-key early.",
      },
    },
    {
      "@type": "Question",
      name: "I don't like spam, accounts, or subscriptions. Is hi-key for me?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "hi-key is exactly for you. There are no accounts. Just download and go. Joining the waitlist means one email when the app is ready, nothing more. When you want more credits, there are one-time packs with no recurring costs. And if you do subscribe, you can cancel anytime. hi-key is fun to have, not a commitment.",
      },
    },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
      <body className={`${inter.variable} ${nunito.variable} font-sans antialiased`}>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdApp) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdWebsite) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdOrg) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdFaq) }}
        />
        {children}
      </body>
    </html>
  );
}
