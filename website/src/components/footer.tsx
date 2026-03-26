export function Footer() {
  return (
    <footer className="border-t border-divider px-6 py-10">
      <div className="mx-auto flex max-w-4xl flex-col items-center gap-6 sm:flex-row sm:justify-between">
        <p className="text-sm text-text-tertiary">
          &copy; {new Date().getFullYear()} hi-key
        </p>
        <p className="text-sm text-text-tertiary">
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
