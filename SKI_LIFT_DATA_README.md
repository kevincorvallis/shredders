# Ski Lift Data System

## Overview

This system extracts ski lift coordinates from OpenStreetMap data and serves them as GeoJSON files for display on interactive maps.

## Architecture

```
OpenSnowMap (planet_pistes.osm)
  ↓
Parse with Python script (scripts/parse-ski-lifts.py)
  ↓
Generate GeoJSON files per mountain
  ↓
Upload to S3 (shredders-lambda-deployments/ski-data/lifts/)
  ↓
Serve via API endpoint (/api/mountains/[id]/lifts)
  ↓
iOS app fetches and displays with MapPolyline
```

## Data Source

- **Source**: [OpenSnowMap](http://www.opensnowmap.org/download/)
- **File**: `planet_pistes.osm.gz` (195MB compressed, 1.7GB uncompressed)
- **Update Frequency**: Daily
- **License**: ODbL (OpenStreetMap Database License)
- **Attribution Required**: © OpenStreetMap contributors

## Data Format

### GeoJSON Structure

Each mountain has a GeoJSON file (e.g., `crystal.geojson`):

```json
{
  "type": "FeatureCollection",
  "properties": {
    "mountain_id": "crystal",
    "mountain_name": "Crystal Mountain",
    "lift_count": 11
  },
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [-121.474, 46.935],
          [-121.473, 46.936],
          ...
        ]
      },
      "properties": {
        "id": "123456",
        "type": "chair_lift",
        "name": "Quicksilver Express",
        "occupancy": "4",
        "capacity": "2400",
        "duration": "7",
        "heating": "yes",
        "bubble": "no"
      }
    }
  ]
}
```

### Lift Types

From OpenStreetMap `aerialway` tags:

- `chair_lift` - Chairlift (single, double, triple, quad, 6-pack, etc.)
- `gondola` - Gondola lift
- `cable_car` - Cable car / tram
- `drag_lift` - Surface lift
- `t-bar` - T-bar lift
- `j-bar` - J-bar lift
- `platter` - Platter lift
- `rope_tow` - Rope tow
- `magic_carpet` - Magic carpet / conveyor belt
- `mixed_lift` - Mixed lift (e.g., chairs + gondola cabins)

## Scripts

### 1. Parse Ski Lifts (`scripts/parse-ski-lifts.py`)

Parses `planet_pistes.osm` and extracts lift data for configured mountains.

**Usage:**
```bash
cd data/ski-lifts
python3 ../../scripts/parse-ski-lifts.py planet_pistes.osm
```

**Output:**
- Creates `geojson/` directory
- Generates individual `.geojson` files per mountain

**Configuration:**

Bounding boxes defined in script for each mountain:
- **Baker**: 48.815 to 48.90 lat, -121.72 to -121.61 lng
- **Stevens**: 47.70 to 47.79 lat, -121.14 to -121.04 lng
- **Crystal**: 46.89 to 46.98 lat, -121.52 to -121.42 lng
- **Snoqualmie**: 47.38 to 47.48 lat, -121.46 to -121.36 lng

### 2. Upload to S3 (`scripts/upload-lifts-to-s3.sh`)

Uploads generated GeoJSON files to S3 bucket.

**Usage:**
```bash
cd data/ski-lifts
../../scripts/upload-lifts-to-s3.sh
```

**Output:**
- Uploads files to `s3://shredders-lambda-deployments/ski-data/lifts/`
- Sets content-type: `application/geo+json`
- Sets cache-control: `max-age=86400` (24 hours)
- Makes files publicly readable

**S3 URLs:**
```
https://shredders-lambda-deployments.s3.us-west-2.amazonaws.com/ski-data/lifts/baker.geojson
https://shredders-lambda-deployments.s3.us-west-2.amazonaws.com/ski-data/lifts/stevens.geojson
https://shredders-lambda-deployments.s3.us-west-2.amazonaws.com/ski-data/lifts/crystal.geojson
https://shredders-lambda-deployments.s3.us-west-2.amazonaws.com/ski-data/lifts/snoqualmie.geojson
```

## API Integration

### Backend Endpoint

Create new endpoint: `GET /api/mountains/[mountainId]/lifts`

```typescript
// src/app/api/mountains/[mountainId]/lifts/route.ts
import { NextResponse } from 'next/server';

export async function GET(
  request: Request,
  { params }: { params: { mountainId: string } }
) {
  const { mountainId } = params;

  // Fetch from S3
  const s3Url = `https://shredders-lambda-deployments.s3.us-west-2.amazonaws.com/ski-data/lifts/${mountainId}.geojson`;

  try {
    const response = await fetch(s3Url, {
      next: { revalidate: 86400 } // Cache for 24 hours
    });

    if (!response.ok) {
      return NextResponse.json({ error: 'Lifts not found' }, { status: 404 });
    }

    const geojson = await response.json();
    return NextResponse.json(geojson);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch lifts' }, { status: 500 });
  }
}
```

## iOS Integration

### 1. Model Updates

```swift
// PowderTracker/Models/LiftData.swift
struct LiftGeoJSON: Codable {
    let type: String
    let properties: LiftProperties
    let features: [LiftFeature]
}

struct LiftProperties: Codable {
    let mountainId: String
    let mountainName: String
    let liftCount: Int

    enum CodingKeys: String, CodingKey {
        case mountainId = "mountain_id"
        case mountainName = "mountain_name"
        case liftCount = "lift_count"
    }
}

struct LiftFeature: Codable, Identifiable {
    var id: String { properties.id }
    let type: String
    let geometry: LiftGeometry
    let properties: LiftFeatureProperties
}

struct LiftGeometry: Codable {
    let type: String
    let coordinates: [[Double]]  // [[lng, lat], ...]
}

struct LiftFeatureProperties: Codable {
    let id: String
    let type: String
    let name: String
    let occupancy: String?
    let capacity: String?
    let duration: String?
    let heating: String?
    let bubble: String?
}
```

### 2. Fetch Lift Data

```swift
// LocationViewModel.swift - add property
@Published var liftData: LiftGeoJSON?

func fetchLiftData() async {
    guard let url = URL(string: "\(APIClient.baseURL)/api/mountains/\(mountain.id)/lifts") else { return }

    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let lifts = try JSONDecoder().decode(LiftGeoJSON.self, from: data)
        await MainActor.run {
            self.liftData = lifts
        }
    } catch {
        print("Failed to fetch lifts: \(error)")
    }
}
```

### 3. Display Lifts on Map

```swift
// LocationMapSection.swift
Map(position: $cameraPosition) {
    // Existing mountain annotation
    Annotation(...) { ... }

    // NEW: Display lift lines
    if let lifts = viewModel.liftData {
        ForEach(lifts.features) { lift in
            MapPolyline(coordinates: lift.coordinates)
                .stroke(liftColor(for: lift.properties.type), lineWidth: 3)
        }
    }

    UserAnnotation()
}

private func liftColor(for type: String) -> Color {
    switch type {
    case "gondola", "cable_car":
        return .red
    case "chair_lift":
        return .blue
    case "drag_lift", "t-bar", "j-bar", "platter":
        return .green
    case "magic_carpet":
        return .purple
    default:
        return .gray
    }
}

// Convert GeoJSON coordinates to CLLocationCoordinate2D
extension LiftFeature {
    var coordinates: [CLLocationCoordinate2D] {
        geometry.coordinates.map { coord in
            CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
        }
    }
}
```

## Data Updates

To update lift data:

```bash
# 1. Download latest planet_pistes.osm.gz
cd data/ski-lifts
curl -O http://www.opensnowmap.org/download/planet_pistes.osm.gz
gunzip planet_pistes.osm.gz

# 2. Parse and generate GeoJSON
python3 ../../scripts/parse-ski-lifts.py planet_pistes.osm

# 3. Upload to S3
../../scripts/upload-lifts-to-s3.sh

# 4. Done! API will serve updated data within 24 hours (cache TTL)
```

## License & Attribution

Data sourced from OpenStreetMap under ODbL license.

**Required attribution:**
© OpenStreetMap contributors

**More info:**
- https://www.openstreetmap.org/copyright
- https://opendatacommons.org/licenses/odbl/

