import { Navbar } from "@/components/navbar";
import { Hero } from "@/components/hero";
import { Comparison } from "@/components/comparison";
import { WorksWith } from "@/components/works-with";
import { HowItWorks } from "@/components/how-it-works";
import { Features } from "@/components/features";
import { FAQ } from "@/components/faq";
import { DownloadCTA } from "@/components/download-cta";
import { Footer } from "@/components/footer";

export default function Home() {
  return (
    <div className="relative min-h-screen bg-background-root">
      {/* Fixed dot grid background */}
      <div className="dot-grid pointer-events-none fixed inset-0 opacity-40" />

      <div className="relative">
        <Navbar />
        <main>
          <Hero />
          <Comparison />
          <WorksWith />
          <HowItWorks />
          <Features />
          <FAQ />
          <DownloadCTA />
        </main>
        <Footer />
      </div>
    </div>
  );
}
