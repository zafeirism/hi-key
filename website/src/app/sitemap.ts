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
      lastModified: new Date(),
      priority: 0.3,
    },
    {
      url: "https://hi-key.ai/terms",
      lastModified: new Date(),
      priority: 0.3,
    },
  ];
}
