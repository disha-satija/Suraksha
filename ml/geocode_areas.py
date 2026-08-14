"""
geocode_areas.py — Re-geocode all 50 (city, area) pairs in safety_cells_import.json
using Nominatim (1 req/sec, India-biased), producing corrected lat/lng.

Outputs:
  1. Console: before/after table for all 50 areas
  2. safety_cells_import.json  — updated in-place with corrected lat/lng
  3. safety_grid.json          — Flutter offline copy, corrected lat/lng

Run from /Users/synaagrawala/hack/Suraksha/ml/:
    python3 geocode_areas.py
"""

import json, time, requests, os, math

SCRIPT_DIR      = os.path.dirname(os.path.abspath(__file__))
IMPORT_PATH     = os.path.join(SCRIPT_DIR, "safety_cells_import.json")
GRID_OUT_PATH   = os.path.join(SCRIPT_DIR, "..", "suraksha", "assets", "data", "safety_grid.json")

NOMINATIM_URL   = "https://nominatim.openstreetmap.org/search"
USER_AGENT      = "Suraksha/1.0 geocode_areas contact=admin@suraksha.app"
RATE_LIMIT_SEC  = 1.1   # Nominatim limit ≤1 req/s

def nominatim_search(area: str, city: str) -> tuple[float, float] | None:
    """Query Nominatim for 'area, city, India'. Returns (lat, lng) or None."""
    for query in [
        f"{area}, {city}, India",
        f"{area}, India",
    ]:
        try:
            resp = requests.get(
                NOMINATIM_URL,
                params={"q": query, "format": "jsonv2", "limit": 1, "addressdetails": "1"},
                headers={"User-Agent": USER_AGENT},
                timeout=10,
            )
            resp.raise_for_status()
            data = resp.json()
            if data:
                return float(data[0]["lat"]), float(data[0]["lon"])
        except Exception as e:
            print(f"    ⚠ Nominatim error for '{query}': {e}")
        time.sleep(RATE_LIMIT_SEC)
    return None

def haversine_km(lat1, lng1, lat2, lng2):
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng/2)**2
    return R * 2 * math.asin(math.sqrt(max(0.0, min(1.0, a))))

# ── Load import file ────────────────────────────────────────────────────────
with open(IMPORT_PATH) as f:
    import_data = json.load(f)

cells = import_data["cells"]
print(f"Loaded {len(cells)} cells from safety_cells_import.json\n")

# ── Geocode each cell ───────────────────────────────────────────────────────
COL = f"{'#':>3}  {'City':<15}  {'Area':<22}  {'OldLat':>10}  {'OldLng':>10}  {'NewLat':>10}  {'NewLng':>10}  {'Shift(km)':>10}  {'Source':<12}"
print(COL)
print("-" * len(COL))

for i, cell in enumerate(cells):
    city = cell["city"]
    area = cell["area"]
    old_lat = cell["latitude"]
    old_lng = cell["longitude"]

    time.sleep(RATE_LIMIT_SEC)
    result = nominatim_search(area, city)
    if result:
        new_lat, new_lng = result
        source = "nominatim"
    else:
        new_lat, new_lng = old_lat, old_lng
        source = "UNCHANGED ⚠"

    shift_km = haversine_km(old_lat, old_lng, new_lat, new_lng)
    print(f"{i+1:>3}  {city:<15}  {area:<22}  {old_lat:>10.6f}  {old_lng:>10.6f}  {new_lat:>10.6f}  {new_lng:>10.6f}  {shift_km:>10.2f}  {source:<12}")

    # Update cell
    cell["latitude"]  = round(new_lat, 6)
    cell["longitude"] = round(new_lng, 6)

# ── Write updated safety_cells_import.json ──────────────────────────────────
with open(IMPORT_PATH, "w") as f:
    json.dump(import_data, f, indent=2)
print(f"\n✅  Updated {IMPORT_PATH}")

# ── Write safety_grid.json for Flutter ─────────────────────────────────────
# Format matches SafetyGridEntry in lib/models/safety_grid_entry.dart
grid_entries = []
for cell in cells:
    grid_entries.append({
        "cellKey":        cell["cellKey"],
        "city":           cell["city"],
        "area":           cell["area"],
        "lat":            cell["latitude"],
        "lng":            cell["longitude"],
        "avgSafetyScore": cell["safetyScore"],
        "avgLighting":    cell["lightingScore"],
        "avgPoliceDist":  cell["policeDistanceKm"],
        "avgCrowd":       cell["crowdDensity"],
        "avgCrimeCount":  cell["crimeCount"],
        "riskLevel":      cell["riskLevel"],
        "sampleCount":    cell["sampleCount"],
    })

os.makedirs(os.path.dirname(GRID_OUT_PATH), exist_ok=True)
with open(GRID_OUT_PATH, "w") as f:
    json.dump(grid_entries, f, indent=2)
print(f"✅  Updated {GRID_OUT_PATH}")
print(f"\nDone. {len(cells)} cells re-geocoded.")
