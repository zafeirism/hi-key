"use client";

import { useEffect, useState } from "react";

export function Navbar() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <nav
      className={`fixed top-0 right-0 left-0 z-50 px-6 pt-[env(safe-area-inset-top)] transition-all duration-300 ${
        scrolled
          ? "border-b border-divider bg-background-root/80 backdrop-blur-xl"
          : "bg-transparent"
      }`}
    >
      <div className="mx-auto flex max-w-5xl items-center justify-between py-4">
        <a href="#" aria-label="hi-key home">
          <img
            src="/hi-key.svg"
            alt="hi-key"
            className="h-8 w-auto"
          />
        </a>

        <div className="hidden items-center gap-8 sm:flex">
          <a
            href="#how-it-works"
            className="text-sm text-text-secondary transition-colors hover:text-text-primary"
          >
            How it works
          </a>
          <a
            href="#features"
            className="text-sm text-text-secondary transition-colors hover:text-text-primary"
          >
            Features
          </a>
          <a
            href="#faq"
            className="text-sm text-text-secondary transition-colors hover:text-text-primary"
          >
            FAQ
          </a>
          <a
            href="#waitlist"
            className="rounded-full bg-accent-lime px-5 py-2 text-sm font-semibold text-background-root transition-opacity hover:opacity-90"
          >
            Join Waitlist
          </a>
        </div>

        {/* Mobile: just the waitlist button */}
        <a
          href="#waitlist"
          className="rounded-full bg-accent-lime px-4 py-1.5 text-sm font-semibold text-background-root transition-opacity hover:opacity-90 sm:hidden"
        >
          Join Waitlist
        </a>
      </div>
    </nav>
  );
}
