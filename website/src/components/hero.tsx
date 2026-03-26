import { WaitlistForm } from "./waitlist-form";
import { LazyVideo } from "./lazy-video";

export function Hero() {
  return (
    <section id="waitlist" className="flex min-h-[90vh] items-center px-6 pt-24 pb-20">
      <div className="mx-auto grid max-w-6xl items-center gap-12 lg:grid-cols-[1fr_1fr] lg:gap-12">
        {/* Text */}
        <div className="text-center lg:text-left">
          <h1 className="font-heading text-4xl font-bold tracking-tight text-text-primary sm:text-5xl md:text-6xl">
            AI images, right from{" "}
            <span className="text-accent-lime">your keyboard</span>
          </h1>
          <p className="mt-6 max-w-lg text-lg text-text-secondary sm:text-xl">
            Create images in seconds, right inside WhatsApp, iMessage or
            any app you use.
          </p>
          <div className="mt-10 flex w-full max-w-sm flex-col items-center gap-3 lg:items-start">
            <WaitlistForm />
            <span className="text-sm text-text-tertiary">
              Early members get 2× credits.{" "}
              <span className="text-text-primary">Forever.</span>
            </span>
          </div>
        </div>

        {/* Hero demo video */}
        <div className="flex justify-center lg:justify-end">
          <LazyVideo
            src="/geekout.mp4"
            poster="/geekout-poster.jpg"
            playing
            fetchPriority="high"
            lazyRootMargin="0px"
            className="w-full max-w-[460px] rounded-4xl overflow-hidden"
          />
        </div>
      </div>
    </section>
  );
}
