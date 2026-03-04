import Image from "next/image";

const APP_STORE_URL =
  "https://apps.apple.com/app/hi-key/idYOUR_APP_ID";

export function AppStoreBadge({ className = "" }: { className?: string }) {
  return (
    <a
      href={APP_STORE_URL}
      target="_blank"
      rel="noopener noreferrer"
      className={`inline-block transition-opacity hover:opacity-80 ${className}`}
      aria-label="Download hi-key on the App Store"
    >
      <Image
        src="/app-store-badge.svg"
        alt="Download on the App Store"
        width={150}
        height={50}
        priority
      />
    </a>
  );
}
