import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: "https://hi-key.ai",
      lastModified: new Date(),
      priority: 1.0,
    },
  ];
}
