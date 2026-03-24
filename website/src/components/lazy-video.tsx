"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useReducedMotion } from "@/hooks/use-reduced-motion";

interface LazyVideoProps {
  src: string;
  poster?: string;
  className?: string;
  playing?: boolean;
  /** If true, video restarts automatically when it ends (default true). Set false for carousel-style control. */
  loop?: boolean;
  onEnded?: () => void;
  onTimeUpdate?: (progress: number) => void;
  /** Called once when video metadata loads, with duration in seconds */
  onDuration?: (seconds: number) => void;
  fetchPriority?: "high" | "low" | "auto";
  lazyRootMargin?: string;
}

export function LazyVideo({
  src,
  poster,
  className,
  playing = false,
  loop = true,
  onEnded,
  onTimeUpdate,
  onDuration,
  fetchPriority,
  lazyRootMargin = "400px",
}: LazyVideoProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [srcLoaded, setSrcLoaded] = useState(false);
  const [visible, setVisible] = useState(false);
  const [userOptedIn, setUserOptedIn] = useState(false);
  const reducedMotion = useReducedMotion();
  const rafRef = useRef<number>(0);

  // Lazy load: set src only when near viewport
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setSrcLoaded(true);
          observer.disconnect();
        }
      },
      { rootMargin: lazyRootMargin }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [lazyRootMargin]);

  // Visibility tracking for play/pause
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => setVisible(entry.isIntersecting),
      { threshold: 0.5 }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  // Play/pause control
  const shouldPlay =
    playing && visible && srcLoaded && (!reducedMotion || userOptedIn);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    if (shouldPlay) {
      video.play().catch(() => {});
    } else {
      video.pause();
    }
  }, [shouldPlay]);

  // rAF-based smooth progress reporting (~60fps)
  const onTimeUpdateRef = useRef(onTimeUpdate);
  onTimeUpdateRef.current = onTimeUpdate;

  useEffect(() => {
    if (!shouldPlay) {
      cancelAnimationFrame(rafRef.current);
      return;
    }

    const tick = () => {
      const video = videoRef.current;
      if (video && video.duration && onTimeUpdateRef.current) {
        onTimeUpdateRef.current(video.currentTime / video.duration);
      }
      rafRef.current = requestAnimationFrame(tick);
    };

    rafRef.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafRef.current);
  }, [shouldPlay]);

  // Report duration once metadata loads
  const onDurationRef = useRef(onDuration);
  onDurationRef.current = onDuration;
  const durationReportedRef = useRef(false);

  const handleLoadedMetadata = useCallback(() => {
    const video = videoRef.current;
    if (!video || durationReportedRef.current) return;
    if (video.duration && isFinite(video.duration)) {
      durationReportedRef.current = true;
      onDurationRef.current?.(video.duration);
    }
  }, []);

  // When video ends: loop=true restarts, loop=false stays on last frame
  const handleEnded = useCallback(() => {
    const video = videoRef.current;
    if (!video) return;
    onEnded?.();
    if (loop) {
      video.currentTime = 0;
      if (shouldPlay) {
        video.play().catch(() => {});
      }
    }
    // loop=false: video stays paused on its last frame
  }, [onEnded, shouldPlay, loop]);

  // Reset video when becoming active
  useEffect(() => {
    const video = videoRef.current;
    if (video && playing) {
      video.currentTime = 0;
    }
    durationReportedRef.current = false;
  }, [playing]);

  return (
    <div ref={containerRef} className={`relative ${className ?? ""}`}>
      <video
        ref={videoRef}
        muted
        playsInline
        poster={poster}
        onEnded={handleEnded}
        onLoadedMetadata={handleLoadedMetadata}
        src={srcLoaded ? src : undefined}
        className="h-full w-full object-cover"
        // @ts-expect-error -- fetchPriority is valid on video but not in React types yet
        fetchPriority={fetchPriority}
      />

      {/* Reduced motion play button overlay */}
      {reducedMotion && !userOptedIn && srcLoaded && (
        <button
          type="button"
          aria-label="Play video demonstration"
          onClick={() => setUserOptedIn(true)}
          className="absolute inset-0 flex items-center justify-center bg-black/30"
        >
          <span className="flex h-16 w-16 items-center justify-center rounded-full bg-white/20 backdrop-blur-sm">
            <svg
              width="24"
              height="28"
              viewBox="0 0 24 28"
              fill="none"
              aria-hidden="true"
            >
              <path d="M2 2L22 14L2 26V2Z" fill="white" />
            </svg>
          </span>
        </button>
      )}
    </div>
  );
}
