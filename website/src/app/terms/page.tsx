import type { Metadata } from "next";
import Link from "next/link";
import { Navbar } from "@/components/navbar";
import { Footer } from "@/components/footer";

export const metadata: Metadata = {
  title: "Terms of Service | hi-key",
  description:
    "The rules of using hi-key. Plain language, with the legal essentials.",
  alternates: { canonical: "https://hi-key.ai/terms" },
  robots: { index: true, follow: true },
};

export default function TermsPage() {
  return (
    <div className="relative min-h-screen bg-background-root">
      <div className="dot-grid pointer-events-none fixed inset-0 opacity-40" />

      <div className="relative">
        <Navbar />
        <main className="mx-auto max-w-3xl px-6 py-16 sm:py-24">
          <header className="mb-12">
            <h1 className="font-heading text-4xl font-bold text-text-primary sm:text-5xl">
              Terms of service
            </h1>
            <p className="mt-3 text-sm text-text-tertiary">Last updated: May 4, 2026</p>
          </header>

          <div className="space-y-10 text-base leading-relaxed text-text-secondary">
            <Callout>
              <p>
                These terms cover what you can expect from hi-key and what we expect from you. They
                form a contract between you and us, hi-key. By downloading or using hi-key, you
                agree to them.
              </p>
            </Callout>

            <div className="space-y-3">
              <p>
                Throughout this document, &quot;we&quot;, &quot;us&quot;, and &quot;our&quot; mean
                hi-key, run by{" "}
                <strong className="text-text-primary">Zafeirios Malafouris</strong>, based in Athens,
                Greece.
              </p>
            </div>

            <Section title="1. What hi-key is">
              <p>
                hi-key is an iOS keyboard extension that turns text prompts into AI-generated
                images. You type a prompt, hi-key sends it to AI providers, and they generate
                images that you can copy and share.
              </p>
            </Section>

            <Section title="2. Your right to use hi-key">
              <p>
                We grant you a personal, non-transferable, non-exclusive licence to install and use
                hi-key on iOS devices linked to your Apple ID, for as long as you comply with these
                terms. You can use the app for personal or commercial purposes. You don&apos;t get
                any other rights in the app or its underlying technology.
              </p>
            </Section>

            <Section title="3. Account, age, and access">
              <p>
                hi-key doesn&apos;t require an account. By using it, you confirm that you are at
                least 13 years old, or the minimum age required in your country to consent to the
                processing of personal data, whichever is higher.
              </p>
              <p>
                The keyboard extension requires &quot;Full Access&quot; in iOS Settings so it can
                connect to our servers. We only process the prompts you type in the hi-key prompt
                bar, never anything else you type.
              </p>
            </Section>

            <Section title="4. Subscriptions, credits, and one-time purchases">
              <p>hi-key uses a credit system. Credits let you generate images. You can buy credits in two ways:</p>
              <ul>
                <li>
                  <strong className="text-text-primary">Subscriptions</strong>: auto-renewing plans
                  that give you a fresh allowance of credits each renewal cycle.
                </li>
                <li>
                  <strong className="text-text-primary">Credit packs</strong>: one-time purchases
                  that add credits to your balance.
                </li>
              </ul>
              <p>
                Prices, credit amounts, and renewal periods are shown in the App Store and on the
                in-app purchase screen at the moment of purchase. The terms in effect for any
                purchase are the ones displayed at the moment of purchase.
              </p>
              <p>
                Subscriptions automatically renew at the end of each cycle unless you cancel at
                least 24 hours before the cycle ends. Renewal is charged within 24 hours of the
                cycle ending. You can manage and cancel subscriptions any time from your Apple
                ID&apos;s Subscription settings on your iPhone.
              </p>
              <p>
                If we offer a free trial, any unused portion of the trial is forfeited when you
                start a paid subscription.
              </p>
              <p>
                Some product details (tier names, prices, credit allowances, trial lengths) may
                change over time as we improve the offering. We won&apos;t change the terms of an
                already-active subscription cycle without notice.
              </p>
            </Section>

            <Section title="5. Refunds">
              <p>
                All purchases go through Apple. Refund requests are handled by Apple at{" "}
                <a
                  href="https://reportaproblem.apple.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-accent-lime hover:underline"
                >
                  reportaproblem.apple.com
                </a>
                , under their refund policy. EU statutory consumer rights apply where they grant
                you stronger protection.
              </p>
            </Section>

            <Section title="6. Your prompts and the images you generate">
              <p>
                You&apos;re responsible for the prompts you write and for how you use the images
                hi-key generates. As far as we&apos;re concerned:
              </p>
              <ul>
                <li>You own (or have permission to use) the prompts you type.</li>
                <li>You can use the generated images for any purpose, including commercial use.</li>
                <li>
                  AI is imperfect. Outputs can be inaccurate, biased, or weird. They might also
                  resemble other works produced by similar models. Whether AI-generated images are
                  eligible for copyright protection depends on the laws of your country. We make no
                  claim of ownership over them.
                </li>
                <li>
                  hi-key does not store generated images for you. If you want to keep an image,
                  copy and share it before closing the keyboard. The same image is removed from our
                  servers in less than an hour after generation.
                </li>
              </ul>
            </Section>

            <Section title="7. Acceptable use">
              <p>You agree not to use hi-key to produce or distribute:</p>
              <ul>
                <li>
                  Content that constitutes a criminal offence under EU law or the law of your
                  country, including (without limitation) child sexual abuse material.
                </li>
                <li>Content that incites violence or terrorism.</li>
              </ul>
              <p>
                Beyond that, you&apos;re free to create. The AI providers we use have their own
                usage policies that may restrict certain content. If their filters block a prompt,
                hi-key will let you know.
              </p>
              <p>
                If we have reason to believe you&apos;re using hi-key in ways that violate these
                acceptable-use rules, we may suspend your access without notice.
              </p>
            </Section>

            <Section title="8. Third-party services">
              <p>
                hi-key relies on third-party services to function, including Apple (App Store and
                in-app purchases), OpenAI, Replicate, Supabase, Cloudflare, RevenueCat, and others
                listed in our <Link href="/privacy" className="text-accent-lime hover:underline">Privacy Policy</Link>.
                Their own terms govern how they handle the data we send them. We don&apos;t
                control their availability and we&apos;re not responsible for their actions, but we
                choose them carefully.
              </p>
            </Section>

            <Section title="9. Service availability">
              <p>
                hi-key is provided &quot;as is&quot;. We do our best to keep it running, but we
                don&apos;t guarantee uninterrupted, error-free, or always-available service. We may
                add, change, or remove features, or stop offering hi-key entirely.
              </p>
            </Section>

            <Section title="10. Disclaimers">
              <p>
                To the extent permitted by law, hi-key is provided without warranties of any kind,
                express or implied, including warranties of merchantability, fitness for a
                particular purpose, accuracy of AI outputs, and non-infringement.
              </p>
            </Section>

            <Section title="11. Limitation of liability">
              <p>
                To the extent permitted by law, our total liability to you for any claim related to
                hi-key is limited to the amount you paid us (through Apple) for hi-key in the 12
                months before the claim arose, or €50, whichever is greater. We&apos;re not liable
                for indirect, incidental, special, or consequential damages, or for loss of data,
                profits, or goodwill.
              </p>
              <p>
                Nothing in these terms limits liability for fraud, gross negligence, death, or
                personal injury caused by negligence, or any other liability that can&apos;t be
                limited under Greek or EU law. Your statutory rights as a consumer are
                unaffected.
              </p>
            </Section>

            <Section title="12. Termination">
              <p>
                You can stop using hi-key at any time by deleting it. We may terminate or suspend
                your access if you breach these terms. Sections that by their nature should
                survive termination (such as ownership, disclaimers, limitation of liability,
                governing law) will survive.
              </p>
            </Section>

            <Section title="13. Privacy">
              <p>
                Your privacy is covered by our{" "}
                <Link href="/privacy" className="text-accent-lime hover:underline">
                  Privacy Policy
                </Link>
                . Please read it.
              </p>
            </Section>

            <Section title="14. Governing law and disputes">
              <p>
                These terms are governed by the law of Greece. Any dispute will be heard by the
                courts of Athens, Greece. If you&apos;re a consumer based elsewhere in the EU,
                mandatory consumer-protection laws of your country of residence still apply, and
                you can also bring proceedings in your local courts.
              </p>
              <p>
                The European Commission also offers an online dispute-resolution platform at{" "}
                <a
                  href="https://ec.europa.eu/consumers/odr"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-accent-lime hover:underline"
                >
                  ec.europa.eu/consumers/odr
                </a>
                .
              </p>
            </Section>

            <Section title="15. Apple-specific terms">
              <p>
                Because hi-key is distributed through Apple&apos;s App Store, you also agree to
                the following Apple-specific terms, which override anything inconsistent in this
                document:
              </p>
              <ul>
                <li>
                  These terms are between you and us only, not with Apple. Apple is not responsible
                  for hi-key or its content.
                </li>
                <li>
                  The licence in Section 2 is limited to a non-transferable licence to use hi-key on
                  Apple-branded products you own or control, as permitted by the App Store Terms of
                  Service.
                </li>
                <li>
                  We are solely responsible for providing maintenance and support for hi-key. Apple
                  has no obligation to provide any maintenance or support.
                </li>
                <li>
                  If hi-key fails to conform to any applicable warranty, you may notify Apple, and
                  Apple may refund the purchase price. To the maximum extent permitted by law,
                  Apple has no other warranty obligation for hi-key, and any other claims, losses,
                  liabilities, damages, costs, or expenses attributable to a failure to conform to a
                  warranty are our sole responsibility.
                </li>
                <li>
                  We, not Apple, are responsible for addressing any claims you or any third party
                  has relating to hi-key, including product-liability claims, claims that hi-key
                  fails to conform to any legal or regulatory requirement, and claims arising under
                  consumer-protection or similar legislation.
                </li>
                <li>
                  In the event of any third-party claim that hi-key or your possession and use of
                  hi-key infringes that third party&apos;s intellectual property rights, we (not
                  Apple) will be solely responsible for the investigation, defence, settlement, and
                  discharge of any such claim.
                </li>
                <li>
                  You represent that you are not located in a country subject to a U.S. Government
                  embargo, or designated by the U.S. Government as a &quot;terrorist supporting&quot;
                  country, and that you are not listed on any U.S. Government list of prohibited or
                  restricted parties.
                </li>
                <li>
                  Apple and Apple&apos;s subsidiaries are third-party beneficiaries of these terms,
                  and upon your acceptance of these terms, Apple has the right (and is deemed to
                  have accepted the right) to enforce these terms against you as a third-party
                  beneficiary.
                </li>
              </ul>
            </Section>

            <Section title="16. Changes to these terms">
              <p>
                If we change these terms in a way that affects your rights, we&apos;ll let you know
                in the app. Continued use after the change means you accept the new terms.
              </p>
            </Section>

            <Section title="17. Contact">
              <p>
                Email:{" "}
                <a href="mailto:support@hi-key.ai" className="text-accent-lime hover:underline">
                  support@hi-key.ai
                </a>
                <br />
                Athens, Greece
              </p>
              <p className="text-text-tertiary">
                See also:{" "}
                <Link href="/privacy" className="text-accent-lime hover:underline">
                  Privacy Policy
                </Link>
                .
              </p>
            </Section>
          </div>
        </main>
        <Footer />
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="space-y-4">
      <h2 className="font-heading text-xl font-semibold text-text-primary sm:text-2xl">{title}</h2>
      <div className="space-y-3 [&_ul]:list-disc [&_ul]:space-y-2 [&_ul]:pl-6">{children}</div>
    </section>
  );
}

function Callout({ children }: { children: React.ReactNode }) {
  return (
    <div className="rounded-2xl border border-divider bg-surface-primary p-6">{children}</div>
  );
}
