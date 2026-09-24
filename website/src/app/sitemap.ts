import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: "https://hi-key.ai",
      lastModified: new Date(),
      priority: 1.0,
    },
    {
      url: "https://hi-key.ai/privacy",
      lastModified: new Date("2026-05-04"),
      priority: 0.5,
    },
    {
      url: "https://hi-key.ai/terms",
      lastModified: new Date("2026-05-04"),
      priority: 0.5,
    },
  ];
}
