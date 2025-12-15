'use client';

import { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { MountainWithScore } from './MountainMapLoader';

interface LeafletMapProps {
  mountains: MountainWithScore[];
  userLocation: { lat: number; lng: number } | null;
  selectedMountainId?: string;
  onMountainSelect?: (mountainId: string) => void;
  isLoading: boolean;
}

// Custom marker icon for powder scores
function createPowderIcon(score: number | undefined, isSelected: boolean): L.DivIcon {
  const color = score === undefined
    ? '#64748b'
    : score >= 7
      ? '#22c55e'
      : score >= 5
        ? '#eab308'
        : '#ef4444';

  const size = isSelected ? 40 : 32;
  const border = isSelected ? '3px solid #fff' : 'none';

  return L.divIcon({
    className: 'powder-marker',
    html: `
      <div style="
        width: ${size}px;
        height: ${size}px;
        background: ${color};
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-weight: bold;
        font-size: ${isSelected ? '14px' : '12px'};
        box-shadow: 0 2px 8px rgba(0,0,0,0.4);
        border: ${border};
        transition: transform 0.2s;
      ">
        ${score?.toFixed(0) ?? '?'}
      </div>
    `,
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
    popupAnchor: [0, -size / 2],
  });
}

// User location marker
function createUserIcon(): L.DivIcon {
  return L.divIcon({
    className: 'user-marker',
    html: `
      <div style="
        width: 16px;
        height: 16px;
        background: #3b82f6;
        border-radius: 50%;
        border: 3px solid white;
        box-shadow: 0 2px 8px rgba(0,0,0,0.4);
      "></div>
      <div style="
        width: 40px;
        height: 40px;
        background: rgba(59, 130, 246, 0.2);
        border-radius: 50%;
        position: absolute;
        top: -12px;
        left: -12px;
        animation: pulse 2s ease-in-out infinite;
      "></div>
    `,
    iconSize: [16, 16],
    iconAnchor: [8, 8],
  });
}

export default function LeafletMap({
  mountains,
  userLocation,
  selectedMountainId,
  onMountainSelect,
  isLoading,
}: LeafletMapProps) {
  const mapRef = useRef<L.Map | null>(null);
  const markersRef = useRef<Map<string, L.Marker>>(new Map());
  const userMarkerRef = useRef<L.Marker | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const isMountedRef = useRef(true);

  // Initialize map
  useEffect(() => {
    isMountedRef.current = true;

    if (!containerRef.current || mapRef.current) return;

    // Center on Pacific Northwest
    const map = L.map(containerRef.current, {
      center: [46.5, -121.5],
      zoom: 6,
      zoomControl: true,
      attributionControl: true,
    });

    // Add tile layers
    const osmLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 18,
    });

    const topoLayer = L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenTopoMap',
      maxZoom: 17,
    });

    const esriSatLayer = L.tileLayer(
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      {
        attribution: '&copy; Esri',
        maxZoom: 18,
      }
    );

    // Default to topo
    topoLayer.addTo(map);

    // Layer control
    const baseLayers = {
      'Terrain': topoLayer,
      'Streets': osmLayer,
      'Satellite': esriSatLayer,
    };

    L.control.layers(baseLayers, {}, { position: 'topright' }).addTo(map);

    mapRef.current = map;

    return () => {
      isMountedRef.current = false;

      // Clear all markers first
      markersRef.current.forEach((marker) => {
        marker.off();
        marker.remove();
      });
      markersRef.current.clear();

      if (userMarkerRef.current) {
        userMarkerRef.current.off();
        userMarkerRef.current.remove();
        userMarkerRef.current = null;
      }

      // Stop all map animations and events before removing
      if (map) {
        map.stop();
        map.off();
        map.remove();
      }
      mapRef.current = null;
    };
  }, []);

  // Update markers when mountains change
  useEffect(() => {
    if (!mapRef.current || !isMountedRef.current) return;

    const map = mapRef.current;

    // Clear existing markers
    markersRef.current.forEach((marker) => {
      marker.off();
      marker.remove();
    });
    markersRef.current.clear();

    // Add mountain markers
    mountains.forEach((mountain) => {
      const isSelected = mountain.id === selectedMountainId;
      const marker = L.marker([mountain.location.lat, mountain.location.lng], {
        icon: createPowderIcon(mountain.powderScore, isSelected),
      });

      // Popup content
      const popupContent = `
        <div style="text-align: center; min-width: 150px;">
          <div style="font-weight: bold; font-size: 14px; margin-bottom: 4px;">${mountain.name}</div>
          <div style="font-size: 12px; color: #666; margin-bottom: 8px;">
            ${mountain.elevation.base.toLocaleString()}' - ${mountain.elevation.summit.toLocaleString()}'
          </div>
          <div style="
            display: inline-block;
            padding: 4px 12px;
            border-radius: 16px;
            background: ${
              mountain.powderScore === undefined
                ? '#64748b'
                : mountain.powderScore >= 7
                  ? '#22c55e'
                  : mountain.powderScore >= 5
                    ? '#eab308'
                    : '#ef4444'
            };
            color: white;
            font-weight: bold;
            font-size: 14px;
          ">
            ${mountain.powderScore?.toFixed(1) ?? 'N/A'}
          </div>
          ${mountain.distance !== undefined ? `
            <div style="font-size: 11px; color: #888; margin-top: 6px;">
              ${mountain.distance.toFixed(0)} miles away
            </div>
          ` : ''}
        </div>
      `;

      marker.bindPopup(popupContent, { closeButton: false });

      marker.on('click', () => {
        onMountainSelect?.(mountain.id);
      });

      marker.addTo(map);
      markersRef.current.set(mountain.id, marker);
    });

    // Fit bounds to show all mountains
    if (mountains.length > 0) {
      const bounds = L.latLngBounds(mountains.map((m) => [m.location.lat, m.location.lng]));
      map.fitBounds(bounds, { padding: [50, 50] });
    }
  }, [mountains, selectedMountainId, onMountainSelect]);

  // Update selected marker style
  useEffect(() => {
    if (!mapRef.current || !isMountedRef.current) return;

    markersRef.current.forEach((marker, id) => {
      const mountain = mountains.find((m) => m.id === id);
      if (mountain) {
        const isSelected = id === selectedMountainId;
        marker.setIcon(createPowderIcon(mountain.powderScore, isSelected));
        if (isSelected) {
          marker.openPopup();
        }
      }
    });
  }, [selectedMountainId, mountains]);

  // Add/update user location marker
  useEffect(() => {
    if (!mapRef.current || !userLocation || !isMountedRef.current) return;

    if (userMarkerRef.current) {
      userMarkerRef.current.setLatLng([userLocation.lat, userLocation.lng]);
    } else {
      const userMarker = L.marker([userLocation.lat, userLocation.lng], {
        icon: createUserIcon(),
        zIndexOffset: -1000,
      });
      userMarker.bindPopup('Your Location');
      userMarker.addTo(mapRef.current);
      userMarkerRef.current = userMarker;
    }
  }, [userLocation]);

  return (
    <>
      <style jsx global>{`
        @keyframes pulse {
          0%, 100% { transform: scale(1); opacity: 0.6; }
          50% { transform: scale(1.5); opacity: 0; }
        }
        .powder-marker:hover > div {
          transform: scale(1.1);
        }
        .leaflet-popup-content-wrapper {
          border-radius: 12px;
        }
        .leaflet-popup-tip {
          background: white;
        }
      `}</style>
      <div ref={containerRef} className="w-full h-full" />
      {isLoading && (
        <div className="absolute inset-0 bg-slate-900/50 flex items-center justify-center z-[1001]">
          <div className="flex items-center gap-2 text-white">
            <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
              <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
            <span>Loading conditions...</span>
          </div>
        </div>
      )}
    </>
  );
}
