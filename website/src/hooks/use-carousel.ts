"use client";

import { useCallback, useEffect, useRef, useState } from "react";

interface UseCarouselOptions {
  stepCount: number;
  /** ms to pause auto-advance after user clicks a step (default 5000) */
  pauseDuration?: number;
  /**
   * ms to linger on the last frame after each video ends before advancing (default 1500).
   * Tweak this to give more or less breathing room between steps.
   */
  dwellMs?: number;
}

export function useCarousel({
  stepCount,
  pauseDuration = 5000,
  dwellMs = 1500,
}: UseCarouselOptions) {
  const [activeStep, setActiveStep] = useState(0);
  const [displayProgress, setDisplayProgress] = useState(0);
  const pauseTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isPausedRef = useRef(false);
  const dwellingRef = useRef(false);
  const dwellRafRef = useRef<number>(0);
  const dwellStartRef = useRef(0);

  // Store known video durations (in seconds) per step index
  const durationsRef = useRef<Map<number, number>>(new Map());

  /** Returns the fraction of the progress bar that the video portion occupies for the active step. */
  const getVideoPortion = useCallback(
    (step: number) => {
      const dur = durationsRef.current.get(step);
      if (!dur) return 0.82; // fallback before metadata loads
      return dur / (dur + dwellMs / 1000);
    },
    [dwellMs]
  );

  // Cleanup dwell animation on unmount
  useEffect(() => {
    return () => cancelAnimationFrame(dwellRafRef.current);
  }, []);

  // Cancel dwell when activeStep changes (e.g. user clicks a step during dwell)
  useEffect(() => {
    dwellingRef.current = false;
    cancelAnimationFrame(dwellRafRef.current);
  }, [activeStep]);

  /** Called by LazyVideo's onDuration — stores the real video length */
  const setStepDuration = useCallback((step: number, seconds: number) => {
    durationsRef.current.set(step, seconds);
  }, []);

  const onVideoEnded = useCallback(() => {
    if (isPausedRef.current) return;

    const videoPortion = getVideoPortion(activeStep);

    // Enter dwell phase — animate progress from videoPortion to 1.0
    dwellingRef.current = true;
    dwellStartRef.current = performance.now();

    const animate = () => {
      if (!dwellingRef.current) return;

      const elapsed = performance.now() - dwellStartRef.current;
      const fraction = Math.min(elapsed / dwellMs, 1);
      setDisplayProgress(videoPortion + fraction * (1 - videoPortion));

      if (fraction < 1) {
        dwellRafRef.current = requestAnimationFrame(animate);
      } else {
        // Dwell complete — advance
        dwellingRef.current = false;
        setActiveStep((prev) => (prev + 1) % stepCount);
        setDisplayProgress(0);
      }
    };

    dwellRafRef.current = requestAnimationFrame(animate);
  }, [stepCount, dwellMs, activeStep, getVideoPortion]);

  const goToStep = useCallback(
    (i: number) => {
      // Cancel any in-progress dwell
      dwellingRef.current = false;
      cancelAnimationFrame(dwellRafRef.current);

      setActiveStep(i);
      setDisplayProgress(0);

      // Pause auto-advance
      isPausedRef.current = true;
      if (pauseTimeoutRef.current) clearTimeout(pauseTimeoutRef.current);
      pauseTimeoutRef.current = setTimeout(() => {
        isPausedRef.current = false;
      }, pauseDuration);
    },
    [pauseDuration]
  );

  const setVideoProgress = useCallback(
    (p: number) => {
      // Scale video's 0-1 progress into 0-videoPortion range.
      // Skip updates during dwell phase (dwell handles its own progress).
      if (dwellingRef.current) return;
      setDisplayProgress(p * getVideoPortion(activeStep));
    },
    [activeStep, getVideoPortion]
  );

  // Drag / swipe gesture support
  const [dragOffset, setDragOffset] = useState(0);
  const [isDragging, setIsDragging] = useState(false);
  const touchStartRef = useRef<{ x: number; y: number } | null>(null);
  const lockedAxisRef = useRef<"x" | "y" | null>(null);

  const onTouchStart = useCallback((e: React.TouchEvent) => {
    touchStartRef.current = {
      x: e.touches[0].clientX,
      y: e.touches[0].clientY,
    };
    lockedAxisRef.current = null;
  }, []);

  const onTouchMove = useCallback(
    (e: React.TouchEvent) => {
      if (!touchStartRef.current) return;
      const dx = e.touches[0].clientX - touchStartRef.current.x;
      const dy = e.touches[0].clientY - touchStartRef.current.y;

      // Lock axis after 10px of movement
      if (!lockedAxisRef.current && (Math.abs(dx) > 10 || Math.abs(dy) > 10)) {
        lockedAxisRef.current = Math.abs(dx) >= Math.abs(dy) ? "x" : "y";
      }

      if (lockedAxisRef.current !== "x") return;

      // Resist dragging past first/last step
      const clamped =
        (activeStep === 0 && dx > 0) || (activeStep === stepCount - 1 && dx < 0)
          ? dx * 0.25
          : dx;

      setIsDragging(true);
      setDragOffset(clamped);
    },
    [activeStep, stepCount]
  );

  const onTouchEnd = useCallback(() => {
    if (!isDragging) {
      touchStartRef.current = null;
      return;
    }

    const threshold = 50;
    if (dragOffset < -threshold && activeStep < stepCount - 1) {
      goToStep(activeStep + 1);
    } else if (dragOffset > threshold && activeStep > 0) {
      goToStep(activeStep - 1);
    }

    setIsDragging(false);
    setDragOffset(0);
    touchStartRef.current = null;
  }, [isDragging, dragOffset, activeStep, stepCount, goToStep]);

  const swipeHandlers = { onTouchStart, onTouchMove, onTouchEnd };

  return {
    activeStep,
    displayProgress,
    onVideoEnded,
    goToStep,
    setVideoProgress,
    setStepDuration,
    swipeHandlers,
    dragOffset,
    isDragging,
  };
}
