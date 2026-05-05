import type { Metadata } from "next";
import Link from "next/link";
import { Navbar } from "@/components/navbar";
import { Footer } from "@/components/footer";

export const metadata: Metadata = {
  title: "Privacy Policy | hi-key",
  description:
    "How hi-key handles your data. No accounts, no tracking, prompts and images deleted within 10 minutes.",
  alternates: { canonical: "https://hi-key.ai/privacy" },
  robots: { index: true, follow: true },
};

export default function PrivacyPage() {
  return (
    <div className="relative min-h-screen bg-background-root">
      <div className="dot-grid pointer-events-none fixed inset-0 opacity-40" />

      <div className="relative">
        <Navbar />
        <main className="mx-auto max-w-3xl px-6 py-16 sm:py-24">
          <header className="mb-12">
            <h1 className="font-heading text-4xl font-bold text-text-primary sm:text-5xl">
              Privacy policy
            </h1>
            <p className="mt-3 text-sm text-text-tertiary">Last updated: May 4, 2026</p>
          </header>

          <div className="prose-legal space-y-10 text-base leading-relaxed text-text-secondary">
            <Callout>
              <p className="text-text-primary font-medium">The short version</p>
              <ul className="mt-3 space-y-2">
                <li>No accounts. No email or password. No name or contact info required.</li>
                <li>
                  Your prompts and the images we generate are deleted from our servers within 10
                  minutes.
                </li>
                <li>We don&apos;t track you across other apps or websites.</li>
                <li>We don&apos;t sell or share your data for advertising. Ever.</li>
              </ul>
              <p className="mt-3">
                If that&apos;s enough, you can stop reading. If you want the details, they&apos;re
                below.
              </p>
            </Callout>

            <div className="space-y-3">
              <p>
                For the purposes of EU data-protection law (GDPR), the data controller of any
                personal data processed through hi-key is us: hi-key, run by{" "}
                <strong className="text-text-primary">Zafeirios Malafouris</strong>, based in Athens,
                Greece. For privacy questions, email <Mail />.
              </p>
            </div>

            <Section title="1. What data hi-key handles">
              <DataTable />
            </Section>

            <Section title="2. What we don't collect">
              <ul>
                <li>Your name, address, phone number, or any contact info (apart from the optional waitlist email).</li>
                <li>The content of your messages, conversations, browsing history, or contacts.</li>
                <li>Anything you type outside the hi-key prompt bar.</li>
                <li>Your location.</li>
                <li>Any advertising identifiers (such as Apple&apos;s IDFA). We don&apos;t use them.</li>
              </ul>
            </Section>

            <Section title="3. Where data goes (sub-processors)">
              <p>
                To run hi-key we rely on a few well-known services. None of them know who you are
                personally. Below is who handles what.
              </p>
              <SubprocessorsTable />
            </Section>

            <Section title="4. International transfers">
              <p>
                Some of these services are based in the United States (notably OpenAI, Replicate,
                RevenueCat, Resend). When data leaves the European Economic Area, we rely on
                the European Commission&apos;s Standard Contractual Clauses and each provider&apos;s
                certifications under the EU-U.S. Data Privacy Framework, where applicable. The data
                sent to AI providers is your prompt, without any identifier that links it to you.
              </p>
            </Section>

            <Section title="5. Why we're allowed to process this data (legal basis)">
              <ul>
                <li>
                  <strong className="text-text-primary">To provide the service</strong> (Article
                  6(1)(b) GDPR, contract performance), sending your prompts to AI providers,
                  storing your credit balance, processing purchases through Apple/RevenueCat.
                </li>
                <li>
                  <strong className="text-text-primary">Our legitimate interests</strong> (Article
                  6(1)(f) GDPR), anonymous analytics to improve the product, error logging to keep
                  things working.
                </li>
                <li>
                  <strong className="text-text-primary">Your consent</strong> (Article 6(1)(a) GDPR)
                  for the optional waitlist signup. You can ask us to delete your email at any time.
                </li>
              </ul>
            </Section>

            <Section title="6. Your rights">
              <p>Under GDPR you have the right to:</p>
              <ul>
                <li>Access the data we hold about you</li>
                <li>Correct inaccurate data</li>
                <li>Delete your data (the &quot;right to be forgotten&quot;)</li>
                <li>Object to processing based on legitimate interests</li>
                <li>Restrict processing in certain situations</li>
                <li>Receive a copy of data you&apos;ve provided in a portable format</li>
              </ul>
              <p>
                Because hi-key has no accounts, your only identifier is an anonymous user ID. You
                can find it inside the app under <em>Settings → User ID</em>. Email it to <Mail />{" "}
                with a brief description of what you&apos;d like, and we&apos;ll handle the request
                within 30 days (usually much faster).
              </p>
              <p>
                You also have the right to lodge a complaint with the Hellenic Data Protection Authority
                or with your local EU supervisory authority if you live elsewhere in the EEA.
              </p>
            </Section>

            <Section title="7. AI providers and your prompts">
              <p>
                The text you type into the hi-key prompt bar is sent to AI providers (such as OpenAI and Replicate) so they
                can process and generate images for you. They use your prompt for the duration of
                the request and may retain it briefly for abuse-prevention per their own policies.
                They don&apos;t receive any identifier that links the prompt to you.
              </p>
              <p>For reference, here are their privacy policies:</p>
              <ul>
                <li>
                  <a
                    href="https://openai.com/policies/privacy-policy"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-accent-lime hover:underline"
                  >
                    OpenAI privacy policy
                  </a>
                </li>
                <li>
                  <a
                    href="https://replicate.com/privacy"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-accent-lime hover:underline"
                  >
                    Replicate privacy policy
                  </a>
                </li>
              </ul>
            </Section>

            <Section title="8. Children">
              <p>
                hi-key isn&apos;t designed for users under 13, and the App Store age rating reflects
                that. If you believe a child under 13 has used hi-key, contact <Mail /> and
                we&apos;ll remove their data.
              </p>
            </Section>

            <Section title="9. Security">
              <p>
                We follow accepted security practices: HTTPS for all traffic, and access to our
                systems is restricted to what&apos;s needed to run them. The strongest protection,
                though, is what we don&apos;t store. hi-key has no accounts, so there are no passwords.
                Prompts and images are deleted from our servers within minutes of generation. And
                nothing in our systems is tied to your real-world identity. By design, there isn&apos;t
                much to expose.
              </p>
            </Section>

            <Section title="10. Changes to this policy">
              <p>
                If we change this policy in a way that materially affects your data, we&apos;ll
                post a notice in the app. The &quot;last updated&quot; date at the top will tell
                you when the document changed.
              </p>
            </Section>

            <Section title="11. Contact">
              <p>
                Email: <Mail />
                <br />
                Athens, Greece
              </p>
              <p className="text-text-tertiary">
                See also: <Link href="/terms" className="text-accent-lime hover:underline">Terms of Service</Link>.
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

function Mail() {
  return (
    <a href="mailto:support@hi-key.ai" className="text-accent-lime hover:underline">
      support@hi-key.ai
    </a>
  );
}

function DataTable() {
  const rows: { data: string; why: string; notes: string }[] = [
    {
      data: "An anonymous user identifier",
      why: "To keep track of your credit balance and subscription status.",
      notes: "A random string. No name, email, or phone attached.",
    },
    {
      data: "Your subscription and credit history",
      why: "To know how many credits you have left and what you've purchased through Apple.",
      notes: "Linked to the anonymous user identifier, not to your Apple ID or any personal info.",
    },
    {
      data: "The text prompts you type",
      why: "Sent to AI providers to generate images.",
      notes: "Deleted from our servers within 10 minutes of generation.",
    },
    {
      data: "The images we generate for you",
      why: "Delivered to your keyboard so you can copy and share them.",
      notes: "Deleted from our servers within 10 minutes of generation.",
    },
    {
      data: "Anonymous usage events (e.g. \"opened referral screen\")",
      why: "To understand what works and improve the app.",
      notes: "Not linked to you personally.",
    },
    {
      data: "Your name (optional)",
      why: "If you set one in Settings, part of it appears in your referral code so a friend can recognise it.",
      notes: "The referral code contains part of your name and is shared only if you generate one.",
    },
    {
      data: "Your referral code (if you create one)",
      why: "To grant credits to you and a friend who uses it.",
      notes: "Linked to the anonymous user identifier.",
    },
    {
      data: "Your email address (waitlist only)",
      why: "If you signed up on the website before launch, we email you when hi-key is ready.",
      notes: "Deleted after the launch email is sent.",
    },
    {
      data: "Crash and error reports",
      why: "To diagnose bugs.",
      notes: "Anonymous device, OS, and app data only. No personal data is included. Typically retained for 90 days by our error-tracking provider.",
    },
  ];

  return (
    <>
      <p className="text-text-secondary">
        Unless noted below, data is kept for as long as it&apos;s needed to run hi-key. You can ask us
        to delete your data at any time, see <em>Your rights</em>.
      </p>
      <div className="overflow-x-auto rounded-2xl border border-divider">
        <table className="w-full text-left text-sm">
          <thead className="bg-surface-secondary text-text-primary">
            <tr>
              <th className="px-4 py-3 font-semibold">Data</th>
              <th className="px-4 py-3 font-semibold">Why we have it</th>
              <th className="px-4 py-3 font-semibold">Notes</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-divider bg-surface-primary">
            {rows.map((row) => (
              <tr key={row.data}>
                <td className="px-4 py-3 align-top text-text-primary">{row.data}</td>
                <td className="px-4 py-3 align-top">{row.why}</td>
                <td className="px-4 py-3 align-top">{row.notes}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}

function SubprocessorsTable() {
  const rows: { service: string; purpose: string; region: string }[] = [
    { service: "Supabase", purpose: "Anonymous user record, credit balance, and usage metadata (e.g. which models are used, generation timing, settings)", region: "Central EU (Frankfurt)" },
    { service: "Cloudflare R2", purpose: "Temporary image storage", region: "EU" },
    { service: "Upstash QStash", purpose: "Background job queue", region: "Central EU (Frankfurt)" },
    { service: "OpenAI", purpose: "Prompt processing (proofreading, autocomplete, enhancement)", region: "United States" },
    { service: "Replicate", purpose: "Runs the AI models that produce the images", region: "United States" },
    { service: "RevenueCat", purpose: "Subscription and credit status", region: "United States" },
    { service: "PostHog", purpose: "Anonymous product analytics", region: "EU" },
    { service: "Resend", purpose: "Sends the waitlist confirmation email (waitlist users only)", region: "United States" },
    { service: "Sentry", purpose: "Crash and error reports", region: "EU" },
    { service: "Vercel", purpose: "Hosts hi-key.ai and the backend API used by the iOS app", region: "Central EU (Frankfurt)" },
  ];

  return (
    <div className="overflow-x-auto rounded-2xl border border-divider">
      <table className="w-full text-left text-sm">
        <thead className="bg-surface-secondary text-text-primary">
          <tr>
            <th className="px-4 py-3 font-semibold">Service</th>
            <th className="px-4 py-3 font-semibold">What they do for hi-key</th>
            <th className="px-4 py-3 font-semibold">Region</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-divider bg-surface-primary">
          {rows.map((row) => (
            <tr key={row.service}>
              <td className="px-4 py-3 align-top text-text-primary">{row.service}</td>
              <td className="px-4 py-3 align-top">{row.purpose}</td>
              <td className="px-4 py-3 align-top">{row.region}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
