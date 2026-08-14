"""
Suraksha -- Safety Grid Builder for Supabase safety_cells table
--------------------------------------------------------------
Reads the Kaggle CSV, groups by city/area (one cell per area),
runs ONNX inference for a representative feature vector per cell
(area-average static features, Afternoon time bucket, Clear weather),
derives risk thresholds from the actual inferred score distribution
(33rd/66th percentile -- not arbitrary cutoffs), and outputs
safety_cells_import.json matching the safety_cells schema in safety.ts.

Tradeoff note (printed at runtime too):
  One row per area uses Afternoon/Clear as the representative context.
  PRO: simple, fast, matches existing Flutter grid shape (one score per area).
  CON: does not capture time-of-day variation per cell.
  Alternative: one row per (area x time_bucket x weather) = 25x more rows,
  better time-aware accuracy, but safety_cells lookup needs a range query.
  Use the single-row approach for the hackathon; note the upgrade path.

Run from /Users/synaagrawala/hack/Suraksha/ml/:
    python3 build_safety_grid.py

Requires (must run train_model.py first):
    ./scaler_params.json
    ../suraksha/assets/model/safety_model.onnx

Outputs:
    ./safety_cells_import.json   (POST to /api/v1/admin/safety-cells/import)
"""

import json
import os
import datetime

import numpy as np
import pandas as pd
import onnxruntime as rt

SCRIPT_DIR    = os.path.dirname(os.path.abspath(__file__))
CSV_PATH      = os.path.join(SCRIPT_DIR, "..", "Woman_Safety_Dataset_Management-1.csv")
ONNX_PATH     = os.path.join(SCRIPT_DIR, "..", "suraksha", "assets", "model", "safety_model.onnx")
SCALER_PATH   = os.path.join(SCRIPT_DIR, "scaler_params.json")
OUTPUT_PATH   = os.path.join(SCRIPT_DIR, "safety_cells_import.json")
MODEL_VERSION = "v2-mlp-20260807"

# -- Load scaler params ------------------------------------------------------
print("=" * 60)
print("  LOADING SCALER PARAMS")
print("=" * 60)
with open(SCALER_PATH) as f:
    sp = json.load(f)

scaler_mean        = np.array(sp["scaler_mean"],  dtype=np.float32)
scaler_scale       = np.array(sp["scaler_scale"], dtype=np.float32)
TIME_CATEGORIES    = sp["time_categories"]
WEATHER_CATEGORIES = sp["weather_categories"]
print(f"  Scaler mean  : {scaler_mean.tolist()}")
print(f"  Scaler scale : {scaler_scale.tolist()}")
print(f"  Time cats    : {TIME_CATEGORIES}")
print(f"  Weather cats : {WEATHER_CATEGORIES}")

# -- Load ONNX model ---------------------------------------------------------
print("\n" + "=" * 60)
print("  LOADING ONNX MODEL")
print("=" * 60)
sess       = rt.InferenceSession(ONNX_PATH)
input_name = sess.get_inputs()[0].name
print(f"  Input name   : {input_name}")
print(f"  Input shape  : {sess.get_inputs()[0].shape}")

def build_vector(lighting, police_dist, crowd, crime_count,
                 time_of_day="Afternoon", weather="Clear"):
    """Build a 14-dim float32 feature vector matching training column order."""
    numeric    = np.array([lighting, police_dist, crowd, crime_count], dtype=np.float32)
    scaled_num = (numeric - scaler_mean) / scaler_scale
    time_oh    = np.array([1.0 if t == time_of_day else 0.0 for t in TIME_CATEGORIES],    dtype=np.float32)
    weather_oh = np.array([1.0 if w == weather    else 0.0 for w in WEATHER_CATEGORIES], dtype=np.float32)
    return np.concatenate([scaled_num, time_oh, weather_oh])

def infer(vector: np.ndarray) -> float:
    x      = vector.reshape(1, -1).astype(np.float32)
    result = sess.run(None, {input_name: x})[0].flatten()[0]
    return float(np.clip(result, 0.0, 1.0))

# -- Tradeoff note -----------------------------------------------------------
print("\n" + "=" * 60)
print("  TRADEOFF NOTE")
print("=" * 60)
print("""  One row per area, using Afternoon/Clear as representative context.
  PRO:  Simple, fast, one-to-one with existing Flutter safety_grid.json.
  CON:  Does not model time-of-day or weather variation per cell.
  ALT:  One row per (area x 5 time_buckets x 5 weather) = 25x rows.
        Better accuracy for time-aware queries but requires range lookup.
  Decision: single-row for hackathon. Upgrade path is clear.""")

# -- Load dataset ------------------------------------------------------------
print("\n" + "=" * 60)
print("  LOADING DATASET")
print("=" * 60)
df = pd.read_csv(CSV_PATH).dropna(subset=[
    "city", "area", "lighting_score",
    "police_station_distance_km", "crowd_density",
    "crime_count", "safety_score"
])
print(f"  Rows after NaN drop : {len(df)}")
print(f"  Cities              : {sorted(df['city'].unique())}")
print(f"  Area count          : {df['area'].nunique()}")

# -- Aggregate per city/area -------------------------------------------------
print("\n" + "=" * 60)
print("  AGGREGATING PER CELL (city x area)")
print("=" * 60)
grid = (
    df.groupby(["city", "area"])
    .agg(
        lat=("latitude", "mean"),
        lng=("longitude", "mean"),
        avg_lighting=("lighting_score", "mean"),
        avg_police_dist=("police_station_distance_km", "mean"),
        avg_crowd=("crowd_density", "mean"),
        avg_crime_count=("crime_count", "mean"),
        sample_count=("safety_score", "count"),
    )
    .reset_index()
)
print(f"  Total cells : {len(grid)}")

# -- Run ONNX inference per cell ---------------------------------------------
print("\n" + "=" * 60)
print("  RUNNING ONNX INFERENCE PER CELL")
print("=" * 60)
scores = []
for _, row in grid.iterrows():
    v     = build_vector(row.avg_lighting, row.avg_police_dist,
                         row.avg_crowd,   row.avg_crime_count)
    score = infer(v)
    scores.append(score)
grid["safety_score"] = scores
print(f"  Inference complete for {len(grid)} cells")

# -- Score distribution and risk thresholds ----------------------------------
print("\n" + "=" * 60)
print("  SCORE DISTRIBUTION ACROSS CELLS")
print("=" * 60)
print(grid["safety_score"].describe().to_string())

p33 = float(np.percentile(grid["safety_score"], 33))
p66 = float(np.percentile(grid["safety_score"], 66))
print(f"\n  Risk thresholds (33rd/66th percentile of inferred cell scores):")
print(f"    High   : score <  {p33:.4f}  (bottom 33%)")
print(f"    Medium : {p33:.4f} <= score < {p66:.4f}  (middle 34%)")
print(f"    Low    : score >= {p66:.4f}  (top 33%)")

def score_to_risk(score):
    if score >= p66:   return "Low"
    elif score >= p33: return "Medium"
    else:              return "High"

grid["risk_level"] = grid["safety_score"].apply(score_to_risk)
print(f"\n  Risk distribution:")
print(grid["risk_level"].value_counts().to_string())

# -- Build safety_cells records (match safety.ts schema) --------------------
print("\n" + "=" * 60)
print("  BUILDING safety_cells_import.json")
print("=" * 60)
now     = datetime.datetime.utcnow().isoformat() + "Z"
records = []
for _, row in grid.iterrows():
    city_slug = row["city"].lower().replace(" ", "_")
    area_slug = row["area"].lower().replace(" ", "_")
    cell_key  = f"{city_slug}_{area_slug}"
    records.append({
        "cellKey":          cell_key,
        "city":             row["city"],
        "area":             row["area"],
        "latitude":         round(float(row["lat"]),  6),
        "longitude":        round(float(row["lng"]),  6),
        "safetyScore":      round(float(row["safety_score"]), 6),
        "riskLevel":        row["risk_level"],
        "lightingScore":    round(float(row["avg_lighting"]),     4),
        "policeDistanceKm": round(float(row["avg_police_dist"]),  4),
        "crowdDensity":     round(float(row["avg_crowd"]),        4),
        "crimeCount":       round(float(row["avg_crime_count"]),  4),
        "confidence":       None,
        "sampleCount":      int(row["sample_count"]),
        "modelVersion":     MODEL_VERSION,
        "validFrom":        now,
        "validUntil":       None,
        "metadata":         None,
    })

# Print 4 sample records
print("\n  Sample records (first 4):")
for rec in records[:4]:
    print(f"    {rec}")

with open(OUTPUT_PATH, "w") as f:
    json.dump({"cells": records}, f, indent=2)

print(f"\n  Total cells written : {len(records)}")
print(f"  Output path         : {OUTPUT_PATH}")
print("\nNext: POST /api/v1/admin/safety-cells/import with body = contents of safety_cells_import.json")
