import { AppStoreBadge } from "./app-store-badge";
import { FadeUp } from "./fade-up";

export function DownloadCTA() {
  return (
    <section className="px-6 py-28">
      <FadeUp>
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            Ready to try it?
          </h2>
          <p className="mt-4 text-lg text-text-secondary">
            Generate your first AI images in under a minute.
          </p>
          <div className="mt-8 flex flex-col items-center gap-3">
            <AppStoreBadge />
            <span className="text-sm text-text-tertiary">
              Free to download. No account required.
            </span>
          </div>
        </div>
      </FadeUp>
    </section>
  );
}
