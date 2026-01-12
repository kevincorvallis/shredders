import { MetadataRoute } from 'next';
import { getAllMountains } from '@shredders/shared';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders.vercel.app';
  const mountains = getAllMountains();

  const mountainRoutes = mountains.flatMap((mountain) => [
    {
      url: `${baseUrl}/mountains/${mountain.id}`,
      lastModified: new Date(),
      changeFrequency: 'hourly' as const,
      priority: 0.8,
    },
    {
      url: `${baseUrl}/mountains/${mountain.id}/history`,
      lastModified: new Date(),
      changeFrequency: 'daily' as const,
      priority: 0.6,
    },
    {
      url: `${baseUrl}/mountains/${mountain.id}/patrol`,
      lastModified: new Date(),
      changeFrequency: 'hourly' as const,
      priority: 0.7,
    },
    {
      url: `${baseUrl}/mountains/${mountain.id}/webcams`,
      lastModified: new Date(),
      changeFrequency: 'hourly' as const,
      priority: 0.7,
    },
  ]);

  return [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'hourly',
      priority: 1,
    },
    {
      url: `${baseUrl}/mountains`,
      lastModified: new Date(),
      changeFrequency: 'hourly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/chat`,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 0.7,
    },
    ...mountainRoutes,
  ];
}
