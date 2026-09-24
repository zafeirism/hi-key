import { FadeUp } from "./fade-up";
import { AppStoreBadge } from "./app-store-badge";

export function DownloadCTA() {
  return (
    <section className="px-6 py-28">
      <FadeUp>
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-heading text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            Ready to try it?
          </h2>
          <p className="mt-4 text-lg text-text-secondary">
            Your keyboard is about to get a lot more fun.
          </p>
          <div className="mt-8 flex justify-center">
            <AppStoreBadge />
          </div>
        </div>
      </FadeUp>
    </section>
  );
}
