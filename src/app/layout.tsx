import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { MountainProvider } from "@/context/MountainContext";
import { SiteHeader } from "@/components/SiteHeader";
import NextTopLoader from 'nextjs-toploader';

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: {
    default: "Shredders - AI-Powered Mountain Conditions",
    template: "%s | Shredders"
  },
  description: "Real-time mountain conditions and AI-powered powder day predictions for Pacific Northwest ski resorts. Track snow depth, powder scores, and weather forecasts.",
  keywords: ["ski conditions", "snow report", "powder day", "PNW skiing", "mountain weather", "ski forecast", "Washington skiing", "Oregon skiing", "Idaho skiing"],
  authors: [{ name: "Shredders" }],
  creator: "Shredders",
  publisher: "Shredders",
  metadataBase: new URL(process.env.NEXT_PUBLIC_BASE_URL || "https://shredders.vercel.app"),
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "/",
    title: "Shredders - AI-Powered Mountain Conditions",
    description: "Real-time mountain conditions and AI-powered powder day predictions for Pacific Northwest ski resorts",
    siteName: "Shredders",
  },
  twitter: {
    card: "summary_large_image",
    title: "Shredders - AI-Powered Mountain Conditions",
    description: "Real-time mountain conditions and AI-powered powder day predictions for PNW ski resorts",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  verification: {
    // Add your verification codes here when ready
    // google: "your-google-verification-code",
    // yandex: "your-yandex-verification-code",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-background min-h-screen`}
      >
        <NextTopLoader
          color="var(--accent)"
          initialPosition={0.08}
          crawlSpeed={200}
          height={2}
          crawl={true}
          showSpinner={false}
          easing="ease"
          speed={200}
          shadow={false}
        />
        <MountainProvider>
          <SiteHeader />
          <main>{children}</main>
        </MountainProvider>
      </body>
    </html>
  );
}
