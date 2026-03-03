import { AppStoreBadge } from "./app-store-badge";

export function Hero() {
  return (
    <section className="flex min-h-[90vh] items-center px-6 pt-24 pb-20">
      <div className="mx-auto grid max-w-5xl items-center gap-12 lg:grid-cols-2 lg:gap-16">
        {/* Text */}
        <div className="text-center lg:text-left">
          <h1 className="max-w-xl font-heading text-4xl font-bold tracking-tight text-text-primary sm:text-5xl md:text-6xl">
            AI images, right from{" "}
            <span className="text-accent-lime">your keyboard</span>
          </h1>
          <p className="mt-6 max-w-lg text-lg text-text-secondary sm:text-xl">
            Describe a scene, get 4 images in seconds — right inside iMessage,
            WhatsApp, Instagram, or any app you already use.
          </p>
          <div className="mt-10 flex flex-col items-center gap-3 lg:items-start">
            <AppStoreBadge />
            <span className="text-sm text-text-tertiary">
              Free to download. 5 credits to start.
            </span>
          </div>
        </div>

        {/* Phone mockup — TODO: replace with actual asset */}
        <div className="flex justify-center lg:justify-end">
          <div className="relative h-[520px] w-[260px] overflow-hidden rounded-[3rem] border-2 border-divider bg-surface-primary shadow-2xl sm:h-[580px] sm:w-[290px]">
            {/* Notch */}
            <div className="absolute top-0 left-1/2 z-10 h-7 w-28 -translate-x-1/2 rounded-b-2xl bg-background-root" />
            {/* Screen content placeholder */}
            <div className="flex h-full flex-col items-center justify-center p-6">
              <div className="grid grid-cols-2 gap-2">
                {[1, 2, 3, 4].map((i) => (
                  <div
                    key={i}
                    className="h-24 w-24 rounded-xl bg-surface-secondary sm:h-28 sm:w-28"
                  />
                ))}
              </div>
              <div className="mt-6 h-10 w-full rounded-xl bg-surface-secondary" />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
