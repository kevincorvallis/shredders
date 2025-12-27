import { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Shredders - AI-Powered Mountain Conditions',
    short_name: 'Shredders',
    description: 'Real-time mountain conditions and AI-powered powder day predictions for PNW ski resorts',
    start_url: '/',
    display: 'standalone',
    background_color: '#0f172a',
    theme_color: '#0ea5e9',
    icons: [
      {
        src: '/icon.svg',
        sizes: 'any',
        type: 'image/svg+xml',
      },
    ],
  };
}
