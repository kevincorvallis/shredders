'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { MountainSelector } from './MountainSelector';
import { useMountain } from '@/context/MountainContext';

export function SiteHeader() {
  const pathname = usePathname();
  const router = useRouter();
  const { selectedMountainId, setSelectedMountain } = useMountain();

  const navLinks = [
    { href: '/mountains', label: 'Mountains' },
    { href: '/chat', label: 'Chat' },
  ];

  const handleMountainChange = (newMountainId: string) => {
    // Update context immediately
    setSelectedMountain(newMountainId);

    // If on a mountain page, preserve sub-route
    if (pathname.startsWith('/mountains/')) {
      const parts = pathname.split('/');
      if (parts.length > 3) {
        // /mountains/baker/history -> /mountains/crystal/history
        parts[2] = newMountainId;
        router.push(parts.join('/'));
      } else {
        // /mountains/baker -> /mountains/crystal
        router.push(`/mountains/${newMountainId}`);
      }
    } else {
      // Not on mountain page, go to mountain root
      router.push(`/mountains/${newMountainId}`);
    }
  };

  return (
    <header className="sticky top-0 z-50 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
            <span className="text-2xl">🏔️</span>
            <span className="text-xl font-bold text-white hidden sm:block">Shredders</span>
          </Link>

          {/* Mountain Selector */}
          <div className="flex-1 flex justify-center px-4">
            <MountainSelector
              selectedId={selectedMountainId}
              onChange={handleMountainChange}
            />
          </div>

          {/* Navigation */}
          <nav className="flex items-center gap-1 sm:gap-2">
            {navLinks.map((link) => {
              const isActive = pathname.startsWith(link.href);
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-slate-800 text-white'
                      : 'text-gray-400 hover:text-white hover:bg-slate-800/50'
                  }`}
                >
                  {link.label}
                </Link>
              );
            })}
          </nav>
        </div>
      </div>
    </header>
  );
}
