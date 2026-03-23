"use client";

import { useCallback } from "react";
import { LazyVideo } from "./lazy-video";
import { useCarousel } from "@/hooks/use-carousel";

const steps = [
  {
    src: "/twocups-switch.mp4",
    poster: "/twocups-switch-poster.jpg",
    title: "Switch to hi-key",
    description:
      "Long-press the globe icon and select hi-key. One tap and you\u2019re ready to create.",
  },
  {
    src: "/twocups-getresults.mp4",
    poster: "/twocups-getresults-poster.jpg",
    title: "Describe a scene",
    description:
      "Type a quick prompt. A vibe, a scene, an idea. Get 4 images back in seconds.",
  },
  {
    src: "/twocups-copypaste.mp4",
    poster: "/twocups-copypaste-poster.jpg",
    title: "Copy, paste, done",
    description:
      "Tap the image you like, paste it into the conversation. No saving, no app switching.",
  },
];

export function HowItWorks() {
  const {
    activeStep,
    displayProgress,
    onVideoEnded,
    goToStep,
    setVideoProgress,
    setStepDuration,
    swipeHandlers,
  } = useCarousel({ stepCount: steps.length });

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      let next = activeStep;
      if (e.key === "ArrowRight" || e.key === "ArrowDown") {
        next = (activeStep + 1) % steps.length;
      } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
        next = (activeStep - 1 + steps.length) % steps.length;
      } else if (e.key === "Home") {
        next = 0;
      } else if (e.key === "End") {
        next = steps.length - 1;
      } else {
        return;
      }
      e.preventDefault();
      goToStep(next);
    },
    [activeStep, goToStep]
  );

  return (
    <section
      className="px-6 py-28 sm:py-32"
      id="how-it-works"
      role="region"
      aria-label="How to use hi-key"
    >
      {/* Tweak max-w to control overall section width: max-w-4xl (56rem), max-w-5xl (64rem), max-w-6xl (72rem) */}
      <div className="mx-auto max-w-5xl">
        {/* Header */}
        <div className="text-center">
          <h2 className="font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            Easier than opening an app
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-lg text-text-secondary">
            Switch keyboard, describe, paste. Without ever leaving the
            conversation.
          </p>
        </div>

        {/* Desktop layout */}
        {/* Tweak lg:gap-* to control space between text and video: gap-12 (3rem), gap-16 (4rem), gap-20 (5rem) */}
        <div className="mt-16 hidden lg:grid lg:grid-cols-[1fr_1fr] lg:items-center lg:gap-16">
          {/* Left: step list */}
          <div role="tablist" aria-label="How it works steps" onKeyDown={handleKeyDown} className="max-w-sm">
            {steps.map((step, i) => {
              const isActive = i === activeStep;
              return (
                <button
                  key={i}
                  role="tab"
                  id={`hiw-tab-${i}`}
                  aria-selected={isActive}
                  aria-controls="hiw-panel"
                  tabIndex={isActive ? 0 : -1}
                  onClick={() => goToStep(i)}
                  className="group block w-full cursor-pointer py-5 text-left"
                >
                  {/* Progress bar */}
                  <div className="mb-3 h-0.5 w-full rounded-full bg-divider overflow-hidden">
                    <div
                      className="h-full rounded-full bg-accent-lime"
                      style={{
                        width: isActive ? `${displayProgress * 100}%` : "0%",
                      }}
                    />
                  </div>
                  <h3
                    className={`font-heading text-lg font-semibold transition-colors duration-300 ${
                      isActive ? "text-text-primary" : "text-text-tertiary"
                    }`}
                  >
                    {step.title}
                  </h3>
                  <p
                    className={`mt-1 text-sm leading-relaxed transition-colors duration-300 ${
                      isActive ? "text-text-secondary" : "text-text-tertiary"
                    }`}
                  >
                    {step.description}
                  </p>
                </button>
              );
            })}
          </div>

          {/* Right: video */}
          <div
            role="tabpanel"
            id="hiw-panel"
            aria-labelledby={`hiw-tab-${activeStep}`}
            className="flex justify-center"
          >
            <div className="relative aspect-square w-full max-w-[420px] overflow-hidden rounded-4xl">
              {steps.map((step, i) => (
                <div
                  key={i}
                  className={`absolute inset-0 transition-opacity duration-300 ${
                    i === activeStep ? "opacity-100" : "opacity-0 pointer-events-none"
                  }`}
                >
                  <LazyVideo
                    src={step.src}
                    poster={step.poster}
                    playing={i === activeStep}
                    loop={false}
                    onEnded={i === activeStep ? onVideoEnded : undefined}
                    onTimeUpdate={i === activeStep ? setVideoProgress : undefined}
                    onDuration={(d) => setStepDuration(i, d)}
                    className="aspect-square"
                    aria-hidden="true"
                  />
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Mobile layout */}
        <div className="mt-12 lg:hidden">
          {/* Video */}
          <div className="mx-auto aspect-square max-w-[360px] overflow-hidden rounded-4xl" {...swipeHandlers}>
            <div
              role="tabpanel"
              id="hiw-panel-mobile"
              aria-labelledby={`hiw-tab-mobile-${activeStep}`}
              className="relative h-full w-full"
            >
              {steps.map((step, i) => (
                <div
                  key={i}
                  className={`absolute inset-0 transition-opacity duration-300 ${
                    i === activeStep ? "opacity-100" : "opacity-0 pointer-events-none"
                  }`}
                >
                  <LazyVideo
                    src={step.src}
                    poster={step.poster}
                    playing={i === activeStep}
                    loop={false}
                    onEnded={i === activeStep ? onVideoEnded : undefined}
                    onTimeUpdate={i === activeStep ? setVideoProgress : undefined}
                    onDuration={(d) => setStepDuration(i, d)}
                    className="aspect-square"
                    aria-hidden="true"
                  />
                </div>
              ))}
            </div>
          </div>

          {/* Dot indicators */}
          <div
            role="tablist"
            aria-label="How it works steps"
            className="mt-6 flex justify-center gap-2"
            onKeyDown={handleKeyDown}
          >
            {steps.map((step, i) => {
              const isActive = i === activeStep;
              return (
                <button
                  key={i}
                  role="tab"
                  id={`hiw-tab-mobile-${i}`}
                  aria-selected={isActive}
                  aria-controls="hiw-panel-mobile"
                  aria-label={step.title}
                  tabIndex={isActive ? 0 : -1}
                  onClick={() => goToStep(i)}
                  className={`relative h-1.5 overflow-hidden rounded-full transition-all duration-300 ${
                    isActive ? "w-10 bg-divider" : "w-4 bg-divider"
                  }`}
                >
                  {isActive && (
                    <div
                      className="absolute inset-y-0 left-0 rounded-full bg-accent-lime"
                      style={{ width: `${displayProgress * 100}%` }}
                    />
                  )}
                </button>
              );
            })}
          </div>

          {/* Step text */}
          <div className="relative mt-6 overflow-hidden text-center" style={{ minHeight: "5rem" }}>
            {steps.map((step, i) => {
              const isActive = i === activeStep;
              return (
                <div
                  key={i}
                  className={`transition-all duration-300 ${
                    isActive
                      ? "relative opacity-100 translate-x-0"
                      : "absolute inset-0 opacity-0 translate-x-4 pointer-events-none"
                  }`}
                >
                  <h3 className="font-heading text-lg font-semibold text-text-primary">
                    {step.title}
                  </h3>
                  <p className="mt-1 text-sm leading-relaxed text-text-secondary">
                    {step.description}
                  </p>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
