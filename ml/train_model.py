"""
Suraksha -- Safety Score Model Training Pipeline (v2)
-----------------------------------------------------
Trains an MLPRegressor (hidden_layer_sizes=(32,16)) AND a LinearRegression,
keeps whichever has higher R^2 on the held-out 20% test set.
Exports to ONNX, writes scaler_params.json for exact backend replication,
and verifies ONNX output against sklearn on 5 test rows.

Run from /Users/synaagrawala/hack/Suraksha/ml/:
    python3 train_model.py

Outputs:
    ../suraksha/assets/model/safety_model.onnx
    ../suraksha/assets/model/model_weights.json   (Dart explainability compat)
    ../suraksha/assets/data/safety_grid.json       (Flutter offline grid)
    ./scaler_params.json                           (backend inference replication)
"""

import json
import os
import warnings

import numpy as np
import pandas as pd
import onnxruntime as rt
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPRegressor
from sklearn.preprocessing import StandardScaler
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType

warnings.filterwarnings("ignore")

# -- Paths -------------------------------------------------------------------
SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
CSV_PATH     = os.path.join(SCRIPT_DIR, "..", "Woman_Safety_Dataset_Management-1.csv")
OUT_DIR      = os.path.join(SCRIPT_DIR, "..", "suraksha", "assets", "model")
DATA_DIR     = os.path.join(SCRIPT_DIR, "..", "suraksha", "assets", "data")
SCALER_PATH  = os.path.join(SCRIPT_DIR, "scaler_params.json")
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)

# -- Feature config ----------------------------------------------------------
NUMERIC_FEATURES   = ["lighting_score", "police_station_distance_km", "crowd_density", "crime_count"]
TIME_CATEGORIES    = ["Morning", "Afternoon", "Evening", "Night", "Late Night"]
WEATHER_CATEGORIES = ["Clear", "Rainy", "Foggy", "Stormy", "Humid"]
TARGET             = "safety_score"

# -- Load data ---------------------------------------------------------------
print("=" * 60)
print("  LOADING DATASET")
print("=" * 60)
df = pd.read_csv(CSV_PATH)
print(f"  Total rows : {len(df)}")
print(f"  Columns    : {list(df.columns)}")
print(f"\n  time_of_day unique values      : {sorted(df['time_of_day'].dropna().unique())}")
print(f"  weather_condition unique values: {sorted(df['weather_condition'].dropna().unique())}")
print(f"\n  Safety score distribution:")
print(df[TARGET].describe().to_string())

# -- Feature engineering -----------------------------------------------------
print("\n" + "=" * 60)
print("  FEATURE ENGINEERING")
print("=" * 60)

for cat in TIME_CATEGORIES:
    df[f"time_{cat.lower().replace(' ', '_')}"] = (df["time_of_day"] == cat).astype(float)
for cat in WEATHER_CATEGORIES:
    df[f"weather_{cat.lower()}"] = (df["weather_condition"] == cat).astype(float)

TIME_FEATURES    = [f"time_{c.lower().replace(' ', '_')}" for c in TIME_CATEGORIES]
WEATHER_FEATURES = [f"weather_{c.lower()}" for c in WEATHER_CATEGORIES]
ALL_FEATURES     = NUMERIC_FEATURES + TIME_FEATURES + WEATHER_FEATURES

df_clean = df[ALL_FEATURES + [TARGET, "latitude", "longitude", "city", "area"]].dropna()
print(f"  Rows after dropping NaN : {len(df_clean)}")
print(f"  Feature count           : {len(ALL_FEATURES)}")
print(f"  Features                : {ALL_FEATURES}")

X = df_clean[ALL_FEATURES].values.astype(np.float32)
y = df_clean[TARGET].values.astype(np.float32)

# -- Scale numeric features only (one-hot columns untouched) ----------------
scaler   = StandardScaler()
X_num    = scaler.fit_transform(X[:, :len(NUMERIC_FEATURES)])
X_scaled = np.hstack([X_num, X[:, len(NUMERIC_FEATURES):]]).astype(np.float32)

print(f"\n  Scaler mean  : {scaler.mean_.tolist()}")
print(f"  Scaler scale : {scaler.scale_.tolist()}")

# -- Train/test split (80/20) ------------------------------------------------
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y, test_size=0.2, random_state=42
)
print(f"\n  Train size : {len(X_train)}")
print(f"  Test  size : {len(X_test)}")

# -- Train MLPRegressor ------------------------------------------------------
print("\n" + "=" * 60)
print("  TRAINING MLPRegressor  (hidden_layer_sizes=(32,16))")
print("=" * 60)
mlp = MLPRegressor(
    hidden_layer_sizes=(32, 16),
    activation="relu",
    solver="adam",
    max_iter=500,
    random_state=42,
    early_stopping=True,
    validation_fraction=0.1,
    n_iter_no_change=20,
)
mlp.fit(X_train, y_train)
y_pred_mlp = mlp.predict(X_test)
r2_mlp  = r2_score(y_test, y_pred_mlp)
mae_mlp = mean_absolute_error(y_test, y_pred_mlp)
print(f"  Iterations used : {mlp.n_iter_}")
print(f"  MLP  R^2        : {r2_mlp:.4f}")
print(f"  MLP  MAE        : {mae_mlp:.4f}")

# -- Train LinearRegression --------------------------------------------------
print("\n" + "=" * 60)
print("  TRAINING LinearRegression (baseline)")
print("=" * 60)
lr = LinearRegression()
lr.fit(X_train, y_train)
y_pred_lr = lr.predict(X_test)
r2_lr  = r2_score(y_test, y_pred_lr)
mae_lr = mean_absolute_error(y_test, y_pred_lr)
print(f"  LR   R^2 : {r2_lr:.4f}")
print(f"  LR   MAE : {mae_lr:.4f}")

# -- Model selection ---------------------------------------------------------
print("\n" + "=" * 60)
print("  MODEL SELECTION")
print("=" * 60)
if r2_mlp >= r2_lr:
    model      = mlp
    model_type = "mlp_regressor"
    r2, mae    = r2_mlp, mae_mlp
    print(f"  -> MLP selected  (R^2={r2_mlp:.4f} >= LR R^2={r2_lr:.4f})")
else:
    model      = lr
    model_type = "linear_regression"
    r2, mae    = r2_lr, mae_lr
    print(f"  -> LinearRegression selected  (R^2={r2_lr:.4f} > MLP R^2={r2_mlp:.4f})")

# -- Save scaler_params.json -------------------------------------------------
print("\n" + "=" * 60)
print("  SAVING scaler_params.json")
print("=" * 60)
scaler_data = {
    "feature_names":      ALL_FEATURES,
    "numeric_features":   NUMERIC_FEATURES,
    "time_categories":    TIME_CATEGORIES,
    "weather_categories": WEATHER_CATEGORIES,
    "scaler_mean":        scaler.mean_.tolist(),
    "scaler_scale":       scaler.scale_.tolist(),
    "n_features":         len(ALL_FEATURES),
}
with open(SCALER_PATH, "w") as f:
    json.dump(scaler_data, f, indent=2)
print(f"  Saved: {SCALER_PATH}")

# -- Export to ONNX ----------------------------------------------------------
print("\n" + "=" * 60)
print("  ONNX EXPORT")
print("=" * 60)
n_features   = X_scaled.shape[1]
initial_type = [("float_input", FloatTensorType([None, n_features]))]
onnx_model   = convert_sklearn(model, initial_types=initial_type, target_opset=12)
onnx_path    = os.path.join(OUT_DIR, "safety_model.onnx")
with open(onnx_path, "wb") as f:
    f.write(onnx_model.SerializeToString())
print(f"  Saved: {onnx_path}")

# -- ONNX verification (5 test rows) ----------------------------------------
print("\n" + "=" * 60)
print("  ONNX VERIFICATION  (sklearn vs onnxruntime, 5 test rows)")
print("=" * 60)
sess       = rt.InferenceSession(onnx_path)
input_name = sess.get_inputs()[0].name
sample     = X_test[:5].astype(np.float32)
sk_preds   = model.predict(sample)
onnx_out   = sess.run(None, {input_name: sample})[0].flatten()
print(f"  {'Row':<5} {'sklearn':>12} {'onnx':>12} {'|delta|':>12}")
print(f"  {'-'*5} {'-'*12} {'-'*12} {'-'*12}")
for i, (s, o) in enumerate(zip(sk_preds, onnx_out)):
    print(f"  {i:<5} {float(s):>12.6f} {float(o):>12.6f} {abs(float(s)-float(o)):>12.8f}")
max_delta = float(max(abs(float(s) - float(o)) for s, o in zip(sk_preds, onnx_out)))
status    = "PASS" if max_delta < 1e-4 else "FAIL -- check skl2onnx version"
print(f"\n  Max delta : {max_delta:.8f}  [{status}]")

# -- Export model_weights.json -----------------------------------------------
print("\n" + "=" * 60)
print("  EXPORTING model_weights.json  (Dart explainability compat)")
print("=" * 60)
if model_type == "linear_regression":
    weights   = model.coef_.tolist()
    intercept = float(model.intercept_)
else:
    weights   = np.abs(model.coefs_[0]).sum(axis=1).tolist()
    intercept = 0.0

weights_data = {
    "model_type":       model_type,
    "feature_names":    ALL_FEATURES,
    "numeric_features": NUMERIC_FEATURES,
    "time_features":    TIME_FEATURES,
    "weather_features": WEATHER_FEATURES,
    "weights":          weights,
    "intercept":        intercept,
    "scaler_mean":      scaler.mean_.tolist(),
    "scaler_scale":     scaler.scale_.tolist(),
    "n_features":       n_features,
    "r2_score":         round(r2, 4),
    "mae":              round(mae, 4),
}
weights_path = os.path.join(OUT_DIR, "model_weights.json")
with open(weights_path, "w") as f:
    json.dump(weights_data, f, indent=2)
print(f"  Saved: {weights_path}")

# -- Precompute safety grid --------------------------------------------------
print("\n" + "=" * 60)
print("  PRECOMPUTING SAFETY GRID  (Flutter offline baseline)")
print("=" * 60)
df_clean = df_clean.copy()
df_clean["predicted_score"] = np.clip(model.predict(X_scaled), 0.0, 1.0)

p33 = float(np.percentile(df_clean["predicted_score"], 33))
p66 = float(np.percentile(df_clean["predicted_score"], 66))
print(f"  Risk thresholds (33rd/66th percentile of predicted scores):")
print(f"    Low    : score >= {p66:.4f}")
print(f"    Medium : {p33:.4f} <= score < {p66:.4f}")
print(f"    High   : score <  {p33:.4f}")

def score_to_risk(score):
    if score >= p66:   return "Low"
    elif score >= p33: return "Medium"
    else:              return "High"

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
grid["risk_level"] = grid["avg_safety_score"].apply(score_to_risk)
grid_records = grid.to_dict(orient="records")
for rec in grid_records:
    for k, v in rec.items():
        if isinstance(v, float):
            rec[k] = round(v, 6)

grid_path = os.path.join(DATA_DIR, "safety_grid.json")
with open(grid_path, "w") as f:
    json.dump(grid_records, f, indent=2)
print(f"\n  Grid entries : {len(grid_records)}")
print(f"  Saved        : {grid_path}")

# -- Final summary -----------------------------------------------------------
print("\n" + "=" * 60)
print("  DONE")
print("=" * 60)
print(f"  Model type   : {model_type}")
print(f"  R^2 (test)   : {r2:.4f}")
print(f"  MAE (test)   : {mae:.4f}")
print(f"  ONNX path    : {onnx_path}")
print(f"  Scaler path  : {SCALER_PATH}")
print(f"  Weights path : {weights_path}")
print(f"  Grid entries : {len(grid_records)}")
print("=" * 60)
print("\nNext step: run build_safety_grid.py to generate safety_cells_import.json")
