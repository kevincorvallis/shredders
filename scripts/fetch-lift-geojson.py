#!/usr/bin/env python3
"""
Fetch ski lift GeoJSON from OpenStreetMap Overpass API for all mountains.
Queries aerialway-tagged ways within 5km of each mountain's coordinates.
Outputs GeoJSON files matching the existing S3 format.
"""

import json
import os
import time
import urllib.request
import urllib.error

OVERPASS_URL = "https://overpass-api.de/api/interpreter"

# All mountains with coordinates from packages/shared/src/config/mountains.ts
MOUNTAINS = {
    # Washington
    "baker": {"name": "Mt. Baker", "lat": 48.857, "lng": -121.669},
    "stevens": {"name": "Stevens Pass", "lat": 47.745, "lng": -121.089},
    "crystal": {"name": "Crystal Mountain", "lat": 46.935, "lng": -121.474},
    "snoqualmie": {"name": "Summit at Snoqualmie", "lat": 47.428, "lng": -121.413},
    "whitepass": {"name": "White Pass", "lat": 46.637, "lng": -121.391},
    "missionridge": {"name": "Mission Ridge", "lat": 47.293, "lng": -120.398},
    "fortynine": {"name": "49 Degrees North", "lat": 48.795, "lng": -117.565},
    # Oregon
    "meadows": {"name": "Mt. Hood Meadows", "lat": 45.331, "lng": -121.665},
    "timberline": {"name": "Timberline Lodge", "lat": 45.331, "lng": -121.711},
    "bachelor": {"name": "Mt. Bachelor", "lat": 43.979, "lng": -121.688},
    "ashland": {"name": "Mt. Ashland", "lat": 42.086, "lng": -122.715},
    "willamette": {"name": "Willamette Pass", "lat": 43.596, "lng": -122.039},
    "hoodoo": {"name": "Hoodoo Ski Area", "lat": 44.408, "lng": -121.870},
    "anthonylakes": {"name": "Anthony Lakes", "lat": 44.96, "lng": -118.23},
    # Idaho
    "schweitzer": {"name": "Schweitzer Mountain", "lat": 48.368, "lng": -116.622},
    "lookout": {"name": "Lookout Pass", "lat": 47.454, "lng": -115.713},
    "sunvalley": {"name": "Sun Valley Resort", "lat": 43.699, "lng": -114.361},
    "brundage": {"name": "Brundage Mountain", "lat": 45.0, "lng": -116.17},
    # Canada
    "whistler": {"name": "Whistler Blackcomb", "lat": 50.115, "lng": -122.95},
    "revelstoke": {"name": "Revelstoke Mountain Resort", "lat": 50.9, "lng": -118.2},
    "cypress": {"name": "Cypress Mountain", "lat": 49.396, "lng": -123.207},
    "sunpeaks": {"name": "Sun Peaks Resort", "lat": 50.885, "lng": -119.885},
    "bigwhite": {"name": "Big White Ski Resort", "lat": 49.7219, "lng": -118.9289},
    "red": {"name": "RED Mountain Resort", "lat": 50.87, "lng": -117.75},
    "panorama": {"name": "Panorama Mountain Resort", "lat": 50.4603, "lng": -116.2403},
    "silverstar": {"name": "SilverStar Mountain Resort", "lat": 50.36, "lng": -119.06},
    "apex": {"name": "Apex Mountain Resort", "lat": 49.3907, "lng": -119.9039},
    # Utah
    "parkcity": {"name": "Park City Mountain", "lat": 40.6508, "lng": -111.5075},
    "snowbird": {"name": "Snowbird", "lat": 40.5756, "lng": -111.6561},
    "alta": {"name": "Alta Ski Area", "lat": 40.5808, "lng": -111.6372},
    "brighton": {"name": "Brighton Resort", "lat": 40.5987, "lng": -111.5833},
    "solitude": {"name": "Solitude Mountain Resort", "lat": 40.6151, "lng": -111.5889},
    "deervalley": {"name": "Deer Valley Resort", "lat": 40.6151, "lng": -111.4870},
    "snowbasin": {"name": "Snowbasin Resort", "lat": 41.2160, "lng": -111.8570},
    "powdermountain": {"name": "Powder Mountain", "lat": 41.3800, "lng": -111.7803},
    # Colorado
    "vail": {"name": "Vail Mountain", "lat": 39.6403, "lng": -106.3742},
    "breckenridge": {"name": "Breckenridge Ski Resort", "lat": 39.4817, "lng": -106.0678},
    "beavercreek": {"name": "Beaver Creek Resort", "lat": 39.6042, "lng": -106.5165},
    "keystone": {"name": "Keystone Resort", "lat": 39.6086, "lng": -105.9428},
    "crestedbutte": {"name": "Crested Butte Mountain Resort", "lat": 38.8972, "lng": -106.9656},
    "aspen": {"name": "Aspen Snowmass", "lat": 39.1913, "lng": -106.8231},
    "steamboat": {"name": "Steamboat Resort", "lat": 40.4572, "lng": -106.8040},
    "winterpark": {"name": "Winter Park Resort", "lat": 39.8869, "lng": -105.7631},
    # California
    "heavenly": {"name": "Heavenly Mountain Resort", "lat": 38.9353, "lng": -119.9400},
    "northstar": {"name": "Northstar California", "lat": 39.2742, "lng": -120.1219},
    "kirkwood": {"name": "Kirkwood Mountain Resort", "lat": 38.6844, "lng": -120.0655},
    "palisades": {"name": "Palisades Tahoe", "lat": 39.1969, "lng": -120.2356},
    "mammoth": {"name": "Mammoth Mountain", "lat": 37.6308, "lng": -119.0326},
    # Wyoming
    "jacksonhole": {"name": "Jackson Hole Mountain Resort", "lat": 43.5875, "lng": -110.8277},
    # Montana
    "bigsky": {"name": "Big Sky Resort", "lat": 45.2860, "lng": -111.4016},
    # Vermont
    "stowe": {"name": "Stowe Mountain Resort", "lat": 44.5253, "lng": -72.7814},
    "killington": {"name": "Killington Resort", "lat": 43.6045, "lng": -72.8201},
    # New Mexico
    "taos": {"name": "Taos Ski Valley", "lat": 36.5953, "lng": -105.4514},
}

SKIP_TYPES = {"station", "zip_line", "goods", "pylon"}


def query_overpass(lat, lng, radius=5000):
    """Query Overpass API for aerialway ways near a point."""
    query = f"""
    [out:json][timeout:30];
    way["aerialway"](around:{radius},{lat},{lng});
    out body;
    >;
    out skel qt;
    """
    data = urllib.request.urlopen(
        urllib.request.Request(
            OVERPASS_URL,
            data=f"data={urllib.parse.quote(query)}".encode(),
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        ),
        timeout=60,
    ).read()
    return json.loads(data)


def overpass_to_geojson(mountain_id, mountain_name, overpass_data):
    """Convert Overpass JSON to GeoJSON FeatureCollection matching existing format."""
    nodes = {}
    for elem in overpass_data.get("elements", []):
        if elem["type"] == "node":
            nodes[elem["id"]] = (elem["lat"], elem["lon"])

    features = []
    for elem in overpass_data.get("elements", []):
        if elem["type"] != "way":
            continue
        tags = elem.get("tags", {})
        aerialway_type = tags.get("aerialway", "")
        if aerialway_type in SKIP_TYPES or not aerialway_type:
            continue

        coords = []
        for node_id in elem.get("nodes", []):
            if node_id in nodes:
                lat, lon = nodes[node_id]
                coords.append([lon, lat])  # GeoJSON is [lng, lat]

        if not coords:
            continue

        features.append({
            "type": "Feature",
            "geometry": {"type": "LineString", "coordinates": coords},
            "properties": {
                "id": str(elem["id"]),
                "type": aerialway_type,
                "name": tags.get("name", f"Lift {elem['id']}"),
                "occupancy": tags.get("aerialway:occupancy"),
                "capacity": tags.get("aerialway:capacity"),
                "duration": tags.get("aerialway:duration"),
                "heating": tags.get("aerialway:heating"),
                "bubble": tags.get("aerialway:bubble"),
            },
        })

    return {
        "type": "FeatureCollection",
        "properties": {
            "mountain_id": mountain_id,
            "mountain_name": mountain_name,
            "lift_count": len(features),
        },
        "features": features,
    }


def main():
    import urllib.parse

    output_dir = os.path.join(os.path.dirname(__file__), "..", "public", "lifts")
    os.makedirs(output_dir, exist_ok=True)

    results = {}
    total = len(MOUNTAINS)

    for i, (mid, mtn) in enumerate(MOUNTAINS.items(), 1):
        print(f"[{i}/{total}] {mid} ({mtn['name']})...", end=" ", flush=True)
        try:
            data = query_overpass(mtn["lat"], mtn["lng"])
            geojson = overpass_to_geojson(mid, mtn["name"], data)
            count = geojson["properties"]["lift_count"]

            if count > 0:
                path = os.path.join(output_dir, f"{mid}.geojson")
                with open(path, "w") as f:
                    json.dump(geojson, f, indent=2)
                print(f"{count} lifts")
            else:
                print("0 lifts (skipped)")

            results[mid] = count
        except Exception as e:
            print(f"ERROR: {e}")
            results[mid] = -1

        # Rate limit: Overpass API asks for 1 req/sec
        if i < total:
            time.sleep(1.5)

    # Summary
    print("\n=== Summary ===")
    found = {k: v for k, v in results.items() if v > 0}
    empty = {k: v for k, v in results.items() if v == 0}
    errors = {k: v for k, v in results.items() if v < 0}
    print(f"Mountains with lifts: {len(found)}/{total}")
    print(f"No lifts found: {len(empty)}")
    if errors:
        print(f"Errors: {len(errors)} - {list(errors.keys())}")
    print("\nLift counts:")
    for mid, count in sorted(found.items(), key=lambda x: -x[1]):
        print(f"  {mid}: {count}")


if __name__ == "__main__":
    main()
