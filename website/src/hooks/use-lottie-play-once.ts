"use client";

import { useRef, useEffect, useState } from "react";
import type { AnimationItem } from "lottie-web";

export function useLottiePlayOnce(path: string | null) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [isLoaded, setIsLoaded] = useState(false);

  useEffect(() => {
    if (!path || !containerRef.current) return;

    let anim: AnimationItem | null = null;
    const el = containerRef.current;

    // Preload observer: load the animation early so the first frame is visible
    const preloadObserver = new IntersectionObserver(
      ([entry]) => {
        if (!entry.isIntersecting) return;
        preloadObserver.disconnect();

        import("lottie-web").then((lottie) => {
          if (!el) return;

          anim = lottie.default.loadAnimation({
            container: el,
            renderer: "svg",
            loop: false,
            autoplay: false,
            path,
            rendererSettings: {
              preserveAspectRatio: "xMidYMid meet",
            },
          });

          anim.addEventListener("DOMLoaded", () => {
            setIsLoaded(true);
            // Play observer: start playback only when fully visible
            const playObserver = new IntersectionObserver(
              ([e]) => {
                if (!e.isIntersecting) return;
                playObserver.disconnect();
                anim?.play();
              },
              { threshold: 1.0 },
            );
            playObserver.observe(el);
          });
        });
      },
      { rootMargin: "200px" },
    );

    preloadObserver.observe(el);

    return () => {
      preloadObserver.disconnect();
      anim?.destroy();
    };
  }, [path]);

  return { containerRef, isLoaded };
}
