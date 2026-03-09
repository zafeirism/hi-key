"use client";

import { FormEvent, Suspense, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Check } from "lucide-react";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function WaitlistFormInner() {
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("");
  const [state, setState] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const isValidEmail = EMAIL_REGEX.test(email);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!isValidEmail || state === "loading") return;

    setState("loading");

    try {
      const referralSource =
        searchParams.get("ref") ?? searchParams.get("utm_source") ?? undefined;

      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, referralSource }),
      });

      if (res.ok) {
        setState("success");
      } else {
        const data = await res.json();
        setErrorMessage(data.error ?? "Something went wrong.");
        setState("error");
        setTimeout(() => setState("idle"), 4000);
      }
    } catch {
      setErrorMessage("Something went wrong. Please try again.");
      setState("error");
      setTimeout(() => setState("idle"), 4000);
    }
  }

  if (state === "success") {
    return (
      <div className="flex items-center gap-2 text-accent-lime">
        <Check className="h-5 w-5" />
        <span className="font-medium">You&apos;re in!</span>
      </div>
    );
  }

  return (
    <div className="w-full">
      <form
        onSubmit={handleSubmit}
        className="flex items-center gap-1.5 rounded-xl border border-divider bg-surface-primary p-1.5"
      >
        <input
          type="email"
          autoComplete="email"
          placeholder="you@email.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="min-w-0 flex-1 bg-transparent px-3 py-2 text-sm text-text-primary placeholder:text-text-tertiary outline-none"
          required
        />
        <button
          type="submit"
          disabled={!isValidEmail || state === "loading"}
          className="shrink-0 rounded-lg bg-accent-lime px-5 py-2 text-sm font-semibold text-background-root transition-opacity duration-200 hover:opacity-90 disabled:opacity-40"
        >
          {state === "loading" ? "Joining..." : "Join Waitlist"}
        </button>
      </form>
      {state === "error" && (
        <p className="mt-2 text-sm text-status-error">{errorMessage}</p>
      )}
    </div>
  );
}

export function WaitlistForm() {
  return (
    <Suspense>
      <WaitlistFormInner />
    </Suspense>
  );
}
