#!/usr/bin/env python3
"""
Generate map tiles from GeoJSON ski lift data.

This script converts ski lift polylines into PNG tiles at multiple zoom levels
for efficient display in mobile apps.

Usage:
    python3 generate-lift-tiles.py <mountain-id> [--zoom-min 10] [--zoom-max 16]

Example:
    python3 generate-lift-tiles.py crystal --zoom-min 12 --zoom-max 15
"""

import argparse
import json
import math
import os
from pathlib import Path
from typing import List, Tuple

from PIL import Image, ImageDraw


def lon_lat_to_tile(lon: float, lat: float, zoom: int) -> Tuple[int, int]:
    """Convert longitude/latitude to tile coordinates at given zoom level."""
    lat_rad = math.radians(lat)
    n = 2.0 ** zoom
    x = int((lon + 180.0) / 360.0 * n)
    y = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
    return x, y


def tile_to_lon_lat(x: int, y: int, zoom: int) -> Tuple[float, float]:
    """Convert tile coordinates to longitude/latitude (NW corner)."""
    n = 2.0 ** zoom
    lon = x / n * 360.0 - 180.0
    lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * y / n)))
    lat = math.degrees(lat_rad)
    return lon, lat


def lon_lat_to_pixel(lon: float, lat: float, zoom: int, tile_x: int, tile_y: int, tile_size: int = 256) -> Tuple[int, int]:
    """Convert lon/lat to pixel coordinates within a specific tile."""
    # Get the lon/lat of the NW corner of this tile
    tile_lon, tile_lat = tile_to_lon_lat(tile_x, tile_y, zoom)
    tile_lon_next, tile_lat_next = tile_to_lon_lat(tile_x + 1, tile_y + 1, zoom)

    # Calculate pixel position within tile
    lon_range = tile_lon_next - tile_lon
    lat_range = tile_lat_next - tile_lat

    px = int((lon - tile_lon) / lon_range * tile_size)
    py = int((lat - tile_lat) / lat_range * tile_size)

    return px, py


def get_lift_color(lift_type: str) -> str:
    """Get color for lift type."""
    colors = {
        'gondola': '#FF0000',
        'cable_car': '#FF0000',
        'chair_lift': '#0066FF',
        'drag_lift': '#00CC00',
        't-bar': '#00CC00',
        'j-bar': '#00CC00',
        'platter': '#00CC00',
        'magic_carpet': '#9933FF',
        'rope_tow': '#00CC00',
    }
    return colors.get(lift_type, '#888888')


def get_lift_width(zoom: int) -> int:
    """Get line width based on zoom level."""
    if zoom <= 11:
        return 1
    elif zoom <= 13:
        return 2
    elif zoom <= 15:
        return 3
    else:
        return 4


def generate_tiles(mountain_id: str, zoom_min: int = 10, zoom_max: int = 16, tile_size: int = 256):
    """Generate tiles for a mountain's lifts."""

    # Read GeoJSON file
    geojson_path = Path(__file__).parent.parent / 'data' / 'ski-lifts' / 'geojson' / f'{mountain_id}.geojson'
    if not geojson_path.exists():
        print(f"Error: GeoJSON file not found: {geojson_path}")
        return

    with open(geojson_path, 'r') as f:
        geojson = json.load(f)

    print(f"Loaded {len(geojson['features'])} lifts for {mountain_id}")

    # Create output directory
    output_dir = Path(__file__).parent.parent / 'public' / 'tiles' / mountain_id
    output_dir.mkdir(parents=True, exist_ok=True)

    # Calculate bounding box to determine which tiles we need
    all_coords = []
    for feature in geojson['features']:
        coords = feature['geometry']['coordinates']
        all_coords.extend(coords)

    min_lon = min(c[0] for c in all_coords)
    max_lon = max(c[0] for c in all_coords)
    min_lat = min(c[1] for c in all_coords)
    max_lat = max(c[1] for c in all_coords)

    print(f"Bounds: ({min_lat:.4f}, {min_lon:.4f}) to ({max_lat:.4f}, {max_lon:.4f})")

    # Generate tiles for each zoom level
    for zoom in range(zoom_min, zoom_max + 1):
        print(f"\nGenerating zoom level {zoom}...")

        # Get tile range
        min_tile_x, max_tile_y = lon_lat_to_tile(min_lon, min_lat, zoom)
        max_tile_x, min_tile_y = lon_lat_to_tile(max_lon, max_lat, zoom)

        print(f"  Tiles X: {min_tile_x} to {max_tile_x}")
        print(f"  Tiles Y: {min_tile_y} to {max_tile_y}")

        # Create zoom directory
        zoom_dir = output_dir / str(zoom)
        zoom_dir.mkdir(exist_ok=True)

        # Generate each tile
        tile_count = 0
        for tile_x in range(min_tile_x, max_tile_x + 1):
            x_dir = zoom_dir / str(tile_x)
            x_dir.mkdir(exist_ok=True)

            for tile_y in range(min_tile_y, max_tile_y + 1):
                # Create transparent image
                img = Image.new('RGBA', (tile_size, tile_size), (0, 0, 0, 0))
                draw = ImageDraw.Draw(img)

                # Get tile bounds
                tile_lon_nw, tile_lat_nw = tile_to_lon_lat(tile_x, tile_y, zoom)
                tile_lon_se, tile_lat_se = tile_to_lon_lat(tile_x + 1, tile_y + 1, zoom)

                # Draw each lift that intersects this tile
                line_width = get_lift_width(zoom)

                for feature in geojson['features']:
                    coords = feature['geometry']['coordinates']
                    lift_type = feature['properties'].get('type', 'chair_lift')
                    color = get_lift_color(lift_type)

                    # Convert coordinates to pixels
                    pixels = []
                    for lon, lat in coords:
                        # Check if point is near this tile
                        if (tile_lon_nw - 0.01 <= lon <= tile_lon_se + 0.01 and
                            tile_lat_se - 0.01 <= lat <= tile_lat_nw + 0.01):
                            px, py = lon_lat_to_pixel(lon, lat, zoom, tile_x, tile_y, tile_size)
                            pixels.append((px, py))

                    # Draw line if we have at least 2 points
                    if len(pixels) >= 2:
                        draw.line(pixels, fill=color, width=line_width)

                # Save tile
                tile_path = x_dir / f'{tile_y}.png'
                img.save(tile_path, 'PNG')
                tile_count += 1

        print(f"  Generated {tile_count} tiles")

    print(f"\nDone! Tiles saved to {output_dir}")
    print(f"\nTile URL template:")
    print(f"  /tiles/{mountain_id}/{{z}}/{{x}}/{{y}}.png")


def main():
    parser = argparse.ArgumentParser(description='Generate map tiles from GeoJSON lift data')
    parser.add_argument('mountain_id', help='Mountain ID (e.g., crystal, baker, stevens)')
    parser.add_argument('--zoom-min', type=int, default=10, help='Minimum zoom level (default: 10)')
    parser.add_argument('--zoom-max', type=int, default=16, help='Maximum zoom level (default: 16)')
    parser.add_argument('--tile-size', type=int, default=256, help='Tile size in pixels (default: 256)')

    args = parser.parse_args()

    generate_tiles(
        mountain_id=args.mountain_id,
        zoom_min=args.zoom_min,
        zoom_max=args.zoom_max,
        tile_size=args.tile_size
    )


if __name__ == '__main__':
    main()
