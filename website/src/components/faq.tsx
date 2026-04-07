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
      "hi-key is an iOS keyboard that generates AI images from text prompts. Switch to it like you switch to the emoji keyboard, type a description, and hi-key creates 4 images in seconds. Right there, inside any app you're using.",
  },
  {
    question: "How does hi-key work?",
    answer:
      "Enable hi-key as a keyboard on your iPhone once and it becomes available in all your apps. Switch to it using the 🌐 icon, describe a scene, and you'll have 4 images in seconds. Tap any result to copy it, then paste it wherever you want.",
  },
  {
    question: "Which apps does hi-key work in?",
    answer:
      "hi-key works in any app with a text input, like iMessage, WhatsApp, Instagram DMs, Telegram, Slack, Notes, email, and more. It's a system keyboard, so it's available everywhere you type.",
  },
  {
    question: "Can I try hi-key for free?",
    answer:
      "Absolutely. There's a free trial to get started. Also, when you refer a friend, you both get free credits. And when you decide you want more, one-off credit packs and subscriptions start under a dollar.",
  },
  {
    question: "Is hi-key safe? Can it read my messages?",
    answer:
      "hi-key only processes the prompts you type in the hi-key prompt bar. It never reads, stores, or sends your messages, passwords, or any other content. Prompts are processed securely and used solely to generate your images.",
  },
  {
    question: 'What does "double credits forever" mean for early members?',
    answer:
      "Everyone who joins the waitlist gets 2× credits on every purchase, forever. Buy 50 credits, get 100. Buy 100, get 200. It applies to subscriptions and one-time packs, and it never expires. Our way of saying thanks for believing in hi-key early.",
  },
  {
    question:
      "I don't like spam, accounts, or subscriptions. Is hi-key for me?",
    answer:
      "hi-key is exactly for you. There are no accounts. Just download and go. Joining the waitlist means one email when the app is ready, nothing more. When you want more credits, there are one-time packs with no recurring costs. And if you do subscribe, you can cancel anytime. hi-key is fun to have, not a commitment.",
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
