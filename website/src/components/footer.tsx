import Link from "next/link";

export function Footer() {
  return (
    <footer className="border-t border-divider px-6 py-10">
      <div className="mx-auto flex max-w-4xl flex-col items-center gap-4 text-sm text-text-tertiary sm:flex-row sm:justify-between">
        <p className="flex flex-wrap items-center justify-center gap-x-2">
          <span>&copy; {new Date().getFullYear()} hi-key</span>
          <span aria-hidden="true">·</span>
          <Link
            href="/privacy"
            className="text-text-secondary transition-colors hover:text-text-primary"
          >
            privacy
          </Link>
          <span aria-hidden="true">·</span>
          <Link
            href="/terms"
            className="text-text-secondary transition-colors hover:text-text-primary"
          >
            terms
          </Link>
          <span aria-hidden="true">·</span>
          <a
            href="mailto:support@hi-key.ai"
            className="text-text-secondary transition-colors hover:text-text-primary"
          >
            support
          </a>
        </p>
        <p>
          made with fun by{" "}
          <a
            href="https://x.com/zafeirism"
            target="_blank"
            rel="noopener noreferrer"
            className="text-text-secondary transition-colors hover:text-text-primary"
          >
            zaf
          </a>
        </p>
      </div>
    </footer>
  );
}
