"use client";

import { useEffect, useState } from "react";

const APP_STORE_URL = "https://apps.apple.com/app/hi-key/idYOUR_APP_ID";

export function Navbar() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <nav
      className={`fixed top-0 right-0 left-0 z-50 transition-all duration-300 ${
        scrolled
          ? "border-b border-divider bg-background-root/80 backdrop-blur-xl"
          : "bg-transparent"
      }`}
    >
      <div className="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
        <a
          href="#"
          className="font-heading text-xl font-bold tracking-tight text-text-primary"
        >
          hi-key
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
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-full bg-accent-lime px-5 py-2 text-sm font-semibold text-background-root transition-opacity hover:opacity-90"
          >
            Download
          </a>
        </div>

        {/* Mobile: just the download button */}
        <a
          href={APP_STORE_URL}
          target="_blank"
          rel="noopener noreferrer"
          className="rounded-full bg-accent-lime px-4 py-1.5 text-sm font-semibold text-background-root transition-opacity hover:opacity-90 sm:hidden"
        >
          Download
        </a>
      </div>
    </nav>
  );
}
