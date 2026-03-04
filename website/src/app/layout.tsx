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
  title: "hi-key — AI Images From Your Keyboard",
  description:
    "Generate AI images instantly from your keyboard in any app. Describe a scene, get 4 images in seconds. Works in iMessage, WhatsApp, Instagram, and more.",
  metadataBase: new URL("https://hi-key.ai"),
  openGraph: {
    title: "hi-key — AI Images From Your Keyboard",
    description:
      "Generate AI images instantly from your keyboard in any app. Describe a scene, get 4 images in seconds.",
    url: "https://hi-key.ai",
    siteName: "hi-key",
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "hi-key — AI Images From Your Keyboard",
    description:
      "Generate AI images instantly from your keyboard in any app. Describe a scene, get 4 images in seconds.",
  },
  manifest: "/site.webmanifest",
  itunes: {
    appId: "YOUR_APP_STORE_ID",
  },
};

const jsonLdApp = {
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  name: "hi-key",
  description:
    "Generate AI images instantly from your keyboard in any app. Describe a scene, get 4 images in seconds.",
  operatingSystem: "iOS",
  applicationCategory: "UtilitiesApplication",
  offers: {
    "@type": "Offer",
    price: "0",
    priceCurrency: "USD",
  },
  downloadUrl: "https://apps.apple.com/app/hi-key/idYOUR_APP_ID",
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
  url: "https://hi-key.ai",
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
        text: "hi-key is an iOS keyboard that generates AI images from text prompts. You type a description of what you want to see, and hi-key creates 4 images in seconds — right inside any app you're already using.",
      },
    },
    {
      "@type": "Question",
      name: "How does hi-key work?",
      acceptedAnswer: {
        "@type": "Answer",
        text: 'Enable hi-key as a keyboard on your iPhone, switch to it in any app with a text field, type a description (e.g., "a cat wearing sunglasses on a beach"), and get 4 AI-generated images instantly. Tap any image to copy it to your clipboard.',
      },
    },
    {
      "@type": "Question",
      name: "Which apps does hi-key work in?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "hi-key works in any app that has a text input — iMessage, WhatsApp, Instagram DMs, Telegram, Slack, Notes, email, and more. It's a system keyboard, so it's available everywhere you type.",
      },
    },
    {
      "@type": "Question",
      name: "Is hi-key free?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Yes, hi-key is free to download and comes with 5 credits to start. Each credit generates 4 images. Subscription plans start at $4.99/month for more credits, and one-time credit packs are available from $2.99.",
      },
    },
    {
      "@type": "Question",
      name: "Is hi-key safe? Can it read my messages?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "hi-key only processes the prompts you type in the hi-key prompt bar. It never reads, stores, or sends your messages, passwords, or any other content. Prompts are processed securely and not stored after image generation.",
      },
    },
    {
      "@type": "Question",
      name: "What does the hi-key watermark mean?",
      acceptedAnswer: {
        "@type": "Answer",
        text: 'Images generated on the free and lower-tier plans include a small "hi-key" watermark. If you received an image with this watermark, someone used hi-key to create it. The Super plan ($12.99/month) removes watermarks.',
      },
    },
    {
      "@type": "Question",
      name: "How do I get more credits?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "You can subscribe to a monthly plan (Starter, Plus, or Super) for recurring credits, buy one-time credit packs, or invite friends with your referral code — you both get 5 bonus credits.",
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
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdFaq) }}
        />
        {children}
      </body>
    </html>
  );
}
