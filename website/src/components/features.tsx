"use client";

import { FadeUp } from "./fade-up";
import { useLottiePlayOnce } from "@/hooks/use-lottie-play-once";

const hLineStyle = {
  height: 1,
  background:
    "linear-gradient(to right, transparent, var(--divider) 20%, var(--divider) 80%, transparent)",
} as const;

const vLineEdgeStyle = {
  width: 1,
  background:
    "linear-gradient(to bottom, transparent, var(--divider) 15%, var(--divider) 85%, transparent)",
} as const;

const vLineSolidStyle = {
  width: 1,
  background: "var(--divider)",
} as const;

/* ── Tweak points ──────────────────────────────────────────────
 *  Header padding:  `py-6` on line ~120  → try py-4 / py-8
 *  Row height:      `py-10` on line ~140 → try py-8 / py-12 / py-16
 * ──────────────────────────────────────────────────────────── */

const features = [
  {
    title: "4 images in seconds",
    description:
      "Fast enough to send in the moment. Describe and get results instantly.",
    animationPath: "/animations/features-fast.json",
    aspect: "aspect-[4/3]" as const,
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
    title: "Works in any app",
    description:
      "iMessage, WhatsApp, Instagram, Telegram, Slack, email. hi-key is a system keyboard, available everywhere you type.",
    animationPath: "/animations/features-allapps.json",
    aspect: "aspect-square" as const,
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
    title: "Your privacy, respected",
    description:
      "hi-key only processes your prompts — never your messages, passwords, or personal data. Prompts are not stored after generation.",
    animationPath: null,
    aspect: "aspect-square" as const,
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

function FeatureLottie({ path, aspect = "aspect-square" }: { path: string | null; aspect?: string }) {
  const { containerRef, isLoaded } = useLottiePlayOnce(path);

  if (!path) return <div className={`w-full max-w-md ${aspect}`} />;

  return (
    <div
      className={`w-full max-w-md ${aspect} transition-opacity duration-500 ${
        isLoaded ? "opacity-100" : "opacity-0"
      }`}
    >
      <div ref={containerRef} className="h-full w-full" />
    </div>
  );
}

export function Features() {
  return (
    <section className="relative px-6 py-24 overflow-hidden" id="features">
      <div className="relative mx-auto max-w-6xl">
        {/* Left & right edge vertical lines (desktop only, fade at edges) */}
        <div
          className="hidden lg:block absolute top-0 bottom-0 left-0"
          style={vLineEdgeStyle}
        />
        <div
          className="hidden lg:block absolute top-0 bottom-0 right-0"
          style={vLineEdgeStyle}
        />

        {/* ── Header ── */}
        <div style={hLineStyle} />

        <FadeUp>
          {/* Header padding — tweak: py-6 (tight) / py-8 / py-10 */}
          <div className="py-6">
            <h2 className="text-center font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
              Right there when it hits you
            </h2>
            <p className="mx-auto mt-4 max-w-xl text-center text-lg text-text-secondary">
              Fast, seamless, and private by design.
            </p>
          </div>
        </FadeUp>

        <div style={hLineStyle} />

        {/* ── Feature rows ── */}
        <div className="flex flex-col">
          {features.map((feature, i) => {
            const textLeft = i % 2 === 1;
            const vLinePos = textLeft ? "66.66%" : "33.33%";

            return (
              <div key={feature.title}>
                {i > 0 && <div style={hLineStyle} />}
                {/* Row wrapper — relative so the vertical line is scoped to this row */}
                <div className="relative">
                  {/* Per-row vertical line (desktop only, solid) */}
                  <div
                    className="hidden lg:block absolute top-0 bottom-0"
                    style={{ ...vLineSolidStyle, left: vLinePos }}
                  />

                  <FadeUp delay={i * 120}>
                    {/* Row height — tweak: py-8 / py-12 / py-16 */}
                    <div
                      className={`flex flex-col items-center gap-8 px-4 py-8 lg:items-end lg:gap-16 lg:px-8 ${
                        textLeft ? "lg:flex-row" : "lg:flex-row-reverse"
                      }`}
                    >
                      {/* Animation side (2/3) */}
                      <div className="flex w-full items-center justify-center lg:w-2/3">
                        <FeatureLottie path={feature.animationPath} aspect={feature.aspect} />
                      </div>

                      {/* Text side (1/3), bottom-aligned on desktop */}
                      <div className={`flex w-full flex-col items-start text-left lg:w-1/3 ${
                        textLeft ? "lg:pl-6" : "lg:pr-6"
                      }`}>
                        <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-surface-secondary text-accent-lime">
                          {feature.icon}
                        </div>
                        <h3 className="mt-4 font-heading text-2xl font-bold text-text-primary">
                          {feature.title}
                        </h3>
                        <p className="mt-2 max-w-md text-base leading-relaxed text-text-secondary">
                          {feature.description}
                        </p>
                      </div>
                    </div>
                  </FadeUp>
                </div>
              </div>
            );
          })}

          {/* Horizontal line after last feature */}
          <div style={hLineStyle} />
        </div>
      </div>
    </section>
  );
}
