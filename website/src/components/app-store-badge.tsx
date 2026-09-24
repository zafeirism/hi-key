import Image from "next/image";

export const APP_STORE_URL = "https://apps.apple.com/app/id6762464437";

export function AppStoreBadge({
  className = "",
  width = 180,
  height = 60,
  priority = false,
}: {
  className?: string;
  width?: number;
  height?: number;
  priority?: boolean;
}) {
  return (
    <a
      href={APP_STORE_URL}
      target="_blank"
      rel="noopener noreferrer"
      className={`inline-block transition-opacity hover:opacity-80 ${className}`}
      aria-label="Download hi-key on the App Store"
    >
      <Image
        src="/app-store-badge-white.svg"
        alt="Download on the App Store"
        width={width}
        height={height}
        priority={priority}
      />
    </a>
  );
}
