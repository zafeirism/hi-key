import { FadeUp } from "./fade-up";

const features = [
  {
    title: "Works in any app",
    description:
      "iMessage, WhatsApp, Instagram, Telegram, Slack, email — hi-key is a system keyboard, available everywhere you type.",
    // TODO: Replace with Lottie animation, video, or image
    mediaBg: "from-accent-lime/10 to-accent-lime/5",
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth={1.5}
        className="h-7 w-7"
        aria-hidden="true"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-2.25a2.25 2.25 0 0 1-2.25-2.25v-2.25Z"
        />
      </svg>
    ),
  },
  {
    title: "4 images in seconds",
    description:
      "Fast enough to send in the moment. No waiting, no app switching — describe and get results instantly.",
    mediaBg: "from-accent-purple/10 to-accent-purple/5",
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth={1.5}
        className="h-7 w-7"
        aria-hidden="true"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="m3.75 13.5 10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75Z"
        />
      </svg>
    ),
  },
  {
    title: "Your privacy, respected",
    description:
      "hi-key only processes your prompts — never your messages, passwords, or personal data. Prompts are not stored after generation.",
    mediaBg: "from-status-info/10 to-status-info/5",
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth={1.5}
        className="h-7 w-7"
        aria-hidden="true"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z"
        />
      </svg>
    ),
  },
];

export function Features() {
  return (
    <section className="px-6 py-24" id="features">
      <div className="mx-auto max-w-5xl">
        <FadeUp>
          <h2 className="text-center font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            Why hi-key
          </h2>
        </FadeUp>
        <div className="mt-16 grid gap-6 sm:grid-cols-3">
          {features.map((feature, i) => (
            <FadeUp key={feature.title} delay={i * 120}>
              <div className="group relative flex h-full flex-col overflow-hidden rounded-2xl bg-surface-primary transition-transform duration-250 hover:-translate-y-1">
                {/* Media area — replace gradient with Lottie/video/image */}
                <div
                  className={`flex h-48 items-center justify-center bg-gradient-to-b ${feature.mediaBg}`}
                >
                  <div className="text-text-tertiary opacity-40">
                    {/* Placeholder for media content */}
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth={1}
                      className="h-16 w-16"
                      aria-hidden="true"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z"
                      />
                    </svg>
                  </div>
                </div>

                {/* Text content */}
                <div className="flex flex-1 flex-col p-6">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-surface-secondary text-accent-lime">
                    {feature.icon}
                  </div>
                  <h3 className="mt-4 font-heading text-lg font-semibold text-text-primary">
                    {feature.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-text-secondary">
                    {feature.description}
                  </p>
                </div>
              </div>
            </FadeUp>
          ))}
        </div>
      </div>
    </section>
  );
}
