"use client";

import { useRef, useEffect, useState } from "react";
import { useScrollProgress } from "@/hooks/use-scroll-progress";
import type { AnimationItem } from "lottie-web";

// Total frames — update when you re-export from Jitter
const TOTAL_FRAMES = 471;

/** Linear interpolation between two values */
function lerp(a: number, b: number, t: number) {
  return a + (b - a) * t;
}

/** Compute opacity for a text line based on progress within a sub-range */
function textOpacity(progress: number, fadeIn: number, holdStart: number, holdEnd: number, fadeOut: number) {
  if (progress < fadeIn) return 0;
  if (progress < holdStart) return (progress - fadeIn) / (holdStart - fadeIn);
  if (progress < holdEnd) return 1;
  if (progress < fadeOut) return 1 - (progress - holdEnd) / (fadeOut - holdEnd);
  return 0;
}

// Phase 1 text lines (without hi-key)
const phase1Lines = [
  { text: "You leave the app.", fadeIn: 0.05, holdStart: 0.10, holdEnd: 0.33, fadeOut: 0.37 },
  { text: "You wait minutes for one result.", fadeIn: 0.15, holdStart: 0.20, holdEnd: 0.34, fadeOut: 0.39 },
  { text: "The moment is lost.", fadeIn: 0.25, holdStart: 0.30, holdEnd: 0.35, fadeOut: 0.40 },
];

// Phase 2: "Switch. Prompt. Paste." appear one by one on the same line
const phase2Words = [
  { text: "Switch.", fadeIn: 0.60, holdStart: 0.65 },
  { text: "Prompt.", fadeIn: 0.70, holdStart: 0.75 },
  { text: "Paste.", fadeIn: 0.80, holdStart: 0.85 },
];
// All three words stay visible — no fade out
const phase2WordsFadeOut = 1.1;
const phase2WordsHoldEnd = 1.0;

// "As you were." line — no fade out, stays visible
const phase2Final = { text: "As you were.", fadeIn: 0.90, holdStart: 0.95, holdEnd: 1.0, fadeOut: 1.1 };

// Phase headers
const phase1Header = { text: "Without hi-key", fadeIn: 0.00, holdStart: 0.00, holdEnd: 0.45, fadeOut: 0.50 };
const phase2Header = { text: "With hi-key", fadeIn: 0.45, holdStart: 0.50, holdEnd: 1.0, fadeOut: 1.1 };

export function Comparison() {
  const runwayRef = useRef<HTMLElement>(null);
  const lottieContainerRef = useRef<HTMLDivElement>(null);
  const animRef = useRef<AnimationItem | null>(null);
  const [isLoaded, setIsLoaded] = useState(false);
  const progress = useScrollProgress(runwayRef);

  // Lazy-load lottie-web and the animation
  useEffect(() => {
    const container = lottieContainerRef.current;
    if (!container) return;

    let anim: AnimationItem | null = null;
    let cancelled = false;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && !animRef.current && !cancelled) {
          observer.disconnect();
          import("lottie-web").then((lottie) => {
            if (cancelled) return;
            anim = lottie.default.loadAnimation({
              container,
              renderer: "svg",
              loop: false,
              autoplay: false,
              path: "/animations/comparison.json",
              rendererSettings: {
                preserveAspectRatio: "xMidYMid slice",
              },
            });
            anim.addEventListener("DOMLoaded", () => {
              // Force the SVG to fill the container
              const svg = container.querySelector("svg");
              if (svg) {
                svg.style.width = "100%";
                svg.style.height = "100%";
                svg.style.display = "block";
              }
              if (!cancelled) {
                animRef.current = anim;
                setIsLoaded(true);
              }
            });
          });
        }
      },
      { rootMargin: "200px" }
    );

    observer.observe(container);

    return () => {
      cancelled = true;
      observer.disconnect();
      if (anim) {
        anim.destroy();
        animRef.current = null;
      }
    };
  }, []);

  // Scrub animation to current frame — linear mapping
  useEffect(() => {
    if (animRef.current && isLoaded) {
      const frame = Math.round(progress * (TOTAL_FRAMES - 1));
      animRef.current.goToAndStop(frame, true);
    }
  }, [progress, isLoaded]);

  // Phase 1 blur (text blurs out as it fades)
  const phase1Blur = progress > 0.38 ? Math.min(8, (progress - 0.38) / 0.07 * 8) : 0;

  // Phase header opacities
  const phase1HeaderOpacity = textOpacity(progress, phase1Header.fadeIn, phase1Header.holdStart, phase1Header.holdEnd, phase1Header.fadeOut);
  const phase2HeaderOpacity = textOpacity(progress, phase2Header.fadeIn, phase2Header.holdStart, phase2Header.holdEnd, phase2Header.fadeOut);

  // Phase 2 words: each word fades in independently, all stay visible
  const phase2WordOpacities = phase2Words.map((w) =>
    textOpacity(progress, w.fadeIn, w.holdStart, phase2WordsHoldEnd, phase2WordsFadeOut)
  );
  const phase2FinalOpacity = textOpacity(progress, phase2Final.fadeIn, phase2Final.holdStart, phase2Final.holdEnd, phase2Final.fadeOut);

  // Shared text content
  const phase1Text = (
    <div
      className="flex flex-col items-center gap-2 lg:items-start"
      style={{ filter: `blur(${phase1Blur}px)` }}
    >
      <span
        className="font-heading text-sm font-medium tracking-widest uppercase text-text-tertiary"
        style={{ opacity: phase1HeaderOpacity }}
      >
        {phase1Header.text}
      </span>
      {phase1Lines.map((line) => {
        const opacity = textOpacity(progress, line.fadeIn, line.holdStart, line.holdEnd, line.fadeOut);
        const y = lerp(8, 0, Math.min(1, opacity * 2));
        return (
          <span
            key={line.text}
            className="font-heading text-lg font-semibold text-text-primary sm:text-xl md:text-2xl"
            style={{ opacity, transform: `translateY(${y}px)` }}
          >
            {line.text}
          </span>
        );
      })}
    </div>
  );

  const phase2Text = (
    <div className="flex flex-col items-center gap-2 lg:items-start">
      <span
        className="font-heading text-sm font-medium tracking-widest uppercase text-text-tertiary"
        style={{ opacity: phase2HeaderOpacity }}
      >
        {phase2Header.text}
      </span>
      <span className="font-heading text-lg font-semibold text-text-primary sm:text-xl md:text-2xl">
        {phase2Words.map((w, i) => (
          <span
            key={w.text}
            style={{ opacity: phase2WordOpacities[i], transition: "none" }}
          >
            {w.text}{i < phase2Words.length - 1 ? " " : ""}
          </span>
        ))}
      </span>
      <span
        className="font-heading text-lg font-semibold text-text-primary sm:text-xl md:text-2xl"
        style={{
          opacity: phase2FinalOpacity,
          transform: `translateY(${lerp(8, 0, Math.min(1, phase2FinalOpacity * 2))}px)`,
        }}
      >
        {phase2Final.text}
      </span>
    </div>
  );

  return (
    <section ref={runwayRef} className="relative" style={{ height: "600vh" }}>
      {/* Sticky container — pinned to viewport */}
      <div className="sticky top-0 flex h-screen w-full items-center justify-center overflow-hidden pt-16">
        {/*
          Mobile: column (animation on top, text below)
          Desktop (lg+): row (animation left, text right)
        */}
        <div className="flex h-full w-full flex-col items-center justify-center px-5 lg:w-auto lg:flex-row lg:items-center lg:gap-12 lg:px-8 xl:gap-16">
          {/* Animation — padded + rounded on mobile, constrained on desktop */}
          <div
            className="w-full shrink-0 lg:max-h-[80vh] lg:w-auto lg:max-w-[min(500px,45vh)]"
            style={{
              aspectRatio: "1024 / 1230",
              opacity: isLoaded ? 1 : 0,
              transform: isLoaded ? "translateY(0)" : "translateY(24px)",
              transition: "opacity 0.6s ease-out, transform 0.6s ease-out",
            }}
          >
            <div
              ref={lottieContainerRef}
              className="h-full w-full overflow-hidden rounded-4xl"
              style={{
                isolation: "isolate",
              }}
            />
          </div>

          {/* Text — stacked below on mobile, beside on desktop */}
          <div className="relative mt-6 h-[120px] w-full px-6 lg:mt-0 lg:h-auto lg:min-h-[140px] lg:flex-1 lg:px-0">
            <div className="absolute inset-x-6 top-0 lg:relative lg:inset-x-0">
              {phase1Text}
            </div>
            <div className="absolute inset-x-6 top-0 lg:absolute lg:inset-0">
              {phase2Text}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
