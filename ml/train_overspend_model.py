# ml/train_overspend_model.py
import json, math, glob
import numpy as np
import pandas as pd
from datetime import datetime
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

# ---------- Load your historical data ----------
# Expect a CSV with columns: user_id,title,amount,date,category,month_budget_json
# OR replace this with your SQLite export.
df = pd.read_csv('expenses_history.csv', parse_dates=['date'])

# Helper: compute features for a given (user, month, snapshot_day)
CATS = ["food","grocery","leisure","travel","work"]  # adjust to your enum

def recurring_count(month_df):
    norm = month_df['title'].str.lower().str.replace(r'[^a-z0-9 ]','',regex=True).str.strip()
    counts = norm.value_counts()
    cand = counts[counts >= 3].index
    if cand.empty: return 0
    return (norm.isin(cand)).sum()

def snapshot_features(month_df, budgets, snapshot_day):
    m = month_df.copy()
    m['day'] = m['date'].dt.day
    mtd = m[m['day'] <= snapshot_day]
    if mtd.empty:
        return None

    days_in_month = m['date'].dt.days_in_month.iloc[0]
    days_ratio = snapshot_day / days_in_month

    spend_mtd = mtd['amount'].sum()
    avg_daily = spend_mtd / max(snapshot_day,1)

    last7_end = snapshot_day
    last7_start = max(1, snapshot_day-6)
    last7 = mtd[(mtd['day']>=last7_start)&(mtd['day']<=last7_end)]['amount'].sum()
    baseline = spend_mtd / max(snapshot_day,1) * 7.0
    last7_vs_base = last7 / max(baseline,1e-6)

    # small purchases
    small = mtd[mtd['amount']<=300]
    small_cnt = len(small)

    # recurring
    rec_cnt = recurring_count(mtd)

    # per-category
    row = {
        "days_ratio": days_ratio,
        "spend_mtd": spend_mtd,
        "avg_daily": avg_daily,
        "last7_sum": last7,
        "last7_vs_base": last7_vs_base,
        "small_cnt": small_cnt,
        "recurring_cnt": rec_cnt,
    }
    for c in CATS:
        cat_mtd = mtd[mtd['category']==c]['amount'].sum()
        row[f'{c}_mtd'] = cat_mtd
        row[f'{c}_ratio'] = (cat_mtd / max(spend_mtd,1e-6))

    total_budget = sum(budgets.get(c,0.0) for c in CATS)
    row['budget_gap_total'] = (total_budget - spend_mtd)

    return row

def month_label(full_month_df, budgets):
    # 1 if any category > budget or total > total budget
    byc = full_month_df.groupby('category')['amount'].sum().to_dict()
    total = full_month_df['amount'].sum()
    total_budget = sum(budgets.get(c,0.0) for c in CATS)
    if total > total_budget: return 1
    for c in CATS:
        if byc.get(c,0.0) > budgets.get(c,0.0) > 0:
            return 1
    return 0

# Parse budgets JSON per month (ensure your CSV has this; else load from another table)
df['month'] = df['date'].dt.to_period('M').astype(str)
rows = []
for (user, mo), g in df.groupby(['user_id','month']):
    # budgets per month
    bjson = g['month_budget_json'].iloc[0]
    budgets = json.loads(bjson) if isinstance(bjson,str) else {c:0.0 for c in CATS}
    g = g.sort_values('date')

    # choose 3 snapshots per month
    days_in_month = g['date'].dt.days_in_month.iloc[0]
    for day in [10, 15, 20]:
        if day > days_in_month: continue
        feats = snapshot_features(g, budgets, day)
        if feats is None: continue
        label = month_label(g, budgets)
        feats['label'] = label
        feats['user_id'] = user
        feats['month'] = mo
        rows.append(feats)

data = pd.DataFrame(rows)
feature_cols = [c for c in data.columns if c not in ['label','user_id','month']]
X = data[feature_cols].fillna(0.0).values.astype('float32')
y = data['label'].values.astype('float32')

# train/val split
perm = np.random.permutation(len(X))
cut = int(0.8*len(X))
tr, va = perm[:cut], perm[cut:]
Xtr, ytr = X[tr], y[tr]
Xva, yva = X[va], y[va]

# scale
mean = Xtr.mean(axis=0)
std = Xtr.std(axis=0) + 1e-6
Xtr = (Xtr - mean) / std
Xva = (Xva - mean) / std

# small MLP
model = keras.Sequential([
    layers.Input(shape=(X.shape[1],)),
    layers.Dense(32, activation='relu'),
    layers.Dense(16, activation='relu'),
    layers.Dense(1, activation='sigmoid')
])
model.compile(optimizer=keras.optimizers.Adam(1e-3),
              loss='binary_crossentropy',
              metrics=['AUC','Precision','Recall'])
model.fit(Xtr, ytr, epochs=25, batch_size=64, validation_data=(Xva, yva))

# save scaler stats for Flutter
meta = {
    "feature_order": feature_cols,
    "mean": mean.tolist(),
    "std": std.tolist(),
}
with open('overspend_meta.json','w') as f:
    json.dump(meta, f, indent=2)

# export TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
open('overspend.tflite','wb').write(tflite_model)

print("Saved: overspend.tflite, overspend_meta.json")
