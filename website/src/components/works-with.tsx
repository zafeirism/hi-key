"use client";

import { useRef, useEffect, useState } from "react";
import type { AnimationItem } from "lottie-web";
import { WaitlistForm } from "./waitlist-form";

export function WorksWith() {
  const sectionRef = useRef<HTMLElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const animRef = useRef<AnimationItem | null>(null);
  const [isLoaded, setIsLoaded] = useState(false);

  useEffect(() => {
    if (!containerRef.current || !sectionRef.current) return;

    let anim: AnimationItem | null = null;
    let observer: IntersectionObserver | null = null;

    import("lottie-web").then((lottie) => {
      if (!containerRef.current || !sectionRef.current) return;

      anim = lottie.default.loadAnimation({
        container: containerRef.current,
        renderer: "svg",
        loop: true,
        autoplay: false,
        path: "/animations/works-with-hi-key.json",
        rendererSettings: {
          preserveAspectRatio: "xMidYMid meet",
        },
      });

      anim.addEventListener("DOMLoaded", () => {
        setIsLoaded(true);
      });

      animRef.current = anim;

      observer = new IntersectionObserver(
        ([entry]) => {
          if (entry.isIntersecting) {
            animRef.current?.play();
          } else {
            animRef.current?.pause();
          }
        },
        { threshold: 0.25 },
      );
      observer.observe(sectionRef.current!);
    });

    return () => {
      observer?.disconnect();
      anim?.destroy();
      animRef.current = null;
    };
  }, []);

  return (
    <section ref={sectionRef} className="px-6 py-24 sm:py-32">
      <div className="mx-auto flex max-w-6xl flex-col-reverse items-center gap-12 lg:grid lg:grid-cols-[3fr_2fr] lg:gap-8">
        {/* Text */}
        <div className="text-center lg:text-left">
          <h2 className="font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            Yes, it works there too
          </h2>
          <p className="mt-4 max-w-lg text-lg text-text-secondary">
            hi-key works with all your favorite apps. If you can type in it, you can use hi-key.
          </p>
          <div className="mt-10 flex w-full max-w-sm flex-col items-center gap-3 lg:items-start">
            <WaitlistForm />
            <span className="text-sm text-text-tertiary">
              Join the waitlist. Be the first to try hi-key.
            </span>
          </div>
        </div>

        {/* Lottie animation */}
        <div className="flex justify-center lg:justify-end">
          <div
            className={`w-full max-w-sm transition-opacity duration-500 ${
              isLoaded ? "opacity-100" : "opacity-0"
            }`}
          >
            <div ref={containerRef} />
          </div>
        </div>
      </div>
    </section>
  );
}
