export function Footer() {
  return (
    <footer className="border-t border-divider px-6 py-10">
      <div className="mx-auto flex max-w-4xl flex-col items-center gap-6 sm:flex-row sm:justify-between">
        <p className="text-sm text-text-tertiary">
          &copy; {new Date().getFullYear()} hi-key. All rights reserved.
        </p>
        <nav className="flex gap-6" aria-label="Footer">
          <a
            href="/privacy"
            className="text-sm text-text-secondary transition-colors hover:text-text-primary"
          >
            Privacy Policy
          </a>
          <a
            href="/terms"
            className="text-sm text-text-secondary transition-colors hover:text-text-primary"
          >
            Terms of Service
          </a>
          <a
            href="mailto:support@hi-key.ai"
            className="text-sm text-text-secondary transition-colors hover:text-text-primary"
          >
            Support
          </a>
        </nav>
      </div>
    </footer>
  );
}
