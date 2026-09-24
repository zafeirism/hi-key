"use client";

import { useEffect, useState, type RefObject } from "react";

/**
 * Returns a 0→1 progress value based on how far the user has scrolled
 * through a container element. 0 = container top just reached viewport top,
 * 1 = container bottom just left viewport bottom.
 */
export function useScrollProgress(ref: RefObject<HTMLElement | null>) {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    let rafId: number | null = null;

    function onScroll() {
      if (rafId !== null) return;
      rafId = requestAnimationFrame(() => {
        rafId = null;
        if (!el) return;
        const rect = el.getBoundingClientRect();
        const viewportHeight = window.innerHeight;
        // progress 0 when top of container hits top of viewport
        // progress 1 when bottom of container hits bottom of viewport
        const scrollable = rect.height - viewportHeight;
        if (scrollable <= 0) {
          setProgress(0);
          return;
        }
        const raw = -rect.top / scrollable;
        setProgress(Math.min(1, Math.max(0, raw)));
      });
    }

    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();

    return () => {
      window.removeEventListener("scroll", onScroll);
      if (rafId !== null) cancelAnimationFrame(rafId);
    };
  }, [ref]);

  return progress;
}
