#!/usr/bin/env python3
"""
Parse planet_pistes.osm and extract ski lift coordinates for each mountain.
Generates individual GeoJSON files per mountain.
"""

import xml.etree.ElementTree as ET
import json
import sys
from collections import defaultdict

# Mountain configurations with bounding boxes (approx 5km radius)
MOUNTAINS = {
    'baker': {
        'name': 'Mt. Baker',
        'center': (48.857, -121.669),
        'bbox': (48.815, -121.72, 48.90, -121.61),  # (min_lat, min_lon, max_lat, max_lon)
    },
    'stevens': {
        'name': 'Stevens Pass',
        'center': (47.745, -121.089),
        'bbox': (47.70, -121.14, 47.79, -121.04),
    },
    'crystal': {
        'name': 'Crystal Mountain',
        'center': (46.935, -121.474),
        'bbox': (46.89, -121.52, 46.98, -121.42),
    },
    'snoqualmie': {
        'name': 'Summit at Snoqualmie',
        'center': (47.428, -121.413),
        'bbox': (47.38, -121.46, 47.48, -121.36),
    },
}

def is_in_bbox(lat, lon, bbox):
    """Check if coordinate is within bounding box."""
    min_lat, min_lon, max_lat, max_lon = bbox
    return min_lat <= lat <= max_lat and min_lon <= lon <= max_lon

def parse_osm_file(osm_file):
    """
    Parse OSM file and extract lift data for each mountain.
    Returns dict of {mountain_id: [lift_features]}
    """
    print(f"🔍 Parsing {osm_file}...")

    # Storage for nodes and lifts
    nodes = {}  # node_id -> (lat, lon)
    mountain_lifts = defaultdict(list)  # mountain_id -> [lifts]

    # Parse in chunks to handle large file
    context = ET.iterparse(osm_file, events=('start', 'end'))
    context = iter(context)
    event, root = next(context)

    way_count = 0
    lift_count = 0
    current_way = None
    current_way_nodes = []
    current_way_tags = {}

    for event, elem in context:
        if event == 'start':
            continue

        # Process nodes
        if elem.tag == 'node':
            node_id = elem.get('id')
            lat = float(elem.get('lat'))
            lon = float(elem.get('lon'))
            nodes[node_id] = (lat, lon)
            elem.clear()

        # Process ways (potential lifts)
        elif elem.tag == 'way':
            if current_way is not None:
                # Check if this way is a lift
                if 'aerialway' in current_way_tags:
                    aerialway_type = current_way_tags['aerialway']

                    # Skip stations and zip lines
                    if aerialway_type not in ['station', 'zip_line', 'goods']:
                        # Get coordinates for this way
                        coords = []
                        for node_ref in current_way_nodes:
                            if node_ref in nodes:
                                coords.append(nodes[node_ref])

                        if coords:
                            # Check which mountain(s) this lift belongs to
                            for mountain_id, mountain_config in MOUNTAINS.items():
                                # Check if any coordinate is in this mountain's bbox
                                if any(is_in_bbox(lat, lon, mountain_config['bbox']) for lat, lon in coords):
                                    lift_feature = {
                                        'type': 'Feature',
                                        'geometry': {
                                            'type': 'LineString',
                                            'coordinates': [[lon, lat] for lat, lon in coords]  # GeoJSON: [lon, lat]
                                        },
                                        'properties': {
                                            'id': current_way,
                                            'type': aerialway_type,
                                            'name': current_way_tags.get('name', f'Lift {current_way}'),
                                            'occupancy': current_way_tags.get('aerialway:occupancy'),
                                            'capacity': current_way_tags.get('aerialway:capacity'),
                                            'duration': current_way_tags.get('aerialway:duration'),
                                            'heating': current_way_tags.get('aerialway:heating'),
                                            'bubble': current_way_tags.get('aerialway:bubble'),
                                        }
                                    }
                                    mountain_lifts[mountain_id].append(lift_feature)
                                    lift_count += 1
                                    break  # Each lift only assigned to one mountain

            # Start new way
            current_way = elem.get('id')
            current_way_nodes = []
            current_way_tags = {}
            way_count += 1

            if way_count % 10000 == 0:
                print(f"  Processed {way_count:,} ways, found {lift_count} lifts...")

            elem.clear()

        # Process way nodes
        elif elem.tag == 'nd' and current_way is not None:
            current_way_nodes.append(elem.get('ref'))
            elem.clear()

        # Process way tags
        elif elem.tag == 'tag' and current_way is not None:
            k = elem.get('k')
            v = elem.get('v')
            current_way_tags[k] = v
            elem.clear()

    root.clear()
    print(f"✅ Parsing complete! Found {lift_count} lifts across {len(mountain_lifts)} mountains")
    return mountain_lifts

def generate_geojson_files(mountain_lifts, output_dir='./geojson'):
    """Generate individual GeoJSON files for each mountain."""
    import os

    os.makedirs(output_dir, exist_ok=True)

    for mountain_id, lifts in mountain_lifts.items():
        if not lifts:
            print(f"  ⚠️  No lifts found for {mountain_id}")
            continue

        geojson = {
            'type': 'FeatureCollection',
            'properties': {
                'mountain_id': mountain_id,
                'mountain_name': MOUNTAINS[mountain_id]['name'],
                'lift_count': len(lifts),
            },
            'features': lifts
        }

        output_file = os.path.join(output_dir, f'{mountain_id}.geojson')
        with open(output_file, 'w') as f:
            json.dump(geojson, f, indent=2)

        print(f"  ✅ {mountain_id}: {len(lifts)} lifts -> {output_file}")

def main():
    osm_file = 'planet_pistes.osm'

    if len(sys.argv) > 1:
        osm_file = sys.argv[1]

    print("🎿 Ski Lift Extractor")
    print("=" * 50)

    # Parse OSM file
    mountain_lifts = parse_osm_file(osm_file)

    # Generate GeoJSON files
    print("\n📝 Generating GeoJSON files...")
    generate_geojson_files(mountain_lifts)

    print("\n✨ Done!")
    print(f"Generated {len(mountain_lifts)} GeoJSON files in ./geojson/")

if __name__ == '__main__':
    main()
