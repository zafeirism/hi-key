import { FadeUp } from "./fade-up";

const steps = [
  {
    number: "1",
    title: "Enable the keyboard",
    description:
      "Add hi-key in your iPhone keyboard settings. Takes 30 seconds.",
  },
  {
    number: "2",
    title: "Type what you want to see",
    description:
      'Switch to hi-key in any app and describe a scene — like "a cat in sunglasses on a beach".',
  },
  {
    number: "3",
    title: "Copy and send",
    description:
      "Get 4 AI-generated images instantly. Tap to copy, paste anywhere.",
  },
];

export function HowItWorks() {
  return (
    <section className="px-6 py-24" id="how-it-works">
      <div className="mx-auto max-w-4xl">
        <FadeUp>
          <h2 className="text-center font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            How it works
          </h2>
        </FadeUp>
        <div className="mt-16 grid gap-10 sm:grid-cols-3">
          {steps.map((step, i) => (
            <FadeUp key={step.number} delay={i * 100}>
              <div className="text-center">
                <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-accent-lime font-heading text-lg font-bold text-background-root">
                  {step.number}
                </div>
                <h3 className="mt-5 font-heading text-lg font-semibold text-text-primary">
                  {step.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-text-secondary">
                  {step.description}
                </p>
              </div>
            </FadeUp>
          ))}
        </div>
      </div>
    </section>
  );
}
