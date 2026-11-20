"""Generate the sample order-to-delivery event log.

100,000 orders over 90 days, 4 warehouses, 5 stages per order. One row per
order per stage with start and end timestamps (about 500k rows). Saved as a
gzipped CSV to keep it a sensible size for GitHub; pandas reads it directly.

The operation I'm simulating:
- Order Placed: payment check + release to the warehouse (system step, ~30 min)
- Picked:       pickers run 24/7 (~40 min)
- Packed:       packing benches only run 06:00-22:00. Anything that reaches
                packing after 22:00 waits for the morning shift. WH02 and WH03
                don't pack on Sundays. WH03 runs one bench short, and lost
                another packer in mid-September. The 14:00-18:00 window is the
                busiest part of the day, so packing queues build up there.
- Dispatched:   handed to the carrier (~40 min)
- Delivered:    last-mile (~35 min, city same-day network)

Orders placed on the last day are still in progress when the data is
pulled, so some of their later stages have no end time or no row yet.
"""
from datetime import datetime, timedelta
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "process_events.csv.gz"

SEED = 27
N_ORDERS = 100_000
START = datetime(2026, 8, 1)
DAYS = 90
SNAPSHOT = START + timedelta(days=DAYS)  # data pulled at midnight after day 90

STAGES = ["Order Placed", "Picked", "Packed", "Dispatched", "Delivered"]

WAREHOUSES = {
    # id: (home region, share of orders, base packing minutes, sunday packing?)
    "WH01": ("North", 0.30, 70, True),
    "WH02": ("West", 0.28, 85, False),
    "WH03": ("South", 0.24, 150, False),
    "WH04": ("East", 0.18, 75, True),
}
REGIONS = ["North", "West", "South", "East"]

rng = np.random.default_rng(SEED)


def lognormal_minutes(mean, sigma=0.45, size=None):
    """Right-skewed durations with roughly the requested mean."""
    mu = np.log(mean) - sigma ** 2 / 2
    return rng.lognormal(mu, sigma, size)


def order_times():
    # More orders in later weeks (volume growth) and during the day.
    day_weights = np.linspace(0.8, 1.25, DAYS)
    days = rng.choice(DAYS, size=N_ORDERS, p=day_weights / day_weights.sum())
    hour_weights = np.array([1, 0.5, 0.3, 0.2, 0.2, 0.4, 1, 2, 3.5, 5, 6, 6.5,
                             6.5, 6, 6, 6.5, 6.5, 6, 6, 6.5, 6, 5, 3.5, 2], dtype=float)
    hours = rng.choice(24, size=N_ORDERS, p=hour_weights / hour_weights.sum())
    minutes = rng.integers(0, 60, N_ORDERS)
    seconds = rng.integers(0, 60, N_ORDERS)
    times = [START + timedelta(days=int(d), hours=int(h), minutes=int(m), seconds=int(s))
             for d, h, m, s in zip(days, hours, minutes, seconds)]
    return sorted(times)


def next_packing_slot(t, sunday_packing):
    """Push t forward to the next time a packing bench is staffed."""
    while True:
        if t.weekday() == 6 and not sunday_packing:
            t = datetime(t.year, t.month, t.day) + timedelta(days=1, hours=6)
            continue
        if t.hour < 6:
            return datetime(t.year, t.month, t.day, 6)
        if t.hour >= 22:
            t = datetime(t.year, t.month, t.day) + timedelta(days=1, hours=6)
            continue
        return t


def packing_minutes(wh, arrive, base):
    m = lognormal_minutes(base, sigma=0.6)
    if 14 <= arrive.hour < 18:          # afternoon peak, queue builds
        m *= 1.8
    if wh == "WH03" and arrive >= datetime(2026, 9, 15):
        m *= 1.5                         # second packer left mid-September
    return m


def build():
    wh_ids = list(WAREHOUSES)
    wh_share = np.array([WAREHOUSES[w][1] for w in wh_ids])
    rows = []
    for i, placed in enumerate(order_times(), start=1):
        order_id = f"ORD-{10000 + i}"
        wh = rng.choice(wh_ids, p=wh_share)
        home, _, base_pack, sunday = WAREHOUSES[wh]
        # 82% of orders go to the warehouse's home region
        region = home if rng.random() < 0.82 else rng.choice([r for r in REGIONS if r != home])

        t = placed
        for stage in STAGES:
            if stage == "Order Placed":
                start, dur = t, lognormal_minutes(30)
            elif stage == "Picked":
                start, dur = t, lognormal_minutes(40)
            elif stage == "Packed":
                start = t  # stage clock starts when it arrives at packing
                ready = next_packing_slot(t, sunday)
                dur = (ready - t).total_seconds() / 60 + packing_minutes(wh, ready, base_pack)
            elif stage == "Dispatched":
                start, dur = t, lognormal_minutes(40)
            else:
                cross = 1.25 if region != home else 1.0
                start, dur = t, lognormal_minutes(35 * cross)

            end = start + timedelta(minutes=float(dur))
            end = end.replace(microsecond=0)
            if start >= SNAPSHOT:
                break                     # stage hasn't started yet at snapshot
            rows.append({
                "OrderID": order_id,
                "Stage": stage,
                "StageStartTime": start,
                "StageEndTime": end if end <= SNAPSHOT else pd.NaT,
                "WarehouseID": wh,
                "Region": region,
            })
            if end > SNAPSHOT:
                break                     # still in this stage
            t = end

    df = pd.DataFrame(rows)
    OUT.parent.mkdir(exist_ok=True)
    # mtime=0 so the same seed always gives a byte-identical file
    df.to_csv(OUT, index=False, date_format="%Y-%m-%d %H:%M:%S", lineterminator="\n",
              compression={"method": "gzip", "mtime": 0})
    return df


if __name__ == "__main__":
    df = build()
    done = df.groupby("OrderID")["Stage"].count().eq(5) & df.groupby("OrderID")["StageEndTime"].count().eq(5)
    print(f"Saved {len(df):,} rows, {df.OrderID.nunique():,} orders ({(~done).sum()} still in flight) -> {OUT.relative_to(ROOT)}")
