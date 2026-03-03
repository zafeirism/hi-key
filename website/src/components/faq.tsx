import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { FadeUp } from "./fade-up";

const faqs = [
  {
    question: "What is hi-key?",
    answer:
      "hi-key is an iOS keyboard that generates AI images from text prompts. You type a description of what you want to see, and hi-key creates 4 images in seconds — right inside any app you're already using.",
  },
  {
    question: "How does hi-key work?",
    answer:
      'Enable hi-key as a keyboard on your iPhone, switch to it in any app with a text field, type a description (e.g., "a cat wearing sunglasses on a beach"), and get 4 AI-generated images instantly. Tap any image to copy it to your clipboard.',
  },
  {
    question: "Which apps does hi-key work in?",
    answer:
      "hi-key works in any app that has a text input — iMessage, WhatsApp, Instagram DMs, Telegram, Slack, Notes, email, and more. It's a system keyboard, so it's available everywhere you type.",
  },
  {
    question: "Is hi-key free?",
    answer:
      "Yes, hi-key is free to download and comes with 5 credits to start. Each credit generates 4 images. Subscription plans start at $4.99/month for more credits, and one-time credit packs are available from $2.99.",
  },
  {
    question: "Is hi-key safe? Can it read my messages?",
    answer:
      "hi-key only processes the prompts you type in the hi-key prompt bar. It never reads, stores, or sends your messages, passwords, or any other content. Prompts are processed securely and not stored after image generation.",
  },
  {
    question: "What does the hi-key watermark mean?",
    answer:
      'Images generated on the free and lower-tier plans include a small "hi-key" watermark. If you received an image with this watermark, someone used hi-key to create it. The Super plan ($12.99/month) removes watermarks.',
  },
  {
    question: "How do I get more credits?",
    answer:
      "You can subscribe to a monthly plan (Starter, Plus, or Super) for recurring credits, buy one-time credit packs, or invite friends with your referral code — you both get 5 bonus credits.",
  },
];

export function FAQ() {
  return (
    <section className="px-6 py-24" id="faq">
      <div className="mx-auto max-w-2xl">
        <FadeUp>
          <h2 className="text-center font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            Frequently asked questions
          </h2>
        </FadeUp>
        <FadeUp delay={100}>
          <Accordion type="single" collapsible className="mt-14">
            {faqs.map((faq, i) => (
              <AccordionItem
                key={i}
                value={`item-${i}`}
                className="border-divider"
              >
                <AccordionTrigger className="text-base font-medium text-text-primary hover:no-underline hover:text-accent-lime">
                  {faq.question}
                </AccordionTrigger>
                <AccordionContent className="text-sm leading-relaxed text-text-secondary">
                  {faq.answer}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </FadeUp>
      </div>
    </section>
  );
}
