import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "All Mountains",
  description: "Explore Pacific Northwest ski resorts with real-time conditions, powder scores, and interactive maps",
};

export default function MountainsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
