"""
Suraksha — Safety Score Model Training Pipeline
------------------------------------------------
Trains a Linear Regression model on the full dataset,
exports to ONNX for on-device inference, and writes
model_weights.json for Dart-side explainability math.

Run:
    python3 train_model.py

Outputs:
    ../suraksha/assets/model/safety_model.onnx
    ../suraksha/assets/model/model_weights.json
    ../suraksha/assets/data/safety_grid.json
"""

import json
import os
import warnings

import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType

warnings.filterwarnings("ignore")

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(SCRIPT_DIR, "..", "Woman_Safety_Dataset_Management-1.csv")
OUT_DIR = os.path.join(SCRIPT_DIR, "..", "suraksha", "assets", "model")
DATA_DIR = os.path.join(SCRIPT_DIR, "..", "suraksha", "assets", "data")
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)

# ── Feature config ─────────────────────────────────────────────────────────────
# These are the features used for model training AND for Dart-side explainability.
# Order matters — must match the ONNX input vector order.
NUMERIC_FEATURES = [
    "lighting_score",
    "police_station_distance_km",
    "crowd_density",
    "crime_count",
]

TIME_CATEGORIES = ["Morning", "Afternoon", "Evening", "Night", "Late Night"]
WEATHER_CATEGORIES = ["Clear", "Rainy", "Foggy", "Stormy", "Humid"]

TARGET = "safety_score"

# ── Load data ──────────────────────────────────────────────────────────────────
print("Loading dataset...")
df = pd.read_csv(CSV_PATH)
print(f"  Total rows: {len(df)}")
print(f"  Columns: {list(df.columns)}")
print(f"\nSafety score stats:\n{df[TARGET].describe()}")

# ── Feature engineering ────────────────────────────────────────────────────────
print("\nEngineering features...")

# One-hot encode time_of_day
for cat in TIME_CATEGORIES:
    col_name = f"time_{cat.lower().replace(' ', '_')}"
    df[col_name] = (df["time_of_day"] == cat).astype(float)

# One-hot encode weather_condition
for cat in WEATHER_CATEGORIES:
    col_name = f"weather_{cat.lower()}"
    df[col_name] = (df["weather_condition"] == cat).astype(float)

TIME_FEATURES = [f"time_{c.lower().replace(' ', '_')}" for c in TIME_CATEGORIES]
WEATHER_FEATURES = [f"weather_{c.lower()}" for c in WEATHER_CATEGORIES]

ALL_FEATURES = NUMERIC_FEATURES + TIME_FEATURES + WEATHER_FEATURES

# Drop rows with missing values in feature or target columns
df_clean = df[ALL_FEATURES + [TARGET, "latitude", "longitude", "city", "area"]].dropna()
print(f"  Rows after cleaning: {len(df_clean)}")

X = df_clean[ALL_FEATURES].values.astype(np.float32)
y = df_clean[TARGET].values.astype(np.float32)

# ── Scale numeric features only ────────────────────────────────────────────────
scaler = StandardScaler()
X_numeric = scaler.fit_transform(X[:, :len(NUMERIC_FEATURES)])
X_scaled = np.hstack([X_numeric, X[:, len(NUMERIC_FEATURES):]]).astype(np.float32)

# ── Train/test split ───────────────────────────────────────────────────────────
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y, test_size=0.2, random_state=42
)
print(f"\nTrain size: {len(X_train)}, Test size: {len(X_test)}")

# ── Train model ────────────────────────────────────────────────────────────────
print("\nTraining Linear Regression...")
model = LinearRegression()
model.fit(X_train, y_train)

y_pred = model.predict(X_test)
r2 = r2_score(y_test, y_pred)
mae = mean_absolute_error(y_test, y_pred)
print(f"  R²  : {r2:.4f}")
print(f"  MAE : {mae:.4f}")

if r2 < 0.5:
    print("\n  ⚠️  R² is below 0.5 — consider switching to Decision Tree.")
    print("      Re-running with DecisionTreeRegressor (depth=3) as fallback...")
    from sklearn.tree import DecisionTreeRegressor
    model = DecisionTreeRegressor(max_depth=3, random_state=42)
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    r2 = r2_score(y_test, y_pred)
    mae = mean_absolute_error(y_test, y_pred)
    print(f"  Decision Tree R²  : {r2:.4f}")
    print(f"  Decision Tree MAE : {mae:.4f}")
    model_type = "decision_tree"
else:
    model_type = "linear_regression"

print(f"\n  Using model: {model_type}")

# ── Export to ONNX ─────────────────────────────────────────────────────────────
print("\nExporting to ONNX...")
n_features = X_scaled.shape[1]
initial_type = [("float_input", FloatTensorType([None, n_features]))]
onnx_model = convert_sklearn(model, initial_types=initial_type, target_opset=12)

onnx_path = os.path.join(OUT_DIR, "safety_model.onnx")
with open(onnx_path, "wb") as f:
    f.write(onnx_model.SerializeToString())
print(f"  Saved: {onnx_path}")

# ── Export model weights for Dart explainability ───────────────────────────────
# For linear regression: coefficients map directly to feature importance.
# For decision tree: we use feature_importances_ as proxy weights.
print("\nExporting model weights for Dart explainability...")

if model_type == "linear_regression":
    weights = model.coef_.tolist()
    intercept = float(model.intercept_)
else:
    weights = model.feature_importances_.tolist()
    intercept = 0.0

weights_data = {
    "model_type": model_type,
    "feature_names": ALL_FEATURES,
    "numeric_features": NUMERIC_FEATURES,
    "time_features": TIME_FEATURES,
    "weather_features": WEATHER_FEATURES,
    "weights": weights,
    "intercept": intercept,
    "scaler_mean": scaler.mean_.tolist(),
    "scaler_scale": scaler.scale_.tolist(),
    "n_features": n_features,
    "r2_score": round(r2, 4),
    "mae": round(mae, 4),
}

weights_path = os.path.join(OUT_DIR, "model_weights.json")
with open(weights_path, "w") as f:
    json.dump(weights_data, f, indent=2)
print(f"  Saved: {weights_path}")

# ── Precompute safety grid ─────────────────────────────────────────────────────
# Grid = average predicted safety score per area, with lat/lng centroid.
# This is the "always available" baseline — used even if ONNX runtime fails.
print("\nPrecomputing safety grid...")

df_clean = df_clean.copy()
df_clean["predicted_score"] = np.clip(
    model.predict(X_scaled), 0.0, 1.0
)

grid = (
    df_clean.groupby(["city", "area"])
    .agg(
        lat=("latitude", "mean"),
        lng=("longitude", "mean"),
        avg_safety_score=("predicted_score", "mean"),
        avg_lighting=("lighting_score", "mean"),
        avg_police_dist=("police_station_distance_km", "mean"),
        avg_crowd=("crowd_density", "mean"),
        avg_crime_count=("crime_count", "mean"),
        incident_count=("predicted_score", "count"),
    )
    .reset_index()
)

# Risk level from score
def score_to_risk(score):
    if score >= 0.75:
        return "Low"
    elif score >= 0.5:
        return "Medium"
    else:
        return "High"

grid["risk_level"] = grid["avg_safety_score"].apply(score_to_risk)

grid_records = grid.to_dict(orient="records")
# Round floats for smaller JSON
for rec in grid_records:
    for k, v in rec.items():
        if isinstance(v, float):
            rec[k] = round(v, 6)

grid_path = os.path.join(DATA_DIR, "safety_grid.json")
with open(grid_path, "w") as f:
    json.dump(grid_records, f, indent=2)

print(f"  Grid entries: {len(grid_records)}")
print(f"  Saved: {grid_path}")

# ── Summary ────────────────────────────────────────────────────────────────────
print("\n" + "=" * 55)
print("  DONE")
print("=" * 55)
print(f"  Model type    : {model_type}")
print(f"  R² score      : {r2:.4f}")
print(f"  MAE           : {mae:.4f}")
print(f"  ONNX path     : {onnx_path}")
print(f"  Weights path  : {weights_path}")
print(f"  Grid path     : {grid_path}")
print(f"  Grid entries  : {len(grid_records)}")
print("=" * 55)
print("\nNext step: copy assets into Flutter and run 'flutter pub get'")
